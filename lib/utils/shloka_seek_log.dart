import 'package:flutter/foundation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Debug logging for chapter / search scroll-to-shloka (filter logcat by SHLOKA_SEEK).
void shlokaSeekLog(String scope, String message) {
  debugPrint('[SHLOKA_SEEK][$scope] $message');
}

void shlokaSeekLogItemPositions(
  String scope,
  Iterable<ItemPosition> positions, {
  int? highlightIndex,
}) {
  final sorted = positions.toList()
    ..sort((a, b) => a.index.compareTo(b.index));
  final parts = sorted.map((p) {
    final center = (p.itemLeadingEdge + p.itemTrailingEdge) / 2;
    final mark = p.index == highlightIndex ? '*' : '';
    return '$mark${p.index}(L=${p.itemLeadingEdge.toStringAsFixed(2)},'
        'T=${p.itemTrailingEdge.toStringAsFixed(2)},C=${center.toStringAsFixed(2)})';
  });
  shlokaSeekLog(scope, 'visible items: ${parts.join(' ')}');
}
