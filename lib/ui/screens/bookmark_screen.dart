import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/audio_provider.dart';
import '../../providers/settings_provider.dart';
import '../../data/database_helper_interface.dart';
import '../../models/shloka_result.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  // We use FutureBuilder/StreamBuilder pattern or just rely on the provider re-rendering.
  // Since fetching details is async, we need a future.

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const SimpleGradientBackground(),
          Consumer<BookmarkProvider>(
            builder: (context, bookmarkProvider, child) {
              return FutureBuilder<List<ShlokaResult>>(
                future: bookmarkProvider.getBookmarkedShlokasDetails(
                  Provider.of<DatabaseHelperInterface>(context, listen: false),
                ),
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
                            Icons.bookmark_border,
                            size: 64,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookmarks yet',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
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
                          100,
                          MediaQuery.of(context).padding.right + 16,
                          16,
                        ), // Top padding for AppBar, side padding for safe area
                        itemCount: shlokas.length,
                        itemBuilder: (context, index) {
                          final shloka = shlokas[index];
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
                                showEmblem: false, // Cleaner look for list
                                isLightTheme:
                                    true, // ✨ FIX: Use light theme for proper contrast
                              ),
                            ),
                          );
                        },
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
