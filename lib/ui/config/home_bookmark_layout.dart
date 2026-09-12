import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Home search screen — Collections bookmark chip (icon + label).
///
/// Edit these values and hot-restart to tune placement and size.
class HomeBookmarkLayout {
  // --- Icon (bookmark band after rotation) ---

  /// Visible height of the band on phone (width follows [bandAspect]).
  static const double bandHeightPhone = 100.0;

  static const double bandHeightTablet = 118.0;

  /// Trimmed asset is 319×912; after rotation, width ÷ height = 912 ÷ 319.
  static const double bandAspect = 912.0 / 319.0;

  /// Rotation in degrees (e.g. -90 = horizontal banner).
  static const double iconRotationDegrees = -70.0;

  static double get iconRotationRadians =>
      iconRotationDegrees * math.pi / 180.0;

  /// Nudge icon visually only (does not change layout slot size).
  static const double iconOffsetX = -50.0;

  static const double iconOffsetY = 0.0;

  /// Shrink layout space below/above the icon (pulls label closer). Try 8–24.
  static const double iconLayoutTrimBottom = 0.0;

  static const double iconLayoutTrimTop = 0.0;

  // --- Label ---

  static const double labelFontSizePhone = 11.0;

  static const double labelFontSizeTablet = 11.0;

  static const FontWeight labelFontWeight = FontWeight.w600;

  /// Gap after icon layout box. May be **negative** (e.g. -6) to overlap label.
  static const double labelGap = -10.0;

  /// Text line height multiplier; use ~0.85–1.0. `null` = font default (often tighter).
  static const double? labelLineHeight = 1.0;

  // --- Placement (whole chip: icon + label) ---

  /// Shifts chip toward the leading screen edge (matches parent horizontal padding).
  static const double leadingEdgePull = 16.0;

  /// Extra offset applied after [leadingEdgePull] (positive X = right, positive Y = down).
  static const double chipOffsetX = 0.0;

  static const double chipOffsetY = 0.0;

  /// Fine-tune label only (relative to centered column under the icon).
  static const double labelOffsetX = -60.0;

  static const double labelOffsetY = 0.0;

  // --- Helpers (used by SearchScreen layout math) ---

  static double bandHeight(bool isTablet) =>
      isTablet ? bandHeightTablet : bandHeightPhone;

  static double bandWidth(double bandHeight) => bandHeight * bandAspect;

  static double labelFontSize(bool isTablet) =>
      isTablet ? labelFontSizeTablet : labelFontSizePhone;

  static double iconLayoutHeight(bool isTablet) {
    final h = bandHeight(isTablet) - iconLayoutTrimTop - iconLayoutTrimBottom;
    return h > 0 ? h : bandHeight(isTablet);
  }

  static double labelTextHeight(bool isTablet) {
    final size = labelFontSize(isTablet);
    if (labelLineHeight == null) {
      return size * 1.1;
    }
    return size * labelLineHeight!;
  }

  static double columnHeight(bool isTablet) =>
      iconLayoutHeight(isTablet) + labelGap + labelTextHeight(isTablet);

  static double totalChipOffsetX() => -leadingEdgePull + chipOffsetX;
}
