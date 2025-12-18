// lib/ui/screens/search_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/foundation.dart';

import '../../navigation/app_router.dart';
import '../../providers/search_provider.dart';
import '../widgets/darkened_animated_background.dart';
import '../widgets/lotus.dart';
import '../widgets/shloka_result_card.dart';
import '../widgets/word_result_card.dart';
import '../widgets/decorative_foreground.dart';
import '../widgets/simple_gradient_background.dart';
import '../../providers/settings_provider.dart';
import '../../data/database_helper_interface.dart';
import '../widgets/responsive_wrapper.dart';
import '../../models/shloka_list.dart';
import '../../models/shloka_result.dart';
import '../../providers/bookmark_provider.dart';
// import '../../main.dart'; // For routeObserver - Removed
import '../../data/static_data.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read the globally provided database helper
    final dbHelper = Provider.of<DatabaseHelperInterface>(
      context,
      listen: false,
    );
    final language = Provider.of<SettingsProvider>(context).language;
    final script = Provider.of<SettingsProvider>(context).script;

    // Pass the helper to the SearchProvider
    return ChangeNotifierProvider(
      key: ValueKey(
        '$language-$script',
      ), // Force re-creation when language or script changes
      create: (_) =>
          SearchProvider(dbHelper, language, script), // Re-creates on change
      child: const _SearchScreenView(),
    );
  }
}

class _SearchScreenView extends StatefulWidget {
  const _SearchScreenView();

  @override
  State<_SearchScreenView> createState() => _SearchScreenViewState();
}

class _SearchScreenViewState extends State<_SearchScreenView> with RouteAware {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    final isSearching = provider.searchQuery.isNotEmpty;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final shouldShowResults = isSearching || isKeyboardOpen;

    return Scaffold(
      backgroundColor: Colors.black,

      // ✨ RESTORED: The floating action button for navigation.
      // It's hidden when the keyboard is visible.
      floatingActionButton:
          (isKeyboardOpen || MediaQuery.of(context).size.width > 600)
          ? null
          : _buildSpeedDial(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Stack(
            children: [
              if (settings.showBackground) ...[
                DarkenedAnimatedBackground(opacity: isKeyboardOpen ? 1.0 : 0.2),
                AnimatedOpacity(
                  opacity: shouldShowResults ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: shouldShowResults,
                    child: isKeyboardOpen
                        ? const DecorativeForeground(opacity: 0.2)
                        : const DecorativeForeground(opacity: 1.0),
                  ),
                ),
              ] else
                // Simple background
                const SimpleGradientBackground(startColor: Colors.black),

              // Wrap the interactive UI in a SafeArea
              SafeArea(
                child: Stack(
                  children: [
                    AnimatedAlign(
                      alignment: shouldShowResults
                          ? Alignment.topCenter
                          : Alignment.center,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      child: Padding(
                        // Removed hardcoded top padding, SafeArea handles it.
                        padding: const EdgeInsets.only(
                          top: 16.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        child: SingleChildScrollView(
                          child: ResponsiveWrapper(
                            maxWidth: 600,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: !shouldShowResults
                                      ? AnimatedScale(
                                          scale: isKeyboardOpen ? 0.7 : 1.0,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                          child: const Lotus(),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: isKeyboardOpen ? 0 : 10,
                                ),
                                _buildSearchBar(provider),
                                if (settings.showRandomShloka &&
                                    !shouldShowResults)
                                  _buildRandomShlokaCard(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isSearching)
                      Padding(
                        // Adjusted padding to position the list below the search bar area.
                        padding: const EdgeInsets.only(top: 100.0),
                        child: ResponsiveWrapper(
                          maxWidth: 600,
                          child: ListView.builder(
                            itemCount:
                                provider.searchResults.length +
                                1, // +1 for "See all"
                            itemBuilder: (context, index) {
                              if (index == provider.searchResults.length) {
                                return ListTile(
                                  leading: const Icon(
                                    Icons.search,
                                    color: Colors.white70,
                                  ),
                                  title: Text(
                                    "See all results for '${provider.searchQuery}'",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  onTap: () {
                                    context.pushNamed(
                                      'shloka-list',
                                      pathParameters: {
                                        'query': provider.searchQuery,
                                      },
                                    );
                                  },
                                );
                              }

                              final item = provider.searchResults[index];
                              if (item is HeaderItem) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    top: 20,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      color: Colors.amber.withOpacity(0.8),
                                      fontSize: 11,
                                      letterSpacing: 1.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              if (item is ShlokaItem) {
                                return ShlokaResultCard(
                                  shloka: item.shloka,
                                  searchQuery: provider.searchQuery,
                                );
                              }
                              if (item is WordItem) {
                                return WordResultCard(word: item.word);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),

                    // Simple Theme Toggle Button (Bottom Left)
                    if (MediaQuery.of(context).viewInsets.bottom == 0 &&
                        MediaQuery.of(context).size.width <= 600)
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          heroTag: 'simple_theme_toggle',
                          mini: true,
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.8),
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          onPressed: () {
                            settings.setShowBackground(
                              !settings.showBackground,
                            );
                          },
                          child: Icon(
                            settings.showBackground
                                ? Icons.format_paint_outlined
                                : Icons.format_paint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ✨ RESTORED: The helper method to build the SpeedDial widget.
  Widget _buildSpeedDial(BuildContext context) {
    return SpeedDial(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.close,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      spacing: 12,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.auto_stories),
          label: 'Full Parayan',
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: () => context.push(AppRoutes.parayan),
        ),
        SpeedDialChild(
          child: const Icon(Icons.menu_book),
          label: 'Browse Chapters',
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: () => context.push(AppRoutes.chapters),
        ),
        SpeedDialChild(
          child: const Icon(Icons.bookmark),
          label: 'Collections',
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: () => context.push(AppRoutes.bookmarks),
        ),
        // In search_screen.dart's _buildSpeedDial method
        if (defaultTargetPlatform != TargetPlatform.iOS)
          SpeedDialChild(
            child: const Icon(Icons.headset),
            label: 'Manage Audio',
            backgroundColor: Theme.of(context).colorScheme.surface,
            onTap: () => context.push(AppRoutes.audioManagement),
          ),
        SpeedDialChild(
          child: const Icon(Icons.info_outline),
          label: 'Credits',
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: () => context.push(AppRoutes.credits),
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: 'Settings',
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: () => context.push(AppRoutes.settings),
        ),
      ],
    );
  }

  Widget _buildSearchBar(SearchProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(50.0),
            border: Border.all(
              color: Colors.amberAccent.withOpacity(0.6),
              width: 1.2,
            ),
          ),
          child: TextField(
            onChanged: (value) => provider.onSearchQueryChanged(value),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.pushNamed(
                  'shloka-list',
                  pathParameters: {'query': value},
                );
              }
            },
            decoration: const InputDecoration(
              hintText: 'Search the Gita...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Random Shloka Logic & UI
  ShlokaResult? _randomShloka;
  String _randomShlokaListName = '';
  bool _loadingRandom = false;

  @override
  void initState() {
    super.initState();
    // Defer the random fetch until after the first frame to access providers context safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadRandomShloka();
      }
    });
  }

  Future<void> _loadRandomShloka() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    if (!settings.showRandomShloka) {
      if (mounted) setState(() => _randomShloka = null);
      return;
    }

    if (mounted) setState(() => _loadingRandom = true);

    try {
      final db = Provider.of<DatabaseHelperInterface>(context, listen: false);
      ShlokaResult? result;

      if (settings.randomShlokaSource == -1) {
        // Entire Gita
        if (mounted) setState(() => _randomShlokaListName = 'Gita Wisdom');
        // Force database to give a random record. logic depends on DB implementation
        result = await db.getRandomShloka(
          language: settings.language,
          script: settings.script,
        );
      } else {
        // Specific List
        final bookmarks = Provider.of<BookmarkProvider>(context, listen: false);

        // Manually get list name
        final lists = [...bookmarks.lists, ...bookmarks.predefinedLists];
        final list = lists.firstWhere(
          (l) => l.id == settings.randomShlokaSource,
          orElse: () => ShlokaList(id: -999, name: 'Collection'),
        );
        if (mounted) setState(() => _randomShlokaListName = list.name);

        final shlokas = await bookmarks.getShlokasForList(
          db,
          settings.randomShlokaSource,
          language: settings.language,
          script: settings.script,
        );

        if (shlokas.isNotEmpty) {
          // Manually pick random from list
          shlokas.shuffle(); // Shuffle in place
          result = shlokas.first;
        }
      }

      if (mounted) {
        setState(() {
          _randomShloka = result;
          _loadingRandom = false;
        });
      }
    } catch (e) {
      debugPrint('SearchScreen: Error loading random shloka: $e');
      if (mounted) setState(() => _loadingRandom = false);
    }
  }

  // Helper to process shloka text similar to FullShlokaCard
  String _processShlokaText(String rawText) {
    String processed = rawText.replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥');
    final couplets = processed.split('*');
    final allLines = <String>[];

    for (var couplet in couplets) {
      final parts = couplet.split('<C>');
      for (int i = 0; i < parts.length; i++) {
        String line = parts[i].trim();
        if (line.isNotEmpty) {
          allLines.add(line);
        }
      }
    }
    return allLines.join('\n');
  }

  Widget _buildRandomShlokaCard() {
    if (_loadingRandom) return const SizedBox.shrink();
    if (_randomShloka == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                context.push(
                  AppRoutes.shlokaDetail.replaceFirst(
                    ':id',
                    _randomShloka!.id.toString(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _randomShlokaListName.toUpperCase(),
                            style: TextStyle(
                              color: Colors.amberAccent.withOpacity(0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              StaticData.localizeSpeaker(
                                _randomShloka!.speaker,
                                Provider.of<SettingsProvider>(context).script,
                              ).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.refresh,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                onPressed: _loadRandomShloka,
                                tooltip: 'Refresh Insight',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        _processShlokaText(_randomShloka!.shlok),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Ch ${_randomShloka!.chapterNo}.${_randomShloka!.shlokNo}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
