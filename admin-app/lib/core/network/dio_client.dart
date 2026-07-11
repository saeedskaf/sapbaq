import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sapbaq_admin/core/config/environment.dart';
import 'package:sapbaq_admin/core/constants/app_constants.dart';
import 'package:sapbaq_admin/core/network/interceptors/auth_interceptor.dart';
import 'package:sapbaq_admin/core/network/interceptors/error_interceptor.dart';
import 'package:sapbaq_admin/core/network/interceptors/locale_interceptor.dart';
import 'package:sapbaq_admin/core/network/session_manager.dart';
import 'package:sapbaq_admin/core/storage/secure_storage.dart';

/// Builds the single configured [Dio] used across the app.
class DioClient {
  DioClient._();

  static Dio create({
    required SecureStorage storage,
    required SessionManager session,
    ValueListenable<String>? language,
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
          'Accept-Language': AppConstants.defaultLanguageCode,
        },
      ),
    );

    // Stamp the live UI language on every request (overrides the static default
    // above). Falls back to the default when no notifier is supplied.
    if (language != null) {
      dio.interceptors.add(LocaleInterceptor(language));
    }
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        session: session,
        baseUrl: Environment.baseUrl,
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
