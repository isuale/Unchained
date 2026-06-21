import 'package:flutter/material.dart';

class PillSelector extends StatelessWidget {
  const PillSelector({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeftSelected,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  final String leftLabel;
  final String rightLabel;
  final bool isLeftSelected;
  final VoidCallback onSelectLeft;
  final VoidCallback onSelectRight;

  static const _accent = Color(0xFF1E5FFF);
  static const _bg = Color(0xFF0E1320);
  static const _border = Color(0xFF1A2238);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pillWidth = width / 2;
        return Container(
          height: 44,
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: isLeftSelected ? 0 : pillWidth,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSelectLeft,
                      child: Center(
                        child: Text(
                          leftLabel,
                          style: TextStyle(
                            color: isLeftSelected
                                ? Colors.white
                                : const Color(0xFF888888),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSelectRight,
                      child: Center(
                        child: Text(
                          rightLabel,
                          style: TextStyle(
                            color: !isLeftSelected
                                ? Colors.white
                                : const Color(0xFF888888),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
