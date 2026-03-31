import 'package:dio/dio.dart';

import '../models/auth.dart';
import '../models/error.dart';
import 'auth_manager.dart';
import 'config.dart';

/// Dio-based HTTP client with auth-token injection, automatic 401 refresh,
/// and snake_case / camelCase transform support.
class MultandoHttpClient {
  MultandoHttpClient({
    required MultandoConfig config,
    required AuthManager authManager,
  })  : _config = config,
        _authManager = authManager {
    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiBasePath,
        connectTimeout: config.timeout,
        receiveTimeout: config.timeout,
        sendTimeout: config.timeout,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-Key': config.apiKey,
          'Accept-Language': config.locale,
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(
      authManager: _authManager,
      dio: _dio,
      config: _config,
    ));

    if (config.logLevel == MultandoLogLevel.debug) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  final MultandoConfig _config;
  final AuthManager _authManager;
  late final Dio _dio;

  /// The raw [Dio] instance, exposed for advanced usage.
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Convenience wrappers that translate DioExceptions into MultandoErrors.
  // ---------------------------------------------------------------------------

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _wrap(() => _dio.get<T>(
            path,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _wrap(() => _dio.post<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _wrap(() => _dio.put<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _wrap(() => _dio.patch<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _wrap(() => _dio.delete<T>(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  /// Wraps a Dio call, converting [DioException] into [MultandoError].
  Future<Response<T>> _wrap<T>(Future<Response<T>> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw MultandoError.fromDioException(e);
    }
  }

  void dispose() {
    _dio.close();
  }
}

// -----------------------------------------------------------------------------
// Interceptor: injects Bearer token and handles 401 auto-refresh.
// -----------------------------------------------------------------------------

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required this.authManager,
    required this.dio,
    required this.config,
  });

  final AuthManager authManager;
  final Dio dio;
  final MultandoConfig config;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final token = authManager.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 && authManager.refreshToken != null) {
      try {
        final newToken = await authManager.refreshIfNeeded(_doRefresh);
        if (newToken != null) {
          // Retry the original request with the new token.
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (_) {
        // Refresh failed; fall through to original error.
      }
    }
    handler.next(err);
  }

  Future<TokenResponse?> _doRefresh(String refreshToken) async {
    try {
      final response = await Dio(BaseOptions(
        baseUrl: config.apiBasePath,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-API-Key': config.apiKey,
        },
      )).post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      if (response.data != null) {
        return TokenResponse.fromJson(response.data!);
      }
    } catch (_) {
      // Refresh failed.
    }
    return null;
  }
}
