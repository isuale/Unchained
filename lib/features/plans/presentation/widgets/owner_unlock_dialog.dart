import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/plans/domain/owner_access.dart';

/// Two-step owner verification: the owner's email, then the current 6-digit
/// Authy code. Returns true only once both check out.
Future<bool> showOwnerUnlockDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OwnerUnlockDialog(),
  );
  return result ?? false;
}

class _OwnerUnlockDialog extends StatefulWidget {
  const _OwnerUnlockDialog();

  @override
  State<_OwnerUnlockDialog> createState() => _OwnerUnlockDialogState();
}

class _OwnerUnlockDialogState extends State<_OwnerUnlockDialog> {
  static const _accent = Color(0xFF1E5FFF);
  static const _dim = Color(0xFF55606F);
  static const _bad = Color(0xFFFF4D4F);

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  int _step = 0; // 0 = email, 1 = TOTP code
  bool _wrong = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (OwnerAccess.verifyEmail(_emailController.text)) {
      setState(() {
        _wrong = false;
        _step = 1;
      });
    } else {
      setState(() {
        _wrong = true;
        _emailController.clear();
      });
    }
  }

  void _submitCode() {
    if (OwnerAccess.verifyCode(_codeController.text)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _wrong = true;
        _codeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmailStep = _step == 0;

    return AlertDialog(
      backgroundColor: const Color(0xFF0A0E18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1B2435)),
      ),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings_outlined,
              color: _accent, size: 22),
          const SizedBox(width: 10),
          Text(
            isEmailStep ? 'Owner' : 'Verification code',
            style: GoogleFonts.dmSerifDisplay(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmailStep
                  ? "Enter the owner's email to continue."
                  : 'Enter the current code from Authy.',
              style: GoogleFonts.inter(color: _dim, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (isEmailStep)
              TextField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.inter(color: Colors.white),
                cursorColor: _accent,
                onSubmitted: (_) => _submitEmail(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF070A12),
                  hintText: 'owner@email.com',
                  hintStyle: const TextStyle(color: Color(0xFF444C5C)),
                  errorText: _wrong ? 'Wrong email' : null,
                  errorStyle: const TextStyle(color: _bad),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B2435)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B2435)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accent),
                  ),
                ),
              )
            else
              TextField(
                controller: _codeController,
                autofocus: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  letterSpacing: 6,
                  fontSize: 20,
                ),
                cursorColor: _accent,
                onSubmitted: (_) => _submitCode(),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFF070A12),
                  hintText: '000000',
                  hintStyle: const TextStyle(
                      color: Color(0xFF444C5C), letterSpacing: 6),
                  errorText: _wrong ? 'Wrong code' : null,
                  errorStyle: const TextStyle(color: _bad),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B2435)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B2435)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _accent),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: GoogleFonts.inter(color: _dim)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: isEmailStep ? _submitEmail : _submitCode,
          child: Text(isEmailStep ? 'Next' : 'Unlock'),
        ),
      ],
    );
  }
}
