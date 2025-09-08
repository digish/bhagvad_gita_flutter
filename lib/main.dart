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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'navigation/app_router.dart';
import 'providers/audio_provider.dart';
import 'data/database_helper.dart';
import 'data/database_helper_interface.dart';
import 'package:just_audio_background/just_audio_background.dart';


Future<void> main() async { // <-- Make main async
  // --- ADD THIS INITIALIZATION BLOCK ---
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'org.komal.bhagvadgeeta.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
  );
  // --- END BLOCK ---

  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  final dbHelper = await getInitializedDatabaseHelper();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        Provider<DatabaseHelperInterface>.value(value: dbHelper),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      title: 'Bhagavad Gita',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

