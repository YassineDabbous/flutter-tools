import 'package:localization/localization.dart';

/// Payment-service-provider contract (gateway-agnostic online payments).
///
/// Capability-style, like [Locator]: the interface lives in core, concrete
/// PSP SDKs plug in from `packages/impl/*` (e.g. `impl_psp_stripe`), and
/// resolution is driver-keyed (backend `gateway_driver`) via the
/// `PspRegistry` in `finance`. Redirect-only drivers (e.g. `flouci`) need no
/// plugin — a null lookup keeps the webview/waiting path.
enum PspCapability { stepUp, cardEntry, walletPay }

/// Payment token as produced by a PSP card-entry sheet. Field-for-field
/// compatible with `storeSavedMethod(paymentMethodId, gatewayToken, last4,
/// brand, expiresAt)` so a future entry UI plugs into the existing save flow.
class CardToken {
  final String token;
  final String? last4;
  final String? brand;
  final String? expiresAt;
  const CardToken({
    required this.token,
    this.last4,
    this.brand,
    this.expiresAt,
  });
}

/// Thrown when no registered plugin can serve a driver/capability.
/// Carries an already-localized [message] — callers surface it verbatim
/// (never raw SDK text).
class PspUnsupported implements Exception {
  final String driver;
  final String message;
  const PspUnsupported(this.driver, this.message);

  @override
  String toString() => 'PspUnsupported($driver): $message';
}

abstract class PspPlugin {
  /// Backend `gateway_driver` string (`stripe`, `flouci`, …).
  String get driver;
  Set<PspCapability> get capabilities;

  /// 3DS RequiresAction confirm (backend guide §4). Requires `stepUp`.
  /// Takes the backend-minted `client_secret` as a primitive so impl
  /// packages never import finance. Returns true when the intent reaches
  /// `Succeeded` client-side; false on user-cancel/decline; throws a
  /// friendly localized message on misconfiguration only.
  Future<bool> confirmStepUp(String clientSecret);

  /// Card-entry tokenize. Requires `cardEntry`; default throws friendly
  /// [PspUnsupported] until a plugin implements it.
  Future<CardToken?> collectCardToken() =>
      throw PspUnsupported(driver, 'psp_unsupported'.i18n());
}
