import 'package:flutter/material.dart';
import 'package:unchained/l10n/app_localizations.dart';

const _accent = Color(0xFF1E5FFF);

/// Asks for the email that will be used both to pre-fill Stripe's checkout
/// page and to look up the subscription afterwards. Returns the entered email,
/// or null if the user cancelled.
Future<String?> showEmailCheckoutDialog(
  BuildContext context, {
  String? initialEmail,
}) {
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    builder: (_) => _EmailCheckoutDialog(initialEmail: initialEmail),
  );
}

class _EmailCheckoutDialog extends StatefulWidget {
  const _EmailCheckoutDialog({this.initialEmail});
  final String? initialEmail;

  @override
  State<_EmailCheckoutDialog> createState() => _EmailCheckoutDialogState();
}

class _EmailCheckoutDialogState extends State<_EmailCheckoutDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialEmail ?? '');
  String? _error;

  bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  void _submit(AppLocalizations l) {
    final email = _controller.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = l.email_dialog_invalid);
      return;
    }
    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: const Color(0xFF0A0F1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.email_dialog_title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l.email_dialog_body,
              style: const TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(l),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l.common_email_hint,
                hintStyle: const TextStyle(color: Color(0xFF666666)),
                errorText: _error,
                filled: true,
                fillColor: const Color(0xFF0A0E18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C2233)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accent),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.common_cancel,
                        style: const TextStyle(color: Color(0xFF9AA3B2))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _submit(l),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(l.common_continue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
