import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapbaq/core/network/api_exception.dart';

ApiException _from(int status, Object? body) {
  final options = RequestOptions(path: '/auth/x/');
  return ApiException.fromDioException(
    DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: status,
        data: body,
      ),
    ),
  );
}

void main() {
  group('ApiException DRF parsing', () {
    test('reads a {detail: ...} body as the message', () {
      final e = _from(400, {'detail': 'الرمز غير صحيح.'});
      expect(e.statusCode, 400);
      expect(e.message, 'الرمز غير صحيح.');
    });

    test('reads a field-error body into details + first message', () {
      final e = _from(429, {
        'phone': ['انتظر 15 دقيقة قبل إعادة الإرسال.'],
      });
      expect(e.message, 'انتظر 15 دقيقة قبل إعادة الإرسال.');
      expect(e.fieldError('phone'), 'انتظر 15 دقيقة قبل إعادة الإرسال.');
    });

    test('still parses the legacy {error: {...}} envelope', () {
      final e = _from(400, {
        'error': {
          'code': 'bad',
          'message': 'msg',
          'details': {
            'email': ['taken'],
          },
        },
      });
      expect(e.code, 'bad');
      expect(e.message, 'msg');
      expect(e.fieldError('email'), 'taken');
    });

    test('keeps the localized session message for 401 (ignores server text)', () {
      final e = _from(401, {'detail': 'Authentication credentials were not provided.'});
      expect(e.message, contains('الجلسة'));
    });

    test('falls back to a status message when the body has no usable text', () {
      final e = _from(500, {'weird': true});
      expect(e.message, isNotEmpty);
    });
  });
}
