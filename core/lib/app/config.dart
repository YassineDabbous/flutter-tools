import 'package:core/core.dart';
import 'package:flutter/material.dart';

/// Abstract base class for all application configurations and constants.
///
/// Concrete classes implement this to provide environment-specific settings
/// (e.g., development, production).
abstract class Config {
  const Config();

  // --- Localization Settings ---
  String get defaultLocalization => 'en';
  List<String> get localDirectories => const ['assets/lang/i18n'];
  List<CustomLang> get supportedLocales => const <CustomLang>[
    CustomLang('English', Locale('en', 'US')),
  ];

  // --- Theme Settings ---
  List<CustomTheme> get themes => <CustomTheme>[
    CustomTheme('Default skin', ThemeData()),
  ];

  // --- API & App Identity ---
  String get baseUrl => 'https://www.yaseen.dev/api/v1';
  String get defaultCurrency => 'TND';
  int get appID => 1; // Used as default tenantID
  String get appSlogon => '';
  String get appLogo => 'assets/imgs/logo.png';
  String get appName => 'no NAME';
  String get appVersionNumber => '1.0.0';

  /// ISO-2 country code (e.g. `'TN'`) used to scope geocoder searches and any
  /// other market-limited feature. Null (default) = unscoped worldwide
  /// behavior.
  String? get countryCode => null;

  // --- External Links ---
  String get kLinkAboutUs => 'http://www.yaseen.dev/';
  String get googlePlayIdentifier => 'googlePlayIdentifier  HERE';
  String get appStoreIdentifier => 'appStoreIdentifier 0123456789';
  String get googlePlayLink =>
      'https://play.google.com/store/apps/details?id=$googlePlayIdentifier';
  String get appStoreLink =>
      'https://apps.apple.com/us/app/facebook/id$appStoreIdentifier';

  // --- External Keys ---
  String get oneSignalAppID => '';
  String get sentryDSN =>
      'https://1bf27e832e4649c7a2014e8f919605cd@o964017.ingest.us.sentry.io/5912864';

  /// Stripe publishable key (3DS step-up confirm only — guide §4). Publishable
  /// keys are public by design; override per app/env. Null (default) disables
  /// in-app 3DS confirm with a friendly message — redirect/SDK polling keeps
  /// working. Long-term the backend should expose this via bootstrap
  /// (`FINANCE_STRIPE_PUBLISHABLE_KEY` exists server-side but is not served).
  String? get stripePublishableKey => null;

  // --- Safety ---
  /// Emergency dispatch number dialed by the ride safety toolkit SOS.
  String get emergencyPhone => '197';

  /// Support/report-issue destination for the safety toolkit.
  String get supportUrl => 'https://rebelo.app/support';

  /// Public trip-tracking URL template. `{uuid}` is replaced with the order
  /// UUID; when null the toolkit shares the `rebelo://tracking/<uuid>` deep
  /// link instead.
  String? get trackingUrl => null;

  // --- WebSocket (Pusher) ---
  String get pusherKey => '';
  String get pusherCluster => 'mt1';

  // When [pusherHost] is set, `SocketService` connects to a self-hosted
  // Reverb/Pusher server via `ws(s)://<host>:<port>/app/<key>` instead of
  // the `ws-<cluster>.pusher.com` endpoint. Null keeps the clustered mode.
  String? get pusherHost => null;
  int? get pusherPort => null;
  String? get pusherScheme => null;

  // Laravel's default `POST /broadcasting/auth` lives OUTSIDE the `/api/v1`
  // prefix baked into [baseUrl]. Derive the origin by stripping the version
  // segment so socket auth hits nginx on port 80 (`http://host/broadcasting/auth`),
  // not `http://host/api/v1/broadcasting/auth` (404).
  String get broadcastingAuthUrl =>
      '${baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '')}/broadcasting/auth';
}
