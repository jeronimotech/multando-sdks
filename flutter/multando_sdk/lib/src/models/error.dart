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

    String message;
    if (data is Map<String, dynamic>) {
      message = (data['detail'] as String?) ??
          (data['message'] as String?) ??
          error.message ??
          'Unknown API error';
    } else {
      message = error.message ?? 'Unknown error';
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
