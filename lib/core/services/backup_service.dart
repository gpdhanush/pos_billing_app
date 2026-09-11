import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/store_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart';
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/models.dart';

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
  Future<void> signIn();
  Future<void> signOut();
  Future<String> upload({required String fileName, required Uint8List bytes});
  Future<Uint8List> download(String fileId);
}

class BackupService {
  BackupService(this._db, {required this.secureStorage, this.drive});

  final AppDatabase _db;
  final FlutterSecureStorage secureStorage;
  final DriveBackupClient? drive;

  static const _keyName = 'pos_backup_aes_key';

  Future<BackupRecord> createBackup({bool uploadToDrive = false}) async {
    final store = await StoreRepository(_db).loadStore();
    final stamp = DateTime.now();
    final fileName =
        'backup_${stamp.year.toString().padLeft(4, '0')}-${stamp.month.toString().padLeft(2, '0')}-${stamp.day.toString().padLeft(2, '0')}_${stamp.hour.toString().padLeft(2, '0')}${stamp.minute.toString().padLeft(2, '0')}${stamp.second.toString().padLeft(2, '0')}.posbak';
    final historyId = await _db.db.insert('backup_history', {
      'file_name': fileName,
      'backup_version': DbConstants.backupFormatVersion,
      'database_version': DbConstants.schemaVersion,
      'status': 'in_progress',
      'created_at': nowMillis(),
    });

    try {
      final pkg = await buildPackage(storeId: store?.id, fileName: fileName);
      final dir = await _backupDir();
      final localFile = File(p.join(dir.path, fileName));
      await localFile.writeAsBytes(pkg.bytes, flush: true);

      String? driveId;
      if (uploadToDrive && drive != null && await drive!.isSignedIn) {
        driveId = await drive!.upload(fileName: fileName, bytes: pkg.bytes);
      }

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

  Future<BackupPackage> buildPackage({int? storeId, required String fileName}) async {
    try {
      await _db.db.execute('PRAGMA wal_checkpoint(FULL)');
    } catch (_) {}
    final dbPath = _db.db.path;
    final dbBytes = await File(dbPath).readAsBytes();
    final checksum = sha256.convert(dbBytes).toString();
    final encrypted = await _encrypt(dbBytes);
    final manifest = <String, Object?>{
      'backup_version': DbConstants.backupFormatVersion,
      'database_version': DbConstants.schemaVersion,
      'app_version': DbConstants.appVersion,
      'created_at': DateTime.now().toIso8601String(),
      'store_id': storeId,
      'checksum': checksum,
      'file_name': fileName,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    final archive = Archive()
      ..addFile(ArchiveFile('manifest.json', manifestBytes.length, manifestBytes))
      ..addFile(ArchiveFile('database.enc', encrypted.length, encrypted));
    final zipped = ZipEncoder().encode(archive);
    return BackupPackage(
      bytes: Uint8List.fromList(zipped),
      fileName: fileName,
      checksum: checksum,
      manifest: manifest,
    );
  }

  Future<void> restoreFromFile(String path, {Future<void> Function()? afterClosed}) async {
    final bytes = await File(path).readAsBytes();
    await restoreFromBytes(bytes, afterClosed: afterClosed);
  }

  Future<void> restoreFromBytes(
    Uint8List bytes, {
    Future<void> Function()? afterClosed,
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
        jsonDecode(utf8.decode(manifestFile.content as List<int>)) as Map<String, dynamic>;
    final version = manifest['backup_version'] as int? ?? 0;
    if (version > DbConstants.backupFormatVersion) {
      throw const RestoreException('This backup was created by a newer app version');
    }
    final decrypted = await _decrypt(Uint8List.fromList(dbFile.content as List<int>));
    final checksum = sha256.convert(decrypted).toString();
    if (checksum != manifest['checksum']) {
      throw const RestoreException('Backup integrity check failed');
    }

    await createBackup(uploadToDrive: false);

    final livePath = _db.db.path;
    await _db.close();
    await File(livePath).writeAsBytes(decrypted, flush: true);
    if (afterClosed != null) {
      await afterClosed();
    }
  }

  Future<List<BackupRecord>> history() async {
    final rows = await _db.db.query('backup_history', orderBy: 'created_at DESC');
    return rows.map(BackupRecord.fromMap).toList();
  }

  Future<BackupRecord?> get(int id) async {
    final rows = await _db.db.query('backup_history', where: 'id = ?', whereArgs: [id]);
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

  Future<Directory> _backupDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(root.path, 'backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<enc.Key> _key() async {
    var stored = await secureStorage.read(key: _keyName);
    if (stored == null) {
      stored = base64Encode(enc.Key.fromSecureRandom(32).bytes);
      await secureStorage.write(key: _keyName, value: stored);
    }
    return enc.Key.fromBase64(stored);
  }

  Future<Uint8List> _encrypt(Uint8List data) async {
    final key = await _key();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(data, iv: iv);
    return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
  }

  Future<Uint8List> _decrypt(Uint8List data) async {
    if (data.length < 17) throw const RestoreException('Backup is corrupted');
    final key = await _key();
    final iv = enc.IV(data.sublist(0, 16));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(enc.Encrypted(data.sublist(16)), iv: iv);
    return Uint8List.fromList(decrypted);
  }
}
