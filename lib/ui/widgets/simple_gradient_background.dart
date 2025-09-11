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
import 'dart:ui';
import './glowing_lotus.dart';


class SimpleGradientBackground extends StatefulWidget {
  final Color? startColor;

  const SimpleGradientBackground({super.key, this.startColor});

  @override
  State<SimpleGradientBackground> createState() => _SimpleGradientBackgroundState();
}

class _SimpleGradientBackgroundState extends State<SimpleGradientBackground>
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
        // Use the provided start color for the gradient, or default to white if null.
        final gradientStartColor = widget.startColor ?? Colors.white;

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gradientStartColor.withOpacity(1.0), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.center, // Fades to white by the center
                ),
              ),
            ),
            // Use the reusable GlowingLotus widget
            const GlowingLotus(
              width: 300,
              height: 300,
              sigma: 5.0,
            ),
            // The bottom leaves image
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: MediaQuery.of(context).size.height,
                height: MediaQuery.of(context).size.width,
                child: Stack(
                  fit: StackFit.expand,
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
                          imageFilter:
                              ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                          child: Transform.rotate(
                            angle: 270 * 3.1415926535 / 180,
                            child: Image.asset(
                              'assets/images/leaves_background.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Crisp leaves image
                    Transform.rotate(
                      angle: 270 * 3.1415926535 / 180,
                      child: Image.asset(
                        'assets/images/leaves_background.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        );
      },
    );
  }
}