import 'package:core/core.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final Config _config;
  final AuthLocalManager _authManager;
  final SharedPrefHelper _prefHelper;

  AuthInterceptor(this._config, this._authManager, this._prefHelper);

  @override
  Future onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers["Accept"] = "application/json";
    options.headers['Tenant-Id'] = _config.appID.toString();

    final langIndex = _prefHelper.getLanguageIndex();
    final supportedLocales = _config.supportedLocales;

    if (supportedLocales.isNotEmpty && langIndex < supportedLocales.length) {
      final locale = supportedLocales.elementAt(langIndex);
      options.headers['Accept-Language'] = locale.data.languageCode;
    } else {
      options.headers['Accept-Language'] = _config.defaultLocalization;
    }

    if (_authManager.check()) {
      final token = _authManager.currentUser!.token;
      options.headers['Authorization'] = 'Bearer $token';
    }

    super.onRequest(options, handler);
  }
}
