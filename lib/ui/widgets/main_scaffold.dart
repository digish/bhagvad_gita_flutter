import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../navigation/app_router.dart';

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

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child: NavigationRail(
              leading: const SizedBox(height: 40),
              selectedIndex: _calculateSelectedIndex(context),
              onDestinationSelected: (int index) =>
                  _onItemTapped(index, context),
              labelType: NavigationRailLabelType.all,
              destinations: const <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book),
                  label: Text('Chapters'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories),
                  label: Text('Parayan'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.info_outline),
                  selectedIcon: Icon(Icons.info),
                  label: Text('Credits'),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
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
    }
  }
}
