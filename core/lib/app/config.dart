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
  int get appID => 1; // Used as default tenantID
  String get appSlogon => '';
  String get appLogo => 'assets/imgs/logo.png';
  String get appName => 'no NAME';
  String get appVersionNumber => '0.0';

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

  // --- WebSocket (Pusher) ---
  String get pusherKey => '';
  String get pusherCluster => 'mt1';

  // When [pusherHost] is set, `SocketService` connects to a self-hosted
  // Reverb/Pusher server via `ws(s)://<host>:<port>/app/<key>` instead of
  // the `ws-<cluster>.pusher.com` endpoint. Null keeps the clustered mode.
  String? get pusherHost => null;
  int? get pusherPort => null;
  String? get pusherScheme => null;
}
