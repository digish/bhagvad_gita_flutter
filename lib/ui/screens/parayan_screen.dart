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
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/audio_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/static_data.dart';

import '../../providers/parayan_provider.dart';
import '../../models/shloka_result.dart';
import '../widgets/chapter_seek_rail.dart';
import '../widgets/parayan_action_island.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/font_size_control.dart';
import '../theme/app_colors.dart';

/// Compact top chrome below the status bar (back + optional sticky speaker).
const double _kParayanChromeExtra = 48.0;

/// Left inset so sticky speaker emblem/name clears the overlaid back button.
/// Keep in sync with inline [_SpeakerHeader] padding for vertical alignment.
const double _kParayanSpeakerBackClearance = 56.0;

/// Right inset used where chrome must clear the floating [ChapterSeekRail]
/// (header / action island). The shloka list itself stays full-width.
const double _kParayanRailInset = 72.0;

/// Viewport fraction for the reading focus line (cursor / card center target).
const double _kParayanFocusLine = 0.40;

/// Leading list item (blue lotus) so shloka 0 can scroll to the focus line.
const int _kParayanLeadingLotusItems = 1;

/// Must match home [DecorativeForeground] blue lotus Hero.
const String _kParayanBlueLotusHero = 'blueLotusHero';

/// Once-per-install coach mark: tap a shloka to reveal controls.
const String _kParayanTapDiscoverKey = 'parayan_tap_discover_done';

/// Once-per-install coach mark: chapter seek rail / glass.
const String _kParayanSeekDiscoverKey = 'parayan_seek_rail_discover_done';

double _parayanChromeHeight(BuildContext context) =>
    MediaQuery.of(context).padding.top + _kParayanChromeExtra;

/// Emblem asset for a speaker name (Parayan headers / sticky bar).
String? _parayanSpeakerEmblemPath(String speakerName) {
  final lower = speakerName.toLowerCase();
  if (lower.contains('bhagvan') ||
      lower.contains('bhagavan') ||
      lower.contains('krishna')) {
    return 'assets/emblems/krishna.png';
  }
  if (lower.contains('arjun')) return 'assets/emblems/arjun.png';
  if (lower.contains('sanjay')) return 'assets/emblems/sanjay.png';
  if (lower.contains('dhritarashtra')) {
    return 'assets/emblems/dhrutrashtra.png';
  }
  if (speakerName.contains('श्री भगवान') || speakerName.contains('श्रीभगवान')) {
    return 'assets/emblems/krishna.png';
  }
  if (speakerName.contains('अर्जुन')) return 'assets/emblems/arjun.png';
  if (speakerName.contains('संजय')) return 'assets/emblems/sanjay.png';
  if (speakerName.contains('धृतराष्ट्र')) {
    return 'assets/emblems/dhrutrashtra.png';
  }
  return null;
}

/// True when this list index shows an inline [_SpeakerHeader].
bool _parayanHasInlineSpeaker(List<ShlokaResult> shlokas, int index) {
  if (index < 0 || index >= shlokas.length) return false;
  if (index == 0) return true;
  final prev = shlokas[index - 1];
  final cur = shlokas[index];
  return prev.speaker != cur.speaker || prev.chapterNo != cur.chapterNo;
}

/// Chapter-start items put a title above the speaker line — offset so sticky
/// only locks once the speaker row itself reaches the pin line.
const double _kParayanChapterTitlePx = 64.0;
const double _kParayanInlineSpeakerPadTopPx = 18.0;

/// Speaker that should pin in the sticky bar, or null before the first inline
/// speaker line has reached the pin line (bottom of the top chrome / sticky).
String? _parayanStickySpeaker({
  required List<ShlokaResult> shlokas,
  required Iterable<ItemPosition> positions,
  required double stickyFrac,
  required double screenHeight,
  int listIndexOffset = _kParayanLeadingLotusItems,
}) {
  if (shlokas.isEmpty || positions.isEmpty || screenHeight <= 0) return null;

  final byIndex = <int, ItemPosition>{
    for (final p in positions) p.index: p,
  };
  final minVisibleList = positions
      .map((p) => p.index)
      .reduce((a, b) => a < b ? a : b);
  final minVisibleShloka = (minVisibleList - listIndexOffset).clamp(
    0,
    shlokas.length - 1,
  );

  String? pinned;
  for (var i = 0; i < shlokas.length; i++) {
    if (!_parayanHasInlineSpeaker(shlokas, i)) continue;
    final listIndex = i + listIndexOffset;
    // Past any visible item — later boundaries can't be pinned yet.
    if (i > minVisibleShloka && !byIndex.containsKey(listIndex)) break;

    final pos = byIndex[listIndex];
    if (pos == null) {
      // Scrolled fully above the viewport ⇒ already passed the sticky line.
      if (i < minVisibleShloka) {
        pinned = shlokas[i].speaker;
      }
      continue;
    }

    final isChapterStart =
        i == 0 || shlokas[i].chapterNo != shlokas[i - 1].chapterNo;
    // Top of the emblem/name row (not the item/column top).
    // First shloka also has the leading lotus above chapter/speaker in the
    // same list item? No — lotus is its own leading list item.
    final rowOffsetPx = _kParayanInlineSpeakerPadTopPx +
        (isChapterStart ? _kParayanChapterTitlePx : 0.0);
    final speakerTop = pos.itemLeadingEdge + rowOffsetPx / screenHeight;

    if (speakerTop <= stickyFrac) {
      pinned = shlokas[i].speaker;
    }
  }

  return pinned;
}

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

  int _listIndexForShloka(int shlokaIndex) =>
      shlokaIndex + _kParayanLeadingLotusItems;

  int? _shlokaIndexForList(int listIndex) {
    if (listIndex < _kParayanLeadingLotusItems) return null;
    return listIndex - _kParayanLeadingLotusItems;
  }

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

  /// Remember expand/collapse of anvay+translation across shloka selection.
  bool _meaningsExpanded = false;

  /// Collapsed list body: shloka → anvay → translation.
  ContinuousListBody _listBodyMode = ContinuousListBody.shloka;

  /// Font-size dock: expanded when idle, tucks into the left wall while scrolling.
  bool _fontDockExpanded = true;
  Timer? _fontDockRevealTimer;
  Timer? _fontDockTuckTimer;
  int? _fontDockLastIndex;
  double? _fontDockLastLead;
  /// Ignore layout-driven position noise while changing font size.
  bool _suppressFontDockScroll = false;
  DateTime? _fontDockScrollStartedAt;

  /// First-visit coach: tap a shloka for the action island.
  bool _showTapDiscoverHint = false;
  Timer? _tapDiscoverShowTimer;
  Timer? _tapDiscoverHideTimer;

  /// First-visit coach: drag the seek-rail glass.
  bool _showSeekDiscoverHint = false;
  Timer? _seekDiscoverShowTimer;
  Timer? _seekDiscoverHideTimer;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  @override
  void initState() {
    super.initState();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _audioProvider?.addListener(_handleAudioChange);
    _itemPositionsListener.itemPositions.addListener(_onParayanScrollForFontDock);
    _scheduleDiscoverHints();
  }

  @override
  void dispose() {
    _fontDockRevealTimer?.cancel();
    _fontDockTuckTimer?.cancel();
    _tapDiscoverShowTimer?.cancel();
    _tapDiscoverHideTimer?.cancel();
    _seekDiscoverShowTimer?.cancel();
    _seekDiscoverHideTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(
      _onParayanScrollForFontDock,
    );
    _currentPositionLabelNotifier.dispose(); // ✨ Add this line
    _audioProvider?.removeListener(_handleAudioChange);
    super.dispose();
  }

  Future<void> _scheduleDiscoverHints() async {
    final prefs = await SharedPreferences.getInstance();
    final tapDone = prefs.getBool(_kParayanTapDiscoverKey) ?? false;
    final seekDone = prefs.getBool(_kParayanSeekDiscoverKey) ?? false;
    if (!mounted) return;
    if (!tapDone) {
      // Let the list paint first, then fade the tip in.
      _tapDiscoverShowTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _showTapDiscoverHint = true);
        _tapDiscoverHideTimer = Timer(const Duration(seconds: 6), () {
          _dismissTapDiscoverHint();
        });
      });
    } else if (!seekDone) {
      _scheduleSeekDiscoverHint(
        delay: const Duration(milliseconds: 900),
      );
    }
  }

  void _scheduleSeekDiscoverHint({required Duration delay}) {
    _seekDiscoverShowTimer?.cancel();
    _seekDiscoverHideTimer?.cancel();
    _seekDiscoverShowTimer = Timer(delay, () async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kParayanSeekDiscoverKey) ?? false) return;
      if (!mounted) return;
      setState(() => _showSeekDiscoverHint = true);
      _seekDiscoverHideTimer = Timer(const Duration(seconds: 6), () {
        _dismissSeekDiscoverHint();
      });
    });
  }

  Future<void> _dismissTapDiscoverHint() async {
    _tapDiscoverShowTimer?.cancel();
    _tapDiscoverHideTimer?.cancel();
    final wasShowing = _showTapDiscoverHint;
    if (_showTapDiscoverHint && mounted) {
      setState(() => _showTapDiscoverHint = false);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kParayanTapDiscoverKey, true);
    final seekDone = prefs.getBool(_kParayanSeekDiscoverKey) ?? false;
    if (!seekDone) {
      _scheduleSeekDiscoverHint(
        delay: wasShowing
            ? const Duration(milliseconds: 450)
            : const Duration(milliseconds: 900),
      );
    }
  }

  Future<void> _dismissSeekDiscoverHint() async {
    _seekDiscoverShowTimer?.cancel();
    _seekDiscoverHideTimer?.cancel();
    if (_showSeekDiscoverHint && mounted) {
      setState(() => _showSeekDiscoverHint = false);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kParayanSeekDiscoverKey, true);
  }

  void _onParayanScrollForFontDock() {
    if (_suppressFontDockScroll) return;
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || !mounted) return;

    final top = positions.reduce(
      (a, b) => a.itemLeadingEdge <= b.itemLeadingEdge ? a : b,
    );
    // Seed baseline without treating first callback as a scroll.
    if (_fontDockLastIndex == null || _fontDockLastLead == null) {
      _fontDockLastIndex = top.index;
      _fontDockLastLead = top.itemLeadingEdge;
      return;
    }

    // Ignore tiny jitter / one-finger nudges.
    final leadDelta = (top.itemLeadingEdge - _fontDockLastLead!).abs();
    final indexChanged = _fontDockLastIndex != top.index;
    final meaningfulScroll = indexChanged || leadDelta > 0.012;
    _fontDockLastIndex = top.index;
    _fontDockLastLead = top.itemLeadingEdge;
    if (!meaningfulScroll) return;

    final now = DateTime.now();
    _fontDockScrollStartedAt ??= now;

    // Keep resetting the reveal timer while scrolling continues.
    _fontDockRevealTimer?.cancel();
    _fontDockRevealTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _fontDockScrollStartedAt = null;
      _fontDockTuckTimer?.cancel();
      _fontDockTuckTimer = null;
      if (!_fontDockExpanded) {
        setState(() => _fontDockExpanded = true);
      }
    });

    // Only tuck after sustained scrolling (~2s), not on brief flicks.
    if (_fontDockExpanded && _fontDockTuckTimer == null) {
      final alreadyScrollingFor = now.difference(_fontDockScrollStartedAt!);
      final remaining = const Duration(seconds: 2) - alreadyScrollingFor;
      _fontDockTuckTimer = Timer(
        remaining.isNegative ? Duration.zero : remaining,
        () {
          _fontDockTuckTimer = null;
          if (!mounted || _suppressFontDockScroll) return;
          // Still in an active scroll window if reveal hasn't fired yet.
          if (_fontDockRevealTimer?.isActive == true && _fontDockExpanded) {
            setState(() => _fontDockExpanded = false);
          }
        },
      );
    }
  }

  void _revealFontDockNow() {
    _fontDockRevealTimer?.cancel();
    _fontDockTuckTimer?.cancel();
    _fontDockTuckTimer = null;
    _fontDockScrollStartedAt = null;
    if (!_fontDockExpanded) {
      setState(() => _fontDockExpanded = true);
    }
  }

  /// Shloka whose center is nearest the reading focus line.
  int _indexNearestFocusLine() {
    final positions = _itemPositionsListener.itemPositions.value;
    final count =
        Provider.of<ParayanProvider>(context, listen: false).shlokas.length;
    if (positions.isEmpty || count <= 0) {
      return _selectedIndex ?? 0;
    }
    final shlokaPositions = positions
        .where((p) => _shlokaIndexForList(p.index) != null)
        .toList();
    if (shlokaPositions.isEmpty) return _selectedIndex ?? 0;
    final focusItem = shlokaPositions.reduce((a, b) {
      final aCenter = (a.itemLeadingEdge + a.itemTrailingEdge) / 2;
      final bCenter = (b.itemLeadingEdge + b.itemTrailingEdge) / 2;
      return (aCenter - _kParayanFocusLine).abs() <=
              (bCenter - _kParayanFocusLine).abs()
          ? a
          : b;
    });
    return _shlokaIndexForList(focusItem.index)!.clamp(0, count - 1);
  }

  /// Change font without losing the focused shloka or tucking the dock.
  Future<void> _onFontSizeChanged(double newSize) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final keepIndex = _selectedIndex ?? _indexNearestFocusLine();

    _suppressFontDockScroll = true;
    _fontDockRevealTimer?.cancel();
    _fontDockTuckTimer?.cancel();
    _fontDockTuckTimer = null;
    _fontDockScrollStartedAt = null;
    if (!_fontDockExpanded && mounted) {
      setState(() => _fontDockExpanded = true);
    }

    await settings.setFontSize(newSize);
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
    }

    await _repinFocusAfterLayoutChange(keepIndex);
  }

  Future<void> _onToggleListContent() async {
    final keepIndex = _selectedIndex ?? _indexNearestFocusLine();
    _suppressFontDockScroll = true;
    _fontDockRevealTimer?.cancel();
    _fontDockTuckTimer?.cancel();
    _fontDockTuckTimer = null;
    _fontDockScrollStartedAt = null;
    if (!_fontDockExpanded && mounted) {
      setState(() => _fontDockExpanded = true);
    }

    setState(() {
      _listBodyMode = switch (_listBodyMode) {
        ContinuousListBody.shloka => ContinuousListBody.anvay,
        ContinuousListBody.anvay => ContinuousListBody.translation,
        ContinuousListBody.translation => ContinuousListBody.shloka,
      };
    });
    await _repinFocusAfterLayoutChange(keepIndex);
  }

  Future<void> _repinFocusAfterLayoutChange(int keepIndex) async {
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
    }

    // Let cards rebuild, then pin the same shloka to the focus line.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _suppressFontDockScroll = false;
        return;
      }
      if (_itemScrollController.isAttached) {
        final listIndex = _listIndexForShloka(keepIndex);
        final alignment = _alignmentForCardCenter(keepIndex) ??
            (_kParayanFocusLine - 0.09).clamp(0.0, 1.0);
        _itemScrollController.jumpTo(index: listIndex, alignment: alignment);
      }
      // Refine once new item heights are known, then reseed dock baseline.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_itemScrollController.isAttached) {
          final refined = _alignmentForCardCenter(
            keepIndex,
            requireVisible: true,
          );
          if (refined != null) {
            _itemScrollController.jumpTo(
              index: _listIndexForShloka(keepIndex),
              alignment: refined,
            );
          }
        }
        final positions = _itemPositionsListener.itemPositions.value;
        if (positions.isNotEmpty) {
          final top = positions.reduce(
            (a, b) => a.itemLeadingEdge <= b.itemLeadingEdge ? a : b,
          );
          _fontDockLastIndex = top.index;
          _fontDockLastLead = top.itemLeadingEdge;
        }
        _suppressFontDockScroll = false;
      });
    });
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

  Future<void> _onCardTap(int index) async {
    if (_isSelectingCard) return;
    unawaited(_dismissTapDiscoverHint());

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
      // Skip scroll when the card is already near the focus line.
      var needsScroll = true;
      final positions = _itemPositionsListener.itemPositions.value;
      final listIndex = _listIndexForShloka(index);
      for (final p in positions) {
        if (p.index == listIndex) {
          final center = (p.itemLeadingEdge + p.itemTrailingEdge) / 2;
          if ((center - _kParayanFocusLine).abs() <= 0.045) {
            needsScroll = false;
          }
          break;
        }
      }
      if (needsScroll) {
        await _scrollCardCenterToFocusLine(index);
      }
      if (!mounted) return;

      // After the snappy scroll lands — show highlight + action island.
      setState(() {
        _selectedIndex = index;
        _actionsVisible = true;
      });
    } finally {
      _isSelectingCard = false;
    }
  }

  /// Scroll so the focus cursor sits at the vertical center of [shlokaIndex].
  Future<void> _scrollCardCenterToFocusLine(int shlokaIndex) async {
    if (!_itemScrollController.isAttached) return;
    final listIndex = _listIndexForShloka(shlokaIndex);

    await _itemScrollController.scrollTo(
      index: listIndex,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: _alignmentForCardCenter(shlokaIndex) ??
          (_kParayanFocusLine - 0.09).clamp(0.0, 1.0),
    );

    // One frame to let positions update, then fine-tune if needed.
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted || !_itemScrollController.isAttached) return;

    final refined = _alignmentForCardCenter(shlokaIndex, requireVisible: true);
    if (refined == null) return;

    final positions = _itemPositionsListener.itemPositions.value;
    ItemPosition? item;
    for (final p in positions) {
      if (p.index == listIndex) {
        item = p;
        break;
      }
    }
    if (item == null) return;

    final center = (item.itemLeadingEdge + item.itemTrailingEdge) / 2;
    if ((center - _kParayanFocusLine).abs() <= 0.025) return;

    await _itemScrollController.scrollTo(
      index: listIndex,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOutCubic,
      alignment: refined,
    );
  }

  /// Viewport alignment for item leading edge so its center hits [_kParayanFocusLine].
  double? _alignmentForCardCenter(int shlokaIndex, {bool requireVisible = false}) {
    final listIndex = _listIndexForShloka(shlokaIndex);
    final positions = _itemPositionsListener.itemPositions.value;
    for (final p in positions) {
      if (p.index == listIndex) {
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
  void _scrollToIndex(int shlokaIndex) {
    unawaited(_dismissSeekDiscoverHint());
    // Align the target shloka to the same 40% focus line the glass tracks.
    _scrollCardCenterToFocusLine(shlokaIndex);
  }

  /// Instant seek used while dragging the glass — keep center on the focus line
  /// so the label and the verse under the cursor stay in sync.
  void _jumpToIndex(int shlokaIndex) {
    unawaited(_dismissSeekDiscoverHint());
    if (!_itemScrollController.isAttached) return;
    final alignment = _alignmentForCardCenter(shlokaIndex) ??
        (_kParayanFocusLine - 0.09).clamp(0.0, 1.0);
    _itemScrollController.jumpTo(
      index: _listIndexForShloka(shlokaIndex),
      alignment: alignment,
    );
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
              showMandala: false,
              showLeaves: true,
              startColor:
                  Theme.of(
                    context,
                  ).extension<AppColors>()?.parayanGradientStart ??
                  const Color.fromARGB(255, 103, 108, 255),
            ),
          Consumer<ParayanProvider>(
            builder: (context, provider, child) {
              // Continuous reading: shlok only. Anvay / tika expand under the
              // selected card after tap.
              final cardConfig = FullShlokaCardConfig(
                baseFontSize: settingsProvider.fontSize,
                showAnvay: false,
                showBhavarth: false,
                showSeparator: false,
                showActions: false,
                showSpeaker: false,
                showColoredCard: false,
                showEmblem: false,
                showShlokIndex: true,
                spacingCompact: true,
                continuousReading: true,
              );

              final shlokas = provider.shlokas;
              final audio = Provider.of<AudioProvider>(context);
              final miniPlayerVisible =
                  audio.playbackState != PlaybackState.stopped &&
                  audio.currentPlayingShlokaId != null;

              // Always build the leading lotus Hero on first frame so the
              // search→parayan flight can run (loading used to hide it).
              final listItemCount =
                  shlokas.length + _kParayanLeadingLotusItems;
              final lotusHeaderHeight =
                  (MediaQuery.of(context).size.height * 0.30).clamp(
                    140.0,
                    260.0,
                  );

              return ResponsiveWrapper(
                maxWidth: 1200, // ✨ NEW: Increased width for iPad
                child: Stack(
                  children: [
                    ScrollablePositionedList.builder(
                  key: const PageStorageKey(
                    'parayan_list',
                  ), // ✨ FIX: Persist scroll state
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: listItemCount,
                  // ✨ FIX: Apply the initial padding here. This is the correct way to offset the list
                  // without interfering with the item position listener.
                  padding: EdgeInsets.only(
                    top: _parayanChromeHeight(context),
                    left: MediaQuery.of(
                      context,
                    ).padding.left, // Respect injected padding
                    // Full-width cards — seek rail floats on top, does not inset the list.
                    right: MediaQuery.of(context).padding.right,
                    bottom: miniPlayerVisible ? 148.0 : 64.0,
                  ),
                  itemBuilder: (context, listIndex) {
                    if (listIndex < _kParayanLeadingLotusItems) {
                      return _ParayanLeadingLotusHeader(
                        height: lotusHeaderHeight,
                      );
                    }
                    final index = listIndex - _kParayanLeadingLotusItems;
                    if (index >= shlokas.length) {
                      return const SizedBox.shrink();
                    }
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
                            fontSize: settingsProvider.fontSize,
                          ),
                        if (speakerChanged || isChapterStart)
                          _SpeakerHeader(
                            speaker: shloka.speaker ?? "Uvacha",
                            script: script,
                            fontSize: settingsProvider.fontSize,
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
                            continuousReading: true,
                            listBodyMode: _listBodyMode,
                            // Meanings follow the remembered expand state.
                            showAnvay:
                                _selectedIndex == index && _meaningsExpanded,
                            showBhavarth:
                                _selectedIndex == index && _meaningsExpanded,
                            showSeparator: false,
                            isLightTheme:
                                Theme.of(context).brightness ==
                                Brightness.light,
                          ),
                        ),
                        // Subtle left-aligned rule between verses (not before chapter end).
                        if (!isChapterEnd) const _ParayanVerseRule(),
                        if (isChapterEnd)
                          _ChapterEndFooter(
                            chapterNumber: int.tryParse(shloka.chapterNo) ?? 0,
                            chapterName: StaticData.getChapterName(
                              int.tryParse(shloka.chapterNo) ?? 1,
                              script,
                            ),
                            script: script,
                            fontSize: settingsProvider.fontSize,
                          ),
                      ],
                    );
                  },
                ),
                    if (provider.isLoading)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
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
                  final topPadding = _parayanChromeHeight(context);
                  return Positioned(
                    right: MediaQuery.of(context).padding.right,
                    top: topPadding,
                    bottom: 8,
                    child: ChapterSeekRail(
                      itemPositionsListener: _itemPositionsListener,
                      itemCount:
                          provider.shlokas.length + _kParayanLeadingLotusItems,
                      chapterMarkers: [
                        for (final i in provider.chapterStartIndices)
                          i + _kParayanLeadingLotusItems,
                      ],
                      focusLine: _kParayanFocusLine,
                      chapterForIndex: (listIndex) {
                        final s = _shlokaIndexForList(listIndex);
                        if (s == null) {
                          return provider.shlokas.isEmpty
                              ? '1'
                              : provider.shlokas.first.chapterNo;
                        }
                        return provider.shlokas[s].chapterNo;
                      },
                      onChapterTap: (chapterIndex) {
                        final shlokaIndex =
                            provider.chapterStartIndices[chapterIndex];
                        _scrollToIndex(shlokaIndex);
                      },
                      onSeekToIndex: (listIndex) {
                        final s = _shlokaIndexForList(listIndex);
                        if (s != null) _jumpToIndex(s);
                      },
                    ),
                  );
                },
              );
            },
          ),
          // Sticky speaker shares the back-button row (drawn under the back hit target)
          Consumer<ParayanProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading || provider.shlokas.isEmpty) {
                return const SizedBox.shrink();
              }
              return ValueListenableBuilder<Iterable<ItemPosition>>(
                valueListenable: _itemPositionsListener.itemPositions,
                builder: (context, positions, _) {
                  final headerH = _parayanChromeHeight(context);
                  final screenH = MediaQuery.of(context).size.height;
                  // Pin when the inline speaker row reaches the bottom of the
                  // top chrome / persistent speaker bar.
                  final stickyFrac = headerH / screenH;
                  final speaker = _parayanStickySpeaker(
                    shlokas: provider.shlokas,
                    positions: positions,
                    stickyFrac: stickyFrac,
                    screenHeight: screenH,
                  );

                  if (speaker == null || speaker.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    left: MediaQuery.of(context).padding.left,
                    right: ChapterSeekRail.glassRadius + 12,
                    top: 0,
                    height: headerH,
                    child: _StickySpeakerBar(
                      speaker: speaker,
                      script: settingsProvider.script,
                      fontSize: settingsProvider.fontSize,
                      leadingInset: _kParayanSpeakerBackClearance,
                    ),
                  );
                },
              );
            },
          ),
          // Back button on top of sticky speaker so taps always hit it
          Positioned(
            left: MediaQuery.of(context).padding.left,
            top: 0,
            right: _kParayanRailInset,
            height: _parayanChromeHeight(context),
            child: const _ParayanChrome(),
          ),
          // Cursor tracks the selected card; resets to the focus line on new tap
          // (selection is cleared during scroll-to-focus, then reappears at home).
          if (_selectedIndex != null)
            ValueListenableBuilder<Iterable<ItemPosition>>(
              valueListenable: _itemPositionsListener.itemPositions,
              builder: (context, positions, _) {
                var focusLine = _kParayanFocusLine;
                final selectedList = _listIndexForShloka(_selectedIndex!);
                for (final p in positions) {
                  if (p.index == selectedList) {
                    focusLine =
                        (p.itemLeadingEdge + p.itemTrailingEdge) / 2;
                    break;
                  }
                }
                return _ParayanFocusPointer(focusLine: focusLine);
              },
            ),
          if (_showTapDiscoverHint)
            _ParayanTapDiscoverHint(
              focusLine: _kParayanFocusLine,
              onDismiss: _dismissTapDiscoverHint,
            ),
          if (_showSeekDiscoverHint)
            _ParayanSeekDiscoverHint(
              onDismiss: _dismissSeekDiscoverHint,
            ),
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
              // Match continuous card selection accent (bright gold).
              const accent = Color(0xFFFFD700);

              return ValueListenableBuilder<Iterable<ItemPosition>>(
                valueListenable: _itemPositionsListener.itemPositions,
                builder: (context, positions, _) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  const islandHeight = 56.0;
                  const gapAboveCard = 20.0;

                  double? top;
                  final targetList = _listIndexForShloka(targetIndex);
                  for (final p in positions) {
                    if (p.index == targetList) {
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
                            meaningsExpanded: _meaningsExpanded,
                            onToggleMeanings: () {
                              setState(() {
                                _meaningsExpanded = !_meaningsExpanded;
                              });
                            },
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
          // Font size — left wall dock; tucks in while scrolling
          Consumer<AudioProvider>(
            builder: (context, audio, _) {
              final miniPlayerVisible =
                  audio.playbackState != PlaybackState.stopped &&
                  audio.currentPlayingShlokaId != null;
              final bottomSafe = MediaQuery.of(context).padding.bottom;
              return Positioned(
                left: MediaQuery.of(context).padding.left,
                bottom: miniPlayerVisible ? 96 + bottomSafe : 12 + bottomSafe,
                child: _ParayanFontSizeDock(
                  settingsProvider: settingsProvider,
                  expanded: _fontDockExpanded,
                  onPeekTap: _revealFontDockNow,
                  onSizeChanged: _onFontSizeChanged,
                  listBodyMode: _listBodyMode,
                  onToggleListContent: _onToggleListContent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Soft first-visit tip near the reading line — tap a shloka for controls.
class _ParayanTapDiscoverHint extends StatelessWidget {
  final double focusLine;
  final VoidCallback onDismiss;

  const _ParayanTapDiscoverHint({
    required this.focusLine,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final screenHeight = MediaQuery.of(context).size.height;
    final top = (screenHeight * focusLine) - 52;

    return Positioned(
      left: MediaQuery.of(context).padding.left + 20,
      right: _kParayanRailInset + 8,
      top: top.clamp(
        _parayanChromeHeight(context) + 8,
        screenHeight - 120,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 8 * (1 - t)),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 26,
                          color: isLight
                              ? const Color(0xFF8B6914)
                              : const Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tap a shloka to play, bookmark, share, or expand meaning',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: isLight
                                  ? Colors.black87
                                  : Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: onDismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isLight
                                ? Colors.black45
                                : Colors.white54,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
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

/// First-visit tip for the chapter seek rail — sits beside the circular glass.
class _ParayanSeekDiscoverHint extends StatelessWidget {
  final VoidCallback onDismiss;

  const _ParayanSeekDiscoverHint({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final railTop = _parayanChromeHeight(context);
    const railBottom = 8.0;
    final railHeight = screenHeight - railTop - railBottom;
    // Glass rests on the reading focus line within the rail track.
    const trackPad = 20.0;
    final glassCenterY =
        railTop +
        trackPad +
        _kParayanFocusLine * (railHeight - 2 * trackPad);
    const tipHeight = 72.0;
    // Tip ends just left of the glass (glass sits on the inner side of the rail).
    final tipRight =
        media.padding.right +
        ChapterSeekRail.width -
        (ChapterSeekRail.glassRadius + 2) -
        6;

    return Positioned(
      right: tipRight.clamp(8.0, media.size.width * 0.5),
      width: (media.size.width * 0.58).clamp(200.0, 280.0),
      top: (glassCenterY - tipHeight / 2).clamp(
        railTop + 4,
        screenHeight - tipHeight - 24,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(10 * (1 - t), 0),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF047BC0).withValues(alpha: 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF047BC0).withValues(alpha: 0.16),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Drag the glass or tap chapter dots to jump through the Parayan',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.25,
                              fontWeight: FontWeight.w500,
                              color: isLight
                                  ? Colors.black87
                                  : Colors.white.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_right_alt_rounded,
                          size: 28,
                          color: isLight
                              ? const Color(0xFF047BC0)
                              : const Color(0xFF7EC8F0),
                        ),
                        IconButton(
                          onPressed: onDismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isLight
                                ? Colors.black45
                                : Colors.white54,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ),
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

/// Focus triangle on the left — sits on [focusLine] (selected card center while scrolling).
class _ParayanFocusPointer extends StatelessWidget {
  final double focusLine;

  const _ParayanFocusPointer({required this.focusLine});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFD700);
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

/// Minimal top chrome: independent back button.
class _ParayanChrome extends StatelessWidget {
  const _ParayanChrome();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor =
        Theme.of(context).iconTheme.color ??
        (isLight ? Colors.black87 : Colors.white);

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.centerLeft,
        child: MediaQuery.of(context).size.width <= 600
            ? IconButton(
                tooltip: 'Back',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                icon: Icon(Icons.arrow_back_ios_new, size: 20, color: iconColor),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Bottom-left font-size dock — speaker-bar style; tucks into the left wall
/// while scrolling and slides back out after idle.
class _ParayanFontSizeDock extends StatelessWidget {
  final SettingsProvider settingsProvider;
  final bool expanded;
  final VoidCallback? onPeekTap;
  final ValueChanged<double> onSizeChanged;
  final ContinuousListBody listBodyMode;
  final VoidCallback onToggleListContent;

  const _ParayanFontSizeDock({
    required this.settingsProvider,
    required this.expanded,
    required this.onSizeChanged,
    required this.listBodyMode,
    required this.onToggleListContent,
    this.onPeekTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor =
        Theme.of(context).iconTheme.color ??
        (isLight ? Colors.black87 : Colors.white);
    final accent = Theme.of(context).colorScheme.secondary;

    final (Widget modeGlyph, String label, String tooltip, bool emphasize) =
        switch (listBodyMode) {
      ContinuousListBody.shloka => (
          Icon(Icons.menu_book_rounded, size: 20, color: iconColor),
          'Shloka',
          'Shloka · tap for anvay',
          false,
        ),
      ContinuousListBody.anvay => (
          Icon(Icons.format_quote_rounded, size: 20, color: accent),
          'Anvay',
          'Anvay · tap for translation',
          true,
        ),
      ContinuousListBody.translation => (
          Text(
            'अ',
            style: TextStyle(
              fontFamily: 'NotoSerif',
              fontSize: 18,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          'Tika',
          'Translation · tap for shloka',
          true,
        ),
    };
    final modeColor = emphasize ? accent : iconColor;

    final dock = ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(22),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white.withValues(alpha: 0.55)
                : Colors.black.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(22),
            ),
            border: Border.all(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FontSizeControl(
                  currentSize: settingsProvider.fontSize,
                  onSizeChanged: onSizeChanged,
                  color: iconColor,
                ),
                Container(
                  width: 1,
                  height: 22,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: iconColor.withValues(alpha: 0.25),
                ),
                Tooltip(
                  message: tooltip,
                  child: InkWell(
                    onTap: onToggleListContent,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            child: Center(child: modeGlyph),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: modeColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: expanded ? Curves.easeOutCubic : Curves.easeInCubic,
      // Mostly off-screen left; leave a small peek of the rounded end.
      offset: expanded ? Offset.zero : const Offset(-0.78, 0),
      child: GestureDetector(
        onTap: expanded ? null : onPeekTap,
        behavior: HitTestBehavior.opaque,
        child: dock,
      ),
    );
  }
}

// --- Reusable private widgets for the list items ---

/// Short left-aligned hairline between continuous shlokas.
class _ParayanVerseRule extends StatelessWidget {
  const _ParayanVerseRule();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 56, 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 88,
          height: 1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                (isLight ? const Color(0xFFB8860B) : const Color(0xFFFFD700))
                    .withValues(alpha: isLight ? 0.35 : 0.28),
                (isLight ? Colors.black : Colors.white)
                    .withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Scrolls away above chapter 1 — gives room for shloka 0 on the focus line.
/// Hero matches Adhyay: same tag flight as home (rotate + move). Tap → search.
class _ParayanLeadingLotusHeader extends StatelessWidget {
  final double height;

  const _ParayanLeadingLotusHeader({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              // Prefer pop (keeps Hero reverse flight); else go search home.
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Hero(
                tag: _kParayanBlueLotusHero,
                // Same rotate shuttle as home / Adhyay white lotus flight.
                flightShuttleBuilder: (
                  flightContext,
                  animation,
                  flightDirection,
                  fromHeroContext,
                  toHeroContext,
                ) {
                  return RotationTransition(
                    turns: animation,
                    child: (toHeroContext.widget as Hero).child,
                  );
                },
                child: Image.asset(
                  'assets/images/lotus_blue12.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChapterStartHeader extends StatelessWidget {
  final int chapterNumber;
  final String script;
  final double fontSize;

  const _ChapterStartHeader({
    required this.chapterNumber,
    required this.script,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final safeChapterNum = chapterNumber < 1 ? 1 : chapterNumber;
    final chapterLabel = StaticData.getChapterLabel(script);
    final localNum = StaticData.localizeNumber(safeChapterNum, script);
    final chapterName = StaticData.getChapterName(safeChapterNum, script);
    const titleColor = Color.fromARGB(255, 4, 123, 192);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final lineColor = titleColor.withValues(alpha: isLight ? 0.4 : 0.55);

    return Padding(
      // Match speaker insets; clear seek-rail glass lane on the right.
      padding: const EdgeInsets.fromLTRB(16, 20, 56, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 14,
              child: Transform.flip(
                flipX: true,
                child: CustomPaint(
                  painter: _SpeakerFlourishPainter(color: lineColor),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fontSize * 0.35),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.55,
              ),
              child: Text(
                '$chapterLabel $localNum $chapterName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: fontSize + 2,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.4,
                  height: 1.25,
                ),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 14,
              child: CustomPaint(
                painter: _SpeakerFlourishPainter(color: lineColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickySpeakerBar extends StatelessWidget {
  final String speaker;
  final String script;
  final double fontSize;
  final double leadingInset;

  const _StickySpeakerBar({
    required this.speaker,
    required this.script,
    required this.fontSize,
    this.leadingInset = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = Theme.of(context).colorScheme.secondary;
    final lineColor = accent.withValues(alpha: isLight ? 0.45 : 0.55);
    final localized = StaticData.localizeSpeaker(speaker, script);
    final emblemPath = _parayanSpeakerEmblemPath(speaker);
    final emblemSize = (fontSize * 1.1).clamp(18.0, 28.0);
    final labelSize = (fontSize * 0.72).clamp(13.0, 22.0);

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(22),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.black.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(22),
                ),
                border: Border.all(
                  color: isLight
                      ? Colors.black.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: SizedBox(
                height: _kParayanChromeExtra - 4,
                child: Padding(
                  // Clear the overlaid back button for emblem + name.
                  padding: EdgeInsets.fromLTRB(leadingInset, 0, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (emblemPath != null) ...[
                        Image.asset(emblemPath, height: emblemSize),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          localized,
                          textAlign: TextAlign.left,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'NotoSerif',
                            fontSize: labelSize,
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 12,
                          child: CustomPaint(
                            painter: _SpeakerFlourishPainter(color: lineColor),
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
    );
  }
}

class _SpeakerHeader extends StatelessWidget {
  final String speaker;
  final String script;
  final double fontSize;

  const _SpeakerHeader({
    required this.speaker,
    required this.script,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final String? emblemPath = _parayanSpeakerEmblemPath(speaker);
    final localizedSpeaker = StaticData.localizeSpeaker(speaker, script);
    final accent = Theme.of(context).colorScheme.secondary;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final lineColor = accent.withValues(alpha: isLight ? 0.45 : 0.55);
    final emblemSize = (fontSize * 1.35).clamp(22.0, 40.0);

    return Padding(
      // Match sticky bar: clear back button, align emblem/name under persistent.
      padding: const EdgeInsets.fromLTRB(
        _kParayanSpeakerBackClearance,
        _kParayanInlineSpeakerPadTopPx,
        56,
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (emblemPath != null) ...[
            Image.asset(
              emblemPath,
              height: emblemSize,
            ),
            SizedBox(width: fontSize * 0.35),
          ],
          Text(
            localizedSpeaker,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'NotoSerif',
              fontSize: fontSize * 0.78,
              color: accent,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.2,
            ),
          ),
          SizedBox(width: fontSize * 0.45),
          Expanded(
            child: SizedBox(
              height: 14,
              child: CustomPaint(
                painter: _SpeakerFlourishPainter(color: lineColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin manuscript-style rule with a small diamond tick, filling width after
/// the speaker name.
class _SpeakerFlourishPainter extends CustomPainter {
  final Color color;

  _SpeakerFlourishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 8) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final midX = size.width * 0.42;
    const diamond = 3.5;

    // Left rule → diamond → right rule
    canvas.drawLine(Offset(0, midY), Offset(midX - diamond - 4, midY), paint);
    canvas.drawLine(
      Offset(midX + diamond + 4, midY),
      Offset(size.width, midY),
      paint,
    );

    final path = Path()
      ..moveTo(midX, midY - diamond)
      ..lineTo(midX + diamond, midY)
      ..lineTo(midX, midY + diamond)
      ..lineTo(midX - diamond, midY)
      ..close();
    canvas.drawPath(path, paint);

    // Soft hairline dots near the ends for a bit more “line art” presence.
    final dot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    if (midX - diamond - 14 > 6) {
      canvas.drawCircle(Offset(midX - diamond - 10, midY), 1.2, dot);
    }
    if (midX + diamond + 14 < size.width - 4) {
      canvas.drawCircle(Offset(midX + diamond + 10, midY), 1.2, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeakerFlourishPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ChapterEndFooter extends StatelessWidget {
  final int chapterNumber;
  final String chapterName;
  final String script;
  final double fontSize;

  const _ChapterEndFooter({
    required this.chapterNumber,
    required this.chapterName,
    required this.script,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final localNum = StaticData.localizeNumber(chapterNumber, script);

    String colophonText;
    if (script == 'dev' || script == 'hi' || script == 'mr') {
      colophonText =
          "ॐ तत्सदिति श्रीमद्भगवद्गीतासूपनिषत्सु\nब्रह्मविद्यायां योगशास्त्रे श्रीकृष्णार्जुनसंवादे\n$chapterName नाम अध्यायः $localNum ॥";
    } else {
      colophonText =
          "${StaticData.getChapterLabel(script)} $localNum: $chapterName\n(End of Chapter)";
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 56, 24),
      child: Text(
        colophonText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'NotoSerif',
          fontSize: fontSize * 0.72,
          color: Theme.of(context).colorScheme.primary,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
      ),
    );
  }
}
