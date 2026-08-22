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
*/

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/static_data.dart';
import '../../models/shloka_result.dart';
import '../../navigation/app_router.dart';
import '../../providers/audio_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/analytics_service.dart';
import 'add_to_list_sheet.dart';
import 'commentary_sheet.dart';
import 'share_options_sheet.dart';

/// Compact glass action bar for the Parayan focus-line shloka.
class ParayanActionIsland extends StatelessWidget {
  final ShlokaResult? shloka;
  final VoidCallback? onPlayPause;
  final String? currentlyPlayingId;
  final bool compact;
  final bool vertical;
  final bool accentBorder;
  final Color? accentColor;
  final bool meaningsExpanded;
  final VoidCallback? onToggleMeanings;

  const ParayanActionIsland({
    super.key,
    required this.shloka,
    this.onPlayPause,
    this.currentlyPlayingId,
    this.compact = false,
    this.vertical = false,
    this.accentBorder = false,
    this.accentColor,
    this.meaningsExpanded = false,
    this.onToggleMeanings,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final enabled = shloka != null;
    final iconSize = compact ? 22.0 : 30.0;
    final hPad = compact ? (vertical ? 4.0 : 6.0) : 12.0;
    final vPad = compact ? (vertical ? 6.0 : 2.0) : 4.0;
    final borderColor = accentBorder
        ? (accentColor ?? const Color(0xFF047BC0))
        : (isLight
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.white12);

    Widget buildButtons(AudioProvider audioProvider) {
      final current = shloka;
      final playingId = audioProvider.currentPlayingShlokaId;
      final thisId = current == null
          ? null
          : '${current.chapterNo}.${current.shlokNo}';
      final isThisTrack =
          current != null &&
          (playingId == thisId ||
              playingId == current.id ||
              currentlyPlayingId == thisId ||
              currentlyPlayingId == current.id);
      final isPlayingThis =
          isThisTrack &&
          audioProvider.playbackState == PlaybackState.playing;
      final isPausedThis =
          isThisTrack &&
          audioProvider.playbackState == PlaybackState.paused;

      final children = <Widget>[
        _IslandIconButton(
          icon: isPlayingThis
              ? Icons.pause_circle_filled
              : Icons.play_circle_filled,
          iconSize: iconSize,
          enabled: enabled,
          onPressed: enabled
              ? () {
                  if (isPlayingThis || isPausedThis) {
                    audioProvider.togglePlayback();
                  } else {
                    onPlayPause?.call();
                  }
                }
              : null,
        ),
        if (current == null ||
            current.commentaries == null ||
            current.commentaries!.isNotEmpty)
          _IslandIconButton(
            icon: Icons.menu_book_rounded,
            iconSize: iconSize,
            enabled: enabled,
            onPressed: enabled
                ? () {
                    CommentarySheet.show(
                      context,
                      commentaries: current?.commentaries,
                      chapterNo: current!.chapterNo,
                      shlokNo: current.shlokNo,
                    );
                  }
                : null,
          ),
        Consumer<BookmarkProvider>(
          builder: (context, bookmarkProvider, _) {
            final isBookmarked =
                current != null &&
                bookmarkProvider.isBookmarked(
                  current.chapterNo,
                  current.shlokNo,
                );
            return _IslandIconButton(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
              iconSize: iconSize,
              enabled: enabled,
              color: isBookmarked
                  ? Theme.of(context).colorScheme.primary
                  : null,
              onPressed: enabled
                  ? () {
                      showModalBottomSheet(
                        context: context,
                        useRootNavigator: true,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        builder: (context) => AddToListSheet(
                          chapterNo: current!.chapterNo,
                          shlokNo: current.shlokNo,
                        ),
                      );
                    }
                  : null,
            );
          },
        ),
        _IslandIconButton(
          icon: meaningsExpanded
              ? Icons.unfold_less
              : Icons.unfold_more,
          iconSize: iconSize,
          enabled: enabled && onToggleMeanings != null,
          color: meaningsExpanded
              ? (accentColor ?? Theme.of(context).colorScheme.primary)
              : null,
          onPressed: enabled ? onToggleMeanings : null,
        ),
        Builder(
          builder: (btnContext) {
            return _IslandIconButton(
              icon: Icons.share_outlined,
              iconSize: iconSize,
              enabled: enabled,
              onPressed: enabled
                  ? () => _shareShloka(btnContext, current!)
                  : null,
            );
          },
        ),
      ];

      if (vertical) {
        return Column(mainAxisSize: MainAxisSize.min, children: children);
      }
      return Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    final island = Container(
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.55)
            : Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        border: Border.all(
          color: borderColor,
          width: accentBorder ? 2.5 : 1.5,
        ),
        boxShadow: [
          if (accentBorder)
            BoxShadow(
              color: (accentColor ?? const Color(0xFF047BC0))
                  .withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 22 : 28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: Consumer<AudioProvider>(
              builder: (context, audioProvider, _) =>
                  buildButtons(audioProvider),
            ),
          ),
        ),
      ),
    );

    if (compact) return island;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: island,
      ),
    );
  }

  Future<void> _shareShloka(BuildContext context, ShlokaResult shloka) async {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareOptionsSheet(
        showAudioOption: true,
        onShare: (selectedOptions) =>
            _executeShare(context, shloka, selectedOptions),
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
    ShlokaResult shloka,
    Set<ShareOption> options,
  ) async {
    final script =
        Provider.of<SettingsProvider>(context, listen: false).script;
    final shlokaIdentifier =
        'Shrimad Bhagavad Gita\nअध्याय ${shloka.chapterNo}, श्लोक ${shloka.shlokNo}';

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

    if (shloka.speaker != null && shloka.speaker!.isNotEmpty) {
      buffer.writeln('${StaticData.localizeSpeaker(shloka.speaker, script)}:');
    }

    buffer.writeln(formatText(shloka.shlok));

    if (options.contains(ShareOption.anvay) && shloka.anvay.isNotEmpty) {
      buffer.writeln('\n---\n');
      buffer.writeln('${StaticData.localizeTerm('anvay', script)}:');
      buffer.writeln(formatText(shloka.anvay));
    }

    if (options.contains(ShareOption.tika) && shloka.bhavarth.isNotEmpty) {
      buffer.writeln('\n---\n');
      buffer.writeln('${StaticData.localizeTerm('tika', script)}:');
      buffer.writeln(shloka.bhavarth);
    }

    const appLink = 'https://digish.github.io/project/gita.html';
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

    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    if (options.contains(ShareOption.audio)) {
      final audioProvider = Provider.of<AudioProvider>(context, listen: false);
      final audioPath = await audioProvider.getShlokaAudioPath(shloka);

      if (audioPath != null) {
        String? validFilePath;
        if (audioPath.startsWith('assets/')) {
          try {
            final byteData = await rootBundle.load(audioPath);
            final tempDir = await getTemporaryDirectory();
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

    await SharePlus.instance.share(
      ShareParams(
        text: shareText,
        subject: shlokaIdentifier,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}

class _IslandIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  final Color? color;
  final double iconSize;

  const _IslandIconButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.color,
    this.iconSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: enabled
            ? (color ?? Theme.of(context).iconTheme.color)
            : Theme.of(context).disabledColor,
      ),
      iconSize: iconSize,
      onPressed: enabled ? onPressed : null,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }
}
