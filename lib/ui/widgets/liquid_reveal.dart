import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidReveal extends StatelessWidget {
  final Widget child;
  final double progress;
  final Offset center;

  const LiquidReveal({
    super.key,
    required this.child,
    required this.progress,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: LiquidRevealClipper(progress: progress, center: center),
      child: child,
    );
  }
}

class LiquidRevealClipper extends CustomClipper<Path> {
  final double progress;
  final Offset center;

  LiquidRevealClipper({required this.progress, required this.center});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (progress == 0) return path;
    if (progress >= 1.0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    final double maxRadius = _calculateMaxRadius(size, center);
    final currentRadius = maxRadius * progress;

    // Golden Ink / Organic Splatter Effect
    // Higher resolution for better organic details
    const int points = 120;

    for (int i = 0; i <= points; i++) {
      final double angle = (i / points) * 2 * math.pi;

      // 1. Large Lobes (The main "splatter" shape)
      final double wave1 = math.sin(angle * 5 + progress * 8) * 40;

      // 2. Irregularity (Asymmetry)
      final double wave2 = math.cos(angle * 13 - progress * 12) * 25;

      // 3. Fine Detail (Rough "ink bleed" edges)
      final double wave3 = math.sin(angle * 29 + progress * 20) * 12;

      // Combine waves, scaling them down as the circle fills the screen
      // so the edges become smooth right at the end (clean finish)
      final double waveStrength =
          math.sin(progress * math.pi) * (1.2 - progress * 0.2);

      final double r = currentRadius + (wave1 + wave2 + wave3) * waveStrength;

      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  double _calculateMaxRadius(Size size, Offset center) {
    final double w = size.width;
    final double h = size.height;

    // Corners
    final d1 = Offset(0, 0) - center;
    final d2 = Offset(w, 0) - center;
    final d3 = Offset(0, h) - center;
    final d4 = Offset(w, h) - center;

    return [
          d1.distance,
          d2.distance,
          d3.distance,
          d4.distance,
        ].reduce(math.max) +
        50; // Extra buffer for waves
  }

  @override
  bool shouldReclip(LiquidRevealClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.center != center;
  }
}
