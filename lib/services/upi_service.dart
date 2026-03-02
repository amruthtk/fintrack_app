import 'package:url_launcher/url_launcher.dart';

class UpiService {
  /// Build a UPI payment URL
  static String buildUpiUrl({
    required String upiId,
    required String payeeName,
    required double amount,
    String? note,
  }) {
    final params = {
      'pa': upiId,
      'pn': payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      if (note != null && note.isNotEmpty) 'tn': note,
    };
    // Don't URI-encode 'am' and 'cu' — encoding the decimal (5.00 → 5%2E00)
    // causes some UPI apps to misread the amount.
    final queryParts = <String>[];
    for (final e in params.entries) {
      final val = (e.key == 'am' || e.key == 'cu')
          ? e.value
          : Uri.encodeComponent(e.value);
      queryParts.add('${e.key}=$val');
    }
    return 'upi://pay?${queryParts.join('&')}';
  }

  /// Launch UPI app with payment URL
  static Future<bool> launchUpiApp(String upiUrl) async {
    final uri = Uri.parse(upiUrl);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Parse a UPI QR code string to extract payment details
  static Map<String, String> parseQrCode(String rawValue) {
    final result = <String, String>{};
    try {
      final uri = Uri.parse(rawValue);
      if (uri.scheme == 'upi' && uri.host == 'pay') {
        result['upiId'] = uri.queryParameters['pa'] ?? '';
        result['name'] = uri.queryParameters['pn'] ?? '';
        result['amount'] = uri.queryParameters['am'] ?? '';
        result['note'] = uri.queryParameters['tn'] ?? '';
      }
    } catch (_) {}
    return result;
  }
}
