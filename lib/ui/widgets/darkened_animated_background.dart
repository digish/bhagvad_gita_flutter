import 'package:flutter/material.dart';
import 'animated_gradient_background.dart'; // Your existing background widget

class DarkenedAnimatedBackground extends StatelessWidget {
  final double opacity;
  final BlendMode blendMode;

  const DarkenedAnimatedBackground({
    super.key,
    this.opacity = 0.7, // Default darkness
    this.blendMode = BlendMode.darken, // Default blend mode
  });

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(opacity),
        blendMode,
      ),
      child: const AnimatedGradientBackground(),
    );
  }
}