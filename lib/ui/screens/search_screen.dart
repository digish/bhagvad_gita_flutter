import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../navigation/app_router.dart';
import '../../providers/search_provider.dart';
import '../widgets/darkened_animated_background.dart';
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
import '../../models/soul_status.dart';
import '../../providers/credit_provider.dart';
import '../../services/ad_service.dart';
import 'image_creator_screen.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../data/ai_questions.dart';

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
  int? _debugStreakOverride; // 🧪 Persist debug streak across screen
  String? _lastProcessedMayaMessage; // 🛡️ Prevent duplicate dialogs
  String? _todaysQuestion;

  void _loadTodaysQuestion() {
    if (mounted) {
      setState(() {
        _todaysQuestion = AiQuestionBank.getRandomSuggestions(count: 1).first;
      });
    }
  }

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
          _loadTodaysActionShloka();
          _loadTodaysQuestion();
        }
      });
    }

    // --- NEW: Check for Soul Status Message ---
    // Check this every time dependencies change (e.g. settings rebuild)
    if (settings.lastSoulStatusMessage != null &&
        settings.streakSystemEnabled) {
      final message = settings.lastSoulStatusMessage!;
      // Only show if we haven't already processed this exact message
      if (message != _lastProcessedMayaMessage) {
        _lastProcessedMayaMessage = message;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showMayaDialog(context, message, settings);
          }
        });
      }
    } else {
      // Clear tracking if no message is present
      _lastProcessedMayaMessage = null;
    }
  }

  void _showMayaDialog(
    BuildContext context,
    String message,
    SettingsProvider settings,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amberAccent, width: 1),
        ),
        title: Row(
          children: [
            Icon(Icons.sync_problem, color: Colors.amberAccent),
            SizedBox(width: 12),
            Text('Maya Check!', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              settings.clearSoulStatusMessage();
              Navigator.pop(context);
            },
            child: const Text(
              'I am back on the path',
              style: TextStyle(color: Colors.amberAccent),
            ),
          ),
        ],
      ),
    );
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

  void _handleBackAction() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    final provider = Provider.of<SearchProvider>(context, listen: false);
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      provider.onSearchQueryChanged('');
    }
    // Ensure UI updates to reflect search mode change
    if (mounted) {
      setState(() {});
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
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return PopScope(
      canPop: !shouldShowResults,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        _handleBackAction();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        // ✨ RESTORED: The floating action button for navigation.
        // It's hidden when the keyboard is visible.
        floatingActionButton: (isKeyboardOpen || width > 600)
            ? null
            : _buildSpeedDial(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Consumer<SettingsProvider>(
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
                              ? const Interval(
                                  0.0,
                                  0.6,
                                  curve: Curves.easeInOut,
                                )
                              : const Interval(
                                  0.0,
                                  1.0,
                                  curve: Curves.easeInOut,
                                ),
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
                              : const Color(
                                  0xFFF48FB1,
                                ), // ✨ Fix: Match Pink target
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

                      // ✨ NEW: Ad Download Verification Overlay
                      // This helps the user verify when an ad is downloading as requested in todo.txt
                      ValueListenableBuilder<String>(
                        valueListenable: AdService.instance.adStatus,
                        builder: (context, status, child) {
                          if (status == 'downloading') {
                            return Positioned(
                              top: MediaQuery.of(context).padding.top + 20,
                              right: 20,
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Ad Downloading...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (status == 'ready') {
                            // Briefly show "Ready" or just vanish.
                            // Let's vanish to kept it clean, but the logs will show it.
                            return const SizedBox.shrink();
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                      // Wrap the interactive UI in a SafeArea
                      SafeArea(
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
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
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          curve: Curves.easeInOut,
                                          height: shouldShowResults
                                              ? 16
                                              : (settings.showBackground
                                                    ? 260
                                                    : 60),
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
                                              _searchController.text =
                                                  suggestion;
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
                                              final credits =
                                                  Provider.of<CreditProvider>(
                                                    context,
                                                    listen: false,
                                                  ).balance;
                                              if (credits <= 0) {
                                                AdService.instance
                                                    .loadRewardedAd();
                                              }
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
                                            !shouldShowResults) ...[
                                          if (settings.streakSystemEnabled)
                                            _buildSoulStatusChip(settings),
                                          if (!settings.reminderEnabled)
                                            _buildReminderNudge(settings),
                                          _buildRandomShlokaCard(),
                                          _buildTodaysActionCard(), // ✨ NEW: Today's Action Card
                                          _buildTodaysQuestionCard(
                                            settings,
                                          ), // ✨ NEW: Today's Question Card
                                        ],
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
                                      if (index ==
                                          provider.searchResults.length) {
                                        return ListTile(
                                          leading: Icon(
                                            Icons.search,
                                            color:
                                                !settings.showBackground &&
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
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

                                      final item =
                                          provider.searchResults[index];
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
                                                  : Colors.amber.withOpacity(
                                                      0.8,
                                                    ),
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
                            // Should only be visible on phones in PORTRAIT mode.
                            if (MediaQuery.of(context).viewInsets.bottom == 0 &&
                                width <=
                                    600 && // Phone check (width-based is more reliable for hidden state)
                                !isLandscape) // Portrait check
                              Positioned(
                                left: 16,
                                bottom: 16,
                                child: FloatingActionButton(
                                  key: _themeToggleKey,
                                  heroTag: 'simple_theme_toggle',
                                  mini: true,
                                  // Use Theme Extension for colors
                                  backgroundColor:
                                      Theme.of(context)
                                          .extension<AppColors>()
                                          ?.simpleThemeToggle ??
                                      Theme.of(context).primaryColor,
                                  foregroundColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Colors.white,
                                  onPressed: () {
                                    if (_revealController.isAnimating) return;

                                    HapticFeedback.lightImpact();
                                    _captureThemeTogglePosition();
                                    setState(() {
                                      _isBackgroundRequested =
                                          !settings.showBackground;
                                    });
                                    _revealController.forward(from: 0).then((
                                      _,
                                    ) {
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
                                ? const Interval(
                                    0.0,
                                    0.6,
                                    curve: Curves.easeInOut,
                                  )
                                : const Interval(
                                    0.0,
                                    1.0,
                                    curve: Curves.easeInOut,
                                  ),
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
        ),
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
                  ? 'Ask Gita anything...'
                  : 'Search the Gita...',
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: _isSearchFocused
                  ? IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: _handleBackAction,
                    )
                  : Icon(Icons.search, color: hintColor),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✨ Clear Button
                  if (_searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: hintColor,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          provider.onSearchQueryChanged('');
                        },
                      ),
                    ),
                  // ✨ AI Mode Send Button
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
                          : 'Switch to AI Mode (Ask Gita)',
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isAiMode = !_isAiMode;
                          });
                          if (_isAiMode) {
                            final credits = Provider.of<CreditProvider>(
                              context,
                              listen: false,
                            ).balance;
                            if (credits <= 0) {
                              AdService.instance.loadRewardedAd();
                            }
                          }
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

  Widget _buildSoulStatusChip(SettingsProvider settings) {
    final int displayStreak = (kDebugMode && _debugStreakOverride != null)
        ? _debugStreakOverride!
        : settings.dailyStreak;
    final status = SoulStatus.getStatus(displayStreak);
    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: GestureDetector(
        onTap: () => _showEvolutionRoadmap(context, settings),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSimpleLight
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: status.color.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: status.color.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: status.imageAssetName != null
                    ? Image.asset(
                        'assets/soul_evolution/${status.imageAssetName}',
                        fit: BoxFit.contain,
                      )
                    : Icon(status.icon, color: status.color, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    status.title,
                    style: TextStyle(
                      color: isSimpleLight
                          ? Colors.brown.shade900
                          : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${displayStreak} Day Streak',
                    style: TextStyle(
                      color: isSimpleLight
                          ? Colors.brown.shade700
                          : Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                  if (kDebugMode && _debugStreakOverride != null)
                    const Text(
                      'DEBUG MODE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEvolutionRoadmap(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final int displayStreak =
              _debugStreakOverride ?? settings.dailyStreak;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 16,
                      top: 24,
                      bottom: 20,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    color: Colors.amberAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AURA ASCENT',
                                    style: TextStyle(
                                      color: Colors.amberAccent.withOpacity(
                                        0.8,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  if (kDebugMode) ...[
                                    // Change to kDebugMode to re-enable debug badge
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(
                                          0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DEBUG',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline: TextBaseline.alphabetic,
                                          children: [
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  '$displayStreak',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 48,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Orbitron',
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'DAY STREAK',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          SoulStatus.getStatus(
                                            displayStreak,
                                          ).title,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(
                                              0.35,
                                            ),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        // Lifeline display
                                        if (settings.availableLifelines >
                                            0) ...[
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.favorite,
                                                color: Colors.pink,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${settings.availableLifelines} ${settings.availableLifelines == 1 ? 'Lifeline' : 'Lifelines'}',
                                                style: const TextStyle(
                                                  color: Colors.pink,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Big last achieved emblem
                                  Builder(
                                    builder: (context) {
                                      final status = SoulStatus.getStatus(
                                        displayStreak,
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          left: 12,
                                        ),
                                        child: status.imageAssetName != null
                                            ? Image.asset(
                                                'assets/soul_evolution/${status.imageAssetName}',
                                                width: 72,
                                                height: 72,
                                                fit: BoxFit.contain,
                                              )
                                            : Icon(
                                                status.icon,
                                                size: 50,
                                                color: Colors.amberAccent
                                                    .withOpacity(0.8),
                                              ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if (kDebugMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 2,
                                      thumbColor: Colors.redAccent,
                                      activeTrackColor: Colors.redAccent
                                          .withOpacity(0.5),
                                      inactiveTrackColor: Colors.white10,
                                      overlayColor: Colors.redAccent
                                          .withOpacity(0.1),
                                    ),
                                    child: Slider(
                                      value: displayStreak.toDouble(),
                                      min: 0,
                                      max: 365,
                                      divisions: 365,
                                      label: '$displayStreak Days',
                                      onChanged: (val) {
                                        setDialogState(() {
                                          _debugStreakOverride = val.toInt();
                                        });
                                        // 🧪 Also update parent screen
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ),
                              // Debug action buttons
                              if (kDebugMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            await settings.debugAdvanceDay();
                                            setDialogState(() {});
                                            setState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            '+1 Day',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.greenAccent,
                                            side: BorderSide(
                                              color: Colors.greenAccent
                                                  .withOpacity(0.5),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () async {
                                            await settings.debugMissDays(1);
                                            setDialogState(() {});
                                            setState(() {});
                                          },
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 14,
                                          ),
                                          label: const Text(
                                            'Miss a Day',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                Colors.orangeAccent,
                                            side: BorderSide(
                                              color: Colors.orangeAccent
                                                  .withOpacity(0.5),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Peak Achievement Card
                  if (settings.peakStreakCount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.withOpacity(0.2),
                              Colors.orange.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Peak Achievement',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${settings.peakMilestone.title} • Achieved ${settings.peakAchievementCount} ${settings.peakAchievementCount == 1 ? 'time' : 'times'}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Max Streak: ${settings.peakStreakCount} Days',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Roadmap List
                  Flexible(
                    child: Builder(
                      builder: (context) {
                        // Calculate current milestone index for auto-scroll
                        final currentStatus = SoulStatus.getStatus(
                          displayStreak,
                        );
                        final currentIndex = SoulStatus.allMilestones
                            .indexWhere((m) => m.title == currentStatus.title);

                        return ScrollablePositionedList.builder(
                          itemCount: SoulStatus.allMilestones.length,
                          initialScrollIndex: currentIndex >= 0
                              ? currentIndex
                              : 0,
                          initialAlignment:
                              0.3, // Position current item at 30% from top
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemBuilder: (context, index) {
                            final milestone = SoulStatus.allMilestones[index];
                            final isReached =
                                displayStreak >= milestone.threshold;
                            final isCurrent =
                                currentStatus.title == milestone.title;
                            final isLast =
                                index == SoulStatus.allMilestones.length - 1;

                            return _RoadmapItem(
                              milestone: milestone,
                              isReached: isReached,
                              isCurrent: isCurrent,
                              isLast: isLast,
                              streak: displayStreak,
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Footer Actions
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (btnContext) {
                              return ElevatedButton.icon(
                                onPressed: () {
                                  final status = SoulStatus.getStatus(
                                    displayStreak,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageCreatorScreen(
                                        streak: displayStreak,
                                        achievementStatus: status,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Share Progress'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amberAccent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderNudge(SettingsProvider settings) {
    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;

    if (settings.reminderNudgeDismissed) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 24, right: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSimpleLight
              ? Colors.pink.withOpacity(0.05)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InkWell(
                onTap: () {
                  settings.setReminderEnabled(true);
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.notification_add,
                        size: 14,
                        color: isSimpleLight ? Colors.pink : Colors.amberAccent,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Remind me daily to maintain my streak',
                          style: TextStyle(
                            color: isSimpleLight
                                ? Colors.pink[800]
                                : Colors.amberAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => settings.dismissReminderNudge(),
              icon: Icon(
                Icons.close,
                size: 14,
                color: isSimpleLight ? Colors.pink[200] : Colors.white24,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 12,
              tooltip: 'Dismiss',
            ),
          ],
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

          // ✨ NEW: Because getShlokasForList optimizes memeory by not fetching commentaries,
          // we must explicitly fetch them for the single chosen random shloka.
          if (result.commentaries == null || result.commentaries!.isEmpty) {
            final commentaries = await db.getCommentariesForShloka(
              result.chapterNo,
              result.shlokNo,
            );
            // Create a new ShlokaResult instance with the fetched commentaries
            result = ShlokaResult.fromMap(
              {
                'id': result.id,
                'chapter_no': result.chapterNo,
                'shloka_no': result.shlokNo,
                'shloka_text': result.shlok,
                'anvay_text': result.anvay,
                'bhavarth': result.bhavarth,
                'speaker': result.speaker,
                'sanskrit_romanized': result.sanskritRomanized,
                'audio_path': result.audioPath,
                'matched_category': result.matchedCategory,
                'match_snippet': result.matchSnippet,
              },
              commentaries: commentaries,
              categorySnippets: result.categorySnippets,
            );
          }

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

  // Today's Action Logic
  ShlokaResult? _todaysActionShloka;
  bool _loadingAction = false;
  bool _isActionExpanded = false;

  Future<void> _loadTodaysActionShloka() async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (mounted) {
      setState(() {
        _loadingAction = true;
        _isActionExpanded = false; // Reset expansion state on refresh
      });
    }

    try {
      final db = Provider.of<DatabaseHelperInterface>(context, listen: false);

      // Select any random from entire Gita
      var result = await db.getRandomShloka(
        language: settings.language,
        script: settings.script,
      );

      if (result != null) {
        // We ALWAYS need commentaries for Today's Action card since it relies on AI Insights
        final commentaries = await db.getCommentariesForShloka(
          result.chapterNo,
          result.shlokNo,
        );
        result = ShlokaResult.fromMap(
          {
            'id': result.id,
            'chapter_no': result.chapterNo,
            'shloka_no': result.shlokNo,
            'shloka_text': result.shlok,
            'anvay_text': result.anvay,
            'bhavarth': result.bhavarth,
            'speaker': result.speaker,
            'sanskrit_romanized': result.sanskritRomanized,
            'audio_path': result.audioPath,
            'matched_category': result.matchedCategory,
            'match_snippet': result.matchSnippet,
          },
          commentaries: commentaries,
          categorySnippets: result.categorySnippets,
        );
      }

      if (mounted) {
        setState(() {
          _todaysActionShloka = result;
          _loadingAction = false;
        });
      }
    } catch (e) {
      debugPrint('SearchScreen: Error loading todays action: $e');
      if (mounted) {
        setState(() {
          _loadingAction = false;
        });
      }
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

  Widget _buildTodaysActionCard() {
    if (_loadingAction || _todaysActionShloka == null)
      return const SizedBox.shrink();

    // Look for AI commentary
    final aiCommentary = _todaysActionShloka!.commentaries?.firstWhere(
      (c) => c.authorName == 'AI Generated' || c.authorName == 'AI Insights',
      orElse: () => Commentary(authorName: '', languageCode: '', content: ''),
    );

    if (aiCommentary == null || aiCommentary.authorName.isEmpty)
      return const SizedBox.shrink();

    final modernCommentary = aiCommentary.modern;
    if (modernCommentary == null || modernCommentary.actionableTakeaway.isEmpty)
      return const SizedBox.shrink();

    final settings = Provider.of<SettingsProvider>(context);
    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;

    final cardColor = isSimpleLight
        ? Colors.white.withOpacity(0.9)
        : Colors.amber.shade900.withOpacity(0.3);

    final borderColor = isSimpleLight
        ? Colors.pink.withOpacity(0.3)
        : Colors.amberAccent.withOpacity(0.3);

    final titleColor = isSimpleLight
        ? Colors.pink.shade900
        : Colors.amberAccent;

    final textColor = isSimpleLight ? Colors.brown.shade900 : Colors.white;

    final iconColor = isSimpleLight ? Colors.pink.shade700 : Colors.amberAccent;

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          // Toggle expansion
          setState(() {
            _isActionExpanded = !_isActionExpanded;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isSimpleLight
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_walk_rounded,
                    color: iconColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "TODAY's ACTION",
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.refresh, size: 18, color: iconColor),
                      onPressed: _loadTodaysActionShloka,
                      tooltip: 'Refresh Action',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                crossFadeState: _isActionExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
                firstChild: Text(
                  modernCommentary.actionableTakeaway,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modernCommentary.actionableTakeaway,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(color: borderColor),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: iconColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          // Navigate to the book reading mode and scroll to the specific shloka
                          context.push(
                            AppRoutes.bookReading.replaceFirst(
                              ':chapter',
                              _todaysActionShloka!.chapterNo,
                            ),
                            extra: int.tryParse(_todaysActionShloka!.shlokNo),
                          );
                        },
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: Text(
                          'Chapter ${_todaysActionShloka!.chapterNo}, Shloka ${_todaysActionShloka!.shlokNo} \u2192',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysQuestionCard(SettingsProvider settings) {
    if (_todaysQuestion == null || _todaysQuestion!.isEmpty)
      return const SizedBox.shrink();

    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;

    final cardColor = isSimpleLight
        ? Colors.white.withOpacity(0.9)
        : Colors.indigo.shade900.withOpacity(0.3);

    final borderColor = isSimpleLight
        ? Colors.blue.withOpacity(0.3)
        : Colors.blueAccent.withOpacity(0.3);

    final textColor = isSimpleLight ? Colors.indigo.shade900 : Colors.white;

    final iconColor = isSimpleLight
        ? Colors.blue.shade700
        : Colors.lightBlueAccent;

    return Padding(
      padding: const EdgeInsets.only(
        top: 16.0,
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
      ), // Extra bottom padding for the final card
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          // Trigger searching this question via AI
          _searchController.text = _todaysQuestion!;
          Provider.of<SearchProvider>(
            context,
            listen: false,
          ).onSearchQueryChanged(_todaysQuestion!);
          _searchFocusNode.unfocus();
          setState(() {
            _isAiMode = true; // explicitly enter AI mode
          });
          context.push(AppRoutes.askGita, extra: _todaysQuestion);
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isSimpleLight
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_alt, color: iconColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: _todaysQuestion!,
                            style: TextStyle(
                              color: textColor.withOpacity(0.9),
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          TextSpan(
                            text: ' Ask GITA \u2192',
                            style: TextStyle(
                              color: iconColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.refresh, size: 18, color: iconColor),
                      onPressed: _loadTodaysQuestion,
                      tooltip: 'Next Question',
                    ),
                  ),
                ],
              ),
            ],
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
                                "Try Ask Gita",
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

class _RoadmapItem extends StatelessWidget {
  final SoulStatus milestone;
  final bool isReached;
  final bool isCurrent;
  final bool isLast;
  final int streak;

  const _RoadmapItem({
    required this.milestone,
    required this.isReached,
    required this.isCurrent,
    required this.isLast,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    // Reached stages: Big Golden Trophy + Sudarshan Chakra
    // Future stages: Big Icon
    final double outerCircleSize = 96.0;
    // final double iconSize = 24.0; // This variable was unused, removed for linting.

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Line & Dot
          Column(
            children: [
              SizedBox(
                width: outerCircleSize,
                height: outerCircleSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isCurrent)
                      _SudarshanChakra(
                        size: 96,
                        color: Colors.amber,
                        isSpinning: true,
                      ),
                    Container(
                      width: 76,
                      height: 76,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors
                            .transparent, // Background removed as requested
                        shape: BoxShape.circle,
                        border: isCurrent
                            ? Border.all(
                                color: Colors.white.withOpacity(0.5),
                                width: 1,
                              )
                            : null,
                        boxShadow: isReached
                            ? [
                                BoxShadow(
                                  color: milestone.color.withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: milestone.imageAssetName != null
                            ? ColorFiltered(
                                colorFilter: isReached
                                    ? const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.dst,
                                      )
                                    : const ColorFilter.matrix([
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                      ]),
                                child: Image.asset(
                                  'assets/soul_evolution/${milestone.imageAssetName}',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        isReached
                                            ? Icons.emoji_events
                                            : milestone.icon,
                                        size: 40,
                                        color: isReached
                                            ? Colors.amberAccent
                                            : Colors.white24,
                                      ),
                                ),
                              )
                            : Icon(
                                isReached ? Icons.emoji_events : milestone.icon,
                                size: 40,
                                color: isReached
                                    ? Colors.amberAccent
                                    : Colors.white24,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: SizedBox(
                    width: outerCircleSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 6,
                          color: isReached
                              ? milestone.color.withOpacity(0.5)
                              : Colors.grey[800],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 32),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48.0, top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: TextStyle(
                      color: isReached ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    milestone.description,
                    style: TextStyle(
                      color: isReached ? Colors.white70 : Colors.white24,
                      fontSize: 13,
                      fontStyle: isReached ? FontStyle.italic : null,
                    ),
                  ),
                  if (!isReached) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${milestone.threshold - streak} days to go',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SudarshanChakra extends StatefulWidget {
  final double size;
  final Color color;
  final bool isSpinning;

  const _SudarshanChakra({
    required this.size,
    required this.color,
    this.isSpinning = true,
  });

  @override
  State<_SudarshanChakra> createState() => _SudarshanChakraState();
}

class _SudarshanChakraState extends State<_SudarshanChakra>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    if (widget.isSpinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_SudarshanChakra oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2.0 * math.pi,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ChakraPainter(color: widget.color),
          ),
        );
      },
    );
  }
}

class _ChakraPainter extends CustomPainter {
  final Color color;
  _ChakraPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer circle
    canvas.drawCircle(center, radius, paint);

    // Spokes/Blades
    final int blades = 12;
    for (int i = 0; i < blades; i++) {
      final double angle = (i * 2 * math.pi) / blades;
      final Offset p1 = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      final Offset p2 = Offset(
        center.dx + radius * math.cos(angle + 0.1),
        center.dy + radius * math.sin(angle + 0.1),
      );
      canvas.drawLine(p1, p2, paint);
    }

    // Inner glowing ring
    canvas.drawCircle(
      center,
      radius - 8,
      paint..color = color.withOpacity(0.3),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
