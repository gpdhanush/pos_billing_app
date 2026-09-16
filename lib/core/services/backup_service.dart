import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/settings_repository.dart';
import 'package:pos_billing/core/database/repositories/store_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/services/backup_crypto.dart';
import 'package:pos_billing/core/services/connectivity_service.dart';
import 'package:pos_billing/core/services/google_drive_client.dart';
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:uuid/uuid.dart';

enum BackupProgressStage {
  preparing,
  creatingCopy,
  encrypting,
  uploading,
  verifying,
  completed,
}

typedef BackupProgressCallback = void Function(BackupProgressStage stage);

class BackupPackage {
  const BackupPackage({
    required this.bytes,
    required this.fileName,
    required this.checksum,
    required this.manifest,
  });

  final Uint8List bytes;
  final String fileName;
  final String checksum;
  final Map<String, Object?> manifest;
}

abstract class DriveBackupClient {
  Future<bool> get isSignedIn;
  Future<String?> get accountEmail;
  Future<String?> get accountId;
  Future<String?> get accountDisplayName;
  Future<String?> get accountPhotoUrl;
  Future<void> signIn();
  Future<void> signOut();
  Future<String> upload({required String fileName, required Uint8List bytes});
  Future<Uint8List> download(String fileId);
  Future<List<DriveBackupEntry>> listBackups();
  Future<DriveBackupEntry?> findLatest();
  Future<void> deleteBackupFile(String fileId);
  Future<void> pruneOldBackups({int keep = 3});
  Future<Uint8List?> downloadByName(String fileName);
  Future<String> uploadEnvelope(Uint8List bytes);
  Future<Uint8List?> downloadEnvelope();
}

class BackupService {
  BackupService(
    this._db, {
    required this.secureStorage,
    this.drive,
    ConnectivityService? connectivity,
    BackupCrypto? crypto,
  })  : connectivity = connectivity ?? ConnectivityService(),
        crypto = crypto ?? BackupCrypto(secureStorage);

  final AppDatabase _db;
  final FlutterSecureStorage secureStorage;
  final DriveBackupClient? drive;
  final ConnectivityService connectivity;
  final BackupCrypto crypto;

  static const folderAppName = 'POS Billing';
  static const folderBackupName = 'backup';
  static const formatName = 'posbackup';
  static const mediaFolderProduct = 'product_images';
  static const mediaFolderStore = 'store_logos';
  static const mediaArchiveEntry = 'media.enc';

  Future<BackupRecord> createBackup({
    bool uploadToDrive = false,
    BackupProgressCallback? onProgress,
    Future<String?> Function()? requestPassphraseForEnvelope,
  }) async {
    final store = await StoreRepository(_db).loadStore();
    final stamp = DateTime.now();
    final stampedName =
        'pos_backup_${stamp.year.toString().padLeft(4, '0')}-'
        '${stamp.month.toString().padLeft(2, '0')}-'
        '${stamp.day.toString().padLeft(2, '0')}_'
        '${stamp.hour.toString().padLeft(2, '0')}'
        '${stamp.minute.toString().padLeft(2, '0')}'
        '${stamp.second.toString().padLeft(2, '0')}.posbackup';
    final historyId = await _db.db.insert('backup_history', {
      'file_name': stampedName,
      'backup_version': DbConstants.backupFormatVersion,
      'database_version': DbConstants.schemaVersion,
      'status': 'in_progress',
      'created_at': nowMillis(),
    });

    try {
      onProgress?.call(BackupProgressStage.preparing);

      // Unlock / create the Drive DEK *before* encrypting. Otherwise a fresh
      // install invents a new local key, skips envelope unlock, and uploads
      // backups that cannot be restored with the account passphrase.
      final signedInForDrive =
          uploadToDrive && drive != null && await drive!.isSignedIn;
      if (signedInForDrive) {
        await _ensureInternetForDrive();
        await _ensureDekEnvelope(requestPassphraseForEnvelope);
      }

      final pkg = await buildPackage(
        storeId: store?.id,
        storeName: store?.businessName,
        fileName: stampedName,
        onProgress: onProgress,
      );

      onProgress?.call(BackupProgressStage.creatingCopy);
      final dir = await _backupDir();
      final localFile = File(p.join(dir.path, stampedName));
      await localFile.writeAsBytes(pkg.bytes, flush: true);

      String? driveId;
      if (signedInForDrive) {
        onProgress?.call(BackupProgressStage.uploading);
        driveId = await drive!.upload(
          fileName: stampedName,
          bytes: pkg.bytes,
        );
        await drive!.upload(
          fileName: GoogleDriveBackupClient.latestFileName,
          bytes: pkg.bytes,
        );
        onProgress?.call(BackupProgressStage.verifying);
        final verified = await _verifyDriveUpload(driveId, pkg.bytes.length);
        if (!verified) {
          throw const BackupException('Drive upload verification failed');
        }
        await drive!.pruneOldBackups(keep: 10);
      }

      onProgress?.call(BackupProgressStage.completed);
      await _db.db.update(
        'backup_history',
        {
          'local_path': localFile.path,
          'drive_file_id': driveId,
          'file_size': pkg.bytes.length,
          'checksum': pkg.checksum,
          'status': 'successful',
          'completed_at': nowMillis(),
        },
        where: 'id = ?',
        whereArgs: [historyId],
      );
      await AuditHelper.write(
        _db.db,
        action: AuditActions.backupCreated,
        entityType: 'backup',
        entityId: historyId,
      );
      await SettingsRepository(_db).setBool(
        SettingKeys.dataChangedSinceBackup,
        false,
      );
      return (await get(historyId))!;
    } catch (e) {
      await _db.db.update(
        'backup_history',
        {
          'status': 'failed',
          'error_message': 'Backup could not be completed.',
          'completed_at': nowMillis(),
        },
        where: 'id = ?',
        whereArgs: [historyId],
      );
      throw BackupException('Backup failed', cause: e);
    }
  }

  Future<BackupPackage> buildPackage({
    int? storeId,
    String? storeName,
    required String fileName,
    BackupProgressCallback? onProgress,
  }) async {
    try {
      await _db.db.execute('PRAGMA wal_checkpoint(FULL)');
    } catch (_) {}
    onProgress?.call(BackupProgressStage.creatingCopy);
    final dbPath = _db.db.path;
    final dbBytes = await File(dbPath).readAsBytes();
    final checksum = BackupCrypto.checksumSha256(dbBytes);

    final mediaPack = await _buildMediaArchiveBytes();
    final mediaCount = mediaPack?.count ?? 0;
    final mediaPlain = mediaPack?.bytes;

    onProgress?.call(BackupProgressStage.encrypting);
    final encrypted = await crypto.encryptGcm(dbBytes);
    Uint8List? mediaEncrypted;
    String? mediaChecksum;
    if (mediaPlain != null) {
      mediaChecksum = BackupCrypto.checksumSha256(mediaPlain);
      mediaEncrypted = await crypto.encryptGcm(mediaPlain);
    }

    final deviceId = await _deviceId();
    final manifest = <String, Object?>{
      'format': formatName,
      'formatVersion': DbConstants.backupFormatVersion,
      'backup_version': DbConstants.backupFormatVersion,
      'appVersion': DbConstants.appVersion,
      'app_version': DbConstants.appVersion,
      'databaseVersion': DbConstants.schemaVersion,
      'database_version': DbConstants.schemaVersion,
      'storeId': storeId,
      'store_id': storeId,
      'storeName': storeName,
      'createdAt': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'deviceId': deviceId,
      'databaseSize': dbBytes.length,
      'checksum': checksum,
      'file_name': fileName,
      'hasMedia': mediaEncrypted != null,
      'mediaCount': mediaCount,
      'mediaChecksum': ?mediaChecksum,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    final archive = Archive()
      ..addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      )
      ..addFile(ArchiveFile('database.enc', encrypted.length, encrypted));
    if (mediaEncrypted != null) {
      archive.addFile(
        ArchiveFile(
          mediaArchiveEntry,
          mediaEncrypted.length,
          mediaEncrypted,
        ),
      );
    }
    final zipped = ZipEncoder().encode(archive);
    return BackupPackage(
      bytes: Uint8List.fromList(zipped),
      fileName: fileName,
      checksum: checksum,
      manifest: manifest,
    );
  }

  Future<void> restoreFromFile(
    String path, {
    Future<void> Function()? afterClosed,
    Future<bool> Function(int backupStoreId, int? currentStoreId)?
        confirmStoreMismatch,
  }) async {
    final bytes = await File(path).readAsBytes();
    await restoreFromBytes(
      bytes,
      afterClosed: afterClosed,
      confirmStoreMismatch: confirmStoreMismatch,
    );
  }

  Future<void> restoreFromBytes(
    Uint8List bytes, {
    Future<void> Function()? afterClosed,
    Future<bool> Function(int backupStoreId, int? currentStoreId)?
        confirmStoreMismatch,
    Future<String?> Function()? requestPassphraseForUnlock,
  }) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw RestoreException('Invalid backup file', cause: e);
    }
    final manifestFile = archive.findFile('manifest.json');
    final dbFile = archive.findFile('database.enc');
    if (manifestFile == null || dbFile == null) {
      throw const RestoreException('Backup is missing required files');
    }
    final manifest =
        jsonDecode(utf8.decode(manifestFile.content as List<int>))
            as Map<String, dynamic>;
    final formatVersion = _readInt(
          manifest,
          const ['formatVersion', 'backup_version'],
        ) ??
        0;
    if (formatVersion > DbConstants.backupFormatVersion) {
      throw const RestoreException(
        'This backup was created by a newer app version',
      );
    }
    final databaseVersion = _readInt(
          manifest,
          const ['databaseVersion', 'database_version'],
        ) ??
        0;
    if (databaseVersion > DbConstants.schemaVersion) {
      throw const RestoreException(
        'This backup requires a newer app database version',
      );
    }

    final backupStoreId = _readInt(
      manifest,
      const ['storeId', 'store_id'],
    );
    final currentStore = await StoreRepository(_db).loadStore();
    if (backupStoreId != null &&
        currentStore != null &&
        backupStoreId != currentStore.id) {
      final ok = confirmStoreMismatch == null
          ? false
          : await confirmStoreMismatch(backupStoreId, currentStore.id);
      if (!ok) {
        throw const RestoreException('Restore cancelled (store mismatch)');
      }
    }

    final encryptedDb = Uint8List.fromList(dbFile.content as List<int>);
    final decrypted = await _decryptBackupDatabase(
      encryptedDb,
      requestPassphraseForUnlock: requestPassphraseForUnlock,
    );
    final checksum = BackupCrypto.checksumSha256(decrypted);
    final expected = manifest['checksum'] as String?;
    if (expected == null || checksum != expected) {
      throw const RestoreException('Backup integrity check failed');
    }

    // Pre-restore local safety backup.
    File? safetyFile;
    try {
      final safety = await buildPackage(
        storeId: currentStore?.id,
        storeName: currentStore?.businessName,
        fileName:
            'pre_restore_${DateTime.now().millisecondsSinceEpoch}.posbackup',
      );
      final dir = await _backupDir();
      safetyFile = File(p.join(dir.path, safety.fileName));
      await safetyFile.writeAsBytes(safety.bytes, flush: true);
    } catch (_) {
      // Continue; best-effort safety copy.
    }

    final livePath = _db.db.path;
    final previousBytes = await File(livePath).readAsBytes();
    await _db.close();
    try {
      await File(livePath).writeAsBytes(decrypted, flush: true);

      // Restore product photos + store logo (optional in older backups).
      final mediaFile = archive.findFile(mediaArchiveEntry);
      if (mediaFile != null) {
        try {
          final mediaEnc =
              Uint8List.fromList(mediaFile.content as List<int>);
          final mediaPlain = await crypto.decryptAuto(
            mediaEnc,
            createIfMissing: false,
          );
          final expectedMedia = manifest['mediaChecksum'] as String?;
          if (expectedMedia != null &&
              BackupCrypto.checksumSha256(mediaPlain) != expectedMedia) {
            throw const RestoreException('Media integrity check failed');
          }
          await _extractMediaArchive(mediaPlain);
          await _rewriteMediaPaths(livePath);
        } catch (_) {
          // Keep DB restore; images may be missing for this device.
          try {
            await _rewriteMediaPaths(livePath);
          } catch (_) {}
        }
      } else {
        try {
          await _rewriteMediaPaths(livePath);
        } catch (_) {}
      }

      if (afterClosed != null) {
        await afterClosed();
      }
    } catch (e) {
      try {
        await File(livePath).writeAsBytes(previousBytes, flush: true);
      } catch (_) {}
      throw RestoreException('Restore failed; previous database restored',
          cause: e);
    }
  }

  Future<List<BackupRecord>> history() async {
    final rows =
        await _db.db.query('backup_history', orderBy: 'created_at DESC');
    return rows.map(BackupRecord.fromMap).toList();
  }

  Future<BackupRecord?> get(int id) async {
    final rows =
        await _db.db.query('backup_history', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return BackupRecord.fromMap(rows.first);
  }

  Future<BackupRecord?> lastSuccessful() async {
    final rows = await _db.db.query(
      'backup_history',
      where: 'status = ?',
      whereArgs: ['successful'],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BackupRecord.fromMap(rows.first);
  }

  /// Deletes an older backup file + history row. The newest successful backup
  /// cannot be deleted.
  Future<void> deleteBackup(int id) async {
    final record = await get(id);
    if (record == null) return;

    final latest = await lastSuccessful();
    if (latest != null &&
        latest.id == record.id &&
        record.status == 'successful') {
      throw const BackupException(
        'Latest backup cannot be deleted. Keep at least one restore point.',
      );
    }

    final path = record.localPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await _db.db.delete(
      'backup_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Directory> localBackupDirectory() => _backupDir();

  Future<String> localBackupDirectoryPath() async {
    final dir = await _backupDir();
    return dir.path;
  }

  /// Ensures DEK envelope exists on Drive (prompts for passphrase if needed).
  Future<void> ensureDriveKeyEnvelope({
    required Future<String?> Function() requestPassphrase,
  }) async {
    if (drive == null || !await drive!.isSignedIn) return;
    await _ensureInternetForDrive();
    await _ensureDekEnvelope(() => requestPassphrase());
  }

  Future<bool> tryUnlockFromDriveEnvelope({
    required Future<String?> Function() requestPassphrase,
  }) async {
    if (drive == null || !await drive!.isSignedIn) return false;
    if (await crypto.hasLocalDek()) return true;
    final envelope = await drive!.downloadEnvelope();
    if (envelope == null) return false;
    final pass = await requestPassphrase();
    if (pass == null || pass.length < 8) return false;
    await crypto.unwrapDekWithPassphrase(envelope, pass);
    return true;
  }

  /// Decrypts [encryptedDb], unlocking the Drive DEK envelope when needed.
  ///
  /// Handles reinstall: a wrong/new local DEK is cleared and replaced from the
  /// passphrase envelope, then decrypt is retried once.
  Future<Uint8List> _decryptBackupDatabase(
    Uint8List encryptedDb, {
    Future<String?> Function()? requestPassphraseForUnlock,
  }) async {
    if (!await crypto.hasLocalDek()) {
      await _unlockFromDriveEnvelope(
        requestPassphraseForUnlock,
        required: true,
      );
    }

    try {
      return await crypto.decryptAuto(encryptedDb, createIfMissing: false);
    } on RestoreException {
      // Likely a DEK created on this install that does not match Drive backups.
      final retried = await _relockFromDriveEnvelope(requestPassphraseForUnlock);
      if (!retried) rethrow;
      return crypto.decryptAuto(encryptedDb, createIfMissing: false);
    }
  }

  Future<void> _unlockFromDriveEnvelope(
    Future<String?> Function()? requestPassphrase, {
    required bool required,
  }) async {
    if (drive == null || !await drive!.isSignedIn) {
      if (required) {
        throw const RestoreException(
          'Missing encryption key. Connect Google Drive and enter your recovery passphrase.',
        );
      }
      return;
    }

    final envelope = await drive!.downloadEnvelope();
    if (envelope == null) {
      if (required) {
        throw const RestoreException(
          'Recovery key not found on Google Drive. This backup cannot be unlocked.',
        );
      }
      return;
    }

    if (requestPassphrase == null) {
      if (required) {
        throw const RestoreException('Recovery passphrase required');
      }
      return;
    }

    final pass = await requestPassphrase();
    if (pass == null || pass.length < 8) {
      throw const RestoreException('Recovery passphrase required');
    }
    await crypto.unwrapDekWithPassphrase(envelope, pass);
  }

  /// Clears a wrong local DEK and unlocks again from Drive. Returns false if
  /// Drive/envelope/passphrase are unavailable.
  Future<bool> _relockFromDriveEnvelope(
    Future<String?> Function()? requestPassphrase,
  ) async {
    if (drive == null ||
        requestPassphrase == null ||
        !await drive!.isSignedIn) {
      return false;
    }
    final envelope = await drive!.downloadEnvelope();
    if (envelope == null) return false;

    final pass = await requestPassphrase();
    if (pass == null || pass.length < 8) return false;

    await crypto.clearLocalDek();
    await crypto.unwrapDekWithPassphrase(envelope, pass);
    return true;
  }

  Future<void> _ensureDekEnvelope(
    Future<String?> Function()? requestPassphrase,
  ) async {
    if (drive == null) return;
    final existing = await drive!.downloadEnvelope();
    if (existing != null) {
      if (!await crypto.hasLocalDek() && requestPassphrase != null) {
        final pass = await requestPassphrase();
        if (pass == null || pass.length < 8) {
          throw const BackupException('Recovery passphrase required');
        }
        await crypto.unwrapDekWithPassphrase(existing, pass);
      }
      return;
    }
    if (requestPassphrase == null) {
      throw const BackupException('Recovery passphrase required for Drive backup');
    }
    final pass = await requestPassphrase();
    if (pass == null || pass.length < 8) {
      throw const BackupException('Recovery passphrase required');
    }
    await crypto.getOrCreateDek();
    final envelope = await crypto.wrapDekWithPassphrase(pass);
    await drive!.uploadEnvelope(envelope);
  }

  Future<void> _ensureInternetForDrive() async {
    final ok = await connectivity.hasInternetAccess();
    if (!ok) {
      throw const BackupException('No internet connection for Drive backup');
    }
  }

  Future<bool> _verifyDriveUpload(String fileId, int expectedSize) async {
    if (fileId.isEmpty) return false;
    try {
      final bytes = await drive!.download(fileId);
      return bytes.length == expectedSize || bytes.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> _deviceId() async {
    final settings = SettingsRepository(_db);
    var id = await settings.get(SettingKeys.installId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await settings.set(SettingKeys.installId, id);
    }
    return id;
  }

  static int? _readInt(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
    }
    return null;
  }

  /// Public Downloads → `POS Billing/backup` when possible; otherwise app docs.
  Future<Directory> _backupDir() async {
    await _ensureStoragePermission();
    final preferred = await _publicDownloadsBackupDir();
    if (preferred != null) {
      try {
        if (!await preferred.exists()) {
          await preferred.create(recursive: true);
        }
        final probe = File(p.join(preferred.path, '.write_probe'));
        await probe.writeAsString('ok', flush: true);
        await probe.delete();
        return preferred;
      } catch (_) {
        // Fall through to private docs.
      }
    }

    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(root.path, folderAppName, folderBackupName),
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory?> _publicDownloadsBackupDir() async {
    if (!Platform.isAndroid) {
      final downloads = await getDownloadsDirectory();
      if (downloads == null) return null;
      return Directory(
        p.join(downloads.path, folderAppName, folderBackupName),
      );
    }

    final candidates = <String>[
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
    ];
    for (final base in candidates) {
      final root = Directory(base);
      if (await root.exists()) {
        return Directory(
          p.join(root.path, folderAppName, folderBackupName),
        );
      }
    }
    return null;
  }

  Future<void> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return;
    final status = await Permission.storage.status;
    if (status.isGranted || status.isLimited) return;
    if (status.isDenied || status.isRestricted) {
      await Permission.storage.request();
    }
  }

  /// Packs `product_images/` + `store_logos/` into a zip (or null if empty).
  Future<({Uint8List bytes, int count})?> _buildMediaArchiveBytes() async {
    final docs = await getApplicationDocumentsDirectory();
    final archive = Archive();
    var count = 0;
    for (final folder in [mediaFolderProduct, mediaFolderStore]) {
      final dir = Directory(p.join(docs.path, folder));
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (name.isEmpty || name.startsWith('.')) continue;
        try {
          final bytes = await entity.readAsBytes();
          if (bytes.isEmpty) continue;
          final entryName = '$folder/$name';
          archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
          count++;
        } catch (_) {
          // Skip unreadable files.
        }
      }
    }
    if (count == 0) return null;
    return (
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
      count: count,
    );
  }

  Future<void> _extractMediaArchive(Uint8List mediaZipBytes) async {
    final docs = await getApplicationDocumentsDirectory();
    final decoded = ZipDecoder().decodeBytes(mediaZipBytes);
    for (final file in decoded.files) {
      if (!file.isFile) continue;
      final name = file.name.replaceAll('\\', '/');
      if (name.contains('..')) continue;
      final parts = name.split('/');
      if (parts.length != 2) continue;
      final folder = parts[0];
      final basename = parts[1];
      if (folder != mediaFolderProduct && folder != mediaFolderStore) {
        continue;
      }
      if (basename.isEmpty || basename.startsWith('.')) continue;
      final dir = Directory(p.join(docs.path, folder));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final dest = File(p.join(dir.path, basename));
      final bytes = Uint8List.fromList(file.content as List<int>);
      if (bytes.isEmpty) continue;
      await dest.writeAsBytes(bytes, flush: true);
    }
  }

  /// Points DB image/logo paths at this device's documents folder by basename.
  Future<void> _rewriteMediaPaths(String dbPath) async {
    final docs = await getApplicationDocumentsDirectory();
    final productDir = p.join(docs.path, mediaFolderProduct);
    final storeDir = p.join(docs.path, mediaFolderStore);
    final db = await AppDatabase.open(path: dbPath);
    try {
      final products = await db.db.query(
        'products',
        columns: ['id', 'image_path'],
      );
      for (final row in products) {
        final id = row['id'] as int?;
        final oldPath = row['image_path'] as String?;
        if (id == null) continue;
        final next = _resolvedMediaPath(oldPath, productDir);
        if (next == oldPath) continue;
        await db.db.update(
          'products',
          {'image_path': next},
          where: 'id = ?',
          whereArgs: [id],
        );
      }

      final stores = await db.db.query(
        'stores',
        columns: ['id', 'logo_path'],
      );
      for (final row in stores) {
        final id = row['id'] as int?;
        final oldPath = row['logo_path'] as String?;
        if (id == null) continue;
        final next = _resolvedMediaPath(oldPath, storeDir);
        if (next == oldPath) continue;
        await db.db.update(
          'stores',
          {'logo_path': next},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } finally {
      await db.close();
    }
  }

  String? _resolvedMediaPath(String? oldPath, String folderPath) {
    if (oldPath == null || oldPath.trim().isEmpty) return null;
    final name = p.basename(oldPath.trim());
    if (name.isEmpty || name == '.' || name == '..') return null;
    final candidate = p.join(folderPath, name);
    if (File(candidate).existsSync()) return candidate;
    // File missing after restore — clear broken absolute path from old device.
    return null;
  }

  /// Best-effort wipe of local backup files (private + public folders).
  static Future<void> wipeLocalBackupFolders() async {
    final targets = <Directory>[];
    try {
      final docs = await getApplicationDocumentsDirectory();
      targets
        ..add(Directory(p.join(docs.path, 'backups')))
        ..add(
          Directory(p.join(docs.path, folderAppName, folderBackupName)),
        );
    } catch (_) {}
    for (final base in [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
    ]) {
      targets.add(
        Directory(p.join(base, folderAppName, folderBackupName)),
      );
    }
    for (final dir in targets) {
      try {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }
}
