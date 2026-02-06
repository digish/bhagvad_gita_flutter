/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*
*  The sacred text of the Bhagavad Gita, as presented herein, is in the public domain. Translations, interpretations, UI elements, and artistic representations created by the developer are protected under copyright law.
*
*  This app is offered in the spirit of dharma and shared learning. You are welcome to use, modify, and distribute the source code under the terms of the MIT License. However, please preserve the integrity of the spiritual message and credit the original contributors where due.
*
*  For licensing details, see the LICENSE file in the repository.
*
**/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/shloka_result.dart';
import '../../navigation/app_router.dart';
import '../../providers/settings_provider.dart';
import '../../ui/theme/app_colors.dart';
import 'dart:ui';

class ShlokaResultCard extends StatelessWidget {
  final ShlokaResult shloka;
  final String searchQuery;
  final bool isCompact;

  const ShlokaResultCard({
    super.key,
    required this.shloka,
    required this.searchQuery,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;

    String displayShlok = shloka.shlok;
    final List<String> snippets = [];

    // Contextual Display Logic: Combine all matched snippets
    if (shloka.categorySnippets != null &&
        shloka.categorySnippets!.isNotEmpty) {
      final order = ['shloka', 'anvay', 'meaning', 'bhavarth'];
      for (final cat in order) {
        if (shloka.categorySnippets!.containsKey(cat)) {
          final s = shloka.categorySnippets![cat]!;
          final prefix = cat == 'shloka'
              ? 'Verse'
              : (cat[0].toUpperCase() + cat.substring(1));
          snippets.add("$prefix: $s");
        }
      }
    }

    if (snippets.isNotEmpty) {
      displayShlok = snippets.join('\n\n');
    } else if (shloka.matchedCategory != null && shloka.matchSnippet != null) {
      // Fallback for legacy items without categorySnippets map
      displayShlok = shloka.matchSnippet!;
    }

    displayShlok = displayShlok
        .replaceAll(RegExp(r'<c>', caseSensitive: false), '\n')
        .replaceAll('*', '\n');

    final termsToHighlight =
        (shloka.matchedWords != null && shloka.matchedWords!.isNotEmpty)
        ? shloka.matchedWords!
        : [searchQuery];

    // Theme-based styling
    final appColors = Theme.of(context).extension<AppColors>();
    final cardColor = isSimpleLight
        ? Colors.white.withOpacity(0.6)
        : Colors.grey[900]!.withOpacity(0.7);

    // In "Non-Simple" Light Mode (Fancy Mode), we use a Dark Card on a Pink Background.
    // So we must use Dark Theme colors (Gold/White) for contrast, not AppColors.light (Pink/Brown).
    final forceDarkColors =
        !isSimpleLight && Theme.of(context).brightness == Brightness.light;

    final borderColor = forceDarkColors
        ? const Color(0xFFFFD700).withOpacity(0.5)
        : (appColors?.cardBorder ??
              (isSimpleLight
                  ? Colors.pink.withOpacity(0.2)
                  : const Color(0xFFFFD700).withOpacity(0.5)));

    final titleColor = forceDarkColors
        ? const Color(0xFFFFD700)
        : (appColors?.cardTitle ??
              (isSimpleLight
                  ? Colors.pink.shade900.withOpacity(0.8)
                  : const Color(0xFFFFD700)));

    final textColor = forceDarkColors
        ? Colors.white.withOpacity(0.85)
        : (appColors?.cardText ??
              (isSimpleLight
                  ? Colors.brown.shade900
                  : Colors.white.withOpacity(0.85)));

    final highlightColor = forceDarkColors
        ? const Color(0xFFFFD700)
        : (appColors?.highlightColor ??
              (isSimpleLight
                  ? const Color(0xFFD81B60)
                  : const Color(0xFFFFD700)));

    List<TextSpan> buildHighlightedText(String text, List<String> terms) {
      if (terms.isEmpty) return [TextSpan(text: text)];
      final spans = <TextSpan>[];
      final lowerText = text.toLowerCase();
      final ranges = <({int start, int end})>[];

      for (final term in terms) {
        final lowerTerm = term.toLowerCase();
        if (lowerTerm.isEmpty) continue;
        int start = 0;
        while (true) {
          final idx = lowerText.indexOf(lowerTerm, start);
          if (idx == -1) break;
          ranges.add((start: idx, end: idx + term.length));
          start = idx + 1;
        }
      }

      ranges.sort((a, b) => a.start.compareTo(b.start));
      final merged = <({int start, int end})>[];
      for (final r in ranges) {
        if (merged.isEmpty) {
          merged.add(r);
        } else {
          final last = merged.last;
          if (r.start < last.end) {
            if (r.end > last.end) {
              merged[merged.length - 1] = (start: last.start, end: r.end);
            }
          } else {
            merged.add(r);
          }
        }
      }

      int currentPos = 0;
      for (final r in merged) {
        if (r.start > currentPos) {
          spans.add(TextSpan(text: text.substring(currentPos, r.start)));
        }
        spans.add(
          TextSpan(
            text: text.substring(r.start, r.end),
            style: TextStyle(
              color: highlightColor,
              fontWeight: FontWeight.bold,
              backgroundColor: isSimpleLight
                  ? highlightColor.withOpacity(0.1)
                  : Colors.transparent,
            ),
          ),
        );
        currentPos = r.end;
      }
      if (currentPos < text.length) {
        spans.add(TextSpan(text: text.substring(currentPos)));
      }
      return spans;
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 16,
        vertical: isCompact ? 4 : 6,
      ),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isSimpleLight
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: InkWell(
                onTap: () {
                  context.push(
                    AppRoutes.shlokaDetail.replaceFirst(
                      ':id',
                      shloka.id.toString(),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: isCompact ? 10 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chapter ${shloka.chapterNo}, Shloka ${shloka.shlokNo}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: isCompact ? 4 : 8),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: isCompact ? 14 : 15,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                          children: buildHighlightedText(
                            displayShlok,
                            termsToHighlight,
                          ),
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
