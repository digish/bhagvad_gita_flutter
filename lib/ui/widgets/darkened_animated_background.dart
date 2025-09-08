/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*
*  The sacred text of the Bhagavad Gita, as presented herein, is in the public domain. Translations, interpretations, UI elements, and artistic representations created by the developer are protected under copyright law.
*
*  This app is offered in the spirit of dharma and shared learning. You are welcome to use, modify, and distribute the source code under the terms of the MIT License. However, please preserve the integrity of the spiritual message and credit the original contributors where due.
*
*  For licensing details, see the LICENSE file in the repository.
*
**/

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