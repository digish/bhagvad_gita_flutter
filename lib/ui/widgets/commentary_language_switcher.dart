import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/commentary_language.dart';

/// Compact tap-to-cycle button for commentary language (SA → EN → HI).
class CommentaryLanguageCycleButton extends StatelessWidget {
  final List<String> availableLanguageCodes;
  final String selectedLanguageCode;
  final VoidCallback onCycle;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? backgroundColor;

  const CommentaryLanguageCycleButton({
    super.key,
    required this.availableLanguageCodes,
    required this.selectedLanguageCode,
    required this.onCycle,
    this.foregroundColor,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (availableLanguageCodes.length <= 1) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final fg = foregroundColor ?? theme.textTheme.bodyMedium?.color;
    final border = borderColor ?? fg?.withValues(alpha: 0.2);
    final bg = backgroundColor ?? fg?.withValues(alpha: 0.06);
    final label = commentaryLanguageShortLabel(selectedLanguageCode);
    final fullLabel = commentaryLanguageLabel(selectedLanguageCode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onCycle,
        borderRadius: BorderRadius.circular(18),
        child: Tooltip(
          message: 'Language: $fullLabel — tap to switch',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border ?? Colors.black12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.notoSerif(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                    letterSpacing: 0.5,
                  ),
                ),
                if (availableLanguageCodes.length > 1) ...[
                  const SizedBox(width: 3),
                  Icon(
                    Icons.autorenew,
                    size: 13,
                    color: fg?.withValues(alpha: 0.55),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Commentary author picker with icon + short name in one compact pill.
class CommentaryAuthorMenuButton extends StatelessWidget {
  final List<String> authors;
  final String selectedAuthor;
  final ValueChanged<String> onAuthorSelected;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? backgroundColor;

  const CommentaryAuthorMenuButton({
    super.key,
    required this.authors,
    required this.selectedAuthor,
    required this.onAuthorSelected,
    this.foregroundColor,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (authors.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final fg = foregroundColor ?? theme.textTheme.bodyMedium?.color;
    final border = borderColor ?? fg?.withValues(alpha: 0.2);
    final bg = backgroundColor ?? fg?.withValues(alpha: 0.06);
    final shortName = commentaryAuthorShortName(selectedAuthor);

    return PopupMenuButton<String>(
      tooltip: 'Commentary: $selectedAuthor',
      initialValue: selectedAuthor,
      onSelected: onAuthorSelected,
      position: PopupMenuPosition.under,
      itemBuilder: (context) {
        return authors.map((author) {
          return PopupMenuItem(
            value: author,
            child: Text(
              author,
              style: GoogleFonts.notoSerif(fontSize: 14),
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border ?? Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 16, color: fg),
            const SizedBox(width: 5),
            Text(
              shortName,
              style: GoogleFonts.notoSerif(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: fg?.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal chips to pick commentary language (Sanskrit / English / Hindi).
class CommentaryLanguageSwitcher extends StatelessWidget {
  final List<String> availableLanguageCodes;
  final String selectedLanguageCode;
  final ValueChanged<String> onLanguageSelected;

  const CommentaryLanguageSwitcher({
    super.key,
    required this.availableLanguageCodes,
    required this.selectedLanguageCode,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableLanguageCodes.length <= 1) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              'Language',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...availableLanguageCodes.map((code) {
            final isSelected =
                code.toLowerCase() == selectedLanguageCode.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(commentaryLanguageLabel(code)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) onLanguageSelected(code);
                },
                selectedColor: theme.colorScheme.primary,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.textTheme.bodyMedium?.color,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.transparent
                        : theme.dividerColor.withValues(alpha: 0.15),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
