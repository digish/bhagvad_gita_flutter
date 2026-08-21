import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_provider.dart';
import '../../services/timing_service.dart';
import '../../models/timing_model.dart';

class KaraokeTextDisplay extends StatelessWidget {
  final String shlokaId;
  final String originalText;
  final TextStyle? style;
  final TextAlign textAlign;
  final Widget? child; // The static widget to show when not playing

  const KaraokeTextDisplay({
    super.key,
    required this.shlokaId,
    required this.originalText,
    this.style,
    this.textAlign = TextAlign.center,
    this.child,
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
    // Dark sky blue — clear against black Devanagari
    const highlightColor = Color(0xFF0277BD);

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
              color: isHighlighted ? highlightColor : defaultColor,
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
