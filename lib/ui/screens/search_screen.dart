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

class _SearchScreenViewState extends State<_SearchScreenView> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SearchProvider>(context);
    final isSearching = provider.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,

      // ✨ RESTORED: The floating action button for navigation.
      // It's hidden when the keyboard is visible.
      floatingActionButton:
          (MediaQuery.of(context).viewInsets.bottom > 0 ||
              MediaQuery.of(context).size.width > 600)
          ? null
          : _buildSpeedDial(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return Stack(
            children: [
              if (settings.showBackground) ...[
                DarkenedAnimatedBackground(
                  opacity: MediaQuery.of(context).viewInsets.bottom > 0
                      ? 1.0
                      : 0.2,
                ),
                AnimatedOpacity(
                  opacity: isSearching ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: isSearching,
                    child: MediaQuery.of(context).viewInsets.bottom > 0
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
                      alignment: isSearching
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
                                  child: !isSearching
                                      ? AnimatedScale(
                                          scale:
                                              MediaQuery.of(
                                                    context,
                                                  ).viewInsets.bottom >
                                                  0
                                              ? 0.7
                                              : 1.0,
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
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          16
                                      ? 0
                                      : 10,
                                ),
                                _buildSearchBar(provider),
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
          label: 'My Lists',
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
                  'shloka-list', // Use name if defined or construct path
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
}
