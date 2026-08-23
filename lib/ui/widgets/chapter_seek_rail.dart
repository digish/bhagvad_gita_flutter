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
*/

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../theme/app_colors.dart';

/// Slim vertical chapter seek control: magnet-bent track, chapter dots,
/// and a movable circular glass showing chapter:shloka in Orbitron.
class ChapterSeekRail extends StatefulWidget {
  static const double width = 72.0;
  static const double glassRadius = 26.0;
  static const double trackInsetRight = 10.0;
  static const double verticalPadding = 20.0;

  final int itemCount;
  final List<int> chapterMarkers;
  final ItemPositionsListener itemPositionsListener;
  final ValueChanged<int> onChapterTap;
  final ValueChanged<int> onSeekToIndex;
  /// Chapter shown inside the glass (Orbitron).
  final String Function(int index) chapterForIndex;
  /// Viewport fraction (from top) that the glass tracks — Parayan focus line.
  final double focusLine;
  /// Live glass circle in global (screen) coordinates — for help spotlights.
  final ValueChanged<Rect>? onGlassRect;
  /// Full seek-rail bounds in global coordinates — for help spotlights.
  final ValueChanged<Rect>? onRailRect;
  /// Help overlay anchor on the movable chapter glass thumb.
  final Key? glassKey;

  const ChapterSeekRail({
    super.key,
    required this.itemCount,
    required this.chapterMarkers,
    required this.itemPositionsListener,
    required this.onChapterTap,
    required this.onSeekToIndex,
    required this.chapterForIndex,
    this.focusLine = 0.40,
    this.onGlassRect,
    this.onRailRect,
    this.glassKey,
  });

  /// Global center of the chapter marker dot for [chapterIndex] (0-based).
  static Offset? chapterDotGlobal({
    required Rect railRect,
    required int chapterIndex,
    required List<int> chapterMarkers,
    required int itemCount,
  }) {
    if (chapterIndex < 0 ||
        chapterIndex >= chapterMarkers.length ||
        itemCount <= 1) {
      return null;
    }
    final drawable = railRect.height - 2 * verticalPadding;
    if (drawable <= 0) return null;
    final ratio =
        (chapterMarkers[chapterIndex] / (itemCount - 1)).clamp(0.0, 1.0);
    final y = railRect.top + verticalPadding + ratio * drawable;
    final x = railRect.right - trackInsetRight;
    return Offset(x, y);
  }

  @override
  State<ChapterSeekRail> createState() => _ChapterSeekRailState();
}

class _ChapterSeekRailState extends State<ChapterSeekRail> {
  static const double _dotRadius = 3.5;
  static const double _activeDotRadius = 5.0;
  static const double _magnetPull = 14.0;
  static const double _bendExtent = 28.0;

  double _scrollRatio = 0.0;
  int _focusIndex = 0;
  bool _isDragging = false;
  /// Finger covers the glass — show chapter above it while interacting.
  bool _showChapterPopup = false;
  Timer? _popupHideTimer;
  /// After a glass seek / chapter tap, hold this index until list focus catches up.
  int? _pendingFocusIndex;
  int? _dragChapterIndex;
  int? _pendingChapterIndex;
  int _lastHapticChapter = -1;
  int _lastSeekIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener.itemPositions.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ChapterSeekRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemPositionsListener != widget.itemPositionsListener) {
      oldWidget.itemPositionsListener.itemPositions.removeListener(_onScroll);
      widget.itemPositionsListener.itemPositions.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _popupHideTimer?.cancel();
    widget.itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  void _hideChapterPopupSoon() {
    _popupHideTimer?.cancel();
    _popupHideTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _isDragging) return;
      setState(() => _showChapterPopup = false);
    });
  }

  /// Shloka whose vertical center is closest to [focusLine] (40% from top).
  ItemPosition? _itemAtFocusLine(Iterable<ItemPosition> positions) {
    if (positions.isEmpty) return null;
    final focusLine = widget.focusLine;
    return positions.reduce((a, b) {
      final aCenter = (a.itemLeadingEdge + a.itemTrailingEdge) / 2;
      final bCenter = (b.itemLeadingEdge + b.itemTrailingEdge) / 2;
      return (aCenter - focusLine).abs() <= (bCenter - focusLine).abs() ? a : b;
    });
  }

  void _onScroll() {
    if (_isDragging || !mounted) return;
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || widget.itemCount <= 1) return;

    final focusItem = _itemAtFocusLine(positions);
    if (focusItem == null) return;

    // While a seek is settling, keep glass on the requested shloka until
    // that item actually becomes the focus-line verse.
    if (_pendingFocusIndex != null) {
      final pending = _pendingFocusIndex!;
      if (focusItem.index == pending) {
        _pendingFocusIndex = null;
      } else {
        final pendingVisible = positions.any((p) => p.index == pending);
        if (pendingVisible) {
          setState(() {
            _focusIndex = pending;
            _scrollRatio = widget.itemCount <= 1
                ? 0.0
                : (pending / (widget.itemCount - 1)).clamp(0.0, 1.0);
          });
          return;
        }
        // Pending target left the viewport — resume normal tracking.
        _pendingFocusIndex = null;
      }
    }

    final ratio = focusItem.index / (widget.itemCount - 1);
    final chapter = _currentChapterForIndex(focusItem.index);

    setState(() {
      _focusIndex = focusItem.index;
      _scrollRatio = ratio.clamp(0.0, 1.0);
      if (_pendingChapterIndex != null && chapter >= _pendingChapterIndex!) {
        _pendingChapterIndex = null;
      }
    });
  }

  int get _currentChapterIndex {
    if (_pendingChapterIndex != null) return _pendingChapterIndex!;
    if (widget.chapterMarkers.isEmpty) return 0;
    return _currentChapterForIndex(_focusIndex);
  }

  double _yForRatio(double ratio, double height) {
    final drawable = height - 2 * ChapterSeekRail.verticalPadding;
    return ChapterSeekRail.verticalPadding + ratio.clamp(0.0, 1.0) * drawable;
  }

  double _ratioForY(double y, double height) {
    final drawable = height - 2 * ChapterSeekRail.verticalPadding;
    if (drawable <= 0) return 0;
    return ((y - ChapterSeekRail.verticalPadding) / drawable).clamp(0.0, 1.0);
  }

  int _indexForRatio(double ratio) {
    if (widget.itemCount <= 1) return 0;
    return (ratio * (widget.itemCount - 1)).round().clamp(
      0,
      widget.itemCount - 1,
    );
  }

  int? _chapterAtY(double y, double height) {
    if (widget.chapterMarkers.isEmpty || widget.itemCount <= 1) return null;
    for (var i = 0; i < widget.chapterMarkers.length; i++) {
      final markerRatio = widget.chapterMarkers[i] / (widget.itemCount - 1);
      final dotY = _yForRatio(markerRatio, height);
      if ((y - dotY).abs() <= 14) return i;
    }
    return null;
  }

  void _applySeek(double y, double height, {required bool commit}) {
    final ratio = _ratioForY(y, height);
    final index = _indexForRatio(ratio);
    final chapter = _currentChapterForIndex(index);

    if (chapter != _lastHapticChapter) {
      _lastHapticChapter = chapter;
      HapticFeedback.selectionClick();
    }

    setState(() {
      _scrollRatio = ratio;
      _focusIndex = index;
      _dragChapterIndex = chapter;
      _pendingFocusIndex = index;
    });

    if (commit && index != _lastSeekIndex) {
      _lastSeekIndex = index;
      widget.onSeekToIndex(index);
    }
  }

  int _currentChapterForIndex(int itemIndex) {
    if (widget.chapterMarkers.isEmpty) return 0;
    var chapter = 0;
    for (var i = 0; i < widget.chapterMarkers.length; i++) {
      if (widget.chapterMarkers[i] <= itemIndex) {
        chapter = i;
      } else {
        break;
      }
    }
    return chapter;
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    final isLight = Theme.of(context).brightness == Brightness.light;
    final accent = appColors?.gitaBlue ?? const Color(0xFF047BC0);
    final trackColor = isLight
        ? accent.withValues(alpha: 0.35)
        : (appColors?.highlightColor ?? const Color(0xFFFFD700)).withValues(
            alpha: 0.4,
          );
    final inactiveDot = isLight
        ? accent.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.45);
    final activeDot = isLight
        ? accent
        : (appColors?.highlightColor ?? const Color(0xFFFFD700));

    return SizedBox(
      width: ChapterSeekRail.width,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final height = constraints.maxHeight;
          final thumbY = _yForRatio(_scrollRatio, height);
          final trackX = ChapterSeekRail.width - ChapterSeekRail.trackInsetRight;
          final glassCenterX = ChapterSeekRail.glassRadius + 2;
          final activeChapter = _isDragging
              ? (_dragChapterIndex ?? _currentChapterIndex)
              : _currentChapterIndex;
          final safeIndex = _focusIndex.clamp(0, widget.itemCount - 1);
          final chapterLabel = widget.itemCount > 0
              ? widget.chapterForIndex(safeIndex)
              : '1';

          if (widget.onGlassRect != null || widget.onRailRect != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final box = context.findRenderObject() as RenderBox?;
              if (box == null || !box.hasSize) return;
              final origin = box.localToGlobal(Offset.zero);
              final size = box.size;
              widget.onRailRect?.call(origin & size);
              if (widget.onGlassRect != null) {
                final r = ChapterSeekRail.glassRadius;
                widget.onGlassRect!(
                  Rect.fromCircle(
                    center: Offset(
                      origin.dx + glassCenterX,
                      origin.dy + thumbY,
                    ),
                    radius: r,
                  ),
                );
              }
            });
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              final chapter = _chapterAtY(details.localPosition.dy, height);
              if (chapter != null) {
                HapticFeedback.lightImpact();
                final markerIndex = widget.chapterMarkers[chapter];
                final ratio = widget.itemCount <= 1
                    ? 0.0
                    : markerIndex / (widget.itemCount - 1);
                setState(() {
                  _scrollRatio = ratio.clamp(0.0, 1.0);
                  _focusIndex = markerIndex;
                  _pendingFocusIndex = markerIndex;
                  _pendingChapterIndex = chapter;
                  _lastSeekIndex = markerIndex;
                  _showChapterPopup = true;
                });
                widget.onChapterTap(chapter);
                _hideChapterPopupSoon();
                return;
              }
              setState(() => _showChapterPopup = true);
              _applySeek(details.localPosition.dy, height, commit: true);
              _hideChapterPopupSoon();
            },
            onVerticalDragStart: (details) {
              _popupHideTimer?.cancel();
              setState(() {
                _isDragging = true;
                _showChapterPopup = true;
                _lastHapticChapter = -1;
              });
              _applySeek(details.localPosition.dy, height, commit: true);
            },
            onVerticalDragUpdate: (details) {
              _applySeek(details.localPosition.dy, height, commit: true);
            },
            onVerticalDragEnd: (_) {
              // Final settle: ensure list centers the glass's shloka on focus line.
              final index = _focusIndex;
              setState(() {
                _isDragging = false;
                _dragChapterIndex = null;
                _pendingFocusIndex = index;
                _showChapterPopup = true;
              });
              if (index != _lastSeekIndex) {
                _lastSeekIndex = index;
                widget.onSeekToIndex(index);
              } else {
                // Re-jump so alignment is focus-line accurate after drag.
                widget.onSeekToIndex(index);
              }
              _hideChapterPopupSoon();
            },
            onVerticalDragCancel: () {
              setState(() {
                _isDragging = false;
                _dragChapterIndex = null;
              });
              _hideChapterPopupSoon();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Magnet-bent track + connector stem
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MagnetTrackPainter(
                      trackX: trackX,
                      thumbY: thumbY,
                      glassRightX:
                          glassCenterX + ChapterSeekRail.glassRadius - 2,
                      top: ChapterSeekRail.verticalPadding,
                      bottom: height - ChapterSeekRail.verticalPadding,
                      pull: _magnetPull,
                      bendExtent: _bendExtent,
                      color: trackColor,
                      accent: activeDot,
                    ),
                  ),
                ),
                // Chapter dots (no numbers — glass carries chapter)
                if (widget.itemCount > 1)
                  for (var i = 0; i < widget.chapterMarkers.length; i++)
                    Positioned(
                      left:
                          trackX -
                          (i == activeChapter
                              ? _activeDotRadius
                              : _dotRadius),
                      top:
                          _yForRatio(
                            widget.chapterMarkers[i] / (widget.itemCount - 1),
                            height,
                          ) -
                          (i == activeChapter
                              ? _activeDotRadius
                              : _dotRadius),
                      child: Container(
                        width:
                            (i == activeChapter
                                ? _activeDotRadius
                                : _dotRadius) *
                            2,
                        height:
                            (i == activeChapter
                                ? _activeDotRadius
                                : _dotRadius) *
                            2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == activeChapter
                              ? activeDot
                              : Colors.transparent,
                          border: Border.all(
                            color: i == activeChapter
                                ? activeDot
                                : inactiveDot,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                // Chapter popup above glass while finger covers it
                if (_showChapterPopup)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: thumbY - ChapterSeekRail.glassRadius - 48,
                    child: Center(
                      child: _ChapterTouchPopup(
                        chapter: chapterLabel,
                        accent: activeDot,
                        isLight: isLight,
                      ),
                    ),
                  ),
                // Movable circular glass
                Positioned(
                  left: glassCenterX - ChapterSeekRail.glassRadius,
                  top: thumbY - ChapterSeekRail.glassRadius,
                  child: KeyedSubtree(
                    key: widget.glassKey,
                    child: _GlassVerseThumb(
                      chapter: chapterLabel,
                      accent: activeDot,
                      isLight: isLight,
                      radius: ChapterSeekRail.glassRadius,
                      isDragging: _isDragging,
                      showHandle: _showChapterPopup,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MagnetTrackPainter extends CustomPainter {
  final double trackX;
  final double thumbY;
  final double glassRightX;
  final double top;
  final double bottom;
  final double pull;
  final double bendExtent;
  final Color color;
  final Color accent;

  const _MagnetTrackPainter({
    required this.trackX,
    required this.thumbY,
    required this.glassRightX,
    required this.top,
    required this.bottom,
    required this.pull,
    required this.bendExtent,
    required this.color,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final apexX = trackX - pull;
    final apexY = thumbY.clamp(top + 4, bottom - 4);
    final bendTop = (apexY - bendExtent).clamp(top, bottom);
    final bendBottom = (apexY + bendExtent).clamp(top, bottom);

    final trackPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(trackX, top);

    if (bendTop > top + 0.5) {
      path.lineTo(trackX, bendTop);
    }

    // Magnet bulge toward the glass (left)
    path.cubicTo(
      trackX,
      bendTop + (apexY - bendTop) * 0.25,
      apexX,
      apexY - (apexY - bendTop) * 0.35,
      apexX,
      apexY,
    );
    path.cubicTo(
      apexX,
      apexY + (bendBottom - apexY) * 0.35,
      trackX,
      bendBottom - (bendBottom - apexY) * 0.25,
      trackX,
      bendBottom,
    );

    if (bendBottom < bottom - 0.5) {
      path.lineTo(trackX, bottom);
    }

    canvas.drawPath(path, trackPaint);

    // Stem from glass edge to bulge apex
    final stemPaint = Paint()
      ..color = accent.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(glassRightX, apexY),
      Offset(apexX, apexY),
      stemPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MagnetTrackPainter oldDelegate) {
    return oldDelegate.thumbY != thumbY ||
        oldDelegate.trackX != trackX ||
        oldDelegate.glassRightX != glassRightX ||
        oldDelegate.color != color ||
        oldDelegate.accent != accent ||
        oldDelegate.top != top ||
        oldDelegate.bottom != bottom;
  }
}

class _GlassVerseThumb extends StatelessWidget {
  final String chapter;
  final Color accent;
  final bool isLight;
  final double radius;
  final bool isDragging;
  /// When true (finger covering glass), show drawer-handle lines instead of the number.
  final bool showHandle;

  const _GlassVerseThumb({
    required this.chapter,
    required this.accent,
    required this.isLight,
    required this.radius,
    required this.isDragging,
    this.showHandle = false,
  });

  @override
  Widget build(BuildContext context) {
    final chapterColor = isLight ? accent : Colors.white;
    final handleColor = chapterColor.withValues(alpha: 0.9);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDragging ? 0.45 : 0.28),
            blurRadius: isDragging ? 14 : 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLight
                  ? Colors.white.withValues(alpha: 0.55)
                  : Colors.black.withValues(alpha: 0.4),
              border: Border.all(
                color: accent.withValues(alpha: 0.85),
                width: 2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? [
                        Colors.white.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.28),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.18),
                        Colors.black.withValues(alpha: 0.35),
                      ],
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: showHandle
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DrawerHandleLine(color: handleColor),
                      const SizedBox(height: 5),
                      _DrawerHandleLine(color: handleColor),
                    ],
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      chapter,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        height: 1.0,
                        letterSpacing: 0.2,
                        color: chapterColor,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DrawerHandleLine extends StatelessWidget {
  final Color color;

  const _DrawerHandleLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Chapter number shown above the glass while the finger covers it.
class _ChapterTouchPopup extends StatelessWidget {
  final String chapter;
  final Color accent;
  final bool isLight;

  const _ChapterTouchPopup({
    required this.chapter,
    required this.accent,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isLight ? accent : Colors.white;

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.94)
              : Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          chapter,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            height: 1.0,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
