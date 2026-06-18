import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sapbaq/core/config/environment.dart';
import 'package:sapbaq/core/network/interceptors/auth_interceptor.dart';
import 'package:sapbaq/core/network/interceptors/error_interceptor.dart';
import 'package:sapbaq/core/network/interceptors/locale_interceptor.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';

/// Builds the single configured [Dio] used across the app.
class DioClient {
  DioClient._();

  static Dio create({
    required SecureStorage storage,
    required SessionManager session,
    required ValueListenable<String> language,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Environment.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Stamp the current UI language on every request (Accept-Language).
    dio.interceptors.add(LocaleInterceptor(language));
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        session: session,
        baseUrl: Environment.baseUrl,
        language: language,
      ),
    );
    dio.interceptors.add(ErrorInterceptor());

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }

    return dio;
  }
}
