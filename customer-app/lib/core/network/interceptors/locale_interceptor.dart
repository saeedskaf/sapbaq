import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Stamps every request with the current UI language.
///
/// The backend uses `Accept-Language` to localize error messages and to pick
/// the language of bilingual text fields (product/mosque names, CMS pages,
/// banners…). Reading from a [ValueListenable] means a language switch in
/// settings takes effect on the very next request with no client restart.
class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._languageCode);

  final ValueListenable<String> _languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = _languageCode.value;
    handler.next(options);
  }
}
