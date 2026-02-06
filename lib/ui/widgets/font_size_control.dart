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
