import 'package:flutter/material.dart';

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

  void _submit() {
    final email = _controller.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0F1C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your email',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "We'll use this to confirm your payment with Stripe and unlock "
              'the plan once it succeeds.',
              style: TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'you@example.com',
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
                    child: const Text('Cancel',
                        style: TextStyle(color: Color(0xFF9AA3B2))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue'),
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
