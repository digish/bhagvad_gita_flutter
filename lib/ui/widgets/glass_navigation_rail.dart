import 'dart:ui';
import 'package:flutter/material.dart';

class GlassNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;

  const GlassNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              right: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1.0,
              ),
            ),
          ),
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            indicatorColor: Colors.transparent,
            groupAlignment: -1.0, // Top align
            leading: SizedBox(
              height: MediaQuery.of(context).size.height < 600 ? 20 : 80,
            ), // Responsive spacing
            selectedIconTheme: const IconThemeData(
              color: Color(0xFFFFD700), // Gold/Amber color
              size: 32,
            ),
            unselectedIconTheme: const IconThemeData(
              color: Colors.black87,
              size: 24,
            ),
            selectedLabelTextStyle: const TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 12,
            ),
            destinations: destinations,
          ),
        ),
      ),
    );
  }
}
