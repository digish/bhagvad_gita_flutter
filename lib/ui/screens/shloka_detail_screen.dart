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
import 'package:provider/provider.dart';
import '../../data/database_helper_interface.dart';
import '../../models/shloka_result.dart';
import '../widgets/full_shloka_card.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../widgets/simple_gradient_background.dart';

class ShlokaDetailScreen extends StatefulWidget {
  final String shlokaId;
  const ShlokaDetailScreen({super.key, required this.shlokaId});

  @override
  State<ShlokaDetailScreen> createState() => _ShlokaDetailScreenState();
}

class _ShlokaDetailScreenState extends State<ShlokaDetailScreen> {
  late Future<ShlokaResult?> _shlokaFuture;

  @override
  void initState() {
    super.initState();
    _loadShloka();
  }

  void _loadShloka() {
    final dbHelper = Provider.of<DatabaseHelperInterface>(
      context,
      listen: false,
    );
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final language = settings.language;
    final script = settings.script;

    _shlokaFuture = dbHelper.getShlokaById(
      widget.shlokaId,
      language: language,
      script: script,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Verse ${widget.shlokaId}"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
      body: Stack(
        children: [
          const SimpleGradientBackground(),
          FutureBuilder<ShlokaResult?>(
            future: _shlokaFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Center(
                  child: Text(
                    "Verse not found.",
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              final shloka = snapshot.data!;
              return Consumer2<AudioProvider, SettingsProvider>(
                builder: (context, audio, settings, child) {
                  return SafeArea(
                    left: true,
                    top: false,
                    right: true,
                    bottom: true,
                    child: SingleChildScrollView(
                      // Allow scrolling if card is long
                      padding: EdgeInsets.fromLTRB(
                        16,
                        kToolbarHeight +
                            MediaQuery.of(context).padding.top +
                            16,
                        16,
                        16,
                      ),
                      child: FullShlokaCard(
                        shloka: shloka,
                        currentlyPlayingId: audio.currentPlayingShlokaId,
                        config: FullShlokaCardConfig(
                          baseFontSize: settings.fontSize,
                          showAnvay: true,
                          showBhavarth: true,
                          showSeparator: true,
                          showSpeaker: true,
                          showShlokIndex: true,
                          showColoredCard: true,
                          showEmblem: false, // Don't need animation here
                          isLightTheme:
                              Theme.of(context).brightness ==
                              Brightness.light, // ✨ Dynamic theme
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
