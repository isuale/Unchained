import 'dart:math';
import 'package:flutter/material.dart';

class TwinklingStarsOverlay extends StatefulWidget {
  const TwinklingStarsOverlay({super.key, this.starCount = 40});

  final int starCount;

  @override
  State<TwinklingStarsOverlay> createState() => _TwinklingStarsOverlayState();
}

class _Star {
  const _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.minOpacity,
    required this.maxOpacity,
    required this.periodMs,
    required this.phaseMs,
  });

  final double x;
  final double y;
  final double radius;
  final double minOpacity;
  final double maxOpacity;
  final int periodMs;
  final int phaseMs;
}

class _TwinklingStarsOverlayState extends State<TwinklingStarsOverlay>
    with SingleTickerProviderStateMixin {
  late final List<_Star> _stars;
  late final AnimationController _ticker;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    final rand = Random(42);
    _stars = List<_Star>.generate(widget.starCount, (_) {
      return _Star(
        x: rand.nextDouble(),
        y: rand.nextDouble(),
        radius: 0.8 + rand.nextDouble() * 1.4,
        minOpacity: 0.05 + rand.nextDouble() * 0.15,
        maxOpacity: 0.55 + rand.nextDouble() * 0.40,
        periodMs: 1500 + rand.nextInt(2500),
        phaseMs: rand.nextInt(4000),
      );
    });
    _stopwatch.start();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ticker,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _StarsPainter(
            stars: _stars,
            elapsedMs: _stopwatch.elapsedMilliseconds,
          ),
        );
      },
    );
  }
}

class _StarsPainter extends CustomPainter {
  _StarsPainter({required this.stars, required this.elapsedMs});

  final List<_Star> stars;
  final int elapsedMs;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final t = ((elapsedMs + star.phaseMs) % star.periodMs) / star.periodMs;
      final osc = (sin(t * 2 * pi) + 1) / 2;
      final opacity =
          star.minOpacity + (star.maxOpacity - star.minOpacity) * osc;
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.elapsedMs != elapsedMs;
}
