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
    const ringDimension = 140.0;

    return Opacity(
      opacity: opacity,
      child: Stack(
        children: [
          // ... (Your Positioned images remain the same)
          Positioned(
            top: 20,
            left: MediaQuery.of(context).size.width * 0.08,
            child: Image.asset(
              'assets/images/leaves_clustor12.png',
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 20,
            left: MediaQuery.of(context).size.width * 0.7,
            child: Image.asset(
              'assets/images/leaves_clustor11.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),

          // "Adhyay" (Chapters) Spinner
          Positioned(
            top: 30,
            left: MediaQuery.of(context).size.width * 0.22,
            child: CenteredSpinner(
              isSpinning: false,
              anchor: _buildLotus(
                // This calls the updated method
                imageAsset: 'assets/images/lotus_white22.png',
                heroTag: 'whiteLotusHero',
                onTap: () => context.push(AppRoutes.chapters),
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
            left: MediaQuery.of(context).size.width * 0.01,
            child: CenteredSpinner(
              isSpinning: false,
              spinDirection: SpinDirection.counterClockwise,
              anchor: _buildLotus(
                // This also calls the updated method
                imageAsset: 'assets/images/lotus_blue12.png',
                heroTag: 'blueLotusHero',
                onTap: () => context.push(AppRoutes.parayan),
              ),
              child: Image.asset(
                'assets/images/parayan_label.png',
                width: ringDimension,
                height: ringDimension,
              ),
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
  }) {
    return SizedBox(
      width: 100,
      height: 100,
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
                          tween: Tween(begin: 1.0, end: 2.5),
                          weight: 50,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 2.5, end: 1.0),
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
