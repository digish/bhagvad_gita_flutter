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
import '../../models/shloka_result.dart';
import '../../navigation/app_router.dart';
import 'dart:ui';

class ShlokaResultCard extends StatelessWidget {
  final ShlokaResult shloka;
  final String searchQuery;

  const ShlokaResultCard({
    super.key,
    required this.shloka,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String displayShlok = shloka.shlok;

    // Contextual Display Logic
    if (shloka.matchedCategory != null && shloka.matchSnippet != null) {
      // If matched in Meaning or Bhavarth, show the snippet
      if ([
        'meaning',
        'bhavarth',
      ].contains(shloka.matchedCategory!.toLowerCase())) {
        displayShlok = shloka.matchSnippet!;
      }
      // If matched in Anvay, show Anvay
      else if (shloka.matchedCategory!.toLowerCase() == 'anvay') {
        displayShlok = shloka.anvay;
      }
    }

    // Cleanup cleaning logic
    displayShlok = displayShlok
        .replaceAll(RegExp(r'<c>', caseSensitive: false), '')
        .replaceAll('*', ' ');

    // Use matched words from DB if available, otherwise fallback to query
    final termsToHighlight =
        (shloka.matchedWords != null && shloka.matchedWords!.isNotEmpty)
        ? shloka.matchedWords!
        : [searchQuery];

    List<TextSpan> buildHighlightedText(String text, List<String> terms) {
      if (terms.isEmpty) return [TextSpan(text: text)];

      final spans = <TextSpan>[];
      final lowerText = text.toLowerCase();

      // We need to find all occurrences of all terms and sort them by position
      // List of (start, end) ranges
      final ranges = <({int start, int end})>[];

      for (final term in terms) {
        final lowerTerm = term.toLowerCase();
        if (lowerTerm.isEmpty) continue;

        int start = 0;
        while (true) {
          final idx = lowerText.indexOf(lowerTerm, start);
          if (idx == -1) break;
          ranges.add((start: idx, end: idx + term.length));
          start = idx + 1; // Overlap check? Let's just step 1 char
        }
      }

      // Sort ranges by start position
      ranges.sort((a, b) => a.start.compareTo(b.start));

      // Merge overlapping ranges
      final merged = <({int start, int end})>[];
      for (final r in ranges) {
        if (merged.isEmpty) {
          merged.add(r);
        } else {
          final last = merged.last;
          if (r.start < last.end) {
            // Overlap
            if (r.end > last.end) {
              // Extend
              merged[merged.length - 1] = (start: last.start, end: r.end);
            }
          } else {
            merged.add(r);
          }
        }
      }

      // Build spans
      int currentPos = 0;
      for (final r in merged) {
        if (r.start > currentPos) {
          spans.add(TextSpan(text: text.substring(currentPos, r.start)));
        }
        spans.add(
          TextSpan(
            text: text.substring(r.start, r.end),
            style: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]!.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: const Color(0xFFFFD700), // Golden border
                width: 1.2,
              ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chapter ${shloka.chapterNo}, Shloka ${shloka.shlokNo}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFD700), // Golden accent
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        children: buildHighlightedText(
                          displayShlok,
                          termsToHighlight,
                        ),
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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
}
