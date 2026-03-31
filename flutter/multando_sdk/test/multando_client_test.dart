import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multando_sdk/multando_sdk.dart';

void main() {
  group('MultandoClient', () {
    late MultandoClient client;
    late Directory tempDir;

    setUp(() async {
      client = MultandoClient();
      tempDir = await Directory.systemTemp.createTemp('multando_test_');
    });

    tearDown(() async {
      await client.dispose();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('isInitialized returns false before initialize()', () {
      expect(client.isInitialized, isFalse);
    });

    test('initialize sets isInitialized to true', () async {
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
        ),
        hivePath: tempDir.path,
      );

      expect(client.isInitialized, isTrue);
    });

    test('initialize is idempotent', () async {
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
        ),
        hivePath: tempDir.path,
      );

      // Second call should not throw.
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.different.io',
          apiKey: 'other-key',
        ),
        hivePath: tempDir.path,
      );

      expect(client.isInitialized, isTrue);
    });

    test('service accessors throw before initialize()', () {
      expect(() => client.auth, throwsA(isA<StateError>()));
      expect(() => client.reports, throwsA(isA<StateError>()));
      expect(() => client.evidence, throwsA(isA<StateError>()));
      expect(() => client.infractions, throwsA(isA<StateError>()));
      expect(() => client.vehicleTypes, throwsA(isA<StateError>()));
      expect(() => client.verification, throwsA(isA<StateError>()));
      expect(() => client.blockchain, throwsA(isA<StateError>()));
    });

    test('service accessors return non-null after initialize()', () async {
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
        ),
        hivePath: tempDir.path,
      );

      expect(client.auth, isNotNull);
      expect(client.reports, isNotNull);
      expect(client.evidence, isNotNull);
      expect(client.infractions, isNotNull);
      expect(client.vehicleTypes, isNotNull);
      expect(client.verification, isNotNull);
      expect(client.blockchain, isNotNull);
    });

    test('isAuthenticated is false when freshly initialized', () async {
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
        ),
        hivePath: tempDir.path,
      );

      expect(client.isAuthenticated, isFalse);
    });

    test('currentUser is null when freshly initialized', () async {
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
        ),
        hivePath: tempDir.path,
      );

      expect(client.currentUser, isNull);
    });

    test('offlineQueueCount is 0 when freshly initialized', () async {
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
          enableOfflineQueue: true,
        ),
        hivePath: tempDir.path,
      );

      expect(client.offlineQueueCount, equals(0));
    });

    test('dispose resets isInitialized to false', () async {
      await client.initialize(
        const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
        ),
        hivePath: tempDir.path,
      );
      expect(client.isInitialized, isTrue);

      await client.dispose();
      expect(client.isInitialized, isFalse);
    });

    test('dispose is safe to call when not initialized', () async {
      // Should not throw.
      await client.dispose();
      expect(client.isInitialized, isFalse);
    });
  });
}
