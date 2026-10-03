import 'package:flutter/material.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// Which accessibility service the disclosure is about. The app has two, each
/// used by different features, and the disclosure must name the right ones.
enum AccessibilityPurpose {
  /// The uninstall watchdog — also drives the prayer app lock.
  guard,

  /// The feed guard — Social feed limits and App time limits.
  limits,
}

/// Google Play's "prominent disclosure" for the AccessibilityService API.
///
/// Must be shown before sending the user to Android's Accessibility settings.
/// Play's rules: two clear buttons, consent only by tapping "Agree", and
/// tapping outside / pressing back / waiting never counts as consent — so the
/// dialog is not barrier-dismissible, blocks system back, and never times out.
///
/// Returns true only when the user tapped "Agree".
Future<bool> showAccessibilityDisclosure(
  BuildContext context,
  AccessibilityPurpose purpose,
) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AccessibilityDisclosureDialog(purpose: purpose),
  );
  return agreed ?? false;
}

/// Shows the disclosure, then runs [openSettings] only if the user agreed.
Future<void> openAccessibilityWithDisclosure(
  BuildContext context,
  AccessibilityPurpose purpose,
  Future<bool> Function() openSettings,
) async {
  if (await showAccessibilityDisclosure(context, purpose)) {
    await openSettings();
  }
}

class _AccessibilityDisclosureDialog extends StatelessWidget {
  const _AccessibilityDisclosureDialog({required this.purpose});

  final AccessibilityPurpose purpose;

  static const Color _card = Color(0xFF0A0E18);
  static const Color _accent = Color(0xFF1E5FFF);
  static const Color _dim = Color(0xFFB8C0D0);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final purposeText = switch (purpose) {
      AccessibilityPurpose.guard => l.a11y_disclosure_purpose_guard,
      AccessibilityPurpose.limits => l.a11y_disclosure_purpose_limits,
    };
    const body = TextStyle(color: _dim, height: 1.4, fontSize: 14);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: _card,
        title: Row(
          children: [
            const Icon(Icons.accessibility_new, color: _accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l.a11y_disclosure_title,
                  style: const TextStyle(color: Colors.white, fontSize: 19)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.a11y_disclosure_intro, style: body),
              const SizedBox(height: 12),
              Text(purposeText,
                  style: body.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Text(l.a11y_disclosure_data, style: body),
              const SizedBox(height: 12),
              Text(l.a11y_disclosure_next, style: body),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.a11y_disclosure_decline,
                style: const TextStyle(color: _dim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.a11y_disclosure_agree),
          ),
        ],
      ),
    );
  }
}
