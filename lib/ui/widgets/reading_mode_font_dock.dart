import 'dart:ui';

import 'package:flutter/material.dart';

import 'font_size_control.dart';
import 'full_shloka_card.dart';

/// Bottom-left dock: font size + layout count + content mode (Parayan & chapter).
class ReadingModeFontDock extends StatelessWidget {
  final double currentSize;
  final bool expanded;
  final VoidCallback? onPeekTap;
  final ValueChanged<double> onSizeChanged;
  final ContinuousListBody listBodyMode;
  final ParayanLayoutCount layoutCount;
  final ContinuousListPair listPairMode;
  final VoidCallback onToggleListContent;
  final VoidCallback onToggleLayoutCount;

  const ReadingModeFontDock({
    super.key,
    required this.currentSize,
    required this.onSizeChanged,
    required this.listBodyMode,
    required this.layoutCount,
    required this.listPairMode,
    required this.onToggleListContent,
    required this.onToggleLayoutCount,
    this.expanded = true,
    this.onPeekTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final iconColor =
        Theme.of(context).iconTheme.color ??
        (isLight ? Colors.black87 : Colors.white);
    final accent = Theme.of(context).colorScheme.secondary;

    final (Widget modeGlyph, String label, String tooltip, bool emphasize) =
        switch (layoutCount) {
      ParayanLayoutCount.three => (
          Icon(
            Icons.layers_outlined,
            size: 20,
            color: iconColor.withValues(alpha: 0.4),
          ),
          'All',
          'All three visible',
          false,
        ),
      ParayanLayoutCount.two => switch (listPairMode) {
          ContinuousListPair.shlokaAnvay => (
              _PairGlyph(
                first: Icon(Icons.menu_book_rounded, size: 13, color: accent),
                second: Icon(
                  Icons.format_quote_rounded,
                  size: 13,
                  color: accent,
                ),
              ),
              'Sh+An',
              'Shloka + Anvay · tap for Shloka + Tika',
              true,
            ),
          ContinuousListPair.shlokaTranslation => (
              _PairGlyph(
                first: Icon(Icons.menu_book_rounded, size: 13, color: accent),
                second: Text(
                  'अ',
                  style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              'Sh+Ti',
              'Shloka + Tika · tap for Anvay + Tika',
              true,
            ),
          ContinuousListPair.anvayTranslation => (
              _PairGlyph(
                first: Icon(
                  Icons.format_quote_rounded,
                  size: 13,
                  color: accent,
                ),
                second: Text(
                  'अ',
                  style: TextStyle(
                    fontFamily: 'NotoSerif',
                    fontSize: 12,
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              'An+Ti',
              'Anvay + Tika · tap for Shloka + Anvay',
              true,
            ),
        },
      ParayanLayoutCount.one => switch (listBodyMode) {
          ContinuousListBody.shloka => (
              Icon(Icons.menu_book_rounded, size: 20, color: iconColor),
              'Shloka',
              'Shloka · tap for anvay',
              false,
            ),
          ContinuousListBody.anvay => (
              Icon(Icons.format_quote_rounded, size: 20, color: accent),
              'Anvay',
              'Anvay · tap for translation',
              true,
            ),
          ContinuousListBody.translation => (
              Text(
                'अ',
                style: TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: 18,
                  height: 1.0,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              'Tika',
              'Translation · tap for shloka',
              true,
            ),
        },
    };
    final viewEnabled = layoutCount != ParayanLayoutCount.three;
    final modeColor = viewEnabled
        ? (emphasize ? accent : iconColor)
        : iconColor.withValues(alpha: 0.4);

    final (int layoutN, String layoutTip) = switch (layoutCount) {
      ParayanLayoutCount.one => (1, 'One item · tap for two'),
      ParayanLayoutCount.two => (2, 'Two items · tap for all three'),
      ParayanLayoutCount.three => (3, 'All three · tap for one'),
    };

    final dock = ClipRRect(
      borderRadius: const BorderRadius.horizontal(
        right: Radius.circular(22),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: isLight
              ? Colors.white.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.55),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(22),
            ),
            side: BorderSide(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            child: Theme(
              data: Theme.of(context).copyWith(
                iconButtonTheme: IconButtonThemeData(
                  style: IconButton.styleFrom(
                    foregroundColor: iconColor,
                    disabledForegroundColor: iconColor.withValues(alpha: 0.35),
                    overlayColor: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FontSizeControl(
                  currentSize: currentSize,
                  onSizeChanged: onSizeChanged,
                  color: iconColor,
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: iconColor.withValues(alpha: 0.25),
                ),
                Tooltip(
                  message: layoutTip,
                  child: InkWell(
                    onTap: onToggleLayoutCount,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            child: Center(
                              child: _StackedBarsGlyph(
                                count: layoutN,
                                color: iconColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$layoutN',
                            style: TextStyle(
                              fontSize: 9,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: iconColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip,
                  child: InkWell(
                    onTap: viewEnabled ? onToggleListContent : null,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            child: Center(child: modeGlyph),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 9,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                              color: modeColor.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                      ),
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

    return AnimatedSlide(
      duration: const Duration(milliseconds: 320),
      curve: expanded ? Curves.easeOutCubic : Curves.easeInCubic,
      offset: expanded ? Offset.zero : const Offset(-0.84, 0),
      child: GestureDetector(
        onTap: expanded ? null : onPeekTap,
        behavior: HitTestBehavior.opaque,
        child: dock,
      ),
    );
  }
}

class _StackedBarsGlyph extends StatelessWidget {
  final int count;
  final Color color;

  const _StackedBarsGlyph({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: count == 3 ? 2.0 : 2.5),
            Container(
              height: count == 1 ? 3.5 : 2.6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PairGlyph extends StatelessWidget {
  final Widget first;
  final Widget second;

  const _PairGlyph({required this.first, required this.second});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        first,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Text(
            '+',
            style: TextStyle(
              fontSize: 9,
              height: 1.0,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        second,
      ],
    );
  }
}
