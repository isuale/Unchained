import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Password that must be entered to switch plans. Only the app owner knows it,
/// so a tester cannot change the plan (and thereby weaken the protection).
/// Change this string to update the password.
const String _planChangePassword = 'nepia';

const Color _accent = Color(0xFF1E5FFF);
const Color _bad = Color(0xFFFF4D4F);
const Color _dim = Color(0xFF55606F);

/// Shows a full blocking password prompt. Returns `true` only when the correct
/// password is entered; `false` if the user cancels.
Future<bool> showPlanPasswordDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PlanPasswordDialog(),
  );
  return result ?? false;
}

class _PlanPasswordDialog extends StatefulWidget {
  const _PlanPasswordDialog();

  @override
  State<_PlanPasswordDialog> createState() => _PlanPasswordDialogState();
}

class _PlanPasswordDialogState extends State<_PlanPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text == _planChangePassword) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0E18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1B2435)),
      ),
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: _accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Enter password',
              style: GoogleFonts.dmSerifDisplay(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Changing your plan is protected. Enter the password to continue.',
            style: GoogleFonts.inter(color: _dim, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _submit(),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            cursorColor: _accent,
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: GoogleFonts.inter(color: _dim),
              filled: true,
              fillColor: const Color(0xFF070A12),
              contentPadding: const EdgeInsets.all(14),
              errorText: _wrong ? 'Wrong password' : null,
              errorStyle: GoogleFonts.inter(color: _bad, fontSize: 12),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: GoogleFonts.inter(color: _dim)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Unlock',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
