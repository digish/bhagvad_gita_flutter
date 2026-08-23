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

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/app_router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/shloka_list_provider.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/font_size_control.dart';
import '../../data/static_data.dart';
import '../../data/database_helper_interface.dart';

import '../widgets/responsive_wrapper.dart';
import '../theme/app_colors.dart';
import '../widgets/spotlight_help_overlay.dart';
import '../widgets/reminder_pitch.dart';
import 'book_reading_screen.dart';

class ShlokaListScreen extends StatefulWidget {
  final String searchQuery;
  final bool showBackButton; // ✨ NEW parameter
  final bool delayEmblem; // ✨ NEW parameter for animation
  final bool isEmbedded; // ✨ NEW parameter for unified background
  final int? initialShlokaNo; // ✨ NEW parameter for scrolling
  /// When true (Settings → Help), always open the spotlight guide.
  final bool showHelp;

  const ShlokaListScreen({
    super.key,
    required this.searchQuery,
    this.showBackButton = true, // Default to true
    this.delayEmblem = false,
    this.isEmbedded = false,
    this.initialShlokaNo,
    this.showHelp = false,
  });

  @override
  State<ShlokaListScreen> createState() => _ShlokaListScreenState();
}

class _ShlokaListScreenState extends State<ShlokaListScreen> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];

  // REMOVED: Local PlaybackMode state. Now using AudioProvider directly.

  String? _currentShlokId;
  bool _hasInitialScrolled = false; // Flag to prevent multiple scrolls

  // --- FIX: Initialize the provider in initState to make it available to listeners ---
  late final ShlokaListProvider _shlokaProvider;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  bool _showHelpGuide = false;
  Timer? _helpGuideTimer;
  int? _helpVerseIndex;
  final GlobalKey _chapterTitleBarKey =
      GlobalKey(debugLabel: 'chapterTitleBar');
  final GlobalKey _fontSizeHelpKey = GlobalKey(debugLabel: 'chapterFontSize');
  final GlobalKey _bookModeHelpKey = GlobalKey(debugLabel: 'chapterBookMode');
  final GlobalKey _helpVerseActionsKey =
      GlobalKey(debugLabel: 'chapterVerseActions');

  /// Commentary book vs verse-card list (chapter view only).
  bool _isBookMode = false;
  /// Chapter list: which verse has Anvay/Bhavarth expanded (null = all collapsed).
  int? _expandedVerseIndex;

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
    _scheduleHelpGuide();
    final isChapter =
        int.tryParse(widget.searchQuery.split(',').first.trim()) != null;
    if (isChapter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          ReminderPitch.maybeShow(context, blocked: _showHelpGuide);
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant ShlokaListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHelp && !oldWidget.showHelp) {
      _scheduleHelpGuide();
    }
    if (widget.searchQuery != oldWidget.searchQuery) {
      _expandedVerseIndex = null;
    }
  }

  @override
  void dispose() {
    _helpGuideTimer?.cancel();
    // ✨ FIX: Use the stored provider instance for safe cleanup.
    _audioProvider?.removeListener(_handleAudioChange);
    _shlokaProvider.dispose(); // Dispose the provider we created.
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scheduleHelpGuide() async {
    final force = widget.showHelp;
    if (!force) {
      final done = await SpotlightHelpPrefs.isDone(kChapterHelpGuideDoneKey);
      if (done) return;
    }
    if (!mounted) return;
    _helpGuideTimer = Timer(const Duration(milliseconds: 900), () async {
      if (!mounted) return;
      final isChapter =
          int.tryParse(widget.searchQuery.split(',').first.trim()) != null;
      if (!force && !isChapter) return;
      for (var i = 0; i < 20 && _shlokaProvider.isLoading; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
      }
      if (!mounted) return;
      final count = _shlokaProvider.shlokas.length;
      if (count > 0) {
        // Wait until list item keys exist (built after load).
        for (var i = 0; i < 20 && _itemKeys.length < count; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          if (!mounted) return;
        }
        // Mid-chapter verse so the card spotlight isn't stuck on the first row.
        final mid = count ~/ 2;
        _helpVerseIndex = mid;
        // Expand so the action island exists for the help spotlight.
        _expandedVerseIndex = mid;
        if (mounted) setState(() {});
        await _scrollToIndex(mid, awaitVisible: true);
        if (!mounted) return;
        for (var i = 0; i < 24 && _helpVerseActionsKey.currentContext == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 80));
          if (!mounted) return;
        }
        final actionsCtx = _helpVerseActionsKey.currentContext;
        if (actionsCtx != null) {
          await Scrollable.ensureVisible(
            actionsCtx,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOutCubic,
            alignment: 0.72,
          );
        }
        if (!mounted) return;
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
      }
      setState(() => _showHelpGuide = true);
    });
  }

  void _closeHelpGuide() {
    if (!_showHelpGuide) return;
    setState(() => _showHelpGuide = false);
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

  Rect? _helpRectOf(GlobalKey key) {
    final ctx = key.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  List<SpotlightHelpStep> _chapterHelpSteps() {
    final titleBar = _helpRectOf(_chapterTitleBarKey);
    final font = _helpRectOf(_fontSizeHelpKey);
    final book = _helpRectOf(_bookModeHelpKey);
    final actionsRow = _helpRectOf(_helpVerseActionsKey);

    return [
      const SpotlightHelpStep(
        title: 'Chapter verses',
        body:
            'Each chapter is a list of shlokas you can read, play, and save.\n\n'
            'Next steps show text size, the commentary book, and verse actions.',
      ),
      SpotlightHelpStep(
        title: 'Size & commentary',
        body:
            'The font dock sits on the left — use − / + for text size.\n\n'
            'Tap the Book button to switch into continuous commentary reading.',
        globalHoles: [
          if (titleBar != null) titleBar,
          if (font != null) font,
          if (book != null) book,
        ],
        callouts: [
          if (font != null)
            SpotlightCallout(
              globalTarget: font.center,
              label: 'Size',
              arrow: SpotlightArrow.right,
            ),
          if (book != null)
            SpotlightCallout(
              globalTarget: book.center,
              label: 'Book / Verses',
              arrow: SpotlightArrow.down,
            ),
        ],
        cornerRadius: 24,
      ),
      SpotlightHelpStep(
        title: 'A verse card',
        body:
            'This is one shloka. Under the verse text you’ll find Play, bookmark, and Share.\n\n'
            'Close help, then try those buttons on any card. You can reopen this guide in Settings.',
        globalHoles: [if (actionsRow != null) actionsRow],
        callouts: [
          if (actionsRow != null)
            SpotlightCallout(
              globalTarget: Offset(
                actionsRow.center.dx,
                actionsRow.bottom,
              ),
              label: 'Play · Save · Share',
              arrow: SpotlightArrow.up,
            ),
        ],
        showTapHint: false,
        cornerRadius: 24,
      ),
    ];
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
  Future<void> _scrollToIndex(int index, {bool awaitVisible = false}) async {
    if (index < 0 || index >= _itemKeys.length) return;

    // Small delay to allow initial list render
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted || !_scrollController.hasClients) return;

    final key = _itemKeys[index];

    // If the Context is null, the item is not yet rendered by the SliverList.
    // Iteratively jump down the list to force it to render.
    if (key.currentContext == null) {
      double targetOffset = (index * 400.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(targetOffset);
      await Future.delayed(const Duration(milliseconds: 100));

      int maxAttempts = 20;
      int attempt = 0;
      while (key.currentContext == null &&
          attempt < maxAttempts &&
          mounted &&
          _scrollController.hasClients) {
        _scrollController.jumpTo(
          (_scrollController.offset + 800).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 50));
        attempt++;
      }
    }

    if (!mounted) return;

    Future<void> ensureVisibleNow() async {
      if (key.currentContext == null) {
        debugPrint("Cannot scroll to index $index: context is still null.");
        return;
      }

      final RenderBox renderBox =
          key.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final screenSize = MediaQuery.of(context).size;
      final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight + 80;

      // Prefer aligning near the top under the sticky chapter header.
      final fullyFramed =
          position.dy >= topPadding &&
          position.dy + math.min(renderBox.size.height, 320) <=
              screenSize.height - 24;

      if (!fullyFramed || awaitVisible) {
        debugPrint(
          "[SCROLL] Item at index $index — ensureVisible (await=$awaitVisible).",
        );
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: Duration(milliseconds: awaitVisible ? 500 : 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.08,
        );
      } else {
        debugPrint(
          "[SCROLL] Item at index $index is already visible. No scroll needed.",
        );
      }
    }

    if (awaitVisible) {
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await ensureVisibleNow();
      await Future<void>.delayed(const Duration(milliseconds: 80));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ensureVisibleNow();
      });
    }
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
                        // 1. Handle Navigation Scroll on First Load
                        if (widget.initialShlokaNo != null &&
                            !_hasInitialScrolled &&
                            shlokas.isNotEmpty) {
                          final targetIndex = shlokas.indexWhere(
                            (s) =>
                                s.shlokNo == widget.initialShlokaNo.toString(),
                          );
                          if (targetIndex != -1) {
                            _scrollToIndex(targetIndex);
                            _hasInitialScrolled = true;
                          }
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
                            _scrollToIndex(playingIndex);
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
                          if (chapterNumber != null) ...[
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).padding.top + 64,
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Center(
                                child: _ChapterEmblemHeader(
                                  chapterNumber: chapterNumber,
                                ),
                              ),
                            ),
                          ],
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final isChapter = chapterNumber != null;
                                final meaningsOpen =
                                    !isChapter ||
                                    _expandedVerseIndex == index;
                                return Container(
                                  key: _itemKeys[index],
                                  child: ResponsiveWrapper(
                                    child: FullShlokaCard(
                                      shloka: shlokas[index],
                                      config: _cardConfig.copyWith(
                                        baseFontSize:
                                            settingsProvider.fontSize,
                                        isLightTheme:
                                            Theme.of(context).brightness ==
                                            Brightness.light,
                                        showEmblem: !isChapter,
                                        showSeparator: isChapter
                                            ? meaningsOpen
                                            : true,
                                        showAnvay: meaningsOpen,
                                        showBhavarth: meaningsOpen,
                                        showActions: meaningsOpen,
                                        spacingCompact: isChapter,
                                        showMeaningsHint:
                                            isChapter && !meaningsOpen,
                                        helpActionsRowKey:
                                            index == _helpVerseIndex
                                            ? _helpVerseActionsKey
                                            : null,
                                      ),
                                      currentlyPlayingId: _currentShlokId,
                                      onTap: isChapter
                                          ? () {
                                              setState(() {
                                                _expandedVerseIndex =
                                                    _expandedVerseIndex ==
                                                        index
                                                    ? null
                                                    : index;
                                              });
                                            }
                                          : null,
                                      onPlayPause: () {
                                        Provider.of<AudioProvider>(
                                          context,
                                          listen: false,
                                        ).playChapter(
                                          shlokas: shlokas,
                                          initialIndex: index,
                                        );
                                      },
                                    ),
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
                  child: IgnorePointer(
                    ignoring: _showHelpGuide,
                    child: _ChapterPeekTitleBar(
                      key: _chapterTitleBarKey,
                      title: title,
                      showBack: _shouldShowBackButton(context),
                      onBack: () => _handleBack(context),
                      isBookMode: _isBookMode,
                      bookModeKey: _bookModeHelpKey,
                      onToggleMode: () {
                        setState(() => _isBookMode = !_isBookMode);
                      },
                    ),
                  ),
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
                        child: IgnorePointer(
                          ignoring: _showHelpGuide,
                          child: _ChapterFontSizeDock(
                            sizeClusterKey: _fontSizeHelpKey,
                            currentSize: settingsProvider.fontSize,
                            onSizeChanged: settingsProvider.setFontSize,
                          ),
                        ),
                      );
                    },
                  ),
              ],
              if (_showHelpGuide)
                Positioned.fill(
                  child: SpotlightHelpOverlay(
                    steps: _chapterHelpSteps(),
                    prefsKey: kChapterHelpGuideDoneKey,
                    onFinished: _closeHelpGuide,
                  ),
                ),
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
  final Key? bookModeKey;
  final VoidCallback onToggleMode;

  const _ChapterPeekTitleBar({
    super.key,
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
        KeyedSubtree(
          key: bookModeKey,
          child: _ChapterModeToggleButton(
            isBookMode: isBookMode,
            onTap: onToggleMode,
          ),
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

class _ChapterFontSizeDock extends StatelessWidget {
  final double currentSize;
  final ValueChanged<double> onSizeChanged;
  final Key? sizeClusterKey;

  const _ChapterFontSizeDock({
    required this.currentSize,
    required this.onSizeChanged,
    this.sizeClusterKey,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor =
        Theme.of(context).iconTheme.color ??
        (isLight ? Colors.black87 : Colors.white);
    final glass = isLight ? const Color(0xFFF7F4EE) : const Color(0xFF2A2A2A);

    return Material(
      color: glass,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(22),
        ),
        side: BorderSide(
          color: isLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        child: Theme(
          data: Theme.of(context).copyWith(
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: iconColor,
                disabledForegroundColor: iconColor.withValues(alpha: 0.35),
                overlayColor: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: KeyedSubtree(
            key: sizeClusterKey,
            child: FontSizeControl(
              currentSize: currentSize,
              onSizeChanged: onSizeChanged,
              color: iconColor,
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
