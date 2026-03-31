import 'enums.dart';

class InfractionResponse {
  const InfractionResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.severity,
    required this.basePoints,
    this.fineAmount,
    required this.isActive,
  });

  factory InfractionResponse.fromJson(Map<String, dynamic> json) {
    return InfractionResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      category: InfractionCategory.values.firstWhere(
        (e) => e.value == json['category'],
        orElse: () => InfractionCategory.other,
      ),
      severity: InfractionSeverity.values.firstWhere(
        (e) => e.value == json['severity'],
        orElse: () => InfractionSeverity.low,
      ),
      basePoints: json['base_points'] as int,
      fineAmount: (json['fine_amount'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String name;
  final String description;
  final InfractionCategory category;
  final InfractionSeverity severity;
  final int basePoints;
  final double? fineAmount;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'category': category.value,
        'severity': severity.value,
        'base_points': basePoints,
        if (fineAmount != null) 'fine_amount': fineAmount,
        'is_active': isActive,
      };
}
