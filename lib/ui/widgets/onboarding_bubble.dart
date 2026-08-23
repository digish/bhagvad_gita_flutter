/*
*  © 2025 Digish Pandya. All rights reserved.
*/

import 'package:flutter/material.dart';

/// Which side of the target the bubble sits on (tail points at the target).
enum OnboardingBubblePlacement {
  aboveTarget,
  belowTarget,
  leftOfTarget,
  rightOfTarget,
}

/// Positions an [OnboardingBubble] from a live [targetKey] rect — not guessed offsets.
class AnchoredOnboardingBubble extends StatefulWidget {
  final GlobalKey targetKey;
  final OnboardingBubblePlacement placement;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final String text;
  final IconData icon;
  final double gap;
  final Listenable? repositionListenable;

  const AnchoredOnboardingBubble({
    super.key,
    required this.targetKey,
    required this.placement,
    required this.onTap,
    required this.onDismiss,
    required this.text,
    required this.icon,
    this.gap = 10,
    this.repositionListenable,
  });

  @override
  State<AnchoredOnboardingBubble> createState() =>
      _AnchoredOnboardingBubbleState();
}

class _AnchoredOnboardingBubbleState extends State<AnchoredOnboardingBubble> {
  double? _left;
  double? _top;
  double? _tailOffset;
  OnboardingBubblePlacement? _resolvedPlacement;
  final GlobalKey _bubbleKey = GlobalKey();

  static const double _edgePad = 8;
  static const double _minTailInset = 14;

  @override
  void initState() {
    super.initState();
    widget.repositionListenable?.addListener(_scheduleReposition);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  @override
  void dispose() {
    widget.repositionListenable?.removeListener(_scheduleReposition);
    super.dispose();
  }

  void _scheduleReposition() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  @override
  void didUpdateWidget(covariant AnchoredOnboardingBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repositionListenable != widget.repositionListenable) {
      oldWidget.repositionListenable?.removeListener(_scheduleReposition);
      widget.repositionListenable?.addListener(_scheduleReposition);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  RenderBox? _stackBox() {
    RenderBox? stackBox;
    context.visitAncestorElements((element) {
      if (element.widget is Stack) {
        stackBox = element.renderObject as RenderBox?;
        return false;
      }
      return true;
    });
    return stackBox;
  }

  Rect? _targetRectInStack(RenderBox stackBox) {
    final targetContext = widget.targetKey.currentContext;
    if (targetContext == null) return null;
    final targetBox = targetContext.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) return null;

    final topLeft = stackBox.globalToLocal(targetBox.localToGlobal(Offset.zero));
    return topLeft & targetBox.size;
  }

  /// True when bubble sits fully outside [target] with at least [gap] between them.
  bool _isSeparated(Rect bubble, Rect target, double gap) {
    return bubble.bottom <= target.top - gap ||
        bubble.top >= target.bottom + gap ||
        bubble.right <= target.left - gap ||
        bubble.left >= target.right + gap;
  }

  List<OnboardingBubblePlacement> _sideCandidates(
    OnboardingBubblePlacement preferred,
  ) {
    const opposites = {
      OnboardingBubblePlacement.aboveTarget: OnboardingBubblePlacement.belowTarget,
      OnboardingBubblePlacement.belowTarget: OnboardingBubblePlacement.aboveTarget,
      OnboardingBubblePlacement.leftOfTarget: OnboardingBubblePlacement.rightOfTarget,
      OnboardingBubblePlacement.rightOfTarget: OnboardingBubblePlacement.leftOfTarget,
    };
    final others = OnboardingBubblePlacement.values
        .where((s) => s != preferred && s != opposites[preferred])
        .toList();
    return [preferred, opposites[preferred]!, ...others];
  }

  ({double left, double top, double tailOffset, OnboardingBubblePlacement side})?
  _layoutForSide({
    required OnboardingBubblePlacement side,
    required Rect target,
    required Size bubble,
    required Size stack,
    required double gap,
  }) {
    final bw = bubble.width;
    final bh = bubble.height;
    final sw = stack.width;
    final sh = stack.height;

    late double left;
    late double top;
    late double tailOffset;

    switch (side) {
      case OnboardingBubblePlacement.belowTarget:
        top = target.bottom + gap;
        left = target.center.dx - bw / 2;
        left = left.clamp(_edgePad, sw - bw - _edgePad);
        top = top.clamp(_edgePad, sh - bh - _edgePad);
        if (top < target.bottom + gap) top = target.bottom + gap;
        tailOffset = (target.center.dx - left).clamp(
          _minTailInset + 10,
          bw - _minTailInset - 10,
        );
      case OnboardingBubblePlacement.aboveTarget:
        top = target.top - gap - bh;
        left = target.center.dx - bw / 2;
        left = left.clamp(_edgePad, sw - bw - _edgePad);
        top = top.clamp(_edgePad, sh - bh - _edgePad);
        if (top + bh > target.top - gap) top = target.top - gap - bh;
        tailOffset = (target.center.dx - left).clamp(
          _minTailInset + 10,
          bw - _minTailInset - 10,
        );
      case OnboardingBubblePlacement.leftOfTarget:
        left = target.left - gap - bw;
        top = target.center.dy - bh / 2;
        top = top.clamp(_edgePad, sh - bh - _edgePad);
        left = left.clamp(_edgePad, sw - bw - _edgePad);
        if (left + bw > target.left - gap) {
          left = target.left - gap - bw;
        }
        tailOffset = (target.center.dy - top).clamp(
          _minTailInset + 10,
          bh - _minTailInset - 10,
        );
      case OnboardingBubblePlacement.rightOfTarget:
        left = target.right + gap;
        top = target.center.dy - bh / 2;
        top = top.clamp(_edgePad, sh - bh - _edgePad);
        left = left.clamp(_edgePad, sw - bw - _edgePad);
        if (left < target.right + gap) left = target.right + gap;
        tailOffset = (target.center.dy - top).clamp(
          _minTailInset + 10,
          bh - _minTailInset - 10,
        );
    }

    final bubbleRect = Rect.fromLTWH(left, top, bw, bh);
    if (!_isSeparated(bubbleRect, target, gap)) return null;
    if (left < _edgePad - 0.5 ||
        top < _edgePad - 0.5 ||
        left + bw > sw - _edgePad + 0.5 ||
        top + bh > sh - _edgePad + 0.5) {
      return null;
    }

    return (left: left, top: top, tailOffset: tailOffset, side: side);
  }

  void _updatePosition({bool afterLayout = false}) {
    final stackBox = _stackBox();
    if (stackBox == null || !mounted) return;

    final target = _targetRectInStack(stackBox);
    if (target == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
      return;
    }

    var bubbleWidth = 220.0;
    var bubbleHeight = 72.0;
    if (afterLayout) {
      final bubbleBox =
          _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
      if (bubbleBox != null && bubbleBox.hasSize) {
        bubbleWidth = bubbleBox.size.width;
        bubbleHeight = bubbleBox.size.height;
      }
    }

    final bubbleSize = Size(bubbleWidth, bubbleHeight);
    final stackSize = stackBox.size;
    final gap = widget.gap;

    ({double left, double top, double tailOffset, OnboardingBubblePlacement side})?
        best;

    for (final side in _sideCandidates(widget.placement)) {
      best = _layoutForSide(
        side: side,
        target: target,
        bubble: bubbleSize,
        stack: stackSize,
        gap: gap,
      );
      if (best != null) break;
    }

    best ??= _layoutForSide(
      side: widget.placement,
      target: target,
      bubble: bubbleSize,
      stack: stackSize,
      gap: gap,
    );

    if (best == null) return;

    final changed = _left != best.left ||
        _top != best.top ||
        _tailOffset != best.tailOffset ||
        _resolvedPlacement != best.side;

    if (changed && mounted) {
      setState(() {
        _left = best!.left;
        _top = best.top;
        _tailOffset = best.tailOffset;
        _resolvedPlacement = best.side;
      });
    }

    if (!afterLayout) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updatePosition(afterLayout: true),
      );
    }
  }

  bool get _pointingDown =>
      _resolvedPlacement == OnboardingBubblePlacement.aboveTarget;

  bool get _pointingLeft =>
      _resolvedPlacement == OnboardingBubblePlacement.rightOfTarget;

  bool get _pointingRight =>
      _resolvedPlacement == OnboardingBubblePlacement.leftOfTarget;

  @override
  Widget build(BuildContext context) {
    if (_left == null || _top == null || _tailOffset == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _left,
      top: _top,
      child: OnboardingBubble(
        key: _bubbleKey,
        text: widget.text,
        icon: widget.icon,
        pointingDown: _pointingDown,
        pointingLeft: _pointingLeft,
        pointingRight: _pointingRight,
        tailOffset: _tailOffset,
        onTap: widget.onTap,
        onDismiss: widget.onDismiss,
      ),
    );
  }
}

/// Floating onboarding tip — same visual language as Home & search hints.
class OnboardingBubble extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final String text;
  final IconData icon;
  final bool pointingDown;
  final bool pointingLeft;
  final bool pointingRight;
  final CrossAxisAlignment tailAlign;
  /// Pixel offset from the bubble's top-left to the tail **center**
  /// (horizontal for top/bottom tails, vertical for left/right tails).
  final double? tailOffset;

  const OnboardingBubble({
    super.key,
    required this.onTap,
    required this.onDismiss,
    this.text = 'Try Ask Gita',
    this.icon = Icons.auto_awesome,
    this.pointingDown = false,
    this.pointingLeft = false,
    this.pointingRight = false,
    this.tailAlign = CrossAxisAlignment.end,
    this.tailOffset,
  });

  @override
  State<OnboardingBubble> createState() => _OnboardingBubbleState();
}

class _OnboardingBubbleState extends State<OnboardingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  static const double _maxBodyWidth = 248;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _floatAnimation = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF424242) : Colors.white;
    final borderColor =
        isDark ? Colors.white24 : Colors.amber.withValues(alpha: 0.5);

    final bubbleBody = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxBodyWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: bubbleColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: borderColor, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: widget.onDismiss,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final tailH = CustomPaint(
      size: const Size(10, 20),
      painter: BubbleTailPainter(
        color: bubbleColor,
        borderColor: borderColor,
        pointingLeft: true,
      ),
    );
    final tailHRight = CustomPaint(
      size: const Size(10, 20),
      painter: BubbleTailPainter(
        color: bubbleColor,
        borderColor: borderColor,
        pointingRight: true,
      ),
    );
    final tailV = (bool down) => CustomPaint(
          size: const Size(20, 10),
          painter: BubbleTailPainter(
            color: bubbleColor,
            borderColor: borderColor,
            pointingDown: down,
          ),
        );

    double _horizontalTailPad() {
      if (widget.tailOffset != null) {
        return (widget.tailOffset! - 10).clamp(4.0, 400.0);
      }
      if (widget.tailAlign == CrossAxisAlignment.start) return 20;
      if (widget.tailAlign == CrossAxisAlignment.end) return 18;
      return 0;
    }

    double _verticalTailPad() {
      if (widget.tailOffset != null) {
        return (widget.tailOffset! - 10).clamp(4.0, 400.0);
      }
      return 0;
    }

    final Widget bubbleContent;
    if (widget.pointingLeft) {
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: _verticalTailPad()),
            child: tailH,
          ),
          bubbleBody,
        ],
      );
    } else if (widget.pointingRight) {
      bubbleContent = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bubbleBody,
          Padding(
            padding: EdgeInsets.only(top: _verticalTailPad()),
            child: tailHRight,
          ),
        ],
      );
    } else if (widget.tailOffset != null) {
      final hPad = _horizontalTailPad();
      bubbleContent = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.pointingDown)
            Padding(
              padding: EdgeInsets.only(left: hPad),
              child: tailV(false),
            ),
          bubbleBody,
          if (widget.pointingDown)
            Padding(
              padding: EdgeInsets.only(left: hPad),
              child: tailV(true),
            ),
        ],
      );
    } else {
      bubbleContent = Column(
        crossAxisAlignment: widget.tailAlign,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!widget.pointingDown)
            Padding(
              padding: EdgeInsets.only(
                right: widget.tailAlign == CrossAxisAlignment.end ? 20 : 0,
                left: widget.tailAlign == CrossAxisAlignment.start ? 20 : 0,
              ),
              child: tailV(false),
            ),
          bubbleBody,
          if (widget.pointingDown)
            Padding(
              padding: EdgeInsets.only(
                right: widget.tailAlign == CrossAxisAlignment.end ? 18 : 0,
                left: widget.tailAlign == CrossAxisAlignment.start ? 18 : 0,
              ),
              child: tailV(true),
            ),
        ],
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: bubbleContent,
      ),
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool pointingDown;
  final bool pointingLeft;
  final bool pointingRight;

  BubbleTailPainter({
    required this.color,
    required this.borderColor,
    this.pointingDown = false,
    this.pointingLeft = false,
    this.pointingRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final borderPath = Path();
    if (pointingLeft) {
      path.moveTo(0, size.height / 2);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
      borderPath.moveTo(0, size.height / 2);
      borderPath.lineTo(size.width, 0);
      borderPath.moveTo(0, size.height / 2);
      borderPath.lineTo(size.width, size.height);
    } else if (pointingRight) {
      path.moveTo(size.width, size.height / 2);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
      borderPath.moveTo(size.width, size.height / 2);
      borderPath.lineTo(0, 0);
      borderPath.moveTo(size.width, size.height / 2);
      borderPath.lineTo(0, size.height);
    } else if (pointingDown) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
      borderPath.moveTo(0, 0);
      borderPath.lineTo(size.width / 2, size.height);
      borderPath.lineTo(size.width, 0);
    } else {
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      borderPath.moveTo(0, size.height);
      borderPath.lineTo(size.width / 2, 0);
      borderPath.lineTo(size.width, size.height);
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
