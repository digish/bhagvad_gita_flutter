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

  const ParayanActionIsland({
    super.key,
    required this.shloka,
    this.onPlayPause,
    this.currentlyPlayingId,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final enabled = shloka != null;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: 0.45)
              : Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isLight
                ? Colors.white.withValues(alpha: 0.45)
                : Colors.white12,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Consumer<AudioProvider>(
                builder: (context, audioProvider, _) {
                  final current = shloka;
                  final isPlayingThis =
                      current != null &&
                      currentlyPlayingId == current.id &&
                      audioProvider.playbackState == PlaybackState.playing;
                  final isPausedThis =
                      current != null &&
                      currentlyPlayingId == current.id &&
                      audioProvider.playbackState == PlaybackState.paused;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _IslandIconButton(
                        icon: isPlayingThis
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
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
                          enabled: enabled,
                          onPressed: enabled
                              ? () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    useRootNavigator: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (context) => CommentarySheet(
                                      commentaries:
                                          current?.commentaries ?? [],
                                      chapterNo: current!.chapterNo,
                                      shlokNo: current.shlokNo,
                                    ),
                                  );
                                }
                              : null,
                        ),
                      Consumer<BookmarkProvider>(
                        builder: (context, bookmarkProvider, _) {
                          final isBookmarked = current != null &&
                              bookmarkProvider.isBookmarked(
                                current.chapterNo,
                                current.shlokNo,
                              );
                          return _IslandIconButton(
                            icon: isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
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
                      Builder(
                        builder: (btnContext) {
                          return _IslandIconButton(
                            icon: Icons.share_outlined,
                            enabled: enabled,
                            onPressed: enabled
                                ? () => _shareShloka(btnContext, current!)
                                : null,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
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

  const _IslandIconButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.color,
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
      iconSize: 30,
      onPressed: enabled ? onPressed : null,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      splashRadius: 22,
    );
  }
}
