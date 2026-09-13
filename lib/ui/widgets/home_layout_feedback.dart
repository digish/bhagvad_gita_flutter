import 'package:flutter/material.dart';

import '../../providers/settings_provider.dart';

/// Three-step indicator beside the home layout FAB (filled dot = current mode).
class HomeLayoutModeDots extends StatelessWidget {
  final HomeUiMode mode;
  final Color? activeColor;
  final Color? inactiveColor;

  const HomeLayoutModeDots({
    super.key,
    required this.mode,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = activeColor ?? theme.colorScheme.primary;
    final inactive =
        inactiveColor ?? theme.colorScheme.onSurface.withOpacity(0.28);
    final index = mode.index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(HomeUiMode.values.length, (i) {
        final isActive = i == index;
        return Padding(
          padding: EdgeInsets.only(bottom: i < HomeUiMode.values.length - 1 ? 5 : 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 7 : 5,
            height: isActive ? 7 : 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? active : inactive,
            ),
          ),
        );
      }),
    );
  }
}
