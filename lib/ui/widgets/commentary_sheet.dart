import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/shloka_result.dart';

class CommentarySheet extends StatefulWidget {
  final List<Commentary> commentaries;
  final String chapterNo;
  final String shlokNo;

  const CommentarySheet({
    super.key,
    required this.commentaries,
    required this.chapterNo,
    required this.shlokNo,
  });

  @override
  State<CommentarySheet> createState() => _CommentarySheetState();
}

class _CommentarySheetState extends State<CommentarySheet> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- NEW: Read Settings ---
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final preferredScript = settings.script;
    final preferredLang = settings.language; // 'hi' or 'en'

    // --- NEW: Group and Select Best Commentary ---
    // 1. Group by Author Name
    final Map<String, List<Commentary>> groupedByAuthor = {};
    for (var c in widget.commentaries) {
      if (c.content.isNotEmpty) {
        groupedByAuthor.putIfAbsent(c.authorName, () => []).add(c);
      }
    }

    final List<Commentary> displayCommentaries = [];

    // 2. Filter and Select Variants
    groupedByAuthor.forEach((authorName, variants) {
      // Filter based on Settings
      final type = _getCommentaryType(authorName);
      if (!settings.showClassicalCommentaries &&
          type == 'Big Three (Classical)') {
        return; // Skip this author
      }

      // Add SINGLE best variant for the author
      Commentary? bestMatch;

      // 1. Try User's Preferred Script (e.g. 'gu' for Gujarati)
      try {
        bestMatch = variants.firstWhere(
          (c) => c.languageCode == preferredScript,
        );
      } catch (_) {}

      // 2. Try User's Preferred Language (Logic varies by language)
      if (bestMatch == null) {
        if (preferredLang == 'en') {
          // If User wants English, try English
          try {
            bestMatch = variants.firstWhere((c) => c.languageCode == 'en');
          } catch (_) {}
        } else if (preferredLang == 'hi') {
          // If User wants Hindi
          // Try Hindi
          try {
            bestMatch = variants.firstWhere((c) => c.languageCode == 'hi');
          } catch (_) {
            // If Hindi missing, try Sanskrit (User preference for Classical fallbacks)
            try {
              bestMatch = variants.firstWhere((c) => c.languageCode == 'sa');
            } catch (_) {}
          }
        }
      }

      // 3. Fallbacks
      if (bestMatch == null) {
        // Try English
        try {
          bestMatch = variants.firstWhere((c) => c.languageCode == 'en');
        } catch (_) {}
      }
      if (bestMatch == null) {
        // Try Sanskrit
        try {
          bestMatch = variants.firstWhere((c) => c.languageCode == 'sa');
        } catch (_) {}
      }

      // 4. Last Resort
      bestMatch ??= variants.first;

      displayCommentaries.add(bestMatch);
    });

    if (displayCommentaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded, size: 48, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text(
              "No commentaries available for this shloka.",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      );
    }

    // Ensure index validity if list changed
    if (_selectedIndex >= displayCommentaries.length) {
      _selectedIndex = 0;
    }

    final selectedCommentary = displayCommentaries[_selectedIndex];

    // Helper to handle rail width manually for overlays
    // We only apply this if we are SURE the rail is showing and overlapping.
    // However, on iPhones, the rail might be hidden. SafeArea is safer.
    // If the sheet is width constrained, we don't want to squeeze content.
    // ✨ FIX: Widen layout for iPad (900px) and center it
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.85)
                    : Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.05),
                  ),
                ),
              ),
              child: SafeArea(
                left: false, // Prevent system rail padding issues
                top: false,
                right: false,
                bottom: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Commentary",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSerif',
                                  ),
                                ),
                                Text(
                                  "Chapter ${widget.chapterNo}, Shloka ${widget.shlokNo}",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Author Tabs
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: List.generate(displayCommentaries.length, (
                          index,
                        ) {
                          final comm = displayCommentaries[index];
                          final isSelected = index == _selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                "${comm.authorName} (${comm.languageCode.toUpperCase()})",
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (bool selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                }
                              },
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.transparent
                                      : theme.dividerColor.withOpacity(0.1),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    const Divider(height: 1),

                    // Content Area
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metadata Row
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.dividerColor.withOpacity(0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.language,
                                    size: 16,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getLanguageDisplayName(
                                      selectedCommentary.languageCode,
                                    ),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.timeline, // Or category icon
                                    size: 16,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getCommentaryType(
                                      selectedCommentary.authorName,
                                    ),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              selectedCommentary.content,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 18,
                                height: 1.8,
                                fontFamily: 'NotoSerif',
                                color: theme.textTheme.bodyLarge?.color
                                    ?.withOpacity(0.9),
                              ),
                            ),
                            const SizedBox(height: 48), // Bottom padding
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    switch (code.toLowerCase()) {
      case 'en':
      case 'ro':
        return 'English';
      case 'hi':
      case 'dev':
        return 'Hindi';
      case 'sa':
        return 'Sanskrit';
      case 'gu':
        return 'Gujarati';
      case 'te':
        return 'Telugu';
      case 'bn':
        return 'Bengali';
      case 'or':
      case 'od':
        return 'Odia';
      default:
        return code.toUpperCase();
    }
  }

  String _getCommentaryType(String author) {
    final name = author.toLowerCase();

    // The Big Three (Acharyas)
    if (name.contains('shankar') || // Adil Shankaracharya
        name.contains('ramanuj') || // Ramanujacharya
        name.contains('madhv') || // Madhvacharya
        name.contains('vallabh') || // Vallabhacharya
        name.contains('nimbark')) {
      // Nimbarkacharya
      return 'Big Three (Classical)';
    }

    // Modern Seekers / Commentators
    if (name.contains('gandhi') ||
        name.contains('chinmayananda') ||
        name.contains('ramsukhdas') ||
        name.contains('vinoba') ||
        name.contains('aurobindo') ||
        name.contains('sivananda') ||
        name.contains('purohit') ||
        name.contains('goyandka') ||
        name.contains('prabhupada') ||
        name.contains('osho')) {
      return 'Modern Seeker';
    }

    // Classical Bhakti / Others
    if (name.contains('sridhara') ||
        name.contains('madhusudan') ||
        name.contains('vishvanath') ||
        name.contains('keshav')) {
      return 'Classical Commentary';
    }

    return 'Standard Commentary';
  }
}
