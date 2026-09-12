import 'package:flutter/material.dart';

const double kDefaultFocusLine = 0.40;

/// Extra scroll extent after the last verse so its center can sit on [focusLine].
double trailingRunwayHeightForFocusLine(
  BuildContext context, {
  double focusLine = kDefaultFocusLine,
}) {
  final viewport = MediaQuery.sizeOf(context).height;
  return (viewport * (1.0 - focusLine)).clamp(240.0, viewport);
}
