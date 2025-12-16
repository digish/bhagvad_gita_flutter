import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';
import 'glass_navigation_rail.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool showRail = width > 600;

    if (!showRail) {
      return child;
    }

    final bool isLandscape = width > MediaQuery.of(context).size.height;
    final double railWidth = isLandscape ? 220.0 : 100.0;

    return Scaffold(
      body: Stack(
        children: [
          // Content Layer - Injected with padding to avoid rail overlap
          Positioned.fill(
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: MediaQuery.of(
                  context,
                ).padding.copyWith(left: railWidth),
              ),
              child: child,
            ),
          ),
          // Navigation Rail Layer - Glassmorphic overlay
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: railWidth, // Responsive width
            child: GlassNavigationRail(
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (int index) =>
                  _onItemTapped(index, context),
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
                  icon: _buildLotusIcon(
                    'assets/images/lotus_white22.png',
                    false,
                  ),
                  selectedIcon: _buildLotusIcon(
                    'assets/images/lotus_white22.png',
                    true,
                  ),
                  label: const Text('Chapters'),
                ),
                NavigationRailDestination(
                  icon: _buildLotusIcon(
                    'assets/images/lotus_blue12.png',
                    false,
                  ),
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
                  icon: const Icon(
                    Icons.bookmark_outline,
                    color: Colors.black54,
                  ),
                  selectedIcon: const Icon(Icons.bookmark, color: Colors.black),
                  label: const Text('Bookmarks'),
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
      ),
    );
  }

  static Widget _buildLotusIcon(String assetPath, bool isSelected) {
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

  static int _calculateSelectedIndex(BuildContext context) {
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
