import 'package:flutter/material.dart';

class ShareOptionsSheet extends StatefulWidget {
  final bool showAudioOption;
  final Function(Set<ShareOption>) onShare;

  const ShareOptionsSheet({
    super.key,
    required this.showAudioOption,
    required this.onShare,
  });

  @override
  State<ShareOptionsSheet> createState() => _ShareOptionsSheetState();
}

enum ShareOption { shloka, anvay, tika, audio }

class _ShareOptionsSheetState extends State<ShareOptionsSheet> {
  final Set<ShareOption> _selectedOptions = {
    ShareOption.shloka,
    ShareOption.anvay,
    ShareOption.tika,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double width = MediaQuery.of(context).size.width;
    final bool isLandscape = width > MediaQuery.of(context).size.height;
    final bool hasRail = width > 600;
    // Use a smaller padding or rely on SafeArea with minimums
    final double railOffset = hasRail && isLandscape ? 150.0 : 0.0;
    // Add some right padding in landscape to balance it (looks like a floating modal)
    final double rightOffset = isLandscape ? 0.0 : 0.0;

    return Padding(
      // ✨ Shift the entire sheet "box" to avoid the rail
      padding: EdgeInsets.only(left: railOffset, right: rightOffset),
      child: Container(
        padding: const EdgeInsets.only(
          top: 20,
          bottom: 0, // Handled by SafeArea
          left: 16,
          right: 16,
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey[900]
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          // If we already applied a large left margin (railOffset), we don't need SafeArea left.
          left: railOffset == 0,
          top: false,
          right: true,
          bottom: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Share Options',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildOptionTile(
                  'Shloka',
                  ShareOption.shloka,
                  isMandatory: true,
                ),
                _buildOptionTile('Anvay', ShareOption.anvay),
                _buildOptionTile('Tika (Meaning)', ShareOption.tika),
                if (widget.showAudioOption)
                  _buildOptionTile('Audio', ShareOption.audio),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onShare(_selectedOptions);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Share', style: TextStyle(fontSize: 16)),
                ),
                // Add some bottom padding for the scroll view
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    ShareOption option, {
    bool isMandatory = false,
  }) {
    final isSelected = _selectedOptions.contains(option);
    return CheckboxListTile(
      title: Text(title),
      value: isSelected,
      onChanged: isMandatory
          ? null // Disable interaction for mandatory field
          : (bool? value) {
              setState(() {
                if (value == true) {
                  _selectedOptions.add(option);
                } else {
                  _selectedOptions.remove(option);
                }
              });
            },
      activeColor: Theme.of(context).colorScheme.primary,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
