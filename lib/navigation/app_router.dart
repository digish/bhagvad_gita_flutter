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
import 'route_observer.dart';
import '../ui/screens/chapters_screen.dart';
import '../ui/screens/parayan_screen.dart';
import '../providers/parayan_provider.dart';
import '../ui/screens/search_screen.dart';
import '../ui/screens/shloka_list_screen.dart';
import 'shloka_navigation.dart';
import '../ui/screens/audio_management_screen.dart';
import '../ui/screens/credits_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/screens/user_lists_screen.dart';
import '../providers/settings_provider.dart'; // Import SettingsProvider
// 1. Import the interface file directly so the router knows about the type.
import '../data/database_helper_interface.dart';
import '../ui/widgets/main_scaffold.dart';
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

  /// Legacy deep links; prefer [shlokaListLocationForVerseId].
  static String shlokaDetailPath(String id) =>
      shlokaListLocationForVerseId(id) ??
      shlokaDetail.replaceFirst(':id', id);
}

int? _initialShlokaFromRouteExtra(Object? extra) {
  if (extra is int) return extra;
  if (extra is num) return extra.toInt();
  if (extra is String) return int.tryParse(extra);
  if (extra is Map) {
    final mapped = extra['initialShloka'];
    if (mapped is int) return mapped;
    if (mapped is num) return mapped.toInt();
    if (mapped is String) return int.tryParse(mapped);
  }
  return null;
}

int? _initialShlokaFromState(GoRouterState state) {
  final fromExtra = _initialShlokaFromRouteExtra(state.extra);
  if (fromExtra != null) return fromExtra;
  final q = state.uri.queryParameters['shloka'];
  if (q != null) return int.tryParse(q);
  return null;
}

bool _initialBookModeFromRouteExtra(Object? extra) {
  if (extra is Map && extra['bookMode'] == true) return true;
  return false;
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
      return shlokaListLocationForVerseId(id) ?? AppRoutes.search;
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
        goShlokaInChapter(router, id);
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
            final initialShloka = _initialShlokaFromState(state);
            var showHelp = state.uri.queryParameters['help'] == '1';
            if (extra is Map) {
              showHelp = showHelp || extra['help'] == true;
            }
            final initialBookMode = _initialBookModeFromRouteExtra(extra);
            return CustomTransitionPage(
              key: ValueKey(
                'shloka-list-$query-help-$showHelp-${initialShloka ?? ''}-book-$initialBookMode',
              ),
              child: ShlokaListScreen(
                searchQuery: query,
                initialShlokaNo: initialShloka,
                initialBookMode: initialBookMode,
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
          redirect: (context, state) {
            final id = state.pathParameters['id'];
            if (id == null) return AppRoutes.search;
            return shlokaListLocationForVerseId(id) ?? AppRoutes.search;
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
            final initialShloka = _initialShlokaFromRouteExtra(state.extra);
            return CustomTransitionPage(
              key: ValueKey(
                'shloka-list-$chapter-book-${initialShloka ?? ''}',
              ),
              child: ShlokaListScreen(
                searchQuery: chapter.toString(),
                initialShlokaNo: initialShloka,
                initialBookMode: true,
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
