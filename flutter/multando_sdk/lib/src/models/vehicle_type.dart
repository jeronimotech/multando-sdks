class VehicleTypeResponse {
  const VehicleTypeResponse({
    required this.id,
    required this.code,
    required this.nameEn,
    required this.nameEs,
    this.icon,
    this.platePattern,
    this.requiresPlate = true,
  });

  factory VehicleTypeResponse.fromJson(Map<String, dynamic> json) {
    return VehicleTypeResponse(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? json['name'] as String? ?? '',
      nameEs: json['name_es'] as String? ?? json['name'] as String? ?? '',
      icon: json['icon'] as String?,
      platePattern: json['plate_pattern'] as String?,
      requiresPlate: json['requires_plate'] as bool? ?? true,
    );
  }

  final int id;
  final String code;
  final String nameEn;
  final String nameEs;
  final String? icon;
  final String? platePattern;
  final bool requiresPlate;

  /// Convenience getter for localized name.
  String name({String locale = 'en'}) => locale == 'es' ? nameEs : nameEn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name_en': nameEn,
        'name_es': nameEs,
        if (icon != null) 'icon': icon,
        if (platePattern != null) 'plate_pattern': platePattern,
        'requires_plate': requiresPlate,
      };
}
