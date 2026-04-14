import 'enums.dart';

class EvidenceCreate {
  const EvidenceCreate({
    required this.type,
    required this.url,
    required this.mimeType,
  });

  factory EvidenceCreate.fromJson(Map<String, dynamic> json) {
    return EvidenceCreate(
      type: EvidenceType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => EvidenceType.photo,
      ),
      url: json['url'] as String,
      mimeType: json['mime_type'] as String,
    );
  }

  final EvidenceType type;
  final String url;
  final String mimeType;

  Map<String, dynamic> toJson() => {
        'type': type.value,
        'url': url,
        'mime_type': mimeType,
      };
}

class EvidenceResponse {
  const EvidenceResponse({
    required this.id,
    required this.reportId,
    required this.type,
    required this.url,
    required this.mimeType,
    required this.createdAt,
  });

  factory EvidenceResponse.fromJson(Map<String, dynamic> json) {
    return EvidenceResponse(
      id: json['id'].toString(),
      reportId: (json['report_id'] ?? '').toString(),
      type: EvidenceType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => EvidenceType.image,
      ),
      url: (json['url'] ?? '') as String,
      mimeType: (json['mime_type'] ?? 'image/jpeg') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String reportId;
  final EvidenceType type;
  final String url;
  final String mimeType;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'report_id': reportId,
        'type': type.value,
        'url': url,
        'mime_type': mimeType,
        'created_at': createdAt.toIso8601String(),
      };
}
