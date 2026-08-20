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
    // The logger goes in BEFORE `ErrorInterceptor`, and the order is the whole
    // point. Dio walks `onError` in registration order, and `ErrorInterceptor`
    // ends the walk with `handler.reject(...)` — so anything registered after it
    // never sees a failure. Logging last meant every successful call was printed
    // and **every failed one vanished**: the exact line worth reading was the
    // only line missing. Cost a payment-debugging round to notice.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          // Off on purpose: these carry the bearer token, and debug logs get
          // pasted into chats and tickets. The body is what debugging needs.
          requestHeader: false,
        ),
      );
    }

    dio.interceptors.add(ErrorInterceptor());

    return dio;
  }
}
