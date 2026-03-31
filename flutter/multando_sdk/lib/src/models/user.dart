import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    this.walletAddress,
    required this.isActive,
    required this.isVerified,
    required this.createdAt,
    this.updatedAt,
    this.reportsCount,
    this.verifiedReportsCount,
    this.reputationScore,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  final String id;
  final String email;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  @JsonKey(name: 'wallet_address')
  final String? walletAddress;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_verified')
  final bool isVerified;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'reports_count')
  final int? reportsCount;
  @JsonKey(name: 'verified_reports_count')
  final int? verifiedReportsCount;
  @JsonKey(name: 'reputation_score')
  final double? reputationScore;

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UserPublic {
  const UserPublic({
    required this.id,
    required this.fullName,
    this.reputationScore,
    this.verifiedReportsCount,
  });

  factory UserPublic.fromJson(Map<String, dynamic> json) =>
      _$UserPublicFromJson(json);

  final String id;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'reputation_score')
  final double? reputationScore;
  @JsonKey(name: 'verified_reports_count')
  final int? verifiedReportsCount;

  Map<String, dynamic> toJson() => _$UserPublicToJson(this);
}
