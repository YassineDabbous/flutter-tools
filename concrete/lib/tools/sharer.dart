import 'package:core/core.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:io' show Platform;

final class Sharer {
  static void share(String text, {String? subject}) {
    SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  static void shareApp(String messageWithoutAppLink) {
    SharePlus.instance.share(
      ShareParams(
        text: '$messageWithoutAppLink ${Platform.isIOS ? Core.get<Config>().appStoreLink : Core.get<Config>().googlePlayLink}', //
        subject: Core.get<Config>().appName,
      ),
    );
  }
}
