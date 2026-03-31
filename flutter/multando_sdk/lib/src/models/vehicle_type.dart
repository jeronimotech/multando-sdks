import 'enums.dart';

class VehicleTypeResponse {
  const VehicleTypeResponse({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    required this.isActive,
  });

  factory VehicleTypeResponse.fromJson(Map<String, dynamic> json) {
    return VehicleTypeResponse(
      id: json['id'] as String,
      name: json['name'] as String,
      category: VehicleCategory.values.firstWhere(
        (e) => e.value == json['category'],
        orElse: () => VehicleCategory.other,
      ),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  final String id;
  final String name;
  final VehicleCategory category;
  final String? description;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.value,
        if (description != null) 'description': description,
        'is_active': isActive,
      };
}
