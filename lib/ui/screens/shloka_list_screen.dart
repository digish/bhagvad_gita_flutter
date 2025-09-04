import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../providers/shloka_list_provider.dart';
import '../widgets/full_shloka_card.dart';
import '../../data/static_data.dart';
import '../../data/database_helper.dart';
import '../../data/database_helper_interface.dart';

class ShlokaListScreen extends StatefulWidget {
  final String searchQuery;
  const ShlokaListScreen({super.key, required this.searchQuery});

  @override
  State<ShlokaListScreen> createState() => _ShlokaListScreenState();
}

class _ShlokaListScreenState extends State<ShlokaListScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();

  void _scrollToIndex(int index) {
    // A post-frame callback ensures that the list has been built and is ready to be scrolled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (itemScrollController.isAttached) {
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
          backgroundColor: Colors.black.withOpacity(0.4),
          elevation: 0, 
          centerTitle: true,
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            const SimpleGradientBackground(),
            Consumer<ShlokaListProvider>(
              builder: (context, provider, child) {
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

                return ScrollablePositionedList.builder(
                  itemScrollController: itemScrollController,
                  itemCount: provider.shlokas.length,
                  // Add padding to account for the transparent AppBar and system status bar.
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + kToolbarHeight + 20,
                    bottom: 20,
                  ),
                  itemBuilder: (context, index) {
                    final shloka = provider.shlokas[index];
                    
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
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
