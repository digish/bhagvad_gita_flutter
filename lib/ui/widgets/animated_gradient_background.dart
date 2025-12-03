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

// lib/ui/widgets/animated_gradient_background.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import './water_ripple_background.dart';

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // The water ripple effect remains as the base background
            const WaterRippleBackground(),

            // The bottom leaves image
            Positioned(
              bottom: -2, // Slight overlap to ensure no gap
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  // Golden glow layer
                  Opacity(
                    opacity: 0.5,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        const Color.fromARGB(255, 0, 0, 0),
                        BlendMode.srcATop,
                      ),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 12.0,
                          sigmaY: 12.0,
                        ),
                        child: Image.asset(
                          'assets/images/leaves_background.png',
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Crisp leaves image
                  Image.asset(
                    'assets/images/leaves_background.png',
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.bottomCenter,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
