import 'dart:ui';
import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _itemKeys = [];
  bool _isContinuousPlayEnabled = false;

  // To detect when a shloka finishes playing
  String? _previousPlayingId;
  PlaybackState? _previousPlaybackState;

  void _scrollToIndex(int index) {
    if (index < 0 || index >= _itemKeys.length) return;
    final key = _itemKeys[index];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          alignment: 0.1,
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
        // The AppBar is now conditional. It only shows for search results (non-chapter views).
        // For chapter views, the SliverPersistentHeader acts as the AppBar.
        appBar: chapterNumber == null
            ? AppBar(
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
              )
            : null,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            const SimpleGradientBackground(),
            Consumer2<ShlokaListProvider, AudioProvider>(
              builder: (context, provider, audioProvider, child) {
                if (provider.isLoading) {
                  // For chapter views, show the emblem header and a loading indicator.
                  // This ensures the Hero widget is present during the page transition.
                  if (chapterNumber != null) {
                    return Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ChapterEmblemHeader(chapterNumber: chapterNumber),
                            const SizedBox(height: 32),
                            const CircularProgressIndicator(),
                          ],
                        ),
                      ),
                    );
                  }
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

                if (provider.shlokas.isNotEmpty &&
                    _itemKeys.length != provider.shlokas.length) {
                  _itemKeys =
                      List.generate(provider.shlokas.length, (_) => GlobalKey());
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

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // If this is a search view (no chapter number), add top padding
                    // to account for the AppBar since extendBodyBehindAppBar is true.
                    if (chapterNumber == null)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                        ),
                      ),
                    if (chapterNumber != null)
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _AnimatingHeaderDelegate(
                          chapterNumber: chapterNumber,
                          title: StaticData.getQueryTitle(widget.searchQuery),
                          isContinuousPlayEnabled: _isContinuousPlayEnabled,
                          onSwitchChanged: (value) {
                            setState(() {
                              _isContinuousPlayEnabled = value;
                            });
                          },
                          minExtent: MediaQuery.of(context).padding.top + kToolbarHeight,
                          // Increased maxExtent to make room for the title below the emblem
                          maxExtent: MediaQuery.of(context).padding.top + kToolbarHeight + 250,
                        ),
                      ),
                    // Add some spacing between the header and the first card for chapter views
                    if (chapterNumber != null)
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 100),
                      ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Container(
                            key: _itemKeys[index],
                            child: FullShlokaCard(shloka: shlokas[index], config: _cardConfig)),
                        childCount: shlokas.length,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                  ],
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
            border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
            boxShadow: [
              BoxShadow( // Changed to a bright, golden glow
                color: Colors.amber.withOpacity(0.8),
                spreadRadius: 4,
                blurRadius: 15.0,
                offset: Offset.zero,
              ),
            ],
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

class _AnimatingHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int chapterNumber;
  final String title;
  final bool isContinuousPlayEnabled;
  final ValueChanged<bool> onSwitchChanged;
  @override
  final double minExtent;
  @override
  final double maxExtent;

  _AnimatingHeaderDelegate({
    required this.chapterNumber,
    required this.title,
    required this.isContinuousPlayEnabled,
    required this.onSwitchChanged,
    required this.minExtent,
    required this.maxExtent,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final paddingTop = MediaQuery.of(context).padding.top;
    final t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    // Emblem properties
    const double maxSize = 160.0;
    const double minSize = 40.0;
    final double currentSize = lerpDouble(maxSize, minSize, t)!;
    final double currentRadius = lerpDouble(16.0, minSize / 2, t)!;

    // Emblem position
    final double maxLeft = (MediaQuery.of(context).size.width - maxSize) / 2;
    final double minLeft = 56.0; // Position next to back button
    final double currentLeft = lerpDouble(maxLeft, minLeft, t)!;

    final double maxTop = minExtent; // Start below the final appbar area
    final double minTop = paddingTop + (kToolbarHeight - minSize) / 2;
    final double currentTop = lerpDouble(maxTop, minTop, t)!;

    // --- NEW: Title animation ---
    // Position
    final double titleMaxTop = maxTop + maxSize + 16; // Below the large emblem
    final double titleMinTop = paddingTop;
    final double titleCurrentTop = lerpDouble(titleMaxTop, titleMinTop, t)!;

    final double titleMaxHorizontalPadding = 16.0;
    final double titleMinHorizontalPadding = 100.0; // To fit between back button and actions
    final double titleCurrentHorizontalPadding = lerpDouble(titleMaxHorizontalPadding, titleMinHorizontalPadding, t)!;

    // Font size
    final double titleMaxFontSize = Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24.0;
    final double titleMinFontSize = Theme.of(context).textTheme.titleLarge?.fontSize ?? 20.0;
    final double titleCurrentFontSize = lerpDouble(titleMaxFontSize, titleMinFontSize, t)!;

    // Opacity for elements that appear when collapsed
    final double contentOpacity = t;

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Back button (always visible)
          Positioned(
            top: paddingTop,
            left: 4,
            child: const BackButton(color: Colors.white),
          ),

          // Title (fades in)
          Positioned(
            top: titleCurrentTop,
            left: titleCurrentHorizontalPadding,
            right: titleCurrentHorizontalPadding,
            height: kToolbarHeight,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: titleCurrentFontSize,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Actions (fades in)
          Positioned(
            top: paddingTop,
            right: 0,
            height: kToolbarHeight,
            child: Opacity(
              opacity: contentOpacity,
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch(
                      value: isContinuousPlayEnabled,
                      onChanged: onSwitchChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text('Non-Stop Play', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70))
                  ],
                ),
              ),
            ),
          ),

          // The animating emblem
          Positioned(
            top: currentTop,
            left: currentLeft,
            child: Hero(
              tag: 'chapterEmblem_$chapterNumber',
              child: Container(
                width: currentSize,
                height: currentSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(currentRadius),
                  border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
                  boxShadow: [
                    BoxShadow( // Animate the glow properties
                      color: Colors.amber.withOpacity(lerpDouble(0.8, 0.7, t)!),
                      spreadRadius: lerpDouble(4, 2, t)!,
                      blurRadius: lerpDouble(15, 12, t)!,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/emblems/chapter/ch${chapterNumber.toString().padLeft(2, '0')}.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_AnimatingHeaderDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        chapterNumber != oldDelegate.chapterNumber ||
        title != oldDelegate.title ||
        isContinuousPlayEnabled != oldDelegate.isContinuousPlayEnabled ||
        onSwitchChanged != oldDelegate.onSwitchChanged;
  }
}
