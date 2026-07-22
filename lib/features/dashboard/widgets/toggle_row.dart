import 'package:flutter/material.dart';

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    super.key,
    required this.label,
    this.sublabel,
    required this.value,
    required this.onChanged,
    this.isLocked = false,
    this.lockedTooltip,
    this.leadingIcon,
    this.parentEnabled = true,
    this.onLockedTap,
    this.onLongPress,
    this.badge,
  });

  final String label;
  final String? sublabel;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLocked;
  final String? lockedTooltip;
  final IconData? leadingIcon;
  final bool parentEnabled;
  final VoidCallback? onLockedTap;

  /// When set, the row shows this text as a small pill instead of a switch and
  /// becomes inert. Used to mark a feature that exists in the UI but isn't
  /// wired up yet (e.g. "Working on it"), so a user can't flip on something
  /// that does nothing.
  final String? badge;

  /// Optional long-press handler. Used by the dev-only "reset daily budget"
  /// affordance on the social-feed rows; null (and inert) in normal builds.
  final VoidCallback? onLongPress;

  static const _accent = Color(0xFF1E5FFF);
  static const _gold = Color(0xFFFFB800);
  static const _sublabelColor = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    final effectiveOpacity = parentEnabled ? 1.0 : 0.4;
    final tappable = badge == null && isLocked && onLockedTap != null;

    final content = SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon,
                  size: 24, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sublabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        sublabel!,
                        style: const TextStyle(
                          color: _sublabelColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (isLocked)
              Row(
                children: [
                  if (lockedTooltip != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        lockedTooltip!,
                        style: const TextStyle(
                          color: _gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const Icon(Icons.workspace_premium,
                      color: _gold, size: 22),
                ],
              )
            else
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: _accent,
                inactiveTrackColor: const Color(0xFF1A2238),
                inactiveThumbColor: const Color(0xFF666666),
              ),
          ],
        ),
      ),
    );

    final wrapped = Opacity(
      opacity: effectiveOpacity,
      child: content,
    );

    if (tappable || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tappable ? onLockedTap : null,
          onLongPress: onLongPress,
          child: wrapped,
        ),
      );
    }
    return wrapped;
  }
}
