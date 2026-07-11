import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sapbaq/core/network/api_endpoints.dart';
import 'package:sapbaq/core/network/interceptors/locale_interceptor.dart';
import 'package:sapbaq/core/network/session_manager.dart';
import 'package:sapbaq/core/storage/secure_storage.dart';

/// Attaches the Bearer token and transparently refreshes it on 401.
///
/// Extends [QueuedInterceptor] so concurrent 401s are handled one at a time —
/// only one refresh happens; queued requests pick up the new token. Refresh
/// uses a bare Dio (no interceptors) to avoid recursion. On refresh failure the
/// session is marked unauthenticated, which drives the router back to login.
class AuthInterceptor extends QueuedInterceptor {
  final SecureStorage _storage;
  final SessionManager _session;
  final Dio _bareDio;

  AuthInterceptor({
    required SecureStorage storage,
    required SessionManager session,
    required String baseUrl,
    required ValueListenable<String> language,
  })  : _storage = storage,
        _session = session,
        _bareDio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        )..interceptors.add(LocaleInterceptor(language));

  static const Set<String> _publicPaths = {
    ApiEndpoints.otpCheckNumber,
    ApiEndpoints.otpRequest,
    ApiEndpoints.otpVerify,
    ApiEndpoints.socialGoogle,
    ApiEndpoints.socialApple,
    ApiEndpoints.passcodeLogin,
    ApiEndpoints.passcodeForgotRequest,
    ApiEndpoints.passcodeForgotReset,
    ApiEndpoints.deviceTrustRequest,
    ApiEndpoints.deviceTrustVerify,
    ApiEndpoints.passkeyLoginBegin,
    ApiEndpoints.passkeyLoginComplete,
    ApiEndpoints.refresh,
  };

  bool _isPublic(String path) => _publicPaths.any(path.endsWith);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isPublic(options.path)) {
      final access = await _storage.getAccessToken();
      if (access != null && access.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $access';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthError = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['__retried'] == true;

    if (!isAuthError ||
        alreadyRetried ||
        _isPublic(err.requestOptions.path)) {
      handler.next(err);
      return;
    }

    // A 401 only means an expired session for a signed-in user. In guest mode
    // there is no token, so a protected endpoint returning 401 must NOT clear
    // the session and bounce the user to login — surface the error and let the
    // caller handle it (e.g. an empty section).
    final current = await _storage.getAccessToken();
    if (current == null || current.isEmpty) {
      handler.next(err);
      return;
    }

    // A concurrent request may have already refreshed the token.
    final used = (err.requestOptions.headers['Authorization'] as String?)
        ?.replaceFirst('Bearer ', '');
    if (current != used) {
      await _retry(err, handler, current);
      return;
    }

    final refreshed = await _tryRefresh();
    if (!refreshed) {
      await _storage.clearAuthData();
      _session.unauthenticated();
      handler.next(err);
      return;
    }

    final access = await _storage.getAccessToken();
    await _retry(err, handler, access!);
  }

  Future<void> _retry(
    DioException err,
    ErrorInterceptorHandler handler,
    String access,
  ) async {
    try {
      final options = err.requestOptions
        ..extra['__retried'] = true
        ..headers['Authorization'] = 'Bearer $access';
      final response = await _bareDio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await _bareDio.post(
        ApiEndpoints.refresh,
        data: {'refresh': refresh},
      );
      final data = res.data;
      if (data is Map && data['access'] != null) {
        await _storage.saveTokens(
          access: data['access'].toString(),
          refresh: (data['refresh'] ?? refresh).toString(),
        );
        return true;
      }
      return false;
    } on DioException {
      return false;
    }
  }
}
