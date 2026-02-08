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
import '../widgets/ai_suggestion_chips.dart'; // ✨ Add AI Suggestions
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
    with RouteAware, TickerProviderStateMixin {
  late final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // ✨ Track focus
  bool _isSearchFocused = false;
  late AnimationController _revealController;
  late AnimationController _pulseController;
  late AnimationController
  _lotusController; // 🌸 Continuous rotation controller
  Offset _revealCenter = Offset.zero;
  final GlobalKey _themeToggleKey = GlobalKey();
  bool? _isBackgroundRequested;
  Set<int>? _lastKnownSources; // Cache for change detection
  bool _isAiMode = false;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 🌸 Initialize continuous lotus rotation (10s per revolution)
    _lotusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    // Removed explicit postFrameCallback here; handled in didChangeDependencies

    // ✨ Listen to focus changes
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
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
        // Sync Onboarding Bubble Support
        if (mounted) {
          _loadRandomShloka();
        }
      });
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    _pulseController.dispose();
    _lotusController.dispose();
    _searchController.dispose(); // ✨ Dispose controller
    _searchFocusNode.dispose(); // ✨ Dispose focus node
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
                    ? DecorativeForeground(
                        opacity: 0.2,
                        scaleAnimation:
                            null, // Fixed: No longer passing custom scale
                      )
                    : DecorativeForeground(opacity: 1.0, scaleAnimation: null),
              ),
            ),
        ],
      );
    } else {
      return SimpleGradientBackground(
        startColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : const Color(0xFFF48FB1),
        showMandala: false, // ✨ Fix: Force simple mode to prevent white flash
      );
    }
  }

  Widget _buildDecorationOnly({
    required bool showBackground,
    required bool isKeyboardOpen,
    required bool shouldShowResults,
    Animation<double>? scaleAnimation,
  }) {
    if (showBackground) {
      return AnimatedOpacity(
        opacity: shouldShowResults ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: shouldShowResults,
          child: isKeyboardOpen
              ? DecorativeForeground(
                  opacity: 0.2,
                  scaleAnimation: scaleAnimation,
                )
              : DecorativeForeground(
                  opacity: 1.0,
                  scaleAnimation: scaleAnimation,
                ),
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
    final shouldShowResults = isSearching || isKeyboardOpen || _isSearchFocused;
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = width > 600;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ✨ RESTORED: The floating action button for navigation.
      // It's hidden when the keyboard is visible.
      floatingActionButton: (isKeyboardOpen || width > 600)
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
            final isLandscape = width > MediaQuery.of(context).size.height;

            // If change came from Rail (iPad/Tablet), start animation from likely button position
            if (isTablet) {
              final double railWidth = isLandscape ? 220.0 : 100.0;
              final double bottomPadding = MediaQuery.of(
                context,
              ).padding.bottom;
              // Approximate center of the button in the rail
              final double buttonX = railWidth / 2;
              final double buttonY =
                  MediaQuery.of(context).size.height - bottomPadding - 40;

              _revealCenter = Offset(buttonX, buttonY);
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
              // 🌸 Sequence Logic:
              // On Phones (!isTablet), we run a local LiquidReveal.
              // On Tablets (isTablet), MainScaffold already has a global LiquidReveal.
              // In both cases, we use Intervals to time the lotus growth.

              final bool isAnimating = _revealController.isAnimating;

              // Background Reveal Animation (0% -> 60% for tiered growth)
              final revealProgress = isAnimating
                  ? CurvedAnimation(
                      parent: _revealController,
                      curve: _isBackgroundRequested!
                          ? const Interval(0.0, 0.6, curve: Curves.easeInOut)
                          : const Interval(0.0, 1.0, curve: Curves.easeInOut),
                    ).value
                  : 1.0;

              Widget baseBackground = _buildBackgroundOnly(
                showBackground: !_isBackgroundRequested!,
                isKeyboardOpen: isKeyboardOpen,
                shouldShowResults: shouldShowResults,
                excludeDecoration: true,
              );

              Widget newBackground = _buildBackgroundOnly(
                showBackground: _isBackgroundRequested!,
                isKeyboardOpen: isKeyboardOpen,
                shouldShowResults: shouldShowResults,
                excludeDecoration: true,
              );

              return Stack(
                children: [
                  // ✨ FIX: Safety Layer to prevent "White Flash" during transitions
                  // Matches the BOTTOM layer's color (the one being covered/revealed over).
                  if (isAnimating && !isTablet)
                    Container(
                      color: _isBackgroundRequested!
                          ? const Color(
                              0xFFFCE4EC,
                            ) // Going to Complex (Pink is bottom)
                          : Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).scaffoldBackgroundColor
                          : const Color(0xFFF48FB1), // ✨ Fix: Match Pink target
                    ),

                  // Base Layer: Background Color
                  // ✨ Only show on PHONES. On Tablets, MainScaffold handles this via snapshot.
                  if (isAnimating && !isTablet) baseBackground,

                  // Top Layer: Revealing Background
                  // ✨ FIX: Only wrap in LiquidReveal on PHONES.
                  // On tablets, MainScaffold itself is wrapped in LiquidReveal.
                  if (isTablet)
                    newBackground
                  else
                    LiquidReveal(
                      progress: revealProgress,
                      center: _revealCenter,
                      child: newBackground,
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
                              clipBehavior: Clip
                                  .none, // ✨ Allow overflow during animation
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
                                              // ✨ Disabled decorative lotus for now
                                              child: false
                                                  ? Lotus(
                                                      controller:
                                                          _lotusController,
                                                    ) // 🌸 Pass shared controller
                                                  : const SizedBox.shrink(),
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
                                    // ✨ AI Suggestions
                                    // Only show if focused, in AI mode, AND text field is empty
                                    if (_isSearchFocused &&
                                        _isAiMode &&
                                        provider.searchQuery.isEmpty)
                                      AiSuggestionChips(
                                        isVisible: true,
                                        direction: Axis
                                            .vertical, // ✨ Vertical suggestions
                                        onSuggestionSelected: (suggestion) {
                                          _searchController.text = suggestion;
                                          provider.onSearchQueryChanged(
                                            suggestion,
                                          );
                                          _searchFocusNode.unfocus();
                                          context.push(
                                            AppRoutes.askGita,
                                            extra: suggestion,
                                          );
                                        },
                                      ),
                                    if (!settings.hasUsedAskAi &&
                                        !shouldShowResults &&
                                        !_isAiMode)
                                      _OnboardingBubble(
                                        onTap: () {
                                          // 1. Mark as used
                                          settings.markAskAiUsed();
                                          // 2. Switch mode or Navigate
                                          // Option A: Just switch to AI mode in place
                                          setState(() {
                                            _isAiMode = true;
                                          });
                                        },
                                        onDismiss: () {
                                          // Just hide locally for this session, or forever?
                                          // User said "ok to not show them", implies permanent dismissal
                                          // or until they actually use it?
                                          // Let's mark it as used so it doesn't pester them.
                                          settings.markAskAiUsed();
                                        },
                                      ),
                                    if (settings.showRandomShloka &&
                                        !shouldShowResults)
                                      _buildRandomShlokaCard(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (isSearching && !_isAiMode)
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
                  // Decoration Layer (Buttons) - ON TOP of content
                  // Base Layer Decoration
                  // ✨ Only show on PHONES.
                  if (_revealController.isAnimating && !isTablet)
                    _buildDecorationOnly(
                      showBackground: !_isBackgroundRequested!,
                      isKeyboardOpen: isKeyboardOpen,
                      shouldShowResults: shouldShowResults,
                      scaleAnimation: CurvedAnimation(
                        parent: ReverseAnimation(_revealController),
                        curve: _isBackgroundRequested!
                            ? const Interval(0.0, 0.6, curve: Curves.easeInOut)
                            : const Interval(0.0, 1.0, curve: Curves.easeInOut),
                      ),
                    ),

                  // Top Layer Decoration - Revealing
                  // ✨ WRAPPED IN LiquidReveal again.
                  // This is the correct way to handle masking and prevent white flash.
                  if (isTablet)
                    _buildDecorationOnly(
                      showBackground: _isBackgroundRequested!,
                      isKeyboardOpen: isKeyboardOpen,
                      shouldShowResults: shouldShowResults,
                      scaleAnimation:
                          null, // No scale on tablet (Snapshot handles it)
                    )
                  else
                    LiquidReveal(
                      progress: revealProgress,
                      center: _revealCenter,
                      child: _buildDecorationOnly(
                        showBackground: _isBackgroundRequested!,
                        isKeyboardOpen: isKeyboardOpen,
                        shouldShowResults: shouldShowResults,
                        scaleAnimation: _revealController.isAnimating
                            ? CurvedAnimation(
                                parent: _revealController,
                                curve: const Interval(
                                  0.6,
                                  1.0,
                                  curve: Curves.easeOutBack,
                                ),
                              )
                            : null, // ✨ Fix: Default to 1.0 when not animating
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
          child: const Icon(Icons.auto_awesome),
          label: 'Ask Gita AI',
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: () => context.push(AppRoutes.askGita),
        ),
        SpeedDialChild(
          child: const Icon(Icons.menu_book),
          label: 'Browse Chapters',
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: () => context.push(AppRoutes.chapters),
        ),
        SpeedDialChild(
          child: const Icon(Icons.bookmark),
          label: 'Collections',
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: () => context.push(AppRoutes.bookmarks),
        ),
        SpeedDialChild(
          child: const Icon(Icons.auto_stories),
          label: 'Full Parayan',
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: () => context.push(AppRoutes.parayan),
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: 'Settings',
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          onTap: () => context.push(AppRoutes.settings),
        ),
        if (defaultTargetPlatform != TargetPlatform.iOS)
          SpeedDialChild(
            child: const Icon(Icons.headset),
            label: 'Manage Audio',
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
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
    final activeAiColor = isLightStyle ? Colors.orange[900]! : Colors.amber;

    // ✨ Dynamic Styling Logic
    Color currentBorderColor;
    double currentBorderWidth;
    List<BoxShadow> currentBoxShadow;

    if (_isAiMode) {
      // AI Mode Active
      currentBorderColor = activeAiColor;
      currentBorderWidth = _isSearchFocused ? 2.0 : 1.2;
      currentBoxShadow = _isSearchFocused
          ? [
              BoxShadow(
                color: activeAiColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ]
          : [];
    } else {
      // Standard Search
      if (_isSearchFocused) {
        // Focused: Use Primary Theme Color
        currentBorderColor = isLightStyle
            ? Theme.of(context).primaryColor
            : Colors.pinkAccent;
        currentBorderWidth = 2.0;
        currentBoxShadow = []; // Cleaner look for standard search
      } else {
        // Idle
        currentBorderColor = borderColor;
        currentBorderWidth = 1.2;
        currentBoxShadow = [];
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(50.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300), // ✨ Consistent 300ms
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(50.0),
            border: Border.all(
              color: currentBorderColor,
              width: currentBorderWidth,
            ),
            boxShadow: currentBoxShadow,
          ),
          child: TextField(
            controller: _searchController, // ✨ Bind controller
            focusNode: _searchFocusNode, // ✨ Attach FocusNode
            textInputAction: _isAiMode
                ? TextInputAction.send
                : TextInputAction.search, // ✨ Dynamic Action Button
            style: TextStyle(color: textColor),
            onChanged: (value) => provider.onSearchQueryChanged(value),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                if (_isAiMode) {
                  context.push(AppRoutes.askGita, extra: value);
                } else {
                  context.pushNamed(
                    'shloka-list',
                    pathParameters: {'query': value},
                  );
                }
              }
            },
            decoration: InputDecoration(
              hintText: _isAiMode
                  ? 'Ask Krishna anything...'
                  : 'Search the Gita...',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: Icon(Icons.search, color: hintColor),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAiMode && provider.searchQuery.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: activeAiColor,
                          size: 20,
                        ),
                        onPressed: () {
                          context.push(
                            AppRoutes.askGita,
                            extra: provider.searchQuery,
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Tooltip(
                      message: _isAiMode
                          ? 'Switch to Normal Search'
                          : 'Switch to AI Mode (Ask Krishna)',
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAiMode = !_isAiMode;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 64, // Fixed width for toggle pill
                          height: 32,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isAiMode
                                ? activeAiColor.withOpacity(0.25)
                                : Colors.grey.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isAiMode
                                  ? activeAiColor.withOpacity(0.8)
                                  : Colors.grey.withOpacity(0.5),
                              width: 1.5,
                            ),
                            boxShadow: _isAiMode
                                ? [
                                    BoxShadow(
                                      color: activeAiColor.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Stack(
                            children: [
                              // Text Labels background
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                alignment: _isAiMode
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: Text(
                                    _isAiMode ? 'AI' : '🔍',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _isAiMode
                                          ? activeAiColor
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              // Sliding Indicator
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOutBack,
                                alignment: _isAiMode
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: _isAiMode
                                        ? activeAiColor
                                        : (Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[300]
                                              : Colors.white),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isAiMode
                                        ? Icons.auto_awesome
                                        : Icons.search_outlined,
                                    size: 14,
                                    color: _isAiMode
                                        ? Colors.white
                                        : Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

class _OnboardingBubble extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _OnboardingBubble({required this.onTap, required this.onDismiss});

  @override
  State<_OnboardingBubble> createState() => _OnboardingBubbleState();
}

class _OnboardingBubbleState extends State<_OnboardingBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _floatAnimation = Tween<double>(
      begin: 0,
      end: -8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? const Color(0xFF424242) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.amber.withOpacity(0.5);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.scale(scale: _scaleAnimation.value, child: child),
          );
        },
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The Tail pointing up to the toggle
                Padding(
                  padding: const EdgeInsets.only(right: 20.0),
                  child: CustomPaint(
                    size: const Size(20, 10),
                    painter: _BubbleTailPainter(
                      color: bubbleColor,
                      borderColor: borderColor,
                    ),
                  ),
                ),
                // The Bubble Body
                GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 240),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Try Ask Krishna",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onDismiss,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _BubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Tip pointing up
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw only the two slanted sides for the border to merge with bubble
    final borderPath = Path();
    borderPath.moveTo(0, size.height);
    borderPath.lineTo(size.width / 2, 0);
    borderPath.lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
