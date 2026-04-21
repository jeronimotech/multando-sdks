import '../core/auth_manager.dart';
import '../core/config.dart';
import '../core/http_client.dart';
import '../models/auth.dart';
import '../models/user.dart';

/// Service for authentication and user-account endpoints.
class AuthService {
  AuthService({
    required MultandoHttpClient httpClient,
    required AuthManager authManager,
    required MultandoConfig config,
  })  : _http = httpClient,
        _authManager = authManager,
        _config = config;

  final MultandoHttpClient _http;
  final AuthManager _authManager;
  final MultandoConfig _config;

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

  // ---------------------------------------------------------------------------
  // OAuth – "Connect Multando" flow for third-party apps
  // ---------------------------------------------------------------------------

  /// Build the Multando OAuth authorization URL.
  ///
  /// The consuming app should open this URL in a browser or webview
  /// (e.g. via `url_launcher`). The user will see a consent screen on
  /// multando.com and, upon approval, be redirected to [redirectUri] with
  /// an authorization `code` query parameter.
  String buildAuthorizeUrl({
    required String redirectUri,
    String scope =
        'reports:create,reports:read,infractions:read,balance:read',
    String? state,
  }) {
    final params = <String, String>{
      'client_id': _config.apiKey,
      'redirect_uri': redirectUri,
      'scope': scope,
      'response_type': 'code',
      if (state != null) 'state': state,
    };
    final query = Uri(queryParameters: params).query;
    // The authorize URL lives on the web frontend, not the API.
    return '${_config.baseUrl}/oauth/authorize?$query';
  }

  /// Exchange an OAuth authorization code for access tokens.
  ///
  /// Call this after the user is redirected back from the consent screen.
  /// The returned [TokenResponse] is automatically persisted so subsequent
  /// API calls are authenticated.
  Future<TokenResponse> exchangeOAuthCode({
    required String code,
    required String redirectUri,
  }) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/oauth/token',
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': _config.apiKey,
        'redirect_uri': redirectUri,
      },
    );
    final tokens = TokenResponse.fromJson(response.data!);
    await _authManager.saveTokens(tokens);
    return tokens;
  }
}
