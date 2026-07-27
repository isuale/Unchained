import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:unchained/features/plans/domain/stripe_checkout.dart';

/// Talks to the Cloudflare Worker backend to email the owner a one-time code
/// and check what the owner typed back against it (see
/// ../../../../stripe-backend/src/index.js, handleOwnerRequestCode /
/// handleOwnerVerifyCode). A failed/timed-out request is treated as failure
/// rather than thrown, matching [EntitlementService]'s pattern.
class OwnerEmailVerification {
  OwnerEmailVerification._();

  static Future<bool> requestCode() async {
    final uri =
        Uri.parse('${StripeCheckout.backendBaseUrl}/v1/owner/request-code');
    try {
      final response = await http.post(uri).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> verifyCode(String code) async {
    final uri =
        Uri.parse('${StripeCheckout.backendBaseUrl}/v1/owner/verify-code');
    try {
      final response = await http
          .post(
            uri,
            headers: {'content-type': 'application/json'},
            body: jsonEncode({'code': code.trim()}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return false;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['valid'] == true;
    } catch (_) {
      return false;
    }
  }
}
