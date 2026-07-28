import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/guard/presentation/scripture_lock_screen.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';
import 'package:unchained/l10n/app_localizations.dart';

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
  static const Color _warn = Color(0xFFFFB020);

  bool _loading = true;
  bool _overlay = false;
  bool _accessibility = false;
  bool _deviceAdmin = false;
  bool _deviceOwner = false;
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
    final deviceAdmin = await UninstallGuardService.isDeviceAdminActive();
    final deviceOwner = await UninstallGuardService.isDeviceOwner();
    final enabled = await UninstallGuardService.isGuardEnabled();
    if (!mounted) return;
    setState(() {
      _overlay = overlay;
      _accessibility = accessibility;
      _deviceAdmin = deviceAdmin;
      _deviceOwner = deviceOwner;
      _enabled = enabled;
      _loading = false;
    });
  }

  /// Whether every supporting permission is granted, i.e. protection can run at
  /// full strength.
  ///
  /// This is deliberately **not** the same question as "is protection on".
  /// [_enabled] mirrors native `GuardState.enabled`, which is the *only* thing
  /// [UninstallGuardService] checks before throwing up the scripture lock — so the
  /// guard really does block uninstall even with a permission missing. Conflating
  /// the two used to make this card report "Off" while the lock was actively firing,
  /// and hide the turn-off button, leaving no way out from inside the app.
  bool get _ready => _overlay && _accessibility;

  /// On, but a supporting permission is missing — honest middle state.
  bool get _partial => _enabled && !_ready;

  Future<void> _turnOn() async {
    await UninstallGuardService.setGuardEnabled(true);
    // If we hold the device-owner role, also apply the OS-level hard block.
    await UninstallGuardService.lockUninstall(true);
    await _refresh();
  }

  Future<void> _turnOff() async {
    // Pass the scripture challenge to disable; the lock flips the flag itself.
    await context.push('/lock', extra: LockMode.disable);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
              Expanded(
                child: Text(
                  l.guard_card_title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!_loading)
                Text(
                  // Reports the guard's real state, not "is everything perfect".
                  // See [_ready] — saying "Off" while the lock is firing is a lie
                  // the user can't act on.
                  switch ((_enabled, _ready)) {
                    (true, true) => l.dashboard_protection_active,
                    (true, false) => l.guard_status_partial,
                    _ => l.dashboard_protection_off,
                  },
                  style: TextStyle(
                    color: switch ((_enabled, _ready)) {
                      (true, true) => _good,
                      (true, false) => _warn,
                      _ => _dim,
                    },
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.guard_explainer,
            style: const TextStyle(color: _dim, height: 1.4),
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
              label: l.guard_req_overlay,
              actionLabel: l.guard_action_allow,
              onAction: UninstallGuardService.openOverlaySettings,
            ),
            const SizedBox(height: 10),
            _requirement(
              done: _accessibility,
              label: l.guard_req_accessibility,
              actionLabel: l.guard_action_enable,
              onAction: UninstallGuardService.openAccessibilitySettings,
            ),
            const SizedBox(height: 10),
            _requirement(
              done: _deviceAdmin,
              label: l.guard_req_device_admin,
              actionLabel: l.guard_action_activate,
              onAction: UninstallGuardService.requestDeviceAdmin,
            ),
            if (_deviceOwner) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.verified_user, color: _good, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.guard_device_owner_note,
                      style: TextStyle(
                        color: _good.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_partial) ...[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: _warn, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.guard_partial_warning,
                      style: TextStyle(
                        color: _warn.withValues(alpha: 0.9),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _mainButton(l),
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

  Widget _mainButton(AppLocalizations l) {
    // Order matters: the "grant the permissions first" hint may only stand in for
    // the button while protection is OFF. While it is ON the guard is enforcing
    // regardless of the missing permission, so the turn-off route must stay
    // reachable — otherwise the user is locked in with no in-app way out (which
    // is exactly what happened when the overlay permission was denied).
    if (!_ready && !_enabled) {
      return Text(
        l.guard_grant_both_hint,
        style: const TextStyle(color: _dim, fontStyle: FontStyle.italic),
      );
    }
    if (!_enabled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _turnOn,
          child: Text(l.guard_turn_on),
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
        child: Text(l.guard_turn_off),
      ),
    );
  }
}
