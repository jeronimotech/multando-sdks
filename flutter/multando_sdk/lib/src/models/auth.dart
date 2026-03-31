class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.username,
    required this.displayName,
    this.phoneNumber,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  final String email;
  final String password;
  final String username;
  final String displayName;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'username': username,
        'display_name': displayName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };
}

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'token_type': tokenType,
        'expires_in': expiresIn,
      };
}

class RefreshRequest {
  const RefreshRequest({
    required this.refreshToken,
  });

  factory RefreshRequest.fromJson(Map<String, dynamic> json) {
    return RefreshRequest(
      refreshToken: json['refresh_token'] as String,
    );
  }

  final String refreshToken;

  Map<String, dynamic> toJson() => {
        'refresh_token': refreshToken,
      };
}

class WalletLinkRequest {
  const WalletLinkRequest({
    required this.walletAddress,
    required this.signature,
  });

  factory WalletLinkRequest.fromJson(Map<String, dynamic> json) {
    return WalletLinkRequest(
      walletAddress: json['wallet_address'] as String,
      signature: json['signature'] as String,
    );
  }

  final String walletAddress;
  final String signature;

  Map<String, dynamic> toJson() => {
        'wallet_address': walletAddress,
        'signature': signature,
      };
}
