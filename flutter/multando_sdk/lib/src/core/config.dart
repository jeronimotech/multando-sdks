/// Configuration for the Multando SDK.
class MultandoConfig {
  const MultandoConfig({
    required this.baseUrl,
    required this.apiKey,
    this.locale = 'en',
    this.timeout = const Duration(seconds: 30),
    this.enableOfflineQueue = true,
    this.logLevel = MultandoLogLevel.none,
  });

  /// Base URL for the Multando API (e.g. `https://api.multando.io`).
  /// Must not include a trailing slash.
  final String baseUrl;

  /// API key issued by the Multando platform.
  final String apiKey;

  /// Locale for API responses (e.g. `en`, `es`).
  final String locale;

  /// HTTP request timeout.
  final Duration timeout;

  /// When `true`, report-creation requests made while offline are
  /// queued locally and flushed when connectivity resumes.
  final bool enableOfflineQueue;

  /// SDK logging verbosity.
  final MultandoLogLevel logLevel;

  /// The full base path for API v1 requests.
  String get apiBasePath => '$baseUrl/api/v1';

  /// The web frontend URL for OAuth consent screens.
  /// Derived from baseUrl: api.multando.com → www.multando.com,
  /// sandbox-api.multando.com → www.multando.com (same frontend).
  /// Override via [MultandoConfig] constructor if you self-host.
  String get webUrl {
    final uri = Uri.parse(baseUrl);
    final host = uri.host;
    // sandbox-api.multando.com or api.multando.com → www.multando.com
    if (host.contains('multando.com')) {
      return 'https://www.multando.com';
    }
    // Self-hosted: assume frontend is on the same host, port 3000
    return '${uri.scheme}://${host.split(':').first}:3000';
  }
}

/// Logging verbosity levels for the SDK.
enum MultandoLogLevel {
  /// No logging.
  none,

  /// Log errors only.
  error,

  /// Log warnings and errors.
  warning,

  /// Log all HTTP traffic and internal events.
  debug,
}
