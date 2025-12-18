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

    // To create a "liquid" feel, we create a polygon with many points
    // and add some wave variance to the radius at each point.
    const int points = 60;
    for (int i = 0; i <= points; i++) {
      final double angle = (i / points) * 2 * math.pi;

      // Liquid effect: radius varies with angle and progress
      // We use multiple sine waves for a more complex, organic shape
      final double wave1 = math.sin(angle * 3 + progress * 15) * 20;
      final double wave2 = math.cos(angle * 5 - progress * 10) * 15;

      // The waves should diminish as the reveal finishes to fill the corners cleanly
      final double waveStrength = math.sin(progress * math.pi);
      final double r = currentRadius + (wave1 + wave2) * waveStrength;

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
