import 'package:flutter/material.dart';

class ShareOptionsSheet extends StatefulWidget {
  final bool showAudioOption;
  final Function(Set<ShareOption>) onShare;
  final VoidCallback? onCreateImage;

  const ShareOptionsSheet({
    super.key,
    required this.showAudioOption,
    required this.onShare,
    this.onCreateImage,
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

    // ✨ REWRITE: Simplified structure.
    // 1. Align(bottomCenter) -> Sticks to bottom.
    // 2. ConstrainedBox(maxWidth: 600) -> Handles iPad width.
    // 3. Container -> The actual visual sheet (color, rounded corners).
    // 4. SafeArea -> SingleChildScrollView -> Column -> Content.
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[900]
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            left:
                false, // ✨ FIX: Prevent system rail padding from shifting centered content
            right: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // Title (Centered, Bold)
                    Text(
                      'Share Options',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Options List
                    // Using a simple Column for options to avoid complex nested padding
                    _buildOptionRow(
                      'Shloka',
                      ShareOption.shloka,
                      isMandatory: true,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionRow('Anvay', ShareOption.anvay),
                    const SizedBox(height: 12),
                    _buildOptionRow('Tika (Meaning)', ShareOption.tika),
                    if (widget.showAudioOption) ...[
                      const SizedBox(height: 12),
                      _buildOptionRow('Audio', ShareOption.audio),
                    ],

                    const SizedBox(height: 32),

                    // Share Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onShare(_selectedOptions);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                        ),
                        child: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Create Visual Card Button
                    if (widget.onCreateImage != null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onCreateImage!();
                          },
                          icon: const Icon(Icons.image_outlined),
                          label: const Text(
                            'Share as Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1.5,
                            ),
                            foregroundColor: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✨ REWRITE: Simplified Option Row to avoid CheckboxListTile padding issues
  Widget _buildOptionRow(
    String title,
    ShareOption option, {
    bool isMandatory = false,
  }) {
    final isSelected = _selectedOptions.contains(option);
    return InkWell(
      onTap: isMandatory
          ? null
          : () {
              setState(() {
                if (isSelected) {
                  _selectedOptions.remove(option);
                } else {
                  _selectedOptions.add(option);
                }
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).cardColor, // Distinct card-like bg for each option? Or just transparent?
          // Let's keep it simple: clear background, border maybe?
          // User said "plain". Let's stick to a clean row with checkbox.
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: isSelected,
                onChanged: isMandatory
                    ? null
                    : (v) {
                        setState(() {
                          if (v == true) {
                            _selectedOptions.add(option);
                          } else {
                            _selectedOptions.remove(option);
                          }
                        });
                      },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
