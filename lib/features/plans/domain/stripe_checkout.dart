import 'package:url_launcher/url_launcher.dart';

/// Opens Stripe's hosted checkout page (a "Payment Link") in the phone's
/// browser for a given paid plan.
///
/// Each paid plan maps to one Stripe Payment Link URL created in the Stripe
/// Dashboard (test links look like `https://buy.stripe.com/test_...`, live ones
/// like `https://buy.stripe.com/...`). Paste the real links into [_links].
///
/// The free trial is NOT here — it grants local access with no payment.
class StripeCheckout {
  StripeCheckout._();

  /// The Cloudflare Worker backend that holds the Stripe secret key and
  /// answers "is this email a paying subscriber?" — see ../../../../stripe-backend.
  static const String backendBaseUrl =
      'https://unchained-stripe-backend.doli-network.workers.dev';

  /// planId -> Stripe Payment Link URL. Fill these in from the Stripe Dashboard.
  static const Map<String, String> _links = {
    'monthly': 'https://buy.stripe.com/5kQ28q2Pn9i9eZI39V5kk00', // €5.99/mo
    'ai_plan': 'https://buy.stripe.com/6oU7sK4Xv8e5eZIdOz5kk01', // €9.99/mo
    'forever': 'https://buy.stripe.com/fZu4gy2PnamdcRA7qb5kk02', // €15.99/mo
  };

  /// Temporary stand-in so tapping a paid plan visibly opens the browser even
  /// before the real Payment Links exist. Once every entry in [_links] is
  /// filled, this is never used and can be removed.
  static const String _standIn = 'https://beunchained.app';

  /// True once a real Payment Link has been configured for [planId]. Only
  /// plans with a real link go through payment gating (email prompt + waiting
  /// for Stripe confirmation) — plans still on the stand-in have no real
  /// checkout to confirm against, so they keep activating immediately.
  static bool hasRealLink(String planId) => (_links[planId] ?? '').isNotEmpty;

  /// The URL to open for [planId] — the real Payment Link (with the buyer's
  /// email pre-filled so the app can look them up after payment) if
  /// configured, otherwise the stand-in so the redirect is still demonstrable.
  static String urlFor(String planId, {String? email}) {
    final configured = _links[planId] ?? '';
    if (configured.isEmpty) return _standIn;
    if (email == null || email.isEmpty) return configured;
    final uri = Uri.parse(configured);
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'prefilled_email': email,
    }).toString();
  }

  /// Opens the plan's checkout page in an external browser.
  /// Returns true if the page was launched.
  static Future<bool> open(String planId, {String? email}) async {
    final uri = Uri.parse(urlFor(planId, email: email));
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
