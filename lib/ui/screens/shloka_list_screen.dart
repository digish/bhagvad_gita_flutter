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
import '../../models/shloka_result.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/shloka_list_provider.dart';
import '../widgets/full_shloka_card.dart';
import '../../data/static_data.dart';
import '../../data/database_helper_interface.dart';

enum PlaybackMode { single, continuous, repeatOne }

class ShlokaListScreen extends StatefulWidget {
  final String searchQuery;
  const ShlokaListScreen({super.key, required this.searchQuery});

  @override
  State<ShlokaListScreen> createState() => _ShlokaListScreenState();
}

class _ShlokaListScreenState extends State<ShlokaListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];

  // ✨ FIX: State for the playback mode, replacing the old boolean.
  PlaybackMode _playbackMode = PlaybackMode.single;

  String? _currentShlokId;
  bool _hasPlaybackStarted = false;
  
  // --- FIX: Initialize the provider in initState to make it available to listeners ---
  late final ShlokaListProvider _shlokaProvider;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  @override
  void initState() {
    super.initState();
    final dbHelper = Provider.of<DatabaseHelperInterface>(context, listen: false);
    _shlokaProvider = ShlokaListProvider(widget.searchQuery, dbHelper);

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

  // This should not be async. We want to react to state changes, not wait for them.
  void _handleAudioChange() {
    // ✨ FIX: Use the stored provider instance.
    final audioProvider = _audioProvider;
    if (audioProvider == null) return; // Safety check
    final currentPlaybackState = audioProvider.playbackState;

    if (currentPlaybackState == PlaybackState.playing) {
      if (_currentShlokId != null) _hasPlaybackStarted = true;
      debugPrint("[CONTINUOUS_PLAY_SM] Playback started for $_currentShlokId. Flag set to true.");
      return;
    }
    if (currentPlaybackState == PlaybackState.stopped) {
      debugPrint("[PLAYBACK_SM] Stopped event received. Mode: $_playbackMode, Playback Started: $_hasPlaybackStarted");

      if (!_hasPlaybackStarted) return; // Don't do anything if playback wasn't properly started.

      final lastPlayedIndex = _shlokaProvider.shlokas.indexWhere((s) => '${s.chapterNo}.${s.shlokNo}' == _currentShlokId);
      if (lastPlayedIndex == -1) {
        debugPrint("[PLAYBACK_SM] Could not find last played shloka. Stopping.");
        _hasPlaybackStarted = false;
        return;
      }

      switch (_playbackMode) {
        case PlaybackMode.single:
          // Do nothing, just let it stop.
          debugPrint("[PLAYBACK_SM] Mode is 'single'. Playback will stop.");
          break;
        case PlaybackMode.continuous:
          debugPrint("[PLAYBACK_SM] Mode is 'continuous'. Checking for next shloka.");
          if (lastPlayedIndex < _shlokaProvider.shlokas.length - 1) {
            final nextShloka = _shlokaProvider.shlokas[lastPlayedIndex + 1];
            final nextShlokaId = '${nextShloka.chapterNo}.${nextShloka.shlokNo}';
            debugPrint("[PLAYBACK_SM] Triggering next shloka: $nextShlokaId");
            audioProvider.playOrPauseShloka(nextShloka);
            _currentShlokId = nextShlokaId;
          } else {
            debugPrint("[PLAYBACK_SM] End of chapter. Stopping.");
          }
          break;
        case PlaybackMode.repeatOne:
          debugPrint("[PLAYBACK_SM] Mode is 'repeatOne'. Repeating shloka $_currentShlokId.");
          final currentShloka = _shlokaProvider.shlokas[lastPlayedIndex];
          audioProvider.playOrPauseShloka(currentShloka);
          break;
      }
      _hasPlaybackStarted = false; // Reset the flag after handling the event.
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
      final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;
      final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
 
      // Is the item within the visible area (below app bar, above bottom of screen)?
      final isVisible = (position.dy >= topPadding) && (position.dy + renderBox.size.height <= screenSize.height);
 
      if (!isVisible) {
        debugPrint("[SCROLL] Item at index $index is not visible. Scrolling now.");
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.1, // Align near the top of the viewport.
        );
      }
      else {
        debugPrint("[SCROLL] Item at index $index is already visible. No scroll needed.");
      }
    });
  }

  // --- NEW: Helper methods for the playback mode cycle button ---

  void _cyclePlaybackMode() {
    setState(() {
      final nextIndex = (_playbackMode.index + 1) % PlaybackMode.values.length;
      _playbackMode = PlaybackMode.values[nextIndex];
    });
  }

  Widget _buildPlaybackModeButton({required bool isHeader}) {
    IconData icon;
    String tooltip;

    switch (_playbackMode) {
      case PlaybackMode.single:
        icon = Icons.play_arrow;
        tooltip = 'Single Play';
        break;
      case PlaybackMode.continuous:
        icon = Icons.playlist_play;
        tooltip = 'Continuous Play';
        break;
      case PlaybackMode.repeatOne:
        icon = Icons.repeat_one;
        tooltip = 'Repeat Shloka';
        break;
    }

    // ✨ FIX: Unify button styles. The search result screen now gets a styled button.
    if (isHeader) {
      // This is for the expanded app bar in chapter view, which is just an icon.
      return Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon),
          color: Colors.white70,
          onPressed: _cyclePlaybackMode,
        ),
      );
    } else {
      // This is for the search result app bar.
      return OutlinedButton.icon(
        onPressed: _cyclePlaybackMode,
        icon: Icon(icon, color: Colors.white70, size: 20),
        label: Text(
          tooltip, // Use the full tooltip as the label
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // A slightly more opaque border for better contrast
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
    final audioProviderForInit = Provider.of<AudioProvider>(context, listen: false);
    if (audioProviderForInit.playbackState == PlaybackState.stopped) {
      _hasPlaybackStarted = false; // Reset continuous play tracker
    }
    // This handles cases like a query of "1" or "1,21".
    final chapterNumber = int.tryParse(widget.searchQuery.split(',').first.trim());

    // --- NEW: Constants for font size control ---
    const double minFontSize = 16.0;
    const double maxFontSize = 32.0;
    const double fontStep = 2.0;
    final settingsProvider = Provider.of<SettingsProvider>(context);

    // Use .value to provide the existing instance created in initState.
    return ChangeNotifierProvider.value(
      value: _shlokaProvider,
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: chapterNumber == null
              ? AppBar(
                  title: Text(
                    StaticData.getQueryTitle(widget.searchQuery),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),                  
                  // ✨ FIX: New background color to complement the pink gradient.
                  backgroundColor: Colors.pink.shade900,
                  elevation: 0,
                  centerTitle: true,
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
                                 settingsProvider.setFontSize(settingsProvider.fontSize - fontStep);
                               }
                             },
                             onIncrement: () {
                               if (settingsProvider.fontSize < maxFontSize) {
                                 settingsProvider.setFontSize(settingsProvider.fontSize + fontStep);
                               }
                             },
                             color: Colors.white,
                           ),
                           _buildPlaybackModeButton(isHeader: false),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              SimpleGradientBackground(
                startColor: chapterNumber == null
                    ? Colors.pink.shade100 // Pink for search results to match lotus
                    : Colors.amber.shade100, // Amber for chapter view
              ),
              Consumer2<ShlokaListProvider, AudioProvider>(
                builder: (context, provider, audioProvider, child) {
                  if (provider.isLoading) {
                    // This ensures the Hero widget is present during the page transition.
                    if (chapterNumber != null) {
                      return Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ChapterEmblemHeader(chapterNumber: chapterNumber),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                      ),
                    );
                  }

                  // Ensure the keys list is synchronized with the shlokas list
                  // before attempting to scroll.
                  if (provider.shlokas.isNotEmpty && _itemKeys.length != provider.shlokas.length) {
                    _itemKeys = List.generate(provider.shlokas.length, (_) => GlobalKey());
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
                    if (_currentShlokId != null && _currentShlokId != provider.lastScrolledId) {
                      final playingIndex = shlokas.indexWhere(
                          (s) => '${s.chapterNo}.${s.shlokNo}' == _currentShlokId);
                      if (playingIndex != -1) {
                        _scrollToIndex(playingIndex);
                        provider.setLastScrolledId(_currentShlokId); // Prevent re-scrolling
                      }
                    }
                  });
                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      if (chapterNumber == null)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                          ),
                        ),
                      if (chapterNumber != null)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _AnimatingHeaderDelegate(
                            chapterNumber: chapterNumber,
                            title: StaticData.getQueryTitle(widget.searchQuery),
                            playbackMode: _playbackMode,
                            onPlaybackModePressed: _cyclePlaybackMode,
                            currentFontSize: settingsProvider.fontSize,
                            onFontSizeIncrement: () {
                              if (settingsProvider.fontSize < maxFontSize) {
                                settingsProvider.setFontSize(settingsProvider.fontSize + fontStep);
                              }
                            },
                            onFontSizeDecrement: () {
                              if (settingsProvider.fontSize > minFontSize) {
                                settingsProvider.setFontSize(settingsProvider.fontSize - fontStep);
                              }
                            },
                            minExtent: MediaQuery.of(context).padding.top + kToolbarHeight + 50, // Increased for the second row
                            // Further increase maxExtent to ensure title and switches are visible initially
                            maxExtent: MediaQuery.of(context).padding.top + 350,
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
                              child: FullShlokaCard(
                                shloka: shlokas[index],
                                config: _cardConfig.copyWith(baseFontSize: settingsProvider.fontSize),
                                currentlyPlayingId: _currentShlokId,
                                onPlayPause: () {
                                  // When the user manually plays, update our local tracker.
                                  _currentShlokId = '${shlokas[index].chapterNo}.${shlokas[index].shlokNo}';
                                  _hasPlaybackStarted = false; // Reset for the new shloka
                                },
                              )),
                          childCount: shlokas.length,
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      }),
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

/// A reusable widget for switches in the AppBar.
class _AppBarSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AppBarSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row( // Each switch is a Row: Label + Switch
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall // Use a brighter white for better contrast on the new background
                ?.copyWith(color: Colors.white)),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

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
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
            boxShadow: [
              BoxShadow( // Changed to a bright, golden glow
                color: Colors.amber.withOpacity(0.8),
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
  @override
  final double minExtent;
  @override
  final double maxExtent;

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
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Emblem properties
    const double maxSize = 160.0;
    const double minSize = 40.0;
    final double currentSize = lerpDouble(maxSize, minSize, t)!;
    final double currentRadius = lerpDouble(16.0, minSize / 2, t)!;

    // Emblem position
    final double maxLeft = (MediaQuery.of(context).size.width - maxSize) / 2;
    final double minLeft = 56.0; // Position next to back button
    final double currentLeft = lerpDouble(maxLeft, minLeft, t)!;

    final double maxTop = paddingTop + 20; // Start near the top
    final double minTop = paddingTop + (kToolbarHeight - minSize) / 2;
    final double currentTop = lerpDouble(maxTop, minTop, t)!;

    // --- NEW: Title animation ---
    // Position
    final double titleMaxTop = maxTop + maxSize + 8; // Positioned right below the large emblem
    final double titleMinTop = paddingTop;
    final double titleCurrentTop = lerpDouble(titleMaxTop, titleMinTop, t)!;

    final double titleMaxHorizontalPadding = 16.0;
    final double titleMinHorizontalPadding = 100.0; // To fit between back button and actions
    final double titleCurrentHorizontalPadding = lerpDouble(titleMaxHorizontalPadding, titleMinHorizontalPadding, t)!;

    // Font size
    final double titleMaxFontSize = Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24.0;
    final double titleMinFontSize = Theme.of(context).textTheme.titleLarge?.fontSize ?? 20.0;
    final double titleCurrentFontSize = lerpDouble(titleMaxFontSize, titleMinFontSize, t)!;

    // Opacity for elements that appear when collapsed
    // Let's make the controls visible from the start by changing the opacity logic
    final double controlsOpacity = lerpDouble(0.0, 1.0, t.clamp(0.5, 1.0))!;
    final double collapsedHeaderOpacity = t;

    return Container(
      // ✨ FIX: Animate the background color to become less transparent as it collapses.
      color: Colors.white.withOpacity(lerpDouble(0.0, 0.85, t)!),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Back button (always visible)
          Positioned(
            top: paddingTop,
            left: 4,
            child: const BackButton(color: Colors.black87),
          ),

          // Title (fades in)
          Positioned(
            top: titleCurrentTop,
            left: titleCurrentHorizontalPadding,
            right: titleCurrentHorizontalPadding,
            height: kToolbarHeight,
            child: Opacity(
              opacity: lerpDouble(1.0, 0.0, t.clamp(0.0, 0.5) * 2)!, // Fade out the large title
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: titleCurrentFontSize,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // A separate title that fades in when collapsed
          Positioned(
            top: paddingTop,
            left: 100,
            right: 100,
            height: kToolbarHeight,
            child: Opacity(
              opacity: collapsedHeaderOpacity,
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.black87, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
          ),

          // Actions (fades in)
          Positioned(
            top: paddingTop,
            right: 0,
            height: kToolbarHeight,
            child: Container(), // This space is now empty, actions are moved below
          ),

          // --- NEW: Positioned controls row ---
          Positioned(
            top: paddingTop + kToolbarHeight, // Positioned below the main app bar area
            left: 0,
            right: 0,
            height: 50, // The height we added to minExtent
            child: Opacity( // Fades in with the rest of the collapsed header
              opacity: collapsedHeaderOpacity, 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FontSizeControl(                    
                    currentSize: currentFontSize,
                    onDecrement: onFontSizeDecrement,
                    onIncrement: onFontSizeIncrement,
                    color: Colors.black54,
                  ),
                  _buildPlaybackModeButtonForHeader(),
                ],
              ),
            ),
          ),

          // The animating emblem
          Positioned(
            top: currentTop,
            left: currentLeft,
            child: Hero(
              tag: 'chapterEmblem_$chapterNumber',
              child: Container(
                width: currentSize,
                height: currentSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(currentRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                  boxShadow: [
                    BoxShadow( // Animate the glow properties
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackModeButtonForHeader() {
    IconData icon;
    String label;

    switch (playbackMode) {
      case PlaybackMode.single:
        icon = Icons.play_arrow;
        label = 'Single Play';
        break;
      case PlaybackMode.continuous:
        icon = Icons.playlist_play;
        label = 'Continuous';
        break;
      case PlaybackMode.repeatOne:
        icon = Icons.repeat_one;
        label = 'Repeat';
        break;
    }

    return OutlinedButton.icon(
      onPressed: onPlaybackModePressed,
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
class _HeaderSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _HeaderSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row( // Each switch is a Row: Label + Switch
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

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
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
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
