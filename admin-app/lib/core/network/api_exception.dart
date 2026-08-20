import 'package:dio/dio.dart';

/// Unified API error.
///
/// The backend returns `{error: {code, message, details}}` where `message` is
/// **Arabic and display-ready** — show it directly. For connectivity/timeout
/// failures (no HTTP response) we synthesize an Arabic message too.
class ApiException implements Exception {
  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic> details;

  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details = const {},
  });

  factory ApiException.fromDioException(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      if (data is Map && data['error'] is Map) {
        final err = Map<String, dynamic>.from(data['error'] as Map);
        return ApiException(
          statusCode: response.statusCode ?? 0,
          code: (err['code'] ?? 'unknown').toString(),
          message: (err['message'] ?? _messageForStatus(response.statusCode))
              .toString(),
          details: err['details'] is Map
              ? Map<String, dynamic>.from(err['details'] as Map)
              : const {},
        );
      }
      // Some newer endpoints answer in raw DRF shape instead of the envelope
      // (`{detail: "…"}` or `{field: ["…"]}`). Their Arabic messages are just
      // as display-ready, so surface them rather than a generic status line.
      if (data is Map) {
        final raw = Map<String, dynamic>.from(data);
        final detail = _firstMessage(raw['detail']) ?? _firstFieldMessage(raw);
        if (detail != null) {
          return ApiException(
            statusCode: response.statusCode ?? 0,
            code: 'unknown',
            message: detail,
            details: raw,
          );
        }
      }
      return ApiException(
        statusCode: response.statusCode ?? 0,
        code: 'unknown',
        message: _messageForStatus(response.statusCode),
      );
    }
    return ApiException(
      statusCode: 0,
      code: _codeForType(e.type),
      message: _messageForType(e.type),
    );
  }

  /// A non-empty message out of a raw DRF error value — a string, or the first
  /// entry of a list of strings.
  static String? _firstMessage(Object? value) {
    if (value is String && value.trim().isNotEmpty) return value;
    if (value is List) {
      for (final item in value) {
        final message = _firstMessage(item);
        if (message != null) return message;
      }
    }
    return null;
  }

  /// The first field-level message in a raw DRF error map (`{mosque_id: [...]}`),
  /// used when there's no `detail` to show.
  static String? _firstFieldMessage(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final message = _firstMessage(entry.value);
      if (message != null) return message;
    }
    return null;
  }

  /// First field-level error for [field] (e.g. to highlight a form input).
  String? fieldError(String field) {
    final value = details[field];
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String) return value;
    return null;
  }

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;

  /// True when an OTP resend was rejected for being too soon (HTTP 429).
  bool get isThrottled => code == 'otp_throttled' || statusCode == 429;

  /// Seconds to wait before retrying, from `error.details.retry_after` (the OTP
  /// throttle response). Null when absent.
  int? get retryAfter => (details['retry_after'] as num?)?.toInt();

  static String _messageForStatus(int? status) {
    switch (status) {
      case 401:
        return 'انتهت الجلسة. يرجى تسجيل الدخول من جديد.';
      case 403:
        return 'لا تملك صلاحية لهذا الإجراء.';
      case 404:
        return 'العنصر غير موجود.';
      case 500:
        return 'حدث خطأ في الخادم. حاول لاحقًا.';
      default:
        return 'حدث خطأ غير متوقّع.';
    }
  }

  static String _codeForType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'timeout';
      case DioExceptionType.connectionError:
        return 'no_connection';
      default:
        return 'network_error';
    }
  }

  static String _messageForType(DioExceptionType type) {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال. تحقّق من الإنترنت وحاول مجددًا.';
      case DioExceptionType.connectionError:
        return 'تعذّر الاتصال بالخادم. تحقّق من اتصالك بالإنترنت.';
      default:
        return 'حدث خطأ في الاتصال. حاول مجددًا.';
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
