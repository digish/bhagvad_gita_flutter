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
import 'package:just_audio_background/just_audio_background.dart'; // <-- ADD THIS IMPORT

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

