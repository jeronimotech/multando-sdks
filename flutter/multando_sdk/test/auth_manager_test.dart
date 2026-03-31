import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:multando_sdk/multando_sdk.dart';
import 'package:multando_sdk/src/core/auth_manager.dart';

/// In-memory implementation of FlutterSecureStorage for testing.
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  group('AuthManager', () {
    late _FakeSecureStorage storage;
    late AuthManager authManager;

    setUp(() {
      storage = _FakeSecureStorage();
      authManager = AuthManager(storage: storage);
    });

    tearDown(() {
      authManager.dispose();
    });

    test('isAuthenticated is false initially', () {
      expect(authManager.isAuthenticated, isFalse);
      expect(authManager.accessToken, isNull);
      expect(authManager.refreshToken, isNull);
    });

    test('saveTokens stores tokens and marks as authenticated', () async {
      const response = TokenResponse(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      await authManager.saveTokens(response);

      expect(authManager.isAuthenticated, isTrue);
      expect(authManager.accessToken, equals('access-123'));
      expect(authManager.refreshToken, equals('refresh-456'));
    });

    test('clearTokens removes tokens and marks as unauthenticated', () async {
      const response = TokenResponse(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      await authManager.saveTokens(response);
      expect(authManager.isAuthenticated, isTrue);

      await authManager.clearTokens();
      expect(authManager.isAuthenticated, isFalse);
      expect(authManager.accessToken, isNull);
      expect(authManager.refreshToken, isNull);
    });

    test('authStateStream emits true on saveTokens and false on clearTokens',
        () async {
      final states = <bool>[];
      final sub = authManager.authStateStream.listen(states.add);

      const response = TokenResponse(
        accessToken: 'access-123',
        refreshToken: 'refresh-456',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      await authManager.saveTokens(response);
      await authManager.clearTokens();

      // Allow microtasks to complete.
      await Future<void>.delayed(Duration.zero);

      expect(states, contains(true));
      expect(states.last, isFalse);

      await sub.cancel();
    });

    test('loadTokens restores persisted tokens', () async {
      // First, save some tokens.
      const response = TokenResponse(
        accessToken: 'persisted-access',
        refreshToken: 'persisted-refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );
      await authManager.saveTokens(response);

      // Create a new AuthManager with the same storage.
      final newManager = AuthManager(storage: storage);
      addTearDown(() => newManager.dispose());

      await newManager.loadTokens();

      expect(newManager.accessToken, equals('persisted-access'));
      expect(newManager.refreshToken, equals('persisted-refresh'));
      expect(newManager.isAuthenticated, isTrue);
    });

    test('shouldRefresh returns false when no token exists', () {
      expect(authManager.shouldRefresh(), isFalse);
    });

    test('shouldRefresh returns false when token is fresh', () async {
      const response = TokenResponse(
        accessToken: 'access',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
        expiresIn: 3600, // 1 hour
      );
      await authManager.saveTokens(response);

      expect(authManager.shouldRefresh(), isFalse);
    });

    test('refreshIfNeeded does nothing when token is fresh', () async {
      const response = TokenResponse(
        accessToken: 'access',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );
      await authManager.saveTokens(response);

      var refreshCalled = false;
      final result = await authManager.refreshIfNeeded((_) async {
        refreshCalled = true;
        return null;
      });

      expect(refreshCalled, isFalse);
      expect(result, equals('access'));
    });

    test('refreshIfNeeded calls doRefresh when token is about to expire',
        () async {
      const response = TokenResponse(
        accessToken: 'expiring-access',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
        expiresIn: 30, // expires in 30 seconds (within the 60s buffer)
      );
      await authManager.saveTokens(response);

      const newResponse = TokenResponse(
        accessToken: 'new-access',
        refreshToken: 'new-refresh',
        tokenType: 'Bearer',
        expiresIn: 3600,
      );

      final result = await authManager.refreshIfNeeded((_) async {
        return newResponse;
      });

      expect(result, equals('new-access'));
      expect(authManager.accessToken, equals('new-access'));
    });

    test('refreshIfNeeded clears tokens when refresh fails', () async {
      const response = TokenResponse(
        accessToken: 'expiring-access',
        refreshToken: 'refresh',
        tokenType: 'Bearer',
        expiresIn: 30,
      );
      await authManager.saveTokens(response);

      final result = await authManager.refreshIfNeeded((_) async {
        throw Exception('Refresh failed');
      });

      expect(result, isNull);
      expect(authManager.isAuthenticated, isFalse);
    });
  });
}
