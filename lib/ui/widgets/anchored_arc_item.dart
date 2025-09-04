// lib/ui/widgets/anchored_arc_item.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class ArcLabelAnimationOptions {
  final bool enableOrbit;
  final bool enableSelfRotation;
  final bool enablePulsation;
  final Duration rotationDuration;
  final Duration pulsationDuration;

  const ArcLabelAnimationOptions({
    this.enableOrbit = false,
    this.enableSelfRotation = false,
    this.enablePulsation = false,
    this.rotationDuration = const Duration(seconds: 10),
    this.pulsationDuration = const Duration(seconds: 2),
  });
}

class AnchoredArcItem extends StatefulWidget {
  final double top, left;
  final Widget anchor;
  final double anchorWidth, anchorHeight;
  final Widget label;
  final double labelAngle;
  final double labelDistance;
  final ArcLabelAnimationOptions animationOptions;

  const AnchoredArcItem({
    super.key,
    this.top = 0.0,
    this.left = 0.0,
    required this.anchor,
    this.anchorWidth = 100.0,
    this.anchorHeight = 100.0,
    required this.label,
    this.labelAngle = 0.0,
    this.labelDistance = 0.0,
    this.animationOptions = const ArcLabelAnimationOptions(),
  });

  @override
  State<AnchoredArcItem> createState() => _AnchoredArcItemState();
}

class _AnchoredArcItemState extends State<AnchoredArcItem>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulsationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: widget.animationOptions.rotationDuration,
    );
    if (widget.animationOptions.enableOrbit || widget.animationOptions.enableSelfRotation) {
      _rotationController.repeat();
    }
    _pulsationController = AnimationController(
      vsync: this,
      duration: widget.animationOptions.pulsationDuration,
      lowerBound: 0.95,
      upperBound: 1.05,
    );
    if (widget.animationOptions.enablePulsation) {
      _pulsationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulsationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.left,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: widget.anchorWidth,
            height: widget.anchorHeight,
            child: widget.anchor,
          ),
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              final double startAngle = widget.labelAngle * (math.pi / 180.0);
              final double orbitAngle = widget.animationOptions.enableOrbit
                  ? _rotationController.value * 2 * math.pi
                  : 0;
              final double currentOrbitAngle = startAngle + orbitAngle;

              final double selfRotationAngle = widget.animationOptions.enableSelfRotation
                  ? _rotationController.value * 2 * math.pi
                  : 0;

              return Transform(
                transform: Matrix4.identity()
                  ..translate(
                    widget.labelDistance * math.cos(currentOrbitAngle - math.pi / 2),
                    widget.labelDistance * math.sin(currentOrbitAngle - math.pi / 2),
                  )
                  ..rotateZ(selfRotationAngle)
                  ..rotateZ(currentOrbitAngle),
                alignment: Alignment.center,
                child: child,
              );
            },
            // ✨ THE FINAL FIX IS HERE ✨
            // We wrap the label in a Stack to create a perfectly centered "turntable".
            child: ScaleTransition(
              scale: _pulsationController,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  widget.label,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}