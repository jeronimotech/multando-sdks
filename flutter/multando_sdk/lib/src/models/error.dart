import 'package:dio/dio.dart';

/// Base error class for all Multando SDK errors.
abstract class MultandoError implements Exception {
  MultandoError({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  final String message;
  final int? statusCode;
  final dynamic originalError;

  @override
  String toString() => 'MultandoError($statusCode): $message';

  /// Factory that converts a [DioException] into the appropriate
  /// [MultandoError] subclass.
  static MultandoError fromDioException(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    // The backend returns structured 429 bodies for both user-level
    // report rate limits and plate-level cooldowns. The envelope is
    // either {"detail": {...}} (FastAPI HTTPException) or a flat map.
    // Both shapes expose `error`/`error_code`, `limit`, `retry_after_seconds`.
    Map<String, dynamic>? structured;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is Map<String, dynamic>) {
        structured = detail;
      } else {
        structured = data;
      }
    }

    String message;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (structured != null && structured['message'] is String) {
        message = structured['message'] as String;
      } else {
        message = (data['message'] as String?) ??
            error.message ??
            'Unknown API error';
      }
    } else {
      message = error.message ?? 'Unknown error';
    }

    // 429 rate-limit / plate-cooldown handling.
    if (statusCode == 429 && structured != null) {
      final errorCode =
          (structured['error_code'] as String?) ?? (structured['error'] as String?);
      final limitName = structured['limit'] as String?;
      final retryAfter = _toInt(structured['retry_after_seconds']);

      // Plate cooldown: either an explicit error_code, or the legacy
      // rate_limit_exceeded with a plate-scoped `limit` name.
      final isPlateCooldown = errorCode == 'plate_cooldown' ||
          (limitName != null &&
              (limitName.startsWith('same_plate') ||
                  limitName.startsWith('plate_reports') ||
                  limitName.contains('plate')));

      if (isPlateCooldown) {
        final plate = structured['plate'] as String?;
        final retryAfterHours = structured['retry_after_hours'] != null
            ? _toInt(structured['retry_after_hours'])
            : (retryAfter != null ? (retryAfter / 3600).ceil() : null);
        return PlateCooldownException(
          message: message,
          plate: plate,
          retryAfterHours: retryAfterHours,
          statusCode: statusCode,
          originalError: error,
        );
      }

      if (errorCode == 'rate_limit_exceeded' || limitName != null) {
        // Scope is "day" if the window is >= 24h or the limit name mentions day,
        // otherwise "hour".
        final windowSeconds = _toInt(structured['window_seconds']);
        final isDay = (limitName != null && limitName.contains('day')) ||
            (windowSeconds != null && windowSeconds >= 86400);
        return RateLimitException(
          message: message,
          retryAfterSeconds: retryAfter,
          scope: isDay ? RateLimitScope.day : RateLimitScope.hour,
          statusCode: statusCode,
          originalError: error,
        );
      }
    }

    // Network / connectivity errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError) {
      return MultandoNetworkError(
        message: message,
        originalError: error,
      );
    }

    if (statusCode == null) {
      return MultandoNetworkError(
        message: message,
        originalError: error,
      );
    }

    // Auth errors
    if (statusCode == 401 || statusCode == 403) {
      return MultandoAuthError(
        message: message,
        statusCode: statusCode,
        originalError: error,
      );
    }

    // Validation errors
    if (statusCode == 422 || statusCode == 400) {
      List<ValidationDetail> details = [];
      if (data is Map<String, dynamic> && data['detail'] is List) {
        details = (data['detail'] as List).map((item) {
          if (item is Map<String, dynamic>) {
            return ValidationDetail(
              field: (item['loc'] as List?)?.map((e) => e.toString()).join('.') ?? '',
              message: (item['msg'] as String?) ?? '',
              type: (item['type'] as String?) ?? '',
            );
          }
          return ValidationDetail(field: '', message: item.toString(), type: '');
        }).toList();
      }
      return MultandoValidationError(
        message: message,
        statusCode: statusCode,
        details: details,
        originalError: error,
      );
    }

    // Generic API error
    return MultandoApiError(
      message: message,
      statusCode: statusCode,
      originalError: error,
    );
  }
}

/// Error returned by the API with an HTTP status code.
class MultandoApiError extends MultandoError {
  MultandoApiError({
    required super.message,
    super.statusCode,
    super.originalError,
  });

  @override
  String toString() => 'MultandoApiError($statusCode): $message';
}

/// Network-level error (timeout, no connectivity, DNS failure, etc.).
class MultandoNetworkError extends MultandoError {
  MultandoNetworkError({
    required super.message,
    super.originalError,
  }) : super(statusCode: null);

  @override
  String toString() => 'MultandoNetworkError: $message';
}

/// Validation error (HTTP 400 / 422) with per-field details.
class MultandoValidationError extends MultandoError {
  MultandoValidationError({
    required super.message,
    super.statusCode,
    super.originalError,
    this.details = const [],
  });

  final List<ValidationDetail> details;

  @override
  String toString() =>
      'MultandoValidationError($statusCode): $message [${details.length} detail(s)]';
}

/// Detail for a single validation field error.
class ValidationDetail {
  const ValidationDetail({
    required this.field,
    required this.message,
    required this.type,
  });

  final String field;
  final String message;
  final String type;

  @override
  String toString() => '$field: $message ($type)';
}

/// Authentication / authorisation error (HTTP 401 / 403).
class MultandoAuthError extends MultandoError {
  MultandoAuthError({
    required super.message,
    super.statusCode,
    super.originalError,
  });

  @override
  String toString() => 'MultandoAuthError($statusCode): $message';
}

/// Scope of a [RateLimitException].
enum RateLimitScope { hour, day }

/// Thrown when the backend returns a structured 429 for a user-level
/// report rate limit (hourly or daily).
///
/// The SDK maps `error_code: "rate_limit_exceeded"` responses from the
/// Multando API into this exception so callers can surface a specific,
/// localized message to the user.
class RateLimitException extends MultandoError {
  RateLimitException({
    required super.message,
    required this.scope,
    this.retryAfterSeconds,
    super.statusCode,
    super.originalError,
  });

  /// Whether the reporter hit the hourly or the daily report cap.
  final RateLimitScope scope;

  /// Server-provided backoff in seconds. May be `null` if the API
  /// did not include `retry_after_seconds`.
  final int? retryAfterSeconds;

  @override
  String toString() =>
      'RateLimitException($statusCode, scope=${scope.name}, '
      'retryAfter=${retryAfterSeconds}s): $message';
}

/// Thrown when a plate-level cooldown blocks a new report for the
/// same plate / area.
///
/// This is part of Multando's responsible-reporting safeguards:
/// a single plate cannot be reported repeatedly by the same user, and
/// a plate cannot accumulate coordinated pile-on reports within a
/// short window without evidence of movement.
class PlateCooldownException extends MultandoError {
  PlateCooldownException({
    required super.message,
    this.plate,
    this.retryAfterHours,
    super.statusCode,
    super.originalError,
  });

  /// The plate that triggered the cooldown, if the API echoed it back.
  final String? plate;

  /// Server-provided backoff in hours. May be `null` if the API
  /// did not include `retry_after_hours` / `retry_after_seconds`.
  final int? retryAfterHours;

  @override
  String toString() => 'PlateCooldownException($statusCode, plate=$plate, '
      'retryAfter=${retryAfterHours}h): $message';
}

/// Parse a value that may be num or String to int (returns null on failure).
int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
