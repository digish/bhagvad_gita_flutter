import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
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
                  padding: const EdgeInsets.only(bottom: 8.0),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapterName = chapters[index];
                    final chapterNumber = index + 1;

                    return _ChapterCard(
                      chapterNumber: chapterNumber,
                      chapterName: chapterName,
                    );
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

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
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
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 🕉️ Adhyay label
              Text(
                'अध्याय $chapterNumber',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(width: 16),

              // 📖 Chapter name
              Expanded(
                child: Text(chapterName, style: theme.textTheme.bodyLarge),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
