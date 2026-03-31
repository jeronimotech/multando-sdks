import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth.dart';

/// Manages access / refresh tokens, persists them in secure storage,
/// and exposes an authentication state stream.
class AuthManager {
  AuthManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'multando_access_token';
  static const _refreshTokenKey = 'multando_refresh_token';
  static const _expiresAtKey = 'multando_expires_at';

  final FlutterSecureStorage _storage;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  bool _refreshing = false;
  Completer<String?>? _refreshCompleter;

  final StreamController<bool> _authStateController =
      StreamController<bool>.broadcast();

  /// Stream that emits `true` when authenticated and `false` when logged out.
  Stream<bool> get authStateStream => _authStateController.stream;

  /// Whether a valid (non-expired) access token is currently held.
  bool get isAuthenticated =>
      _accessToken != null &&
      _expiresAt != null &&
      _expiresAt!.isAfter(DateTime.now());

  /// Current access token, or `null`.
  String? get accessToken => _accessToken;

  /// Current refresh token, or `null`.
  String? get refreshToken => _refreshToken;

  /// Load tokens from secure storage. Call once at SDK initialisation.
  Future<void> loadTokens() async {
    _accessToken = await _storage.read(key: _accessTokenKey);
    _refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresStr = await _storage.read(key: _expiresAtKey);
    if (expiresStr != null) {
      _expiresAt = DateTime.tryParse(expiresStr);
    }
    _authStateController.add(isAuthenticated);
  }

  /// Persist a new token pair from a [TokenResponse].
  Future<void> saveTokens(TokenResponse response) async {
    _accessToken = response.accessToken;
    _refreshToken = response.refreshToken;
    _expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: _accessToken),
      _storage.write(key: _refreshTokenKey, value: _refreshToken),
      _storage.write(key: _expiresAtKey, value: _expiresAt!.toIso8601String()),
    ]);
    _authStateController.add(true);
  }

  /// Clear all stored tokens (logout).
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
    ]);
    _authStateController.add(false);
  }

  /// Returns `true` when the access token will expire within the given
  /// [buffer] (default 60 s). Used to trigger proactive refresh.
  bool shouldRefresh({Duration buffer = const Duration(seconds: 60)}) {
    if (_expiresAt == null || _accessToken == null) return false;
    return _expiresAt!.isBefore(DateTime.now().add(buffer));
  }

  /// Ensures only one refresh request is in-flight at a time.
  /// [doRefresh] is the actual HTTP call, provided by the caller.
  /// Returns the new access token, or `null` on failure.
  Future<String?> refreshIfNeeded(
    Future<TokenResponse?> Function(String refreshToken) doRefresh,
  ) async {
    if (!shouldRefresh()) return _accessToken;
    if (_refreshToken == null) return null;

    if (_refreshing) {
      return _refreshCompleter?.future;
    }

    _refreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final response = await doRefresh(_refreshToken!);
      if (response != null) {
        await saveTokens(response);
        _refreshCompleter!.complete(_accessToken);
      } else {
        await clearTokens();
        _refreshCompleter!.complete(null);
      }
    } catch (_) {
      await clearTokens();
      _refreshCompleter!.complete(null);
    } finally {
      _refreshing = false;
    }

    return _refreshCompleter!.future;
  }

  /// Release resources.
  void dispose() {
    _authStateController.close();
  }
}
