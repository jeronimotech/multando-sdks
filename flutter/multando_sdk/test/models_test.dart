import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multando_sdk/multando_sdk.dart';

void main() {
  group('ReportCreate', () {
    test('serializes to JSON with snake_case keys', () {
      const report = ReportCreate(
        infractionId: 'inf-001',
        plateNumber: 'ABC1234',
        location: LocationData(
          latitude: 40.4168,
          longitude: -3.7038,
          address: '123 Main St',
        ),
        description: 'Illegal parking',
      );

      final json = report.toJson();

      expect(json['infraction_id'], equals('inf-001'));
      expect(json['plate_number'], equals('ABC1234'));
      expect(json['location']['latitude'], equals(40.4168));
      expect(json['location']['address'], equals('123 Main St'));
      expect(json['description'], equals('Illegal parking'));
      expect(json['source'], equals('sdk'));
    });

    test('deserializes from JSON with snake_case keys', () {
      final json = {
        'infraction_id': 'inf-002',
        'plate_number': 'XYZ5678',
        'location': {
          'latitude': 19.4326,
          'longitude': -99.1332,
        },
        'source': 'sdk',
      };

      final report = ReportCreate.fromJson(json);

      expect(report.infractionId, equals('inf-002'));
      expect(report.plateNumber, equals('XYZ5678'));
      expect(report.location.latitude, equals(19.4326));
      expect(report.source, equals(ReportSource.sdk));
    });

    test('round-trips through JSON encoding and decoding', () {
      const original = ReportCreate(
        infractionId: 'inf-003',
        plateNumber: 'TEST9999',
        location: LocationData(
          latitude: 51.5074,
          longitude: -0.1278,
          city: 'London',
          country: 'UK',
        ),
        vehicleTypeId: 'vt-car',
        description: 'Red light violation',
      );

      final jsonString = jsonEncode(original.toJson());
      final decoded = ReportCreate.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(decoded.infractionId, equals(original.infractionId));
      expect(decoded.plateNumber, equals(original.plateNumber));
      expect(decoded.location.latitude, equals(original.location.latitude));
      expect(decoded.location.city, equals('London'));
      expect(decoded.vehicleTypeId, equals('vt-car'));
    });
  });

  group('ReportDetail', () {
    test('deserializes from full JSON payload', () {
      final json = {
        'id': 'rpt-100',
        'infraction_id': 'inf-001',
        'plate_number': 'ABC1234',
        'location': {
          'latitude': 40.4168,
          'longitude': -3.7038,
          'address': '123 Main St',
          'city': 'Madrid',
          'state': 'Madrid',
          'country': 'Spain',
          'postal_code': '28013',
        },
        'status': 'verified',
        'source': 'sdk',
        'reporter_id': 'user-001',
        'vehicle_type_id': 'vt-car',
        'description': 'Double parked',
        'occurred_at': '2025-01-15T10:30:00Z',
        'created_at': '2025-01-15T10:35:00Z',
        'updated_at': '2025-01-15T11:00:00Z',
        'evidence': [],
        'verification_count': 3,
        'rejection_count': 0,
      };

      final detail = ReportDetail.fromJson(json);

      expect(detail.id, equals('rpt-100'));
      expect(detail.status, equals(ReportStatus.verified));
      expect(detail.location.postalCode, equals('28013'));
      expect(detail.location.city, equals('Madrid'));
      expect(detail.verificationCount, equals(3));
      expect(detail.rejectionCount, equals(0));
      expect(detail.evidence, isEmpty);
    });

    test('serializes back to JSON correctly', () {
      final detail = ReportDetail(
        id: 'rpt-200',
        infractionId: 'inf-002',
        plateNumber: 'XYZ5678',
        location: const LocationData(latitude: 0, longitude: 0),
        status: ReportStatus.rejected,
        source: ReportSource.sdk,
        reporterId: 'user-002',
        createdAt: DateTime.utc(2025, 3, 1),
      );

      final json = detail.toJson();

      expect(json['id'], equals('rpt-200'));
      expect(json['status'], equals('rejected'));
      expect(json['source'], equals('sdk'));
      expect(json['reporter_id'], equals('user-002'));
    });
  });

  group('ReportSummary', () {
    test('deserializes from JSON', () {
      final json = {
        'id': 'rpt-300',
        'infraction_id': 'inf-003',
        'plate_number': 'DEF4567',
        'status': 'under_review',
        'source': 'mobile_app',
        'created_at': '2025-06-01T08:00:00Z',
        'description': 'Running stop sign',
      };

      final summary = ReportSummary.fromJson(json);

      expect(summary.id, equals('rpt-300'));
      expect(summary.status, equals(ReportStatus.underReview));
      expect(summary.source, equals(ReportSource.mobileApp));
      expect(summary.description, equals('Running stop sign'));
    });
  });

  group('LocationData', () {
    test('handles optional fields', () {
      final json = {
        'latitude': 10.0,
        'longitude': 20.0,
      };

      final loc = LocationData.fromJson(json);

      expect(loc.latitude, equals(10.0));
      expect(loc.longitude, equals(20.0));
      expect(loc.address, isNull);
      expect(loc.city, isNull);
      expect(loc.state, isNull);
      expect(loc.country, isNull);
      expect(loc.postalCode, isNull);
    });

    test('includes all fields when present', () {
      const loc = LocationData(
        latitude: 48.8566,
        longitude: 2.3522,
        address: 'Champs-Elysees',
        city: 'Paris',
        state: 'Ile-de-France',
        country: 'France',
        postalCode: '75008',
      );

      final json = loc.toJson();

      expect(json['latitude'], equals(48.8566));
      expect(json['address'], equals('Champs-Elysees'));
      expect(json['postal_code'], equals('75008'));
    });
  });

  group('ReportList', () {
    test('deserializes paginated response', () {
      final json = {
        'items': [
          {
            'id': 'rpt-a',
            'infraction_id': 'inf-1',
            'plate_number': 'AAA111',
            'status': 'draft',
            'source': 'sdk',
            'created_at': '2025-01-01T00:00:00Z',
          },
          {
            'id': 'rpt-b',
            'infraction_id': 'inf-2',
            'plate_number': 'BBB222',
            'status': 'submitted',
            'source': 'web',
            'created_at': '2025-01-02T00:00:00Z',
          },
        ],
        'total': 25,
        'page': 2,
        'page_size': 10,
        'total_pages': 3,
      };

      final list = ReportList.fromJson(json);

      expect(list.items, hasLength(2));
      expect(list.total, equals(25));
      expect(list.page, equals(2));
      expect(list.pageSize, equals(10));
      expect(list.totalPages, equals(3));
      expect(list.items.first.plateNumber, equals('AAA111'));
      expect(list.items.last.status, equals(ReportStatus.submitted));
    });
  });

  group('Enums', () {
    test('ReportStatus values map correctly', () {
      expect(ReportStatus.draft.value, equals('draft'));
      expect(ReportStatus.underReview.value, equals('under_review'));
      expect(ReportStatus.verified.value, equals('verified'));
      expect(ReportStatus.rejected.value, equals('rejected'));
    });

    test('ReportSource values map correctly', () {
      expect(ReportSource.sdk.value, equals('sdk'));
      expect(ReportSource.mobileApp.value, equals('mobile_app'));
      expect(ReportSource.web.value, equals('web'));
      expect(ReportSource.api.value, equals('api'));
    });

    test('InfractionSeverity values map correctly', () {
      expect(InfractionSeverity.low.value, equals('low'));
      expect(InfractionSeverity.medium.value, equals('medium'));
      expect(InfractionSeverity.high.value, equals('high'));
      expect(InfractionSeverity.critical.value, equals('critical'));
    });

    test('InfractionCategory values map correctly', () {
      expect(InfractionCategory.parking.value, equals('parking'));
      expect(InfractionCategory.speeding.value, equals('speeding'));
      expect(InfractionCategory.redLight.value, equals('red_light'));
      expect(InfractionCategory.dui.value, equals('dui'));
    });
  });
}
