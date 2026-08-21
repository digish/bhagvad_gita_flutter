import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../services/timing_service.dart';
import '../../models/timing_model.dart';

typedef VerseLineWrapper = List<String> Function(
  String line,
  TextStyle style,
  double maxWidth,
);

class KaraokeTextDisplay extends StatelessWidget {
  final String shlokaId;
  final String originalText;
  final TextStyle? style;
  final TextAlign textAlign;
  final Color? highlightColor;
  final Widget? child; // The static widget to show when not playing

  /// When set with [wrapLine], playback uses the same wrap + indent Column
  /// as the static continuous verse (avoids reflow on play).
  final double? wrapMaxWidth;
  final double? continuationIndent;
  final VerseLineWrapper? wrapLine;

  const KaraokeTextDisplay({
    super.key,
    required this.shlokaId,
    required this.originalText,
    this.style,
    this.textAlign = TextAlign.center,
    this.highlightColor,
    this.child,
    this.wrapMaxWidth,
    this.continuationIndent,
    this.wrapLine,
  });

  /// Same preprocessing as [FullShlokaCard.formatItalicText]:
  /// strip verse-number markers, split `*` / `<C>` into display lines.
  static List<String> displayLinesFromRaw(String rawText) {
    final processed = rawText.replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥');
    final lines = <String>[];
    for (final couplet in processed.split('*')) {
      for (final part in couplet.split('<C>')) {
        final line = part.trim();
        if (line.isNotEmpty) lines.add(line);
      }
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final timings = TimingService.getTimings(shlokaId);

    return Consumer<AudioProvider>(
      builder: (context, audioProvider, childMaybe) {
        final isPlayingThis = audioProvider.currentPlayingShlokaId == shlokaId;

        if (!isPlayingThis || timings == null || timings.isEmpty) {
          return child ??
              Text(originalText, style: style, textAlign: textAlign);
        }

        return StreamBuilder<Duration>(
          stream: audioProvider.positionStream,
          builder: (context, snapshot) {
            final position = snapshot.data ?? Duration.zero;
            final currentWordTiming = TimingService.getWordAt(
              shlokaId,
              position,
            );

            final useContinuousWrap =
                wrapMaxWidth != null && wrapLine != null;

            if (useContinuousWrap) {
              return _buildWrappedKaraoke(
                context,
                timings,
                currentWordTiming,
              );
            }

            return RichText(
              textAlign: textAlign,
              text: TextSpan(
                style: style ?? DefaultTextStyle.of(context).style,
                children: _buildSpans(timings, currentWordTiming, context),
              ),
            );
          },
        );
      },
    );
  }

  /// Same visual lines as the static continuous Column — word color only changes.
  Widget _buildWrappedKaraoke(
    BuildContext context,
    List<WordTiming> timings,
    WordTiming? current,
  ) {
    final baseStyle = (style ?? DefaultTextStyle.of(context).style);
    final defaultColor = baseStyle.color ?? Colors.black;
    final Color activeHighlight = highlightColor ?? const Color(0xFFCA8A04);
    final maxWidth = wrapMaxWidth!;
    final indent = continuationIndent ?? 0.0;
    final wrapper = wrapLine!;

    final logicalLines = displayLinesFromRaw(originalText);
    final lineWidgets = <Widget>[];
    var timingIndex = 0;

    for (final logical in logicalLines) {
      final parts = wrapper(logical, baseStyle, maxWidth);
      for (var i = 0; i < parts.length; i++) {
        final part = parts[i];
        final words =
            part.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        final spans = <InlineSpan>[];

        for (var w = 0; w < words.length; w++) {
          final word = words[w];
          final isPunctuation =
              RegExp(r'^[\s\d\|।*॥\.\-]+$').hasMatch(word);

          var isHighlighted = false;
          if (!isPunctuation && timingIndex < timings.length) {
            if (current == timings[timingIndex]) {
              isHighlighted = true;
            }
            timingIndex++;
          }

          final wordStyle = baseStyle.copyWith(
            color: isHighlighted ? activeHighlight : defaultColor,
            fontWeight: isHighlighted ? FontWeight.w700 : baseStyle.fontWeight,
          );
          // Strip shadows from embedded danda so they don't ghost beside the line.
          if (RegExp(r'[|।॥]').hasMatch(word)) {
            final plain = wordStyle.copyWith(shadows: const <Shadow>[]);
            var start = 0;
            for (final m in RegExp(r'[|।॥]+').allMatches(word)) {
              if (m.start > start) {
                spans.add(
                  TextSpan(
                    text: word.substring(start, m.start),
                    style: wordStyle,
                  ),
                );
              }
              spans.add(TextSpan(text: m.group(0), style: plain));
              start = m.end;
            }
            if (start < word.length) {
              spans.add(TextSpan(text: word.substring(start), style: wordStyle));
            }
          } else {
            spans.add(
              TextSpan(
                text: word,
                style: wordStyle.copyWith(
                  shadows: isPunctuation ? const <Shadow>[] : wordStyle.shadows,
                ),
              ),
            );
          }
          if (w < words.length - 1) {
            spans.add(TextSpan(text: ' ', style: baseStyle));
          }
        }

        lineWidgets.add(
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0.0 : indent),
            child: SizedBox(
              width: (maxWidth - (i == 0 ? 0.0 : indent)).clamp(40.0, maxWidth),
              child: RichText(
                textAlign: TextAlign.left,
                softWrap: false,
                overflow: TextOverflow.clip,
                text: TextSpan(style: baseStyle, children: spans),
              ),
            ),
          ),
        );
      }
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lineWidgets,
      ),
    );
  }

  /// Word-level [TextSpan]s over the *same* preprocessed lines as the card.
  /// Highlight = golden-orange color only (no WidgetSpan / boxes).
  List<InlineSpan> _buildSpans(
    List<WordTiming> timings,
    WordTiming? current,
    BuildContext context,
  ) {
    final lines = displayLinesFromRaw(originalText);
    final isFourLine = originalText.contains('<C>');
    final baseStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      height: 1.6,
      fontStyle: isFourLine ? FontStyle.italic : FontStyle.normal,
    );
    final defaultColor = baseStyle.color ?? Colors.black;
    // Default gold; continuous Parayan passes hue-matched yellows per verse type.
    final Color activeHighlight =
        highlightColor ?? const Color(0xFFCA8A04);

    final spans = <InlineSpan>[];
    var timingIndex = 0;

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final words = line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);

      var wordInLine = 0;
      final wordList = words.toList();
      for (final word in wordList) {
        final isPunctuation = RegExp(r'^[\s\d\|।*॥\.\-]+$').hasMatch(word);

        var isHighlighted = false;
        if (!isPunctuation && timingIndex < timings.length) {
          if (current == timings[timingIndex]) {
            isHighlighted = true;
          }
          timingIndex++;
        }

        spans.add(
          TextSpan(
            text: word,
            style: baseStyle.copyWith(
              color: isHighlighted ? activeHighlight : defaultColor,
              fontWeight: isHighlighted ? FontWeight.w700 : baseStyle.fontWeight,
            ),
          ),
        );

        if (wordInLine < wordList.length - 1) {
          spans.add(TextSpan(text: ' ', style: baseStyle));
        }
        wordInLine++;
      }

      if (lineIndex < lines.length - 1) {
        spans.add(TextSpan(text: '\n', style: baseStyle));
      }
    }

    return spans;
  }
}
