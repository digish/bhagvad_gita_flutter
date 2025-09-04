// lib/ui/widgets/centered_spinner.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Defines the direction of rotation for an animation.
enum SpinDirection { clockwise, counterClockwise }

class CenteredSpinner extends StatefulWidget {
  final Widget anchor;
  final List<Widget>? overlayFrames;
  final Widget child;
  
  final bool isSpinning;
  final Duration spinDuration;
  final SpinDirection spinDirection;
  final double initialSpinOffset;

  final Duration frameAnimationDuration;
  final SpinDirection frameCycleDirection;

  const CenteredSpinner({
    super.key,
    required this.anchor,
    this.overlayFrames,
    required this.child,
    this.isSpinning = true,
    this.spinDuration = const Duration(seconds: 15),
    this.spinDirection = SpinDirection.clockwise,
    this.initialSpinOffset = 0.0,
    this.frameAnimationDuration = const Duration(milliseconds: 500),
    this.frameCycleDirection = SpinDirection.clockwise,
  });

  @override
  State<CenteredSpinner> createState() => _CenteredSpinnerState();
}

class _CenteredSpinnerState extends State<CenteredSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _frameController;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: widget.spinDuration,
    );
    _spinController.value = widget.initialSpinOffset; 
    if (widget.isSpinning) {
      if (widget.spinDirection == SpinDirection.clockwise) {
        _spinController.repeat();
      } else {
        _spinController.repeat(reverse: true);
      }
    }

    _frameController = AnimationController(
      vsync: this,
      duration: widget.frameAnimationDuration,
    );
    if (widget.overlayFrames != null && widget.overlayFrames!.isNotEmpty) {
      if (widget.frameCycleDirection == SpinDirection.clockwise) {
        _frameController.repeat();
      } else {
        _frameController.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _frameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Layer 1: The anchor (lotus). This can be tapped.
        widget.anchor,

        // ✨ IMPORTANT FIX: This IgnorePointer allows taps to pass through
        // the animated layers to the button below.
        IgnorePointer(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Layer 2: The animated overlay.
              if (widget.overlayFrames != null && widget.overlayFrames!.isNotEmpty)
                AnimatedBuilder(
                  animation: _frameController,
                  builder: (context, child) {
                    final frameCount = widget.overlayFrames!.length;
                    final frameIndex = (_frameController.value * frameCount).floor() % frameCount;
                    return widget.overlayFrames![frameIndex];
                  },
                ),
              
              // Layer 3: The spinning child.
              AnimatedBuilder(
                animation: _spinController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _spinController.value * 2 * math.pi,
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ],
          ),
        ),
      ],
    );
  }
}