import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';
import 'package:pos_billing/core/errors/app_exception.dart';

/// AES-256-GCM DEK management + passphrase envelope for cross-device restore.
class BackupCrypto {
  BackupCrypto(this.secureStorage);

  final FlutterSecureStorage secureStorage;

  static const dekStorageKey = 'pos_backup_dek_v1';
  static const legacyKeyName = 'pos_backup_aes_key';
  static const envelopeMagic = 'POSDEK1';
  static const pbkdf2Iterations = 100000;
  static const saltLength = 16;
  static const gcmNonceLength = 12;
  static const gcmTagBits = 128;

  /// Returns (or creates) the 32-byte data encryption key.
  Future<enc.Key> getOrCreateDek() async {
    var stored = await secureStorage.read(key: dekStorageKey);
    if (stored == null || stored.isEmpty) {
      // Migrate legacy CBC key if present so old local backups still decrypt.
      final legacy = await secureStorage.read(key: legacyKeyName);
      if (legacy != null && legacy.isNotEmpty) {
        stored = legacy;
        await secureStorage.write(key: dekStorageKey, value: stored);
      } else {
        stored = base64Encode(enc.Key.fromSecureRandom(32).bytes);
        await secureStorage.write(key: dekStorageKey, value: stored);
      }
    }
    return enc.Key.fromBase64(stored);
  }

  Future<void> storeDek(Uint8List dekBytes) async {
    if (dekBytes.length != 32) {
      throw const BackupException('Invalid backup key length');
    }
    await secureStorage.write(
      key: dekStorageKey,
      value: base64Encode(dekBytes),
    );
  }

  Future<bool> hasLocalDek() async {
    final v = await secureStorage.read(key: dekStorageKey);
    if (v != null && v.isNotEmpty) return true;
    final legacy = await secureStorage.read(key: legacyKeyName);
    return legacy != null && legacy.isNotEmpty;
  }

  /// Reads the stored DEK without creating one.
  Future<enc.Key?> readDek() async {
    var stored = await secureStorage.read(key: dekStorageKey);
    if (stored == null || stored.isEmpty) {
      stored = await secureStorage.read(key: legacyKeyName);
    }
    if (stored == null || stored.isEmpty) return null;
    try {
      return enc.Key.fromBase64(stored);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLocalDek() async {
    await secureStorage.delete(key: dekStorageKey);
    await secureStorage.delete(key: legacyKeyName);
  }

  /// Encrypts database bytes: `nonce || ciphertext+tag` (AES-256-GCM).
  Future<Uint8List> encryptGcm(Uint8List plaintext, {enc.Key? key}) async {
    final dek = key ?? await getOrCreateDek();
    final nonce = enc.IV.fromSecureRandom(gcmNonceLength);
    // Do not pass padding:null — that uses processBlock and skips the GCM tag.
    final encrypter = enc.Encrypter(enc.AES(dek, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(plaintext, iv: nonce);
    return Uint8List.fromList([...nonce.bytes, ...encrypted.bytes]);
  }

  /// Decrypts GCM payload; falls back to legacy CBC (`iv16 || ciphertext`).
  ///
  /// When [createIfMissing] is false (restore path), never invents a new DEK —
  /// a missing or wrong key must surface as a decrypt/key error, not "success"
  /// with garbage from a freshly generated key.
  Future<Uint8List> decryptAuto(
    Uint8List data, {
    enc.Key? key,
    bool createIfMissing = true,
  }) async {
    if (data.length < 17) {
      throw const RestoreException('Backup is corrupted');
    }
    final enc.Key dek;
    if (key != null) {
      dek = key;
    } else if (createIfMissing) {
      dek = await getOrCreateDek();
    } else {
      final existing = await readDek();
      if (existing == null) {
        throw const RestoreException('Missing encryption key');
      }
      dek = existing;
    }
    try {
      return _decryptGcm(data, dek);
    } catch (_) {
      try {
        return _decryptCbcLegacy(data, dek);
      } catch (e) {
        throw RestoreException(
          'Could not decrypt backup. Check your recovery passphrase.',
          cause: e,
        );
      }
    }
  }

  Uint8List _decryptGcm(Uint8List data, enc.Key dek) {
    if (data.length < gcmNonceLength + 16) {
      throw const RestoreException('Backup is corrupted');
    }
    final nonce = enc.IV(data.sublist(0, gcmNonceLength));
    final body = data.sublist(gcmNonceLength);
    final encrypter = enc.Encrypter(enc.AES(dek, mode: enc.AESMode.gcm));
    final decrypted =
        encrypter.decryptBytes(enc.Encrypted(body), iv: nonce);
    return Uint8List.fromList(decrypted);
  }

  Uint8List _decryptCbcLegacy(Uint8List data, enc.Key dek) {
    final iv = enc.IV(data.sublist(0, 16));
    final encrypter = enc.Encrypter(enc.AES(dek, mode: enc.AESMode.cbc));
    final decrypted =
        encrypter.decryptBytes(enc.Encrypted(data.sublist(16)), iv: iv);
    return Uint8List.fromList(decrypted);
  }

  /// Builds `pos_dek_envelope.v1`: magic | salt | nonce | gcm(KEK, DEK).
  Future<Uint8List> wrapDekWithPassphrase(String passphrase) async {
    if (passphrase.length < 8) {
      throw const BackupException('Recovery passphrase must be at least 8 characters');
    }
    final dek = await getOrCreateDek();
    final salt = _randomBytes(saltLength);
    final kekBytes = deriveKek(passphrase, salt);
    final kek = enc.Key(kekBytes);
    final nonce = enc.IV.fromSecureRandom(gcmNonceLength);
    final encrypter = enc.Encrypter(enc.AES(kek, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(dek.bytes, iv: nonce);
    final magic = utf8.encode(envelopeMagic);
    return Uint8List.fromList([
      ...magic,
      ...salt,
      ...nonce.bytes,
      ...encrypted.bytes,
    ]);
  }

  /// Unwraps envelope and stores DEK locally.
  Future<void> unwrapDekWithPassphrase(
    Uint8List envelope,
    String passphrase,
  ) async {
    if (passphrase.length < 8) {
      throw const RestoreException('Recovery passphrase must be at least 8 characters');
    }
    final magic = utf8.encode(envelopeMagic);
    if (envelope.length < magic.length + saltLength + gcmNonceLength + 16) {
      throw const RestoreException('Invalid key envelope');
    }
    for (var i = 0; i < magic.length; i++) {
      if (envelope[i] != magic[i]) {
        throw const RestoreException('Invalid key envelope');
      }
    }
    var offset = magic.length;
    final salt = envelope.sublist(offset, offset + saltLength);
    offset += saltLength;
    final nonce = enc.IV(envelope.sublist(offset, offset + gcmNonceLength));
    offset += gcmNonceLength;
    final body = envelope.sublist(offset);
    final kek = enc.Key(deriveKek(passphrase, salt));
    final encrypter = enc.Encrypter(enc.AES(kek, mode: enc.AESMode.gcm));
    try {
      final dekBytes =
          encrypter.decryptBytes(enc.Encrypted(body), iv: nonce);
      await storeDek(Uint8List.fromList(dekBytes));
    } catch (e) {
      throw RestoreException('Incorrect recovery passphrase', cause: e);
    }
  }

  /// PBKDF2-HMAC-SHA256(passphrase, salt, 100000, 32).
  static Uint8List deriveKek(String passphrase, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, pbkdf2Iterations, 32));
    final out = Uint8List(32);
    final pwd = Uint8List.fromList(utf8.encode(passphrase));
    derivator.deriveKey(pwd, 0, out, 0);
    return out;
  }

  static String checksumSha256(Uint8List bytes) =>
      sha256.convert(bytes).toString();

  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
}
