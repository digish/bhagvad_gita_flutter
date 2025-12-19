import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import 'glass_navigation_rail.dart';
import 'liquid_reveal.dart';

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

  ui.Image? _snapshotImage;
  final GlobalKey _repaintBoundaryKey = GlobalKey();

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

  void _handleThemeToggle() async {
    // 1. Capture Snapshot of current state (OLD)
    await _captureSnapshot();
    if (_snapshotImage == null) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      settings.setShowBackground(!settings.showBackground);
      return;
    }

    // 2. Capture button position
    _captureThemeTogglePosition();

    // 4. Update Global Settings (NEW State)
    if (!mounted) return;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final bool newBackgroundState = !settings.showBackground;

    settings.setShowBackground(newBackgroundState);

    // 5. Start Animation (Reveal NEW over OLD)
    _revealController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _snapshotImage = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showRail = width > 600;

    if (!showRail) {
      return widget.child;
    }

    return Scaffold(
      body: AnimatedBuilder(
        animation: _revealController,
        builder: (context, child) {
          return Stack(
            children: [
              // BOTTOM LAYER: The "Old" State (Snapshot)
              if (_revealController.isAnimating && _snapshotImage != null)
                Positioned.fill(
                  child: RawImage(image: _snapshotImage, fit: BoxFit.cover),
                ),

              // TOP LAYER: The "New" State (Live Widget Tree)
              LiquidReveal(
                progress:
                    (_revealController.isAnimating && _snapshotImage != null)
                    ? _revealController.value
                    : 1.0,
                center: _revealCenter,
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: _buildScaffoldLayout(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScaffoldLayout(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isLandscape = width > MediaQuery.of(context).size.height;
    final double railWidth = isLandscape ? 220.0 : 100.0;

    return Stack(
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
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (int index) => _onItemTapped(index, context),
            trailing: FloatingActionButton(
              key: _railThemeToggleKey,
              heroTag: 'rail_theme_toggle',
              mini: true,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              elevation: 0,
              onPressed: _handleThemeToggle,
              child: Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  return Icon(
                    settings.showBackground
                        ? Icons.format_paint_outlined
                        : Icons.format_paint,
                  );
                },
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
                icon: const Icon(Icons.bookmark_outline, color: Colors.black54),
                selectedIcon: const Icon(Icons.bookmark, color: Colors.black),
                label: const Text('Collections'),
              ),
              NavigationRailDestination(
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black54,
                ),
                selectedIcon: const Icon(Icons.settings, color: Colors.black),
                label: const Text('Settings'),
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
    if (location.startsWith(AppRoutes.chapters)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.parayan)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.credits)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.bookmarks)) {
      return 4;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return 5;
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
        context.go(AppRoutes.chapters);
        break;
      case 2:
        context.go(AppRoutes.parayan);
        break;
      case 3:
        context.go(AppRoutes.credits);
        break;
      case 4:
        context.go(AppRoutes.bookmarks);
        break;
      case 5:
        context.go(AppRoutes.settings);
        break;
    }
  }
}
