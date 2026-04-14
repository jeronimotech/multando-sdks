/// Safely parse a value that may be num or String to double.
double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

/// Safely parse a value that may be num or String to int.
int _toInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.phoneNumber,
    this.walletAddress,
    this.avatarUrl,
    this.points = 0,
    required this.isVerified,
    this.reputationScore,
    required this.createdAt,
    this.totalReportsCount = 0,
    this.rejectedReportsCount,
    this.rejectionRate,
    this.rejectionRateWarning = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      walletAddress: json['wallet_address'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      points: _toInt(json['points']),
      isVerified: json['is_verified'] as bool? ?? false,
      reputationScore: _toDouble(json['reputation_score']),
      createdAt: DateTime.parse(json['created_at'] as String),
      totalReportsCount: _toInt(json['total_reports_count']),
      rejectedReportsCount: json['rejected_reports_count'] == null
          ? null
          : _toInt(json['rejected_reports_count']),
      rejectionRate: _toDouble(json['rejection_rate']),
      rejectionRateWarning:
          json['rejection_rate_warning'] as bool? ?? false,
    );
  }

  final String id;
  final String email;
  final String username;
  final String displayName;
  final String? phoneNumber;
  final String? walletAddress;
  final String? avatarUrl;
  final int points;
  final bool isVerified;
  final double? reputationScore;
  final DateTime createdAt;

  /// Total number of reports submitted by this user (lifetime).
  final int totalReportsCount;

  /// Number of those reports that were rejected. `null` if the backend
  /// did not include it (e.g. privacy-stripped public endpoint).
  final int? rejectedReportsCount;

  /// Fraction in `[0.0, 1.0]` — rejected / total. `null` when unknown.
  final double? rejectionRate;

  /// Server-computed flag: `true` when [rejectionRate] exceeds the
  /// responsible-reporting threshold (currently 30%). UIs should nudge
  /// the reporter toward the principles page when this is set.
  final bool rejectionRateWarning;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'display_name': displayName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (walletAddress != null) 'wallet_address': walletAddress,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'points': points,
        'is_verified': isVerified,
        if (reputationScore != null) 'reputation_score': reputationScore,
        'created_at': createdAt.toIso8601String(),
        'total_reports_count': totalReportsCount,
        if (rejectedReportsCount != null)
          'rejected_reports_count': rejectedReportsCount,
        if (rejectionRate != null) 'rejection_rate': rejectionRate,
        'rejection_rate_warning': rejectionRateWarning,
      };
}

class UserPublic {
  const UserPublic({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.points = 0,
    this.reputationScore,
  });

  factory UserPublic.fromJson(Map<String, dynamic> json) {
    return UserPublic(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: _toInt(json['points']),
      reputationScore: _toDouble(json['reputation_score']),
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int points;
  final double? reputationScore;

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'points': points,
        if (reputationScore != null) 'reputation_score': reputationScore,
      };
}
