/* 
*  © 2025 Digish Pandya. All rights reserved.
*
*  This mobile application, "Shrimad Bhagavad Gita," including its code, design, and original content, is released under the [MIT License] unless otherwise noted.
*
*  The sacred text of the Bhagavad Gita, as presented herein, is in the public domain. Translations, interpretations, UI elements, and artistic representations created by the developer are protected under copyright law.
*
*  This app is offered in the spirit of dharma and shared learning. You are welcome to use, modify, and distribute the source code under the terms of the MIT License. However, please preserve the integrity of the spiritual message and credit the original contributors where due.
*
*  For licensing details, see the LICENSE file in the repository.
*
**/

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Check if this import is correct based on file structure
import '../ui/screens/chapters_screen.dart';
import '../ui/screens/parayan_screen.dart';
import '../providers/parayan_provider.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/shloka_detail_screen.dart';
import '../ui/screens/shloka_list_screen.dart';
import '../ui/screens/audio_management_screen.dart';
import '../ui/screens/credits_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/user_lists_screen.dart';
import '../providers/settings_provider.dart'; // Import SettingsProvider
// 1. Import the interface file directly so the router knows about the type.
import '../data/database_helper_interface.dart';
import '../ui/widgets/main_scaffold.dart';
import '../ui/screens/book_reading_screen.dart';
import '../ui/screens/ask_gita_screen.dart';
import '../ui/screens/image_creator_screen.dart';
import '../services/deep_link_parser.dart';

class AppRoutes {
  static const String search = '/';
  static const String chapters = '/chapters';
  static const String parayan = '/parayan';
  static const String shlokaList = '/shloka-list/:query';
  static const String shlokaDetail = '/shloka-detail/:id';
  static const String audioManagement = '/audio-management';
  static const String credits = '/credits';
  static const String settings = '/settings';
  static const String bookmarks = '/bookmarks';
  static const String bookReading = '/book-reading/:chapter';
  static const String askGita = '/ask-gita';
  static const String imageCreator = '/image-creator';

  static String shlokaDetailPath(String id) =>
      shlokaDetail.replaceFirst(':id', id);
}

final GoRouter router = GoRouter(
  initialLocation: AppRoutes.search,
  observers: [routeObserver],
  redirect: (context, state) {
    // Widget / OS deep links arrive as bhagvadgeeta://shloka/12.7
    // Map them onto a real in-app route before go_router errors.
    final uri = state.uri;
    if (!DeepLinkParser.isCustomScheme(uri)) return null;

    final id = DeepLinkParser.extractShlokaId(
      uri: uri,
      payload: uri.toString(),
    );
    if (id != null) {
      return AppRoutes.shlokaDetailPath(id);
    }
    return AppRoutes.search;
  },
  errorBuilder: (context, state) {
    // Last-resort recovery if a deep link slipped past redirect.
    final id = DeepLinkParser.extractShlokaId(
      uri: state.uri,
      payload: state.uri.toString(),
    );
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(AppRoutes.shlokaDetailPath(id));
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error?.toString() ?? 'Page not found'),
            TextButton(
              onPressed: () => router.go(AppRoutes.search),
              child: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.search,
          pageBuilder: (context, state) {
            final showSearchHints = state.extra is Map &&
                (state.extra as Map)['searchHints'] == true;
            return CustomTransitionPage(
              key: ValueKey('search-hints-$showSearchHints'),
              child: SearchScreen(showSearchHints: showSearchHints),
              transitionDuration: const Duration(milliseconds: 700),
              reverseTransitionDuration: const Duration(milliseconds: 700),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: AppRoutes.chapters,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const ChaptersScreen(),
              transitionDuration: const Duration(milliseconds: 700),
              reverseTransitionDuration: const Duration(milliseconds: 700),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
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
            final settings = context.read<SettingsProvider>();
            final language = settings.language;
            final script = settings.script;
            final shlokaScript = settings.shlokaScript;
            final showHelp = state.uri.queryParameters['help'] == '1' ||
                (state.extra is Map &&
                    (state.extra as Map)['help'] == true);
            return CustomTransitionPage(
              key: ValueKey('parayan-help-$showHelp'),
              child: ChangeNotifierProvider(
                create: (_) => ParayanProvider(
                  dbHelper,
                  language,
                  script,
                  shlokaScript: shlokaScript,
                ),
                child: ParayanScreen(showHelp: showHelp),
              ),
              transitionDuration: const Duration(milliseconds: 700),
              reverseTransitionDuration: const Duration(milliseconds: 700),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: AppRoutes.shlokaList,
          name: 'shloka-list',
          pageBuilder: (context, state) {
            final query = state.pathParameters['query']!;
            final extra = state.extra;
            int? initialShloka;
            var showHelp = state.uri.queryParameters['help'] == '1';
            if (extra is int) {
              initialShloka = extra;
            } else if (extra is Map) {
              final mapped = extra['initialShloka'];
              if (mapped is int) initialShloka = mapped;
              showHelp = showHelp || extra['help'] == true;
            }
            debugPrint(
              'AppRouter shlokaList: query=$query, initialShloka=$initialShloka',
            );
            return CustomTransitionPage(
              key: ValueKey(
                'shloka-list-$query-help-$showHelp-${initialShloka ?? ''}',
              ),
              child: ShlokaListScreen(
                searchQuery: query,
                initialShlokaNo: initialShloka, // Pass it down
                showHelp: showHelp,
              ),
              transitionDuration: const Duration(milliseconds: 700),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
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
        GoRoute(
          path: AppRoutes.credits,
          pageBuilder: (context, state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const CreditsScreen(),
              transitionDuration: const Duration(milliseconds: 700),
              reverseTransitionDuration: const Duration(milliseconds: 700),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.bookmarks,
          builder: (context, state) => const UserListsScreen(),
        ),
        GoRoute(
          path: AppRoutes.bookReading,
          pageBuilder: (context, state) {
            final chapter = int.parse(state.pathParameters['chapter']!);
            final initialShloka = state.extra as int?;
            return CustomTransitionPage(
              key: state.pageKey,
              child: BookReadingScreen(
                chapterNumber: chapter,
                initialShlokaNo: initialShloka,
              ),
              transitionDuration: const Duration(milliseconds: 500),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
            );
          },
        ),
        GoRoute(
          path: AppRoutes.askGita,
          builder: (context, state) {
            final query = state.extra as String?;
            return AskGitaScreen(initialQuery: query);
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.imageCreator,
      pageBuilder: (context, state) {
        // Expecting params as a Map in 'extra'
        final args = state.extra as Map<String, dynamic>? ?? {};
        return CustomTransitionPage(
          key: state.pageKey,
          child: ImageCreatorScreen(
            text: args['text'] ?? '',
            question: args['question'],
            translation: args['translation'],
            source: args['source'],
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        );
      },
    ),
  ],
);
