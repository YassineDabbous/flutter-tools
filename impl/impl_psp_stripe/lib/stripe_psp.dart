import 'package:core/core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Stripe [PspPlugin]: in-app 3DS step-up confirmation (backend guide §4).
///
/// The backend charges the saved card server-side and mints the intent; the
/// app only handles the `RequiresAction` next action via [confirmStepUp],
/// then resumes polling until `success` (the `payment_intent.succeeded`
/// webhook finalizes it).
///
/// Publishable key comes from `Config.stripePublishableKey` (per app/env,
/// never hardcoded; null disables confirm with a friendly message — the
/// redirect/SDK polling flows keep working).
class StripePspPlugin implements PspPlugin {
  const StripePspPlugin();

  @override
  String get driver => 'stripe';

  @override
  Set<PspCapability> get capabilities => const {PspCapability.stepUp};

  // No cardEntry capability — card tokens come from the backend
  // `storeSavedMethod` flow, never from an in-app Stripe sheet.
  @override
  Future<CardToken?> collectCardToken() =>
      throw PspUnsupported(driver, 'psp_unsupported'.i18n());

  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    final key = Core.get<Config>().stripePublishableKey;
    if (key == null || key.isEmpty) {
      throw 'stripe_not_configured'.i18n();
    }
    Stripe.publishableKey = key;
    await Stripe.instance.applySettings();
    _initialized = true;
  }

  /// Presents the 3DS challenge (if any) for a backend-minted
  /// `client_secret`. Returns true when the intent reaches `Succeeded`
  /// client-side (server webhook is still the source of truth — callers
  /// resume polling afterwards). False on user-cancel/decline; throws a
  /// friendly localized message on misconfiguration only — Stripe declines
  /// surface as false, never raw SDK text.
  @override
  Future<bool> confirmStepUp(String clientSecret) async {
    await _ensureInitialized();
    try {
      final intent = await Stripe.instance.handleNextAction(clientSecret);
      return intent.status == PaymentIntentsStatus.Succeeded;
    } catch (e) {
      Object().logNet.warning('pay: 3DS step-up confirm failed', e);
      return false;
    }
  }
}
