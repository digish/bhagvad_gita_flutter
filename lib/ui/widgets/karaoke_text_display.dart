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

  @override
  Widget build(BuildContext context) {
    // 1. Check if we have timings for this shloka
    final timings = TimingService.getTimings(shlokaId);

    // If no timings or not playing this shloka, return static text
    // We check if this shloka is the one currently playing in AudioProvider
    // But since we want to be reactive, we listen to AudioProvider updates.

    // Changing to Consumer to listen to state changes (playing/stopped)
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, childMaybe) {
        final isPlayingThis = audioProvider.currentPlayingShlokaId == shlokaId;

        // Optimization: If not playing this shloka, show static text immediately
        if (!isPlayingThis || timings == null || timings.isEmpty) {
          return child ??
              Text(originalText, style: style, textAlign: textAlign);
        }

        // 2. StreamBuilder for high-frequency updates (Word Highlighting)
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

  List<InlineSpan> _buildSpans(
    List<WordTiming> timings,
    WordTiming? current,
    BuildContext context,
  ) {
    final List<InlineSpan> spans = [];
    final defaultColor = style?.color ?? Colors.black;
    // highlightColor removed as we use custom style now

    // 1. Raw Split - Keep everything initially
    // Ensure * is spaced out so it becomes its own token
    final rawTokens = originalText
        .replaceAll('<C>', ' ')
        .replaceAll('*', ' * ') // Force * to be its own token
        .replaceAll('\n', ' ')
        .split(' ');

    int timingIndex = 0;

    for (var token in rawTokens) {
      if (token.trim().isEmpty) continue;

      // 2. Special handling for * -> Newline
      if (token == '*') {
        spans.add(const TextSpan(text: "\n"));
        continue;
      }

      // 3. Check if this token is a "Word" or "Punctuation"
      final isPunctuation = RegExp(r'^[\s\d\|।*।॥\.\-]+$').hasMatch(token);

      bool isHighlighted = false;

      // 4. Map to timing
      if (!isPunctuation && timingIndex < timings.length) {
        final t = timings[timingIndex];
        if (current == t) {
          isHighlighted = true;
        }
        timingIndex++;
      }

      // 5. Build Span
      // Ensure STABLE LAYOUT by wrapping ALL words in the same Container structure
      // Highlighted: Amber Gradient, Shadow, Black Text, Bold
      // Unhighlighted: Transparent, No Shadow, Default Text, Normal

      if (!isPunctuation) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 2.0,
              ),
              decoration: isHighlighted
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade300, Colors.amber.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4.0,
                          offset: const Offset(2.0, 2.0),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.amber.shade100,
                        width: 1.0,
                      ),
                    )
                  : BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(color: Colors.transparent, width: 1.0),
                    ),
              child: Text(
                token,
                style: (style ?? const TextStyle()).copyWith(
                  color: isHighlighted ? Colors.black : defaultColor,
                  fontWeight: isHighlighted
                      ? FontWeight.w900
                      : FontWeight.normal,
                  // REMOVED 1.1x scaling to prevent layout shift
                  fontSize: style?.fontSize,
                  shadows: [],
                ),
              ),
            ),
          ),
        );
      } else {
        // Punctuation remains simple TextSpan
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(
              color: defaultColor,
              fontWeight: FontWeight.normal,
              fontSize: style?.fontSize,
            ),
          ),
        );
      }

      // Add space between tokens
      // Logic adjusted: WidgetSpan has margin, so explicit space span is redundant?
      // No, let's keep it consistent with previous logic or remove if margin is enough.
      // Margin 2.0 + 2.0 = 4.0px might be small. Let's keep a small space if needed.
      // Actually, removing space span and relying on margin is cleaner for WidgetSpan flow.
      // But Punctuation needs space?

      // Let's assume standard flow requires space, or we can just rely on margin.
      // If we remove space span, we need to ensure margin is sufficient.
      // Let's keep space span for now, but maybe make it smaller or rely on margin.
      // Wait, if we mix WidgetSpan and TextSpan, TextSpan space is good.

      spans.add(const TextSpan(text: " "));
    }

    return spans;
  }
}
