import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Owner-only override: lets the app's owner (the developer) verify with
/// their own email plus a rotating 6-digit code from an authenticator app
/// (Authy) to activate any plan without going through Stripe payment.
///
/// Both checks are fully local/offline — there is no backend involved, so the
/// "email verification" is a hardcoded match (like the old plan-password
/// dialog) rather than an emailed code, and the "app code" is a standard
/// RFC 6238 TOTP computed on-device from a secret only the owner has loaded
/// into Authy.
class OwnerAccess {
  OwnerAccess._();

  static const String ownerEmail = 'imblueale@gmail.com';

  /// Base32 TOTP secret. Add this once to Authy as a generic account (Authy ->
  /// Add Account -> enter key manually), 6 digits / 30s / SHA1 — standard
  /// Google-Authenticator-compatible TOTP. Changing this value invalidates
  /// whatever is already saved in Authy.
  static const String _secretBase32 = 'NPRV4WXQ75TSRMWHZA5JUQXPV4JTW3NE';

  static const int _stepSeconds = 30;
  static const int _codeDigits = 6;

  static bool verifyEmail(String input) =>
      input.trim().toLowerCase() == ownerEmail;

  /// Accepts the current 30s step plus one step on either side, so a slow
  /// typist or minor clock drift between the phone and Authy doesn't fail.
  static bool verifyCode(String code, {DateTime? now}) {
    final cleaned = code.trim();
    if (cleaned.length != _codeDigits || int.tryParse(cleaned) == null) {
      return false;
    }
    final seconds = (now ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/
        1000;
    final step = seconds ~/ _stepSeconds;
    for (final delta in [0, -1, 1]) {
      if (_totpAt(step + delta) == cleaned) return true;
    }
    return false;
  }

  static String _totpAt(int counter) {
    final key = _base32Decode(_secretBase32);
    final msg = ByteData(8)..setInt64(0, counter, Endian.big);
    final hash = Hmac(sha1, key).convert(msg.buffer.asUint8List()).bytes;
    final offset = hash[hash.length - 1] & 0x0f;
    final binCode = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);
    final code = binCode % 1000000;
    return code.toString().padLeft(_codeDigits, '0');
  }

  static List<int> _base32Decode(String input) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final clean = input.replaceAll('=', '').toUpperCase();
    final bytes = <int>[];
    var buffer = 0;
    var bitsLeft = 0;
    for (final char in clean.split('')) {
      final value = alphabet.indexOf(char);
      if (value < 0) continue;
      buffer = (buffer << 5) | value;
      bitsLeft += 5;
      if (bitsLeft >= 8) {
        bitsLeft -= 8;
        bytes.add((buffer >> bitsLeft) & 0xff);
      }
    }
    return bytes;
  }
}
