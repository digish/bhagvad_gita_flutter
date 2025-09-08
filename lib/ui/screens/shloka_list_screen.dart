import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../models/shloka_result.dart';
import '../../providers/audio_provider.dart';
import '../../providers/shloka_list_provider.dart';
import '../widgets/full_shloka_card.dart';
import '../../data/static_data.dart';
import '../../data/database_helper_interface.dart';

class ShlokaListScreen extends StatefulWidget {
  final String searchQuery;
  const ShlokaListScreen({super.key, required this.searchQuery});

  @override
  State<ShlokaListScreen> createState() => _ShlokaListScreenState();
}

class _ShlokaListScreenState extends State<ShlokaListScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  int? _lastScrolledIndex;
  bool _isContinuousPlayEnabled = false;

  // To detect when a shloka finishes playing
  String? _previousPlayingId;
  PlaybackState? _previousPlaybackState;

  void _scrollToIndex(int index) {
    if (_lastScrolledIndex == index) return; // Avoid redundant scrolls
    // A post-frame callback ensures that the list has been built and is ready to be scrolled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
        _lastScrolledIndex = index;
        itemScrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          alignment: 0.1, // Aligns the item near the top of the viewport
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbHelper = Provider.of<DatabaseHelperInterface>(context, listen: false);

    // Try to parse chapter number for showing the emblem header.
    // This handles cases like a query of "1" or "1,21".
    final chapterNumber = int.tryParse(widget.searchQuery.split(',').first.trim());

    return ChangeNotifierProvider(
      create: (_) => ShlokaListProvider(widget.searchQuery, dbHelper),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            StaticData.getQueryTitle(widget.searchQuery),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // The switch is placed first.
                  Switch(
                    value: _isContinuousPlayEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isContinuousPlayEnabled = value;
                      });
                    },
                    // This makes the switch more compact vertically.
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  // The label is placed below the switch.
                  Text('Non-Stop Play', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70))
                ],
              ),
            ),
          ],
          backgroundColor: Colors.black.withOpacity(0.4),
          elevation: 0,
          centerTitle: true,
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            const SimpleGradientBackground(),
            Consumer2<ShlokaListProvider, AudioProvider>(
              builder: (context, provider, audioProvider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.shlokas.isEmpty) {
                  return Center(
                    child: Text(
                      'No shlokas found for "${widget.searchQuery}".',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                    ),
                  );
                }

                // If an initial scroll index is set by the provider, trigger the scroll.
                if (provider.initialScrollIndex != null) {
                  _scrollToIndex(provider.initialScrollIndex!);
                  // Clear the index in the provider to prevent re-scrolling on rebuilds.
                  provider.clearScrollIndex();
                }

                final shlokas = provider.shlokas;
                final currentPlayingId = audioProvider.currentPlayingShlokaId;
                final currentPlaybackState = audioProvider.playbackState;

                // --- AUTO-SCROLL LOGIC ---
                if (currentPlayingId != null) {
                  final playingIndex = shlokas.indexWhere(
                      (s) => '${s.chapterNo}.${s.shlokNo}' == currentPlayingId);
                  if (playingIndex != -1) {
                    _scrollToIndex(playingIndex);
                  }
                } else {
                  _lastScrolledIndex = null;
                }

                // --- CONTINUOUS PLAY LOGIC ---
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Detect completion: previous state was playing, current is not.
                  if (_previousPlayingId != null &&
                      _previousPlaybackState == PlaybackState.playing &&
                      currentPlayingId != _previousPlayingId) {
                    if (_isContinuousPlayEnabled) {
                      final lastPlayedIndex = shlokas.indexWhere((s) =>
                          '${s.chapterNo}.${s.shlokNo}' == _previousPlayingId);

                      if (lastPlayedIndex != -1 &&
                          lastPlayedIndex < shlokas.length - 1) {
                        final ShlokaResult nextShloka =
                            shlokas[lastPlayedIndex + 1];
                        audioProvider.playOrPauseShloka(nextShloka);
                      }
                    }
                  }
                  _previousPlayingId = currentPlayingId;
                  _previousPlaybackState = currentPlaybackState;
                });

                return ScrollablePositionedList.builder(
                  itemScrollController: itemScrollController,
                  itemCount: provider.shlokas.length,
                  // Add padding to account for the transparent AppBar and system status bar.
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                    bottom: 20,
                  ),
                  itemBuilder: (context, index) {
                    final shloka = shlokas[index];

                    // If this is a chapter view, display a static emblem header above the first shloka.
                    if (index == 0 && chapterNumber != null) {
                      return Column(
                        children: [
                          _ChapterEmblemHeader(chapterNumber: chapterNumber),
                          FullShlokaCard(
                            shloka: shloka,
                            config: _cardConfig,
                          ),
                        ],
                      );
                    }

                    return FullShlokaCard(
                      shloka: shloka,
                      config: _cardConfig,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // A single configuration for the shloka cards to ensure consistency.
  final FullShlokaCardConfig _cardConfig = const FullShlokaCardConfig(
    showSpeaker: true,
    showAnvay: true,
    showBhavarth: true,
    showSeparator: true,
    showColoredCard: true,
    showEmblem: true,
    showShlokIndex: true,
    spacingCompact: false,
    isLightTheme: true,
  );
}

/// A simplified, static header to replace the animated SliverPersistentHeader.
/// This allows for the use of ScrollablePositionedList.
class _ChapterEmblemHeader extends StatelessWidget {
  final int chapterNumber;
  const _ChapterEmblemHeader({required this.chapterNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Hero(
        tag: 'chapterEmblem_$chapterNumber',
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade200, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
