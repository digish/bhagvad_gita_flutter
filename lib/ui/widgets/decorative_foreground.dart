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
import 'package:bhagvadgeeta/navigation/app_router.dart';
import 'centered_spinner.dart';

class DecorativeForeground extends StatelessWidget {
  final double opacity;

  const DecorativeForeground({super.key, this.opacity = 1.0});

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
    final double railOffset = isTablet ? 80.0 : 0.0;

    return Opacity(
      opacity: opacity,
      child: Stack(
        children: [
          // ... (Your Positioned images remain the same)
          Positioned(
            top: 20,
            left:
                MediaQuery.of(context).size.width * 0.08 +
                railOffset, // Shifted
            child: Stack(
              children: [
                // Shadow
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
                // Original Image
                Image.asset(
                  'assets/images/leaves_clustor12.png',
                  width: leaves1Size,
                  height: leaves1Size,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            left:
                MediaQuery.of(context).size.width * 0.7 + railOffset, // Shifted
            child: Stack(
              children: [
                // Shadow
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
                // Original Image
                Image.asset(
                  'assets/images/leaves_clustor11.png',
                  width: leaves2Size,
                  height: leaves2Size,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),

          // "Adhyay" (Chapters) Spinner
          Positioned(
            top: 30,
            left:
                MediaQuery.of(context).size.width * 0.22 +
                railOffset, // Shifted
            child: CenteredSpinner(
              isSpinning: false,
              anchor: _buildLotus(
                // This calls the updated method
                imageAsset: 'assets/images/lotus_white22.png',
                heroTag: 'whiteLotusHero',
                onTap: () => context.push(AppRoutes.chapters),
                size: lotusSize,
              ),
              child: Image.asset(
                'assets/images/adhyay_label.png',
                width: ringDimension,
                height: ringDimension,
              ),
            ),
          ),

          // "Parayan" Spinner
          Positioned(
            top: 100,
            left:
                MediaQuery.of(context).size.width * 0.01 +
                railOffset, // Shifted
            child: CenteredSpinner(
              isSpinning: false,
              spinDirection: SpinDirection.counterClockwise,
              anchor: _buildLotus(
                // This also calls the updated method
                imageAsset: 'assets/images/lotus_blue12.png',
                heroTag: 'blueLotusHero',
                onTap: () => context.push(AppRoutes.parayan),
                size: lotusSize,
              ),
              child: Image.asset(
                'assets/images/parayan_label.png',
                width: ringDimension,
                height: ringDimension,
              ),
            ),
          ),

          // "Credits" Spinner
          Positioned(
            top: 65,
            right:
                MediaQuery.of(context).size.width *
                0.15, // No shift needed for right-aligned
            child: CenteredSpinner(
              isSpinning: false,
              spinDirection: SpinDirection.clockwise,
              anchor: _buildLotus(
                imageAsset: 'assets/images/lotus_gold.png', // New asset
                heroTag: 'creditsLotusHero', // New hero tag
                onTap: () => context.push(AppRoutes.credits),
                size: lotusSize,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build the lotus
  Widget _buildLotus({
    required String imageAsset,
    required String heroTag,
    required VoidCallback onTap,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background glow effect
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

          // Main interactive lotus
          GestureDetector(
            onTap: onTap,
            child: Hero(
              tag: heroTag,

              // ✨ ADD THE CUSTOM ANIMATION BUILDER HERE ✨
              flightShuttleBuilder:
                  (
                    flightContext,
                    animation,
                    flightDirection,
                    fromHeroContext,
                    toHeroContext,
                  ) {
                    final rotationAnimation = animation.drive(
                      Tween<double>(begin: 0.0, end: 1.0), // 1 full rotation
                    );
                    final scaleAnimation = animation.drive(
                      TweenSequence([
                        TweenSequenceItem(
                          tween: Tween(begin: 1.0, end: 1.0),
                          weight: 50,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 1.0, end: 1.0),
                          weight: 50,
                        ),
                      ]),
                    );

                    return RotationTransition(
                      turns: rotationAnimation,
                      child: ScaleTransition(
                        scale: scaleAnimation,
                        // Use the widget from the destination Hero as the shuttle
                        child: (toHeroContext.widget as Hero).child,
                      ),
                    );
                  },
              child: Image.asset(imageAsset, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
