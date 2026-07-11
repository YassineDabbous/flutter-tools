import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalNotificationImpl extends Notifier {
  static final bool isSupported =
      !kIsWeb && !Platform.isWindows && !Platform.isLinux;

  @override
  Future init() async {
    if (!isSupported) {
      logNet.debug(
        '○○○ init: OneSignal notifications not supported on this plateform',
      );
      return false;
    }
    logNet.debug('○○○ RemoteNotificationImpl init');
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(Core.get<Config>().oneSignalAppID);
    OneSignal.Notifications.requestPermission(true);
  }

  @override
  Future<bool> logout() async {
    if (!isSupported) {
      logNet.debug(
        '○○○ logout: OneSignal notifications not supported on this plateform',
      );
      return false;
    }
    logNet.debug('○○○ RemoteNotificationImpl logout');
    await OneSignal.logout();
    return true;
  }

  @override
  Future<bool> unsubscribe(int id) async {
    if (!isSupported) {
      logNet.debug(
        '○○○ remove: OneSignal notifications not supported on this plateform',
      );
      return false;
    }
    logNet.debug('○○○ RemoteNotificationImpl remove');
    await OneSignal.logout();
    return true;
  }

  @override
  Future<bool> subscribe(int id) async {
    if (!isSupported) {
      logNet.debug(
        '○○○ subscribe: OneSignal notifications not supported on this plateform',
      );
      return false;
    }
    logNet.debug('○○○ RemoteNotificationImpl subscribe to $id');
    await OneSignal.login(id.toString());
    return true;
  }

  @override
  Future<bool> subscribeTo(String tag) async {
    if (!isSupported) {
      logNet.debug(
        '○○○ subscribe: OneSignal notifications not supported on this plateform',
      );
      return false;
    }
    logNet.debug('○○○ RemoteNotificationImpl subscribeTo to $tag');
    await OneSignal.User.addTagWithKey(tag, tag);
    return true;
  }

  @override
  Future<bool> unSubscribeFrom(String tag) async {
    if (!isSupported) {
      logNet.debug(
        '○○○ subscribe: OneSignal notifications not supported on this plateform',
      );
      return false;
    }
    logNet.debug('○○○ RemoteNotificationImpl subscribeTo to $tag');
    await OneSignal.User.removeTag(tag);
    return true;
  }
}
