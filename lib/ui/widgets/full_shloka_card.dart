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
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import '../../models/shloka_result.dart';
import '../../providers/audio_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../services/analytics_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../widgets/sneaky_emblem.dart';
import 'karaoke_text_display.dart';
import 'add_to_list_sheet.dart';
import 'share_options_sheet.dart';
import 'commentary_sheet.dart';
import 'chapter_seek_rail.dart';
import '../../providers/settings_provider.dart';
import '../../data/static_data.dart';
import '../theme/app_colors.dart';
import '../theme/chapter_reading_colors.dart';

// --- NEW: Configurable variable to control font sizing logic ---
const bool _enableDynamicFontSizing = false;

class FullShlokaCard extends StatelessWidget {
  final ShlokaResult shloka;
  final FullShlokaCardConfig config;
  final String? currentlyPlayingId; // The reliable ID from the parent screen
  final VoidCallback? onPlayPause; // Callback for when play/pause is pressed
  final VoidCallback? onTap;
  final bool isFocused;

  const FullShlokaCard({
    super.key,
    required this.shloka,
    this.config = const FullShlokaCardConfig(),
    this.currentlyPlayingId,
    this.onPlayPause,
    this.onTap,
    this.isFocused = false,
  });

  // This is your existing text formatting logic, it remains unchanged.
  List<TextSpan> formatItalicText(
    String rawText,
    TextStyle baseStyle,
    double maxWidth, {
    bool shrinkToFit = false,
  }) {
    final isFourLine = rawText.contains('<C>');
    final allLines = KaraokeTextDisplay.displayLinesFromRaw(rawText);

    // --- ✨ NEW LOGIC: Step 1 - Find the single smallest font size needed for the whole block ---
    double uniformFontSize = baseStyle.fontSize ?? 20;

    // --- MODIFIED: Use the configurable variable to control the logic ---
    if (_enableDynamicFontSizing || shrinkToFit) {
      for (final line in allLines) {
        if (uniformFontSize <= 12) break; // Don't shrink further

        TextPainter painter;
        do {
          painter = TextPainter(
            text: TextSpan(
              text: line,
              style: baseStyle.copyWith(fontSize: uniformFontSize),
            ),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: double.infinity);

          if (painter.width > maxWidth) {
            uniformFontSize -= 1;
          } else {
            break; // This line fits, move to the next line
          }
        } while (painter.width > maxWidth && uniformFontSize > 12);
      }
    }

    // --- ✨ NEW LOGIC: Step 2 - Build the TextSpans using the uniform font size ---
    final spans = <TextSpan>[];
    final adjustedStyle = baseStyle.copyWith(
      fontSize: uniformFontSize,
      height: 1.6,
      fontStyle: isFourLine ? FontStyle.italic : FontStyle.normal,
    );

    for (int i = 0; i < allLines.length; i++) {
      final line = allLines[i];
      final isLastLine = i == allLines.length - 1;
      final lineText = isLastLine ? line : '$line\n';
      spans.add(TextSpan(text: lineText, style: adjustedStyle));
    }

    return spans;
  }

  /// Split an overflowing verse line near the **middle** (balanced couplet look),
  /// not greedy end-orphans. Continuations are indented by the caller.
  static List<String> wrapVerseLine(
    String line,
    TextStyle style,
    double maxWidth,
  ) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return [line];
    if (_lineFits(trimmed, style, maxWidth)) return [trimmed];

    final breakAt = _balancedBreakIndex(trimmed);
    if (breakAt <= 0 || breakAt >= trimmed.length) {
      return _hardWrapVerseLine(trimmed, style, maxWidth);
    }

    var first = trimmed.substring(0, breakAt).trimRight();
    var second = trimmed.substring(breakAt).trimLeft();
    // Keep trailing danda / pipe with the previous chunk — orphan `|` / `।` / `॥`
    // on a continuation line reads as a "ghost" stroke under the next verse.
    final orphanPunct = RegExp(r'^[|\s।॥]+$');
    if (second.isNotEmpty && orphanPunct.hasMatch(second)) {
      first = '$first$second'.trimRight();
      second = '';
    }
    if (first.isEmpty) return wrapVerseLine(second, style, maxWidth);
    if (second.isEmpty) {
      if (_lineFits(first, style, maxWidth)) return [first];
      return _hardWrapVerseLine(first, style, maxWidth);
    }

    // Recurse if a half is still too wide (very large fonts).
    return [
      ...wrapVerseLine(first, style, maxWidth),
      ...wrapVerseLine(second, style, maxWidth),
    ];
  }

  /// Prefer a whitespace nearest the midpoint; else the midpoint itself.
  static int _balancedBreakIndex(String text) {
    if (text.length < 2) return -1;
    final mid = text.length ~/ 2;

    // Search outward from midpoint for a space / Devanagari danda pause.
    // Include double-danda; do not break so the next chunk is only punctuation.
    final breakChars = RegExp(r'[\s।|॥]');
    var best = -1;
    var bestDist = 1 << 30;
    for (var i = 0; i < text.length; i++) {
      if (!breakChars.hasMatch(text[i])) continue;
      // Don't break at leading/trailing edge.
      if (i == 0 || i >= text.length - 1) continue;
      final after = text.substring(i + 1).trimLeft();
      if (after.isEmpty || RegExp(r'^[|\s।॥]+$').hasMatch(after)) continue;
      final dist = (i - mid).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = i + 1; // break after the separator
      }
    }
    if (best > 0 && best < text.length) return best;
    return mid;
  }

  static bool _lineFits(String text, TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    // Safety margin: TextPainter vs on-screen glyphs (letterSpacing / subpixel)
    // can disagree by a px or two; softWrap:false then bleeds trailing danda.
    return painter.width <= maxWidth - 2.0;
  }

  /// Verse spans with drop shadow on letters, but none on `|` / `।` / `॥`
  /// (thin danda shadows paint as detached ghost strokes).
  static List<InlineSpan> verseSpansSkipDandaShadow(
    String text,
    TextStyle style,
  ) {
    if (text.isEmpty) return [TextSpan(text: text, style: style)];
    final plain = style.copyWith(shadows: const <Shadow>[]);
    final spans = <InlineSpan>[];
    final danda = RegExp(r'[|।॥]+');
    var start = 0;
    for (final match in danda.allMatches(text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(text: text.substring(start, match.start), style: style),
        );
      }
      spans.add(TextSpan(text: match.group(0), style: plain));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    if (spans.isEmpty) spans.add(TextSpan(text: text, style: style));
    return spans;
  }

  static List<String> _hardWrapVerseLine(
    String line,
    TextStyle style,
    double maxWidth,
  ) {
    // Balanced hard wrap: keep splitting near midpoint until each piece fits.
    final trimmed = line.trim();
    if (trimmed.isEmpty) return [line];
    if (_lineFits(trimmed, style, maxWidth)) return [trimmed];
    if (trimmed.length < 4) return [trimmed];

    final mid = trimmed.length ~/ 2;
    final first = trimmed.substring(0, mid).trimRight();
    final second = trimmed.substring(mid).trimLeft();
    if (first.isEmpty || second.isEmpty) return [trimmed];
    return [
      ..._hardWrapVerseLine(first, style, maxWidth),
      ..._hardWrapVerseLine(second, style, maxWidth),
    ];
  }

  Color getSpeakerColor(String? speaker, {bool isLightTheme = false}) {
    final palette = ChapterReadingColors.of(
      isLightTheme ? Brightness.light : Brightness.dark,
    );
    return palette.speakerTint(speaker);
  }

  // --- NEW: Share functionality with Options ---
  Future<void> _shareShloka(BuildContext context) async {
    // Show the options sheet first
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // ✨ Ensure it overlays the rail
      backgroundColor: Colors.transparent,
      builder: (context) => ShareOptionsSheet(
        showAudioOption: true, // Allow audio for individual shloka
        onShare: (selectedOptions) => _executeShare(context, selectedOptions),
        onCreateImage: () {
          context.push(
            AppRoutes.imageCreator,
            extra: {
              'text': shloka.shlok,
              'translation': shloka.bhavarth,
              'source': 'Chapter ${shloka.chapterNo}.${shloka.shlokNo}',
            },
          );
        },
      ),
    );
  }

  Future<void> _executeShare(
    BuildContext context,
    Set<ShareOption> options,
  ) async {
    final shlokaIdentifier =
        'Shrimad Bhagavad Gita\nअध्याय ${shloka.chapterNo}, श्लोक ${shloka.shlokNo}';

    // Helper to format text
    String formatText(String text) {
      return text
          .replaceAll('<C>', '\n')
          .replaceAll('*', '\n')
          .replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥')
          .trim();
    }

    final buffer = StringBuffer();
    buffer.writeln(shlokaIdentifier);
    buffer.writeln();

    // Speaker
    if (shloka.speaker != null && shloka.speaker!.isNotEmpty) {
      buffer.writeln(
        '${StaticData.localizeSpeaker(shloka.speaker, Provider.of<SettingsProvider>(context, listen: false).script)}:',
      );
    }

    // Shloka Text (Mandatory)
    buffer.writeln(formatText(shloka.shlok));

    // Anvay
    if (options.contains(ShareOption.anvay) && shloka.anvay.isNotEmpty) {
      buffer.writeln('\n---\n');
      buffer.writeln(
        '${StaticData.localizeTerm('anvay', Provider.of<SettingsProvider>(context, listen: false).script)}:',
      );
      buffer.writeln(formatText(shloka.anvay));
    }

    // Tika/Bhavarth
    if (options.contains(ShareOption.tika) && shloka.bhavarth.isNotEmpty) {
      buffer.writeln('\n---\n'); // Separator
      buffer.writeln(
        '${StaticData.localizeTerm('tika', Provider.of<SettingsProvider>(context, listen: false).script)}:',
      );
      buffer.writeln(shloka.bhavarth);
    }

    // Footer
    const String appLink =
        'https://digish.github.io/project/gita.html';
    buffer.writeln(
      '\n\n---\nShared from the Shrimad Bhagavad Gita app:\n$appLink',
    );

    final shareText = buffer.toString();

    AnalyticsService.instance.logShare(
      contentType: options.contains(ShareOption.audio)
          ? 'shloka_audio'
          : 'shloka_text',
      itemId: '${shloka.chapterNo}.${shloka.shlokNo}',
    );

    // Calculate share position origin for iPad
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    // Handle Audio sharing if selected
    if (options.contains(ShareOption.audio)) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final audioPath = await audioProvider.getShlokaAudioPath(shloka);

      if (audioPath != null) {
        String? validFilePath;
        if (audioPath.startsWith('assets/')) {
          try {
            final byteData = await rootBundle.load(audioPath);
            final tempDir = await getTemporaryDirectory();

            // Create a descriptive filename for better sharing experience
            // Use .ogg extension for compatibility
            final fileName =
                'BhagavadGita_Ch${shloka.chapterNo}_Sh${shloka.shlokNo}.ogg';
            final tempFile = File('${tempDir.path}/$fileName');
            await tempFile.writeAsBytes(byteData.buffer.asUint8List());
            validFilePath = tempFile.path;
          } catch (e) {
            debugPrint('Error preparing asset for share: $e');
          }
        } else {
          validFilePath = audioPath;
        }

        if (validFilePath != null && await File(validFilePath).exists()) {
          await SharePlus.instance.share(
            ShareParams(
              // Use application/octet-stream to force "Document" handling (attachment style)
              files: [
                XFile(validFilePath, mimeType: 'application/octet-stream'),
              ],
              text: shareText,
              subject: shlokaIdentifier,
              sharePositionOrigin: sharePositionOrigin,
            ),
          );
          return;
        }
      }
    }

    // Fallback or Text Only Share
    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: shlokaIdentifier,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  // --- MODIFIED buildCardContent ---
  // It now accepts audio state to handle highlighting and passing data to the button
  Widget buildCardContent(
    BuildContext context, {
    required AudioProvider audioProvider,
    required bool isPlayingThisShloka,
    required PlaybackState playbackState,
    required AssetPackStatus downloadStatus,
  }) {
    final theme = Theme.of(context);
    final bool isLightTheme = config.isLightTheme;
    final bool continuous = config.continuousReading;
    final speakerColor = getSpeakerColor(
      shloka.speaker,
      isLightTheme: isLightTheme,
    );
    final readingPalette = ChapterReadingColors.of(theme.brightness);
    final Color primaryTextColor = continuous
        ? readingPalette.shloka
        : (isLightTheme ? Colors.black87 : Colors.white);
    final Color secondaryTextColor = isLightTheme
        ? Colors.black54
        : Colors.white.withOpacity(0.85);
    final Color accentColor = isLightTheme
        ? const Color(0xFFD84315)
        : const Color(0xFFFFD700);
    final bool chapterChrome = config.preserveCardChrome;
    // Continuous: layout stays identical when focused — only the border paints.
    final bool showAsCard = chapterChrome || !continuous || isFocused;
    final Color cardBackgroundColor = continuous && !chapterChrome
        ? (isLightTheme
              ? Colors.white.withOpacity(0.45)
              : Colors.white.withOpacity(0.10))
        : (isLightTheme
              ? Colors.white.withOpacity(0.6)
              : Colors.white.withOpacity(0.07));
    final Color mainBorderColor = isLightTheme
        ? Colors.grey.shade400
        : const Color(0xFFFFD700);
    final Color innerCardBorderColor = isLightTheme
        ? Colors.black.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);
    // Continuous Parayan: bright gold selection (matches app highlight gold).
    final focusAccent = continuous && !chapterChrome
        ? const Color(0xFFFFD700)
        : (Theme.of(context).extension<AppColors>()?.gitaBlue ??
              const Color(0xFF047BC0));

    final cardBody = Padding(
      padding: EdgeInsets.symmetric(
        // Fixed insets in continuous mode so focus never reflows the verse.
        horizontal: continuous && !chapterChrome ? 16.0 : 5.0,
        vertical: continuous && !chapterChrome ? 4.0 : 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        padding: continuous && !chapterChrome
                            ? EdgeInsets.zero
                            : (config.spacingCompact
                                  ? const EdgeInsets.all(1)
                                  : const EdgeInsets.all(4)),
                        decoration: BoxDecoration(
                          color: config.showColoredCard
                              ? speakerColor
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: config.showColoredCard
                                ? innerCardBorderColor
                                : Colors.transparent,
                            width: config.showColoredCard ? 1 : 0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!continuous ||
                                config.showSpeaker ||
                                chapterChrome)
                              Row(
                                mainAxisAlignment: continuous && !chapterChrome
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.spaceBetween,
                                children: [
                                  // 1. Speaker Name (Left)
                                  if (config.showSpeaker &&
                                      shloka.speaker != null &&
                                      shloka.speaker!.isNotEmpty)
                                    Expanded(
                                      child: Text(
                                        // Localize speaker
                                        '${StaticData.localizeSpeaker(shloka.speaker, Provider.of<SettingsProvider>(context).script)}:',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: primaryTextColor
                                                  .withOpacity(0.9),
                                              letterSpacing: 0.5,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (!continuous || chapterChrome)
                                    const SizedBox(width: 8),
                                  // 2. Chapter & Shloka Index (non-continuous cards)
                                  if ((!continuous || chapterChrome) &&
                                      config.showShlokIndex)
                                    Builder(
                                      builder: (context) {
                                        final script =
                                            Provider.of<SettingsProvider>(
                                              context,
                                            ).script;
                                        final chapLabel =
                                            StaticData.getChapterLabel(script);
                                        // Localize numbers
                                        final chapNum =
                                            StaticData.localizeNumber(
                                              int.tryParse(shloka.chapterNo) ??
                                                  0,
                                              script,
                                            );
                                        final shlokNum =
                                            StaticData.localizeNumber(
                                              int.tryParse(shloka.shlokNo) ?? 0,
                                              script,
                                            );

                                        // Shloka label
                                        String vsLabel = 'Vs';
                                        if (script == 'dev' ||
                                            script == 'hi' ||
                                            script == 'mr') {
                                          vsLabel = 'श्लोक';
                                        } else if (script == 'gu') {
                                          vsLabel = 'શ્લોક';
                                        } else if (script == 'bn') {
                                          vsLabel = 'শ্লোক';
                                        } else if (script == 'te') {
                                          vsLabel = 'శ్లోక';
                                        }

                                        final text = config.spacingCompact
                                            ? '$chapNum:$shlokNum'
                                            : '$chapLabel $chapNum, $vsLabel $shlokNum';

                                        return Flexible(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: accentColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: accentColor.withOpacity(
                                                  0.3,
                                                ),
                                              ),
                                            ),
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                text,
                                                style: theme
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: accentColor,
                                                      letterSpacing: 0.6,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),

                            if ((!continuous &&
                                    (config.showSpeaker ||
                                        config.showShlokIndex)) ||
                                (continuous &&
                                    (config.showSpeaker ||
                                        (chapterChrome &&
                                            config.showShlokIndex))))
                              SizedBox(
                                height: continuous && !chapterChrome
                                    ? 4
                                    : (config.spacingCompact ? 8 : 16),
                              ),

                            // 3. Continuous list body: 1 / 2 / 3 items
                            // from layout count + view toggle (expand-on-select
                            // still shows all three on the focused card).
                            if (continuous)
                              _ContinuousVerseWithNumber(
                                shloka: shloka,
                                config: config,
                                primaryTextColor: primaryTextColor,
                                constraints: constraints,
                              )
                            else
                              KaraokeTextDisplay(
                                shlokaId:
                                    '${shloka.chapterNo}.${shloka.shlokNo}',
                                originalText: shloka.shlok,
                                style: TextStyle(
                                  fontSize: config.baseFontSize,
                                  fontStyle: FontStyle.normal,
                                  color: primaryTextColor,
                                  fontFamily: 'NotoSerif',
                                ),
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    children: formatItalicText(
                                      shloka.shlok,
                                      TextStyle(
                                        fontSize: config.baseFontSize,
                                        fontStyle: FontStyle.normal,
                                        color: primaryTextColor,
                                        fontFamily: 'NotoSerif',
                                      ),
                                      constraints.maxWidth - 32,
                                    ),
                                  ),
                                ),
                              ),

                          if (config.showActions)
                            SizedBox(height: continuous ? 10 : (config.spacingCompact ? 8 : 16)),

                          // 4. Action Row (Bottom)
                          if (config.showActions)
                            Center(
                              child: KeyedSubtree(
                                key: config.helpActionsRowKey,
                                child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isLightTheme
                                      ? Colors.grey.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          // Play Audio
                                          _buildAudioActionButton(
                                            context: context,
                                            shloka: shloka,
                                            isPlayingThis: isPlayingThisShloka,
                                            playbackState: playbackState,
                                            downloadStatus: downloadStatus,
                                            audioProvider: audioProvider,
                                          ),
                                          const SizedBox(width: 16),
                                          // Commentary
                                          if (shloka.commentaries == null ||
                                              shloka
                                                  .commentaries!
                                                  .isNotEmpty) ...[
                                            _ActionButton(
                                              icon: Icons.menu_book_rounded,
                                              onPressed: () {
                                                CommentarySheet.show(
                                                  context,
                                                  commentaries:
                                                      shloka.commentaries,
                                                  chapterNo: shloka.chapterNo,
                                                  shlokNo: shloka.shlokNo,
                                                );
                                              },
                                            ),
                                            const SizedBox(width: 16),
                                          ],

                                          // Bookmark
                                          Consumer<BookmarkProvider>(
                                            builder: (context, bookmarkProvider, _) {
                                              final isBookmarked =
                                                  bookmarkProvider.isBookmarked(
                                                    shloka.chapterNo,
                                                    shloka.shlokNo,
                                                  );
                                              return _ActionButton(
                                                icon: isBookmarked
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_outline,
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                    context: context,
                                                    useRootNavigator: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    isScrollControlled: true,
                                                    shape: const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                  16,
                                                                ),
                                                          ),
                                                    ),
                                                    builder: (context) =>
                                                        AddToListSheet(
                                                          chapterNo: shloka
                                                              .chapterNo,
                                                          shlokNo:
                                                              shloka.shlokNo,
                                                        ),
                                                  );
                                                },
                                                color: isBookmarked
                                                    ? theme.colorScheme.primary
                                                    : null,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 16),
                                          // Share
                                          Builder(
                                            builder: (btnContext) {
                                              return _ActionButton(
                                                icon: Icons.share_outlined,
                                                onPressed: () =>
                                                    _shareShloka(btnContext),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (!continuous && config.showMeaningsHint) ...[
                  SizedBox(height: config.spacingCompact ? 4 : 8),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${StaticData.localizeTerm('anvay', Provider.of<SettingsProvider>(context).script)}'
                          ' · '
                          '${StaticData.localizeTerm('tika', Provider.of<SettingsProvider>(context).script)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accentColor.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 18,
                          color: accentColor.withValues(alpha: 0.75),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!continuous &&
                    (config.showAnvay || config.showBhavarth))
                  SizedBox(height: config.spacingCompact ? 5 : 10),

                if (!continuous) ...[
                  if (config.showSeparator)
                    config.spacingCompact
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 2,
                            ),
                            child: Divider(
                              height: 1,
                              thickness: 0.8,
                              color: accentColor.withValues(alpha: 0.35),
                            ),
                          )
                        : Center(
                            child: SizedBox(
                              width: 150,
                              child: isLightTheme
                                  ? ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        Colors.grey[700]!,
                                        BlendMode.srcIn,
                                      ),
                                      child: Image.asset(
                                        'assets/images/line_seperator.png',
                                      ),
                                    )
                                  : Image.asset(
                                      'assets/images/line_seperator.png',
                                    ),
                            ),
                          ),
                  if (config.showSeparator)
                    config.spacingCompact
                        ? const SizedBox(height: 6)
                        : const SizedBox(height: 10),
                  if (config.showAnvay && shloka.anvay.isNotEmpty) ...[
                    Center(
                      child: Text(
                        StaticData.localizeTerm(
                          'anvay',
                          Provider.of<SettingsProvider>(context).script,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    config.spacingCompact
                        ? const SizedBox(height: 4)
                        : const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: formatItalicText(
                              shloka.anvay,
                              TextStyle(
                                fontSize: config.baseFontSize,
                                fontStyle: FontStyle.italic,
                                color: secondaryTextColor,
                                fontFamily: 'NotoSerif',
                                height: 1.6,
                              ),
                              constraints.maxWidth,
                            ),
                          ),
                        );
                      },
                    ),
                    config.spacingCompact
                        ? const SizedBox(height: 5)
                        : const SizedBox(height: 10),
                  ],
                  if (config.showBhavarth && shloka.bhavarth.isNotEmpty) ...[
                    Center(
                      child: Text(
                        StaticData.localizeTerm(
                          'tika',
                          Provider.of<SettingsProvider>(context).script,
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    config.spacingCompact
                        ? const SizedBox(height: 4)
                        : const SizedBox(height: 8),
                    Text(
                      shloka.bhavarth,
                      style: TextStyle(
                        fontSize: config.baseFontSize - 4,
                        fontStyle: FontStyle.normal,
                        color: secondaryTextColor,
                        fontFamily: 'NotoSerif',
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(
        // Continuous: fixed margin — focus must not change wrap width.
        horizontal: continuous && !chapterChrome
            ? 12
            : (isFocused ? 4 : 8),
        vertical: continuous && !chapterChrome
            ? 0
            : (isFocused ? 6 : 4),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          continuous && !chapterChrome ? 16.0 : 22.0,
        ),
        // Continuous Parayan: border-only selection — no fill/glow over the gradient.
        boxShadow: showAsCard && isFocused && (!continuous || chapterChrome)
            ? [
                BoxShadow(
                  color: focusAccent.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: focusAccent.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: continuous && !chapterChrome
          // Always the same box metrics; transparent border when idle so
          // selecting never reflows the verse lines.
          ? Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(
                  color: isFocused
                      ? focusAccent.withOpacity(0.85)
                      : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: cardBody,
            )
          : (showAsCard
              ? Container(
                  decoration: BoxDecoration(
                    color: cardBackgroundColor,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(
                      color: isFocused
                          ? focusAccent
                          : (isPlayingThisShloka &&
                                playbackState == PlaybackState.playing)
                          ? theme.colorScheme.primary
                          : mainBorderColor,
                      width: isFocused
                          ? 3.0
                          : (isPlayingThisShloka &&
                                playbackState == PlaybackState.playing)
                          ? 2.5
                          : 1.5,
                    ),
                  ),
                  child: cardBody,
                )
              : cardBody),
    );
  }

  // --- NEW: Helper widget to build the correct audio button icon ---
  Widget _buildAudioActionButton({
    required BuildContext context,
    required ShlokaResult shloka,
    required bool isPlayingThis,
    required PlaybackState playbackState,
    required AssetPackStatus downloadStatus,
    required AudioProvider audioProvider,
  }) {
    // --- FIX: Show download icon for both 'notDownloaded' and 'unknown' states ---
    if (downloadStatus == AssetPackStatus.notDownloaded ||
        downloadStatus == AssetPackStatus.unknown) {
      return _ActionButton(
        icon: Icons.download_for_offline_outlined,
        onPressed: () {
          debugPrint(
            "[UI] Download button pressed for shloka ${shloka.chapterNo}.${shloka.shlokNo}",
          );
          audioProvider
          // We can safely parse here as chapterNo is always a valid integer string.
          .initiateChapterAudioDownload(int.parse(shloka.chapterNo));
        },
      );
    }
    if (downloadStatus == AssetPackStatus.pending) {
      return _ActionButton(
        icon: Icons.download_for_offline_outlined,
        onPressed: () => audioProvider.initiateChapterAudioDownload(
          int.parse(shloka.chapterNo),
        ),
      );
    }
    if (downloadStatus == AssetPackStatus.downloading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: audioProvider.getChapterDownloadProgress(
            int.parse(shloka.chapterNo),
          ),
        ),
      );
    }
    if (isPlayingThis) {
      if (playbackState == PlaybackState.loading) {
        return const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        );
      }
      if (playbackState == PlaybackState.playing) {
        return _ActionButton(
          icon: Icons.pause_circle_filled,
          // MODIFIED: If onPlayPause is provided, delegate to it.
          // Otherwise fall back to simple toggle.
          onPressed: () {
            if (onPlayPause != null) {
              onPlayPause!();
            } else {
              audioProvider.playOrPauseShloka(shloka);
            }
          },
          color: Theme.of(context).colorScheme.primary,
        );
      }
    }
    return _ActionButton(
      icon: Icons.play_circle_outline,
      onPressed: () {
        // MODIFIED: If onPlayPause is provided, delegate to it fully.
        // The parent is responsible for calling the appropriate provider method.
        if (onPlayPause != null) {
          onPlayPause!();
        } else {
          audioProvider.playOrPauseShloka(shloka);
        }
      },
    );
  }

  // --- MODIFIED build method ---
  // It is now wrapped in a Consumer to get the audio state
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final shlokaId = '${shloka.chapterNo}.${shloka.shlokNo}';
        // Use the reliable ID passed from the parent for UI logic
        final isPlayingThisShloka = currentlyPlayingId == shlokaId;
        final playbackState = audioProvider.playbackState;
        final chapterNumber = int.tryParse(shloka.chapterNo) ?? 0;
        final downloadStatus = audioProvider.getChapterPackStatus(
          chapterNumber,
        );

        // --- LOGGING FOR HIGHLIGHT ---
        if (isPlayingThisShloka && playbackState == PlaybackState.playing) {
          debugPrint(
            "[HIGHLIGHT] Card $shlokaId is being built with highlight ON.",
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: config.continuousReading
                  ? const EdgeInsets.fromLTRB(8, 4, 8, 2)
                  : config.spacingCompact
                  ? const EdgeInsets.fromLTRB(12, 4, 12, 10)
                  : const EdgeInsets.fromLTRB(16, 8, 16, 32),
              // Pass the audio state down to the content builder
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: buildCardContent(
                  context,
                  audioProvider: audioProvider,
                  isPlayingThisShloka: isPlayingThisShloka,
                  playbackState: playbackState,
                  downloadStatus: downloadStatus,
                ),
              ),
            ),
            if (config.showEmblem) SneakyEmblem(speaker: shloka.speaker),
          ],
        );
      },
    );
  }
}

// --- NEW: A smaller, reusable IconButton for our card actions ---
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color ?? Theme.of(context).iconTheme.color),
      iconSize: 32,
      onPressed: onPressed,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(),
      splashRadius: 24,
    );
  }
}

/// Continuous Parayan verse + Orbitron shloka watermark in the inter-verse gap.
class _ContinuousVerseWithNumber extends StatelessWidget {
  final ShlokaResult shloka;
  final FullShlokaCardConfig config;
  final Color primaryTextColor;
  final BoxConstraints constraints;

  const _ContinuousVerseWithNumber({
    required this.shloka,
    required this.config,
    required this.primaryTextColor,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    const leftInset = 16.0;
    const rightInset = 56.0;
    final verseMaxWidth =
        (constraints.maxWidth - leftInset - rightInset).clamp(120.0, 1200.0);

    final base = config.baseFontSize;
    final lineHeight = base >= 24 ? 1.55 : (base >= 20 ? 1.65 : 1.75);
    final letterSpacing = base >= 24 ? 0.15 : 0.35;
    final indent = (base * 1.35).clamp(18.0, 36.0);
    final bodies = config.visibleListBodies;
    final ruleColor = config.isLightTheme
        ? const Color(0xFFB8860B).withValues(alpha: 0.35)
        : const Color(0xFFFFD700).withValues(alpha: 0.35);

    final sections = <Widget>[];
    for (var i = 0; i < bodies.length; i++) {
      if (i > 0) {
        sections.add(
          Padding(
            padding: const EdgeInsets.only(left: leftInset, right: rightInset),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: 12,
                  width: 48,
                  child: CustomPaint(
                    painter: _MeaningRulePainter(color: ruleColor),
                  ),
                ),
              ),
            ),
          ),
        );
      }
      sections.add(
        _sectionWithOptionalLabel(
          context,
          body: bodies[i],
          verseMaxWidth: verseMaxWidth,
          leftInset: leftInset,
          rightInset: rightInset,
          base: base,
          lineHeight: lineHeight,
          letterSpacing: letterSpacing,
          indent: indent,
        ),
      );
    }

    final verseBody = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );

    if (!config.showShlokIndex || config.preserveCardChrome) return verseBody;

    // Align with the circular glass column (rail overlays the right 72px).
    // Content is inset from the screen edge, so a small/negative [right]
    // pulls the # into the glass lane — clear of the track (~10px inset).
    const trackClearance = 8.0; // gap so digits don't touch the seek line
    final numberRight = -(
      ChapterSeekRail.glassRadius - trackClearance
    ); // ≈ -18 → sits on glass x, left of track
    final fontSize = (config.baseFontSize * 2.2).clamp(24.0, 34.0);
    final numberColor = config.isLightTheme
        ? primaryTextColor.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.32);
    final lift = fontSize * 0.5 + 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -lift,
          right: numberRight,
          child: IgnorePointer(
            child: Text(
              shloka.shlokNo,
              textAlign: TextAlign.center,
              softWrap: false,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                height: 1.0,
                color: numberColor,
              ),
            ),
          ),
        ),
        verseBody,
      ],
    );
  }

  Widget _sectionWithOptionalLabel(
    BuildContext context, {
    required ContinuousListBody body,
    required double verseMaxWidth,
    required double leftInset,
    required double rightInset,
    required double base,
    required double lineHeight,
    required double letterSpacing,
    required double indent,
  }) {
    final content = _bodyFor(
      body,
      verseMaxWidth: verseMaxWidth,
      leftInset: leftInset,
      rightInset: rightInset,
      base: base,
      lineHeight: lineHeight,
      letterSpacing: letterSpacing,
      indent: indent,
    );
    if (!config.preserveCardChrome) return content;

    final script = Provider.of<SettingsProvider>(context).script;
    final termKey = switch (body) {
      ContinuousListBody.shloka => 'shloka',
      ContinuousListBody.anvay => 'anvay',
      ContinuousListBody.translation => 'tika',
    };
    final accentColor = config.isLightTheme
        ? const Color(0xFFD84315)
        : const Color(0xFFFFD700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: leftInset, right: rightInset),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              StaticData.localizeTerm(termKey, script),
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                fontSize: (base * 0.85).clamp(14.0, 18.0),
                fontFamily: 'NotoSerif',
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        content,
      ],
    );
  }

  Widget _bodyFor(
    ContinuousListBody body, {
    required double verseMaxWidth,
    required double leftInset,
    required double rightInset,
    required double base,
    required double lineHeight,
    required double letterSpacing,
    required double indent,
  }) {
    final palette = ChapterReadingColors.of(
      config.isLightTheme ? Brightness.light : Brightness.dark,
    );

    if (body == ContinuousListBody.translation) {
      final tikaColor = palette.tika;
      final verseStyle = TextStyle(
        fontSize: base,
        fontStyle: FontStyle.normal,
        color: tikaColor,
        fontFamily: 'NotoSerif',
        height: lineHeight,
        letterSpacing: letterSpacing,
      );
      final text = shloka.bhavarth.trim().isEmpty
          ? '—'
          : shloka.bhavarth.trim();
      return Padding(
        padding: EdgeInsets.only(left: leftInset, right: rightInset),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, textAlign: TextAlign.left, style: verseStyle),
        ),
      );
    }

    if (body == ContinuousListBody.anvay) {
      final anvayColor = palette.anvay;
      final verseStyle = TextStyle(
        fontSize: base,
        fontStyle: FontStyle.italic,
        color: anvayColor,
        fontFamily: 'NotoSerif',
        height: lineHeight,
        letterSpacing: letterSpacing,
      );
      final raw = shloka.anvay.trim().isEmpty ? '—' : shloka.anvay;
      return Padding(
        padding: EdgeInsets.only(left: leftInset, right: rightInset),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _wrappedLines(
              raw,
              verseStyle,
              verseMaxWidth,
              indent,
            ),
          ),
        ),
      );
    }

    final isFourLine = shloka.shlok.contains('<C>');
    final verseColor =
        isFourLine ? palette.shlokaFourLine : palette.shloka;
    final karaokeHighlight = palette.karaokeHighlight;

    final verseStyle = TextStyle(
      fontSize: base,
      fontStyle: isFourLine ? FontStyle.italic : FontStyle.normal,
      color: verseColor,
      fontFamily: 'NotoSerif',
      height: lineHeight,
      letterSpacing: letterSpacing,
      fontWeight: isFourLine ? FontWeight.w500 : FontWeight.w400,
    );

    return Padding(
      padding: EdgeInsets.only(left: leftInset, right: rightInset),
      child: KaraokeTextDisplay(
        shlokaId: '${shloka.chapterNo}.${shloka.shlokNo}',
        originalText: shloka.shlok,
        style: verseStyle,
        textAlign: TextAlign.left,
        highlightColor: karaokeHighlight,
        wrapMaxWidth: verseMaxWidth,
        continuationIndent: indent,
        wrapLine: FullShlokaCard.wrapVerseLine,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _wrappedLines(
              shloka.shlok,
              verseStyle,
              verseMaxWidth,
              indent,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _wrappedLines(
    String raw,
    TextStyle verseStyle,
    double verseMaxWidth,
    double indent,
  ) {
    final lineWidgets = <Widget>[];
    for (final logical in KaraokeTextDisplay.displayLinesFromRaw(raw)) {
      final parts = FullShlokaCard.wrapVerseLine(
        logical,
        verseStyle,
        verseMaxWidth,
      );
      for (var i = 0; i < parts.length; i++) {
        final lineIndent = i == 0 ? 0.0 : indent;
        lineWidgets.add(
          Padding(
            padding: EdgeInsets.only(left: lineIndent),
            child: SizedBox(
              width: (verseMaxWidth - lineIndent).clamp(40.0, verseMaxWidth),
              child: RichText(
                textAlign: TextAlign.left,
                softWrap: false,
                overflow: TextOverflow.clip,
                text: TextSpan(
                  children: FullShlokaCard.verseSpansSkipDandaShadow(
                    parts[i],
                    verseStyle,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return lineWidgets;
  }
}

enum ContinuousListBody {
  shloka,
  anvay,
  translation,
}

/// How many of shloka / anvay / translation the Parayan list shows.
enum ParayanLayoutCount { one, two, three }

/// Which pair is shown when [ParayanLayoutCount.two] is selected.
enum ContinuousListPair { shlokaAnvay, shlokaTranslation, anvayTranslation }

extension ContinuousListPairBodies on ContinuousListPair {
  List<ContinuousListBody> get bodies => switch (this) {
    ContinuousListPair.shlokaAnvay => const [
      ContinuousListBody.shloka,
      ContinuousListBody.anvay,
    ],
    ContinuousListPair.shlokaTranslation => const [
      ContinuousListBody.shloka,
      ContinuousListBody.translation,
    ],
    ContinuousListPair.anvayTranslation => const [
      ContinuousListBody.anvay,
      ContinuousListBody.translation,
    ],
  };
}

class FullShlokaCardConfig {
  final bool showSpeaker;
  final bool showAnvay;
  final bool showBhavarth;
  final bool showSeparator;
  final bool showColoredCard;
  final bool showEmblem;
  final bool showShlokIndex;
  final bool spacingCompact;
  final bool isLightTheme;
  final double baseFontSize;
  final bool showActions;
  /// Chapter list: show Anvay · Tika expand affordance when meanings are collapsed.
  final bool showMeaningsHint;
  /// Parayan continuous reading: no card chrome unless focused.
  final bool continuousReading;
  /// Chapter list: keep filled card + border even in continuous body layout.
  final bool preserveCardChrome;
  /// Collapsed Parayan list primary body (one-item layout).
  final ContinuousListBody listBodyMode;
  /// How many bodies each Parayan verse shows.
  final ParayanLayoutCount layoutCount;
  /// Pair shown when [layoutCount] is two.
  final ContinuousListPair listPairMode;
  /// Live spotlight target for chapter help (Play / bookmark / Share row).
  final Key? helpActionsRowKey;

  const FullShlokaCardConfig({
    this.showSpeaker = true,
    this.showAnvay = true,
    this.showBhavarth = true,
    this.showSeparator = true,
    this.showColoredCard = true,
    this.showEmblem = true,
    this.showShlokIndex = true,
    this.spacingCompact = false,
    this.isLightTheme = false,
    this.baseFontSize = 20.0,
    this.showActions = true,
    this.showMeaningsHint = false,
    this.continuousReading = false,
    this.preserveCardChrome = false,
    this.listBodyMode = ContinuousListBody.shloka,
    this.layoutCount = ParayanLayoutCount.one,
    this.listPairMode = ContinuousListPair.shlokaAnvay,
    this.helpActionsRowKey,
  });

  /// Bodies shown in the Parayan continuous list.
  /// Expand-on-select ([showAnvay] / [showBhavarth]) always reveals all three.
  List<ContinuousListBody> get visibleListBodies {
    if (showAnvay || showBhavarth) {
      return const [
        ContinuousListBody.shloka,
        ContinuousListBody.anvay,
        ContinuousListBody.translation,
      ];
    }
    return switch (layoutCount) {
      ParayanLayoutCount.one => [listBodyMode],
      ParayanLayoutCount.two => listPairMode.bodies,
      ParayanLayoutCount.three => const [
        ContinuousListBody.shloka,
        ContinuousListBody.anvay,
        ContinuousListBody.translation,
      ],
    };
  }

  static const minimal = FullShlokaCardConfig(
    showSpeaker: false,
    showAnvay: true,
    showBhavarth: false,
    showSeparator: true,
    showColoredCard: false,
    showEmblem: false,
    showShlokIndex: true,
    spacingCompact: true,
    isLightTheme: false,
    baseFontSize: 20.0,
  );

  static const lightThemeDefault = FullShlokaCardConfig(
    isLightTheme: true,
    baseFontSize: 20.0,
  );

  static const minimalLight = FullShlokaCardConfig(
    showSpeaker: false,
    showAnvay: true,
    showBhavarth: false,
    showSeparator: true,
    showColoredCard: false,
    showEmblem: false,
    showShlokIndex: true,
    spacingCompact: true,
    isLightTheme: true,
    baseFontSize: 20.0,
  );

  FullShlokaCardConfig copyWith({
    bool? showSpeaker,
    bool? showAnvay,
    bool? showBhavarth,
    bool? showSeparator,
    bool? showColoredCard,
    bool? showEmblem,
    bool? showShlokIndex,
    bool? spacingCompact,
    bool? isLightTheme,
    double? baseFontSize,
    bool? showActions,
    bool? showMeaningsHint,
    bool? continuousReading,
    bool? preserveCardChrome,
    ContinuousListBody? listBodyMode,
    ParayanLayoutCount? layoutCount,
    ContinuousListPair? listPairMode,
    Key? helpActionsRowKey,
  }) {
    return FullShlokaCardConfig(
      showSpeaker: showSpeaker ?? this.showSpeaker,
      showAnvay: showAnvay ?? this.showAnvay,
      showBhavarth: showBhavarth ?? this.showBhavarth,
      showSeparator: showSeparator ?? this.showSeparator,
      showColoredCard: showColoredCard ?? this.showColoredCard,
      showEmblem: showEmblem ?? this.showEmblem,
      showShlokIndex: showShlokIndex ?? this.showShlokIndex,
      spacingCompact: spacingCompact ?? this.spacingCompact,
      isLightTheme: isLightTheme ?? this.isLightTheme,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      showActions: showActions ?? this.showActions,
      showMeaningsHint: showMeaningsHint ?? this.showMeaningsHint,
      continuousReading: continuousReading ?? this.continuousReading,
      preserveCardChrome: preserveCardChrome ?? this.preserveCardChrome,
      listBodyMode: listBodyMode ?? this.listBodyMode,
      layoutCount: layoutCount ?? this.layoutCount,
      listPairMode: listPairMode ?? this.listPairMode,
      helpActionsRowKey: helpActionsRowKey ?? this.helpActionsRowKey,
    );
  }
}

/// Subtle hairline + diamond between anvay and tika on expanded Parayan cards.
class _MeaningRulePainter extends CustomPainter {
  final Color color;

  _MeaningRulePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 12) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final midY = size.height / 2;
    final midX = size.width / 2;
    const diamond = 3.0;
    const gap = 6.0;

    canvas.drawLine(Offset(0, midY), Offset(midX - diamond - gap, midY), paint);
    canvas.drawLine(
      Offset(midX + diamond + gap, midY),
      Offset(size.width, midY),
      paint,
    );

    final path = Path()
      ..moveTo(midX, midY - diamond)
      ..lineTo(midX + diamond, midY)
      ..lineTo(midX, midY + diamond)
      ..lineTo(midX - diamond, midY)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MeaningRulePainter oldDelegate) =>
      oldDelegate.color != color;
}
