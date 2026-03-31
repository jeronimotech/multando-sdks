import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'infraction.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
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

  factory InfractionResponse.fromJson(Map<String, dynamic> json) =>
      _$InfractionResponseFromJson(json);

  final String id;
  final String name;
  final String description;
  final InfractionCategory category;
  final InfractionSeverity severity;
  @JsonKey(name: 'base_points')
  final int basePoints;
  @JsonKey(name: 'fine_amount')
  final double? fineAmount;
  @JsonKey(name: 'is_active')
  final bool isActive;

  Map<String, dynamic> toJson() => _$InfractionResponseToJson(this);
}
