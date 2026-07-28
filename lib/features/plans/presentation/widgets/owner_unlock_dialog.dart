import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/plans/domain/owner_access.dart';
import 'package:unchained/features/plans/domain/owner_email_verification.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// Two-step owner verification:
///  1. The owner's email (checked locally — a wrong email never touches the
///     network, so a typo can't spam the inbox or probe the backend).
///  2. The one-time code the backend just emailed to that address.
/// Returns true only once both pass.
Future<bool> showOwnerUnlockDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _OwnerUnlockDialog(),
  );
  return result ?? false;
}

enum _Step { email, emailCode }

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
  final _emailCodeController = TextEditingController();

  _Step _step = _Step.email;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _emailCodeController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    final l = AppLocalizations.of(context)!;
    if (!OwnerAccess.verifyEmail(_emailController.text)) {
      setState(() {
        _error = l.owner_dialog_wrong_email;
        _emailController.clear();
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final sent = await OwnerEmailVerification.requestCode();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (sent) {
        _step = _Step.emailCode;
      } else {
        _error = l.owner_dialog_send_failed;
      }
    });
  }

  Future<void> _resendCode() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final sent = await OwnerEmailVerification.requestCode();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = sent ? null : l.owner_dialog_resend_failed;
    });
  }

  Future<void> _submitEmailCode() async {
    final l = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    final valid = await OwnerEmailVerification.verifyCode(_emailCodeController.text);
    if (!mounted) return;
    if (valid) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = l.owner_dialog_wrong_code;
      _emailCodeController.clear();
    });
  }

  void _submit() {
    switch (_step) {
      case _Step.email:
        _submitEmail();
      case _Step.emailCode:
        _submitEmailCode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final (title, hint, field) = switch (_step) {
      _Step.email => (
          l.owner_dialog_title,
          l.owner_dialog_email_hint_text,
          _buildTextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            hintText: l.owner_dialog_email_field_hint,
          ),
        ),
      _Step.emailCode => (
          l.owner_dialog_check_email_title,
          l.owner_dialog_code_hint_text,
          _buildTextField(
            controller: _emailCodeController,
            keyboardType: TextInputType.number,
            hintText: '000000',
            digits: true,
          ),
        ),
    };

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
            title,
            style: GoogleFonts.dmSerifDisplay(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hint, style: GoogleFonts.inter(color: _dim, fontSize: 13)),
            const SizedBox(height: 16),
            field,
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.inter(color: _bad, fontSize: 12)),
            ],
            if (_step == _Step.emailCode) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _busy ? null : _resendCode,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l.owner_dialog_resend_code,
                    style: GoogleFonts.inter(color: _accent, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l.common_cancel, style: GoogleFonts.inter(color: _dim)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_step == _Step.emailCode
                  ? l.owner_dialog_unlock
                  : l.owner_dialog_next),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String hintText,
    bool digits = false,
  }) {
    return TextField(
      controller: controller,
      autofocus: true,
      enabled: !_busy,
      keyboardType: keyboardType,
      maxLength: digits ? 6 : null,
      style: GoogleFonts.inter(
        color: Colors.white,
        letterSpacing: digits ? 6 : 0,
        fontSize: digits ? 20 : 14,
      ),
      cursorColor: _accent,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        counterText: digits ? '' : null,
        filled: true,
        fillColor: const Color(0xFF070A12),
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFF444C5C),
          letterSpacing: digits ? 6 : 0,
        ),
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
    );
  }
}
