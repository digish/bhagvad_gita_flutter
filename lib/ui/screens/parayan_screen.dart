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
import '../../providers/audio_provider.dart';
import '../../data/static_data.dart';
import '../../models/shloka_result.dart';
import '../../providers/parayan_provider.dart';
import '../widgets/custom_scroll_indicator.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';

class ParayanScreen extends StatefulWidget {
  const ParayanScreen({super.key});

  @override
  State<ParayanScreen> createState() => _ParayanScreenState();
}

class _ParayanScreenState extends State<ParayanScreen> {
  final List<GlobalKey> _itemKeys = [];
  final GlobalKey _listViewKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  bool _showAnvay = true;
  final ValueNotifier<String> _currentPositionLabelNotifier = ValueNotifier(
    'अध्याय 1, श्लोक 1',
  );

  // --- NEW: State to track the currently playing shloka ID ---
  String? _currentlyPlayingId;

  void _updateCurrentPositionLabel() {
    final provider = Provider.of<ParayanProvider>(context, listen: false);
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstVisible = positions
          .where((p) => p.itemLeadingEdge >= 0)
          .reduce(
            (min, p) => p.itemLeadingEdge < min.itemLeadingEdge ? p : min,
          );

      final shloka = provider.shlokas[firstVisible.index];

      _currentPositionLabelNotifier.value =
          'अध्याय ${shloka.chapterNo}, श्लोक ${shloka.shlokNo}';
    }
  }

  @override
  void initState() {
    super.initState();
    // --- NEW: Listen to AudioProvider for UI updates ---
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.addListener(_audioListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemPositionsListener.itemPositions.addListener(
        _updateCurrentPositionLabel,
      );
    });
  }

  // --- NEW: Listener to update the playing ID ---
  void _audioListener() {
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    if (mounted && _currentlyPlayingId != audioProvider.currentPlayingShlokaId) {
      setState(() {
        _currentlyPlayingId = audioProvider.currentPlayingShlokaId;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _currentPositionLabelNotifier.dispose(); // ✨ Add this line
    _itemPositionsListener.itemPositions.removeListener(
      _updateCurrentPositionLabel,
    );
    // --- NEW: Clean up the audio listener ---
    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    audioProvider.removeListener(_audioListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
          title: const Text('Full Parayan'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ), */
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          //DarkenedAnimatedBackground(opacity: 0.7),
          SimpleGradientBackground(startColor: const Color.fromARGB(255, 103, 108, 255)),
          Column(
            children: [
              // --- Header Row ---
              Padding(
                // Add padding to account for the status bar
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  bottom: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. --- Position Label ---
                    ValueListenableBuilder<String>(
                      valueListenable: _currentPositionLabelNotifier,
                      builder: (context, value, child) {
                        return Text(
                          value,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                    ),

                    // 2. --- Lotus Hero Widget ---
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Hero(
                        tag: 'blueLotusHero',
                        flightShuttleBuilder: (
                          flightContext,
                          animation,
                          flightDirection,
                          fromHeroContext,
                          toHeroContext,
                        ) {
                          return (toHeroContext.widget as Hero).child;
                        },
                        child: Image.asset(
                          'assets/images/lotus_blue12.png',
                          height: 100, // Reduced size to fit in a row
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // 3. --- Anvay Switch (Grouped) ---
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Anvay'),
                        Switch(
                          value: _showAnvay,
                          onChanged: (val) {
                            setState(() => _showAnvay = val);
                          },
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /// 🌿 Wrap ScrollablePositionedList + ScrollIndicator in a Stack
              Expanded(
                child: Consumer<ParayanProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final shlokas = provider.shlokas;

                    return Stack(
                      children: [
                        /// 📜 Main ScrollablePositionedList
                        ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          itemCount: shlokas.length,
                          padding: const EdgeInsets.only(
                            bottom: 8.0,
                            right: 50,
                          ),
                          itemBuilder: (context, index) {
                            final shloka = shlokas[index];
                            final previousShloka = (index > 0)
                                ? shlokas[index - 1]
                                : null;

                            final isChapterStart =
                                previousShloka == null ||
                                shloka.chapterNo != previousShloka.chapterNo;
                            final isChapterEnd =
                                (index == shlokas.length - 1) ||
                                shloka.chapterNo !=
                                    shlokas[index + 1].chapterNo;
                            final speakerChanged =
                                previousShloka != null &&
                                previousShloka.speaker != shloka.speaker;

                            return Column(
                              children: [
                                if (isChapterStart)
                                  _ChapterStartHeader(
                                    chapterNumber:
                                        int.tryParse(shloka.chapterNo) ?? 0,
                                  ),
                                if (speakerChanged | isChapterStart)
                                  _SpeakerHeader(
                                    speaker: shloka.speaker ?? "Uvacha",
                                  ),
                                //_ParayanShlokaCard(shloka: shloka),
                                FullShlokaCard(
                                  shloka: shloka,
                                  // --- NEW: Pass down the playing ID and a callback ---
                                  currentlyPlayingId: _currentlyPlayingId,
                                  onPlayPause: () {
                                    setState(() {
                                      _currentlyPlayingId = '${shloka.chapterNo}.${shloka.shlokNo}';
                                    });
                                  },
                                  config: FullShlokaCardConfig(
                                    showSpeaker: false,
                                    showAnvay: _showAnvay,
                                    showBhavarth: false,
                                    showSeparator: _showAnvay,
                                    showColoredCard: false,
                                    showEmblem: false,
                                    showShlokIndex: true,
                                    spacingCompact: true,
                                    isLightTheme: true,
                                  ),
                                ),

                                if (isChapterEnd)
                                  _ChapterEndFooter(
                                    chapterNumber:
                                        int.tryParse(shloka.chapterNo) ?? 0,
                                    chapterName:
                                        StaticData.geetaAdhyay[(int.tryParse(
                                                  shloka.chapterNo,
                                                ) ??
                                                1) -
                                            1],
                                  ),
                              ],
                            );
                          },
                        ),

                        /// 🐝 Custom Scroll Indicator
                        Positioned(
                          right: 0,
                          top: 0,
                          bottom: 0,
                          child: CustomScrollIndicator(
                            itemCount: shlokas.length,
                            chapterMarkers: provider.chapterStartIndices,
                            chapterLabels: provider.chapterStartIndices.map((
                              i,
                            ) {
                              final chapterNo = shlokas[i].chapterNo;
                              final name =
                                  StaticData.geetaAdhyay[(int.tryParse(
                                            chapterNo,
                                          ) ??
                                          1) -
                                      1];
                              return chapterNo; // or return 'Adhyay $chapterNo\n$name' for full label
                            }).toList(),

                            /// 🐝 Use ItemPositionsListener to track scroll position
                            itemPositionsListener: _itemPositionsListener,

                            /// 🪷 Scroll to chapter using ItemScrollController
                            onLotusTap: (index) {
                              final chapterIndex =
                                  provider.chapterStartIndices[index];

                              _itemScrollController.scrollTo(
                                index: chapterIndex,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Reusable private widgets for the list items ---

class _ChapterStartHeader extends StatelessWidget {
  final int chapterNumber;

  const _ChapterStartHeader({required this.chapterNumber});

  @override
  Widget build(BuildContext context) {
    // This could be styled more elaborately later
    // FIX: The `getChapterTitle` method had a range error for chapter 18.
    // Using `geetaAdhyay` list directly with correct 0-based indexing is safer
    // and consistent with other parts of the app (e.g., _ChapterEndFooter).
    // We clamp the chapter number to be at least 1 to prevent negative indices.
    String chapterName = StaticData.geetaAdhyay[(chapterNumber > 0 ? chapterNumber : 1) - 1];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Text(
        'अध्याय $chapterNumber $chapterName',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 4, 123, 192),
        ),
      ),
    );
  }
}

class _SpeakerHeader extends StatelessWidget {
  final String speaker;
  const _SpeakerHeader({required this.speaker});

  // ✨ Helper function to get the emblem asset path based on the speaker's name
  String? _getSpeakerEmblemPath(String speakerName) {
    switch (speakerName) {
      case 'श्री भगवान':
        return 'assets/emblems/krishna.png';
      case 'अर्जुन':
        return 'assets/emblems/arjun.png';
      case 'संजय':
        return 'assets/emblems/sanjay.png';
      case 'धृतराष्ट्र':
        return 'assets/emblems/dhrutrashtra.png';
      default:
        // Return null if there's no emblem for the speaker
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the path for the emblem, which might be null
    final String? emblemPath = _getSpeakerEmblemPath(speaker);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      // Use a Column to stack the emblem and text vertically
      child: Column(
        children: [
          // Conditionally show the emblem only if a path exists
          if (emblemPath != null) ...[
            Image.asset(
              emblemPath,
              height: 50, // Adjust the size of the emblem as needed
            ),
            const SizedBox(height: 8), // Adds a little space
          ],

          // The original speaker text
          Text(
            '$speaker उवाच',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParayanShlokaCard extends StatelessWidget {
  final ShlokaResult shloka;
  const _ParayanShlokaCard({required this.shloka});

  @override
  Widget build(BuildContext context) {
    final cleanShlok = shloka.shlok
        .replaceAll(RegExp(r'<c>', caseSensitive: false), '')
        .replaceAll('*', ' ');
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${shloka.chapterNo}.${shloka.shlokNo}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 12),
            Text(
              cleanShlok,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterEndFooter extends StatelessWidget {
  final int chapterNumber;
  final String chapterName;
  const _ChapterEndFooter({
    required this.chapterNumber,
    required this.chapterName,
  });

  @override
  Widget build(BuildContext context) {
    final colophonText =
        "ॐ तत्सदिति श्रीमद्भगवद्गीतासूपनिषत्सु\nब्रह्मविद्यायां योगशास्त्रे श्रीकृष्णार्जुनसंवादे\n$chapterName नाम अध्यायः $chapterNumber ॥";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
      child: Text(
        colophonText,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
