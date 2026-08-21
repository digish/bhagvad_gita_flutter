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
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/static_data.dart';
import 'dart:ui';

import '../../providers/parayan_provider.dart';
import '../widgets/chapter_seek_rail.dart';
import '../widgets/parayan_action_island.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/font_size_control.dart';
import '../theme/app_colors.dart';

// --- NEW: Enum to manage the content display modes ---
enum ParayanDisplayMode { shlokOnly, shlokAndAnvay, all }

/// Expanded header band below the status bar (glass island + docked lotus).
const double _kParayanExpandedExtra = 120.0;

/// Collapsed header band below the status bar.
const double _kParayanCollapsedExtra = 108.0;

/// Right inset reserved for [ChapterSeekRail].
const double _kParayanRailInset = 28.0;

/// Viewport fraction for the reading focus line (cursor / card center target).
const double _kParayanFocusLine = 0.40;

double _parayanExpandedHeaderHeight(BuildContext context) =>
    MediaQuery.of(context).padding.top + _kParayanExpandedExtra;

double _parayanCollapsedHeaderHeight(BuildContext context) =>
    MediaQuery.of(context).padding.top + _kParayanCollapsedExtra;

// PlaybackMode is now imported from audio_provider.dart

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

  ParayanDisplayMode _displayMode = ParayanDisplayMode.shlokOnly;

  // REMOVED: Local PlaybackMode state. Now using AudioProvider directly.

  final ValueNotifier<String> _currentPositionLabelNotifier = ValueNotifier(
    // This is not used anymore but kept for potential future use.
    'अध्याय 1, श्लोक 1',
  );

  // --- NEW: State to track the currently playing shloka ID ---
  String? _currentlyPlayingId;

  /// Selected card after tap (null = nothing selected / no cursor / no highlight).
  int? _selectedIndex;
  bool _actionsVisible = false;
  bool _isSelectingCard = false;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  @override
  void initState() {
    super.initState();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _audioProvider?.addListener(_handleAudioChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context);
    final parayanProvider = Provider.of<ParayanProvider>(
      context,
      listen: false,
    );

    // Defer the update to the next frame to avoid 'setState() or markNeedsBuild() called during build'
    WidgetsBinding.instance.addPostFrameCallback((_) {
      parayanProvider.updateSettings(
        language: settings.language,
        script: settings.script,
        shlokaScript: settings.shlokaScript,
      );
    });
  }

  // --- UPDATED: Listener to handle audio state changes ---
  void _handleAudioChange() {
    final audioProvider = _audioProvider;
    if (audioProvider == null || !mounted) return;

    final newId = audioProvider.currentPlayingShlokaId;
    if (_currentlyPlayingId == newId) return;

    setState(() {
      _currentlyPlayingId = newId;
    });

    // Auto-scroll + move selection/island with the playing shloka
    if (newId != null) {
      final parayanProvider = Provider.of<ParayanProvider>(
        context,
        listen: false,
      );
      final index = parayanProvider.shlokas.indexWhere(
        (s) =>
            '${s.chapterNo}.${s.shlokNo}' == newId || s.id == newId,
      );

      if (index != -1) {
        setState(() {
          _selectedIndex = index;
          _actionsVisible = true;
        });
        _scrollCardCenterToFocusLine(index);
      }
    }
  }

  @override
  void dispose() {
    _currentPositionLabelNotifier.dispose(); // ✨ Add this line
    _audioProvider?.removeListener(_handleAudioChange);
    super.dispose();
  }

  Future<void> _onCardTap(int index) async {
    if (_isSelectingCard) return;

    // Tap same selected card → dismiss selection + controls
    if (_selectedIndex == index && (_actionsVisible || _selectedIndex != null)) {
      setState(() {
        _selectedIndex = null;
        _actionsVisible = false;
      });
      return;
    }

    _isSelectingCard = true;
    setState(() {
      _selectedIndex = null;
      _actionsVisible = false;
    });

    try {
      await _scrollCardCenterToFocusLine(index);
      if (!mounted) return;

      // Land at focus line → show cursor + highlight
      setState(() => _selectedIndex = index);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted) return;

      // Then pop in bottom controls
      setState(() => _actionsVisible = true);
    } finally {
      _isSelectingCard = false;
    }
  }

  /// Scroll so the focus cursor sits at the vertical center of [index].
  Future<void> _scrollCardCenterToFocusLine(int index) async {
    if (!_itemScrollController.isAttached) return;

    await _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeInOutCubic,
      alignment: _alignmentForCardCenter(index) ??
          (_kParayanFocusLine - 0.09).clamp(0.0, 1.0),
    );

    // One frame to let positions update, then fine-tune if needed.
    await Future<void>.delayed(const Duration(milliseconds: 32));
    if (!mounted || !_itemScrollController.isAttached) return;

    final refined = _alignmentForCardCenter(index, requireVisible: true);
    if (refined == null) return;

    final positions = _itemPositionsListener.itemPositions.value;
    ItemPosition? item;
    for (final p in positions) {
      if (p.index == index) {
        item = p;
        break;
      }
    }
    if (item == null) return;

    final center = (item.itemLeadingEdge + item.itemTrailingEdge) / 2;
    if ((center - _kParayanFocusLine).abs() <= 0.015) return;

    await _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: refined,
    );
  }

  /// Viewport alignment for item leading edge so its center hits [_kParayanFocusLine].
  double? _alignmentForCardCenter(int index, {bool requireVisible = false}) {
    final positions = _itemPositionsListener.itemPositions.value;
    for (final p in positions) {
      if (p.index == index) {
        final halfHeight =
            (p.itemTrailingEdge - p.itemLeadingEdge).abs() / 2;
        return (_kParayanFocusLine - halfHeight).clamp(0.0, 1.0);
      }
    }
    if (requireVisible) return null;
    // Off-screen estimate: typical compact shloka card ≈ 16–20% of screen.
    return (_kParayanFocusLine - 0.09).clamp(0.0, 1.0);
  }

  // ✨ NEW: Method to scroll to a specific item using its GlobalKey.
  void _scrollToIndex(int index) {
    // ✨ FIX: Use the itemScrollController which is designed for this.
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.12, // Keep chapter start near top so seek-rail chapter matches
    );
  }

  void _jumpToIndex(int index) {
    _itemScrollController.jumpTo(index: index, alignment: 0.15);
  }

  // REMOVED: _cyclePlaybackMode
  // The playback mode toggle has been moved to the Global Mini Player.

  // REMOVED: _buildPlaybackModeButton
  // The playback mode toggle has been moved to the Global Mini Player.

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
          : Theme.of(
              context,
            ).scaffoldBackgroundColor, // Solid light background for readability
      body: Stack(
        children: [
          if (settingsProvider.showBackground)
            SimpleGradientBackground(
              startColor:
                  Theme.of(
                    context,
                  ).extension<AppColors>()?.parayanGradientStart ??
                  const Color.fromARGB(255, 103, 108, 255),
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
                    showActions: false,
                  );
                  break;
                case ParayanDisplayMode.shlokAndAnvay:
                  cardConfig = FullShlokaCardConfig(
                    baseFontSize: settingsProvider.fontSize,
                    showAnvay: true,
                    showBhavarth: false,
                    showSeparator: true,
                    showActions: false,
                  );
                  break;
                case ParayanDisplayMode.all:
                  cardConfig = FullShlokaCardConfig(
                    baseFontSize: settingsProvider.fontSize,
                    showAnvay: true,
                    showBhavarth: true,
                    showSeparator: true,
                    showActions: false,
                  );
                  break;
              }

              final shlokas = provider.shlokas;
              final audio = Provider.of<AudioProvider>(context);
              final miniPlayerVisible =
                  audio.playbackState != PlaybackState.stopped &&
                  audio.currentPlayingShlokaId != null;

              // ✨ FIX: Revert to ScrollablePositionedList
              return ResponsiveWrapper(
                maxWidth: 1200, // ✨ NEW: Increased width for iPad
                child: ScrollablePositionedList.builder(
                  key: const PageStorageKey(
                    'parayan_list',
                  ), // ✨ FIX: Persist scroll state
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: shlokas.length,
                  // ✨ FIX: Apply the initial padding here. This is the correct way to offset the list
                  // without interfering with the item position listener.
                  padding: EdgeInsets.only(
                    top: _parayanExpandedHeaderHeight(context),
                    left: MediaQuery.of(
                      context,
                    ).padding.left, // Respect injected padding
                    right:
                        MediaQuery.of(context).padding.right +
                        _kParayanRailInset,
                    bottom: miniPlayerVisible ? 100.0 : 16.0,
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

                    final script = settingsProvider.script;
                    return Column(
                      children: [
                        if (isChapterStart)
                          _ChapterStartHeader(
                            chapterNumber: int.tryParse(shloka.chapterNo) ?? 0,
                            script: script,
                          ),
                        if (speakerChanged || isChapterStart)
                          _SpeakerHeader(
                            speaker: shloka.speaker ?? "Uvacha",
                            script: script,
                          ),
                        FullShlokaCard(
                          shloka: shloka,
                          currentlyPlayingId: _currentlyPlayingId,
                          isFocused: _selectedIndex == index,
                          onTap: () => _onCardTap(index),
                          onPlayPause: () {
                            _audioProvider?.playChapter(
                              shlokas: shlokas,
                              initialIndex: index,
                            );
                          },
                          config: cardConfig.copyWith(
                            showSpeaker: false,
                            showColoredCard: false,
                            showEmblem: false,
                            showShlokIndex: true,
                            spacingCompact: true,
                            showActions: false,
                            isLightTheme:
                                Theme.of(context).brightness ==
                                Brightness.light,
                          ),
                        ),
                        if (isChapterEnd)
                          _ChapterEndFooter(
                            chapterNumber: int.tryParse(shloka.chapterNo) ?? 0,
                            chapterName: StaticData.getChapterName(
                              int.tryParse(shloka.chapterNo) ?? 1,
                              script,
                            ),
                            script: script,
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
                      ? _parayanExpandedHeaderHeight(context)
                      : _parayanCollapsedHeaderHeight(context);
                  return Positioned(
                    right: MediaQuery.of(context).padding.right,
                    top: topPadding,
                    bottom: 8,
                    child: ChapterSeekRail(
                      itemPositionsListener: _itemPositionsListener,
                      itemCount: provider.shlokas.length,
                      chapterMarkers: provider.chapterStartIndices,
                      onChapterTap: (chapterIndex) {
                        final shlokaIndex =
                            provider.chapterStartIndices[chapterIndex];
                        _scrollToIndex(shlokaIndex);
                      },
                      onSeekToIndex: _jumpToIndex,
                    ),
                  );
                },
              );
            },
          ),
          // --- Animating Header Layer ---
          Positioned(
            left: MediaQuery.of(context).padding.left,
            top: 0,
            right: 0,
            child: AnimatingParayanHeader(
              itemPositionsListener: _itemPositionsListener,
              settingsProvider: settingsProvider,
            ),
          ),
          // Cursor only after a card is selected and scrolled into place
          if (_selectedIndex != null)
            const _ParayanFocusPointer(focusLine: _kParayanFocusLine),
          // Action island — pops in just above the selected card
          Consumer2<ParayanProvider, AudioProvider>(
            builder: (context, provider, audioProvider, _) {
              if (provider.isLoading ||
                  provider.shlokas.isEmpty ||
                  _selectedIndex == null) {
                return const SizedBox.shrink();
              }
              final targetIndex = _selectedIndex!.clamp(
                0,
                provider.shlokas.length - 1,
              );
              final targetShloka = provider.shlokas[targetIndex];
              final accent =
                  Theme.of(context).extension<AppColors>()?.gitaBlue ??
                  const Color(0xFF047BC0);

              return ValueListenableBuilder<Iterable<ItemPosition>>(
                valueListenable: _itemPositionsListener.itemPositions,
                builder: (context, positions, _) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  const islandHeight = 56.0;
                  const gapAboveCard = 6.0;

                  double? top;
                  for (final p in positions) {
                    if (p.index == targetIndex) {
                      // Travel with the card — sit just above its top edge,
                      // even if that means going off-screen.
                      top =
                          screenHeight * p.itemLeadingEdge -
                          islandHeight -
                          gapAboveCard;
                      break;
                    }
                  }
                  // Card not in viewport yet — keep island hidden off-screen
                  top ??= -islandHeight * 2;

                  return Positioned(
                    left: 0,
                    right: _kParayanRailInset,
                    top: top,
                    child: IgnorePointer(
                      ignoring: !_actionsVisible,
                      child: AnimatedScale(
                        scale: _actionsVisible ? 1 : 0.86,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _actionsVisible ? 1 : 0,
                          child: ParayanActionIsland(
                            accentBorder: true,
                            accentColor: accent,
                            shloka: targetShloka,
                            currentlyPlayingId: _currentlyPlayingId,
                            onPlayPause: () {
                              _audioProvider?.playChapter(
                                shlokas: provider.shlokas,
                                initialIndex: targetIndex,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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
    String tooltip;

    switch (_displayMode) {
      case ParayanDisplayMode.shlokOnly:
        icon = Icons.article_outlined;
        tooltip = 'Shlok Only';
        break;
      case ParayanDisplayMode.shlokAndAnvay:
        icon = Icons.segment;
        tooltip = 'Shlok & Anvay';
        break;
      case ParayanDisplayMode.all:
        icon = Icons.view_headline;
        tooltip = 'Show All';
        break;
    }

    // Returning an IconButton for compact layout in the island
    return IconButton(
      onPressed: _cycleDisplayMode,
      icon: Icon(icon, color: Theme.of(context).iconTheme.color),
      tooltip: tooltip,
      iconSize: 24,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}

/// Persistent focus triangle on the left at the reading line.
class _ParayanFocusPointer extends StatelessWidget {
  final double focusLine;

  const _ParayanFocusPointer({required this.focusLine});

  @override
  Widget build(BuildContext context) {
    final accent =
        Theme.of(context).extension<AppColors>()?.gitaBlue ??
        const Color(0xFF047BC0);
    final screenHeight = MediaQuery.of(context).size.height;
    final top = screenHeight * focusLine;

    return Positioned(
      left: MediaQuery.of(context).padding.left + 4,
      top: top - 11,
      child: IgnorePointer(
        child: CustomPaint(
          size: const Size(12, 22),
          painter: _FocusTrianglePainter(
            color: accent,
            shadowColor: accent.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _FocusTrianglePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;

  _FocusTrianglePainter({required this.color, required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, shadowColor, 4, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _FocusTrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.shadowColor != shadowColor;
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
    // ✨ FIX: Initialize label correctly based on current script
    // We can set the initial label directly without setState since we are in initState.
    // However, we rely on Provider to get data. If provider is empty, it returns default.
    // We wrapped _getLabel with try-catch and empty check.
    _currentLabel = _getLabel(
      0,
    ); // Initialize with Chapter 1, Shloka 1 (index 0)
    widget.itemPositionsListener.itemPositions.addListener(_scrollListener);
  }

  // ✨ REFACTORED: Helper to get localized label
  String _getLabel(int index) {
    if (!mounted) return _currentLabel;
    try {
      final parayanProvider = Provider.of<ParayanProvider>(
        context,
        listen: false,
      );
      if (parayanProvider.shlokas.isNotEmpty &&
          index < parayanProvider.shlokas.length) {
        final shloka = parayanProvider.shlokas[index];
        final script = widget.settingsProvider.script;
        final chapLabel = StaticData.getChapterLabel(script);
        final chapNum = StaticData.localizeNumber(
          int.tryParse(shloka.chapterNo) ?? 1,
          script,
        );
        final shlokNum = StaticData.localizeNumber(
          int.tryParse(shloka.shlokNo) ?? 1,
          script,
        );
        // "Shloka" label localization - simple fallback
        String shlokaLabel = 'Shloka';
        if (script == 'gu')
          shlokaLabel = 'શ્લોક';
        else if (script == 'te')
          shlokaLabel = 'శ్లోక';
        else if (script == 'bn')
          shlokaLabel = 'শ্লোক';
        else if (script == 'hi' || script == 'dev' || script == 'mr')
          shlokaLabel = 'श्लोक';

        return '$chapLabel $chapNum, $shlokaLabel $shlokNum';
      }
    } catch (_) {}
    return _currentLabel;
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

      // The Y position of the first item's top edge
      final itemY = absoluteTopItem.itemLeadingEdge * viewportHeight;

      // Define the scroll range for the animation
      // Start: Item is at its initial padded position (Expanded Header)
      final startY = _parayanExpandedHeaderHeight(context);

      // End: Item is at the bottom of the collapsed header (Collapsed Header)
      final endY = _parayanCollapsedHeaderHeight(context);

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
      _parayanExpandedHeaderHeight(context),
      _parayanCollapsedHeaderHeight(context),
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
      final newLabel = _getLabel(topVisibleItem.index);
      // Only call setState if label or index actually changed
      if (_currentLabel != newLabel || _lastTopIndex != topVisibleItem.index) {
        setState(() {
          _currentLabel = newLabel;
          _lastTopIndex = topVisibleItem.index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeaderHeight = _parayanExpandedHeaderHeight(context);
    final double minHeaderHeight = _parayanCollapsedHeaderHeight(context);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final t = _animationController.value;
        final headerHeight = lerpDouble(maxHeaderHeight, minHeaderHeight, t)!;

        return SizedBox(
          height: headerHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Glass island with docked lotus (always inside the bar) ---
              Positioned(
                bottom: 12,
                left: 0,
                right: _kParayanRailInset,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 700,
                      minWidth: 300,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.white12,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 8.0,
                          ),
                          child: Row(
                            children: [
                              // Back + docked lotus
                              GestureDetector(
                                onTap: MediaQuery.of(context).size.width > 600
                                    ? null
                                    : () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go('/');
                                        }
                                      },
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (MediaQuery.of(context).size.width <=
                                        600) ...[
                                      const Icon(
                                        Icons.arrow_back_ios_new,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Hero(
                                      tag: 'blueLotusHero',
                                      flightShuttleBuilder:
                                          (
                                            flightContext,
                                            animation,
                                            flightDirection,
                                            fromHeroContext,
                                            toHeroContext,
                                          ) {
                                            final rotationAnimation = animation
                                                .drive(
                                                  Tween<double>(
                                                    begin: 0.0,
                                                    end: 1.0,
                                                  ),
                                                );
                                            return RotationTransition(
                                              turns: rotationAnimation,
                                              child:
                                                  (toHeroContext.widget as Hero)
                                                      .child,
                                            );
                                          },
                                      child: Image.asset(
                                        'assets/images/lotus_blue12.png',
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Title + controls
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      _currentLabel,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            height: 1.2,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      height: 40,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            FontSizeControl(
                                              currentSize: widget
                                                  .settingsProvider
                                                  .fontSize,
                                              onSizeChanged: (newSize) => widget
                                                  .settingsProvider
                                                  .setFontSize(newSize),
                                              color:
                                                  Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color ??
                                                  Colors.black87,
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              width: 1,
                                              height: 20,
                                              color: Theme.of(
                                                context,
                                              ).dividerColor,
                                            ),
                                            const SizedBox(width: 8),
                                            (context
                                                    .findAncestorStateOfType<
                                                      _ParayanScreenState
                                                    >()!)
                                                ._buildDisplayModeButton(),
                                          ],
                                        ),
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
            ],
          ),
        );
      },
    );
  }
}

// --- Reusable private widgets for the list items ---

class _ChapterStartHeader extends StatelessWidget {
  final int chapterNumber;
  final String script;

  const _ChapterStartHeader({
    required this.chapterNumber,
    required this.script,
  });

  @override
  Widget build(BuildContext context) {
    // This could be styled more elaborately later
    // FIX: The `getChapterTitle` method had a range error for chapter 18.
    // Using `geetaAdhyay` list directly with correct 0-based indexing is safer
    // and consistent with other parts of the app (e.g., _ChapterEndFooter).
    // We clamp the chapter number to be at least 1 to prevent negative indices.
    final safeChapterNum = chapterNumber < 1 ? 1 : chapterNumber;
    final chapterLabel = StaticData.getChapterLabel(script);
    final localNum = StaticData.localizeNumber(safeChapterNum, script);
    final chapterName = StaticData.getChapterName(safeChapterNum, script);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Text(
        '$chapterLabel $localNum $chapterName',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 4, 123, 192),
        ),
      ),
    );
  }
}

class _SpeakerHeader extends StatelessWidget {
  final String speaker;
  final String script;
  const _SpeakerHeader({required this.speaker, required this.script});

  // ✨ Helper function to get the emblem asset path based on the speaker's name
  String? _getSpeakerEmblemPath(String speakerName) {
    final lower = speakerName.toLowerCase();
    if (lower.contains('bhagvan') ||
        lower.contains('bhagavan') ||
        lower.contains('krishna'))
      return 'assets/emblems/krishna.png';
    if (lower.contains('arjun')) return 'assets/emblems/arjun.png';
    if (lower.contains('sanjay')) return 'assets/emblems/sanjay.png';
    if (lower.contains('dhritarashtra'))
      return 'assets/emblems/dhrutrashtra.png';
    // Fallback for "Sri Bhagavan" logic in Hindi
    if (speakerName.contains('श्री भगवान') || speakerName.contains('श्रीभगवान'))
      return 'assets/emblems/krishna.png';
    if (speakerName.contains('अर्जुन')) return 'assets/emblems/arjun.png';
    if (speakerName.contains('संजय')) return 'assets/emblems/sanjay.png';
    if (speakerName.contains('धृतराष्ट्र'))
      return 'assets/emblems/dhrutrashtra.png';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Get the path for the emblem, which might be null
    final String? emblemPath = _getSpeakerEmblemPath(speaker);
    // Localized Speaker Name
    final localizedSpeaker = StaticData.localizeSpeaker(speaker, script);
    // Determine Uvacha label

    // If "Uvaca" is already in the string (from StaticData), don't append.
    // StaticData.localizeSpeaker returns map value e.g. "Arjuna Uvaca".
    // So we just use that.

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emblemPath != null) ...[
            Image.asset(
              emblemPath,
              height: 50,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              localizedSpeaker,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.bold,
              ),
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
  final String script;
  const _ChapterEndFooter({
    required this.chapterNumber,
    required this.chapterName,
    required this.script,
  });

  @override
  Widget build(BuildContext context) {
    final localNum = StaticData.localizeNumber(chapterNumber, script);

    // Construct Colophon dynamically
    // Keep Sanskrit structure but use localized numeric/names?
    // User wants "Everything" in respective lipi.
    // Ideally whole colophon should be transliterated.
    // For now, I will keep standard Sanskrit but insert Localized Name/Number.
    // Or simpler: Just "Chapter End: Name" if full Sanskrit is too hard to transliterate dynamically.
    // I will stick to the existing format but simpler for non-Devanagari

    String colophonText;
    if (script == 'dev' || script == 'hi' || script == 'mr') {
      colophonText =
          "ॐ तत्सदिति श्रीमद्भगवद्गीतासूपनिषत्सु\nब्रह्मविद्यायां योगशास्त्रे श्रीकृष्णार्जुनसंवादे\n$chapterName नाम अध्यायः $localNum ॥";
    } else {
      // Simplified for others until full transliteration available
      // Or just use English-ish format
      colophonText =
          "${StaticData.getChapterLabel(script)} $localNum: $chapterName\n(End of Chapter)";
    }

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
