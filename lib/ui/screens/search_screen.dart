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
import '../widgets/liquid_reveal.dart';
import '../../models/shloka_list.dart';
import '../../models/shloka_result.dart';
import '../../providers/bookmark_provider.dart';
// import '../../main.dart'; // For routeObserver - Removed
import '../../data/static_data.dart';
import '../theme/app_colors.dart';
import '../../services/home_widget_service.dart';

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

class _SearchScreenViewState extends State<_SearchScreenView>
    with RouteAware, SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  Offset _revealCenter = Offset.zero;
  final GlobalKey _themeToggleKey = GlobalKey();
  bool? _isBackgroundRequested;
  Set<int>? _lastKnownSources; // Cache for change detection

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Removed explicit postFrameCallback here; handled in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = Provider.of<SettingsProvider>(context);
    final newSources = settings.randomShlokaSources;

    // Trigger load if sources change (or first run)
    if (_lastKnownSources == null ||
        !setEquals(_lastKnownSources, newSources)) {
      _lastKnownSources = Set.from(newSources);
      // Defer to avoid setState during build integration
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadRandomShloka();
        }
      });
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  void _captureThemeTogglePosition() {
    final RenderBox? renderBox =
        _themeToggleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _revealCenter = renderBox.localToGlobal(
        renderBox.size.center(Offset.zero),
      );
    }
  }

  Widget _buildBackgroundOnly({
    required bool showBackground,
    required bool isKeyboardOpen,
    required bool shouldShowResults,
    bool excludeDecoration = false,
  }) {
    if (showBackground) {
      return Stack(
        children: [
          DarkenedAnimatedBackground(opacity: isKeyboardOpen ? 1.0 : 0.2),
          if (!excludeDecoration)
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
        ],
      );
    } else {
      return SimpleGradientBackground(
        startColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFF48FB1),
      );
    }
  }

  Widget _buildDecorationOnly({
    required bool showBackground,
    required bool isKeyboardOpen,
    required bool shouldShowResults,
  }) {
    if (showBackground) {
      return AnimatedOpacity(
        opacity: shouldShowResults ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: shouldShowResults,
          child: isKeyboardOpen
              ? const DecorativeForeground(opacity: 0.2)
              : const DecorativeForeground(opacity: 1.0),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    final isSearching = provider.searchQuery.isNotEmpty;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final shouldShowResults = isSearching || isKeyboardOpen;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ✨ RESTORED: The floating action button for navigation.
      // It's hidden when the keyboard is visible.
      floatingActionButton:
          (isKeyboardOpen || MediaQuery.of(context).size.width > 600)
          ? null
          : _buildSpeedDial(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          // Initialize local state if first run
          if (_isBackgroundRequested == null) {
            _isBackgroundRequested = settings.showBackground;
          }

          // Check if setting changed externally (e.g. from Navigation Rail)
          // and we are not currently animating a change we initiated locally.
          if (settings.showBackground != _isBackgroundRequested &&
              !_revealController.isAnimating) {
            final width = MediaQuery.of(context).size.width;
            final isLandscape = width > MediaQuery.of(context).size.height;
            final showRail = width > 600;

            // If change came from Rail (iPad/Tablet), start animation from likely button position
            if (showRail) {
              final double railWidth = isLandscape ? 220.0 : 100.0;
              final double bottomPadding = MediaQuery.of(
                context,
              ).padding.bottom;
              // Approximate center of the button in the rail
              final double buttonX = railWidth / 2;
              final double buttonY =
                  MediaQuery.of(context).size.height - bottomPadding - 40;

              _revealCenter = Offset(buttonX, buttonY);

              // Update our local tracking to match new target
              // We need to trigger the animation "backwards" or "forwards" depending on state?
              // The logic below assumes we want to reveal the NEW state.
              // So we set _isBackgroundRequested to the OLD state (what is currently visible),
              // then start animation to reveal the NEW state (settings.showBackground).

              // Actually, the LiquidReveal reveals the *child* (which is the requested state).
              // So we want to reveal 'settings.showBackground'.
              // The 'background' (base layer) should be inputs that match !_isBackgroundRequested.

              // Let's defer to the standard flow:
              // 1. We acknowledge the change is happening.
              // 2. We start the animation.
              _isBackgroundRequested = settings.showBackground;
              _revealController.forward(from: 0);
            } else {
              // Phone/Narrow layout - just sync state without animation if we can't determine source,
              // or maybe we should just snap?
              // Ideally this case doesn't happen often as the FAB is the only changer,
              // but if it did, we just update local state.
              _isBackgroundRequested = settings.showBackground;
            }
          } else if (!_revealController.isAnimating) {
            // Ensure strict sync when idle
            _isBackgroundRequested = settings.showBackground;
          }

          return AnimatedBuilder(
            animation: _revealController,
            builder: (context, _) {
              return Stack(
                children: [
                  // Base Layer: Background Color (No Buttons)
                  if (_revealController.isAnimating)
                    _buildBackgroundOnly(
                      showBackground: !_isBackgroundRequested!,
                      isKeyboardOpen: isKeyboardOpen,
                      shouldShowResults: shouldShowResults,
                      excludeDecoration: true,
                    ),

                  // Top Layer: Background Color (No Buttons) - Revealing
                  LiquidReveal(
                    progress: _revealController.isAnimating
                        ? _revealController.value
                        : 1.0,
                    center: _revealCenter,
                    child: _buildBackgroundOnly(
                      showBackground: _isBackgroundRequested!,
                      isKeyboardOpen: isKeyboardOpen,
                      shouldShowResults: shouldShowResults,
                      excludeDecoration: true,
                    ),
                  ),

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
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
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
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
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
                                      leading: Icon(
                                        Icons.search,
                                        color:
                                            !settings.showBackground &&
                                                Theme.of(context).brightness ==
                                                    Brightness.light
                                            ? Colors.brown.withOpacity(0.7)
                                            : Colors.white70,
                                      ),
                                      title: Text(
                                        "See all results for '${provider.searchQuery}'",
                                        style: TextStyle(
                                          color:
                                              !settings.showBackground &&
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.light
                                              ? Colors.brown.shade900
                                              : Colors.white,
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
                                          color:
                                              !settings.showBackground &&
                                                  Theme.of(
                                                        context,
                                                      ).brightness ==
                                                      Brightness.light
                                              ? Colors.pink.shade900
                                                    .withOpacity(0.7)
                                              : Colors.amber.withOpacity(0.8),
                                          fontSize: 12,
                                          letterSpacing: 1.8,
                                          fontWeight: FontWeight.w800,
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
                              key: _themeToggleKey,
                              heroTag: 'simple_theme_toggle',
                              mini: true,
                              // Use Theme Extension for colors
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).extension<AppColors>()?.simpleThemeToggle ??
                                  Theme.of(context).primaryColor,
                              foregroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Colors.white,
                              onPressed: () {
                                _captureThemeTogglePosition();
                                setState(() {
                                  _isBackgroundRequested =
                                      !settings.showBackground;
                                });
                                _revealController.forward(from: 0).then((_) {
                                  settings.setShowBackground(
                                    _isBackgroundRequested!,
                                  );
                                });
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

                  // Decoration Layer (Buttons) - ON TOP of content
                  // Base Layer Decoration
                  if (_revealController.isAnimating)
                    _buildDecorationOnly(
                      showBackground: !_isBackgroundRequested!,
                      isKeyboardOpen: isKeyboardOpen,
                      shouldShowResults: shouldShowResults,
                    ),

                  // Top Layer Decoration - Revealing
                  LiquidReveal(
                    progress: _revealController.isAnimating
                        ? _revealController.value
                        : 1.0,
                    center: _revealCenter,
                    child: _buildDecorationOnly(
                      showBackground: _isBackgroundRequested!,
                      isKeyboardOpen: isKeyboardOpen,
                      shouldShowResults: shouldShowResults,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ✨ RESTORED: The helper method to build the SpeedDial widget.
  Widget _buildSpeedDial(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColors>();
    return SpeedDial(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.close,
      backgroundColor:
          appColors?.speedDialBg ?? Theme.of(context).colorScheme.primary,
      foregroundColor:
          appColors?.speedDialFg ?? Theme.of(context).colorScheme.onPrimary,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      spacing: 12,
      children: [
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
        SpeedDialChild(
          child: const Icon(Icons.auto_stories),
          label: 'Full Parayan',
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: () => context.push(AppRoutes.parayan),
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: 'Settings',
          backgroundColor: Theme.of(context).colorScheme.surface,
          onTap: () => context.push(AppRoutes.settings),
        ),
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
      ],
    );
  }

  Widget _buildSearchBar(SearchProvider provider) {
    final settings = Provider.of<SettingsProvider>(context);
    final isLightStyle =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;
    final textColor = isLightStyle ? Colors.black87 : Colors.white;
    final hintColor = isLightStyle ? Colors.black54 : Colors.white70;
    final fillColor = isLightStyle
        ? Colors.black.withOpacity(0.05)
        : Colors.white.withOpacity(0.15);
    final borderColor = isLightStyle
        ? Colors.black.withOpacity(0.1)
        : Colors.amberAccent.withOpacity(0.6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(50.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(50.0),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: TextField(
            style: TextStyle(color: textColor),
            onChanged: (value) => provider.onSearchQueryChanged(value),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.pushNamed(
                  'shloka-list',
                  pathParameters: {'query': value},
                );
              }
            },
            decoration: InputDecoration(
              hintText: 'Search the Gita...',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(Icons.search, color: hintColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
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

      final selectedSources = settings.randomShlokaSources;

      if (selectedSources.contains(-1)) {
        // Entire Gita
        if (mounted) setState(() => _randomShlokaListName = 'Gita Wisdom');
        // Force database to give a random record. logic depends on DB implementation
        result = await db.getRandomShloka(
          language: settings.language,
          script: settings.script,
        );
      } else {
        // Specific List(s)
        final bookmarks = Provider.of<BookmarkProvider>(context, listen: false);
        // Store pair of <ListName, Shloka>
        final allShlokasWithSource = <MapEntry<String, ShlokaResult>>[];

        final allLists = [...bookmarks.lists, ...bookmarks.predefinedLists];

        // Fetch shlokas from all selected lists
        for (final sourceId in selectedSources) {
          // Resolve List Name
          final listName = allLists
              .firstWhere(
                (l) => l.id == sourceId,
                orElse: () => ShlokaList(id: -999, name: 'Collection'),
              )
              .name;

          final shlokas = await bookmarks.getShlokasForList(
            db,
            sourceId,
            language: settings.language,
            script: settings.script,
          );

          debugPrint(
            'Debug: Source $sourceId ($listName) brought ${shlokas.length} shlokas',
          );

          // Add to aggregation with source name
          for (var s in shlokas) {
            allShlokasWithSource.add(MapEntry(listName, s));
          }
        }

        debugPrint(
          'Debug: Total aggregated shlokas: ${allShlokasWithSource.length}',
        );

        if (allShlokasWithSource.isNotEmpty) {
          // Manually pick random from aggregated list
          allShlokasWithSource.shuffle(); // Shuffle in place
          final selection = allShlokasWithSource.first;

          result = selection.value;
          if (mounted) {
            setState(() {
              _randomShlokaListName = selection.key;
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _randomShloka = result;
          _loadingRandom = false;
        });

        // Sync with Home Widget
        if (result != null) {
          HomeWidgetService.updateWidgetData(
            result,
            header: _randomShlokaListName,
          );
        }
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

    final settings = Provider.of<SettingsProvider>(context);
    // Determine styles based on theme
    // Determine styles based on theme
    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;

    final cardColor = isSimpleLight
        ? Colors.white.withOpacity(0.6)
        : Colors.black.withOpacity(0.3);

    final borderColor = isSimpleLight
        ? Colors.pink.withOpacity(0.2)
        : Colors.white.withOpacity(0.1);

    final titleColor = isSimpleLight
        ? Colors.pink.shade900.withOpacity(0.8)
        : Colors.amberAccent.withOpacity(0.8);

    final speakerColor = isSimpleLight
        ? Colors.brown.shade700.withOpacity(0.7)
        : Colors.white.withOpacity(0.6);

    final textColor = isSimpleLight
        ? Colors.brown.shade900
        : Colors.white.withOpacity(0.95);

    final subtitleColor = isSimpleLight
        ? Colors.brown.shade800.withOpacity(0.6)
        : Colors.white.withOpacity(0.5);

    final iconColor = isSimpleLight
        ? Colors.pink.shade700.withOpacity(0.7)
        : Colors.white70;

    return Padding(
      padding: const EdgeInsets.only(top: 24.0, left: 16.0, right: 16.0),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isSimpleLight
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20.0),
                onTap: () {
                  context.push(
                    AppRoutes.shlokaDetail.replaceFirst(
                      ':id',
                      _randomShloka!.id.toString(),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: borderColor, width: 1.5),
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
                                color: titleColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
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
                                  color: speakerColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.refresh,
                                    size: 18,
                                    color: iconColor,
                                  ),
                                  onPressed: _loadRandomShloka,
                                  tooltip: 'Refresh Insight',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _processShlokaText(_randomShloka!.shlok),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 17,
                            height: 1.6,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Chapter ${_randomShloka!.chapterNo}, Shloka ${_randomShloka!.shlokNo}',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
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
      ),
    );
  }
}
