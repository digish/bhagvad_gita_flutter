import 'package:flutter/material.dart';

class FontSizeControl extends StatelessWidget {
  final double currentSize;
  final Function(double) onSizeChanged;
  final Color? color;
  final double minSize;
  final double maxSize;
  final double step;

  const FontSizeControl({
    super.key,
    required this.currentSize,
    required this.onSizeChanged,
    this.color,
    this.minSize = 16.0,
    this.maxSize = 32.0,
    this.step = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        color ??
        Theme.of(context).textTheme.bodyMedium?.color ??
        Colors.black87;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: textColor),
          onPressed: currentSize > minSize
              ? () => onSizeChanged(currentSize - step)
              : null,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Decrease Font Size',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '${currentSize.toInt()}',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: textColor),
          onPressed: currentSize < maxSize
              ? () => onSizeChanged(currentSize + step)
              : null,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: 'Increase Font Size',
        ),
      ],
    );
  }
}

/// Left-wall − / size / + dock (chapter list, book reading, Parayan).
class FontSizeDock extends StatelessWidget {
  final double currentSize;
  final ValueChanged<double> onSizeChanged;
  final Color? iconColor;
  final Color? backgroundColor;

  const FontSizeDock({
    super.key,
    required this.currentSize,
    required this.onSizeChanged,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final fg = iconColor ??
        Theme.of(context).iconTheme.color ??
        (isLight ? Colors.black87 : Colors.white);
    final glass =
        backgroundColor ?? (isLight ? const Color(0xFFF7F4EE) : const Color(0xFF2A2A2A));

    return Material(
      color: glass,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(22),
        ),
        side: BorderSide(
          color: isLight
              ? Colors.black.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
        child: Theme(
          data: Theme.of(context).copyWith(
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: fg,
                disabledForegroundColor: fg.withValues(alpha: 0.35),
                overlayColor: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
          child: FontSizeControl(
            currentSize: currentSize,
            onSizeChanged: onSizeChanged,
            color: fg,
          ),
        ),
      ),
    );
  }
}
