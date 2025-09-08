import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../ui/screens/chapters_screen.dart';
import '../ui/screens/parayan_screen.dart';
import '../providers/parayan_provider.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/shloka_detail_screen.dart';
import '../ui/screens/shloka_list_screen.dart';
import '../ui/screens/audio_management_screen.dart';
// 1. Import the interface file directly so the router knows about the type.
import '../data/database_helper_interface.dart';

class AppRoutes {
  static const String search = '/';
  static const String chapters = '/chapters';
  static const String parayan = '/parayan';
  static const String shlokaList = '/shloka-list/:query';
  static const String shlokaDetail = '/shloka-detail/:id';
  static const String audioManagement = '/audio-management';
}

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.search,
  routes: [
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: AppRoutes.chapters,
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const ChaptersScreen(),
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.parayan,
      pageBuilder: (context, state) {
        // 2. Read the globally provided dbHelper from the provider context.
        // This will now work because the type is known.
        final dbHelper = context.read<DatabaseHelperInterface>();
        return CustomTransitionPage(
          key: state.pageKey,
          child: ChangeNotifierProvider(
            create: (_) => ParayanProvider(dbHelper),
            child: const ParayanScreen(),
          ),
          transitionDuration: const Duration(milliseconds: 700),
          reverseTransitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.shlokaList,
      pageBuilder: (context, state) {
        final query = state.pathParameters['query']!;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ShlokaListScreen(searchQuery: query),
          transitionDuration: const Duration(milliseconds: 700),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.shlokaDetail,
      builder: (context, state) {
        final shlokaId = state.pathParameters['id']!;
        return ShlokaDetailScreen(shlokaId: shlokaId);
      },
    ),
    GoRoute(
      path: AppRoutes.audioManagement,
      builder: (context, state) => const AudioManagementScreen(),
    ),
  ],
);
