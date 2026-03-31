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
