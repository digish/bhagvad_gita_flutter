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
import '../../providers/audio_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/static_data.dart';

import '../../providers/parayan_provider.dart';
import '../../models/shloka_result.dart';
import '../widgets/chapter_seek_rail.dart';
import '../widgets/parayan_action_island.dart';
import '../widgets/onboarding_bubble.dart';
import '../widgets/reminder_pitch.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/reading_mode_font_dock.dart';
import '../theme/app_colors.dart';

/// Compact top chrome below the status bar (back + optional sticky speaker).
const double _kParayanChromeExtra = 48.0;

/// Left inset so sticky speaker emblem/name clears the overlaid back button.
/// Keep in sync with inline [_SpeakerHeader] padding for vertical alignment.
const double _kParayanSpeakerBackClearance = 56.0;

/// Phone chrome shows a back button; iPad/rail layouts do not.
bool _parayanShowsBackButton(BuildContext context) =>
    MediaQuery.sizeOf(context).width <= 600;

/// Emblem/name inset: clear the back button on phones, sit on the left wall
/// (same as the font-size dock) when the rail is the left edge.
double _parayanSpeakerLeadingInset(BuildContext context) =>
    _parayanShowsBackButton(context) ? _kParayanSpeakerBackClearance : 12.0;

/// Right inset used where chrome must clear the floating [ChapterSeekRail]
/// (header / action island). The shloka list itself stays full-width.
const double _kParayanRailInset = 72.0;

/// Viewport fraction for the reading focus line (cursor / card center target).
const double _kParayanFocusLine = 0.40;

/// Leading list item (blue lotus) so shloka 0 can scroll to the focus line.
const int _kParayanLeadingLotusItems = 1;

/// Must match home [DecorativeForeground] blue lotus Hero.
const String _kParayanBlueLotusHero = 'blueLotusHero';

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
const double _kParayanChapterTitlePx = 72.0;
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
  /// When true (Settings → Help), replay floating onboarding tips.
  final bool showHelp;

  const ParayanScreen({super.key, this.showHelp = false});

  @override
  State<ParayanScreen> createState() => _ParayanScreenState();
}

class _ParayanScreenState extends State<ParayanScreen> {
  // ✨ FIX: Revert to ItemScrollController and ItemPositionsListener for accuracy.
  ItemScrollController _itemScrollController = ItemScrollController();
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

  /// How many of shloka / anvay / translation each verse shows.
  ParayanLayoutCount _layoutCount = ParayanLayoutCount.one;

  /// Pair shown when [_layoutCount] is two.
  ContinuousListPair _listPairMode = ContinuousListPair.shlokaAnvay;

  /// Remount token so height-changing view modes don't correct a stale offset.
  int _listRebuildToken = 0;
  int _listInitialIndex = 0;
  double _listInitialAlignment = _kParayanFocusLine - 0.09;

  /// Font-size dock: expanded when idle, tucks into the left wall while scrolling.
  bool _fontDockExpanded = true;
  Timer? _fontDockRevealTimer;
  Timer? _fontDockTuckTimer;
  int? _fontDockLastIndex;
  double? _fontDockLastLead;
  /// Ignore layout-driven position noise while changing font size.
  bool _suppressFontDockScroll = false;
  DateTime? _fontDockScrollStartedAt;

  final GlobalKey _seekGlassKey = GlobalKey(debugLabel: 'parayanSeekGlass');
  final GlobalKey _fontDockKey = GlobalKey(debugLabel: 'parayanFontDock');
  final GlobalKey _verseTapTargetKey = GlobalKey(debugLabel: 'parayanVerseTap');
  int? _helpVerseListIndex;

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

  @override
  void initState() {
    super.initState();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _audioProvider?.addListener(_handleAudioChange);
    _itemPositionsListener.itemPositions.addListener(_onParayanScrollForFontDock);
    _itemPositionsListener.itemPositions.addListener(_syncHelpVerseAnchor);
    if (widget.showHelp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _replayParayanOnboardingHints();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        ReminderPitch.maybeShow(context, blocked: _parayanHintsVisible());
      });
    });
  }

  @override
  void didUpdateWidget(covariant ParayanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showHelp && !oldWidget.showHelp) {
      _replayParayanOnboardingHints();
    }
  }

  Future<void> _replayParayanOnboardingHints() async {
    if (!mounted) return;
    await Provider.of<SettingsProvider>(context, listen: false)
        .resetParayanOnboardingHints();
  }

  bool _parayanHintsVisible() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return !settings.hasUsedParayanSeekHint ||
        !settings.hasUsedParayanTapHint ||
        !settings.hasUsedParayanFontHint;
  }

  @override
  void dispose() {
    _fontDockRevealTimer?.cancel();
    _fontDockTuckTimer?.cancel();
    _itemPositionsListener.itemPositions.removeListener(
      _onParayanScrollForFontDock,
    );
    _itemPositionsListener.itemPositions.removeListener(_syncHelpVerseAnchor);
    _currentPositionLabelNotifier.dispose(); // ✨ Add this line
    _audioProvider?.removeListener(_handleAudioChange);
    super.dispose();
  }

  void _syncHelpVerseAnchor() {
    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (settings.hasUsedParayanTapHint) return;
    final next = _listIndexNearestFocusLine(
      _itemPositionsListener.itemPositions.value,
    );
    if (next != _helpVerseListIndex) {
      setState(() => _helpVerseListIndex = next);
    }
  }

  /// List index (incl. leading lotus rows) whose center is nearest the focus line.
  int? _listIndexNearestFocusLine(Iterable<ItemPosition> positions) {
    ItemPosition? best;
    var bestDist = double.infinity;
    for (final p in positions) {
      if (p.index < _kParayanLeadingLotusItems) continue;
      final center = (p.itemLeadingEdge + p.itemTrailingEdge) / 2;
      final dist = (center - _kParayanFocusLine).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = p;
      }
    }
    return best?.index;
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
    final keepIndex = _beginDockLayoutChange();
    await settings.setFontSize(newSize);
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
    }
    await _repinFocusAfterLayoutChange(keepIndex);
  }

  Future<void> _onToggleLayoutCount() async {
    final keepIndex = _beginDockLayoutChange();
    setState(() {
      _layoutCount = switch (_layoutCount) {
        ParayanLayoutCount.one => ParayanLayoutCount.two,
        ParayanLayoutCount.two => ParayanLayoutCount.three,
        ParayanLayoutCount.three => ParayanLayoutCount.one,
      };
      _rebuildListPinnedTo(keepIndex);
    });
    await _settleAfterListRemount();
  }

  Future<void> _onToggleListContent() async {
    if (_layoutCount == ParayanLayoutCount.three) return;
    final keepIndex = _beginDockLayoutChange();
    setState(() {
      if (_layoutCount == ParayanLayoutCount.one) {
        _listBodyMode = switch (_listBodyMode) {
          ContinuousListBody.shloka => ContinuousListBody.anvay,
          ContinuousListBody.anvay => ContinuousListBody.translation,
          ContinuousListBody.translation => ContinuousListBody.shloka,
        };
      } else {
        _listPairMode = switch (_listPairMode) {
          ContinuousListPair.shlokaAnvay =>
            ContinuousListPair.shlokaTranslation,
          ContinuousListPair.shlokaTranslation =>
            ContinuousListPair.anvayTranslation,
          ContinuousListPair.anvayTranslation =>
            ContinuousListPair.shlokaAnvay,
        };
      }
      _rebuildListPinnedTo(keepIndex);
    });
    await _settleAfterListRemount();
  }

  /// Drop the old list (stale item extents) and open a fresh one on [shlokaIndex].
  void _rebuildListPinnedTo(int shlokaIndex) {
    _listRebuildToken++;
    _listInitialIndex = _listIndexForShloka(shlokaIndex);
    _listInitialAlignment = (_kParayanFocusLine - 0.09).clamp(0.0, 1.0);
    _itemScrollController = ItemScrollController();
  }

  Future<void> _settleAfterListRemount() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
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
  }

  int _beginDockLayoutChange() {
    final keepIndex = _selectedIndex ?? _indexNearestFocusLine();
    _suppressFontDockScroll = true;
    _fontDockRevealTimer?.cancel();
    _fontDockTuckTimer?.cancel();
    _fontDockTuckTimer = null;
    _fontDockScrollStartedAt = null;
    if (!_fontDockExpanded && mounted) {
      setState(() => _fontDockExpanded = true);
    }
    return keepIndex;
  }

  Future<void> _repinFocusAfterLayoutChange(int keepIndex) async {
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
    }

    // Two frames so new item heights exist; one jump (no refine) avoids
    // UnboundedViewport layout-cycle crashes on large lists.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
    }
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      _suppressFontDockScroll = false;
      return;
    }
    if (_itemScrollController.isAttached) {
      final listIndex = _listIndexForShloka(keepIndex);
      final alignment = _alignmentForCardCenter(keepIndex, requireVisible: true) ??
          (_kParayanFocusLine - 0.09).clamp(0.0, 1.0);
      _itemScrollController.jumpTo(index: listIndex, alignment: alignment);
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
    // Align the target shloka to the same 40% focus line the glass tracks.
    _scrollCardCenterToFocusLine(shlokaIndex);
  }

  /// Instant seek used while dragging the glass — keep center on the focus line
  /// so the label and the verse under the cursor stay in sync.
  void _jumpToIndex(int shlokaIndex) {
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
                  key: ValueKey('parayan_list_$_listRebuildToken'),
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  itemCount: listItemCount,
                  initialScrollIndex: _listInitialIndex.clamp(
                    0,
                    listItemCount > 0 ? listItemCount - 1 : 0,
                  ),
                  initialAlignment: _listInitialAlignment,
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
                            chapterNumber:
                                int.tryParse(shloka.chapterNo) ?? 0,
                            script: script,
                            fontSize: settingsProvider.fontSize,
                          ),
                        if (speakerChanged || isChapterStart)
                          _SpeakerHeader(
                            speaker: shloka.speaker ?? "Uvacha",
                            script: script,
                            fontSize: settingsProvider.fontSize,
                          ),
                        KeyedSubtree(
                          key: listIndex == _helpVerseListIndex
                              ? _verseTapTargetKey
                              : null,
                          child: FullShlokaCard(
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
                              layoutCount: _layoutCount,
                              listPairMode: _listPairMode,
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
                      glassKey: _seekGlassKey,
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
                      leadingInset: _parayanSpeakerLeadingInset(context),
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
                            onToggleMeanings:
                                _layoutCount == ParayanLayoutCount.three
                                ? null
                                : () {
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
              final dockBottom =
                  miniPlayerVisible ? 96 + bottomSafe : 12 + bottomSafe;
              return Positioned(
                left: MediaQuery.of(context).padding.left,
                bottom: dockBottom,
                child: KeyedSubtree(
                  key: _fontDockKey,
                  child: ReadingModeFontDock(
                    currentSize: settingsProvider.fontSize,
                    expanded: _fontDockExpanded,
                    onPeekTap: _revealFontDockNow,
                    onSizeChanged: _onFontSizeChanged,
                    listBodyMode: _listBodyMode,
                    layoutCount: _layoutCount,
                    listPairMode: _listPairMode,
                    onToggleListContent: _onToggleListContent,
                    onToggleLayoutCount: _onToggleLayoutCount,
                  ),
                ),
              );
            },
          ),
          if (!settingsProvider.hasUsedParayanSeekHint)
            AnchoredOnboardingBubble(
              targetKey: _seekGlassKey,
              placement: OnboardingBubblePlacement.leftOfTarget,
              repositionListenable: _itemPositionsListener.itemPositions,
              text: 'Jump chapters on the seek rail',
              icon: Icons.swipe_vertical,
              onTap: () => settingsProvider.markParayanSeekHintUsed(),
              onDismiss: () => settingsProvider.markParayanSeekHintUsed(),
            ),
          if (!settingsProvider.hasUsedParayanTapHint)
            AnchoredOnboardingBubble(
              targetKey: _verseTapTargetKey,
              placement: OnboardingBubblePlacement.leftOfTarget,
              repositionListenable: _itemPositionsListener.itemPositions,
              text: 'Tap a verse to select it',
              icon: Icons.touch_app_outlined,
              onTap: () => settingsProvider.markParayanTapHintUsed(),
              onDismiss: () => settingsProvider.markParayanTapHintUsed(),
            ),
          if (!settingsProvider.hasUsedParayanFontHint)
            AnchoredOnboardingBubble(
              targetKey: _fontDockKey,
              placement: OnboardingBubblePlacement.leftOfTarget,
              repositionListenable: _itemPositionsListener.itemPositions,
              text: 'Size & what you read',
              icon: Icons.format_size,
              onTap: () => settingsProvider.markParayanFontHintUsed(),
              onDismiss: () => settingsProvider.markParayanFontHintUsed(),
            ),
        ],
      ),
    );
  }
}

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
      left: false,
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

// --- Reusable private widgets for the list items ---

/// Short left-aligned hairline between continuous shlokas.
class _ParayanVerseRule extends StatelessWidget {
  const _ParayanVerseRule();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 10, 56, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 120,
          height: 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            gradient: LinearGradient(
              colors: [
                (isLight ? const Color(0xFFB8860B) : const Color(0xFFFFD700))
                    .withValues(alpha: isLight ? 0.58 : 0.5),
                (isLight ? const Color(0xFFB8860B) : const Color(0xFFFFD700))
                    .withValues(alpha: isLight ? 0.22 : 0.18),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Deep navy on light lavender; warm gold on dark — both read as a title.
    final titleColor = isLight
        ? const Color(0xFF0B1F4A)
        : const Color(0xFFFFD54F);
    final lineColor = titleColor.withValues(alpha: isLight ? 0.55 : 0.65);
    final titleSize = (fontSize * 1.28).clamp(22.0, 34.0);

    return Padding(
      // Match speaker insets; clear seek-rail glass lane on the right.
      padding: const EdgeInsets.fromLTRB(16, 24, 56, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 16,
              child: Transform.flip(
                flipX: true,
                child: CustomPaint(
                  painter: _SpeakerFlourishPainter(color: lineColor),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: fontSize * 0.4),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.62,
              ),
              child: Text(
                '$chapterLabel $localNum $chapterName',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: 0.8,
                  height: 1.3,
                ),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 16,
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
      left: false,
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
      // Match sticky bar: clear back button on phones; flush to the left
      // wall beside the rail on iPad (same as the font-size dock).
      padding: EdgeInsets.fromLTRB(
        _parayanSpeakerLeadingInset(context),
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
