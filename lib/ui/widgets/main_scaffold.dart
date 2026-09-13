import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'glass_navigation_rail.dart';
import 'liquid_reveal.dart';
import 'global_mini_player.dart';
import 'home_layout_picker_sheet.dart';

/// Live rail widget keys (reserved for future coach marks).
class HelpRailAnchors extends InheritedWidget {
  final GlobalKey railKey;
  final GlobalKey settingsKey;
  final GlobalKey themeKey;
  final ValueNotifier<Widget?> coachOverlay;

  const HelpRailAnchors({
    super.key,
    required this.railKey,
    required this.settingsKey,
    required this.themeKey,
    required this.coachOverlay,
    required super.child,
  });

  static HelpRailAnchors? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HelpRailAnchors>();
  }

  @override
  bool updateShouldNotify(HelpRailAnchors oldWidget) =>
      railKey != oldWidget.railKey ||
      settingsKey != oldWidget.settingsKey ||
      themeKey != oldWidget.themeKey ||
      coachOverlay != oldWidget.coachOverlay;
}

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  Offset _revealCenter = Offset.zero;
  final GlobalKey _railThemeToggleKey = GlobalKey();
  final GlobalKey _railHelpKey = GlobalKey(debugLabel: 'navRailHelp');
  final GlobalKey _settingsRailHelpKey =
      GlobalKey(debugLabel: 'navRailSettingsHelp');

  ui.Image? _snapshotImage;
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final ValueNotifier<Widget?> _coachOverlay = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _coachOverlay.dispose();
    _revealController.dispose();
    super.dispose();
  }

  Future<void> _captureSnapshot() async {
    try {
      final RenderRepaintBoundary? boundary =
          _repaintBoundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(
        pixelRatio: MediaQuery.of(context).devicePixelRatio,
      );
      setState(() {
        _snapshotImage = image;
      });
    } catch (e) {
      debugPrint("Snapshot failed: $e");
    }
  }

  void _captureThemeTogglePosition() {
    final RenderBox? renderBox =
        _railThemeToggleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final center = renderBox.localToGlobal(size.center(Offset.zero));
      setState(() {
        _revealCenter = center;
      });
    }
  }

  Future<void> _applyHomeUiMode(HomeUiMode next) async {
    if (_revealController.isAnimating) return;

    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final current = settings.homeUiMode;
    if (current == next) return;

    HapticFeedback.lightImpact();

    if (current.showsDecorativeBackground == next.showsDecorativeBackground) {
      await settings.setHomeUiMode(next);
      return;
    }

    await _captureSnapshot();
    if (_snapshotImage == null) {
      await settings.setHomeUiMode(next);
      return;
    }

    _captureThemeTogglePosition();

    if (!mounted) return;
    await settings.setHomeUiMode(next);

    _revealController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _snapshotImage = null;
        });
      }
    });
  }

  void _handleThemeToggle() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _applyHomeUiMode(settings.nextHomeUiMode);
  }

  Future<void> _openHomeLayoutPicker() async {
    if (_revealController.isAnimating) return;
    HapticFeedback.mediumImpact();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final picked = await showHomeLayoutPickerSheet(
      context,
      current: settings.homeUiMode,
    );
    if (!mounted || picked == null || picked == settings.homeUiMode) return;
    await _applyHomeUiMode(picked);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final bool showRail = width > 600;

    // 📲 Phone Landscape Auto-Toggle Logic
    // If we're on a phone in landscape, and backgrounds are ON, trigger the reveal animation to turn them OFF.
    if (!isTablet && isLandscape) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      if (settings.showBackground && !_revealController.isAnimating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (settings.showBackground && !_revealController.isAnimating) {
            _handleThemeToggle();
          }
        });
      }
    }

    if (!showRail) {
      return HelpRailAnchors(
        railKey: _railHelpKey,
        settingsKey: _settingsRailHelpKey,
        themeKey: _railThemeToggleKey,
        coachOverlay: _coachOverlay,
        child: Stack(children: [widget.child, const GlobalMiniPlayer()]),
      );
    }

    return HelpRailAnchors(
      railKey: _railHelpKey,
      settingsKey: _settingsRailHelpKey,
      themeKey: _railThemeToggleKey,
      coachOverlay: _coachOverlay,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _revealController,
          builder: (context, child) {
            return Stack(
              children: [
                if (_revealController.isAnimating && _snapshotImage != null)
                  Positioned.fill(
                    child: RawImage(image: _snapshotImage, fit: BoxFit.cover),
                  ),
                LiquidReveal(
                  progress:
                      (_revealController.isAnimating && _snapshotImage != null)
                      ? _revealController.value
                      : 1.0,
                  center: _revealCenter,
                  child: RepaintBoundary(
                    key: _repaintBoundaryKey,
                    child: _buildScaffoldLayout(
                      context,
                      isTablet,
                      isLandscape,
                      _coachOverlay,
                    ),
                  ),
                ),
                const GlobalMiniPlayer(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScaffoldLayout(
    BuildContext context,
    bool isTablet,
    bool isLandscape,
    ValueNotifier<Widget?> coachOverlay,
  ) {
    final double railWidth = isLandscape ? 220.0 : 100.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Content Layer
        Positioned.fill(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(left: railWidth),
            ),
            child: widget.child,
          ),
        ),
        // Navigation Rail Layer
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: railWidth,
          child: GlassNavigationRail(
            key: _railHelpKey,
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (int index) => _onItemTapped(index, context),
            trailing: (!isTablet && isLandscape)
                ? null // ✨ Hide toggle in landscape on phones
                : GestureDetector(
                    onLongPress: _openHomeLayoutPicker,
                    child: FloatingActionButton(
                      key: _railThemeToggleKey,
                      heroTag: 'rail_theme_toggle',
                      mini: true,
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.8),
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 0,
                      onPressed: _handleThemeToggle,
                      child: Consumer<SettingsProvider>(
                        builder: (context, settings, _) {
                          return Icon(
                            settings.homeUiMode.layoutToggleIcon,
                            size: 22,
                          );
                        },
                      ),
                    ),
                  ),
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: _buildLotusIcon('assets/images/lotus_top.png', false),
                selectedIcon: _buildLotusIcon(
                  'assets/images/lotus_top.png',
                  true,
                ),
                label: const Text('Search'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome),
                label: const Text('Ask Gita AI'),
              ),
              NavigationRailDestination(
                icon: _buildLotusIcon('assets/images/lotus_white22.png', false),
                selectedIcon: _buildLotusIcon(
                  'assets/images/lotus_white22.png',
                  true,
                ),
                label: const Text('Chapters'),
              ),
              NavigationRailDestination(
                icon: _buildLotusIcon('assets/images/lotus_blue12.png', false),
                selectedIcon: _buildLotusIcon(
                  'assets/images/lotus_blue12.png',
                  true,
                ),
                label: const Text('Parayan'),
              ),
              NavigationRailDestination(
                icon: _buildLotusIcon('assets/images/lotus_gold.png', false),
                selectedIcon: _buildLotusIcon(
                  'assets/images/lotus_gold.png',
                  true,
                ),
                label: const Text('Credits'),
              ),
              NavigationRailDestination(
                icon: const Icon(Icons.bookmark_outline),
                selectedIcon: const Icon(Icons.bookmark),
                label: const Text('Collections'),
              ),
              NavigationRailDestination(
                icon: KeyedSubtree(
                  key: _settingsRailHelpKey,
                  child: const Icon(Icons.settings_outlined),
                ),
                selectedIcon: const Icon(Icons.settings),
                label: const Text('Settings'),
              ),
            ],
          ),
        ),
        // Coach marks sit above the rail so tails can reach rail controls.
        Positioned.fill(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ValueListenableBuilder<Widget?>(
                valueListenable: coachOverlay,
                builder: (context, overlay, _) =>
                    overlay ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLotusIcon(String assetPath, bool isSelected) {
    if (isSelected) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Image.asset(assetPath, width: 40, height: 40),
      );
    } else {
      return Opacity(
        opacity: 0.6,
        child: Image.asset(assetPath, width: 32, height: 32),
      );
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == AppRoutes.askGita) {
      return 1;
    }
    if (location.startsWith(AppRoutes.chapters)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.parayan)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.credits)) {
      return 4;
    }
    if (location.startsWith(AppRoutes.bookmarks)) {
      return 5;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return 6;
    }
    if (location == AppRoutes.search) {
      return 0;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.search);
        break;
      case 1:
        context.go(AppRoutes.askGita);
        break;
      case 2:
        context.go(AppRoutes.chapters);
        break;
      case 3:
        context.go(AppRoutes.parayan);
        break;
      case 4:
        context.go(AppRoutes.credits);
        break;
      case 5:
        context.go(AppRoutes.bookmarks);
        break;
      case 6:
        context.go(AppRoutes.settings);
        break;
    }
  }
}
