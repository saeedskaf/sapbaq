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

  /// First field-level error for [field] (e.g. to highlight a form input).
  String? fieldError(String field) {
    final value = details[field];
    if (value is List && value.isNotEmpty) return value.first.toString();
    if (value is String) return value;
    return null;
  }

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;

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
