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
import '../../providers/audio_provider.dart';
import '../../providers/shloka_list_provider.dart';
import '../widgets/full_shloka_card.dart';
import '../../data/static_data.dart';
import '../../data/database_helper_interface.dart';

class ShlokaListScreen extends StatefulWidget {
  final String searchQuery;
  const ShlokaListScreen({super.key, required this.searchQuery});

  @override
  State<ShlokaListScreen> createState() => _ShlokaListScreenState();
}

class _ShlokaListScreenState extends State<ShlokaListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];
  bool _isContinuousPlayEnabled = false;

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
      debugPrint("[CONTINUOUS_PLAY_SM] Stopped event received. Non-stop: $_isContinuousPlayEnabled, Playback Started: $_hasPlaybackStarted");
      // Condition: if nonstop_play_flag is true and playback_state was set to true
      if (_isContinuousPlayEnabled && _hasPlaybackStarted) {
        final lastPlayedIndex = _shlokaProvider.shlokas.indexWhere((s) => '${s.chapterNo}.${s.shlokNo}' == _currentShlokId);
        debugPrint("[CONTINUOUS_PLAY_SM] Last played shloka index: $lastPlayedIndex");

        if (lastPlayedIndex != -1 && lastPlayedIndex < _shlokaProvider.shlokas.length - 1) {
          final nextShloka = _shlokaProvider.shlokas[lastPlayedIndex + 1];
          final nextShlokaId = '${nextShloka.chapterNo}.${nextShloka.shlokNo}';
          debugPrint("[CONTINUOUS_PLAY_SM] Triggering next shloka: $nextShlokaId");

          audioProvider.playOrPauseShloka(nextShloka);
          _currentShlokId = nextShlokaId;

        } else {
          debugPrint("[CONTINUOUS_PLAY_SM] End of chapter or shloka not found. Stopping.");
        }
        _hasPlaybackStarted = false;
        debugPrint("[CONTINUOUS_PLAY_SM] Playback flag reset to false.");
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

  @override
  Widget build(BuildContext context) {
    // When a user presses play, we need to initialize our state machine.
    final audioProviderForInit = Provider.of<AudioProvider>(context, listen: false);
    if (audioProviderForInit.playbackState == PlaybackState.stopped) {
      _hasPlaybackStarted = false; // Reset continuous play tracker
    }
    // This handles cases like a query of "1" or "1,21".
    final chapterNumber = int.tryParse(widget.searchQuery.split(',').first.trim());

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
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Switch(
                            value: _isContinuousPlayEnabled,
                            onChanged: (value) => setState(() => _isContinuousPlayEnabled = value),
                            // This makes the switch more compact vertically.
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          // The label is placed below the switch.
                          Text('Non-Stop Play', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70))
                        ],
                      ),
                    ),
                  ],
                  backgroundColor: Colors.black.withOpacity(0.4),
                  elevation: 0,
                  centerTitle: true,
                )
              : null,
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              SimpleGradientBackground(startColor: Colors.amber.shade100),
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
                            isContinuousPlayEnabled: _isContinuousPlayEnabled,
                            onSwitchChanged: (value) => setState(() => _isContinuousPlayEnabled = value),
                            minExtent: MediaQuery.of(context).padding.top + kToolbarHeight,
                            // Increased maxExtent to make room for the title below the emblem
                            maxExtent: MediaQuery.of(context).padding.top + kToolbarHeight + 250,
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
                                config: _cardConfig,
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
    isLightTheme: true,
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
  final bool isContinuousPlayEnabled;
  final ValueChanged<bool> onSwitchChanged;
  @override
  final double minExtent;
  @override
  final double maxExtent;

  _AnimatingHeaderDelegate({
    required this.chapterNumber,
    required this.title,
    required this.isContinuousPlayEnabled,
    required this.onSwitchChanged,
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

    final double maxTop = minExtent; // Start below the final appbar area
    final double minTop = paddingTop + (kToolbarHeight - minSize) / 2;
    final double currentTop = lerpDouble(maxTop, minTop, t)!;

    // --- NEW: Title animation ---
    // Position
    final double titleMaxTop = maxTop + maxSize + 16; // Below the large emblem
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
    final double contentOpacity = t;

    return Container(
      color: Colors.black.withOpacity(0.01),
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
            child: Center(
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

          // Actions (fades in)
          Positioned(
            top: paddingTop,
            right: 0,
            height: kToolbarHeight,
            child: Opacity(
              opacity: contentOpacity,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: isContinuousPlayEnabled,
                      onChanged: onSwitchChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text('Non-Stop Play', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54))
                  ],
                ),
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

  @override
  bool shouldRebuild(_AnimatingHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        chapterNumber != oldDelegate.chapterNumber ||
        title != oldDelegate.title ||
        isContinuousPlayEnabled != oldDelegate.isContinuousPlayEnabled ||
        onSwitchChanged != oldDelegate.onSwitchChanged;
  }
}
