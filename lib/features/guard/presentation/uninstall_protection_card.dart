import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/guard/presentation/scripture_lock_screen.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';

/// Settings card that sets up and reflects the state of uninstall protection.
///
/// Two system permissions plus an in-app switch must all be on:
///  1. "Display over other apps" (so the lock can cover Settings),
///  2. the accessibility watchdog (so it can see the escape doors),
///  3. protection turned on.
///
/// Turning protection *off* is deliberately not free — it routes through the same
/// scripture lock, so a weak moment can't quietly undo the guard.
class UninstallProtectionCard extends StatefulWidget {
  const UninstallProtectionCard({super.key});

  @override
  State<UninstallProtectionCard> createState() => _UninstallProtectionCardState();
}

class _UninstallProtectionCardState extends State<UninstallProtectionCard>
    with WidgetsBindingObserver {
  static const Color _card = Color(0xFF0A0E18);
  static const Color _accent = Color(0xFF1E5FFF);
  static const Color _good = Color(0xFF34C759);
  static const Color _dim = Color(0xFF8893A5);

  bool _loading = true;
  bool _overlay = false;
  bool _accessibility = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check after the user returns from a system settings screen.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final overlay = await UninstallGuardService.isOverlayGranted();
    final accessibility = await UninstallGuardService.isAccessibilityEnabled();
    final enabled = await UninstallGuardService.isGuardEnabled();
    if (!mounted) return;
    setState(() {
      _overlay = overlay;
      _accessibility = accessibility;
      _enabled = enabled;
      _loading = false;
    });
  }

  bool get _ready => _overlay && _accessibility;

  Future<void> _turnOn() async {
    await UninstallGuardService.setGuardEnabled(true);
    await _refresh();
  }

  Future<void> _turnOff() async {
    // Pass the scripture challenge to disable; the lock flips the flag itself.
    await context.push('/lock', extra: LockMode.disable);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: _accent),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Uninstall protection',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!_loading)
                Text(
                  _enabled && _ready ? 'ON' : 'OFF',
                  style: TextStyle(
                    color: _enabled && _ready ? _good : _dim,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'When you head toward Force stop or Uninstall, Unchained covers the '
            'screen and asks you to copy a passage of Scripture within four minutes '
            'first.',
            style: TextStyle(color: _dim, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                ),
              ),
            )
          else ...[
            _requirement(
              done: _overlay,
              label: 'Display over other apps',
              actionLabel: 'Allow',
              onAction: UninstallGuardService.openOverlaySettings,
            ),
            const SizedBox(height: 10),
            _requirement(
              done: _accessibility,
              label: 'Accessibility watchdog',
              actionLabel: 'Enable',
              onAction: UninstallGuardService.openAccessibilitySettings,
            ),
            const SizedBox(height: 16),
            _mainButton(),
          ],
        ],
      ),
    );
  }

  Widget _requirement({
    required bool done,
    required String label,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    return Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? _good : _dim,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: done ? Colors.white : _dim,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (!done)
          TextButton(
            onPressed: () => onAction(),
            child: Text(actionLabel, style: const TextStyle(color: _accent)),
          ),
      ],
    );
  }

  Widget _mainButton() {
    if (!_ready) {
      return const Text(
        'Grant both permissions above to switch protection on.',
        style: TextStyle(color: _dim, fontStyle: FontStyle.italic),
      );
    }
    if (!_enabled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _turnOn,
          child: const Text('Turn on protection'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _turnOff,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF4D4F),
          side: const BorderSide(color: Color(0xFF3A2030)),
        ),
        child: const Text('Turn off protection'),
      ),
    );
  }
}
