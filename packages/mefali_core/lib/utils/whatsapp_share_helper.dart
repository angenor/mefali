import 'package:url_launcher/url_launcher.dart';

class WhatsAppShareHelper {
  WhatsAppShareHelper._();

  static Future<bool> shareOnWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static String buildRestaurantMessage({
    required String merchantName,
    required String shareUrl,
  }) {
    return 'Decouvre $merchantName sur mefali ! Commande facilement depuis ton telephone.\n$shareUrl';
  }

  static String buildAppInviteMessage({
    required String referralCode,
    required String shareBaseUrl,
  }) {
    return 'Rejoins mefali ! L\'app pour commander a manger a Bouake.\n$shareBaseUrl/share?ref=$referralCode';
  }
}
