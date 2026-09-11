import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class PinService {
  PinService(this._storage, {LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const _hashKey = 'pos_pin_hash';
  static const _saltKey = 'pos_pin_salt';

  Future<bool> hasPin() async => (await _storage.read(key: _hashKey)) != null;

  Future<void> setPin(String pin) async {
    final salt = base64Encode(
      List<int>.generate(
        16,
        (i) => (DateTime.now().microsecondsSinceEpoch + i * 31) & 0xff,
      ),
    );
    final hash = sha256.convert(utf8.encode('$salt:$pin')).toString();
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final hash = await _storage.read(key: _hashKey);
    if (salt == null || hash == null) return false;
    return sha256.convert(utf8.encode('$salt:$pin')).toString() == hash;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _hashKey);
    await _storage.delete(key: _saltKey);
  }

  Future<bool> biometricAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final types = await _localAuth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric({
    String reason = 'Unlock POS Billing',
  }) async {
    try {
      final available = await biometricAvailable();
      if (!available) return false;
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
