/*
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*/

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared prefs helpers for one-shot spotlight guides.
class SpotlightHelpPrefs {
  SpotlightHelpPrefs._();

  static Future<bool> isDone(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markDone(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}

const String kSearchHelpGuideDoneKey = 'search_help_guide_done';
const String kChapterHelpGuideDoneKey = 'chapter_shloka_help_guide_done';

enum SpotlightArrow { right, left, down, up }

class SpotlightCallout {
  /// Target in **global** (screen) coordinates.
  final Offset globalTarget;
  final String label;
  final SpotlightArrow arrow;

  const SpotlightCallout({
    required this.globalTarget,
    required this.label,
    this.arrow = SpotlightArrow.down,
  });
}

class SpotlightHelpStep {
  final String title;
  final String body;
  /// Holes in **global** coordinates. Empty = overview (dim only).
  final List<Rect> globalHoles;
  final List<SpotlightCallout> callouts;
  final bool showTapHint;
  final double cornerRadius;
  /// Pin the tip card in the vertical/horizontal center (e.g. bottom FAB steps).
  final bool centerTip;

  const SpotlightHelpStep({
    required this.title,
    required this.body,
    this.globalHoles = const [],
    this.callouts = const [],
    this.showTapHint = false,
    this.cornerRadius = 16,
    this.centerTip = false,
  });
}

/// Generic spotlight coach. Parent rebuilds [steps] from live widget bounds.
class SpotlightHelpOverlay extends StatefulWidget {
  final List<SpotlightHelpStep> steps;
  final String prefsKey;
  final VoidCallback onFinished;

  const SpotlightHelpOverlay({
    super.key,
    required this.steps,
    required this.prefsKey,
    required this.onFinished,
  });

  @override
  State<SpotlightHelpOverlay> createState() => _SpotlightHelpOverlayState();
}

class _SpotlightHelpOverlayState extends State<SpotlightHelpOverlay>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  late final AnimationController _tapPulse;

  static const Color _gold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _tapPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _tapPulse.dispose();
    super.dispose();
  }

  SpotlightHelpStep get _step {
    final steps = widget.steps;
    if (steps.isEmpty) {
      return const SpotlightHelpStep(title: '', body: '');
    }
    return steps[_index.clamp(0, steps.length - 1)];
  }

  Future<void> _finish() async {
    // Persist first so a remounted Search screen won't reopen the guide.
    await SpotlightHelpPrefs.markDone(widget.prefsKey);
    // Overlay may outlive the route State when hosted above the rail.
    widget.onFinished();
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      _finish();
      return;
    }
    setState(() => _index += 1);
  }

  Rect _localRect(Rect global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    final tl = box.globalToLocal(global.topLeft);
    return Rect.fromLTWH(tl.dx, tl.dy, global.width, global.height);
  }

  Offset _localOffset(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return global;
    return box.globalToLocal(global);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final step = _step;
    final holes = [for (final h in step.globalHoles) _localRect(h).inflate(4)];
    final primary = holes.isEmpty ? null : holes.first;
    final tipLayout = _tipLayout(size, pad, primary);
    final centerTip = step.centerTip || _holesAreAlongBottom(size, holes);
    final tipTop = centerTip ? null : _tipTop(size, pad, primary);
    final stepCount = widget.steps.length.clamp(1, 99);
    final isLast = _index >= stepCount - 1;

    final tipCard = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: tipLayout.maxWidth),
      child: _HelpTipCard(
        isLight: isLight,
        title: step.title,
        body: step.body,
        stepIndex: _index,
        stepCount: stepCount,
        onNext: _next,
        onSkip: _finish,
        nextLabel: isLast ? 'Done' : 'Next',
      ),
    );

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                holes: [
                  for (final hole in holes)
                    (
                      hole,
                      hole.height > hole.width * 2 ? 14.0 : step.cornerRadius,
                    ),
                ],
                scrim: Colors.black.withValues(
                  alpha: holes.isEmpty ? 0.48 : 0.72,
                ),
              ),
            ),
          ),
          for (final hole in holes)
            Positioned.fromRect(
              rect: hole.inflate(3),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      hole.height > hole.width * 2
                          ? 14
                          : step.cornerRadius + 2,
                    ),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.9),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          if (step.showTapHint && primary != null)
            Positioned(
              left: primary.center.dx - 36,
              top: primary.center.dy - 20,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _tapPulse,
                  builder: (context, _) =>
                      _TapGestureHint(progress: _tapPulse.value),
                ),
              ),
            ),
          // Tip under callouts so labels on FABs / rail stay readable.
          if (centerTip)
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22 + pad.left,
                  pad.top + 12,
                  22 + pad.right,
                  pad.bottom + 12,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: tipCard,
                ),
              ),
            )
          else
            Positioned(
              left: tipLayout.left,
              right: tipLayout.right,
              top: tipTop,
              child: Align(
                alignment: tipLayout.alignment,
                child: tipCard,
              ),
            ),
          for (final c in step.callouts) _positionedCallout(c),
        ],
      ),
    );
  }

  bool _holesAreAlongBottom(Size size, List<Rect> holes) {
    if (holes.isEmpty) return false;
    return holes.every((h) => h.top > size.height * 0.62);
  }

  Widget _positionedCallout(SpotlightCallout c) {
    final to = _localOffset(c.globalTarget);
    if (c.arrow == SpotlightArrow.right) {
      return Positioned(
        left: to.dx - 120,
        top: to.dy - 16,
        child: IgnorePointer(
          child: _LabeledArrow(label: c.label, direction: SpotlightArrow.right),
        ),
      );
    }
    if (c.arrow == SpotlightArrow.left) {
      // Place label in the gutter beside the rail, not under the tip card.
      return Positioned(
        left: to.dx + 22,
        top: to.dy - 16,
        child: IgnorePointer(
          child: _LabeledArrow(label: c.label, direction: SpotlightArrow.left),
        ),
      );
    }
    if (c.arrow == SpotlightArrow.up) {
      // Badge below the target; chevron points up at Play / Save / Share.
      const badgeW = 140.0;
      return Positioned(
        left: to.dx - badgeW / 2,
        top: to.dy + 8,
        child: IgnorePointer(
          child: _LabeledArrow(label: c.label, direction: SpotlightArrow.up),
        ),
      );
    }
    const badgeW = 72.0;
    return Positioned(
      left: to.dx - badgeW / 2,
      top: to.dy - 48,
      child: IgnorePointer(
        child: _LabeledArrow(label: c.label, direction: SpotlightArrow.down),
      ),
    );
  }

  bool _isLeftRailHole(Size size, Rect? hole) =>
      hole != null &&
      hole.left < size.width * 0.3 &&
      hole.height > hole.width * 1.6;

  ({double? left, double? right, double maxWidth, Alignment alignment})
      _tipLayout(Size size, EdgeInsets pad, Rect? hole) {
    final isWide = size.width > 600;
    final maxWidth = isWide
        ? math.min(400.0, size.width * 0.48)
        : size.width;

    // Wide / rail steps: keep a compact card centered (callouts paint above it).
    if (isWide) {
      return (
        left: 22 + pad.left,
        right: 22 + pad.right,
        maxWidth: maxWidth,
        alignment: Alignment.topCenter,
      );
    }

    return (
      left: 22 + pad.left,
      right: 22 + pad.right,
      maxWidth: size.width,
      alignment: Alignment.topCenter,
    );
  }

  double _tipTop(Size size, EdgeInsets pad, Rect? hole) {
    if (hole == null) {
      return (size.height * 0.32).clamp(
        pad.top + 24,
        size.height - 320,
      );
    }
    if (_isLeftRailHole(size, hole)) {
      return (size.height * 0.22).clamp(pad.top + 24, size.height - 320);
    }
    final below = hole.bottom + 14;
    if (below + 260 < size.height - pad.bottom - 12) {
      return below;
    }
    final above = hole.top - 240;
    if (above > pad.top + 8) return above;
    return (size.height * 0.22).clamp(pad.top + 16, size.height * 0.4);
  }
}

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
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LabeledArrow extends StatelessWidget {
  final String label;
  final SpotlightArrow direction;

  const _LabeledArrow({
    required this.label,
    required this.direction,
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

    if (direction == SpotlightArrow.down) {
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

    if (direction == SpotlightArrow.up) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: math.pi,
            child: const CustomPaint(
              size: Size(18, 16),
              painter: _ChevronPainter(down: true),
            ),
          ),
          const SizedBox(height: 2),
          badge,
        ],
      );
    }

    if (direction == SpotlightArrow.left) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: math.pi,
            child: const CustomPaint(
              size: Size(22, 14),
              painter: _ChevronPainter(down: false),
            ),
          ),
          const SizedBox(width: 4),
          badge,
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

class _HelpTipCard extends StatelessWidget {
  final bool isLight;
  final String title;
  final String body;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String nextLabel;

  const _HelpTipCard({
    required this.isLight,
    required this.title,
    required this.body,
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
      oldDelegate.holes.length != holes.length;
}
