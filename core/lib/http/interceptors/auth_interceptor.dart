import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// A Dio interceptor that dynamically adds application-specific headers to every outgoing request.
///
/// This interceptor is responsible for injecting:
/// 1.  `Tenant-Id`: From the application [Config].
/// 2.  `Accept-Language`: Based on the user's currently selected language.
/// 3.  `Authorization`: The `Bearer` token if a user is currently authenticated.
///
/// By centralizing this logic, it decouples the Dio instance (`BaseDio`) from authentication
/// and configuration state, making the networking layer cleaner and more maintainable.
class AuthInterceptor extends Interceptor {
  final Config _config;
  final AuthLocalManager _authManager;
  final SharedPrefHelper _prefHelper;

  AuthInterceptor(this._config, this._authManager, this._prefHelper);

  @override
  Future onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers["Accept"] = "application/json";

    // Add Tenant ID header from the app config.
    options.headers['Tenant-Id'] = _config.appID.toString();

    // Add Accept-Language header based on the stored preference.
    final langIndex = _prefHelper.getLanguageIndex();
    final supportedLocales = _config.supportedLocales;

    // A safe way to get the language code, falling back to the default.
    if (supportedLocales.isNotEmpty && langIndex < supportedLocales.length) {
      final locale = supportedLocales.elementAt(langIndex);
      options.headers['Accept-Language'] = locale.data.languageCode;
    } else {
      options.headers['Accept-Language'] = _config.defaultLocalization;
    }

    // Add Authorization header if the user is logged in.
    // The check() method quickly verifies if a currentUser object exists in memory.
    if (_authManager.check()) {
      final token = _authManager.currentUser!.token;
      options.headers['Authorization'] = 'Bearer $token';
      logAuth.debug('Authorization header added to request.');
    } else {
      logAuth.debug('No user logged in, request sent without Authorization header.');
    }

    // Continue the request chain.
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Example: if (err.response?.statusCode == 401) { /* refresh token logic */ }
    super.onError(err, handler);
  }
}
