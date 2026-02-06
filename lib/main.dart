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

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/theme/app_theme.dart';

import 'navigation/app_router.dart';
import 'providers/audio_provider.dart';
import 'data/database_helper.dart';
import 'providers/settings_provider.dart';
import 'providers/bookmark_provider.dart';
import 'data/database_helper_interface.dart';
import 'package:just_audio_background/just_audio_background.dart';

Future<void> main() async {
  // <-- Make main async
  // --- ADD THIS INITIALIZATION BLOCK ---
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'org.komal.bhagvadgeeta.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
  );

  runApp(const AppInitializer());
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getInitializedDatabaseHelper(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final dbHelper = snapshot.data as DatabaseHelperInterface;
          return MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => SettingsProvider()),
              ChangeNotifierProvider(create: (_) => AudioProvider()),
              ChangeNotifierProvider(create: (_) => BookmarkProvider()),
              Provider<DatabaseHelperInterface>.value(value: dbHelper),
            ],
            child: const MyApp(),
          );
        }
        // Show a simple splash screen while initializing
        return const Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: Colors.white,
            child: Center(
              // Using a simple flutter logo or loader to indicate activity
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Define global RouteObserver
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp.router(
          routerConfig: router,
          title: 'Bhagavad Gita',
          themeMode: settings.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
