/*
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*/

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chapter_seek_rail.dart';

/// SharedPreferences key — guide seen or skipped.
const String kParayanHelpGuideDoneKey = 'parayan_help_guide_done';

/// Spotlight coach for the Parayan screen.
class ParayanHelpGuide {
  ParayanHelpGuide._();

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kParayanHelpGuideDoneKey) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kParayanHelpGuideDoneKey, true);
  }
}

/// Live widget bounds in **global** coordinates — measured by Parayan, not guessed.
class ParayanHelpTargets {
  /// Round chapter glass on the seek rail.
  final Rect? glass;
  /// Full seek-rail column (for shloka-number lane alignment).
  final Rect? seekRail;
  /// Selected verse card (tap / controls steps).
  final Rect? verse;
  /// Action island above the selected verse.
  final Rect? actionIsland;
  /// Whole bottom-left font dock.
  final Rect? fontDock;
  /// Center of − / size / + cluster.
  final Offset? fontSizeCenter;
  /// Center of Shloka / Anvay / Tika toggle.
  final Offset? fontViewCenter;

  const ParayanHelpTargets({
    this.glass,
    this.seekRail,
    this.verse,
    this.actionIsland,
    this.fontDock,
    this.fontSizeCenter,
    this.fontViewCenter,
  });

  static const empty = ParayanHelpTargets();

  ParayanHelpTargets copyWith({
    Rect? glass,
    Rect? seekRail,
    Rect? verse,
    Rect? actionIsland,
    Rect? fontDock,
    Offset? fontSizeCenter,
    Offset? fontViewCenter,
  }) {
    return ParayanHelpTargets(
      glass: glass ?? this.glass,
      seekRail: seekRail ?? this.seekRail,
      verse: verse ?? this.verse,
      actionIsland: actionIsland ?? this.actionIsland,
      fontDock: fontDock ?? this.fontDock,
      fontSizeCenter: fontSizeCenter ?? this.fontSizeCenter,
      fontViewCenter: fontViewCenter ?? this.fontViewCenter,
    );
  }
}

/// Full-screen overlay; parent shows this when help should run.
///
/// Pass [targets] with live measured rects so spotlights and labels track
/// real UI on any screen size.
class ParayanHelpGuideOverlay extends StatefulWidget {
  final VoidCallback onFinished;
  final double focusLine;
  final double chromeHeight;
  final ParayanHelpTargets targets;
  final ValueChanged<int>? onStepIndex;

  const ParayanHelpGuideOverlay({
    super.key,
    required this.onFinished,
    this.focusLine = 0.40,
    required this.chromeHeight,
    this.targets = ParayanHelpTargets.empty,
    this.onStepIndex,
  });

  @override
  State<ParayanHelpGuideOverlay> createState() =>
      _ParayanHelpGuideOverlayState();
}

enum _HelpStep { overview, seek, tap, controls, font, done }

class _ParayanHelpGuideOverlayState extends State<ParayanHelpGuideOverlay>
    with SingleTickerProviderStateMixin {
  _HelpStep _step = _HelpStep.overview;

  static const int _stepCount = 5;
  static const Color _gold = Color(0xFFFFD700);
  static const double _labelAboveH = 42;
  static const double _labelSideW = 120;

  late final AnimationController _tapPulse;

  @override
  void initState() {
    super.initState();
    _tapPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onStepIndex?.call(0);
    });
  }

  @override
  void dispose() {
    _tapPulse.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ParayanHelpGuide.markDone();
    if (mounted) widget.onFinished();
  }

  void _next() {
    setState(() {
      _step = switch (_step) {
        _HelpStep.overview => _HelpStep.seek,
        _HelpStep.seek => _HelpStep.tap,
        _HelpStep.tap => _HelpStep.controls,
        _HelpStep.controls => _HelpStep.font,
        _HelpStep.font => _HelpStep.done,
        _HelpStep.done => _HelpStep.done,
      };
    });
    if (_step == _HelpStep.done) {
      _finish();
      return;
    }
    widget.onStepIndex?.call(_stepIndex);
  }

  /// Global → this overlay's local coordinates.
  Rect? _localRect(Rect? global) {
    if (global == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    final tl = box.globalToLocal(global.topLeft);
    return Rect.fromLTWH(tl.dx, tl.dy, global.width, global.height);
  }

  Offset? _localOffset(Offset? global) {
    if (global == null) return null;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final isLight = Theme.of(context).brightness == Brightness.light;

    final spotlights = _spotlightRects(size, pad);
    final primaryHole = spotlights.isEmpty ? null : spotlights.first;
    final card = _cardPlacement(size, pad, primaryHole);
    final callouts = _callouts(size, pad);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                holes: [
                  for (final hole in spotlights)
                    (
                      hole,
                      hole.height > hole.width * 2 ? 14.0 : _cornerRadius,
                    ),
                ],
                scrim: Colors.black.withValues(
                  alpha: _step == _HelpStep.overview ? 0.48 : 0.72,
                ),
              ),
            ),
          ),
          if (_step != _HelpStep.overview)
            for (final hole in spotlights)
              Positioned.fromRect(
                rect: hole.inflate(3),
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        hole.height > hole.width * 2 ? 14 : _cornerRadius + 2,
                      ),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.9),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
          if (_step == _HelpStep.tap && primaryHole != null)
            Positioned(
              left: primaryHole.center.dx - 36,
              top: primaryHole.center.dy - 20,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _tapPulse,
                  builder: (context, _) =>
                      _TapGestureHint(progress: _tapPulse.value),
                ),
              ),
            ),
          for (final c in callouts)
            Positioned(
              left: c.left,
              top: c.top,
              child: IgnorePointer(child: c.child),
            ),
          Positioned(
            left: card.left,
            right: card.right,
            top: card.top,
            child: _HelpTipCard(
              isLight: isLight,
              title: _title,
              body: _body,
              footer: _step == _HelpStep.font
                  ? 'Open this help anytime in Settings.'
                  : null,
              stepIndex: _stepIndex,
              stepCount: _stepCount,
              onNext: _next,
              onSkip: _finish,
              nextLabel: _step == _HelpStep.font ? 'Done' : 'Next',
            ),
          ),
        ],
      ),
    );
  }

  double get _cornerRadius => switch (_step) {
        _HelpStep.overview => 28,
        _HelpStep.seek => 32,
        _HelpStep.tap => 14,
        _HelpStep.controls => 14,
        _HelpStep.font => 22,
        _HelpStep.done => 16,
      };

  int get _stepIndex => switch (_step) {
        _HelpStep.overview => 0,
        _HelpStep.seek => 1,
        _HelpStep.tap => 2,
        _HelpStep.controls => 3,
        _HelpStep.font => 4,
        _HelpStep.done => 4,
      };

  String get _title => switch (_step) {
        _HelpStep.overview => 'Continuous reading',
        _HelpStep.seek => 'Jump in the book',
        _HelpStep.tap => 'Tap a verse',
        _HelpStep.controls => 'Verse buttons',
        _HelpStep.font => 'Size & view',
        _HelpStep.done => '',
      };

  String get _body => switch (_step) {
        _HelpStep.overview =>
          'Continuous reading of the Gita — verses flow one after another.\n\n'
              'Next steps show how to jump, tap, use buttons, and adjust text.',
        _HelpStep.seek =>
          'Drag the round glass up or down to jump.\n\n'
              '• Number in the glass = chapter\n'
              '• Tall column of faint numbers = shloka\n'
              '• Blue dots on the line = chapter starts',
        _HelpStep.tap =>
          'Tap any verse to select it.\n\n'
              'Buttons will appear above that verse.',
        _HelpStep.controls =>
          'After you tap a verse:\n\n'
              '• Play — listen\n'
              '• Book — commentary\n'
              '• Bookmark — save\n'
              '• Expand — show meaning\n'
              '• Share — send to others',
        _HelpStep.font =>
          'Size (− / +): make verses easier to read.\n\n'
              'Count (1 / 2 / 3): how many parts to show.\n\n'
              'View control: choose what you want to see — shloka, anvay, or tika.',
        _HelpStep.done => '',
      };

  Rect _fallbackGlass(Size size, EdgeInsets pad) {
    return Rect.fromCircle(
      center: Offset(
        size.width -
            pad.right -
            ChapterSeekRail.width +
            ChapterSeekRail.glassRadius +
            2,
        size.height * widget.focusLine,
      ),
      radius: ChapterSeekRail.glassRadius + 8,
    );
  }

  /// Shloka-number column aligned to the live glass X.
  Rect _shlokaColumn(Size size, EdgeInsets pad, Rect glass) {
    final rail = _localRect(widget.targets.seekRail);
    final left = rail?.left ?? (glass.center.dx - ChapterSeekRail.glassRadius);
    final right = glass.center.dx + ChapterSeekRail.glassRadius + 4;
    return Rect.fromLTRB(
      left,
      widget.chromeHeight + 6,
      right.clamp(left + 24, size.width - pad.right),
      size.height - pad.bottom - 72,
    );
  }

  Rect _fallbackVerse(Size size, EdgeInsets pad) {
    final cy = size.height * widget.focusLine;
    final railLeft = size.width - pad.right - ChapterSeekRail.width;
    return Rect.fromLTRB(
      pad.left + 4,
      cy - 85,
      railLeft + ChapterSeekRail.glassRadius * 2 + 4,
      cy + 85,
    );
  }

  List<Rect> _spotlightRects(Size size, EdgeInsets pad) {
    final t = widget.targets;
    switch (_step) {
      case _HelpStep.overview:
        return const [];
      case _HelpStep.seek:
        final glass =
            _localRect(t.glass)?.inflate(8) ?? _fallbackGlass(size, pad);
        return [glass, _shlokaColumn(size, pad, glass)];
      case _HelpStep.tap:
        final verse = _localRect(t.verse)?.inflate(6);
        return [verse ?? _fallbackVerse(size, pad)];
      case _HelpStep.controls:
        final verse = _localRect(t.verse);
        final island = _localRect(t.actionIsland);
        if (verse != null && island != null) {
          return [
            Rect.fromLTRB(
              math.min(verse.left, island.left) - 4,
              island.top - 6,
              math.max(verse.right, island.right) + 4,
              verse.bottom + 6,
            ),
          ];
        }
        if (verse != null) return [verse.inflate(8)];
        return [_fallbackVerse(size, pad).inflate(40)];
      case _HelpStep.font:
        final dock = _localRect(t.fontDock);
        if (dock != null) return [dock.inflate(6)];
        return [
          Rect.fromLTWH(
            pad.left,
            size.height - pad.bottom - 62,
            220,
            50,
          ),
        ];
      case _HelpStep.done:
        return const [];
    }
  }

  List<_Callout> _callouts(Size size, EdgeInsets pad) {
    final t = widget.targets;
    switch (_step) {
      case _HelpStep.overview:
        return const [];
      case _HelpStep.seek:
        final glass =
            _localRect(t.glass)?.inflate(8) ?? _fallbackGlass(size, pad);
        final shloka = _shlokaColumn(size, pad, glass);
        return [
          _calloutPointingRight(
            to: glass.center,
            label: 'Chapter',
          ),
          _calloutPointingRight(
            to: Offset(shloka.left + 8, shloka.top + 40),
            label: 'Shloka',
          ),
        ];
      case _HelpStep.font:
        final dock = _localRect(t.fontDock);
        final sizeC = _localOffset(t.fontSizeCenter) ??
            (dock != null
                ? Offset(dock.left + dock.width * 0.35, dock.center.dy)
                : null);
        final viewC = _localOffset(t.fontViewCenter) ??
            (dock != null
                ? Offset(dock.left + dock.width * 0.82, dock.center.dy)
                : null);
        final out = <_Callout>[];
        if (sizeC != null) {
          out.add(_calloutPointingDown(to: sizeC, label: 'Size'));
        }
        if (viewC != null) {
          out.add(_calloutPointingDown(to: viewC, label: 'View'));
        }
        return out;
      case _HelpStep.tap:
      case _HelpStep.controls:
      case _HelpStep.done:
        return const [];
    }
  }

  _Callout _calloutPointingRight({
    required Offset to,
    required String label,
  }) {
    return _Callout(
      left: to.dx - _labelSideW,
      top: to.dy - 16,
      child: _LabeledArrow(label: label, pointRight: true),
    );
  }

  _Callout _calloutPointingDown({
    required Offset to,
    required String label,
  }) {
    // Badge ~56 wide; chevron centered under it → tip at badge center + ~16.
    const badgeW = 56.0;
    return _Callout(
      left: to.dx - badgeW / 2,
      top: to.dy - _labelAboveH - 6,
      child: _LabeledArrow(label: label, pointRight: false),
    );
  }

  _CardPlacement _cardPlacement(Size size, EdgeInsets pad, Rect? hole) {
    switch (_step) {
      case _HelpStep.overview:
        return _CardPlacement(
          left: 22 + pad.left,
          right: 22 + pad.right,
          top: size.height * 0.32,
        );
      case _HelpStep.seek:
        final glassBottom =
            _localRect(widget.targets.glass)?.bottom ?? (size.height * 0.5);
        final tipTop = glassBottom + 20;
        return _CardPlacement(
          left: 20 + pad.left,
          right: ChapterSeekRail.width + 8,
          top: tipTop.clamp(widget.chromeHeight + 8, size.height - 320),
        );
      case _HelpStep.tap:
        final tipTop = (hole?.bottom ?? size.height * 0.55) + 10;
        return _CardPlacement(
          left: 16 + pad.left,
          right: 16 + pad.right,
          top: tipTop.clamp(widget.chromeHeight + 8, size.height - 300),
        );
      case _HelpStep.controls:
        final tipTop = (hole?.bottom ?? size.height * 0.55) + 8;
        return _CardPlacement(
          left: 16 + pad.left,
          right: 16 + pad.right,
          top: tipTop.clamp(widget.chromeHeight + 8, size.height - 360),
        );
      case _HelpStep.font:
        final dockTop = _localRect(widget.targets.fontDock)?.top;
        final tipBottom = (dockTop ?? size.height - 80) - 16;
        final tipTop = (tipBottom - 320).clamp(
          widget.chromeHeight + 24.0,
          size.height * 0.35,
        );
        return _CardPlacement(
          left: 22 + pad.left,
          right: 22 + pad.right,
          top: tipTop,
        );
      case _HelpStep.done:
        return const _CardPlacement(left: 20, right: 20, top: 100);
    }
  }
}

class _Callout {
  final double left;
  final double top;
  final Widget child;

  const _Callout({
    required this.left,
    required this.top,
    required this.child,
  });
}

/// Pulsing finger + ripple to show “tap here”.
class _TapGestureHint extends StatelessWidget {
  final double progress;

  const _TapGestureHint({required this.progress});

  @override
  Widget build(BuildContext context) {
    final press = progress < 0.45
        ? (progress / 0.45)
        : (1 - (progress - 0.45) / 0.55).clamp(0.0, 1.0);
    final ripple = progress < 0.35 ? 0.0 : ((progress - 0.35) / 0.65);
    final scale = 1.0 - press * 0.12;

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(72, 72),
            painter: _RipplePainter(
              progress: ripple,
              color: const Color(0xFFFFD700),
            ),
          ),
          Transform.scale(
            scale: scale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.touch_app_rounded,
                color: Color(0xFFFFD700),
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RipplePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.shortestSide * 0.48;
    final r = maxR * (0.35 + progress * 0.65);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = color.withValues(alpha: (1 - progress) * 0.85);
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(
      center,
      r * 0.72,
      paint..color = color.withValues(alpha: (1 - progress) * 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _LabeledArrow extends StatelessWidget {
  final String label;
  final bool pointRight;

  const _LabeledArrow({
    required this.label,
    required this.pointRight,
  });

  @override
  Widget build(BuildContext context) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD700), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFD700),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
      ),
    );

    if (!pointRight) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(height: 2),
          const CustomPaint(
            size: Size(18, 16),
            painter: _ChevronPainter(down: true),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 4),
        const CustomPaint(
          size: Size(22, 14),
          painter: _ChevronPainter(down: false),
        ),
      ],
    );
  }
}

class _ChevronPainter extends CustomPainter {
  final bool down;

  const _ChevronPainter({required this.down});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (down) {
      path
        ..moveTo(size.width * 0.5, 1)
        ..lineTo(size.width * 0.5, size.height - 2)
        ..moveTo(size.width * 0.2, size.height * 0.45)
        ..lineTo(size.width * 0.5, size.height - 2)
        ..lineTo(size.width * 0.8, size.height * 0.45);
    } else {
      path
        ..moveTo(1, size.height * 0.5)
        ..lineTo(size.width - 2, size.height * 0.5)
        ..moveTo(size.width * 0.55, size.height * 0.15)
        ..lineTo(size.width - 2, size.height * 0.5)
        ..lineTo(size.width * 0.55, size.height * 0.85);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChevronPainter oldDelegate) =>
      oldDelegate.down != down;
}

class _CardPlacement {
  final double left;
  final double right;
  final double top;

  const _CardPlacement({
    required this.left,
    required this.right,
    required this.top,
  });
}

class _HelpTipCard extends StatelessWidget {
  final bool isLight;
  final String title;
  final String body;
  final String? footer;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;

  const _HelpTipCard({
    required this.isLight,
    required this.title,
    required this.body,
    this.footer,
    required this.stepIndex,
    required this.stepCount,
    required this.onNext,
    required this.onSkip,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isLight
                ? Colors.white.withValues(alpha: 0.94)
                : Colors.black.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFFD700).withValues(alpha: 0.55),
              width: 1.4,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Help  ${stepIndex + 1}/$stepCount',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLight ? Colors.black54 : Colors.white60,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          color: isLight ? Colors.black54 : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: isLight ? Colors.black87 : Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    color: isLight
                        ? Colors.black.withValues(alpha: 0.82)
                        : Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (footer != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    footer!,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      color: isLight
                          ? const Color(0xFF8B6914)
                          : const Color(0xFFFFD700),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF047BC0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(nextLabel),
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

class _SpotlightPainter extends CustomPainter {
  final List<(Rect, double)> holes;
  final Color scrim;

  _SpotlightPainter({
    required this.holes,
    required this.scrim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var dimmed = Path()..addRect(Offset.zero & size);
    for (final (hole, radius) in holes) {
      final cut = Path()
        ..addRRect(
          RRect.fromRectAndRadius(hole, Radius.circular(radius)),
        );
      dimmed = Path.combine(PathOperation.difference, dimmed, cut);
    }
    canvas.drawPath(dimmed, Paint()..color = scrim);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) =>
      oldDelegate.scrim != scrim ||
      oldDelegate.holes.length != holes.length ||
      !_sameHoles(oldDelegate.holes, holes);

  static bool _sameHoles(List<(Rect, double)> a, List<(Rect, double)> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].$1 != b[i].$1 || a[i].$2 != b[i].$2) return false;
    }
    return true;
  }
}
