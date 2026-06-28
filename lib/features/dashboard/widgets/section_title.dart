import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.accentSubtitle,
    this.comingSoonLabel,
  });

  final String title;
  final String? accentSubtitle;

  /// When set, shows a "Working on it" pill on the right of the header to flag
  /// a section whose controls are not wired to real blocking logic yet.
  final String? comingSoonLabel;

  static const _accent = Color(0xFF1E5FFF);
  static const _accentSubtitleColor = Color(0xFFFFB800);
  static const _comingSoon = Color(0xFF00D26A);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (accentSubtitle != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          accentSubtitle!,
                          style: const TextStyle(
                            color: _accentSubtitleColor,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (comingSoonLabel != null) ...[
                const SizedBox(width: 8),
                _ComingSoonPill(label: comingSoonLabel!),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 24,
            height: 2,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded badge that flags a not-yet-functional section.
class _ComingSoonPill extends StatelessWidget {
  const _ComingSoonPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SectionTitle._comingSoon.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: SectionTitle._comingSoon.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: SectionTitle._comingSoon,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: SectionTitle._comingSoon,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
