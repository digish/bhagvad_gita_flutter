import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../navigation/app_router.dart';
import '../../navigation/shloka_navigation.dart';
import '../../providers/search_provider.dart';
import '../widgets/darkened_animated_background.dart';
import '../widgets/shloka_result_card.dart';
import '../widgets/word_result_card.dart';
import '../widgets/decorative_foreground.dart';
import '../widgets/simple_gradient_background.dart';
import '../widgets/ai_suggestion_chips.dart'; // ✨ Add AI Suggestions
import '../widgets/sacred_sutra_promo_card.dart';
import '../../providers/settings_provider.dart';
import '../../data/database_helper_interface.dart';
import '../widgets/responsive_wrapper.dart';
import '../widgets/onboarding_bubble.dart';
import '../widgets/liquid_reveal.dart';
import '../widgets/main_scaffold.dart';
import '../../models/shloka_list.dart';
import '../../models/shloka_result.dart';
import '../../providers/bookmark_provider.dart';
import '../../navigation/route_observer.dart';
import '../../data/static_data.dart';
import '../theme/app_colors.dart';
import '../config/home_bookmark_layout.dart';
import '../../services/home_widget_service.dart';
import '../../services/ask_gita_service.dart';
import '../../models/soul_status.dart';
import '../../providers/credit_provider.dart';
import '../../services/ad_service.dart';
import 'image_creator_screen.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../../data/ai_questions.dart';

class SearchScreen extends StatelessWidget {
  /// Settings → Help: Home & search — replay floating onboarding tips.
  final bool showSearchHints;

  const SearchScreen({super.key, this.showSearchHints = false});

  @override
  Widget build(BuildContext context) {
    // Read the globally provided database helper
    final dbHelper = Provider.of<DatabaseHelperInterface>(
      context,
      listen: false,
    );
    final language = Provider.of<SettingsProvider>(context).language;
    final script = Provider.of<SettingsProvider>(context).script;
    final shlokaScript = Provider.of<SettingsProvider>(context).shlokaScript;

    return ChangeNotifierProvider(
      key: ValueKey(
        '$language-$script-$shlokaScript',
      ), // Force re-creation when language or script changes
      create: (_) => SearchProvider(
        dbHelper,
        language,
        script,
        shlokaScript: shlokaScript,
      ), // Re-creates on change
      child: _SearchScreenView(showSearchHints: showSearchHints),
    );
  }
}

class _SearchScreenView extends StatefulWidget {
  final bool showSearchHints;

  const _SearchScreenView({this.showSearchHints = false});

  @override
  State<_SearchScreenView> createState() => _SearchScreenViewState();
}

class _SearchScreenViewState extends State<_SearchScreenView>
    with RouteAware, TickerProviderStateMixin {
  late final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(); // ✨ Track focus
  bool _isAiMode = false; // ✨ Toggle for AI Mode
  /// Keeps AI suggestion taps from triggering [TextField.onTapOutside].
  static final Object _homeSearchTapRegionGroup = Object();
  static bool _hasCheckedLanguagePrompt = false; // Flag to prevent multiple dialogs
  bool _isSearchFocused = false;
  /// Home chrome collapsed for search (same as focus, but safe to drive layout).
  bool _collapseHomeForSearch = false;
  late AnimationController _revealController;
  late AnimationController _pulseController;
  late AnimationController _minimalHomeController;
  late AnimationController _searchCollapseController;
  late AnimationController
  _lotusController; // 🌸 Continuous rotation controller
  bool? _trackedMinimalHomeLayout;
  bool? _trackedSearchCollapsed;
  final ScrollController _homeScrollController = ScrollController();
  /// How far the top lotuses have been pushed up with home scroll.
  /// Clamped to >= 0 so they never settle below their resting position.
  final ValueNotifier<double> _lotusLift = ValueNotifier(0.0);
  Offset _revealCenter = Offset.zero;
  final GlobalKey _themeToggleKey = GlobalKey();
  /// Keeps the home search field mounted when its parent moves (minimal layout).
  final GlobalKey _homeSearchBarKey = GlobalKey();
  bool? _isBackgroundRequested;
  Set<int>? _lastKnownSources; // Cache for change detection
  int? _debugStreakOverride; // 🧪 Persist debug streak across screen
  String? _todaysQuestion;
  ValueNotifier<Widget?>? _coachOverlayRef;
  bool _railThemeCoachVisible = false;
  ModalRoute<void>? _routeSubscription;

  void _syncRailThemeCoachOverlay({
    required bool show,
    required SettingsProvider settings,
  }) {
    final overlay = _coachOverlayRef;
    if (overlay == null) return;

    if (!show) {
      if (_railThemeCoachVisible) {
        _railThemeCoachVisible = false;
        overlay.value = null;
      }
      return;
    }

    if (_railThemeCoachVisible && overlay.value != null) return;

    _railThemeCoachVisible = true;
    overlay.value = _RailThemeHintOverlay(
      onTap: () {
        settings.markThemeHintUsed();
        _syncRailThemeCoachOverlay(show: false, settings: settings);
      },
      onDismiss: () {
        settings.markThemeHintUsed();
        _syncRailThemeCoachOverlay(show: false, settings: settings);
      },
    );
  }

  Future<void> _loadTodaysQuestion() async {
    final suggestions = await AiQuestionBank.getNonRepeatingRandomSuggestions(
      count: 1,
    );
    if (mounted && suggestions.isNotEmpty) {
      setState(() {
        _todaysQuestion = suggestions.first;
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

    _minimalHomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _searchCollapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 🌸 Initialize continuous lotus rotation (10s per revolution)
    _lotusController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    // Removed explicit postFrameCallback here; handled in didChangeDependencies

    // ✨ Listen to focus changes (search bar chrome only — not layout collapse).
    _searchFocusNode.addListener(_onSearchFocusChanged);

    // Top lotuses scroll up with home content, but never below their rest position.
    _homeScrollController.addListener(_onHomeScroll);
    if (widget.showSearchHints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _replaySearchOnboardingHints();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _SearchScreenView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSearchHints && !oldWidget.showSearchHints) {
      _replaySearchOnboardingHints();
    }
  }

  Future<void> _replaySearchOnboardingHints() async {
    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.resetSearchOnboardingHints();
    if (!mounted) return;
    GoRouter.of(context).go('/');
  }

  void _onSearchFocusChanged() {
    if (!mounted) return;
    final hasFocus = _searchFocusNode.hasFocus;
    if (hasFocus) {
      if (_homeScrollController.hasClients &&
          _homeScrollController.offset > 0) {
        _homeScrollController.jumpTo(0);
      }
      _lotusLift.value = 0;
      if (_isSearchFocused && _collapseHomeForSearch) return;
      setState(() {
        _isSearchFocused = true;
        _collapseHomeForSearch = true;
      });
    } else {
      if (!_isSearchFocused && !_collapseHomeForSearch) return;
      setState(() {
        _isSearchFocused = false;
        _collapseHomeForSearch = false;
      });
    }
  }

  /// Resets scroll/lift and search-collapse so the home search bar stays visible
  /// after returning from a pushed route (e.g. Ask Gita).
  void _restoreHomeSearchChrome() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    if (_homeScrollController.hasClients && _homeScrollController.offset > 0) {
      _homeScrollController.jumpTo(0);
    }
    _lotusLift.value = 0;
    if (!_isSearchFocused && !_collapseHomeForSearch) return;
    if (!mounted) return;
    setState(() {
      _isSearchFocused = false;
      _collapseHomeForSearch = false;
    });
  }

  void _navigateToAskGita([String? query]) {
    _restoreHomeSearchChrome();
    if (query != null && query.trim().isNotEmpty) {
      context.push(AppRoutes.askGita, extra: query.trim());
    } else {
      context.push(AppRoutes.askGita);
    }
  }

  @override
  void didPopNext() {
    _restoreHomeSearchChrome();
  }

  bool _showHomeOnboardingHints(SettingsProvider settings) {
    return settings.hasSeenLanguagePrompt &&
        settings.homeUiMode != HomeUiMode.minimal &&
        !_isSearchFocused &&
        MediaQuery.of(context).viewInsets.bottom == 0 &&
        _searchController.text.isEmpty;
  }

  bool _isMinimalHomeLayout(
    SettingsProvider settings,
    bool shouldShowResults,
  ) {
    return settings.homeUiMode == HomeUiMode.minimal && !shouldShowResults;
  }

  bool _showsSimpleModeNavButtons(SettingsProvider settings, double width) {
    return width <= 600 &&
        (settings.homeUiMode == HomeUiMode.minimal ||
            !settings.showBackground);
  }

  /// Hide lotus/cards until the centered minimal layout has fully settled.
  bool _suppressHomeChromeDuringMinimalLayout(SettingsProvider settings) {
    return settings.homeUiMode == HomeUiMode.minimal &&
        (_minimalHomeController.isAnimating ||
            _minimalHomeController.value < 1.0);
  }

  void _syncMinimalHomeLayoutAnimation(bool isMinimalHome) {
    if (_trackedMinimalHomeLayout == null) {
      _trackedMinimalHomeLayout = isMinimalHome;
      _minimalHomeController.value = isMinimalHome ? 1.0 : 0.0;
      return;
    }
    if (_trackedMinimalHomeLayout == isMinimalHome) return;
    _trackedMinimalHomeLayout = isMinimalHome;
    if (isMinimalHome) {
      _minimalHomeController.forward();
    } else {
      _minimalHomeController.reverse();
    }
  }

  void _syncSearchCollapseAnimation(bool collapsed) {
    if (_trackedSearchCollapsed == null) {
      _trackedSearchCollapsed = collapsed;
      _searchCollapseController.value = collapsed ? 1.0 : 0.0;
      return;
    }
    if (_trackedSearchCollapsed == collapsed) return;
    _trackedSearchCollapsed = collapsed;
    if (collapsed) {
      _searchCollapseController.forward();
    } else {
      _searchCollapseController.reverse();
    }
  }

  Widget _buildHomeUiModeToggleFab(SettingsProvider settings) {
    final appColors = Theme.of(context).extension<AppColors>();
    return FloatingActionButton(
      key: _themeToggleKey,
      heroTag: 'simple_theme_toggle',
      shape: const CircleBorder(),
      backgroundColor:
          appColors?.speedDialBg ?? Theme.of(context).colorScheme.primary,
      foregroundColor:
          appColors?.speedDialFg ?? Theme.of(context).colorScheme.onPrimary,
      elevation: 6,
      highlightElevation: 12,
      onPressed: () => _cycleHomeUiModeFromToggle(settings),
      child: Icon(
        settings.homeUiMode.layoutToggleIcon,
        size: 24,
      ),
    );
  }

  Future<void> _cycleHomeUiModeFromToggle(SettingsProvider settings) async {
    if (_revealController.isAnimating) {
      return;
    }

    HapticFeedback.lightImpact();
    _captureThemeTogglePosition();
    _resetLotusScrollLift();

    final current = settings.homeUiMode;
    final next = settings.nextHomeUiMode;
    final backgroundChanges =
        current.showsDecorativeBackground != next.showsDecorativeBackground;

    if (backgroundChanges) {
      setState(() {
        _isBackgroundRequested = next.showsDecorativeBackground;
      });
      await _revealController.forward(from: 0);
      if (!mounted) return;
      await settings.setHomeUiMode(next);
      _ensureLotusLiftSynced();
    } else {
      await settings.setHomeUiMode(next);
      if (mounted) setState(() {});
    }
  }

  void _onHomeScroll() {
    if (!_homeScrollController.hasClients) return;
    // Negative overscroll (pull down) keeps lift at 0 — lotuses stay at rest.
    final lift = _homeScrollController.offset.clamp(0.0, double.infinity);
    if (lift != _lotusLift.value) {
      _lotusLift.value = lift;
    }
  }

  /// Sync lotus overlay to the current scroll offset (no motion).
  void _ensureLotusLiftSynced() {
    if (_homeScrollController.hasClients) {
      _lotusLift.value =
          _homeScrollController.offset.clamp(0.0, double.infinity);
    } else {
      _lotusLift.value = 0.0;
    }
  }

  /// Ease home scroll (and lotus lift) back to rest after theme / layout changes.
  Future<void> _resetLotusScrollLift() async {
    final gate = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (!mounted) return;
        final hasScroll = _homeScrollController.hasClients;
        final offset = hasScroll ? _homeScrollController.offset : 0.0;

        if (hasScroll && offset > 0.5) {
          // Lotuses track scroll via listener — ease both down together.
          await _homeScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
          );
        } else if (_lotusLift.value > 0.5) {
          // Scroll already at top but overlay lift is stale — ease lotuses down.
          final start = _lotusLift.value;
          final controller = AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 750),
          );
          final animation = CurvedAnimation(
            parent: controller,
            curve: Curves.easeOutCubic,
          );
          void tick() {
            _lotusLift.value = start * (1.0 - animation.value);
          }

          animation.addListener(tick);
          try {
            await controller.forward();
          } finally {
            animation.removeListener(tick);
            controller.dispose();
          }
        }
        if (mounted) {
          _lotusLift.value = 0.0;
        }
      } finally {
        if (!gate.isCompleted) gate.complete();
      }
    });
    return gate.future;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void> && route != _routeSubscription) {
      routeObserver.unsubscribe(this);
      _routeSubscription = route;
      routeObserver.subscribe(this, route);
    }
    _coachOverlayRef = HelpRailAnchors.maybeOf(context)?.coachOverlay;
    final settings = Provider.of<SettingsProvider>(context);
    final newSources = settings.randomShlokaSources;

    if (settings.isInitialized && !_hasCheckedLanguagePrompt && !settings.hasSeenLanguagePrompt) {
      _hasCheckedLanguagePrompt = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showLanguagePromptDialog(context, settings);
        }
      });
    }

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
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _coachOverlayRef?.value = null;
    _homeScrollController.removeListener(_onHomeScroll);
    _homeScrollController.dispose();
    _lotusLift.dispose();
    _revealController.dispose();
    _pulseController.dispose();
    _minimalHomeController.dispose();
    _searchCollapseController.dispose();
    _lotusController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    _restoreHomeSearchChrome();
  }

  void _toggleAiMode() {
    final keepSearchExpanded =
        _searchFocusNode.hasFocus ||
        _collapseHomeForSearch ||
        MediaQuery.of(context).viewInsets.bottom > 0;
    setState(() {
      _isAiMode = !_isAiMode;
      if (keepSearchExpanded) {
        _isSearchFocused = true;
        _collapseHomeForSearch = true;
      }
    });
    if (keepSearchExpanded && !_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
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
    final settings = Provider.of<SettingsProvider>(context);
    final isSearching = provider.searchQuery.isNotEmpty;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final shouldShowResults =
        isSearching || isKeyboardOpen || _collapseHomeForSearch;
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final showOnboarding = _showHomeOnboardingHints(settings) && !shouldShowResults;
    final isMinimalHome = _isMinimalHomeLayout(settings, shouldShowResults);
    _syncMinimalHomeLayoutAnimation(isMinimalHome);
    _syncSearchCollapseAnimation(shouldShowResults);
    final showRailThemeCoach =
        width > 600 &&
        MediaQuery.of(context).viewInsets.bottom == 0 &&
        !settings.hasUsedThemeHint &&
        showOnboarding;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncRailThemeCoachOverlay(
        show: showRailThemeCoach,
        settings: settings,
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        } else if (shouldShowResults) {
          _handleBackAction();
        } else {
          // Fallback
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        // ✨ RESTORED: The floating action button for navigation.
        // It's hidden when the keyboard is visible.
        floatingActionButton: (isKeyboardOpen || width > 600)
            ? null
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!settings.hasUsedExploreMore && showOnboarding)
                    OnboardingBubble(
                      text: "Explore more",
                      icon: Icons.explore_outlined,
                      pointingDown: true,
                      onTap: () => settings.markExploreMoreUsed(),
                      onDismiss: () => settings.markExploreMoreUsed(),
                    ),
                  const SizedBox(height: 12),
                  _buildSpeedDial(context),
                ],
              ),
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
                  _resetLotusScrollLift();
                  _revealController.forward(from: 0);
                } else {
                  // Phone/Narrow layout - just sync state without animation if we can't determine source,
                  // or maybe we should just snap?
                  // Ideally this case doesn't happen often as the FAB is the only changer,
                  // but if it did, we just update local state.
                  _isBackgroundRequested = settings.showBackground;
                  _resetLotusScrollLift();
                }
              } else if (!_revealController.isAnimating) {
                // Ensure strict sync when idle
                _isBackgroundRequested = settings.showBackground;
              }

              return AnimatedBuilder(
                animation: Listenable.merge([
                  _revealController,
                  _minimalHomeController,
                ]),
                builder: (context, _) {
                  // 🌸 Sequence Logic:
                  // On Phones (!isTablet), we run a local LiquidReveal.
                  // On Tablets (isTablet), MainScaffold already has a global LiquidReveal.
                  // In both cases, we use Intervals to time the lotus growth.

                  final bool isAnimating = _revealController.isAnimating;
                  final effectiveShouldShowResults = shouldShowResults ||
                      _suppressHomeChromeDuringMinimalLayout(settings);

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
                    shouldShowResults: effectiveShouldShowResults,
                    excludeDecoration: true,
                  );

                  Widget newBackground = _buildBackgroundOnly(
                    showBackground: _isBackgroundRequested!,
                    isKeyboardOpen: isKeyboardOpen,
                    shouldShowResults: effectiveShouldShowResults,
                    excludeDecoration: true,
                  );

                  return Stack(
                    clipBehavior: Clip.none,
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
                      if (kDebugMode)
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
                                      color: Colors.blueAccent.withOpacity(
                                        0.95,
                                      ),
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
                          clipBehavior: Clip.none,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 16.0,
                                  left: 16.0,
                                  right: 16.0,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxHeight =
                                        MediaQuery.sizeOf(context).height -
                                        MediaQuery.paddingOf(context).top -
                                        MediaQuery.paddingOf(context).bottom -
                                        16;
                                    return SizedBox(
                                      height: maxHeight,
                                      child: ResponsiveWrapper(
                                        maxWidth: 600,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: AnimatedBuilder(
                                                animation: Listenable.merge([
                                                  _minimalHomeController,
                                                  _searchCollapseController,
                                                ]),
                                                builder: (context, _) {
                                                  final minimalT =
                                                      Curves.easeInOutCubic
                                                          .transform(
                                                    _minimalHomeController
                                                        .value,
                                                  );
                                                  final collapseT =
                                                      Curves.easeInOutCubic
                                                          .transform(
                                                    _searchCollapseController
                                                        .value,
                                                  );
                                                  final showSimpleNav =
                                                      _showsSimpleModeNavButtons(
                                                    settings,
                                                    width,
                                                  ) &&
                                                      collapseT < 1.0;
                                                  const searchBarHeight = 52.0;
                                                  const navBlockHeight = 54.0;

                                                  return LayoutBuilder(
                                                    builder: (context,
                                                        constraints) {
                                                      final maxHeight =
                                                          constraints.maxHeight;
                                                      final homeHeaderSpacer =
                                                          settings
                                                                  .showBackground
                                                              ? (isTablet
                                                                    ? 300.0
                                                                    : 190.0)
                                                              : 4.0;
                                                      const searchHeaderSpacer =
                                                          16.0;
                                                      final headerSpacer =
                                                          lerpDouble(
                                                                homeHeaderSpacer,
                                                                searchHeaderSpacer,
                                                                collapseT,
                                                              ) ??
                                                              searchHeaderSpacer;
                                                      final homeSoulBlockHeight =
                                                          _homeHeaderActionsRowHeight(
                                                        isTablet,
                                                      );
                                                      final soulBlockHeight =
                                                          lerpDouble(
                                                                homeSoulBlockHeight,
                                                                0.0,
                                                                collapseT,
                                                              ) ??
                                                              0.0;
                                                      final homeSearchHintHeight =
                                                          (showOnboarding &&
                                                                  !settings
                                                                      .hasUsedSearchBarHint)
                                                              ? 72.0
                                                              : 0.0;
                                                      final searchHintHeight =
                                                          lerpDouble(
                                                                homeSearchHintHeight,
                                                                0.0,
                                                                collapseT,
                                                              ) ??
                                                              0.0;
                                                      final topContentEnd =
                                                          headerSpacer +
                                                              soulBlockHeight +
                                                              searchHintHeight;
                                                      final topSearchY =
                                                          topContentEnd +
                                                              (showSimpleNav
                                                                  ? navBlockHeight
                                                                  : 0.0);
                                                      final groupHeight =
                                                          (showSimpleNav
                                                                  ? navBlockHeight
                                                                  : 0.0) +
                                                              searchBarHeight;
                                                      final minimalNavY =
                                                          (maxHeight -
                                                                  groupHeight) /
                                                              2;
                                                      final minimalSearchY =
                                                          minimalNavY +
                                                              (showSimpleNav
                                                                  ? navBlockHeight
                                                                  : 0.0);
                                                      final navY = showSimpleNav
                                                          ? lerpDouble(
                                                              topContentEnd,
                                                              minimalNavY,
                                                              minimalT,
                                                            )!
                                                          : 0.0;
                                                      final searchY = lerpDouble(
                                                        topSearchY,
                                                        minimalSearchY,
                                                        minimalT,
                                                      )!;
                                                      final topBookmarkY =
                                                          headerSpacer;
                                                      final minimalBookmarkY =
                                                          showSimpleNav
                                                              ? minimalNavY -
                                                                  soulBlockHeight
                                                              : minimalSearchY -
                                                                  soulBlockHeight;
                                                      final bookmarkY = lerpDouble(
                                                        topBookmarkY,
                                                        minimalBookmarkY,
                                                        minimalT,
                                                      )!;
                                                      final showAiSuggestions =
                                                          _isSearchFocused &&
                                                          _isAiMode &&
                                                          provider
                                                              .searchQuery
                                                              .isEmpty;
                                                      final showBookmarkOverlayInMinimal =
                                                          settings.homeUiMode ==
                                                              HomeUiMode
                                                                  .minimal &&
                                                          !shouldShowResults &&
                                                          !showAiSuggestions;
                                                      final homeFade = showAiSuggestions
                                                          ? 1.0
                                                          : settings
                                                                      .homeUiMode ==
                                                                  HomeUiMode
                                                                      .minimal
                                                              ? 0.0
                                                              : ((1 -
                                                                          minimalT) *
                                                                      (1 -
                                                                          collapseT))
                                                                  .clamp(
                                                                  0.0,
                                                                  1.0,
                                                                );

                                                      return ValueListenableBuilder<
                                                          double>(
                                                        valueListenable:
                                                            _lotusLift,
                                                        builder: (context,
                                                            scrollLift, _) {
                                                          final scrollComp =
                                                              scrollLift *
                                                                  (1.0 -
                                                                      minimalT);

                                                          return Stack(
                                                        clipBehavior: Clip.none,
                                                        children: [
                                                          Opacity(
                                                            opacity: homeFade,
                                                            child:
                                                                IgnorePointer(
                                                              ignoring:
                                                                  minimalT >
                                                                          0.5 &&
                                                                      !showAiSuggestions,
                                                              child:
                                                                  SingleChildScrollView(
                                                                controller:
                                                                    _homeScrollController,
                                                                  clipBehavior:
                                                                      Clip.none,
                                                                  physics:
                                                                      minimalT >=
                                                                              1.0
                                                                          ? const NeverScrollableScrollPhysics()
                                                                          : null,
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .stretch,
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: [
                                                                      AnimatedSize(
                                                                        duration:
                                                                            const Duration(
                                                                          milliseconds:
                                                                              400,
                                                                        ),
                                                                        curve: Curves
                                                                            .easeInOut,
                                                                        alignment:
                                                                            Alignment
                                                                                .topCenter,
                                                                        clipBehavior:
                                                                            Clip
                                                                                .none,
                                                                        child: shouldShowResults
                                                                            ? const SizedBox(
                                                                                height:
                                                                                    16,
                                                                                width:
                                                                                    double.infinity,
                                                                              )
                                                                            : Column(
                                                                                mainAxisSize:
                                                                                    MainAxisSize.min,
                                                                                crossAxisAlignment:
                                                                                    CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  SizedBox(
                                                                                    height:
                                                                                        headerSpacer,
                                                                                  ),
                                                                                  _buildHomeHeaderActionsRow(
                                                                                    settings,
                                                                                    showBookmark:
                                                                                        !showBookmarkOverlayInMinimal,
                                                                                  ),
                                                                                  if (showOnboarding &&
                                                                                      !settings
                                                                                          .hasUsedSearchBarHint)
                                                                                    Padding(
                                                                                      padding:
                                                                                          const EdgeInsets.only(
                                                                                        bottom:
                                                                                            8,
                                                                                        left:
                                                                                            12,
                                                                                        right:
                                                                                            12,
                                                                                      ),
                                                                                      child:
                                                                                          Align(
                                                                                        alignment:
                                                                                            Alignment.topCenter,
                                                                                        child:
                                                                                            OnboardingBubble(
                                                                                          text:
                                                                                              'Search by word, chapter, or verse',
                                                                                          icon:
                                                                                              Icons.search,
                                                                                          pointingDown:
                                                                                              true,
                                                                                          tailAlign:
                                                                                              CrossAxisAlignment.center,
                                                                                          onTap: () =>
                                                                                              settings.markSearchBarHintUsed(),
                                                                                          onDismiss: () =>
                                                                                              settings.markSearchBarHintUsed(),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                ],
                                                                              ),
                                                                      ),
                                                                      if (showSimpleNav)
                                                                        const SizedBox(
                                                                          height:
                                                                              navBlockHeight,
                                                                        ),
                                                                      const SizedBox(
                                                                        height:
                                                                            searchBarHeight,
                                                                      ),
                                                      if (showOnboarding &&
                                                          !settings
                                                              .hasUsedAskAi &&
                                                          !_isAiMode)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                            top: 6,
                                                            left: 12,
                                                            right: 12,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Spacer(),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  right: 8,
                                                                  top: 2,
                                                                ),
                                                                child:
                                                                    OnboardingBubble(
                                                                  onTap: () {
                                                                    settings
                                                                        .markAskAiUsed();
                                                                    setState(() {
                                                                      _isAiMode =
                                                                          true;
                                                                    });
                                                                    final creditProvider =
                                                                        Provider.of<
                                                                          CreditProvider
                                                                        >(
                                                                          context,
                                                                          listen:
                                                                              false,
                                                                        );
                                                                    if (!creditProvider
                                                                            .isLoading &&
                                                                        creditProvider
                                                                                .balance <=
                                                                            0) {
                                                                      // Ad loading handled by CreditProvider.
                                                                    }
                                                                  },
                                                                  onDismiss: () {
                                                                    settings
                                                                        .markAskAiUsed();
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      if (showAiSuggestions)
                                                        TextFieldTapRegion(
                                                          groupId:
                                                              _homeSearchTapRegionGroup,
                                                          child:
                                                              AiSuggestionChips(
                                                            isVisible: true,
                                                            direction:
                                                                Axis.vertical,
                                                            onSuggestionSelected:
                                                                (suggestion) {
                                                              _searchController
                                                                      .text =
                                                                  suggestion;
                                                              provider
                                                                  .onSearchQueryChanged(
                                                                suggestion,
                                                              );
                                                              _navigateToAskGita(
                                                                suggestion,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      if (!shouldShowResults) ...[
                                                        if (settings
                                                            .showRandomShloka) ...[
                                                          if (!settings
                                                                  .hasUsedDailyShlokaHint &&
                                                              showOnboarding)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                top: 16,
                                                                left: 28,
                                                              ),
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                child:
                                                                    OnboardingBubble(
                                                                  text:
                                                                      "Today's verse",
                                                                  icon: Icons
                                                                      .wb_sunny_outlined,
                                                                  pointingDown:
                                                                      true,
                                                                  tailAlign:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  onTap: () =>
                                                                      settings
                                                                          .markDailyShlokaHintUsed(),
                                                                  onDismiss: () =>
                                                                      settings
                                                                          .markDailyShlokaHintUsed(),
                                                                ),
                                                              ),
                                                            ),
                                                          _buildRandomShlokaCard(),
                                                        ],
                                                        if (settings
                                                            .showSacredSutraQuote)
                                                          SacredSutraPromoCard(
                                                            isSimpleLight:
                                                                !settings
                                                                        .showBackground &&
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                            .brightness ==
                                                                        Brightness
                                                                            .light,
                                                            languageCode:
                                                                settings
                                                                    .language,
                                                          ),
                                                        if (settings
                                                            .showTodaysAction)
                                                          _buildTodaysActionCard(),
                                                        if (settings
                                                            .showTodaysAiQuestion)
                                                          _buildTodaysQuestionCard(
                                                            settings,
                                                          ),
                                                      ],
                                                      const SizedBox(
                                                        height: 100,
                                                      ),
                                                    ],
                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          if (showBookmarkOverlayInMinimal)
                                                            Positioned(
                                                              top: bookmarkY -
                                                                  scrollComp,
                                                              left: 0,
                                                              right: 0,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .centerLeft,
                                                                child: Padding(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .only(
                                                                    bottom:
                                                                        isTablet
                                                                            ? 28
                                                                            : 18,
                                                                  ),
                                                                  child:
                                                                      _buildHomeBookmarkChipForHeader(
                                                                    settings,
                                                                    isTablet,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          if (showSimpleNav)
                                                            Positioned(
                                                              top: navY -
                                                                  scrollComp,
                                                              left: 0,
                                                              right: 0,
                                                              child:
                                                                  _buildAnimatedSimpleModeNavButtons(
                                                                show:
                                                                    showSimpleNav,
                                                                settings:
                                                                    settings,
                                                              ),
                                                            ),
                                                          Positioned(
                                                            top: (searchY -
                                                                    scrollComp)
                                                                .clamp(
                                                              0.0,
                                                              maxHeight,
                                                            ),
                                                            left: 0,
                                                            right: 0,
                                                            child: KeyedSubtree(
                                                              key:
                                                                  _homeSearchBarKey,
                                                              child:
                                                                  _buildSearchBar(
                                                                provider,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
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
                                              fontSize: 14,
                                              letterSpacing: 1.6,
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
                                width <= 600 &&
                                !isLandscape)
                              Positioned(
                                left: 16,
                                bottom: 16,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!settings.hasUsedThemeHint &&
                                        showOnboarding)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                          left: 4,
                                        ),
                                        child: OnboardingBubble(
                                          text: 'Simple theme',
                                          icon: Icons.format_paint_outlined,
                                          pointingDown: true,
                                          tailAlign: CrossAxisAlignment.start,
                                          onTap: () =>
                                              settings.markThemeHintUsed(),
                                          onDismiss: () =>
                                              settings.markThemeHintUsed(),
                                        ),
                                      ),
                                    _buildHomeUiModeToggleFab(settings),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Decorations Layer (Buttons) - ON TOP of content
                      // Scrolls up with home content; clamped so it never drops below rest.
                      ValueListenableBuilder<double>(
                        valueListenable: _lotusLift,
                        builder: (context, lift, child) {
                          return Transform.translate(
                            offset: Offset(0, -lift),
                            child: child,
                          );
                        },
                        child: Stack(
                          children: [
                            // Base Layer Decorations
                            // Only show on PHONES during reveal animation.
                            if (_revealController.isAnimating && !isTablet)
                              _buildDecorationOnly(
                                showBackground: !_isBackgroundRequested!,
                                isKeyboardOpen: isKeyboardOpen,
                                shouldShowResults: effectiveShouldShowResults,
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

                            // Top Layer Decorations - Revealing
                            // WRAPPED IN LiquidReveal again.
                            // This is the correct way to handle masking and prevent white flash.
                            if (isTablet)
                              _buildDecorationOnly(
                                showBackground: _isBackgroundRequested!,
                                isKeyboardOpen: isKeyboardOpen,
                                shouldShowResults: effectiveShouldShowResults,
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
                                  shouldShowResults: effectiveShouldShowResults,
                                  scaleAnimation: _revealController.isAnimating
                                      ? CurvedAnimation(
                                          parent: _revealController,
                                          curve: const Interval(
                                            0.6,
                                            1.0,
                                            curve: Curves.easeOutBack,
                                          ),
                                        )
                                      : null, // Default to 1.0 when not animating
                                ),
                              ),
                          ],
                        ),
                      ),

                    ],
                  );
                },
              );
            },
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
      shape: const CircleBorder(),
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
          onTap: () => _navigateToAskGita(),
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
      key: const ValueKey('home_search_bar'),
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
            key: const ValueKey('home_search_field'),
            groupId: _homeSearchTapRegionGroup,
            controller: _searchController, // ✨ Bind controller
            focusNode: _searchFocusNode, // ✨ Attach FocusNode
            textInputAction: _isAiMode
                ? TextInputAction.send
                : TextInputAction.search, // ✨ Dynamic Action Button
            style: TextStyle(color: textColor),
            maxLength: _isAiMode ? AskGitaService.maxQueryLength : null,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) {
                  if (!_isAiMode || maxLength == null) {
                    return const SizedBox.shrink();
                  }
                  // Only show when at the cap (user tried to type past the limit).
                  if (currentLength < maxLength) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '$currentLength / $maxLength',
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor,
                    ),
                  );
                },
            onTapOutside: (_) => _searchFocusNode.unfocus(),
            onChanged: (value) => provider.onSearchQueryChanged(value),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                if (_isAiMode) {
                  if (AskGitaService.exceedsMaxLength(value)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please keep your question under ${AskGitaService.maxQueryLength} characters.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  _navigateToAskGita(value);
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
              prefixIcon: TextFieldTapRegion(
                groupId: _homeSearchTapRegionGroup,
                child: IconButton(
                  icon: Icon(
                    _isSearchFocused ? Icons.arrow_back : Icons.search,
                    color: _isSearchFocused ? textColor : hintColor,
                  ),
                  onPressed: _isSearchFocused
                      ? _handleBackAction
                      : () => _searchFocusNode.requestFocus(),
                ),
              ),
              suffixIcon: TextFieldTapRegion(
                groupId: _homeSearchTapRegionGroup,
                child: Row(
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
                          final query = provider.searchQuery;
                          if (AskGitaService.exceedsMaxLength(query)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please keep your question under ${AskGitaService.maxQueryLength} characters.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          _navigateToAskGita(query);
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
                        behavior: HitTestBehavior.opaque,
                        onTap: _toggleAiMode,
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

  Widget _buildAnimatedSimpleModeNavButtons({
    required bool show,
    required SettingsProvider settings,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, -0.14),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: show
          ? KeyedSubtree(
              key: const ValueKey('simple_mode_nav'),
              child: _buildSimpleModeNavButtons(settings),
            )
          : const SizedBox.shrink(key: ValueKey('simple_mode_nav_hidden')),
    );
  }

  Widget _buildSimpleModeNavButtons(SettingsProvider settings) {
    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;
    final Color labelColor = isSimpleLight
        ? Colors.brown.shade800
        : Colors.white.withValues(alpha: 0.95);
    final Color borderColor = isSimpleLight
        ? Colors.brown.shade300.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.35);
    final script = settings.script;

    Widget navButton(String termKey, VoidCallback onTap) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                child: Text(
                  StaticData.localizeTerm(termKey, script),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          navButton('parayan', () => context.push(AppRoutes.parayan)),
          const SizedBox(width: 8),
          navButton('adhyay', () => context.push(AppRoutes.chapters)),
          const SizedBox(width: 8),
          navButton('krutagyata', () => context.push(AppRoutes.credits)),
        ],
      ),
    );
  }

  double _homeHeaderOrnamentSize(bool isTablet) => isTablet ? 120.0 : 80.0;

  Color _homeHeaderLabelColor(SettingsProvider settings) {
    final isSimpleLight =
        !settings.showBackground &&
        Theme.of(context).brightness == Brightness.light;
    return isSimpleLight ? Colors.brown.shade900 : Colors.white;
  }

  /// Vertical space for [_buildHomeHeaderActionsRow] (bookmark + optional streak).
  double _homeHeaderActionsRowHeight(bool isTablet) {
    final streakSize = _homeHeaderOrnamentSize(isTablet);
    final bookmarkColumnHeight = HomeBookmarkLayout.columnHeight(isTablet);
    final bottomPad = isTablet ? 28.0 : 18.0;
    const streakLabelGap = 6.0;
    const streakLabelHeight = 11.0;
    final streakColumnHeight = streakSize + streakLabelGap + streakLabelHeight;
    return math.max(streakColumnHeight, bookmarkColumnHeight) + bottomPad;
  }

  Widget _buildHomeHeaderActionsRow(
    SettingsProvider settings, {
    bool showBookmark = true,
  }) {
    final bool isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;

    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 28 : 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showBookmark) _buildHomeBookmarkChipForHeader(settings, isTablet),
          const Spacer(),
          if (settings.streakSystemEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildSoulStreakChip(settings),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeBookmarkOrnament(
    SettingsProvider settings,
    double bandHeight,
  ) {
    const assetPath = 'assets/images/bookmark.png';
    const brightnessScale = 1.1;
    const brightnessOffset = 14.0;
    final bandWidth = HomeBookmarkLayout.bandWidth(bandHeight);

    final trimTop = HomeBookmarkLayout.iconLayoutTrimTop;
    final trimBottom = HomeBookmarkLayout.iconLayoutTrimBottom;
    final layoutHeight = (bandHeight - trimTop - trimBottom).clamp(
      1.0,
      bandHeight,
    );

    final ornament = SizedBox(
      width: bandWidth,
      height: bandHeight,
      child: Transform.rotate(
        angle: HomeBookmarkLayout.iconRotationRadians,
        child: SizedBox(
          width: bandHeight,
          height: bandWidth,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              brightnessScale, 0, 0, 0, brightnessOffset,
              0, brightnessScale, 0, 0, brightnessOffset,
              0, 0, brightnessScale, 0, brightnessOffset,
              0, 0, 0, 1, 0,
            ]),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );

    if (trimTop == 0 && trimBottom == 0) {
      return RepaintBoundary(child: ornament);
    }

    return RepaintBoundary(
      child: SizedBox(
        width: bandWidth,
        height: layoutHeight,
        child: ClipRect(
          child: Transform.translate(
            offset: Offset(0, -trimTop),
            child: ornament,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeBookmarkChipForHeader(
    SettingsProvider settings,
    bool isTablet,
  ) {
    return Transform.translate(
      offset: Offset(
        HomeBookmarkLayout.totalChipOffsetX(),
        HomeBookmarkLayout.chipOffsetY,
      ),
      child: _buildHomeBookmarkChip(settings, isTablet),
    );
  }

  Widget _buildHomeBookmarkChip(SettingsProvider settings, bool isTablet) {
    final double bandHeight = HomeBookmarkLayout.bandHeight(isTablet);
    final textColor = _homeHeaderLabelColor(settings);
    final labelSize = HomeBookmarkLayout.labelFontSize(isTablet);

    return Semantics(
      button: true,
      label: 'Collections',
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.bookmarks),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(
                HomeBookmarkLayout.iconOffsetX,
                HomeBookmarkLayout.iconOffsetY,
              ),
              child: _buildHomeBookmarkOrnament(settings, bandHeight),
            ),
            Transform.translate(
              offset: Offset(
                HomeBookmarkLayout.labelOffsetX,
                HomeBookmarkLayout.labelGap + HomeBookmarkLayout.labelOffsetY,
              ),
              child: Text(
                'Collections',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: labelSize,
                  fontWeight: HomeBookmarkLayout.labelFontWeight,
                  height: HomeBookmarkLayout.labelLineHeight,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoulStreakChip(SettingsProvider settings) {
    final int displayStreak = (kDebugMode && _debugStreakOverride != null)
        ? _debugStreakOverride!
        : settings.dailyStreak;
    final status = SoulStatus.getStatus(displayStreak);
    final textColor = _homeHeaderLabelColor(settings);
    final bool usesImage = status.imageAssetName != null;
    // Slightly larger than the lotus markers (phone 100 / tablet 150).
    final bool isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final double innerSize = _homeHeaderOrnamentSize(isTablet);

    return GestureDetector(
      onTap: () => _showEvolutionRoadmap(context, settings),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: innerSize,
            height: innerSize,
            child: usesImage
                ? Image.asset(
                    'assets/soul_evolution/${status.imageAssetName}',
                    fit: BoxFit.contain,
                  )
                : Icon(
                    status.icon,
                    color: SoulStatus.sparkGold,
                    size: innerSize,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            '${displayStreak}d - ${status.title}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
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
          final currentStatus = SoulStatus.getStatus(displayStreak);
          final metaParts = <String>[];
          if (settings.availableLifelines > 0) {
            metaParts.add(
              '♥ ${settings.availableLifelines} '
              '${settings.availableLifelines == 1 ? 'lifeline' : 'lifelines'}',
            );
          }
          if (settings.peakStreakCount > 0) {
            metaParts.add('Best ${settings.peakStreakCount}d');
          }

          final media = MediaQuery.of(context);
          final isTablet = media.size.shortestSide >= 600;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 72 : 20,
              vertical: isTablet ? 64 : 40,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 460 : 520,
                maxHeight: media.size.height * (isTablet ? 0.72 : 0.88),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.amberAccent.withOpacity(0.15),
                  ),
                ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 8, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: '$displayStreak',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Orbitron',
                                              ),
                                            ),
                                            TextSpan(
                                              text: '  ·  ${currentStatus.title}',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.75,
                                                ),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  currentStatus.imageAssetName != null
                                      ? Image.asset(
                                          'assets/soul_evolution/${currentStatus.imageAssetName}',
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.contain,
                                        )
                                      : Icon(
                                          currentStatus.icon,
                                          size: 44,
                                          color: SoulStatus.sparkGold,
                                        ),
                                ],
                              ),
                              if (metaParts.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  metaParts.join('  ·  '),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              if (kDebugMode) ...[
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 2,
                                    thumbColor: Colors.redAccent,
                                    activeTrackColor:
                                        Colors.redAccent.withOpacity(0.5),
                                    inactiveTrackColor: Colors.white10,
                                    overlayColor:
                                        Colors.redAccent.withOpacity(0.1),
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
                                      setState(() {});
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await settings.debugAdvanceDay();
                                          setDialogState(() {});
                                          setState(() {});
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.greenAccent,
                                          side: BorderSide(
                                            color: Colors.greenAccent
                                                .withOpacity(0.4),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                        ),
                                        child: const Text(
                                          '+1 Day',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () async {
                                          await settings.debugMissDays(1);
                                          setDialogState(() {});
                                          setState(() {});
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orangeAccent,
                                          side: BorderSide(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.4),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                        ),
                                        child: const Text(
                                          'Miss a Day',
                                          style: TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

                  // Roadmap
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final currentIndex = SoulStatus.allMilestones
                            .indexWhere((m) => m.title == currentStatus.title);

                        return ScrollablePositionedList.builder(
                          itemCount: SoulStatus.allMilestones.length,
                          initialScrollIndex:
                              currentIndex >= 0 ? currentIndex : 0,
                          initialAlignment: 0.25,
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                          itemBuilder: (context, index) {
                            final milestone = SoulStatus.allMilestones[index];
                            final isReached =
                                displayStreak >= milestone.threshold;
                            final isCurrent =
                                currentStatus.title == milestone.title;
                            final isLast = index ==
                                SoulStatus.allMilestones.length - 1;

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

                  // Share
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImageCreatorScreen(
                                streak: displayStreak,
                                achievementStatus: currentStatus,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share progress'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          );
        },
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
          shlokaScript: settings.shlokaScript,
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
            shlokaScript: settings.shlokaScript,
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
        shlokaScript: settings.shlokaScript,
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
                  pushShlokaInChapter(
                    context,
                    chapterNo: _randomShloka!.chapterNo,
                    shlokNo: _randomShloka!.shlokNo,
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
  void _showLanguagePromptDialog(BuildContext context, SettingsProvider settings) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to choose
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(dialogContext).brightness == Brightness.light
              ? Colors.white
              : Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: Theme.of(dialogContext).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choose Your Language',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(dialogContext).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(dialogContext).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(dialogContext).colorScheme.primary.withOpacity(0.3),
                    )
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Theme.of(dialogContext).colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You can always change this later in Settings.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(dialogContext).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Consumer<SettingsProvider>(
                  builder: (consumerContext, currentSettings, child) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SettingsProvider.supportedScripts.entries.map((entry) {
                        final isSelected = currentSettings.script == entry.key;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              currentSettings.setAppLanguage(entry.key);
                            }
                          },
                        );
                      }).toList(),
                    );
                  }
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(dialogContext).colorScheme.primary,
                      foregroundColor: Theme.of(dialogContext).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      settings.markLanguagePromptSeen();
                      Navigator.of(dialogContext, rootNavigator: true).pop();
                    },
                    child: const Text(
                      'Confirm & Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  Widget _buildTodaysActionCard() {
    if (_loadingAction || _todaysActionShloka == null)
      return const SizedBox.shrink();

    final settings = Provider.of<SettingsProvider>(context);

    // Look for AI commentary matching user language/script
    final aiCommentaries =
        _todaysActionShloka!.commentaries?.where((c) => c.isAI).toList() ?? [];

    Commentary? aiCommentary;

    // 1. Try script-specific (e.g. 'gu')
    try {
      aiCommentary = aiCommentaries.firstWhere(
        (c) => c.languageCode == settings.script,
      );
    } catch (_) {}

    // 2. Try language-specific (e.g. 'hi')
    if (aiCommentary == null && settings.language != 'sa') {
      try {
        aiCommentary = aiCommentaries.firstWhere(
          (c) => c.languageCode == settings.language,
        );
      } catch (_) {}
    }

    // 3. Fallback to 'en' or first available
    aiCommentary ??= aiCommentaries.firstWhere(
      (c) => c.languageCode == 'en',
      orElse: () => aiCommentaries.isNotEmpty
          ? aiCommentaries.first
          : Commentary(authorName: '', languageCode: '', content: ''),
    );

    if (aiCommentary.authorName.isEmpty) return const SizedBox.shrink();

    final modernCommentary = aiCommentary.modern;
    if (modernCommentary == null || modernCommentary.actionableTakeaway.isEmpty)
      return const SizedBox.shrink();
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
                          final shlokaNo = int.tryParse(
                            _todaysActionShloka!.shlokNo,
                          );
                          context.push(
                            AppRoutes.shlokaList.replaceFirst(
                              ':query',
                              _todaysActionShloka!.chapterNo,
                            ),
                            extra: {
                              'initialShloka': shlokaNo,
                              'bookMode': true,
                            },
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
          setState(() {
            _isAiMode = true;
          });
          _navigateToAskGita(_todaysQuestion);
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

class _RailThemeHintOverlay extends StatefulWidget {
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _RailThemeHintOverlay({
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_RailThemeHintOverlay> createState() => _RailThemeHintOverlayState();
}

class _RailThemeHintOverlayState extends State<_RailThemeHintOverlay> {
  double? _left;
  double? _bottom;
  final GlobalKey _bubbleKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePosition());
  }

  RenderBox? _stackBox() {
    RenderBox? stackBox;
    context.visitAncestorElements((element) {
      if (element.widget is Stack) {
        stackBox = element.renderObject as RenderBox?;
        return false;
      }
      return true;
    });
    return stackBox;
  }

  void _updatePosition({bool afterLayout = false}) {
    final themeKey = HelpRailAnchors.maybeOf(context)?.themeKey;
    final targetContext = themeKey?.currentContext;
    final stackBox = _stackBox();
    if (targetContext == null || stackBox == null || !mounted) return;

    final targetBox = targetContext.findRenderObject() as RenderBox?;
    if (targetBox == null || !targetBox.hasSize) return;

    var bubbleWidth = 252.0;
    var bubbleHeight = 76.0;
    if (afterLayout) {
      final bubbleBox =
          _bubbleKey.currentContext?.findRenderObject() as RenderBox?;
      if (bubbleBox != null && bubbleBox.hasSize) {
        bubbleWidth = bubbleBox.size.width;
        bubbleHeight = bubbleBox.size.height;
      }
    }

    const tailInset = 18.0;
    const gapAboveButton = 6.0;

    final buttonCenterGlobal =
        targetBox.localToGlobal(targetBox.size.center(Offset.zero));
    final buttonTopGlobal = targetBox.localToGlobal(Offset.zero);

    final buttonCenterLocal = stackBox.globalToLocal(buttonCenterGlobal);
    final buttonTopLocal = stackBox.globalToLocal(buttonTopGlobal).dy;

    // Align the downward tail (start) with the rail paint button.
    var left = buttonCenterLocal.dx - tailInset;
    left = left.clamp(
      8.0,
      (stackBox.size.width - bubbleWidth).clamp(0.0, double.infinity),
    );

    final bottom = (stackBox.size.height - buttonTopLocal + gapAboveButton)
        .clamp(gapAboveButton, stackBox.size.height);

    final changed = _left != left || _bottom != bottom;
    if (changed) {
      setState(() {
        _left = left;
        _bottom = bottom;
      });
    }

    if (!afterLayout) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _updatePosition(afterLayout: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_left == null || _bottom == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: _left,
      bottom: _bottom,
      child: OnboardingBubble(
        key: _bubbleKey,
        text: 'Paint button on the left rail switches theme',
        icon: Icons.format_paint_outlined,
        pointingDown: true,
        tailAlign: CrossAxisAlignment.start,
        onTap: widget.onTap,
        onDismiss: widget.onDismiss,
      ),
    );
  }
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
    final titleColor = isCurrent
        ? Colors.white
        : (isReached ? Colors.white70 : Colors.white38);
    // Smaller than the old 76–96 framed emblems; no outer ring.
    const double emblemSize = 52.0;

    Widget emblem;
    if (milestone.imageAssetName != null) {
      emblem = Image.asset(
        'assets/soul_evolution/${milestone.imageAssetName}',
        width: emblemSize,
        height: emblemSize,
        fit: BoxFit.contain,
      );
    } else {
      emblem = Icon(
        milestone.icon,
        size: emblemSize * 0.72,
        color: isReached || isCurrent
            ? SoulStatus.sparkGold
            : Colors.white24,
      );
    }

    if (!isReached && !isCurrent && milestone.imageAssetName != null) {
      emblem = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: Opacity(opacity: 0.45, child: emblem),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 8 : 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: emblemSize,
              child: Column(
                children: [
                  SizedBox(
                    width: emblemSize,
                    height: emblemSize,
                    child: Center(child: emblem),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isReached
                            ? Colors.amberAccent.withOpacity(0.35)
                            : Colors.white12,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone.title,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                        fontSize: isCurrent ? 16 : 14,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(height: 4),
                      Text(
                        milestone.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final idx = SoulStatus.allMilestones.indexWhere(
                            (m) => m.title == milestone.title,
                          );
                          if (idx < 0 ||
                              idx >= SoulStatus.allMilestones.length - 1) {
                            return const SizedBox.shrink();
                          }
                          final next = SoulStatus.allMilestones[idx + 1];
                          final daysToNext = next.threshold - streak;
                          if (daysToNext <= 0) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$daysToNext days to ${next.title}',
                              style: TextStyle(
                                color: SoulStatus.sparkGold.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
