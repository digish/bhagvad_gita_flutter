import 'dart:ui';
import 'package:flutter/material.dart';

class GlassNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final Widget? trailing;

  const GlassNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

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
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: NavigationRail(
                          backgroundColor: Colors.transparent,
                          extended: isLandscape,
                          minExtendedWidth: 220,
                          selectedIndex: selectedIndex,
                          onDestinationSelected: onDestinationSelected,
                          labelType: isLandscape
                              ? NavigationRailLabelType.none
                              : NavigationRailLabelType.all,
                          indicatorColor: Colors.transparent,
                          groupAlignment: -1.0, // Top align
                          leading: SizedBox(
                            height: MediaQuery.of(context).size.height < 400
                                ? 10
                                : (MediaQuery.of(context).size.height < 600
                                      ? 20
                                      : 80),
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
                          // Spacer to prevent overlap with sticky trailing widget
                          trailing: trailing != null
                              ? const SizedBox(height: 80)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (trailing != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  child: Center(child: trailing!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
