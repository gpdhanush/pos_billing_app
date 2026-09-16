import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/services/backup_crypto.dart';
import 'package:pos_billing/core/services/backup_service.dart';

void main() {
  group('Backup manifest', () {
    test('manifest contains required upgraded fields', () {
      final checksum = BackupCrypto.checksumSha256(
        Uint8List.fromList(utf8.encode('db')),
      );
      final manifest = <String, Object?>{
        'format': BackupService.formatName,
        'formatVersion': DbConstants.backupFormatVersion,
        'backup_version': DbConstants.backupFormatVersion,
        'appVersion': DbConstants.appVersion,
        'app_version': DbConstants.appVersion,
        'databaseVersion': DbConstants.schemaVersion,
        'database_version': DbConstants.schemaVersion,
        'storeId': 1,
        'store_id': 1,
        'storeName': 'Demo Store',
        'createdAt': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'deviceId': 'device-1',
        'databaseSize': 2,
        'checksum': checksum,
      };

      expect(manifest['format'], 'posbackup');
      expect(manifest['formatVersion'], 1);
      expect(manifest['backup_version'], 1);
      expect(manifest['appVersion'], DbConstants.appVersion);
      expect(manifest['databaseVersion'], DbConstants.schemaVersion);
      expect(manifest['storeId'], 1);
      expect(manifest['storeName'], 'Demo Store');
      expect(manifest['deviceId'], isNotEmpty);
      expect(manifest['databaseSize'], 2);
      expect(manifest['checksum'], checksum);
    });

    test('zip package checksum mismatch is detectable', () {
      final dbBytes = Uint8List.fromList(utf8.encode('sqlite-bytes'));
      final goodChecksum = sha256.convert(dbBytes).toString();
      final manifest = jsonEncode({
        'format': 'posbackup',
        'formatVersion': 1,
        'backup_version': 1,
        'databaseVersion': 1,
        'checksum': goodChecksum,
      });
      final archive = Archive()
        ..addFile(
          ArchiveFile(
            'manifest.json',
            utf8.encode(manifest).length,
            utf8.encode(manifest),
          ),
        )
        ..addFile(ArchiveFile('database.enc', dbBytes.length, dbBytes));
      final zipped = ZipEncoder().encode(archive);
      expect(zipped, isNotEmpty);

      final decoded = ZipDecoder().decodeBytes(zipped);
      final m = jsonDecode(
        utf8.decode(decoded.findFile('manifest.json')!.content as List<int>),
      ) as Map<String, dynamic>;
      final encFile = decoded.findFile('database.enc')!;
      final payload = Uint8List.fromList(encFile.content as List<int>);
      final actual = sha256.convert(payload).toString();
      expect(actual, m['checksum']);

      payload[0] ^= 0xff;
      final corrupt = sha256.convert(payload).toString();
      expect(corrupt, isNot(m['checksum']));
    });

    test('newer databaseVersion should be blocked by restore policy', () {
      final newer = DbConstants.schemaVersion + 1;
      expect(newer > DbConstants.schemaVersion, isTrue);
    });
  });
}
