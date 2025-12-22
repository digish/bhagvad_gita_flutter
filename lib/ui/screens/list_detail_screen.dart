import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/audio_provider.dart';

import '../../providers/settings_provider.dart';
import '../../data/database_helper_interface.dart';
import '../../models/shloka_result.dart';
import '../../models/shloka_list.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';
import '../widgets/share_options_sheet.dart';
import '../../data/static_data.dart';

class ListDetailScreen extends StatefulWidget {
  final ShlokaList list;
  final bool isEmbedded;

  const ListDetailScreen({
    super.key,
    required this.list,
    this.isEmbedded = false,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  late Future<List<ShlokaResult>> _shlokasFuture;

  @override
  void initState() {
    super.initState();
    _loadShlokas();
  }

  void _loadShlokas() {
    final provider = Provider.of<BookmarkProvider>(context, listen: false);
    final db = Provider.of<DatabaseHelperInterface>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    _shlokasFuture = provider.getShlokasForList(
      db,
      widget.list.id,
      language: settings.language,
      script: settings.script,
    );
  }

  Future<void> _shareList(BuildContext context) async {
    // Show options, Audio disabled for list sharing
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ShareOptionsSheet(
        showAudioOption: false,
        onShare: (selectedOptions) =>
            _executeShareList(context, selectedOptions),
      ),
    );
  }

  Future<void> _executeShareList(
    BuildContext context,
    Set<ShareOption> options,
  ) async {
    try {
      final shlokas = await _shlokasFuture;
      if (shlokas.isEmpty) return;

      final StringBuffer buffer = StringBuffer();
      buffer.writeln('${widget.list.name}\n');

      const String appLink =
          'https://digish.github.io/project/index.html#bhagvadgita';

      // Helper to format text
      String formatText(String text) {
        return text
            .replaceAll('<C>', '\n')
            .replaceAll('*', '\n')
            .replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥')
            .trim();
      }

      for (var shloka in shlokas) {
        buffer.writeln('Chapter ${shloka.chapterNo}.${shloka.shlokNo}');

        if (shloka.speaker != null && shloka.speaker!.isNotEmpty) {
          buffer.writeln(
            '${StaticData.localizeSpeaker(shloka.speaker, Provider.of<SettingsProvider>(context, listen: false).script)}:',
          );
        }

        // Shloka Text (Mandatory)
        buffer.writeln(formatText(shloka.shlok));

        // Anvay
        if (options.contains(ShareOption.anvay) && shloka.anvay.isNotEmpty) {
          buffer.writeln(
            '\n${StaticData.localizeTerm('anvay', Provider.of<SettingsProvider>(context, listen: false).script)}:',
          );
          buffer.writeln(formatText(shloka.anvay));
        }

        // Tika (Bhavarth)
        if (options.contains(ShareOption.tika) && shloka.bhavarth.isNotEmpty) {
          buffer.writeln(
            '\n${StaticData.localizeTerm('tika', Provider.of<SettingsProvider>(context, listen: false).script)}:',
          );
          buffer.writeln(shloka.bhavarth);
        }

        buffer.writeln('\n---\n'); // Separator between shlokas
      }

      buffer.writeln('Shared from the Shrimad Bhagavad Gita app:\n$appLink');

      final box = context.findRenderObject() as RenderBox?;

      await Share.share(
        buffer.toString(),
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } catch (e) {
      debugPrint('Error sharing list: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to share list')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isEmbedded ? Colors.transparent : null,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.isEmbedded ? '' : widget.list.name,
        ), // Hide title if embedded as header might be elsewhere? No, keep title but maybe adjust. User lists screen has NO header for right pane? It has "Collections" for left. Let's keep title.
        // Actually, if embedded, we might want to hide the AppBar if the parent handles it?
        // But the parent UserListsScreen just puts it in valid area.
        // Let's keep title.
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: Consumer<AudioProvider>(
        builder: (context, audioProvider, child) {
          final isMiniPlayerVisible =
              audioProvider.playbackState != PlaybackState.stopped &&
              audioProvider.currentPlayingShlokaId != null;
          final double bottomPadding = isMiniPlayerVisible ? 100.0 : 0.0;

          return Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: FloatingActionButton.extended(
              heroTag: 'share_list_fab',
              onPressed: () => _shareList(context),
              icon: const Icon(Icons.share),
              label: const Text('Share Collection'),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          );
        },
      ),
      body: Stack(
        children: [
          if (!widget.isEmbedded) const SimpleGradientBackground(),
          FutureBuilder<List<ShlokaResult>>(
            future: _shlokasFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final shlokas = snapshot.data ?? [];

              if (shlokas.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_books,
                        size: 64,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This list is empty',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Consumer2<AudioProvider, SettingsProvider>(
                builder: (context, audioProvider, settingsProvider, child) {
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      MediaQuery.of(context).padding.left + 16,
                      kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                      MediaQuery.of(context).padding.right + 16,
                      16,
                    ),
                    itemCount: shlokas.length,
                    itemBuilder: (context, index) {
                      final shloka = shlokas[index];
                      // We wrap in a Dismissible to remove from list?
                      // Maybe too risky for accidental deletes.
                      // For now just list them.
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FullShlokaCard(
                          shloka: shloka,
                          currentlyPlayingId:
                              audioProvider.currentPlayingShlokaId,
                          config: FullShlokaCardConfig(
                            baseFontSize: settingsProvider.fontSize,
                            showAnvay: true,
                            showBhavarth: true,
                            showSeparator: true,
                            showSpeaker: true,
                            showShlokIndex: true,
                            showColoredCard: true,
                            showEmblem: false,
                            isLightTheme: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
