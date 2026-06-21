import 'package:flutter/material.dart';

class UnchainedCard extends StatelessWidget {
  const UnchainedCard({
    super.key,
    required this.child,
    this.isActive = false,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final bool isActive;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  static const _bg = Color(0xFF0E1320);
  static const _border = Color(0xFF1A2238);
  static const _accent = Color(0xFF1E5FFF);

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? _accent : _border,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: _accent.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: -4,
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}
