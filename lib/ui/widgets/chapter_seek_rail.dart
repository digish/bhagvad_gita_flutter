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

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../theme/app_colors.dart';

/// Slim vertical chapter seek control: track, chapter dots, and a draggable thumb.
class ChapterSeekRail extends StatefulWidget {
  static const double width = 28.0;

  final int itemCount;
  final List<int> chapterMarkers;
  final ItemPositionsListener itemPositionsListener;
  final ValueChanged<int> onChapterTap;
  final ValueChanged<int> onSeekToIndex;

  const ChapterSeekRail({
    super.key,
    required this.itemCount,
    required this.chapterMarkers,
    required this.itemPositionsListener,
    required this.onChapterTap,
    required this.onSeekToIndex,
  });

  @override
  State<ChapterSeekRail> createState() => _ChapterSeekRailState();
}

class _ChapterSeekRailState extends State<ChapterSeekRail> {
  static const double _verticalPadding = 12.0;
  static const double _thumbRadius = 8.0;
  static const double _dotRadius = 3.5;
  static const double _activeDotRadius = 5.0;

  double _scrollRatio = 0.0;
  bool _isDragging = false;
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
    widget.itemPositionsListener.itemPositions.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_isDragging || !mounted) return;
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || widget.itemCount <= 1) return;

    // Prefer the deepest item in the upper reading band. Using the absolute
    // topmost index leaves the filled chapter dot one behind after jumps
    // (previous chapter footer/title still sits above the new chapter).
    const upperBand = 0.42;
    final inBand = positions.where(
      (p) => p.itemLeadingEdge <= upperBand && p.itemTrailingEdge > 0.02,
    );
    final focusItem = inBand.isNotEmpty
        ? inBand.reduce((a, b) => a.index >= b.index ? a : b)
        : positions.reduce((a, b) {
            const focusLine = 0.22;
            final aDist = (a.itemLeadingEdge - focusLine).abs();
            final bDist = (b.itemLeadingEdge - focusLine).abs();
            return aDist <= bDist ? a : b;
          });

    final ratio = focusItem.index / (widget.itemCount - 1);
    final chapter = _currentChapterForIndex(focusItem.index);

    setState(() {
      _scrollRatio = ratio.clamp(0.0, 1.0);
      // Hold the tapped chapter until scroll actually reaches it (or past it).
      if (_pendingChapterIndex != null && chapter >= _pendingChapterIndex!) {
        _pendingChapterIndex = null;
      }
    });
  }

  int get _currentChapterIndex {
    if (_pendingChapterIndex != null) return _pendingChapterIndex!;
    if (widget.chapterMarkers.isEmpty) return 0;
    final itemIndex = (_scrollRatio * (widget.itemCount - 1)).round();
    return _currentChapterForIndex(itemIndex);
  }

  double _yForRatio(double ratio, double height) {
    final drawable = height - 2 * _verticalPadding;
    return _verticalPadding + ratio.clamp(0.0, 1.0) * drawable;
  }

  double _ratioForY(double y, double height) {
    final drawable = height - 2 * _verticalPadding;
    if (drawable <= 0) return 0;
    return ((y - _verticalPadding) / drawable).clamp(0.0, 1.0);
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
      final markerRatio =
          widget.chapterMarkers[i] / (widget.itemCount - 1);
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
      _dragChapterIndex = chapter;
    });

    if (commit) {
      if (index != _lastSeekIndex) {
        _lastSeekIndex = index;
        widget.onSeekToIndex(index);
      }
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
    final accent =
        appColors?.gitaBlue ?? const Color(0xFF047BC0);
    final trackColor = isLight
        ? accent.withValues(alpha: 0.28)
        : (appColors?.highlightColor ?? const Color(0xFFFFD700)).withValues(
            alpha: 0.35,
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
          final activeChapter = _isDragging
              ? (_dragChapterIndex ?? _currentChapterIndex)
              : _currentChapterIndex;

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
                  _pendingChapterIndex = chapter;
                  _lastSeekIndex = markerIndex;
                });
                widget.onChapterTap(chapter);
                return;
              }
              _applySeek(details.localPosition.dy, height, commit: true);
            },
            onVerticalDragStart: (details) {
              setState(() {
                _isDragging = true;
                _lastHapticChapter = -1;
              });
              _applySeek(details.localPosition.dy, height, commit: true);
            },
            onVerticalDragUpdate: (details) {
              _applySeek(details.localPosition.dy, height, commit: true);
            },
            onVerticalDragEnd: (_) {
              setState(() {
                _isDragging = false;
                _dragChapterIndex = null;
              });
            },
            onVerticalDragCancel: () {
              setState(() {
                _isDragging = false;
                _dragChapterIndex = null;
              });
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Track
                Positioned(
                  left: ChapterSeekRail.width / 2 - 1,
                  top: _verticalPadding,
                  bottom: _verticalPadding,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: trackColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // Chapter dots
                if (widget.itemCount > 1)
                  for (var i = 0; i < widget.chapterMarkers.length; i++)
                    Positioned(
                      left: ChapterSeekRail.width / 2 -
                          (i == activeChapter
                              ? _activeDotRadius
                              : _dotRadius),
                      top: _yForRatio(
                            widget.chapterMarkers[i] /
                                (widget.itemCount - 1),
                            height,
                          ) -
                          (i == activeChapter
                              ? _activeDotRadius
                              : _dotRadius),
                      child: Container(
                        width: (i == activeChapter
                                ? _activeDotRadius
                                : _dotRadius) *
                            2,
                        height: (i == activeChapter
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
                // Thumb
                Positioned(
                  left: ChapterSeekRail.width / 2 - _thumbRadius,
                  top: thumbY - _thumbRadius,
                  child: _SeekThumb(
                    radius: _thumbRadius,
                    accent: activeDot,
                    isLight: isLight,
                  ),
                ),
                // Chapter label while dragging
                if (_isDragging && _dragChapterIndex != null)
                  Positioned(
                    right: ChapterSeekRail.width + 4,
                    top: thumbY - 14,
                    child: _ChapterLabelBubble(
                      chapterNumber: _dragChapterIndex! + 1,
                      accent: activeDot,
                      isLight: isLight,
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

class _SeekThumb extends StatelessWidget {
  final double radius;
  final Color accent;
  final bool isLight;

  const _SeekThumb({
    required this.radius,
    required this.accent,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isLight
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.65),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ChapterLabelBubble extends StatelessWidget {
  final int chapterNumber;
  final Color accent;
  final bool isLight;

  const _ChapterLabelBubble({
    required this.chapterNumber,
    required this.accent,
    required this.isLight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.92)
              : Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '$chapterNumber',
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
