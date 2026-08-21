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
  /// Bottom lotus leaves. Defaults to [showMandala] / settings when null.
  final bool? showLeaves;

  const SimpleGradientBackground({
    super.key,
    this.startColor,
    this.showMandala,
    this.showLeaves,
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
    final settings = Provider.of<SettingsProvider>(context);
    final bool effectiveShowMandala =
        widget.showMandala ?? settings.showBackground;
    final bool effectiveShowLeaves =
        widget.showLeaves ?? effectiveShowMandala;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final gradientStartColor = widget.startColor ?? Colors.white;
        final appColors = Theme.of(context).extension<AppColors>();
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: effectiveShowMandala
                      ? (isDark
                            ? [
                                (gradientStartColor == Colors.white
                                        ? Colors.black
                                        : gradientStartColor)
                                    .withOpacity(1.0),
                                Colors.black,
                              ]
                            : [
                                gradientStartColor.withOpacity(1.0),
                                Colors.white,
                              ])
                      : (isDark
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
                              ]),
                  begin: Alignment.topCenter,
                  end: effectiveShowMandala
                      ? Alignment.center
                      : Alignment.bottomCenter,
                ),
              ),
            ),
            if (effectiveShowMandala)
              const GlowingLotus(width: 300, height: 300, sigma: 5.0),
            if (effectiveShowLeaves)
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Opacity(
                    // Soften so scrolling text stays readable over the leaves.
                    opacity: effectiveShowMandala ? 1.0 : 0.45,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: effectiveShowMandala ? 0.0 : 10.0,
                        sigmaY: effectiveShowMandala ? 0.0 : 10.0,
                      ),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: 0.5,
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : const Color.fromARGB(255, 0, 0, 0),
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
                          Image.asset(
                            'assets/images/leaf.png',
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.bottomCenter,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
