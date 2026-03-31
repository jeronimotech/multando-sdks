import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';
import 'evidence.dart';

part 'report.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory LocationData.fromJson(Map<String, dynamic> json) =>
      _$LocationDataFromJson(json);

  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  @JsonKey(name: 'postal_code')
  final String? postalCode;

  Map<String, dynamic> toJson() => _$LocationDataToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ReportCreate {
  const ReportCreate({
    required this.infractionId,
    required this.plateNumber,
    required this.location,
    this.vehicleTypeId,
    this.description,
    this.occurredAt,
    this.source = ReportSource.sdk,
  });

  factory ReportCreate.fromJson(Map<String, dynamic> json) =>
      _$ReportCreateFromJson(json);

  @JsonKey(name: 'infraction_id')
  final String infractionId;
  @JsonKey(name: 'plate_number')
  final String plateNumber;
  final LocationData location;
  @JsonKey(name: 'vehicle_type_id')
  final String? vehicleTypeId;
  final String? description;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  final ReportSource source;

  Map<String, dynamic> toJson() => _$ReportCreateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
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
  });

  factory ReportDetail.fromJson(Map<String, dynamic> json) =>
      _$ReportDetailFromJson(json);

  final String id;
  @JsonKey(name: 'infraction_id')
  final String infractionId;
  @JsonKey(name: 'plate_number')
  final String plateNumber;
  final LocationData location;
  final ReportStatus status;
  final ReportSource source;
  @JsonKey(name: 'reporter_id')
  final String reporterId;
  @JsonKey(name: 'vehicle_type_id')
  final String? vehicleTypeId;
  final String? description;
  @JsonKey(name: 'occurred_at')
  final DateTime? occurredAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<EvidenceResponse> evidence;
  @JsonKey(name: 'verification_count')
  final int? verificationCount;
  @JsonKey(name: 'rejection_count')
  final int? rejectionCount;

  Map<String, dynamic> toJson() => _$ReportDetailToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ReportSummary {
  const ReportSummary({
    required this.id,
    required this.infractionId,
    required this.plateNumber,
    required this.status,
    required this.source,
    required this.createdAt,
    this.description,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) =>
      _$ReportSummaryFromJson(json);

  final String id;
  @JsonKey(name: 'infraction_id')
  final String infractionId;
  @JsonKey(name: 'plate_number')
  final String plateNumber;
  final ReportStatus status;
  final ReportSource source;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  final String? description;

  Map<String, dynamic> toJson() => _$ReportSummaryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ReportList {
  const ReportList({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory ReportList.fromJson(Map<String, dynamic> json) =>
      _$ReportListFromJson(json);

  final List<ReportSummary> items;
  final int total;
  final int page;
  @JsonKey(name: 'page_size')
  final int pageSize;
  @JsonKey(name: 'total_pages')
  final int totalPages;

  Map<String, dynamic> toJson() => _$ReportListToJson(this);
}
