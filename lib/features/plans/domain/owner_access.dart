/// Owner-only override: lets the app's owner (the developer) verify with
/// their own email to activate any plan without going through Stripe payment.
///
/// The email check is fully local/offline — there is no backend involved, so
/// it's a hardcoded match (like the old plan-password dialog) rather than a
/// network call. The actual one-time code the owner types back is emailed by
/// the backend and checked there (see [OwnerEmailVerification]).
class OwnerAccess {
  OwnerAccess._();

  static const String ownerEmail = 'imblueale@gmail.com';

  static bool verifyEmail(String input) =>
      input.trim().toLowerCase() == ownerEmail;
}
