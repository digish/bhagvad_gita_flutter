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
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/static_data.dart';
import 'dart:ui';

import '../../providers/parayan_provider.dart';
import '../widgets/custom_scroll_indicator.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';
import '../widgets/responsive_wrapper.dart';

// --- NEW: Enum to manage the content display modes ---
enum ParayanDisplayMode { shlokOnly, shlokAndAnvay, all }

class ParayanScreen extends StatefulWidget {
  const ParayanScreen({super.key});

  @override
  State<ParayanScreen> createState() => _ParayanScreenState();
}

class _ParayanScreenState extends State<ParayanScreen> {
  // ✨ FIX: Revert to ItemScrollController and ItemPositionsListener for accuracy.
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  ParayanDisplayMode _displayMode = ParayanDisplayMode.shlokAndAnvay;

  final ValueNotifier<String> _currentPositionLabelNotifier = ValueNotifier(
    // This is not used anymore but kept for potential future use.
    'अध्याय 1, श्लोक 1',
  );

  // --- NEW: State to track the currently playing shloka ID ---
  String? _currentlyPlayingId;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  @override
  void initState() {
    super.initState();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _audioProvider?.addListener(_audioListener);
  }

  // --- NEW: Listener to update the playing ID ---
  void _audioListener() {
    if (mounted &&
        _currentlyPlayingId != _audioProvider?.currentPlayingShlokaId) {
      setState(() {
        _currentlyPlayingId = _audioProvider?.currentPlayingShlokaId;
      });
    }
  }

  @override
  void dispose() {
    _currentPositionLabelNotifier.dispose(); // ✨ Add this line
    _audioProvider?.removeListener(_audioListener);
    super.dispose();
  }

  // ✨ NEW: Method to scroll to a specific item using its GlobalKey.
  void _scrollToIndex(int index) {
    // ✨ FIX: Use the itemScrollController which is designed for this.
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Constants for font size control ---

    // Use a Consumer to rebuild when font size changes.
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      /*appBar: AppBar(
          title: const Text('Full Parayan'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ), */
      // ✨ FIX: Set background color based on settings.
      backgroundColor: settingsProvider.showBackground
          ? Colors
                .black // Original dark background for gradient
          : Colors.grey.shade200, // Solid light background for readability
      body: Stack(
        children: [
          if (settingsProvider.showBackground)
            SimpleGradientBackground(
              startColor: const Color.fromARGB(255, 103, 108, 255),
            ),
          Consumer<ParayanProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // --- NEW: Determine card configuration based on display mode ---
              final FullShlokaCardConfig cardConfig;
              switch (_displayMode) {
                case ParayanDisplayMode.shlokOnly:
                  cardConfig = FullShlokaCardConfig(
                    baseFontSize: settingsProvider.fontSize,
                    showAnvay: false,
                    showBhavarth: false,
                    showSeparator: false,
                  );
                  break;
                case ParayanDisplayMode.shlokAndAnvay:
                  cardConfig = FullShlokaCardConfig(
                    baseFontSize: settingsProvider.fontSize,
                    showAnvay: true,
                    showBhavarth: false,
                    showSeparator: true,
                  );
                  break;
                case ParayanDisplayMode.all:
                  cardConfig = FullShlokaCardConfig(
                    baseFontSize: settingsProvider.fontSize,
                    showAnvay: true,
                    showBhavarth: true,
                    showSeparator: true,
                  );
                  break;
              }

              final shlokas = provider.shlokas;

              // ✨ FIX: Revert to ScrollablePositionedList
              return ResponsiveWrapper(
                child: ScrollablePositionedList.builder(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: shlokas.length,
                  // ✨ FIX: Apply the initial padding here. This is the correct way to offset the list
                  // without interfering with the item position listener.
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 240,
                    left: MediaQuery.of(
                      context,
                    ).padding.left, // Respect injected padding
                    right: 50,
                    bottom: 8.0,
                  ),
                  itemBuilder: (context, index) {
                    final shloka = shlokas[index];
                    final previousShloka = (index > 0)
                        ? shlokas[index - 1]
                        : null;

                    final isChapterStart =
                        previousShloka == null ||
                        shloka.chapterNo != previousShloka.chapterNo;
                    final isChapterEnd =
                        (index == shlokas.length - 1) ||
                        shloka.chapterNo != shlokas[index + 1].chapterNo;
                    final speakerChanged =
                        previousShloka != null &&
                        previousShloka.speaker != shloka.speaker;

                    return Column(
                      children: [
                        if (isChapterStart)
                          _ChapterStartHeader(
                            chapterNumber: int.tryParse(shloka.chapterNo) ?? 0,
                          ),
                        if (speakerChanged || isChapterStart)
                          _SpeakerHeader(speaker: shloka.speaker ?? "Uvacha"),
                        FullShlokaCard(
                          shloka: shloka,
                          currentlyPlayingId: _currentlyPlayingId,
                          onPlayPause: () {
                            setState(() {
                              _currentlyPlayingId =
                                  '${shloka.chapterNo}.${shloka.shlokNo}';
                            });
                          },
                          config: cardConfig.copyWith(
                            showSpeaker: false,
                            showColoredCard: false,
                            showEmblem: false,
                            showShlokIndex: true,
                            spacingCompact: true,
                            isLightTheme: true,
                          ),
                        ),
                        if (isChapterEnd)
                          _ChapterEndFooter(
                            chapterNumber: int.tryParse(shloka.chapterNo) ?? 0,
                            chapterName:
                                StaticData.geetaAdhyay[(int.tryParse(
                                          shloka.chapterNo,
                                        ) ??
                                        1) -
                                    1],
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
          // ✨ NEW: The scroll indicator now sits on top of the CustomScrollView
          Consumer<ParayanProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const SizedBox.shrink();
              }
              // The header is a separate stateful widget, so we can't directly access its
              // animation controller here. However, we can listen to the same scroll
              // positions to derive the animation state.
              return ValueListenableBuilder<Iterable<ItemPosition>>(
                valueListenable: _itemPositionsListener.itemPositions,
                builder: (context, positions, _) {
                  bool isAtTop =
                      positions.isEmpty ||
                      (positions.first.index == 0 &&
                          positions.first.itemLeadingEdge >= 0);
                  final double topPadding = isAtTop
                      ? 240.0 // Expanded header height
                      : MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            50; // Collapsed header height
                  return Positioned(
                    right: 0,
                    top: topPadding,
                    bottom: 0,
                    child: CustomScrollIndicator(
                      itemPositionsListener:
                          _itemPositionsListener, // ✨ FIX: Pass the listener
                      itemCount: provider.shlokas.length,
                      chapterMarkers: provider.chapterStartIndices,
                      chapterLabels: provider.chapterStartIndices.map((i) {
                        final chapterNo = provider.shlokas[i].chapterNo;
                        return chapterNo;
                      }).toList(),
                      onLotusTap: (index) {
                        final chapterIndex =
                            provider.chapterStartIndices[index];
                        _scrollToIndex(chapterIndex);
                      },
                    ),
                  );
                },
              );
            },
          ),
          // --- Animating Header Layer ---
          AnimatingParayanHeader(
            itemPositionsListener: _itemPositionsListener,
            settingsProvider: settingsProvider,
          ),
        ],
      ),
    );
  }

  // --- NEW: Cycle button for display mode ---
  void _cycleDisplayMode() {
    setState(() {
      final nextIndex =
          (_displayMode.index + 1) % ParayanDisplayMode.values.length;
      _displayMode = ParayanDisplayMode.values[nextIndex];
    });
  }

  Widget _buildDisplayModeButton() {
    IconData icon;
    String label;

    switch (_displayMode) {
      case ParayanDisplayMode.shlokOnly:
        icon = Icons.article_outlined;
        label = 'Shlok Only';
        break;
      case ParayanDisplayMode.shlokAndAnvay:
        icon = Icons.segment;
        label = 'Shlok & Anvay';
        break;
      case ParayanDisplayMode.all:
        icon = Icons.view_headline;
        label = 'Show All';
        break;
    }

    return OutlinedButton.icon(
      onPressed: _cycleDisplayMode,
      icon: Icon(icon, color: Colors.black54, size: 20),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: Colors.black.withOpacity(0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
    );
  }
}

// ✨ NEW: A dedicated StatefulWidget for the animating header.
class AnimatingParayanHeader extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final SettingsProvider settingsProvider;

  const AnimatingParayanHeader({
    super.key,
    required this.itemPositionsListener,
    required this.settingsProvider,
  });

  @override
  State<AnimatingParayanHeader> createState() => _AnimatingParayanHeaderState();
}

class _AnimatingParayanHeaderState extends State<AnimatingParayanHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  String _currentLabel = 'अध्याय 1, श्लोक 1';
  int _lastTopIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    widget.itemPositionsListener.itemPositions.addListener(_scrollListener);
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions.removeListener(_scrollListener);
    _animationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || !mounted) return;

    // --- Trigger Logic ---
    // Find the item with the smallest index.
    final absoluteTopItem = positions.reduce(
      (min, p) => p.index < min.index ? p : min,
    );

    // Calculate animation value based on scroll position
    if (absoluteTopItem.index == 0) {
      final viewportHeight = MediaQuery.of(context).size.height;
      final paddingTop = MediaQuery.of(context).padding.top;

      // The Y position of the first item's top edge
      final itemY = absoluteTopItem.itemLeadingEdge * viewportHeight;

      // Define the scroll range for the animation
      // Start: Item is at its initial padded position (Expanded Header)
      final startY = paddingTop + 240.0;

      // End: Item is at the bottom of the collapsed header (Collapsed Header)
      final endY = paddingTop + kToolbarHeight + 50;

      // Calculate progress t: 0.0 at startY, 1.0 at endY
      // As itemY goes down (scrolling up), t should go to 0? No, itemY goes UP when scrolling DOWN.
      // Scrolling DOWN (content moves UP): itemY decreases.
      // We want t to go 0 -> 1 as itemY goes startY -> endY.
      final t = (startY - itemY) / (startY - endY);
      _animationController.value = t.clamp(0.0, 1.0);
    } else {
      // If the first item is scrolled out of view, we are fully collapsed
      _animationController.value = 1.0;
    }

    // --- Shloka Count Logic ---
    // ✨ FIX: Find the first item that is visible *below* the header.
    final double headerHeight = lerpDouble(
      240.0,
      MediaQuery.of(context).padding.top + kToolbarHeight + 50,
      _animationController.value,
    )!;
    final visibleBelowHeader = positions.where(
      (p) => p.itemTrailingEdge > headerHeight,
    );

    // ✨ FIX: Check if any items are visible below the header before reducing.
    final ItemPosition topVisibleItem = visibleBelowHeader.isNotEmpty
        ? visibleBelowHeader.reduce(
            (min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min,
          )
        : absoluteTopItem; // Fallback to the absolute top item if none are fully visible yet.

    if (topVisibleItem.index != _lastTopIndex) {
      final parayanProvider = Provider.of<ParayanProvider>(
        context,
        listen: false,
      );
      if (parayanProvider.shlokas.isNotEmpty &&
          topVisibleItem.index < parayanProvider.shlokas.length) {
        final shloka = parayanProvider.shlokas[topVisibleItem.index];
        setState(() {
          _currentLabel = 'अध्याय ${shloka.chapterNo}, श्लोक ${shloka.shlokNo}';
          _lastTopIndex = topVisibleItem.index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // These values are now static within the build method.
    const double maxHeaderHeight = 240;
    final double minHeaderHeight =
        MediaQuery.of(context).padding.top + kToolbarHeight + 50;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // The animation progress 't' is now driven by the AnimationController.
        final t = _animationController.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            // All the lerp calculations remain the same.
            const double maxLotusSize = 120.0;
            const double minLotusSize = 40.0;
            final double currentLotusSize = lerpDouble(
              maxLotusSize,
              minLotusSize,
              t,
            )!;
            final double maxLotusTop = MediaQuery.of(context).padding.top + 20;
            final double minLotusTop =
                MediaQuery.of(context).padding.top +
                (kToolbarHeight - minLotusSize) / 2;
            final double currentLotusTop = lerpDouble(
              maxLotusTop,
              minLotusTop,
              t,
            )!;
            final double maxLotusLeft =
                (width - maxLotusSize) / 2; // ✨ Use local width
            final double minLotusLeft =
                56.0 +
                MediaQuery.of(
                  context,
                ).padding.left; // ✨ Shifted to make room for rail
            final double currentLotusLeft = lerpDouble(
              maxLotusLeft,
              minLotusLeft,
              t,
            )!;

            final double maxTextTop = currentLotusTop + maxLotusSize + 8;
            final double minTextTop = minLotusTop;
            final double currentTextTop = lerpDouble(
              maxTextTop,
              minTextTop,
              t,
            )!;
            final double maxTextLeft = 0;
            final double minTextLeft = minLotusLeft + minLotusSize + 16;
            final double currentTextLeft = lerpDouble(
              maxTextLeft,
              minTextLeft,
              t,
            )!;
            final double textOpacity = lerpDouble(
              1.0,
              0.0,
              t.clamp(0.0, 0.5) * 2,
            )!;
            final double collapsedTextOpacity = t;

            return Container(
              height: lerpDouble(maxHeaderHeight, minHeaderHeight, t),
              color: Colors.indigo.shade50.withOpacity(t * 0.95),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Back Button (always visible)

                  // Expanded Controls (unchanged)
                  // Collapsed Controls (unchanged)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Opacity(
                      opacity: collapsedTextOpacity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _FontSizeControl(
                            currentSize: widget.settingsProvider.fontSize,
                            onDecrement: () {
                              if (widget.settingsProvider.fontSize > 16.0) {
                                widget.settingsProvider.setFontSize(
                                  widget.settingsProvider.fontSize - 2.0,
                                );
                              }
                            },
                            onIncrement: () {
                              if (widget.settingsProvider.fontSize < 32.0) {
                                widget.settingsProvider.setFontSize(
                                  widget.settingsProvider.fontSize + 2.0,
                                );
                              }
                            },
                            color: Colors.black54,
                          ),
                          (context
                                  .findAncestorStateOfType<
                                    _ParayanScreenState
                                  >()!)
                              ._buildDisplayModeButton(),
                          // --- NEW: Background Toggle Button (Collapsed) ---
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) {
                              return IconButton(
                                icon: Icon(
                                  settings.showBackground
                                      ? Icons.image
                                      : Icons.image_not_supported,
                                  color: Colors.black54,
                                ),
                                tooltip: settings.showBackground
                                    ? 'Hide Background'
                                    : 'Show Background',
                                onPressed: () => settings.setShowBackground(
                                  !settings.showBackground,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Animating Lotus (unchanged)
                  Positioned(
                    top: currentLotusTop,
                    left: currentLotusLeft,
                    child: GestureDetector(
                      onTap: MediaQuery.of(context).size.width > 600
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Hero(
                        tag: 'blueLotusHero',
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
                        child: Image.asset(
                          'assets/images/lotus_blue12.png',
                          height: currentLotusSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  // Animating Text Label (now uses state variable)
                  Positioned(
                    top: currentTextTop,
                    left: currentTextLeft,
                    right: 0,
                    height: kToolbarHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: textOpacity,
                          child: Text(
                            _currentLabel,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Opacity(
                          opacity: collapsedTextOpacity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _currentLabel,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ✨ FIX: Back Button moved to end of Stack and spacing standardized
                  // Only show on iOS and narrow screens (<= 600)
                  if (Theme.of(context).platform == TargetPlatform.iOS &&
                      MediaQuery.of(context).size.width <= 600)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      left: 4,
                      child: const BackButton(color: Colors.black87),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- Reusable private widgets for the list items ---

class _ChapterStartHeader extends StatelessWidget {
  final int chapterNumber;

  const _ChapterStartHeader({required this.chapterNumber});

  @override
  Widget build(BuildContext context) {
    // This could be styled more elaborately later
    // FIX: The `getChapterTitle` method had a range error for chapter 18.
    // Using `geetaAdhyay` list directly with correct 0-based indexing is safer
    // and consistent with other parts of the app (e.g., _ChapterEndFooter).
    // We clamp the chapter number to be at least 1 to prevent negative indices.
    String chapterName =
        StaticData.geetaAdhyay[(chapterNumber > 0 ? chapterNumber : 1) - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Text(
        'अध्याय $chapterNumber $chapterName',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 4, 123, 192),
        ),
      ),
    );
  }
}

// --- NEW: Font size control widget (copied from shloka_list_screen) ---
class _FontSizeControl extends StatelessWidget {
  final double currentSize;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color color;

  const _FontSizeControl({
    required this.currentSize,
    required this.onDecrement,
    required this.onIncrement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: color),
          onPressed: onDecrement,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '${currentSize.toInt()}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: color),
          onPressed: onIncrement,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

class _SpeakerHeader extends StatelessWidget {
  final String speaker;
  const _SpeakerHeader({required this.speaker});

  // ✨ Helper function to get the emblem asset path based on the speaker's name
  String? _getSpeakerEmblemPath(String speakerName) {
    switch (speakerName) {
      case 'श्री भगवान':
        return 'assets/emblems/krishna.png';
      case 'अर्जुन':
        return 'assets/emblems/arjun.png';
      case 'संजय':
        return 'assets/emblems/sanjay.png';
      case 'धृतराष्ट्र':
        return 'assets/emblems/dhrutrashtra.png';
      default:
        // Return null if there's no emblem for the speaker
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the path for the emblem, which might be null
    final String? emblemPath = _getSpeakerEmblemPath(speaker);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      // Use a Column to stack the emblem and text vertically
      child: Column(
        children: [
          // Conditionally show the emblem only if a path exists
          if (emblemPath != null) ...[
            Image.asset(
              emblemPath,
              height: 50, // Adjust the size of the emblem as needed
            ),
            const SizedBox(height: 8), // Adds a little space
          ],

          // The original speaker text
          Text(
            '$speaker उवाच',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterEndFooter extends StatelessWidget {
  final int chapterNumber;
  final String chapterName;
  const _ChapterEndFooter({
    required this.chapterNumber,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    final colophonText =
        "ॐ तत्सदिति श्रीमद्भगवद्गीतासूपनिषत्सु\nब्रह्मविद्यायां योगशास्त्रे श्रीकृष्णार्जुनसंवादे\n$chapterName नाम अध्यायः $chapterNumber ॥";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
      child: Text(
        colophonText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
