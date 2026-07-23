import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:unchained/features/plans/domain/stripe_checkout.dart';

/// Whether an email is currently a paying subscriber, per the backend's
/// GET /v1/entitlement endpoint (see ../../../../stripe-backend/src/index.js).
class Entitlement {
  const Entitlement({required this.active, this.plan});
  final bool active;
  final String? plan;

  static const Entitlement inactive = Entitlement(active: false);
}

/// Talks to the Cloudflare Worker backend to check whether a Stripe payment
/// has gone through. A failed/timed-out request is treated as "not active yet"
/// rather than thrown — the caller (the confirmation screen) just keeps
/// polling or offers a manual retry.
class EntitlementService {
  EntitlementService._();

  static Future<Entitlement> check(String email) async {
    final uri = Uri.parse('${StripeCheckout.backendBaseUrl}/v1/entitlement')
        .replace(queryParameters: {'email': email});
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return Entitlement.inactive;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return Entitlement(
        active: body['active'] == true,
        plan: body['plan'] as String?,
      );
    } catch (_) {
      return Entitlement.inactive;
    }
  }
}
