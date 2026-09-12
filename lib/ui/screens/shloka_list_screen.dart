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

import 'dart:math' as math;

import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../navigation/app_router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/shloka_list_provider.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/font_size_control.dart';
import '../widgets/reading_mode_font_dock.dart';
import '../../data/static_data.dart';
import '../../models/shloka_result.dart';
import '../../data/database_helper_interface.dart';

import '../widgets/responsive_wrapper.dart';
import '../theme/app_colors.dart';
import '../widgets/onboarding_bubble.dart';
import '../widgets/reminder_pitch.dart';
import 'book_reading_screen.dart';
import '../../utils/scroll_focus_runway.dart';

class ShlokaListScreen extends StatefulWidget {
  final String searchQuery;
  final bool showBackButton; // ✨ NEW parameter
  final bool delayEmblem; // ✨ NEW parameter for animation
  final bool isEmbedded; // ✨ NEW parameter for unified background
  final int? initialShlokaNo; // ✨ NEW parameter for scrolling
  /// Open directly in commentary book mode (chapter view only).
  final bool initialBookMode;
  /// When true (Settings → Help), replay floating onboarding tips.
  final bool showHelp;

  const ShlokaListScreen({
    super.key,
    required this.searchQuery,
    this.showBackButton = true, // Default to true
    this.delayEmblem = false,
    this.isEmbedded = false,
    this.initialShlokaNo,
    this.initialBookMode = false,
    this.showHelp = false,
  });

  @override
  State<ShlokaListScreen> createState() => _ShlokaListScreenState();
}

class _ShlokaListScreenState extends State<ShlokaListScreen> {
  final ScrollController _scrollController = ScrollController();
  final ItemScrollController _chapterItemScrollController =
      ItemScrollController();
  final ItemPositionsListener _chapterItemPositionsListener =
      ItemPositionsListener.create();
  List<GlobalKey> _itemKeys = [];

  /// Header row in [ScrollablePositionedList] before verse 0.
  static const int _kChapterHeaderListItems = 1;
  /// Trailing spacer so the last verse can reach the focus line.
  static const int _kChapterTrailingRunwayItems = 1;
  static const double _kChapterFocusLine = kDefaultFocusLine;

  // REMOVED: Local PlaybackMode state. Now using AudioProvider directly.

  String? _currentShlokId;
  bool _hasInitialScrolled = false; // Flag to prevent multiple scrolls
  bool _initialSeekInFlight = false;

  // --- FIX: Initialize the provider in initState to make it available to listeners ---
  late final ShlokaListProvider _shlokaProvider;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  /// Commentary book vs verse-card list (chapter view only).
  late bool _isBookMode;
  /// Chapter list: which verse has Anvay/Bhavarth expanded (null = all collapsed).
  int? _expandedVerseIndex;

  /// Default verse-card content (same controls as Parayan).
  ContinuousListBody _listBodyMode = ContinuousListBody.shloka;
  ParayanLayoutCount _layoutCount = ParayanLayoutCount.one;
  ContinuousListPair _listPairMode = ContinuousListPair.shlokaAnvay;

  final GlobalKey _bookModeKey = GlobalKey(debugLabel: 'chapterBookMode');
  final GlobalKey _fontDockKey = GlobalKey(debugLabel: 'chapterFontDock');
  final GlobalKey _verseHintKey = GlobalKey(debugLabel: 'chapterVerseHint');

  @override
  void initState() {
    super.initState();
    _isBookMode = widget.initialBookMode;
    final dbHelper = Provider.of<DatabaseHelperInterface>(
      context,
      listen: false,
    );
    final language = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ).language;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final script = settings.script;
    _shlokaProvider = ShlokaListProvider(
      widget.searchQuery,
      dbHelper,
      language,
      script,
      shlokaScript: settings.shlokaScript,
    );

    // ✨ FIX: Get the provider once and store it.
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _audioProvider?.addListener(_handleAudioChange);
    if (widget.showHelp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _replayChapterOnboardingHints();
      });
    }
    final isChapter =
        int.tryParse(widget.searchQuery.split(',').first.trim()) != null;
    if (isChapter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          ReminderPitch.maybeShow(context, blocked: _chapterHintsVisible());
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant ShlokaListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHelp && !oldWidget.showHelp) {
      _replayChapterOnboardingHints();
    }
    if (widget.searchQuery != oldWidget.searchQuery) {
      _expandedVerseIndex = null;
    }
  }

  @override
  void dispose() {
    // ✨ FIX: Use the stored provider instance for safe cleanup.
    _audioProvider?.removeListener(_handleAudioChange);
    _shlokaProvider.dispose(); // Dispose the provider we created.
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _replayChapterOnboardingHints() async {
    if (!mounted) return;
    await Provider.of<SettingsProvider>(context, listen: false)
        .resetChapterOnboardingHints();
  }

  bool _chapterHintsVisible() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return !settings.hasUsedChapterBookHint ||
        !settings.hasUsedChapterFontHint ||
        !settings.hasUsedChapterTapHint;
  }

  /// Show back when we can pop, or when this route replaced the stack
  /// (Settings → Help) so the user is never trapped.
  bool _shouldShowBackButton(BuildContext context) {
    if (!widget.showBackButton) return false;
    if (!GoRouter.of(context).canPop()) return true;
    // Match existing phone-iOS chrome; tablets use the rail instead.
    return Theme.of(context).platform == TargetPlatform.iOS &&
        MediaQuery.sizeOf(context).width <= 600;
  }

  void _handleBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.settings);
    }
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
          if (_isChapterQuery() && !_isBookMode) {
            _scrollToChapterVerseIndex(index);
          } else {
            _scrollToIndex(index);
          }
        }
      }
    }
  }

  bool _isChapterQuery() =>
      int.tryParse(widget.searchQuery.split(',').first.trim()) != null;

  int _chapterListIndexForVerse(int verseIndex) =>
      verseIndex + _kChapterHeaderListItems;

  int _indexForShlokaNo(List<ShlokaResult> shlokas, int shlokaNo) {
    return shlokas.indexWhere(
      (s) => int.tryParse(s.shlokNo) == shlokaNo,
    );
  }

  Future<void> _seekInitialShloka(List<ShlokaResult> shlokas) async {
    final targetNo = widget.initialShlokaNo;
    if (targetNo == null ||
        _hasInitialScrolled ||
        _initialSeekInFlight ||
        shlokas.isEmpty) {
      return;
    }
    _initialSeekInFlight = true;

    if (_isBookMode) {
      _hasInitialScrolled = true;
      _initialSeekInFlight = false;
      return;
    }

    final targetIndex = _indexForShlokaNo(shlokas, targetNo);
    if (targetIndex == -1) {
      _initialSeekInFlight = false;
      return;
    }

    final usePositionedList = _isChapterQuery();
    for (var attempt = 0; attempt < 10; attempt++) {
      final ok = usePositionedList
          ? await _scrollToChapterVerseIndex(targetIndex)
          : await _scrollToIndex(targetIndex, awaitVisible: true);
      if (ok) {
        _hasInitialScrolled = true;
        _initialSeekInFlight = false;
        return;
      }
      await Future<void>.delayed(Duration(milliseconds: 80 * (attempt + 1)));
    }
    _initialSeekInFlight = false;
  }

  /// Scrolls the verse list so [index] is framed; returns whether scroll ran.
  Future<bool> _scrollToIndex(int index, {bool awaitVisible = false}) async {
    if (index < 0 || index >= _itemKeys.length) {
      return false;
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return false;
    if (!_scrollController.hasClients) {
      return false;
    }

    final key = _itemKeys[index];

    if (key.currentContext == null) {
      final maxExtent = _scrollController.position.maxScrollExtent;
      double targetOffset = (index * 400.0).clamp(0.0, maxExtent);
      _scrollController.jumpTo(targetOffset);
      await Future.delayed(const Duration(milliseconds: 100));

      int maxAttempts = 20;
      int attempt = 0;
      while (key.currentContext == null &&
          attempt < maxAttempts &&
          mounted &&
          _scrollController.hasClients) {
        _scrollController.jumpTo(
          (_scrollController.offset + 800).clamp(0.0, maxExtent),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        attempt++;
      }
    }

    if (!mounted) return false;

    Future<bool> ensureVisibleNow() async {
      if (key.currentContext == null) {
        return false;
      }

      final RenderBox renderBox =
          key.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;
      final topPadding =
          MediaQuery.of(context).padding.top + kToolbarHeight + 80;

      final fullyFramed =
          position.dy >= topPadding &&
          position.dy + math.min(renderBox.size.height, 320) <=
              screenSize.height - 24;

      if (!fullyFramed || awaitVisible) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration(milliseconds: awaitVisible ? 500 : 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.40,
        );
        return true;
      }
      return true;
    }

    if (awaitVisible) {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return false;
      final ok = await ensureVisibleNow();
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return ok;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ensureVisibleNow();
    });
    return true;
  }

  double? _alignmentForChapterVerse(
    int verseIndex, {
    bool requireVisible = false,
  }) {
    final listIndex = _chapterListIndexForVerse(verseIndex);
    final positions = _chapterItemPositionsListener.itemPositions.value;
    for (final p in positions) {
      if (p.index == listIndex) {
        final halfHeight =
            (p.itemTrailingEdge - p.itemLeadingEdge).abs() / 2;
        return (_kChapterFocusLine - halfHeight).clamp(0.0, 1.0);
      }
    }
    if (requireVisible) return null;
    return (_kChapterFocusLine - 0.09).clamp(0.0, 1.0);
  }

  int _chapterVerseNearestFocusLine(int verseCount) {
    final positions = _chapterItemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return 0;
    final verseStart = _kChapterHeaderListItems;
    ItemPosition? focusItem;
    for (final p in positions) {
      if (p.index < verseStart || p.index >= verseStart + verseCount) {
        continue;
      }
      if (focusItem == null) {
        focusItem = p;
        continue;
      }
      final aCenter =
          (focusItem.itemLeadingEdge + focusItem.itemTrailingEdge) / 2;
      final bCenter = (p.itemLeadingEdge + p.itemTrailingEdge) / 2;
      if ((bCenter - _kChapterFocusLine).abs() <
          (aCenter - _kChapterFocusLine).abs()) {
        focusItem = p;
      }
    }
    if (focusItem == null) return 0;
    return (focusItem.index - verseStart).clamp(0, verseCount - 1);
  }

  Future<void> _repinChapterVerseAfterLayoutChange(int verseIndex) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (!_chapterItemScrollController.isAttached) return;
    final listIndex = _chapterListIndexForVerse(verseIndex);
    final alignment = _alignmentForChapterVerse(verseIndex, requireVisible: true) ??
        (_kChapterFocusLine - 0.09).clamp(0.0, 1.0);
    _chapterItemScrollController.jumpTo(
      index: listIndex,
      alignment: alignment,
    );
  }

  Future<void> _onChapterFontSizeChanged(double newSize) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.setFontSize(newSize);
    if (!mounted) return;
    final count = _shlokaProvider.shlokas.length;
    if (count == 0) return;
    final keepIndex = _chapterVerseNearestFocusLine(count);
    await _repinChapterVerseAfterLayoutChange(keepIndex);
  }

  Future<void> _onChapterToggleLayoutCount() async {
    final count = _shlokaProvider.shlokas.length;
    final keepIndex =
        count == 0 ? 0 : _chapterVerseNearestFocusLine(count);
    setState(() {
      _layoutCount = switch (_layoutCount) {
        ParayanLayoutCount.one => ParayanLayoutCount.two,
        ParayanLayoutCount.two => ParayanLayoutCount.three,
        ParayanLayoutCount.three => ParayanLayoutCount.one,
      };
    });
    await _repinChapterVerseAfterLayoutChange(keepIndex);
  }

  Future<void> _onChapterToggleListContent() async {
    if (_layoutCount == ParayanLayoutCount.three) return;
    final count = _shlokaProvider.shlokas.length;
    final keepIndex =
        count == 0 ? 0 : _chapterVerseNearestFocusLine(count);
    setState(() {
      if (_layoutCount == ParayanLayoutCount.one) {
        _listBodyMode = switch (_listBodyMode) {
          ContinuousListBody.shloka => ContinuousListBody.anvay,
          ContinuousListBody.anvay => ContinuousListBody.translation,
          ContinuousListBody.translation => ContinuousListBody.shloka,
        };
      } else {
        _listPairMode = switch (_listPairMode) {
          ContinuousListPair.shlokaAnvay => ContinuousListPair.shlokaTranslation,
          ContinuousListPair.shlokaTranslation =>
            ContinuousListPair.anvayTranslation,
          ContinuousListPair.anvayTranslation =>
            ContinuousListPair.shlokaAnvay,
        };
      }
    });
    await _repinChapterVerseAfterLayoutChange(keepIndex);
  }

  Future<bool> _scrollToChapterVerseIndex(int verseIndex) async {
    final listIndex = _chapterListIndexForVerse(verseIndex);
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted) return false;
      if (!_chapterItemScrollController.isAttached) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        continue;
      }

      final alignment = _alignmentForChapterVerse(verseIndex) ??
          (_kChapterFocusLine - 0.09).clamp(0.0, 1.0);
      await _chapterItemScrollController.scrollTo(
        index: listIndex,
        duration: Duration(milliseconds: attempt == 0 ? 500 : 220),
        curve: Curves.easeInOutCubic,
        alignment: alignment,
      );

      await Future<void>.delayed(const Duration(milliseconds: 48));
      if (!mounted || !_chapterItemScrollController.isAttached) return false;

      final refined =
          _alignmentForChapterVerse(verseIndex, requireVisible: true);
      if (refined == null) {
        continue;
      }

      final positions = _chapterItemPositionsListener.itemPositions.value;
      ItemPosition? item;
      for (final p in positions) {
        if (p.index == listIndex) {
          item = p;
          break;
        }
      }
      if (item == null) continue;

      final center = (item.itemLeadingEdge + item.itemTrailingEdge) / 2;
      final delta = (center - _kChapterFocusLine).abs();
      if (delta <= 0.03) {
        return true;
      }
      // End of list: runway limits how high the center can go — stop retrying.
      if (center <= _kChapterFocusLine + 0.06 && item.itemTrailingEdge <= 1.02) {
        return true;
      }

      await _chapterItemScrollController.scrollTo(
        index: listIndex,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        alignment: refined,
      );
      await Future<void>.delayed(const Duration(milliseconds: 32));
    }
    return false;
  }

  Widget _buildVerseCard({
    required BuildContext context,
    required List<ShlokaResult> shlokas,
    required int index,
    required SettingsProvider settingsProvider,
    required int? chapterNumber,
  }) {
    final isChapter = chapterNumber != null;
    final meaningsOpen = !isChapter || _expandedVerseIndex == index;
    final showTapHint = isChapter &&
        !meaningsOpen &&
        _layoutCount == ParayanLayoutCount.one &&
        _listBodyMode == ContinuousListBody.shloka;
    final card = ResponsiveWrapper(
      child: FullShlokaCard(
        shloka: shlokas[index],
        isFocused: false,
        config: _cardConfig.copyWith(
          baseFontSize: settingsProvider.fontSize,
          isLightTheme: Theme.of(context).brightness == Brightness.light,
          showEmblem: !isChapter,
          showSeparator: isChapter ? meaningsOpen : true,
          // Chapter: dock when collapsed; tap reveals all three + actions.
          showAnvay: !isChapter || meaningsOpen,
          showBhavarth: !isChapter || meaningsOpen,
          showActions: !isChapter || meaningsOpen,
          spacingCompact: isChapter,
          showMeaningsHint: showTapHint,
          continuousReading: isChapter,
          preserveCardChrome: isChapter,
          showColoredCard: _cardConfig.showColoredCard,
          showSpeaker: _cardConfig.showSpeaker,
          listBodyMode: _listBodyMode,
          layoutCount: _layoutCount,
          listPairMode: _listPairMode,
        ),
        currentlyPlayingId: _currentShlokId,
        onTap: isChapter
            ? () {
                setState(() {
                  _expandedVerseIndex =
                      _expandedVerseIndex == index ? null : index;
                });
              }
            : null,
        onPlayPause: () {
          Provider.of<AudioProvider>(context, listen: false).playChapter(
            shlokas: shlokas,
            initialIndex: index,
          );
        },
      ),
    );
    if (index == 0 &&
        isChapter &&
        !settingsProvider.hasUsedChapterTapHint) {
      return KeyedSubtree(key: _verseHintKey, child: card);
    }
    return card;
  }

  Widget _buildChapterPositionedList({
    required BuildContext context,
    required List<ShlokaResult> shlokas,
    required int chapterNumber,
    required SettingsProvider settingsProvider,
  }) {
    return ScrollablePositionedList.builder(
      itemScrollController: _chapterItemScrollController,
      itemPositionsListener: _chapterItemPositionsListener,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: shlokas.length +
          _kChapterHeaderListItems +
          _kChapterTrailingRunwayItems,
      itemBuilder: (context, listIndex) {
        if (listIndex < _kChapterHeaderListItems) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 64),
              Center(
                child: _ChapterEmblemHeader(chapterNumber: chapterNumber),
              ),
            ],
          );
        }
        final verseListStart = _kChapterHeaderListItems;
        if (listIndex >= verseListStart + shlokas.length) {
          return SizedBox(
            height: trailingRunwayHeightForFocusLine(
              context,
              focusLine: _kChapterFocusLine,
            ),
          );
        }
        final index = listIndex - verseListStart;
        return _buildVerseCard(
          context: context,
          shlokas: shlokas,
          index: index,
          settingsProvider: settingsProvider,
          chapterNumber: chapterNumber,
        );
      },
    );
  }

  // --- NEW: Helper methods for the playback mode cycle button ---

  // REMOVED: _cyclePlaybackMode and _buildPlaybackModeButton
  // Playback control moved to Global Mini Player.

  @override
  Widget build(BuildContext context) {
    // When a user presses play, we need to initialize our state machine.

    // This handles cases like a query of "1" or "1,21".
    final chapterNumber = int.tryParse(
      widget.searchQuery.split(',').first.trim(),
    );

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

          return Stack(
            children: [
              Scaffold(
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
                    leading: _shouldShowBackButton(context)
                        ? BackButton(
                            color: Colors.white,
                            onPressed: () => _handleBack(context),
                          )
                        : null,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(50.0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            FontSizeControl(
                              currentSize: settingsProvider.fontSize,
                              onSizeChanged: (newSize) =>
                                  settingsProvider.setFontSize(newSize),
                              color: Colors.white,
                            ),
                            // REMOVED: Playback Mode Button
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
                        final scrollIndex = provider.initialScrollIndex!;
                        if (chapterNumber != null) {
                          _scrollToChapterVerseIndex(scrollIndex);
                        } else {
                          _scrollToIndex(scrollIndex, awaitVisible: true);
                        }
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
                        // 1. Handle Navigation Scroll on First Load
                        if (widget.initialShlokaNo != null &&
                            !_hasInitialScrolled &&
                            shlokas.isNotEmpty) {
                          _seekInitialShloka(shlokas);
                        }

                        // 2. Handle Audio Playback Scroll
                        if (_currentShlokId != null &&
                            _currentShlokId != provider.lastScrolledId) {
                          final playingIndex = shlokas.indexWhere(
                            (s) =>
                                '${s.chapterNo}.${s.shlokNo}' ==
                                _currentShlokId,
                          );
                          if (playingIndex != -1) {
                            if (chapterNumber != null) {
                              _scrollToChapterVerseIndex(playingIndex);
                            } else {
                              _scrollToIndex(playingIndex);
                            }
                            provider.setLastScrolledId(
                              _currentShlokId,
                            ); // Prevent re-scrolling
                          }
                        }
                      });

                      if (chapterNumber != null && _isBookMode) {
                        return BookReadingScreen(
                          key: ValueKey('book_$chapterNumber'),
                          chapterNumber: chapterNumber,
                          initialShlokaNo: widget.initialShlokaNo,
                          embedded: true,
                        );
                      }

                      if (chapterNumber != null) {
                        return _buildChapterPositionedList(
                          context: context,
                          shlokas: shlokas,
                          chapterNumber: chapterNumber,
                          settingsProvider: settingsProvider,
                        );
                      }

                      return CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).padding.top +
                                  kToolbarHeight +
                                  20,
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return Container(
                                  key: _itemKeys[index],
                                  child: _buildVerseCard(
                                    context: context,
                                    shlokas: shlokas,
                                    index: index,
                                    settingsProvider: settingsProvider,
                                    chapterNumber: null,
                                  ),
                                );
                              },
                              childCount: shlokas.length,
                            ),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 88),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
              // Chapter chrome — Parayan-inspired left-peek title + mode toggle
              if (chapterNumber != null) ...[
                Positioned(
                  left: MediaQuery.of(context).padding.left,
                  top: MediaQuery.of(context).padding.top + 6,
                  right: 12,
                  child: _ChapterPeekTitleBar(
                    title: title,
                    showBack: _shouldShowBackButton(context),
                    onBack: () => _handleBack(context),
                    isBookMode: _isBookMode,
                    bookModeKey: _bookModeKey,
                    onToggleMode: () {
                      setState(() => _isBookMode = !_isBookMode);
                    },
                  ),
                ),
                if (!_isBookMode &&
                    !settingsProvider.hasUsedChapterBookHint)
                  AnchoredOnboardingBubble(
                    targetKey: _bookModeKey,
                    placement: OnboardingBubblePlacement.belowTarget,
                    repositionListenable:
                        _chapterItemPositionsListener.itemPositions,
                    text: 'Book mode — continuous commentary',
                    icon: Icons.menu_book_outlined,
                    onTap: () =>
                        settingsProvider.markChapterBookHintUsed(),
                    onDismiss: () =>
                        settingsProvider.markChapterBookHintUsed(),
                  ),
                if (!_isBookMode &&
                    !settingsProvider.hasUsedChapterTapHint)
                  AnchoredOnboardingBubble(
                    targetKey: _verseHintKey,
                    placement: OnboardingBubblePlacement.belowTarget,
                    repositionListenable:
                        _chapterItemPositionsListener.itemPositions,
                    text: 'Tap a verse for meaning & actions',
                    icon: Icons.touch_app_outlined,
                    onTap: () => settingsProvider.markChapterTapHintUsed(),
                    onDismiss: () =>
                        settingsProvider.markChapterTapHintUsed(),
                  ),
                if (!_isBookMode)
                  Consumer<AudioProvider>(
                    builder: (context, audio, _) {
                      final miniPlayerVisible =
                          audio.playbackState != PlaybackState.stopped &&
                          audio.currentPlayingShlokaId != null;
                      final bottomSafe =
                          MediaQuery.of(context).padding.bottom;
                      return Positioned(
                        left: MediaQuery.of(context).padding.left,
                        bottom: miniPlayerVisible
                            ? 96 + bottomSafe
                            : 12 + bottomSafe,
                        child: KeyedSubtree(
                          key: _fontDockKey,
                          child: ReadingModeFontDock(
                            currentSize: settingsProvider.fontSize,
                            onSizeChanged: _onChapterFontSizeChanged,
                            listBodyMode: _listBodyMode,
                            layoutCount: _layoutCount,
                            listPairMode: _listPairMode,
                            onToggleListContent: () {
                              _onChapterToggleListContent();
                            },
                            onToggleLayoutCount: () {
                              _onChapterToggleLayoutCount();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                if (!_isBookMode && !settingsProvider.hasUsedChapterFontHint)
                  AnchoredOnboardingBubble(
                    targetKey: _fontDockKey,
                    placement: OnboardingBubblePlacement.leftOfTarget,
                    repositionListenable:
                        _chapterItemPositionsListener.itemPositions,
                    text: 'Text size & what each verse shows',
                    icon: Icons.format_size,
                    onTap: () =>
                        settingsProvider.markChapterFontHintUsed(),
                    onDismiss: () =>
                        settingsProvider.markChapterFontHintUsed(),
                  ),
              ],
            ],
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

class _ChapterPeekTitleBar extends StatelessWidget {
  final String title;
  final bool showBack;
  final VoidCallback onBack;
  final bool isBookMode;
  final VoidCallback onToggleMode;
  final Key? bookModeKey;

  const _ChapterPeekTitleBar({
    required this.title,
    required this.showBack,
    required this.onBack,
    required this.isBookMode,
    required this.onToggleMode,
    this.bookModeKey,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = isLight ? const Color(0xFF0B1F4A) : Colors.white;
    // Opaque fill — BackdropFilter was picking up gold emblems and reading as
    // a yellow glow / false underlines behind the title.
    final glass = isLight ? const Color(0xFFF7F4EE) : const Color(0xFF2A2A2A);

    return Row(
      children: [
        Flexible(
          child: Material(
            color: glass,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(22),
              ),
              side: BorderSide(color: Color(0x14000000), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: EdgeInsets.only(
                  left: showBack ? 4 : 14,
                  right: 14,
                ),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          foregroundColor: fg,
                          overlayColor: Colors.black.withValues(alpha: 0.06),
                        ),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                          color: fg,
                        ),
                        onPressed: onBack,
                      ),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'NotoSerif',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fg,
                          height: 1.15,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ChapterModeToggleButton(
          key: bookModeKey,
          isBookMode: isBookMode,
          onTap: onToggleMode,
        ),
      ],
    );
  }
}

/// Prominent pill that flips between verse-list and commentary-book modes.
class _ChapterModeToggleButton extends StatelessWidget {
  final bool isBookMode;
  final VoidCallback onTap;

  const _ChapterModeToggleButton({
    super.key,
    required this.isBookMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isBookMode
        ? (isLight ? const Color(0xFF0B1F4A) : const Color(0xFFFFD54F))
        : (isLight ? const Color(0xFFE65100) : const Color(0xFFFF8A65));
    final fg = isBookMode
        ? (isLight ? Colors.white : const Color(0xFF1A1200))
        : Colors.white;
    const radius = BorderRadius.all(Radius.circular(24));

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bg,
            Color.lerp(bg, Colors.black, 0.18)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBookMode
                      ? Icons.view_agenda_rounded
                      : Icons.menu_book_rounded,
                  size: 18,
                  color: fg,
                ),
                const SizedBox(width: 8),
                Text(
                  isBookMode ? 'Verses' : 'Book',
                  style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: fg,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterEmblemHeader extends StatelessWidget {
  final int chapterNumber;
  const _ChapterEmblemHeader({required this.chapterNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72.0),
      child: Hero(
        tag: 'chapterEmblem_$chapterNumber',
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.6), // Gold tint
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
                // Changed to a bright, golden glow
                color: Colors.amber.withOpacity(0.8),
                spreadRadius: 4,
                blurRadius: 15.0,
                offset: Offset.zero,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
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
    );
  }
}
