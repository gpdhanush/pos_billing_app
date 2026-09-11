import 'dart:typed_data';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
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
}

class GoogleDriveBackupClient implements DriveBackupClient {
  GoogleDriveBackupClient({GoogleSignIn? signIn})
      : _signIn = signIn ??
            GoogleSignIn(
              scopes: [drive.DriveApi.driveFileScope],
            );

  final GoogleSignIn _signIn;
  static const _folderName = 'POS_Backup';

  @override
  Future<bool> get isSignedIn async => (await _signIn.signInSilently()) != null || _signIn.currentUser != null;

  @override
  Future<String?> get accountEmail async =>
      _signIn.currentUser?.email ?? (await _signIn.signInSilently())?.email;

  @override
  Future<void> signIn() async {
    try {
      final account = await _signIn.signIn();
      if (account == null) {
        throw const DriveAuthException('Google Drive sign-in was cancelled');
      }
    } catch (e) {
      if (e is DriveAuthException) rethrow;
      throw DriveAuthException('Google Drive sign-in failed', cause: e);
    }
  }

  @override
  Future<void> signOut() => _signIn.signOut();

  Future<drive.DriveApi> _api() async {
    final user = _signIn.currentUser ?? await _signIn.signInSilently();
    if (user == null) throw const DriveAuthException('Not signed in');
    final headers = await user.authHeaders;
    return drive.DriveApi(GoogleHttpClient(headers));
  }

  Future<String> _folderId(drive.DriveApi api) async {
    final found = await api.files.list(
      q: "mimeType='application/vnd.google-apps.folder' and name='$_folderName' and trashed=false",
      spaces: 'drive',
    );
    if (found.files != null && found.files!.isNotEmpty) {
      return found.files!.first.id!;
    }
    final created = await api.files.create(
      drive.File()
        ..name = _folderName
        ..mimeType = 'application/vnd.google-apps.folder',
    );
    return created.id!;
  }

  @override
  Future<String> upload({required String fileName, required Uint8List bytes}) async {
    final api = await _api();
    final folderId = await _folderId(api);
    final media = drive.Media(Stream.value(bytes), bytes.length);
    final created = await api.files.create(
      drive.File()
        ..name = fileName
        ..parents = [folderId],
      uploadMedia: media,
    );
    return created.id ?? '';
  }

  @override
  Future<Uint8List> download(String fileId) async {
    final api = await _api();
    final media = await api.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia)
        as drive.Media;
    final builder = BytesBuilder();
    await for (final chunk in media.stream) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}
