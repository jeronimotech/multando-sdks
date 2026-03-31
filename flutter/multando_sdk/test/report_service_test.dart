import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multando_sdk/multando_sdk.dart';
import 'package:multando_sdk/src/core/http_client.dart';
import 'package:multando_sdk/src/core/auth_manager.dart';

/// A [HttpClientAdapter] that returns canned responses for testing.
class _MockAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> _handlers = {};

  void onGet(String path, ResponseBody Function(RequestOptions) handler) {
    _handlers['GET:$path'] = handler;
  }

  void onPost(String path, ResponseBody Function(RequestOptions) handler) {
    _handlers['POST:$path'] = handler;
  }

  void onDelete(String path, ResponseBody Function(RequestOptions) handler) {
    _handlers['DELETE:$path'] = handler;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method}:${options.path}';
    // Try exact match first, then prefix match for parameterized paths.
    final handler = _handlers[key] ??
        _handlers.entries
            .where((e) => key.startsWith(e.key))
            .map((e) => e.value)
            .firstOrNull;
    if (handler != null) {
      return handler(options);
    }
    return ResponseBody.fromString(
      jsonEncode({'detail': 'Not Found'}),
      404,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonBody(dynamic data, {int status = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  group('ReportService', () {
    late Dio dio;
    late _MockAdapter adapter;
    late ReportService service;

    final sampleReportDetail = {
      'id': 'rpt-001',
      'infraction_id': 'inf-123',
      'plate_number': 'ABC1234',
      'location': {
        'latitude': 40.4168,
        'longitude': -3.7038,
        'address': 'Test Street',
      },
      'status': 'submitted',
      'source': 'sdk',
      'reporter_id': 'user-001',
      'created_at': '2025-01-15T10:00:00Z',
      'evidence': [],
    };

    final sampleReportList = {
      'items': [
        {
          'id': 'rpt-001',
          'infraction_id': 'inf-123',
          'plate_number': 'ABC1234',
          'status': 'submitted',
          'source': 'sdk',
          'created_at': '2025-01-15T10:00:00Z',
        },
      ],
      'total': 1,
      'page': 1,
      'page_size': 20,
      'total_pages': 1,
    };

    setUp(() {
      adapter = _MockAdapter();
      dio = Dio(BaseOptions(
        baseUrl: 'https://api.test.multando.io/api/v1',
      ));
      dio.httpClientAdapter = adapter;

      // Create a minimal MultandoHttpClient with the dio instance injected.
      // Since we need the _http field, we create a ReportService directly.
      final httpClient = MultandoHttpClient(
        config: const MultandoConfig(
          baseUrl: 'https://api.test.multando.io',
          apiKey: 'test-key',
        ),
        authManager: AuthManager(),
      );
      // Override the internal dio with our mock adapter.
      httpClient.dio.httpClientAdapter = adapter;

      service = ReportService(httpClient: httpClient);
    });

    test('create() sends POST /reports and returns ReportDetail', () async {
      adapter.onPost('/reports', (_) => _jsonBody(sampleReportDetail));

      final report = ReportCreate(
        infractionId: 'inf-123',
        plateNumber: 'ABC1234',
        location: const LocationData(latitude: 40.4168, longitude: -3.7038),
      );

      final result = await service.create(report);
      expect(result, isNotNull);
      expect(result!.id, equals('rpt-001'));
      expect(result.plateNumber, equals('ABC1234'));
      expect(result.status, equals(ReportStatus.submitted));
    });

    test('list() sends GET /reports and returns ReportList', () async {
      adapter.onGet('/reports', (_) => _jsonBody(sampleReportList));

      final result = await service.list();
      expect(result.items, hasLength(1));
      expect(result.total, equals(1));
      expect(result.page, equals(1));
      expect(result.items.first.plateNumber, equals('ABC1234'));
    });

    test('list() sends pagination parameters', () async {
      adapter.onGet('/reports', (options) {
        expect(options.queryParameters['page'], equals(2));
        expect(options.queryParameters['page_size'], equals(10));
        return _jsonBody(sampleReportList);
      });

      await service.list(page: 2, pageSize: 10);
    });

    test('getById() sends GET /reports/:id and returns ReportDetail', () async {
      adapter.onGet('/reports/rpt-001', (_) => _jsonBody(sampleReportDetail));

      final result = await service.getById('rpt-001');
      expect(result.id, equals('rpt-001'));
      expect(result.infractionId, equals('inf-123'));
    });

    test('delete() sends DELETE /reports/:id', () async {
      var deleteCalled = false;
      adapter.onDelete('/reports/rpt-001', (_) {
        deleteCalled = true;
        return _jsonBody({'ok': true});
      });

      await service.delete('rpt-001');
      expect(deleteCalled, isTrue);
    });
  });
}
