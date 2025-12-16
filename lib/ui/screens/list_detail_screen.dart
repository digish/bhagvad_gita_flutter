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

class ListDetailScreen extends StatefulWidget {
  final ShlokaList list;

  const ListDetailScreen({super.key, required this.list});

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
    _shlokasFuture = provider.getShlokasForList(db, widget.list.id);
  }

  Future<void> _shareList() async {
    try {
      final shlokas = await _shlokasFuture;
      if (shlokas.isEmpty) return;

      final StringBuffer buffer = StringBuffer();
      buffer.writeln('${widget.list.name}\n');

      for (var shloka in shlokas) {
        buffer.writeln('Chapter ${shloka.chapterNo}.${shloka.shlokNo}');
        buffer.writeln(shloka.shlok);
        buffer.writeln(); // Empty line between shlokas
      }

      await Share.share(buffer.toString());
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.list.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareList,
            tooltip: 'Share List',
          ),
        ],
      ),
      body: Stack(
        children: [
          const SimpleGradientBackground(),
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
