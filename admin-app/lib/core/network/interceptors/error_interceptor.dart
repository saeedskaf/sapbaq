import 'package:dio/dio.dart';
import 'package:sapbaq_admin/core/network/api_exception.dart';

/// Maps every [DioException] to an [ApiException] (Arabic, display-ready) so
/// call sites only ever deal with ApiException.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: ApiException.fromDioException(err),
      ),
    );
  }
}
