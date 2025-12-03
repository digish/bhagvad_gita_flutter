// lib/ui/screens/search_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/foundation.dart';
import '../../data/database_helper.dart';
import '../../navigation/app_router.dart';
import '../../providers/search_provider.dart';
import '../widgets/darkened_animated_background.dart';
import '../widgets/lotus.dart';
import '../widgets/shloka_result_card.dart';
import '../widgets/word_result_card.dart';
import '../widgets/decorative_foreground.dart';
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

    // Pass the helper to the SearchProvider
    return ChangeNotifierProvider(
      create: (_) => SearchProvider(dbHelper),
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
    final ringDimension = 160.0;

    return Scaffold(
      backgroundColor: Colors.black,

      // ✨ RESTORED: The floating action button for navigation.
      // It's hidden when the keyboard is visible.
      floatingActionButton: MediaQuery.of(context).viewInsets.bottom > 0
          ? null
          : _buildSpeedDial(context),
      body: Stack(
        children: [
          DarkenedAnimatedBackground(
            opacity: MediaQuery.of(context).viewInsets.bottom > 0 ? 1.0 : 0.2,
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
                                  MediaQuery.of(context).viewInsets.bottom > 16
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
                        itemCount: provider.searchResults.length,
                        itemBuilder: (context, index) {
                          final item = provider.searchResults[index];
                          if (item is ShlokaItem) {
                            return ShlokaResultCard(shloka: item.shloka);
                          }
                          if (item is WordItem) {
                            return WordResultCard(word: item.word);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
            style: const TextStyle(
              fontSize: 18,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
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
