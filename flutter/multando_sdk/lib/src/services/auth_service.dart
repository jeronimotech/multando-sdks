import '../core/auth_manager.dart';
import '../core/http_client.dart';
import '../models/auth.dart';
import '../models/user.dart';

/// Service for authentication and user-account endpoints.
class AuthService {
  AuthService({
    required MultandoHttpClient httpClient,
    required AuthManager authManager,
  })  : _http = httpClient,
        _authManager = authManager;

  final MultandoHttpClient _http;
  final AuthManager _authManager;

  /// Register a new user account.
  Future<TokenResponse> register(RegisterRequest request) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/register',
      data: request.toJson(),
    );
    final tokens = TokenResponse.fromJson(response.data!);
    await _authManager.saveTokens(tokens);
    return tokens;
  }

  /// Authenticate with email and password.
  Future<TokenResponse> login(LoginRequest request) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/login',
      data: request.toJson(),
    );
    final tokens = TokenResponse.fromJson(response.data!);
    await _authManager.saveTokens(tokens);
    return tokens;
  }

  /// Log out the current user and clear stored tokens.
  Future<void> logout() async {
    await _authManager.clearTokens();
  }

  /// Manually refresh the access token.
  Future<TokenResponse> refreshToken() async {
    final rt = _authManager.refreshToken;
    if (rt == null) {
      throw StateError('No refresh token available');
    }
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: RefreshRequest(refreshToken: rt).toJson(),
    );
    final tokens = TokenResponse.fromJson(response.data!);
    await _authManager.saveTokens(tokens);
    return tokens;
  }

  /// Get the current user's full profile.
  Future<UserProfile> getProfile() async {
    final response = await _http.get<Map<String, dynamic>>('/auth/me');
    return UserProfile.fromJson(response.data!);
  }

  /// Authenticate via social provider (Google, GitHub).
  /// For Google Sign-In on mobile, pass the ID token.
  /// For web OAuth flow, pass the authorization code + redirect URI.
  Future<TokenResponse> socialLogin({
    required String provider,
    String? idToken,
    String? code,
    String? redirectUri,
  }) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/auth/oauth/$provider',
      data: {
        'provider': provider,
        if (idToken != null) 'id_token': idToken,
        if (code != null) 'code': code,
        if (redirectUri != null) 'redirect_uri': redirectUri,
      },
    );
    final tokens = TokenResponse.fromJson(response.data!);
    await _authManager.saveTokens(tokens);
    return tokens;
  }

  /// Link a blockchain wallet to the user's account.
  Future<void> linkWallet(WalletLinkRequest request) async {
    await _http.post<Map<String, dynamic>>(
      '/auth/link-wallet',
      data: request.toJson(),
    );
  }
}
