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
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import './glowing_lotus.dart';

class SimpleGradientBackground extends StatefulWidget {
  final Color? startColor;
  final bool? showMandala;

  const SimpleGradientBackground({
    super.key,
    this.startColor,
    this.showMandala,
  });

  @override
  State<SimpleGradientBackground> createState() =>
      _SimpleGradientBackgroundState();
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
    // Watch the SettingsProvider only if showMandala is not explicitly provided
    final settings = Provider.of<SettingsProvider>(context);
    final bool effectiveShowMandala =
        widget.showMandala ?? settings.showBackground;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Use the provided start color for the gradient, or default to white if null.
        final gradientStartColor = widget.startColor ?? Colors.white;
        final appColors = Theme.of(context).extension<AppColors>();

        if (!effectiveShowMandala) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        gradientStartColor == Colors.white
                            ? Colors.black
                            : gradientStartColor,
                        appColors?.defaultGradientEnd ??
                            const Color(0xFF1E1E1E),
                      ]
                    : [
                        gradientStartColor,
                        appColors?.defaultGradientEnd ??
                            const Color(0xFFFCE4EC),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          (gradientStartColor == Colors.white
                                  ? Colors.black
                                  : gradientStartColor)
                              .withOpacity(1.0),
                          Colors.black,
                        ]
                      : [gradientStartColor.withOpacity(1.0), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment
                      .center, // Fades to white (or black) by the center
                ),
              ),
            ),
            // Use the reusable GlowingLotus widget
            const GlowingLotus(width: 300, height: 300, sigma: 5.0),
            // The bottom leaves image
            Positioned(
              bottom: -2,
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  // Golden glow layer
                  Opacity(
                    opacity: 0.5,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(
                                0.1,
                              ) // Subtle light glow in dark mode
                            : const Color.fromARGB(
                                255,
                                0,
                                0,
                                0,
                              ), // Dark shadow in light mode
                        BlendMode.srcATop,
                      ),
                      child: ImageFiltered(
                        imageFilter: ImageFilter.blur(
                          sigmaX: 12.0,
                          sigmaY: 12.0,
                        ),
                        child: Image.asset(
                          'assets/images/leaf.png',
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  // Crisp leaves image
                  Image.asset(
                    'assets/images/leaf.png',
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
