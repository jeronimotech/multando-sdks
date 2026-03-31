import 'package:json_annotation/json_annotation.dart';

import 'enums.dart';

part 'vehicle_type.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class VehicleTypeResponse {
  const VehicleTypeResponse({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.isActive,
  });

  factory VehicleTypeResponse.fromJson(Map<String, dynamic> json) =>
      _$VehicleTypeResponseFromJson(json);

  final String id;
  final String name;
  final VehicleCategory category;
  final String? description;
  @JsonKey(name: 'is_active')
  final bool isActive;

  Map<String, dynamic> toJson() => _$VehicleTypeResponseToJson(this);
}
