import 'package:flutter/material.dart';
import 'package:unchained/features/dashboard/widgets/unchained_card.dart';

class MasterToggleCard extends StatefulWidget {
  const MasterToggleCard({
    super.key,
    required this.title,
    required this.activeLabel,
    required this.offLabel,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String activeLabel;
  final String offLabel;
  final bool value;
  final Future<void> Function(bool) onChanged;

  @override
  State<MasterToggleCard> createState() => _MasterToggleCardState();
}

class _MasterToggleCardState extends State<MasterToggleCard>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF1E5FFF);

  late final AnimationController _pulse;
  bool _pending = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.value) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant MasterToggleCard old) {
    super.didUpdateWidget(old);
    if (widget.value && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.value && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _handle(bool v) async {
    if (_pending) return;
    setState(() => _pending = true);
    try {
      await widget.onChanged(v);
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return UnchainedCard(
      isActive: widget.value,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      onTap: _pending ? null : () => _handle(!widget.value),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final t = _pulse.value;
                          final scale = widget.value
                              ? 1.0 + (0.6 * (0.5 - (t - 0.5).abs()) * 2)
                              : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: widget.value
                                    ? _accent
                                    : const Color(0xFF555555),
                                shape: BoxShape.circle,
                                boxShadow: widget.value
                                    ? [
                                        BoxShadow(
                                          color:
                                              _accent.withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.value ? widget.activeLabel : widget.offLabel,
                        style: TextStyle(
                          color: widget.value
                              ? Colors.white
                              : const Color(0xFF888888),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_pending)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _accent,
                  ),
                ),
              )
            else
              Transform.scale(
                scale: 1.2,
                child: Switch(
                  value: widget.value,
                  onChanged: _handle,
                  activeThumbColor: Colors.white,
                  activeTrackColor: _accent,
                  inactiveTrackColor: const Color(0xFF1A2238),
                  inactiveThumbColor: const Color(0xFF666666),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
