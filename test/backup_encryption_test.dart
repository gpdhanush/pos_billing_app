import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_billing/core/services/backup_crypto.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('BackupCrypto', () {
    test('AES-GCM encrypt/decrypt roundtrip', () async {
      final crypto = BackupCrypto(const FlutterSecureStorage());
      final plain = Uint8List.fromList(
        utf8.encode('pos-sqlite-bytes-${List.filled(200, 'x').join()}'),
      );
      final encrypted = await crypto.encryptGcm(plain);
      expect(encrypted.length, greaterThan(plain.length));
      final decrypted = await crypto.decryptAuto(encrypted);
      expect(decrypted, plain);
    });

    test('checksum is stable sha256', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final a = BackupCrypto.checksumSha256(bytes);
      final b = BackupCrypto.checksumSha256(bytes);
      expect(a, b);
      expect(a.length, 64);
      expect(
        BackupCrypto.checksumSha256(Uint8List.fromList([1, 2, 3, 4, 6])),
        isNot(a),
      );
    });

    test('corrupt ciphertext is detected', () async {
      final crypto = BackupCrypto(const FlutterSecureStorage());
      final plain = Uint8List.fromList(utf8.encode('integrity-check'));
      final encrypted = await crypto.encryptGcm(plain);
      encrypted[encrypted.length - 1] ^= 0xff;
      expect(
        () => crypto.decryptAuto(encrypted),
        throwsA(anything),
      );
    });

    test('legacy CBC payload still decrypts', () async {
      final crypto = BackupCrypto(const FlutterSecureStorage());
      final dek = await crypto.getOrCreateDek();
      final plain = Uint8List.fromList(utf8.encode('legacy-cbc-backup'));

      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(dek, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(plain, iv: iv);
      final payload = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);

      final decrypted = await crypto.decryptAuto(payload);
      expect(utf8.decode(decrypted), 'legacy-cbc-backup');
    });

    test('passphrase envelope wrap/unwrap', () async {
      final crypto = BackupCrypto(const FlutterSecureStorage());
      await crypto.getOrCreateDek();
      final envelope = await crypto.wrapDekWithPassphrase('secret-pass');
      expect(utf8.decode(envelope.sublist(0, 7)), 'POSDEK1');

      FlutterSecureStorage.setMockInitialValues({});
      final other = BackupCrypto(const FlutterSecureStorage());
      await other.unwrapDekWithPassphrase(envelope, 'secret-pass');
      final plain = Uint8List.fromList([9, 8, 7, 6]);
      final encrypted = await crypto.encryptGcm(plain);
      final round = await other.decryptAuto(encrypted);
      expect(round, plain);
    });

    test('wrong passphrase fails unwrap', () async {
      final crypto = BackupCrypto(const FlutterSecureStorage());
      await crypto.getOrCreateDek();
      final envelope = await crypto.wrapDekWithPassphrase('correct-one');
      FlutterSecureStorage.setMockInitialValues({});
      final other = BackupCrypto(const FlutterSecureStorage());
      expect(
        () => other.unwrapDekWithPassphrase(envelope, 'wrong-pass'),
        throwsA(anything),
      );
    });

    test('PBKDF2 KEK is deterministic', () {
      final salt = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final a = BackupCrypto.deriveKek('passphrase!', salt);
      final b = BackupCrypto.deriveKek('passphrase!', salt);
      expect(a, b);
      expect(a.length, 32);
      expect(BackupCrypto.deriveKek('other', salt), isNot(a));
    });
  });
}
