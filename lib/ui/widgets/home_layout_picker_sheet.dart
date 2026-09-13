import 'package:flutter/material.dart';

import '../../providers/settings_provider.dart';

/// Bottom sheet: pick Classic / Simple / Focus home layout explicitly.
Future<HomeUiMode?> showHomeLayoutPickerSheet(
  BuildContext context, {
  required HomeUiMode current,
}) {
  return showModalBottomSheet<HomeUiMode>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  'Home appearance',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...HomeUiMode.values.map((mode) {
                return _HomeLayoutPickerTile(
                  mode: mode,
                  selected: mode == current,
                  onTap: () => Navigator.of(context).pop(mode),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

class _HomeLayoutPickerTile extends StatelessWidget {
  final HomeUiMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _HomeLayoutPickerTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.primaryColor.withOpacity(isDark ? 0.25 : 0.12),
        child: Icon(mode.layoutToggleIcon, color: theme.primaryColor),
      ),
      title: Text(
        mode.displayName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(mode.shortDescription),
      trailing: selected
          ? Icon(Icons.check_circle, color: theme.primaryColor)
          : Icon(Icons.circle_outlined, color: theme.hintColor),
      onTap: onTap,
    );
  }
}
