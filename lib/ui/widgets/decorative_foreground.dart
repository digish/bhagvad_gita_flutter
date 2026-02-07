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

// lib/ui/widgets/decorative_foreground.dart

import 'dart:ui';
// ✨ ADD THIS IMPORT for the rotation animation
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bhagvadgeeta/navigation/app_router.dart';
import 'centered_spinner.dart';
import '../../data/static_data.dart';
import '../../providers/settings_provider.dart';

class DecorativeForeground extends StatelessWidget {
  final double opacity;
  final Animation<double>? scaleAnimation;

  const DecorativeForeground({
    super.key,
    this.opacity = 1.0,
    this.scaleAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    // Sizes based on device type
    final double ringDimension = isTablet ? 200.0 : 140.0;
    final double leaves1Size = isTablet ? 220.0 : 150.0;
    final double leaves2Size = isTablet ? 150.0 : 100.0;
    final double lotusSize = isTablet ? 150.0 : 100.0;

    // Adjusted offset for rail
    final double railOffset = isTablet ? 100.0 : 0.0;

    // Derived animation for "Settling" effect (Bouncy)
    final Animation<double> effectiveScale =
        scaleAnimation ?? const AlwaysStoppedAnimation(1.0);
    final Animation<double> bounceScale = CurvedAnimation(
      parent: effectiveScale,
      curve: Curves.easeOutBack,
    );

    return Opacity(
      opacity: opacity,
      child: Stack(
        children: [
          // Left Leaves
          Positioned(
            top: 20,
            left: MediaQuery.of(context).size.width * 0.08 + railOffset,
            child: ScaleTransition(
              scale: bounceScale,
              child: Stack(
                children: [
                  Transform.translate(
                    offset: const Offset(4, 4),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          'assets/images/leaves_clustor12.png',
                          width: leaves1Size,
                          height: leaves1Size,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/leaves_clustor12.png',
                    width: leaves1Size,
                    height: leaves1Size,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),

          // Right Leaves
          Positioned(
            top: 20,
            left: MediaQuery.of(context).size.width * 0.7 + railOffset,
            child: ScaleTransition(
              scale: bounceScale,
              child: Stack(
                children: [
                  Transform.translate(
                    offset: const Offset(4, 4),
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.srcATop,
                        ),
                        child: Image.asset(
                          'assets/images/leaves_clustor11.png',
                          width: leaves2Size,
                          height: leaves2Size,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Image.asset(
                    'assets/images/leaves_clustor11.png',
                    width: leaves2Size,
                    height: leaves2Size,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),

          // "Adhyay" (Chapters) Spinner
          Positioned(
            top: 30,
            left: MediaQuery.of(context).size.width * 0.22 + railOffset,
            child: ScaleTransition(
              scale: bounceScale,
              child: CenteredSpinner(
                isSpinning: false,
                anchor: _buildLotus(
                  imageAsset: 'assets/images/lotus_white22.png',
                  heroTag: 'whiteLotusHero',
                  onTap: () => context.push(AppRoutes.chapters),
                  size: lotusSize,
                ),
                child: SizedBox(
                  width: ringDimension,
                  height: ringDimension,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, 55),
                      child: Text(
                        StaticData.localizeTerm(
                          'adhyay',
                          Provider.of<SettingsProvider>(context).script,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // "Parayan" Spinner
          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width * 0.01 + railOffset,
            child: ScaleTransition(
              scale: bounceScale,
              child: CenteredSpinner(
                isSpinning: false,
                spinDirection: SpinDirection.counterClockwise,
                anchor: _buildLotus(
                  imageAsset: 'assets/images/lotus_blue12.png',
                  heroTag: 'blueLotusHero',
                  onTap: () => context.push(AppRoutes.parayan),
                  size: lotusSize,
                ),
                child: SizedBox(
                  width: ringDimension,
                  height: ringDimension,
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, 55),
                      child: Text(
                        StaticData.localizeTerm(
                          'parayan',
                          Provider.of<SettingsProvider>(context).script,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // "Credits" Spinner
          Positioned(
            top: 65,
            right: MediaQuery.of(context).size.width * 0.15,
            child: ScaleTransition(
              scale: bounceScale,
              child: CenteredSpinner(
                isSpinning: false,
                spinDirection: SpinDirection.clockwise,
                anchor: _buildLotus(
                  imageAsset: 'assets/images/lotus_gold.png',
                  heroTag: 'creditsLotusHero',
                  onTap: () => context.push(AppRoutes.credits),
                  size: lotusSize,
                ),
                child: const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLotus({
    required String imageAsset,
    required String heroTag,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.5,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    heroTag == 'whiteLotusHero'
                        ? Colors.white
                        : heroTag == 'creditsLotusHero'
                        ? Colors.amber
                        : const Color.fromARGB(255, 0, 150, 255),
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(imageAsset, fit: BoxFit.contain),
                ),
              ),
            ),
            Hero(
              tag: heroTag,
              flightShuttleBuilder:
                  (
                    flightContext,
                    animation,
                    flightDirection,
                    fromHeroContext,
                    toHeroContext,
                  ) {
                    final rotationAnimation = animation.drive(
                      Tween<double>(begin: 0.0, end: 1.0),
                    );
                    return RotationTransition(
                      turns: rotationAnimation,
                      child: (toHeroContext.widget as Hero).child,
                    );
                  },
              child: Image.asset(imageAsset, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
