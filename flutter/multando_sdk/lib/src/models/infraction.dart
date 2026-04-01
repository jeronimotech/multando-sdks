import 'enums.dart';

class InfractionResponse {
  const InfractionResponse({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameEs,
    required this.descriptionEn,
    required this.descriptionEs,
    required this.category,
    required this.severity,
    required this.pointsReward,
    this.multaReward,
    this.icon,
  });

  factory InfractionResponse.fromJson(Map<String, dynamic> json) {
    return InfractionResponse(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      nameEs: json['name_es'] as String? ?? json['name'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? json['description'] as String? ?? '',
      descriptionEs: json['description_es'] as String? ?? json['description'] as String? ?? '',
      category: InfractionCategory.values.firstWhere(
        (e) => e.value == json['category'],
        orElse: () => InfractionCategory.other,
      ),
      severity: InfractionSeverity.values.firstWhere(
        (e) => e.value == json['severity'],
        orElse: () => InfractionSeverity.low,
      ),
      pointsReward: json['points_reward'] as int? ?? json['base_points'] as int? ?? 0,
      multaReward: _parseDouble(json['multa_reward'] ?? json['fine_amount']),
      icon: json['icon'] as String?,
    );
  }

  final int id;
  final String code;
  final String nameEn;
  final String nameEs;
  final String descriptionEn;
  final String descriptionEs;
  final InfractionCategory category;
  final InfractionSeverity severity;
  final int pointsReward;
  final double? multaReward;
  final String? icon;

  /// Convenience getter for localized name.
  String name({String locale = 'en'}) => locale == 'es' ? nameEs : nameEn;
  String description({String locale = 'en'}) => locale == 'es' ? descriptionEs : descriptionEn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name_en': nameEn,
        'name_es': nameEs,
        'description_en': descriptionEn,
        'description_es': descriptionEs,
        'category': category.value,
        'severity': severity.value,
        'points_reward': pointsReward,
        if (multaReward != null) 'multa_reward': multaReward,
        if (icon != null) 'icon': icon,
      };
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
