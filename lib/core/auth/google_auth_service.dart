import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:pos_billing/core/errors/app_exception.dart';

/// Persisted Google account profile (no OAuth tokens in SQLite).
class GoogleAccountSession {
  const GoogleAccountSession({
    required this.googleUserId,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.lastAuthAt,
  });

  final String googleUserId;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime lastAuthAt;

  GoogleAccountSession copyWith({
    String? googleUserId,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? lastAuthAt,
  }) {
    return GoogleAccountSession(
      googleUserId: googleUserId ?? this.googleUserId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastAuthAt: lastAuthAt ?? this.lastAuthAt,
    );
  }
}

/// Google Sign-In with Drive appDataFolder scope only.
class GoogleAuthService {
  GoogleAuthService({
    required FlutterSecureStorage secureStorage,
    GoogleSignIn? signIn,
  })  : _storage = secureStorage,
        _signIn = signIn ??
            GoogleSignIn(
              scopes: const [drive.DriveApi.driveAppdataScope],
            );

  final FlutterSecureStorage _storage;
  final GoogleSignIn _signIn;

  static const _kUserId = 'google_user_id';
  static const _kEmail = 'google_email';
  static const _kDisplayName = 'google_display_name';
  static const _kPhotoUrl = 'google_photo_url';
  static const _kLastAuthAt = 'google_last_auth_at';

  /// Exposed for Drive client auth headers.
  GoogleSignIn get googleSignIn => _signIn;

  GoogleSignInAccount? get currentUser => _signIn.currentUser;

  Future<GoogleAccountSession?> get session async {
    final id = await _storage.read(key: _kUserId);
    final email = await _storage.read(key: _kEmail);
    if (id == null || email == null || id.isEmpty || email.isEmpty) {
      return null;
    }
    final lastRaw = await _storage.read(key: _kLastAuthAt);
    return GoogleAccountSession(
      googleUserId: id,
      email: email,
      displayName: await _storage.read(key: _kDisplayName),
      photoUrl: await _storage.read(key: _kPhotoUrl),
      lastAuthAt: DateTime.tryParse(lastRaw ?? '') ?? DateTime.now(),
    );
  }

  Future<bool> get isSignedIn async {
    if (_signIn.currentUser != null) return true;
    try {
      final account = await _signIn.signInSilently();
      if (account != null) {
        await _persist(account);
        return true;
      }
    } catch (_) {}
    // Stored profile alone is not enough — Drive API needs a live session.
    return _signIn.currentUser != null;
  }

  Future<GoogleAccountSession> signIn() async {
    try {
      final account = await _signIn.signIn();
      if (account == null) {
        throw const DriveAuthException('Google Drive sign-in was cancelled');
      }
      return await _persist(account);
    } catch (e) {
      if (e is DriveAuthException) rethrow;
      throw DriveAuthException('Google Drive sign-in failed', cause: e);
    }
  }

  /// Silent restore; never throws for missing session.
  /// Returns a session only when Google Sign-In has a live account
  /// (auth headers available for Drive). Falls back to stored profile
  /// metadata only when [allowCachedProfile] is true for UI display.
  Future<GoogleAccountSession?> restoreSilently({
    bool allowCachedProfile = false,
  }) async {
    try {
      final account = await _signIn.signInSilently();
      if (account != null) {
        return await _persist(account);
      }
    } catch (_) {}
    if (allowCachedProfile) return session;
    return _signIn.currentUser == null ? null : session;
  }

  Future<void> signOut() async {
    try {
      await _signIn.signOut();
    } catch (_) {}
    await _clearStored();
  }

  Future<GoogleAccountSession> _persist(GoogleSignInAccount account) async {
    final now = DateTime.now();
    await _storage.write(key: _kUserId, value: account.id);
    await _storage.write(key: _kEmail, value: account.email);
    await _storage.write(key: _kDisplayName, value: account.displayName ?? '');
    await _storage.write(key: _kPhotoUrl, value: account.photoUrl ?? '');
    await _storage.write(key: _kLastAuthAt, value: now.toIso8601String());
    return GoogleAccountSession(
      googleUserId: account.id,
      email: account.email,
      displayName: account.displayName,
      photoUrl: account.photoUrl,
      lastAuthAt: now,
    );
  }

  Future<void> _clearStored() async {
    await _storage.delete(key: _kUserId);
    await _storage.delete(key: _kEmail);
    await _storage.delete(key: _kDisplayName);
    await _storage.delete(key: _kPhotoUrl);
    await _storage.delete(key: _kLastAuthAt);
  }
}
