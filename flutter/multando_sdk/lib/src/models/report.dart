import 'enums.dart';
import 'evidence.dart';

class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['lat'] as num? ?? json['latitude'] as num).toDouble(),
      longitude: (json['lon'] as num? ?? json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      postalCode: json['postal_code'] as String?,
    );
  }

  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lon': longitude,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (country != null) 'country': country,
      };
}

class ReportCreate {
  const ReportCreate({
    required this.infractionId,
    required this.plateNumber,
    required this.location,
    this.vehicleTypeId,
    this.description,
    this.occurredAt,
    this.source = ReportSource.sdk,
    this.evidenceImageBase64,
    this.evidenceMediaType,
    this.evidenceImageHash,
    this.evidenceSignature,
    this.evidenceTimestamp,
    this.evidenceDeviceId,
    this.evidenceCaptureMethod,
  });

  factory ReportCreate.fromJson(Map<String, dynamic> json) {
    return ReportCreate(
      infractionId: json['infraction_id'] as String,
      plateNumber: json['plate_number'] as String,
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      vehicleTypeId: json['vehicle_type_id'] as String?,
      description: json['description'] as String?,
      occurredAt: json['occurred_at'] != null
          ? DateTime.parse(json['occurred_at'] as String)
          : null,
      source: ReportSource.values.firstWhere(
        (e) => e.value == json['source'],
        orElse: () => ReportSource.sdk,
      ),
      evidenceImageBase64: json['evidence_image_base64'] as String?,
      evidenceMediaType: json['evidence_media_type'] as String?,
      evidenceImageHash: json['evidence_image_hash'] as String?,
      evidenceSignature: json['evidence_signature'] as String?,
      evidenceTimestamp: json['evidence_timestamp'] as String?,
      evidenceDeviceId: json['evidence_device_id'] as String?,
      evidenceCaptureMethod: json['evidence_capture_method'] as String?,
    );
  }

  final String infractionId;
  final String plateNumber;
  final LocationData location;
  final String? vehicleTypeId;
  final String? description;
  final DateTime? occurredAt;
  final ReportSource source;

  /// Optional signed evidence fields
  final String? evidenceImageBase64;
  final String? evidenceMediaType;
  final String? evidenceImageHash;
  final String? evidenceSignature;
  final String? evidenceTimestamp;
  final String? evidenceDeviceId;
  final String? evidenceCaptureMethod;

  Map<String, dynamic> toJson() => {
        'infraction_id': int.tryParse(infractionId) ?? infractionId,
        'vehicle_plate': plateNumber,
        'location': location.toJson(),
        if (vehicleTypeId != null && int.tryParse(vehicleTypeId!) != null)
          'vehicle_type_id': int.parse(vehicleTypeId!),
        'incident_datetime': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
        'source': source.value,
        if (evidenceImageBase64 != null) 'evidence_image_base64': evidenceImageBase64,
        if (evidenceMediaType != null) 'evidence_media_type': evidenceMediaType,
        if (evidenceImageHash != null) 'evidence_image_hash': evidenceImageHash,
        if (evidenceSignature != null) 'evidence_signature': evidenceSignature,
        if (evidenceTimestamp != null) 'evidence_timestamp': evidenceTimestamp,
        if (evidenceDeviceId != null) 'evidence_device_id': evidenceDeviceId,
        if (evidenceCaptureMethod != null) 'evidence_capture_method': evidenceCaptureMethod,
      };
}

class ReportDetail {
  const ReportDetail({
    required this.id,
    required this.infractionId,
    required this.plateNumber,
    required this.location,
    required this.status,
    required this.source,
    required this.reporterId,
    this.vehicleTypeId,
    this.description,
    this.occurredAt,
    required this.createdAt,
    this.updatedAt,
    this.evidence = const [],
    this.verificationCount,
    this.rejectionCount,
    this.reporterDisplayName,
  });

  factory ReportDetail.fromJson(Map<String, dynamic> json) {
    return ReportDetail(
      id: json['id'].toString(),
      infractionId: (json['infraction_id'] ?? '').toString(),
      plateNumber: (json['vehicle_plate'] ?? json['plate_number'] ?? '') as String,
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      status: ReportStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => ReportStatus.draft,
      ),
      source: ReportSource.values.firstWhere(
        (e) => e.value == json['source'],
        orElse: () => ReportSource.mobile,
      ),
      reporterId: (json['reporter_id'] ?? '').toString(),
      vehicleTypeId: json['vehicle_type_id']?.toString(),
      description: json['description'] as String?,
      occurredAt: json['incident_datetime'] != null
          ? DateTime.parse(json['incident_datetime'] as String)
          : json['occurred_at'] != null
              ? DateTime.parse(json['occurred_at'] as String)
              : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      evidence: (json['evidences'] ?? json['evidence']) != null
          ? ((json['evidences'] ?? json['evidence']) as List)
              .map((e) =>
                  EvidenceResponse.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      verificationCount: json['verification_count'] as int?,
      rejectionCount: json['rejection_count'] as int?,
      reporterDisplayName: json['reporter_display_name'] as String?,
    );
  }

  final String id;
  final String infractionId;
  final String plateNumber;
  final LocationData location;
  final ReportStatus status;
  final ReportSource source;
  final String reporterId;
  final String? vehicleTypeId;
  final String? description;
  final DateTime? occurredAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<EvidenceResponse> evidence;
  final int? verificationCount;
  final int? rejectionCount;

  /// Anonymized display label shown in lieu of a reporter reference when
  /// the API omits / nulls [reporterId] (e.g. "Community reporter").
  /// Reporter identity is never exposed to the reported party.
  final String? reporterDisplayName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'infraction_id': infractionId,
        'plate_number': plateNumber,
        'location': location.toJson(),
        'status': status.value,
        'source': source.value,
        'reporter_id': reporterId,
        if (vehicleTypeId != null) 'vehicle_type_id': vehicleTypeId,
        if (description != null) 'description': description,
        if (occurredAt != null) 'occurred_at': occurredAt!.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
        'evidence': evidence.map((e) => e.toJson()).toList(),
        if (verificationCount != null) 'verification_count': verificationCount,
        if (rejectionCount != null) 'rejection_count': rejectionCount,
        if (reporterDisplayName != null)
          'reporter_display_name': reporterDisplayName,
      };
}

class ReportSummary {
  const ReportSummary({
    required this.id,
    required this.infractionId,
    required this.plateNumber,
    required this.status,
    required this.source,
    required this.createdAt,
    this.description,
    this.location,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      id: json['id'].toString(),
      infractionId: (json['infraction_id'] ?? '').toString(),
      plateNumber: (json['vehicle_plate'] ?? json['plate_number'] ?? '') as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => ReportStatus.draft,
      ),
      source: ReportSource.values.firstWhere(
        (e) => e.value == json['source'],
        orElse: () => ReportSource.mobile,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      location: json['location'] != null
          ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final String infractionId;
  final String plateNumber;
  final ReportStatus status;
  final ReportSource source;
  final DateTime createdAt;
  final String? description;
  final LocationData? location;

  Map<String, dynamic> toJson() => {
        'id': id,
        'infraction_id': infractionId,
        'plate_number': plateNumber,
        'status': status.value,
        'source': source.value,
        'created_at': createdAt.toIso8601String(),
        if (description != null) 'description': description,
      };
}

class ReportList {
  const ReportList({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ReportList.fromJson(Map<String, dynamic> json) {
    final total = json['total'] as int? ?? 0;
    final pageSize = json['page_size'] as int? ?? 20;
    final totalPages = json['total_pages'] as int?
        ?? json['pages'] as int?
        ?? (pageSize > 0 ? (total + pageSize - 1) ~/ pageSize : 0);
    return ReportList(
      items: (json['items'] as List? ?? [])
          .map((e) => ReportSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      page: json['page'] as int? ?? 1,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  final List<ReportSummary> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
        'page': page,
        'page_size': pageSize,
        'total_pages': totalPages,
      };
}
