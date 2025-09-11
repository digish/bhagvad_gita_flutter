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
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../models/shloka_result.dart';
import '../../providers/audio_provider.dart';
import '../widgets/sneaky_emblem.dart';

class FullShlokaCard extends StatelessWidget {
  final ShlokaResult shloka;
  final FullShlokaCardConfig config;

  const FullShlokaCard({
    super.key,
    required this.shloka,
    this.config = const FullShlokaCardConfig(),
  });

  // This is your existing text formatting logic, it remains unchanged.
  List<TextSpan> formatItalicText(
      String rawText, TextStyle baseStyle, double maxWidth) {
    final spans = <TextSpan>[];
    String processed = rawText.replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥');
    final isFourLine = processed.contains('<C>');
    final couplets = processed.split('*');
    for (var couplet in couplets) {
      final parts = couplet.split('<C>');
      for (int i = 0; i < parts.length; i++) {
        String line = parts[i].trim();
        if (isFourLine && i % 2 == 1) {
          line = '       $line';
        }
        final isLastCouplet = couplet == couplets.last;
        final isLastLine = i == parts.length - 1 && isLastCouplet;
        line = line.replaceAll('॥', '॥');
        final lineText = isLastLine ? line : '$line\n';
        double fontSize = baseStyle.fontSize ?? 20;
        TextPainter painter;
        do {
          painter = TextPainter(
            text: TextSpan(
                text: lineText, style: baseStyle.copyWith(fontSize: fontSize)),
            maxLines: 1,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
            ellipsis: null,
            textWidthBasis: TextWidthBasis.parent,
          )..layout(maxWidth: double.infinity);
          if (painter.width > maxWidth) fontSize -= 1;
        } while (painter.width > maxWidth && fontSize > 12);
        if (painter.width > maxWidth && fontSize <= 12) {
          spans.add(
              TextSpan(text: lineText, style: baseStyle.copyWith(fontSize: 14)));
          continue;
        }
        final adjustedStyle = baseStyle.copyWith(
          fontSize: fontSize,
          height: 1.6,
          fontStyle: isFourLine ? FontStyle.italic : FontStyle.normal,
        );
        spans.add(TextSpan(text: '$line\n', style: adjustedStyle));
      }
    }
    return spans;
  }

  // Your existing color logic, unchanged.
  Color getSpeakerColor(String? speaker, {bool isLightTheme = false}) {
    if (isLightTheme) {
      switch (speaker?.toLowerCase()) {
        case 'श्री भगवान':
          return const Color.fromARGB(146, 241, 245, 23);
        case 'अर्जुन':
          return const Color.fromARGB(148, 255, 90, 90);
        case 'संजय':
          return const Color.fromARGB(122, 13, 72, 161);
        case 'धृतराष्ट्र':
          return const Color.fromARGB(132, 78, 52, 46);
        default:
          return Colors.black.withOpacity(0.05);
      }
    }
    switch (speaker?.toLowerCase()) {
      case 'श्री भगवान':
        return const Color.fromARGB(167, 248, 244, 21);
      case 'अर्जुन':
        return const Color.fromARGB(102, 250, 117, 9);
      case 'संजय':
        return const Color.fromARGB(102, 87, 155, 233);
      case 'धृतराष्ट्र':
        return const Color.fromARGB(102, 121, 88, 86);
      default:
        return Colors.white.withOpacity(0.07);
    }
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
    final speakerColor =
        getSpeakerColor(shloka.speaker, isLightTheme: isLightTheme);
    final Color primaryTextColor = isLightTheme ? Colors.black87 : Colors.white;
    final Color secondaryTextColor =
        isLightTheme ? Colors.black54 : Colors.white.withOpacity(0.85);
    final Color accentColor =
        isLightTheme ? const Color(0xFFD84315) : const Color(0xFFFFD700);
    final Color cardBackgroundColor = isLightTheme
        ? Colors.white.withOpacity(0.6)
        : Colors.white.withOpacity(0.07);
    final Color mainBorderColor =
        isLightTheme ? Colors.grey.shade400 : const Color(0xFFFFD700);
    final Color innerCardBorderColor = isLightTheme
        ? Colors.black.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
        child: Container(
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            borderRadius: BorderRadius.circular(20.0),
            // --- MODIFICATION: Border highlighting for playing shloka ---
            border: Border.all(
              color: isPlayingThisShloka && playbackState == PlaybackState.playing
                  ? theme.colorScheme.primary
                  : mainBorderColor,
              width: isPlayingThisShloka && playbackState == PlaybackState.playing
                  ? 2.0
                  : 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      padding: config.spacingCompact
                          ? const EdgeInsets.all(1)
                          : const EdgeInsets.all(4),
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
                          Row(
                            children: [
                              if (config.showSpeaker &&
                                  shloka.speaker != null &&
                                  shloka.speaker!.isNotEmpty)
                                Text(
                                  '${shloka.speaker!}:',
                                  style:
                                      theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor.withOpacity(0.9),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              if (config.showShlokIndex)
                                Text(
                                  config.spacingCompact
                                      ? '  श्लोक: ${shloka.chapterNo}:${shloka.shlokNo}'
                                      : '  अध्याय ${shloka.chapterNo}, श्लोक ${shloka.shlokNo}',
                                  style:
                                      theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: accentColor,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              // --- MODIFICATION: Add spacer and audio button ---
                              const Spacer(),
                              _buildAudioActionButton(
                                context: context,
                                shloka: shloka,
                                isPlayingThis: isPlayingThisShloka,
                                playbackState: playbackState,
                                downloadStatus: downloadStatus,
                                audioProvider: audioProvider,
                              ),
                            ],
                          ),
                          if (config.showSpeaker || config.showShlokIndex)
                            config.spacingCompact
                                ? const SizedBox(height: 8)
                                : const SizedBox(height: 16),
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              children: formatItalicText(
                                shloka.shlok,
                                TextStyle(
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic,
                                  color: primaryTextColor,
                                  fontFamily: 'NotoSerif',
                                ),
                                constraints.maxWidth - 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (config.showAnvay ||
                    config.showBhavarth ||
                    config.showSeparator)
                  config.spacingCompact
                      ? const SizedBox(height: 5)
                      : const SizedBox(height: 10),
                if (config.showSeparator)
                  Center(
                    child: SizedBox(
                      width: 150, // Constrain the width to make it smaller
                      child: isLightTheme
                          ? ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                  Colors.grey[700]!, BlendMode.srcIn),
                              child: Image.asset(
                                'assets/images/line_seperator.png',
                              ),
                            )
                          : Image.asset('assets/images/line_seperator.png'),
                            ),
                    ),

                if (config.showSeparator)
                  config.spacingCompact
                      ? const SizedBox(height: 5)
                      : const SizedBox(height: 10),
                if (config.showAnvay && shloka.anvay.isNotEmpty) ...[
                  Text('अन्वय',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      )),
                  config.spacingCompact
                      ? const SizedBox(height: 4)
                      : const SizedBox(height: 8),
                  LayoutBuilder(builder: (context, constraints) {
                    return RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                            children: formatItalicText(
                                shloka.anvay,
                                TextStyle(
                                  fontSize: 20,
                                  fontStyle: FontStyle.normal,
                                  color: secondaryTextColor,
                                  fontFamily: 'NotoSerif',
                                  height: 1.6,
                                ),
                                constraints.maxWidth)));
                  }),
                  config.spacingCompact
                      ? const SizedBox(height: 5)
                      : const SizedBox(height: 10),
                ],
                if (config.showBhavarth && shloka.bhavarth.isNotEmpty) ...[
                  Text('टिका',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(height: 8),
                  Text(shloka.bhavarth,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.normal,
                        color: secondaryTextColor,
                        height: 1.4,
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
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
    if (downloadStatus == AssetPackStatus.notDownloaded) {
      return _ActionButton(
        icon: Icons.download_for_offline_outlined,
        onPressed: () {
          debugPrint("[UI] Download button pressed for shloka ${shloka.chapterNo}.${shloka.shlokNo}");
          audioProvider
              .initiateChapterAudioDownload(int.parse(shloka.chapterNo));
        },
      );
    }
    if (downloadStatus == AssetPackStatus.pending) {
      return _ActionButton(
        icon: Icons.download_for_offline_outlined,
        onPressed: () =>
            audioProvider.initiateChapterAudioDownload(int.parse(shloka.chapterNo)),
      );
    }
    if (downloadStatus == AssetPackStatus.downloading) {
      return SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          value: audioProvider
              .getChapterDownloadProgress(int.parse(shloka.chapterNo)),
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
          onPressed: () => audioProvider.playOrPauseShloka(shloka),
          color: Theme.of(context).colorScheme.primary,
        );
      }
    }
    return _ActionButton(
      icon: Icons.play_circle_outline,
      onPressed: () => audioProvider.playOrPauseShloka(shloka),
    );
  }

  // --- MODIFIED build method ---
  // It is now wrapped in a Consumer to get the audio state
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProvider, child) {
        final shlokaId = '${shloka.chapterNo}.${shloka.shlokNo}';
        final isPlayingThisShloka =
            audioProvider.currentPlayingShlokaId == shlokaId;
        final playbackState = audioProvider.playbackState;
        final chapterNumber = int.tryParse(shloka.chapterNo) ?? 0;
        final downloadStatus =
            audioProvider.getChapterPackStatus(chapterNumber);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              // Pass the audio state down to the content builder
              child: buildCardContent(
                context,
                audioProvider: audioProvider,
                isPlayingThisShloka: isPlayingThisShloka,
                playbackState: playbackState,
                downloadStatus: downloadStatus,
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

// Your existing config class, unchanged.
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
  });

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
  );

  static const lightThemeDefault = FullShlokaCardConfig(
    isLightTheme: true,
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
  );
}
