import 'dart:io';

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoImpl implements DeviceInfo {
  @override
  Future<String?> uuid() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor; // unique ID on iOS
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return android.id; // unique ID on Android
    } else if (Platform.isWindows) {
      final windows = await deviceInfo.windowsInfo;
      return "${windows.computerName}${windows.numberOfCores}${windows.systemMemoryInMegabytes}";
    } else if (Platform.isMacOS) {
      final macos = await deviceInfo.macOsInfo;
      return macos.systemGUID;
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      return linux.machineId;
    } else if (kIsWeb) {
      final browserInfo = await deviceInfo.webBrowserInfo;
      return "${browserInfo.vendor}${browserInfo.userAgent}${browserInfo.hardwareConcurrency}";
    }
    return null;
  }

  @override
  Future<String?> name() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return ios.identifierForVendor; // unique ID on iOS
    } else if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return android.device; // unique ID on Android
    } else if (Platform.isWindows) {
      final windows = await deviceInfo.windowsInfo;
      return windows.computerName;
    } else if (Platform.isMacOS) {
      final macos = await deviceInfo.macOsInfo;
      return macos.computerName;
    } else if (Platform.isLinux) {
      final linux = await deviceInfo.linuxInfo;
      return linux.name;
    } else if (kIsWeb) {
      final browserInfo = await deviceInfo.webBrowserInfo;
      return browserInfo.appName;
    }
    return null;
  }
}
