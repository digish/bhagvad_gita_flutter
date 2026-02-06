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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/static_data.dart';
import '../../providers/audio_provider.dart';
import '../widgets/simple_gradient_background.dart';

class AudioManagementScreen extends StatelessWidget {
  const AudioManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Audio Downloads'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SimpleGradientBackground(
            startColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          SafeArea(
            child: Consumer<AudioProvider>(
              builder: (context, audioProvider, child) {
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 16),
                  itemCount: 18,
                  itemBuilder: (context, index) {
                    final chapterNumber = index + 1;
                    return _ChapterAudioTile(
                      chapterNumber: chapterNumber,
                      chapterName: StaticData.geetaAdhyay[index],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterAudioTile extends StatelessWidget {
  final int chapterNumber;
  final String chapterName;

  const _ChapterAudioTile({
    required this.chapterNumber,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    // We listen to the provider to get the status for *this specific tile*
    final audioProvider = Provider.of<AudioProvider>(context);
    final status = audioProvider.getChapterPackStatus(chapterNumber);
    final progress = audioProvider.getChapterDownloadProgress(chapterNumber);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.green.shade900.withOpacity(0.3)
                  : Colors.green.shade50.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.green.shade800.withOpacity(0.5)
                    : Colors.green.shade100.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Chapter Number Icon
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.9),
                  child: Text(
                    chapterNumber.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Chapter Name and Status Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'अध्याय $chapterNumber: $chapterName',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: DefaultTextStyle(
                          style:
                              theme.textTheme.bodySmall?.copyWith(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.black54,
                              ) ??
                              const TextStyle(),
                          child: switch (status) {
                            AssetPackStatus.downloaded => const Text(
                              'Downloaded',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AssetPackStatus.pending => const Text(
                              'Download pending...',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AssetPackStatus.downloading => Text(
                              'Downloading... ${(progress * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AssetPackStatus.failed => const Text(
                              'Download failed',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AssetPackStatus.notDownloaded => const Text(
                              'Not downloaded',
                            ),
                            AssetPackStatus.unknown => const Text(
                              'Status unknown',
                            ),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Action Button/Indicator
                _buildActionButton(context, status, audioProvider),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    AssetPackStatus status,
    AudioProvider audioProvider,
  ) {
    switch (status) {
      case AssetPackStatus.downloaded:
        return const Icon(Icons.check_circle, color: Colors.green, size: 30);
      case AssetPackStatus.pending:
        return const SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(strokeWidth: 3),
        );
      case AssetPackStatus.downloading:
        return SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: audioProvider.getChapterDownloadProgress(chapterNumber),
            strokeWidth: 3,
          ),
        );
      case AssetPackStatus.failed:
        return IconButton(
          icon: const Icon(Icons.error, color: Colors.red, size: 30),
          onPressed: () =>
              audioProvider.initiateChapterAudioDownload(chapterNumber),
          tooltip: 'Retry Download',
        );
      case AssetPackStatus.notDownloaded:
      default:
        return IconButton(
          icon: Icon(
            Icons.download_for_offline_outlined,
            size: 30,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : Colors.grey.shade700,
          ),
          onPressed: () {
            debugPrint(
              "[UI] Download button pressed for chapter $chapterNumber",
            );
            audioProvider.initiateChapterAudioDownload(chapterNumber);
          },
          tooltip: 'Download Audio',
        );
    }
  }
}
