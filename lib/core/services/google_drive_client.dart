import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:pos_billing/core/auth/google_auth_service.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/services/backup_service.dart';

class GoogleHttpClient extends http.BaseClient {
  GoogleHttpClient(this._headers);

  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

class DriveBackupEntry {
  const DriveBackupEntry({
    required this.id,
    required this.name,
    this.modifiedTime,
    this.size,
  });

  final String id;
  final String name;
  final DateTime? modifiedTime;
  final int? size;
}

/// Google Drive backup client using **appDataFolder** only (no My Drive folders).
class GoogleDriveBackupClient implements DriveBackupClient {
  GoogleDriveBackupClient({required this.auth});

  final GoogleAuthService auth;

  GoogleAuthService get _auth => auth;

  static const envelopeFileName = 'pos_dek_envelope.v1';
  static const latestFileName = 'pos_backup_latest.posbackup';

  @override
  Future<bool> get isSignedIn => _auth.isSignedIn;

  @override
  Future<String?> get accountEmail async =>
      (await _auth.session)?.email ?? _auth.currentUser?.email;

  @override
  Future<String?> get accountId async =>
      (await _auth.session)?.googleUserId ?? _auth.currentUser?.id;

  @override
  Future<String?> get accountDisplayName async =>
      (await _auth.session)?.displayName ?? _auth.currentUser?.displayName;

  @override
  Future<String?> get accountPhotoUrl async =>
      (await _auth.session)?.photoUrl ?? _auth.currentUser?.photoUrl;

  @override
  Future<void> signIn() async {
    await _auth.signIn();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<drive.DriveApi> _api() async {
    var user = _auth.currentUser;
    if (user == null) {
      await _auth.restoreSilently();
      user = _auth.currentUser;
    }
    if (user == null) {
      throw const DriveAuthException(
        'Google Drive session expired. Please connect again.',
      );
    }
    final headers = await user.authHeaders;
    return drive.DriveApi(GoogleHttpClient(headers));
  }

  @override
  Future<String> upload({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final api = await _api();
    final existing = await _findByName(api, fileName);
    final media = drive.Media(Stream.value(bytes), bytes.length);
    if (existing != null) {
      final updated = await api.files.update(
        drive.File()..name = fileName,
        existing.id!,
        uploadMedia: media,
      );
      return updated.id ?? existing.id!;
    }
    final created = await api.files.create(
      drive.File()
        ..name = fileName
        ..parents = ['appDataFolder'],
      uploadMedia: media,
    );
    return created.id ?? '';
  }

  @override
  Future<Uint8List> download(String fileId) async {
    final api = await _api();
    final media = await api.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  Future<List<DriveBackupEntry>> listBackups() async {
    final api = await _api();
    final out = <DriveBackupEntry>[];
    String? pageToken;
    try {
      do {
        // Avoid server-side orderBy — it often fails on appDataFolder and
        // caused the UI to clear the list. Sort locally instead.
        final listed = await api.files.list(
          spaces: 'appDataFolder',
          q: "trashed=false and (name contains 'pos_backup_' or name contains '.posbackup')",
          $fields: 'nextPageToken,files(id,name,modifiedTime,size)',
          pageSize: 100,
          pageToken: pageToken,
        );
        _collectBackupFiles(listed.files, out);
        pageToken = listed.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);
    } catch (_) {
      // Fallback: list appDataFolder without a query filter.
      out.clear();
      pageToken = null;
      do {
        final listed = await api.files.list(
          spaces: 'appDataFolder',
          $fields: 'nextPageToken,files(id,name,modifiedTime,size)',
          pageSize: 100,
          pageToken: pageToken,
        );
        _collectBackupFiles(listed.files, out);
        pageToken = listed.nextPageToken;
      } while (pageToken != null && pageToken.isNotEmpty);
    }

    out.sort((a, b) {
      final am = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bm = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bm.compareTo(am);
    });
    return out;
  }

  void _collectBackupFiles(
    List<drive.File>? files,
    List<DriveBackupEntry> out,
  ) {
    for (final f in files ?? const <drive.File>[]) {
      final id = f.id;
      final name = f.name;
      if (id == null || name == null) continue;
      if (name == envelopeFileName) continue;
      if (!name.contains('pos_backup_') && !name.endsWith('.posbackup')) {
        continue;
      }
      out.add(
        DriveBackupEntry(
          id: id,
          name: name,
          modifiedTime: f.modifiedTime,
          size: int.tryParse(f.size ?? ''),
        ),
      );
    }
  }

  @override
  Future<DriveBackupEntry?> findLatest() async {
    final all = await listBackups();
    for (final e in all) {
      if (e.name == latestFileName) return e;
    }
    return all.isEmpty ? null : all.first;
  }

  @override
  Future<void> deleteBackupFile(String fileId) async {
    final api = await _api();
    await api.files.delete(fileId);
  }

  /// Deletes older timestamped backups after a verified upload. Always keeps
  /// [latestFileName] plus up to [keep] newest timestamped files.
  @override
  Future<void> pruneOldBackups({int keep = 10}) async {
    final all = await listBackups();
    final latest = <DriveBackupEntry>[];
    final stamped = <DriveBackupEntry>[];
    for (final e in all) {
      if (e.name == latestFileName) {
        latest.add(e);
      } else {
        stamped.add(e);
      }
    }
    if (stamped.length <= keep) return;
    stamped.sort((a, b) {
      final am = a.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bm = b.modifiedTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bm.compareTo(am);
    });
    final toDelete = stamped.skip(keep);
    final api = await _api();
    for (final entry in toDelete) {
      try {
        await api.files.delete(entry.id);
      } catch (_) {
        // Best-effort prune.
      }
    }
    // Keep a single "latest" pointer if duplicates somehow exist.
    for (final dup in latest.skip(1)) {
      try {
        await api.files.delete(dup.id);
      } catch (_) {}
    }
  }

  @override
  Future<Uint8List?> downloadByName(String fileName) async {
    final api = await _api();
    final file = await _findByName(api, fileName);
    if (file?.id == null) return null;
    return download(file!.id!);
  }

  @override
  Future<String> uploadEnvelope(Uint8List bytes) =>
      upload(fileName: envelopeFileName, bytes: bytes);

  @override
  Future<Uint8List?> downloadEnvelope() => downloadByName(envelopeFileName);

  Future<drive.File?> _findByName(drive.DriveApi api, String name) async {
    final listed = await api.files.list(
      spaces: 'appDataFolder',
      q: "name='$name' and trashed=false",
      $fields: 'files(id,name)',
      pageSize: 5,
    );
    final files = listed.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }
}
