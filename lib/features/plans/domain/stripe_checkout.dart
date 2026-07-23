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

  /// planId -> Stripe Payment Link URL. Fill these in from the Stripe Dashboard.
  static const Map<String, String> _links = {
    'monthly': 'https://buy.stripe.com/test_5kQ28q2Pn9i9eZI39V5kk00', // €5.99/mo
    'ai_plan': '', // paste https://buy.stripe.com/test_... for €9.99/mo
    'forever': '', // paste https://buy.stripe.com/test_... for €15.99/mo
  };

  /// Temporary stand-in so tapping a paid plan visibly opens the browser even
  /// before the real Payment Links exist. Once every entry in [_links] is
  /// filled, this is never used and can be removed.
  static const String _standIn = 'https://beunchained.app';

  /// True once a real Payment Link has been configured for [planId].
  static bool hasRealLink(String planId) => (_links[planId] ?? '').isNotEmpty;

  /// The URL to open for [planId] — the real Payment Link if set, otherwise the
  /// stand-in so the redirect is still demonstrable.
  static String urlFor(String planId) {
    final configured = _links[planId] ?? '';
    return configured.isNotEmpty ? configured : _standIn;
  }

  /// Opens the plan's checkout page in an external browser.
  /// Returns true if the page was launched.
  static Future<bool> open(String planId) async {
    final uri = Uri.parse(urlFor(planId));
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
