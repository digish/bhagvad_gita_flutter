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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          _buildOptionTile('Shloka', ShareOption.shloka, isMandatory: true),
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
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
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
    );
  }
}
