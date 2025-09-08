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

import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../data/static_data.dart';

class ChaptersScreen extends StatelessWidget {
  const ChaptersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chapters = StaticData.geetaAdhyay;

    return Scaffold(
      // Set a base background color, which is good practice
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. --- This is the background widget ---
          // It's the first child, so it's at the bottom of the stack.
          //const DarkenedAnimatedBackground(opacity: 0.7),
          const SimpleGradientBackground(),

          // 2. --- This is your original content ---
          // This Column is placed on top of the background.
          Column(
            children: [
              // 1. --- This is the starting Hero widget ---
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  context.pop();
                },
                child: Hero(
                  tag: 'whiteLotusHero', // The unique tag for the animation
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
                            child: (toHeroContext.widget as Hero).child,
                          ),
                        );
                      },
                  child: Image.asset(
                    'assets/images/lotus_white22.png',
                    height: 120, // A good size for this screen
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // --- End of Hero widget ---

              // 2. The ListView is now wrapped in an Expanded widget
              // This makes it take up the remaining screen space.
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 16, bottom: 8.0),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapterName = chapters[index];
                    final chapterNumber = index + 1;
                    return _ChapterCard(
                        chapterNumber: chapterNumber, chapterName: chapterName);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ... _ChapterCard widget remains the same ...
class _ChapterCard extends StatelessWidget {
  final int chapterNumber;
  final String chapterName;

  const _ChapterCard({required this.chapterNumber, required this.chapterName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
  // By applying the filter to each card, the background between cards remains clear.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: 2,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
              ),
              child: InkWell(
                onTap: () {
                  context.push('/shloka-list/$chapterNumber');
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 🪷 Chapter emblem
                      Hero(
                        tag: 'chapterEmblem_$chapterNumber',
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.9),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow( // Changed to a bright, golden glow
                                color: Colors.amber.withOpacity(0.7),
                                spreadRadius: 2,
                                blurRadius: 12.0,
                                offset: Offset
                                    .zero, // Centered glow instead of a drop shadow
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'अध्याय $chapterNumber',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary.withOpacity(0.9),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chapterName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.black.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                                fontSize: 20, // Explicitly setting size for prominence
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ), // Row
                ), // Padding
              ), // InkWell
            ), // Container
          ),
        ),
      ),
    );
  }
}
