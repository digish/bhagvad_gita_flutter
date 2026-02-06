import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImageGeneratorService {
  /// Captures a [RepaintBoundary] wrapped widget as a PNG image.
  static Future<Uint8List?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Render at higher pixel ratio for better quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }

  /// Shares the image bytes using the native share sheet.
  /// Returns true if successful.
  static Future<bool> shareImage({
    required Uint8List bytes,
    String text = 'Shared via Bhagavad Gita App',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/gita_wisdom_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final result = await Share.shareXFiles([XFile(file.path)], text: text);

      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Error sharing image: $e');
      return false;
    }
  }
}
