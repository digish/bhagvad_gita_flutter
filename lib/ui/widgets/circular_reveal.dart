import 'dart:math' as math;
import 'package:flutter/material.dart';

class CircularReveal extends StatelessWidget {
  final Widget child;
  final double radius;
  final Offset center;

  const CircularReveal({
    super.key,
    required this.child,
    required this.radius,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: CircularRevealClipper(fraction: radius, center: center),
      child: child,
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;

  CircularRevealClipper({required this.fraction, required this.center});

  @override
  Path getClip(Size size) {
    final path = Path();

    // Calculate distance to the farthest corner
    final double maxRadius = _calculateMaxRadius(size, center);

    path.addOval(Rect.fromCircle(center: center, radius: maxRadius * fraction));
    return path;
  }

  double _calculateMaxRadius(Size size, Offset center) {
    final double w = size.width;
    final double h = size.height;

    final double d1 = math.sqrt(
      math.pow(center.dx, 2) + math.pow(center.dy, 2),
    );
    final double d2 = math.sqrt(
      math.pow(w - center.dx, 2) + math.pow(center.dy, 2),
    );
    final double d3 = math.sqrt(
      math.pow(center.dx, 2) + math.pow(h - center.dy, 2),
    );
    final double d4 = math.sqrt(
      math.pow(w - center.dx, 2) + math.pow(h - center.dy, 2),
    );

    return [d1, d2, d3, d4].reduce(math.max);
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}
