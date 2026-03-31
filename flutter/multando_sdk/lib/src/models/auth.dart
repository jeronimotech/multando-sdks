import 'package:json_annotation/json_annotation.dart';

part 'auth.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  final String email;
  final String password;
  @JsonKey(name: 'full_name')
  final String fullName;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  final String email;
  final String password;

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseFromJson(json);

  @JsonKey(name: 'access_token')
  final String accessToken;
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @JsonKey(name: 'token_type')
  final String tokenType;
  @JsonKey(name: 'expires_in')
  final int expiresIn;

  Map<String, dynamic> toJson() => _$TokenResponseToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RefreshRequest {
  const RefreshRequest({
    required this.refreshToken,
  });

  factory RefreshRequest.fromJson(Map<String, dynamic> json) =>
      _$RefreshRequestFromJson(json);

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  Map<String, dynamic> toJson() => _$RefreshRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class WalletLinkRequest {
  const WalletLinkRequest({
    required this.walletAddress,
    required this.signature,
  });

  factory WalletLinkRequest.fromJson(Map<String, dynamic> json) =>
      _$WalletLinkRequestFromJson(json);

  @JsonKey(name: 'wallet_address')
  final String walletAddress;
  final String signature;

  Map<String, dynamic> toJson() => _$WalletLinkRequestToJson(this);
}
