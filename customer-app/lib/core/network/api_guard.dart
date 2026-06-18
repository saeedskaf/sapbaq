import 'package:dio/dio.dart';
import 'package:sapbaq/core/network/api_exception.dart';

/// Runs an API call and normalizes any failure to an [ApiException]
/// (Arabic, display-ready), so repositories/cubits only deal with one type.
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw e.error is ApiException
        ? e.error as ApiException
        : ApiException.fromDioException(e);
  }
}
