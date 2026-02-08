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
import 'package:provider/provider.dart';
import '../../data/static_data.dart';
import '../../navigation/app_router.dart';
import '../../providers/settings_provider.dart';
import 'shloka_list_screen.dart';

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen>
    with TickerProviderStateMixin {
  int? _selectedChapter;
  final Map<int, GlobalKey> _emblemKeys = {}; // Keys for list items
  bool _shouldDelayEmblem = false; // Flag to delay detail pane emblem

  void _runFlyAnimation(int chapter, GlobalKey sourceKey) {
    // 1. Get Source Rect
    final RenderBox? sourceBox =
        sourceKey.currentContext?.findRenderObject() as RenderBox?;
    if (sourceBox == null) return;
    final startRect = sourceBox.localToGlobal(Offset.zero) & sourceBox.size;

    // 2. Calculate Target Rect
    final screenWidth = MediaQuery.of(context).size.width;
    final paddingLeft = MediaQuery.of(context).padding.left;
    final contentWidth = 160.0;
    final detailStartX = contentWidth + paddingLeft + 1.0;
    final detailWidth = screenWidth - detailStartX;
    final targetSize = 160.0;

    // Center of the detail pane
    final targetX = detailStartX + (detailWidth / 2) - (targetSize / 2);
    final topPadding = MediaQuery.of(context).padding.top;

    final endRect = Rect.fromLTWH(
      targetX,
      topPadding + 20,
      targetSize,
      targetSize,
    );

    // 3. Create Animation
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final rectAnimation = RectTween(begin: startRect, end: endRect).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic),
    );

    overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final rect = rectAnimation.value!;
            // Simple opacity fade out at the very end to blend?
            // Or just remove.
            return Positioned(
              left: rect.left,
              top: rect.top,
              width: rect.width,
              height: rect.height,
              child: Material(
                elevation: 8, // Add some shadow during flight
                color: Colors.transparent,
                shape: const CircleBorder(), // Or RoundedRect matching target
                // Target is RoundedRect(16). Source is Circle.
                // We should animate shape too?
                // Visual complication: Source is circle, Target is RRest.
                // Let's just use ClipRRect with animated radius.
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(
                      lerpDouble(28, 16, controller.value)!, // 56/2 = 28
                    ),
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        Colors.amber.withOpacity(0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    image: DecorationImage(
                      image: AssetImage(
                        'assets/emblems/chapter/ch${chapter.toString().padLeft(2, '0')}.png',
                      ),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.white.withOpacity(0.2),
                        BlendMode.screen,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.6),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlayState.insert(overlayEntry);
    controller.forward().then((_) {
      overlayEntry.remove();
      controller.dispose();
      // Ensure emblem is visible in Detail Pane now
      // (It faded in over 600ms, matching this duration)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consume SettingsProvider to get current script
    final settings = Provider.of<SettingsProvider>(context);
    final script = settings.script;
    final chapters = StaticData.geetaAdhyay; // Only for length count if needed

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        final bool isCompactMasterPane = isWideScreen;
        final double contentWidth = isCompactMasterPane ? 160.0 : 350.0;
        final double masterPaneWidth =
            contentWidth + MediaQuery.of(context).padding.left;

        // If we are on a wide screen and no chapter is selected, select the first one by default.
        if (isWideScreen && _selectedChapter == null) {
          // We can't setState during build, so we just use a local variable or effect.
          // Better to initialize it in initState, but we don't know screen size there.
          // So we'll handle it in the logic below: if _selectedChapter is null, use 1.
        }

        final activeChapter = _selectedChapter ?? 1;

        if (isWideScreen) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: Stack(
              children: [
                // ✨ Unified Background for Split View
                // const SimpleGradientBackground(startColor: Colors.white),
                // Using null lets it fall through to Scaffold background or we can make it conditional
                if (Theme.of(context).brightness == Brightness.light)
                  const SimpleGradientBackground(startColor: Colors.white),
                Row(
                  children: [
                    // MASTER PANE
                    SizedBox(
                      width: masterPaneWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          SafeArea(
                            bottom: false,
                            left: false,
                            right: false,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: 16.0,
                                right: 16.0,
                                bottom: 16.0,
                                left:
                                    16.0 + MediaQuery.of(context).padding.left,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // const Align(
                                  //   alignment: Alignment.centerLeft,
                                  //   child: BackButton(color: Colors.black),
                                  // ),
                                  Hero(
                                    tag: 'whiteLotusHero',
                                    child: Image.asset(
                                      'assets/images/lotus_white22.png',
                                      height: isCompactMasterPane ? 60 : 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.only(
                                top: 0,
                                bottom: 16,
                                left: MediaQuery.of(
                                  context,
                                ).padding.left, // Avoid rail
                              ),
                              itemCount: chapters.length,
                              itemBuilder: (context, index) {
                                final chapterNumber = index + 1;
                                final chapterName = StaticData.getChapterName(
                                  chapterNumber,
                                  script,
                                );
                                final localizedNum = StaticData.localizeNumber(
                                  chapterNumber,
                                  script,
                                );
                                final localizedLabel =
                                    StaticData.getChapterLabel(script);
                                final isSelected =
                                    chapterNumber == activeChapter;

                                // Ensure key exists
                                if (!_emblemKeys.containsKey(chapterNumber)) {
                                  _emblemKeys[chapterNumber] = GlobalKey();
                                }

                                return _ChapterCard(
                                  chapterNumber: chapterNumber,
                                  chapterName: chapterName,
                                  script: script, // Pass script if needed
                                  localizedNumber: localizedNum,
                                  localizedLabel: localizedLabel,
                                  isSelected: isSelected,
                                  isWideScreen: true,
                                  isCompact: isCompactMasterPane,
                                  emblemKey: _emblemKeys[chapterNumber],
                                  onTap: () {
                                    // Trigger animation
                                    if (_emblemKeys.containsKey(
                                      chapterNumber,
                                    )) {
                                      _runFlyAnimation(
                                        chapterNumber,
                                        _emblemKeys[chapterNumber]!,
                                      );
                                    }
                                    setState(() {
                                      _selectedChapter = chapterNumber;
                                      _shouldDelayEmblem =
                                          true; // Delay target appearance
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // DIVIDER
                    const VerticalDivider(width: 1, thickness: 1),
                    // DETAIL PANE
                    Expanded(
                      child: ClipRect(
                        child: ShlokaListScreen(
                          key: ValueKey(
                            activeChapter,
                          ), // Force rebuild on change
                          searchQuery: activeChapter.toString(),
                          showBackButton: false,
                          delayEmblem: _shouldDelayEmblem, // Pass flag
                          isEmbedded: true, // ✨ Use shared background
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // MOBILE LAYOUT (Original)
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              if (Theme.of(context).brightness == Brightness.light)
                const SimpleGradientBackground(startColor: Colors.white),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 24,
                    ), // ✨ Standardized spacing matching CreditsScreen
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // ✨ FIX: Uniform Back Button Logic (iOS + Narrow only)
                        if (Theme.of(context).platform == TargetPlatform.iOS &&
                            constraints.maxWidth <= 600)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: BackButton(
                                color: Theme.of(context).iconTheme.color,
                              ),
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: IconButton(
                              icon: const Icon(
                                Icons.bookmark_outline,
                                color: Colors.black,
                                size: 28,
                              ),
                              onPressed: () {
                                context.push(AppRoutes.bookmarks);
                              },
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/');
                            }
                          },
                          child: Hero(
                            tag: 'whiteLotusHero',
                            child: Image.asset(
                              'assets/images/lotus_white22.png',
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 8.0),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          final chapterNumber = index + 1;
                          final chapterName = StaticData.getChapterName(
                            chapterNumber,
                            script,
                          );
                          final localizedNum = StaticData.localizeNumber(
                            chapterNumber,
                            script,
                          );
                          final localizedLabel = StaticData.getChapterLabel(
                            script,
                          );
                          return _ChapterCard(
                            chapterNumber: chapterNumber,
                            chapterName: chapterName,
                            localizedNumber: localizedNum,
                            localizedLabel: localizedLabel,
                            script: script,
                            isSelected: false,
                            isWideScreen: false,
                            isCompact: false,
                            onTap: () {
                              context.push('/shloka-list/$chapterNumber');
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final int chapterNumber;
  final String chapterName;
  final String localizedNumber;
  final String localizedLabel;
  final String script;
  final bool isSelected;
  final bool isWideScreen;
  final bool isCompact;
  final VoidCallback onTap;
  final GlobalKey? emblemKey; // ✨ NEW parameter

  const _ChapterCard({
    required this.chapterNumber,
    required this.chapterName,
    required this.localizedNumber,
    required this.localizedLabel,
    required this.script,
    required this.isSelected,
    required this.isWideScreen,
    required this.isCompact,
    required this.onTap,
    this.emblemKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        elevation: isSelected ? 8 : 2,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Theme.of(context).brightness == Brightness.light
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white.withOpacity(0.7),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: isCompact
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Hero(
                              tag: isWideScreen
                                  ? 'chapterListEmblem_$chapterNumber'
                                  : 'chapterEmblem_$chapterNumber',
                              child: Container(
                                key: emblemKey, // ✨ Assign key
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withOpacity(0.6), // Gold tint
                                    width: 2.5,
                                  ),
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.9),
                                      Colors.amber.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.8),
                                      spreadRadius: 3,
                                      blurRadius: 15.0,
                                      offset: Offset.zero,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.25),
                                      BlendMode.screen,
                                    ),
                                    child: Image.asset(
                                      'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$localizedLabel $localizedNumber',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.9,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chapterName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Hero(
                              tag: isWideScreen
                                  ? 'chapterListEmblem_$chapterNumber'
                                  : 'chapterEmblem_$chapterNumber',
                              child: Container(
                                key: emblemKey, // ✨ Assign key
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withOpacity(0.6), // Gold tint
                                    width: 2.5,
                                  ),
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.9),
                                      Colors.amber.withOpacity(0.4),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.8),
                                      spreadRadius: 3,
                                      blurRadius: 15.0,
                                      offset: Offset.zero,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withOpacity(0.25),
                                      BlendMode.screen,
                                    ),
                                    child: Image.asset(
                                      'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
                                      fit: BoxFit.cover,
                                    ),
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
                                    '$localizedLabel $localizedNumber',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    chapterName,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.85),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
