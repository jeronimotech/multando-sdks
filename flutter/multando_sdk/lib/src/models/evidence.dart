import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'evidence.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EvidenceCreate {
  const EvidenceCreate({
    required this.type,
    required this.url,
    required this.mimeType,
  });

  factory EvidenceCreate.fromJson(Map<String, dynamic> json) =>
      _$EvidenceCreateFromJson(json);

  final EvidenceType type;
  final String url;
  @JsonKey(name: 'mime_type')
  final String mimeType;

  Map<String, dynamic> toJson() => _$EvidenceCreateToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class EvidenceResponse {
  const EvidenceResponse({
    required this.id,
    required this.reportId,
    required this.type,
    required this.url,
    required this.mimeType,
    required this.createdAt,
  });

  factory EvidenceResponse.fromJson(Map<String, dynamic> json) =>
      _$EvidenceResponseFromJson(json);

  final String id;
  @JsonKey(name: 'report_id')
  final String reportId;
  final EvidenceType type;
  final String url;
  @JsonKey(name: 'mime_type')
  final String mimeType;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$EvidenceResponseToJson(this);
}
