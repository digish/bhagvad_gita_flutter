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

import 'dart:ui';
import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/shloka_list_provider.dart';
import '../widgets/full_shloka_card.dart';
import '../../data/static_data.dart';
import '../../data/database_helper_interface.dart';

import '../widgets/responsive_wrapper.dart';
import '../theme/app_colors.dart';

class ShlokaListScreen extends StatefulWidget {
  final String searchQuery;
  final bool showBackButton; // ✨ NEW parameter
  final bool delayEmblem; // ✨ NEW parameter for animation
  final bool isEmbedded; // ✨ NEW parameter for unified background

  const ShlokaListScreen({
    super.key,
    required this.searchQuery,
    this.showBackButton = true, // Default to true
    this.delayEmblem = false,
    this.isEmbedded = false,
  });

  @override
  State<ShlokaListScreen> createState() => _ShlokaListScreenState();
}

class _ShlokaListScreenState extends State<ShlokaListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];

  // ✨ FIX: State for the playback mode, replacing the old boolean.
  PlaybackMode _playbackMode = PlaybackMode.continuous; // Default to Continuous

  String? _currentShlokId;

  // --- FIX: Initialize the provider in initState to make it available to listeners ---
  late final ShlokaListProvider _shlokaProvider;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  @override
  void initState() {
    super.initState();
    final dbHelper = Provider.of<DatabaseHelperInterface>(
      context,
      listen: false,
    );
    final language = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).language;
    final script = Provider.of<SettingsProvider>(context, listen: false).script;
    _shlokaProvider = ShlokaListProvider(
      widget.searchQuery,
      dbHelper,
      language,
      script,
    );

    // ✨ FIX: Get the provider once and store it.
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _audioProvider?.addListener(_handleAudioChange);
  }

  @override
  void dispose() {
    // ✨ FIX: Use the stored provider instance for safe cleanup.
    _audioProvider?.removeListener(_handleAudioChange);
    _shlokaProvider.dispose(); // Dispose the provider we created.
    _scrollController.dispose();
    super.dispose();
  }

  void _handleAudioChange() {
    // ✨ FIX: Use the stored provider instance.
    final audioProvider = _audioProvider;
    if (audioProvider == null) return; // Safety check

    // Always sync the current playing ID from the provider to the local state.
    // This ensures that when the playlist advances (native background play),
    // the UI reflects the change (highlight + scroll).
    final newId = audioProvider.currentPlayingShlokaId;
    if (_currentShlokId != newId) {
      debugPrint("[UI_SYNC] Shloka changed from $_currentShlokId to $newId");
      setState(() {
        _currentShlokId = newId;
      });

      if (_currentShlokId != null) {
        // Auto-scroll logic
        final index = _shlokaProvider.shlokas.indexWhere(
          (s) => '${s.chapterNo}.${s.shlokNo}' == _currentShlokId,
        );
        if (index != -1) {
          _scrollToIndex(index);
        }
      }
    }
  }

  // A more robust scrolling method.
  void _scrollToIndex(int index) {
    if (index < 0 || index >= _itemKeys.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _itemKeys[index];
      if (key.currentContext == null) {
        debugPrint("Cannot scroll to index $index: context is null.");
        return;
      }

      // Check if the item is already reasonably visible.
      final RenderBox renderBox =
          key.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;
      final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

      // Is the item within the visible area (below app bar, above bottom of screen)?
      final isVisible =
          (position.dy >= topPadding) &&
          (position.dy + renderBox.size.height <= screenSize.height);

      if (!isVisible) {
        debugPrint(
          "[SCROLL] Item at index $index is not visible. Scrolling now.",
        );
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.1, // Align near the top of the viewport.
        );
      } else {
        debugPrint(
          "[SCROLL] Item at index $index is already visible. No scroll needed.",
        );
      }
    });
  }

  // --- NEW: Helper methods for the playback mode cycle button ---

  void _cyclePlaybackMode() {
    setState(() {
      final nextIndex = (_playbackMode.index + 1) % PlaybackMode.values.length;
      _playbackMode = PlaybackMode.values[nextIndex];
    });

    // ✨ NEW: If playback is active, reload with the new mode seamlessly
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (audioProvider.playbackState == PlaybackState.playing ||
        audioProvider.playbackState == PlaybackState.paused) {
      if (_currentShlokId != null) {
        // Find the index of the currently playing shloka
        final index = _shlokaProvider.shlokas.indexWhere(
          (s) => '${s.chapterNo}.${s.shlokNo}' == _currentShlokId,
        );

        if (index != -1) {
          audioProvider.playChapter(
            shlokas: _shlokaProvider.shlokas,
            initialIndex: index,
            playbackMode: _playbackMode,
            initialPosition: audioProvider.position,
          );
        }
      }
    }
  }

  Widget _buildPlaybackModeButton({required bool isHeader}) {
    IconData icon;
    String tooltip;

    switch (_playbackMode) {
      case PlaybackMode.single:
        icon = Icons.play_arrow;
        tooltip = 'Single';
        break;
      case PlaybackMode.continuous:
        icon = Icons.playlist_play;
        tooltip = 'Continuous';
        break;
      case PlaybackMode.repeatOne:
        icon = Icons.repeat_one;
        tooltip = 'Repeat';
        break;
    }

    // ✨ FIX: Unify button styles. The search result screen now gets a styled button.
    if (isHeader) {
      // This is for the expanded app bar in chapter view, which is just an icon.
      // This is for the expanded app bar in chapter view.
      return Tooltip(
        message: tooltip,
        child: TextButton.icon(
          onPressed: _cyclePlaybackMode,
          icon: Icon(icon, color: Colors.white, size: 24),
          label: Text(
            tooltip,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      );
    } else {
      // This is for the search result app bar.
      return OutlinedButton.icon(
        onPressed: _cyclePlaybackMode,
        icon: Icon(icon, color: Colors.white70, size: 20),
        label: Text(
          tooltip, // Use the full tooltip as the label
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ), // A slightly more opaque border for better contrast
          side: BorderSide(color: Colors.white.withOpacity(0.7)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // When a user presses play, we need to initialize our state machine.

    // This handles cases like a query of "1" or "1,21".
    final chapterNumber = int.tryParse(
      widget.searchQuery.split(',').first.trim(),
    );

    // --- NEW: Constants for font size control ---
    const double minFontSize = 16.0;
    const double maxFontSize = 32.0;
    const double fontStep = 2.0;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Use .value to provide the existing instance created in initState.
    return ChangeNotifierProvider.value(
      value: _shlokaProvider,
      child: Builder(
        builder: (context) {
          // --- NEW: Calculate localized title ---
          String title;
          if (chapterNumber != null) {
            final script = settingsProvider.script;
            title =
                '${StaticData.getChapterLabel(script)} ${StaticData.localizeNumber(chapterNumber, script)} – ${StaticData.getChapterName(chapterNumber, script)}';
          } else {
            title = StaticData.getQueryTitle(widget.searchQuery);
          }

          return Scaffold(
            // ✨ FIX: Set background color based on settings.
            // If embedded, force transparent.
            backgroundColor: widget.isEmbedded
                ? Colors.transparent
                : (settingsProvider.showBackground
                      ? null // Let the gradient handle it
                      : Theme.of(context).scaffoldBackgroundColor),
            appBar: chapterNumber == null
                ? AppBar(
                    title: Text(
                      title, // Use localized title
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // ✨ FIX: New background color to complement the pink gradient.
                    backgroundColor: Theme.of(
                      context,
                    ).appBarTheme.backgroundColor,
                    elevation: 0,
                    centerTitle: true,
                    leading:
                        widget.showBackButton &&
                            (Theme.of(context).platform == TargetPlatform.iOS &&
                                MediaQuery.of(context).size.width <= 600)
                        ? const BackButton(color: Colors.white)
                        : null, // ✨ Respect showBackButton AND Platform logic
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(50.0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _FontSizeControl(
                              currentSize: settingsProvider.fontSize,
                              onDecrement: () {
                                if (settingsProvider.fontSize > minFontSize) {
                                  settingsProvider.setFontSize(
                                    settingsProvider.fontSize - fontStep,
                                  );
                                }
                              },
                              onIncrement: () {
                                if (settingsProvider.fontSize < maxFontSize) {
                                  settingsProvider.setFontSize(
                                    settingsProvider.fontSize + fontStep,
                                  );
                                }
                              },
                              color: Colors.white,
                            ),
                            _buildPlaybackModeButton(isHeader: false),
                            // ✨ NEW: Book Reading Mode Button
                            if (chapterNumber != null)
                              Tooltip(
                                message: "Read as Book",
                                child: IconButton(
                                  icon: const Icon(Icons.menu_book_rounded),
                                  color: Colors.white,
                                  onPressed: () {
                                    context.push(
                                      '/book-reading/$chapterNumber',
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                : null,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                if (!widget.isEmbedded &&
                    settingsProvider.showBackground &&
                    Theme.of(context).brightness == Brightness.light)
                  SimpleGradientBackground(
                    startColor: chapterNumber == null
                        ? Theme.of(context)
                                  .extension<AppColors>()
                                  ?.searchResultGradientStart ??
                              Colors.pink.shade100
                        : Theme.of(
                                context,
                              ).extension<AppColors>()?.chapterGradientStart ??
                              Colors.amber.shade100,
                  ),
                SafeArea(
                  top: false,
                  bottom: false,
                  // ✨ FIX: Only apply side padding for Search Results (chapterNumber == null)
                  // to avoid double padding in Chapter View (which handles it differently).
                  left: chapterNumber == null,
                  right: true,
                  child: Consumer2<ShlokaListProvider, AudioProvider>(
                    builder: (context, provider, audioProvider, child) {
                      if (provider.isLoading) {
                        // This ensures the Hero widget is present during the page transition.
                        if (chapterNumber != null) {
                          return Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top:
                                    MediaQuery.of(context).padding.top +
                                    kToolbarHeight +
                                    20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ChapterEmblemHeader(
                                    chapterNumber: chapterNumber,
                                  ),
                                  const SizedBox(height: 32),
                                  const CircularProgressIndicator(),
                                ],
                              ),
                            ),
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (provider.shlokas.isEmpty) {
                        return Center(
                          child: Text(
                            'No shlokas found for "${widget.searchQuery}".',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                          ),
                        );
                      }

                      // Ensure the keys list is synchronized with the shlokas list
                      // before attempting to scroll.
                      if (provider.shlokas.isNotEmpty &&
                          _itemKeys.length != provider.shlokas.length) {
                        _itemKeys = List.generate(
                          provider.shlokas.length,
                          (_) => GlobalKey(),
                        );
                      }

                      // If an initial scroll index is set by the provider, trigger the scroll.
                      if (provider.initialScrollIndex != null) {
                        debugPrint(
                          "Scrolling to initial index: ${provider.initialScrollIndex!}",
                        );
                        _scrollToIndex(provider.initialScrollIndex!);
                        // Clear the index in the provider to prevent re-scrolling on rebuilds.
                        provider.clearScrollIndex();
                      }

                      final shlokas = provider.shlokas;
                      // --- AUTO-SCROLL LOGIC ---
                      // This logic triggers whenever the playing ID changes, either from user
                      // interaction or continuous play.
                      // We still read from the provider here for UI updates, but our state machine is independent.
                      // We use a post-frame callback to ensure the widget tree is built before scrolling.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // The scroll should be based on our reliable local state, not the provider's.
                        if (_currentShlokId != null &&
                            _currentShlokId != provider.lastScrolledId) {
                          final playingIndex = shlokas.indexWhere(
                            (s) =>
                                '${s.chapterNo}.${s.shlokNo}' ==
                                _currentShlokId,
                          );
                          if (playingIndex != -1) {
                            _scrollToIndex(playingIndex);
                            provider.setLastScrolledId(
                              _currentShlokId,
                            ); // Prevent re-scrolling
                          }
                        }
                      });
                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          if (chapterNumber == null)
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.top +
                                    kToolbarHeight +
                                    20,
                              ),
                            ),
                          if (chapterNumber != null)
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _AnimatingHeaderDelegate(
                                chapterNumber: chapterNumber,
                                title: title, // Use localized title
                                playbackMode: _playbackMode,
                                onPlaybackModePressed: _cyclePlaybackMode,
                                currentFontSize: settingsProvider.fontSize,
                                onFontSizeIncrement: () {
                                  if (settingsProvider.fontSize < maxFontSize) {
                                    settingsProvider.setFontSize(
                                      settingsProvider.fontSize + fontStep,
                                    );
                                  }
                                },
                                onFontSizeDecrement: () {
                                  if (settingsProvider.fontSize > minFontSize) {
                                    settingsProvider.setFontSize(
                                      settingsProvider.fontSize - fontStep,
                                    );
                                  }
                                },
                                minExtent:
                                    MediaQuery.of(context).padding.top +
                                    kToolbarHeight +
                                    100, // Tightened to reduce top margin while fitting 3 rows
                                // Further increase maxExtent to ensure title and switches are visible initially
                                maxExtent:
                                    MediaQuery.of(context).padding.top + 350,
                                showBackButton:
                                    widget.showBackButton &&
                                    (Theme.of(context).platform ==
                                            TargetPlatform.iOS &&
                                        MediaQuery.of(context).size.width <=
                                            600), // ✨ Pass validated logic
                                delayEmblem: widget.delayEmblem,
                              ),
                            ),
                          // Add some spacing between the header and the first card for chapter views
                          if (chapterNumber != null)
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Container(
                                key: _itemKeys[index],
                                child: ResponsiveWrapper(
                                  child: FullShlokaCard(
                                    shloka: shlokas[index],
                                    config: _cardConfig.copyWith(
                                      baseFontSize: settingsProvider.fontSize,
                                      isLightTheme:
                                          Theme.of(context).brightness ==
                                          Brightness.light,
                                    ),
                                    currentlyPlayingId: _currentShlokId,
                                    onPlayPause: () {
                                      // Call playChapter to start the playlist from this index.
                                      // This ensures background playback works via ConcatenatingAudioSource.
                                      Provider.of<AudioProvider>(
                                        context,
                                        listen: false,
                                      ).playChapter(
                                        shlokas: shlokas,
                                        initialIndex: index,
                                        playbackMode: _playbackMode,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              childCount: shlokas.length,
                            ),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 20),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // A single configuration for the shloka cards to ensure consistency.
  final FullShlokaCardConfig _cardConfig = const FullShlokaCardConfig(
    showSpeaker: true,
    showAnvay: true,
    showBhavarth: true,
    showSeparator: true,
    showColoredCard: true,
    showEmblem: true,
    showShlokIndex: true,
    spacingCompact: false,
    isLightTheme: true, // This will be overridden by the logic below
  );
}

class _ChapterEmblemHeader extends StatelessWidget {
  final int chapterNumber;
  const _ChapterEmblemHeader({required this.chapterNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Hero(
        tag: 'chapterEmblem_$chapterNumber',
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white24,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                // Changed to a bright, golden glow
                color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                spreadRadius: 4,
                blurRadius: 15.0,
                offset: Offset.zero,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _AnimatingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int chapterNumber;
  final String title;
  final PlaybackMode playbackMode;
  final VoidCallback onPlaybackModePressed;
  final double currentFontSize;
  final VoidCallback onFontSizeIncrement;
  final VoidCallback onFontSizeDecrement;
  final double minExtent;
  @override
  final double maxExtent;
  final bool showBackButton; // ✨ NEW parameter
  final bool delayEmblem;

  _AnimatingHeaderDelegate({
    required this.chapterNumber,
    required this.title,
    required this.playbackMode,
    required this.onPlaybackModePressed,
    required this.currentFontSize,
    required this.onFontSizeIncrement,
    required this.onFontSizeDecrement,
    required this.minExtent,
    required this.maxExtent,
    required this.showBackButton,
    required this.delayEmblem,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // ✨ Wrap in LayoutBuilder to get correct width for centering
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Emblem properties
        const double maxSize = 160.0;
        const double minSize = 50.0; // Larger for the side-by-side view
        final double currentSize = lerpDouble(maxSize, minSize, t)!;
        // final double currentRadius = lerpDouble(16.0, minSize / 2, t)!; // Unused

        // Emblem position
        final double maxLeft = (width - maxSize) / 2;

        // Target Left Logic:
        // The Button Island is centered with constraints (maxWidth: 700).
        // It has a horizontal margin of 16 on both sides.
        // So visually: ScreenEdge -> Margin(16) -> FlexibleSpace -> Island -> FlexibleSpace -> Margin(16).
        // Actually the margin is on the Container inside Center.
        // Island Width = (width - 32).clamp(300.0, 700.0);
        // Island Left Offset = (width - Island Width) / 2;
        // Inside Island: Padding(horizontal: 16).
        // Target Emblem Left = Island Left Offset + 16.
        final double islandWidth = (width - 32.0).clamp(300.0, 700.0);
        final double islandLeftOffset = (width - islandWidth) / 2;
        // Target Emblem Left calculation:
        // Island padding (16) + (Back Button Width (20) + Gap (8) IF shown).
        final double backButtonOffset = showBackButton ? (20.0 + 8.0) : 0.0;
        final double minLeft = islandLeftOffset + 16.0 + backButtonOffset;

        final double currentLeft = lerpDouble(maxLeft, minLeft, t)!;

        // Calculate minTop to align with the center of the Button Island
        // Island is at bottom 16.
        // Island Content Height: Title(24) + Gap(8) + Controls(48) = 80.
        // Island Vertical Padding: 12*2 = 24.
        // Total Height = 104 + 16 (bottom) = 120.
        // Top of Island = minExtent - 120.
        // Top of Row = minExtent - 108.
        // Center of Row = minExtent - 68.
        // Emblem Top = minExtent - 68 - 25 = minExtent - 93.
        // Island Bottom (16) + Height (~124)/2 = Center Y from bottom (78).
        // Emblem Top from bottom = 78 + 25 = 103.
        // minTop = minExtent - 103.
        final double minTop = minExtent - 103;
        final double maxTop = paddingTop + 20; // Start near the top

        final double currentTop = lerpDouble(maxTop, minTop, t)!;

        return Container(
          // ✨ FIX: Animate the background color to become less transparent as it collapses.
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: paddingTop,
                right: 0,
                height: kToolbarHeight,
                child:
                    Container(), // This space is now empty, actions are moved below
              ),

              // --- NEW: Button Island ---
              Positioned(
                bottom: 16, // Float near bottom
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    // height: 56, // removed fixed height
                    // width:  constraints.maxWidth * 0.9, // Constrain width or let it hug content
                    constraints: BoxConstraints(maxWidth: 700, minWidth: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white.withOpacity(0.4)
                          : Colors.black.withOpacity(
                              0.6,
                            ), // Semi-transparent for glass effect
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white.withOpacity(0.4)
                            : Colors.white12,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 16,
                          sigmaY: 16,
                        ), // Stronger blur
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            // Main Layout: Left Image, Right Content
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Back Button & Docked Emblem Group
                              GestureDetector(
                                onTap: showBackButton
                                    ? () => context.pop()
                                    : null,
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (showBackButton) ...[
                                      const Icon(
                                        Icons.arrow_back_ios_new,
                                        size: 20,
                                        // color: Colors.black87, // Removed hardcoded color
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (t > 0.95)
                                      Hero(
                                        tag: 'chapterEmblem_$chapterNumber',
                                        child: _buildEmblemContent(
                                          minSize,
                                          1.0,
                                        ),
                                      )
                                    else
                                      const SizedBox(width: 50, height: 50),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 16),

                              // 2. Right Content (Title + Controls Lines)
                              Expanded(
                                child: SizedBox(
                                  height: 110, // Increased height for 3 rows
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Line 1: Title
                                      SizedBox(
                                        height: 20, // Compact title slot
                                        child: Center(
                                          child: Text(
                                            title,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.color,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      15, // Slightly smaller
                                                  height: 1.2,
                                                ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // Line 2: Font & Playback Controls
                                      SizedBox(
                                        height: 48,
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            return FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  _FontSizeControl(
                                                    currentSize:
                                                        currentFontSize,
                                                    onDecrement:
                                                        onFontSizeDecrement,
                                                    onIncrement:
                                                        onFontSizeIncrement,
                                                    color:
                                                        Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.color ??
                                                        Colors.black87,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _VerticalDivider(),
                                                  const SizedBox(width: 8),
                                                  TextButton(
                                                    onPressed:
                                                        onPlaybackModePressed,
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                            vertical: 2,
                                                          ),
                                                      foregroundColor:
                                                          Theme.of(context)
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.color,
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          playbackMode ==
                                                                  PlaybackMode
                                                                      .single
                                                              ? Icons.play_arrow
                                                              : playbackMode ==
                                                                    PlaybackMode
                                                                        .continuous
                                                              ? Icons
                                                                    .playlist_play
                                                              : Icons
                                                                    .repeat_one,
                                                          color: Theme.of(
                                                            context,
                                                          ).iconTheme.color,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          playbackMode ==
                                                                  PlaybackMode
                                                                      .single
                                                              ? 'Single'
                                                              : playbackMode ==
                                                                    PlaybackMode
                                                                        .continuous
                                                              ? 'Continuous'
                                                              : 'Repeat',
                                                          style: TextStyle(
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.color,
                                                            fontSize: 10,
                                                            height: 1.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      // Line 3: Read Mode Button (Centered)
                                      SizedBox(
                                        height: 36,
                                        child: Center(
                                          child: FilledButton.icon(
                                            onPressed: () {
                                              context.push(
                                                '/book-reading/$chapterNumber',
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.menu_book_rounded,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              "Commentry Book",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.deepOrange,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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

              // The animating emblem (Only visible during transition)
              if (t <= 0.95)
                Positioned(
                  top: currentTop,
                  left: currentLeft,
                  child: delayEmblem
                      ? TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: const Interval(
                            0.5,
                            1.0,
                            curve: Curves.easeIn,
                          ), // Delay start
                          builder: (context, value, child) {
                            return Opacity(opacity: value, child: child);
                          },
                          child: _buildEmblemContent(currentSize, t),
                        )
                      : Hero(
                          tag: 'chapterEmblem_$chapterNumber',
                          child: _buildEmblemContent(currentSize, t),
                        ),
                ),

              // ✨ FIX: Moved Back Button to the end of Stack to ensure it's on top
              // Added some vertical spacing to avoid iPad multitasking controls
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmblemContent(double currentSize, double t) {
    return Container(
      width: currentSize,
      height: currentSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
        boxShadow: [
          BoxShadow(
            // Animate the glow properties
            color: Colors.amber.withOpacity(lerpDouble(0.8, 0.7, t)!),
            spreadRadius: lerpDouble(4, 2, t)!,
            blurRadius: lerpDouble(15, 12, t)!,
            offset: Offset.zero,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  bool shouldRebuild(_AnimatingHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        chapterNumber != oldDelegate.chapterNumber ||
        title != oldDelegate.title ||
        playbackMode != oldDelegate.playbackMode ||
        onPlaybackModePressed != oldDelegate.onPlaybackModePressed ||
        currentFontSize != oldDelegate.currentFontSize ||
        onFontSizeIncrement != oldDelegate.onFontSizeIncrement ||
        onFontSizeDecrement != oldDelegate.onFontSizeDecrement;
  }
}

/// A reusable widget for switches in the collapsing header.

// --- NEW: Font size control widget ---
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

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
