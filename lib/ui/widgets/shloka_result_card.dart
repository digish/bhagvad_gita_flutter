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
import 'dart:ui';

class ShlokaResultCard extends StatelessWidget {
  final ShlokaResult shloka;
  final String searchQuery;
  final double? score;

  const ShlokaResultCard({
    super.key,
    required this.shloka,
    required this.searchQuery,
    this.score,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = Provider.of<SettingsProvider>(context);
    final isSimpleTheme = !settings.showBackground;

    // --- 1. Main Shloka Text (Always Visible) ---
    String mainShlokaText = shloka.shlok;
    mainShlokaText = mainShlokaText
        .replaceAll(RegExp(r'<c>', caseSensitive: false), '')
        .replaceAll('*', ' ');

    // --- 2. Determines Logic Mode ---
    bool isAiMode =
        shloka.matchSnippet != null &&
        shloka.matchSnippet!.contains("Confidence:");

    // Variables for the Result "Snippet" (The context below the shloka)
    String? snippetContent;
    String? snippetSource;
    String? aiDebugInfo; // Only for AI

    if (isAiMode) {
      // --- AI MODE LOGIC ---
      final parts = shloka.matchSnippet!.split('\n');
      if (parts.isNotEmpty) {
        aiDebugInfo = parts[0]; // e.g. "Confidence: 54.9% | Matches: 29"
        if (parts.length > 1) {
          String secondLine = parts.sublist(1).join('\n');
          if (secondLine.contains("Match:")) {
            final splitContent = secondLine.split("Match:");
            snippetSource = splitContent[0].trim();
            snippetContent = splitContent
                .sublist(1)
                .join("Match:")
                .replaceAll('"', '')
                .trim();
            if (snippetContent!.startsWith("Context: ")) {
              snippetContent = snippetContent!.replaceFirst("Context: ", "");
            }
          } else {
            snippetSource = secondLine;
          }
        }
      }
    } else {
      // --- NON-AI (FTS) MODE LOGIC ---
      // Determine what to show in the snippet box based on where the match happened
      if (shloka.matchedCategory != null) {
        final category = shloka.matchedCategory!.toLowerCase();

        if (category == 'anvay') {
          snippetSource = "ANVAY";
          snippetContent = shloka.anvay;
        } else if (['meaning', 'bhavarth'].contains(category)) {
          snippetSource = "MEANING";
          // Use matchSnippet if generated (contextual), else fallback to full bhavarth
          snippetContent =
              (shloka.matchSnippet != null && shloka.matchSnippet!.isNotEmpty)
              ? shloka.matchSnippet
              : shloka.bhavarth;
        } else if (category.contains('commentary') ||
            category.contains('tika') ||
            category.contains('ramanuj')) {
          snippetSource = "COMMENTARY";
          snippetContent =
              shloka.matchSnippet ?? "Content matched in commentary";
        } else if (category == 'shlok') {
          // Match is in the shloka itself, no snippet needed
          snippetContent = null;
        }
      }
    }

    final termsToHighlight =
        (shloka.matchedWords != null && shloka.matchedWords!.isNotEmpty)
        ? shloka.matchedWords!
        : [searchQuery];

    // Theme Colors
    final cardColor = isSimpleTheme
        ? Colors.white.withOpacity(0.9)
        : Colors.grey[900]!.withOpacity(0.85);
    final borderColor = isSimpleTheme
        ? Colors.pink.withOpacity(0.1)
        : const Color(0xFFFFD700).withOpacity(0.3);
    final titleColor = isSimpleTheme
        ? const Color(0xFF880E4F)
        : const Color(0xFFFFD700);
    final textColor = isSimpleTheme
        ? Colors.brown.shade900
        : Colors.white.withOpacity(0.9);
    final highlightColor = isSimpleTheme
        ? const Color(0xFFD81B60)
        : const Color(0xFFFFD700);
    final snippetBgColor = isSimpleTheme
        ? Colors.orange.withOpacity(0.08)
        : Colors.black.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isSimpleTheme
              ? [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: borderColor, width: 1),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Chapter ${shloka.chapterNo}, Shloka ${shloka.shlokNo}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          // Display appropriate badge
                          if (isAiMode && aiDebugInfo != null)
                            _buildAIInfoBadge(aiDebugInfo!, titleColor)
                          else if (score != null)
                            _buildScoreBadge(score!, isSimpleTheme, titleColor),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- MAIN SHLOKA TEXT ---
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: textColor,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'NotoSerifDevanagari',
                          ),
                          children: buildHighlightedText(
                            mainShlokaText,
                            termsToHighlight,
                            highlightColor,
                            isSimpleTheme,
                          ),
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // --- SNIPPET BOX (AI Match or Non-AI Context) ---
                      if (snippetContent != null &&
                          snippetContent!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: snippetBgColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: titleColor.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Source Label
                              Row(
                                children: [
                                  Icon(
                                    isAiMode
                                        ? Icons.auto_awesome
                                        : Icons.menu_book_rounded,
                                    size: 12,
                                    color: titleColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    snippetSource?.toUpperCase() ?? "MATCH",
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Snippet Text
                              RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: textColor.withOpacity(0.85),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  children: buildHighlightedText(
                                    snippetContent!,
                                    termsToHighlight,
                                    highlightColor,
                                    isSimpleTheme,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildAIInfoBadge(String debugInfo, Color color) {
    // Expected format: "Confidence: 54.9% | Matches: 29"
    String label = "Match";
    try {
      final parts = debugInfo.split('|');
      final percentStr = parts[0]
          .replaceAll('Confidence:', '')
          .replaceAll('%', '')
          .trim();
      final percent = double.tryParse(percentStr) ?? 0.0;

      // Extract Matches count if available
      String matchesCountStr = "";
      if (parts.length > 1) {
        final countVal = parts[1].replaceAll('Matches:', '').trim();
        matchesCountStr = " • $countVal Vecs"; // " • 29 Vecs"
      }

      // Reconstruct label with logic
      label = "${percent.toStringAsFixed(0)}%$matchesCountStr";
    } catch (e) {
      // Fallback
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  List<TextSpan> buildHighlightedText(
    String text,
    List<String> terms,
    Color highlightColor,
    bool isSimpleTheme,
  ) {
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
            backgroundColor: isSimpleTheme
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

  Widget _buildScoreBadge(double score, bool isSimpleTheme, Color titleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isSimpleTheme
            ? Colors.black.withOpacity(0.05)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${(score * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: titleColor.withOpacity(0.8),
        ),
      ),
    );
  }
}
