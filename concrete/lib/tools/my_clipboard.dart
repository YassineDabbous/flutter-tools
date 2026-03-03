//import 'package:clipboard_manager/clipboard_manager.dart';

import 'package:flutter/services.dart';

final class MyClipboard {
  static void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    //ClipboardManager.copyToClipBoard(text).then((result) {});
  }
}
