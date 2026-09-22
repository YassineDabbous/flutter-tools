import 'package:core/core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/notifications.dart';

/// FCM push bootstrap — Android / iOS only.
///
/// This is the SOLE Firebase importer in the repo: `modules/notifications`
/// stays Firebase-free and works purely on payload maps
/// ([NotificationService.handleFcmPayload]) so desktop keeps working through
/// the DB inbox + socket path.
///
/// `isSupported` gates every call: on Windows/Linux/macOS/web [init] is a
/// no-op, so the Firebase native SDKs are never touched there (same idiom as
/// `OneSignalNotificationImpl.isSupported`).
///
/// Setup: drop the Firebase project's `google-services.json` into
/// `android/app/` (and `GoogleService-Info.plist` for iOS) — no
/// `firebase_options.dart` needed, `Firebase.initializeApp()` reads the
/// native configs. Until those files exist, [init] logs a warning and push
/// stays on the inbox/socket path.
class FcmPushProvider {
  static bool get isSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }

  Future<void> init(NotificationService service) async {
    if (!isSupported) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      Object().logNet.warning('FcmPushProvider: Firebase init failed: $e');
      return;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await messaging.getToken();
      if (token != null) await service.registerFcmToken(token);
      FirebaseMessaging.onMessage.listen(
        (message) => service.handleFcmPayload(message.data),
      );
    } catch (e) {
      Object().logNet.warning('FcmPushProvider: FCM setup failed: $e');
    }
  }
}
