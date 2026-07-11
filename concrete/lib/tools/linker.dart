import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_unilink/whatsapp_unilink.dart';

final class Linker {
  static void open(String? url) {
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  static void openPhone(String? phoneNumber) {
    if (phoneNumber != null) {
      final uri = Uri.tryParse("tel:$phoneNumber");
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  static void openWhatsapp(String? phoneNumber) {
    if (phoneNumber != null) {
      final uri = Uri.tryParse(
        WhatsAppUnilink(phoneNumber: phoneNumber).toString(),
      );
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }
}
