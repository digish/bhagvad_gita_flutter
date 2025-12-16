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
import 'shloka_list_screen.dart';

class ChaptersScreen extends StatefulWidget {
  const ChaptersScreen({super.key});

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  int? _selectedChapter;

  @override
  Widget build(BuildContext context) {
    final chapters = StaticData.geetaAdhyay;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        // If we are on a wide screen and no chapter is selected, select the first one by default.
        if (isWideScreen && _selectedChapter == null) {
          // We can't setState during build, so we just use a local variable or effect.
          // Better to initialize it in initState, but we don't know screen size there.
          // So we'll handle it in the logic below: if _selectedChapter is null, use 1.
        }

        final activeChapter = _selectedChapter ?? 1;

        if (isWideScreen) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Row(
              children: [
                // MASTER PANE
                SizedBox(
                  width: 350,
                  child: Stack(
                    children: [
                      const SimpleGradientBackground(startColor: Colors.white),
                      Column(
                        children: [
                          // Header
                          SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
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
                                      height: 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 0,
                                bottom: 16,
                              ),
                              itemCount: chapters.length,
                              itemBuilder: (context, index) {
                                final chapterName = chapters[index];
                                final chapterNumber = index + 1;
                                final isSelected =
                                    chapterNumber == activeChapter;

                                return _ChapterCard(
                                  chapterNumber: chapterNumber,
                                  chapterName: chapterName,
                                  isSelected: isSelected,
                                  isWideScreen: true,
                                  onTap: () {
                                    setState(() {
                                      _selectedChapter = chapterNumber;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
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
                      key: ValueKey(activeChapter), // Force rebuild on change
                      searchQuery: activeChapter.toString(),
                      showBackButton: false,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // MOBILE LAYOUT (Original)
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
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
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: BackButton(color: Colors.black),
                            ),
                          ),
                        GestureDetector(
                          onTap: () {
                            context.pop();
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
                          final chapterName = chapters[index];
                          final chapterNumber = index + 1;
                          return _ChapterCard(
                            chapterNumber: chapterNumber,
                            chapterName: chapterName,
                            isSelected: false,
                            isWideScreen: false,
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
  final bool isSelected;
  final bool isWideScreen;
  final VoidCallback onTap;

  const _ChapterCard({
    required this.chapterNumber,
    required this.chapterName,
    required this.isSelected,
    required this.isWideScreen,
    required this.onTap,
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
                    ? Colors.amber.withOpacity(0.3)
                    : Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSelected
                      ? Colors.amber
                      : Colors.white.withOpacity(0.7),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(
                        tag: isWideScreen
                            ? 'chapterListEmblem_$chapterNumber'
                            : 'chapterEmblem_$chapterNumber',
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
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.7),
                                spreadRadius: 2,
                                blurRadius: 12.0,
                                offset: Offset.zero,
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
                                color: theme.colorScheme.primary.withOpacity(
                                  0.9,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chapterName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.black.withOpacity(0.85),
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
