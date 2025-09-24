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

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CustomScrollIndicator extends StatefulWidget {
  final int itemCount;
  final List<int> chapterMarkers;
  final List<String> chapterLabels;
  final Function(int index) onLotusTap;
  final ItemPositionsListener itemPositionsListener; // ✨ FIX: Revert to listener

  const CustomScrollIndicator({
    super.key,
    required this.itemCount,
    required this.chapterMarkers,
    required this.chapterLabels,
    required this.onLotusTap,
    required this.itemPositionsListener, // ✨ FIX: Revert
  });

  @override
  State<CustomScrollIndicator> createState() => _CustomScrollIndicatorState();
}

class _CustomScrollIndicatorState extends State<CustomScrollIndicator> {
  double _scrollRatio = 0.0;
  bool _isInteracting = false;
  ui.Image? beeImage;
  ui.Image? lotusImage;
  final Map<int, Rect> _lotusRects = {};

  @override
  void initState() {
    super.initState();
    _loadImages();

    // ✨ FIX: Listen to the ItemPositionsListener for accurate updates.
    widget.itemPositionsListener.itemPositions.addListener(() {
      final positions = widget.itemPositionsListener.itemPositions.value;

      if (positions.isNotEmpty) {
        // Find the item with the smallest index to represent the top of the viewport.
        final firstVisible = positions.reduce(
          (min, p) => p.index < min.index ? p : min,
        );

        final scrollIndex = firstVisible.index;
        // Calculate scroll ratio based on item index, which is more stable.
        final scrollRatio = scrollIndex / (widget.itemCount - 1);

        if (mounted) setState(() => _scrollRatio = scrollRatio.clamp(0.0, 1.0));
      }
    });
  }

  Future<void> _loadImages() async {
    beeImage = await _loadUiImage('assets/images/honeybee.png');
    lotusImage = await _loadUiImage('assets/images/lotus_marker2.png');
    setState(() {});
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final Size indicatorSize = Size(60, height);

    // Wait for images to load before painting
    if (lotusImage == null || beeImage == null) {
      return SizedBox(
        width: indicatorSize.width,
        height: indicatorSize.height,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _isInteracting ? 0.7 : 0.7,
      child: GestureDetector(
        onTapDown: (details) {
          final localPos = details.localPosition;
          for (final entry in _lotusRects.entries) {
            if (entry.value.contains(localPos)) {
              widget.onLotusTap(entry.key);
              break;
            }
          }
        },
        child: SizedBox(
          width: indicatorSize.width,
          height: indicatorSize.height,
          child: CustomPaint(
            size: indicatorSize,
            painter: StemPainter(
              scrollRatio: _scrollRatio,
              beeImage: beeImage,
              lotusImage: lotusImage,
              itemCount: widget.itemCount,
              chapterMarkers: widget.chapterMarkers,
              chapterLabels: widget.chapterLabels,
              lotusRects: _lotusRects,
            ),
          ),
        ),
      ),
    );
  }

  /*
  List<Offset> _generateStemPoints(Size size) {
    final double spacing = size.height / (widget.itemCount + 1);
    final List<Offset> points = [];

    for (int i = 0; i < widget.itemCount; i++) {
      final double y = spacing * (i + 1);
      final double x = size.width / 2 + sin(i * 0.7) * 20; // match StemPainter exactly
      points.add(Offset(x, y));
    }

    return points;
  }
*/
}

class StemPainter extends CustomPainter {
  final double scrollRatio;
  final ui.Image? beeImage;
  final ui.Image? lotusImage;
  final int itemCount;
  final List<int> chapterMarkers;
  final List<String> chapterLabels;
  final Map<int, Rect> lotusRects;

  StemPainter({
    required this.scrollRatio,
    required this.beeImage,
    required this.lotusImage,
    required this.itemCount,
    required this.chapterMarkers,
    required this.chapterLabels,
    required this.lotusRects,
  });

  // ✨ Helper function to calculate a point on a curve
  Offset _getQuadraticBezierPoint(Offset p0, Offset p1, Offset p2, double t) {
    final double u = 1 - t;
    final double tt = t * t;
    final double uu = u * u;

    final double x = uu * p0.dx + 2 * u * t * p1.dx + tt * p2.dx;
    final double y = uu * p0.dy + 2 * u * t * p1.dy + tt * p2.dy;

    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Clear the rects map for each paint cycle to ensure positions are fresh.
    lotusRects.clear();

    /// 1. Define the Zigzag Layout (Same as before)
    final double leftX = size.width * 0.25;
    final double rightX = size.width * 0.75;
    final double verticalPadding = 40.0;
    final double drawableHeight = size.height - (2 * verticalPadding);
    final double ySpacing = drawableHeight / (chapterMarkers.length - 1);

    final List<Offset> lotusPositions = [];
    for (int i = 0; i < chapterMarkers.length; i++) {
      final double x = (i % 2 == 0) ? leftX : rightX;
      final double y = verticalPadding + (i * ySpacing);
      lotusPositions.add(Offset(x, y));
    }

    /// 2. Generate the full CURVED path
    final List<Offset> stemPoints = [];
    // ✨ Controls how much the stem bows outwards. Higher value = more curve.
    final double curveIntensity = 45.0;

    if (chapterMarkers.length > 1) {
      for (int i = 0; i < chapterMarkers.length - 1; i++) {
        final startItemIndex = chapterMarkers[i];
        final endItemIndex = chapterMarkers[i + 1];
        final pointsInSegment = endItemIndex - startItemIndex;

        final startPos = lotusPositions[i];
        final endPos = lotusPositions[i + 1];

        // ✨ Calculate a control point to define the curve
        final midPoint = (startPos + endPos) / 2;
        // The direction of the curve depends on which side it's on
        final controlPoint = Offset(
          midPoint.dx + (i % 2 == 0 ? curveIntensity : -curveIntensity),
          midPoint.dy,
        );

        if (pointsInSegment <= 0) continue;

        for (int j = 0; j < pointsInSegment; j++) {
          final t = j / pointsInSegment;
          // ✨ Calculate point on the curve instead of a straight line
          final point = _getQuadraticBezierPoint(
            startPos,
            controlPoint,
            endPos,
            t,
          );
          stemPoints.add(point);
        }
      }
    }
    if (lotusPositions.isNotEmpty) {
      stemPoints.add(lotusPositions.last);
    }

    while (stemPoints.length < itemCount) {
      stemPoints.add(lotusPositions.last);
    }

    /// 3. Draw the path (Same as before, but it will now be curved)
    if (stemPoints.isNotEmpty) {
      final Paint stemPaint = Paint()
        ..color = const ui.Color.fromARGB(255, 56, 142, 60)
        ..strokeWidth = 5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final Path stemPath = Path();
      stemPath.moveTo(stemPoints[0].dx, stemPoints[0].dy);
      for (int i = 1; i < stemPoints.length; i++) {
        stemPath.lineTo(stemPoints[i].dx, stemPoints[i].dy);
      }
      canvas.drawPath(stemPath, stemPaint);
    }

    /// 4. Draw the Lotuses and Labels on TOP of the path
    final double lotusSize = 35.0;
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < chapterMarkers.length; i++) {
      final Offset pos = lotusPositions[i];
      final Rect lotusRect = Rect.fromCenter(
        center: pos,
        width: lotusSize,
        height: lotusSize,
      );
      lotusRects[i] = lotusRect; // Store rect for tap detection

      // Draw shadow (dummy image: blurred black circle)
      final double shadowSize = lotusSize + 10;
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(pos, shadowSize / 2, shadowPaint);
      
      if (lotusImage != null) {
        paintImage(
          canvas: canvas,
          rect: lotusRect,
          image: lotusImage!,
          fit: BoxFit.contain,
        );
      }

      final label = chapterLabels[i];
      final textPainter = TextPainter(
        text: TextSpan(text: label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      // Center the text inside the lotus
      final textOffset = Offset(
        pos.dx - textPainter.width / 2,
        pos.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }

    /// 5. Draw the Bee on its current position on the path
    if (stemPoints.isNotEmpty && beeImage != null) {
      final int beeIndex = (scrollRatio * (itemCount - 1)).round().clamp(
        0,
        stemPoints.length - 1,
      );
      final Offset beePos = stemPoints[beeIndex];

      paintImage(
        canvas: canvas,
        rect: Rect.fromCenter(center: beePos, width: 28, height: 28),
        image: beeImage!,
        fit: BoxFit.contain,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StemPainter oldDelegate) {
    // Only repaint if the scroll ratio has changed. This is more efficient.
    return oldDelegate.scrollRatio != scrollRatio;
  }
}
