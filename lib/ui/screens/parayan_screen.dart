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
import '../../providers/settings_provider.dart';
import '../../data/static_data.dart';
import '../../models/shloka_result.dart';
import '../../providers/parayan_provider.dart';
import '../widgets/custom_scroll_indicator.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../widgets/full_shloka_card.dart';
import '../widgets/simple_gradient_background.dart';

// --- NEW: Enum to manage the content display modes ---
enum ParayanDisplayMode { shlokOnly, shlokAndAnvay, all }

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
  // --- NEW: State for display mode, replacing the old boolean ---
  ParayanDisplayMode _displayMode = ParayanDisplayMode.shlokAndAnvay;

  final ValueNotifier<String> _currentPositionLabelNotifier = ValueNotifier(
    'अध्याय 1, श्लोक 1',
  );

  // --- NEW: State to track the currently playing shloka ID ---
  String? _currentlyPlayingId;

  // --- NEW: Key and state to measure the header's height ---
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 200.0; // A reasonable default.

  // ✨ FIX: Store the provider instance to avoid unsafe lookups in dispose().
  AudioProvider? _audioProvider;

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
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
    _audioProvider?.addListener(_audioListener);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _itemPositionsListener.itemPositions.addListener(
        _updateCurrentPositionLabel,
      );
      // --- NEW: Measure the header's height after the first frame ---
      _measureHeader();
    });
  }

  void _measureHeader() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? headerBox = _headerKey.currentContext?.findRenderObject() as RenderBox?;
      if (headerBox != null && headerBox.hasSize && mounted) setState(() => _headerHeight = headerBox.size.height);
    });
  }

  // --- NEW: Listener to update the playing ID ---
  void _audioListener() {
    if (mounted && _currentlyPlayingId != _audioProvider?.currentPlayingShlokaId) {
      setState(() {
        _currentlyPlayingId = _audioProvider?.currentPlayingShlokaId;
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
    _audioProvider?.removeListener(_audioListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- NEW: Constants for font size control ---
    const double minFontSize = 16.0;
    const double maxFontSize = 32.0;
    const double fontStep = 2.0;
    // Use a Consumer to rebuild when font size changes.
    final settingsProvider = Provider.of<SettingsProvider>(context);

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
          Stack( // ✨ FIX: Use a Stack to layer the header over the list
              children: [
                // --- List Layer (at the bottom of the Stack) ---
                Consumer<ParayanProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                
                    // --- NEW: Determine card configuration based on display mode ---
                    final FullShlokaCardConfig cardConfig;
                    switch (_displayMode) {
                      case ParayanDisplayMode.shlokOnly:
                        cardConfig = FullShlokaCardConfig(baseFontSize: settingsProvider.fontSize, showAnvay: false, showBhavarth: false, showSeparator: false);
                        break;
                      case ParayanDisplayMode.shlokAndAnvay:
                        cardConfig = FullShlokaCardConfig(baseFontSize: settingsProvider.fontSize, showAnvay: true, showBhavarth: false, showSeparator: true);
                        break;
                      case ParayanDisplayMode.all:
                        cardConfig = FullShlokaCardConfig(baseFontSize: settingsProvider.fontSize, showAnvay: true, showBhavarth: true, showSeparator: true);
                        break;
                    }
                
                    final shlokas = provider.shlokas;
                
                    return Stack(
                      children: [
                        /// 📜 Main ScrollablePositionedList
                        ScrollablePositionedList.builder(
                            itemScrollController: _itemScrollController,
                            itemPositionsListener: _itemPositionsListener,
                            itemCount: shlokas.length,
                            padding: EdgeInsets.only(
                              // ✨ FIX: Add top padding to prevent the first item from being hidden by the header.
                              // 140 is a good starting point, adjust as needed.
                              // ✨ FIX: Add extra padding to the measured height to push the list down.
                              top: _headerHeight + 40.0,
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
                                    config: cardConfig.copyWith(showSpeaker: false, showColoredCard: false, showEmblem: false, showShlokIndex: true, spacingCompact: true, isLightTheme: true),
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
                // --- Header Layer (on top of the Stack) ---
                Positioned(
                  top: 0, left: 0, right: 0,
                  // ✨ FIX: Use a ValueListenableBuilder to react to scroll changes
                  child: ValueListenableBuilder<Iterable<ItemPosition>>(
                    valueListenable: _itemPositionsListener.itemPositions,
                    builder: (context, positions, child) {
                      // ✨ FIX: Get the status bar height to apply as padding.
                      final statusBarHeight = MediaQuery.of(context).padding.top;
                      double opacity = 0.0;
                      // Calculate opacity based on scroll position.
                      if (positions.isNotEmpty) {
                        // Get the position of the first item in the list.
                        final firstItem = positions.firstWhere(
                          (p) => p.index == 0,
                          orElse: () => positions.first,
                        );
                        // ✨ FIX: The opacity calculation should use the measured header height, not a fixed value.
                        // This ensures the fade effect starts exactly when the list scrolls under the header.
                        // We calculate how much of the header area has been scrolled over.
                        final scrollAmount = _headerHeight - firstItem.itemLeadingEdge;
                      // Clamp the opacity between 0.0 and 1.0.
                        opacity = (scrollAmount / 80.0).clamp(0.0, 1.0);
                      }

                      return Container(
                        // ✨ FIX: Use a light blue that complements the background gradient.
                        // This creates a softer, more integrated look than plain white.
                        color: Colors.indigo.shade50.withOpacity(opacity * 0.5),
                        // ✨ FIX: Add status bar height to the top padding.
                        padding: EdgeInsets.only(
                            top: statusBarHeight + 12,
                            left: 16,
                            right: 16,
                            bottom: 12),
                        child: child, // The header content
                      );
                    },
                    // The actual header content, which doesn't need to rebuild on every scroll tick.
                    child: Column(
                      key: _headerKey, // ✨ FIX: Assign key to the content to be measured.
                      children: [
                        _buildCenterWidget(context),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // This widget is defined below, ensure it's part of the measured content.
                            _FontSizeControl(
                              currentSize: settingsProvider.fontSize,
                              onDecrement: () {
                                if (settingsProvider.fontSize > minFontSize) {
                                  settingsProvider.setFontSize(settingsProvider.fontSize - fontStep);
                                }
                              },
                              onIncrement: () {
                                if (settingsProvider.fontSize < maxFontSize) {
                                  settingsProvider.setFontSize(settingsProvider.fontSize + fontStep);
                                }
                              },
                              color: Colors.black87,
                            ),
                            // This widget is defined below, ensure it's part of the measured content.
                            _buildDisplayModeButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
                
  Widget _buildCenterWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              // ✨ FIX: Added the rotation animation to match the other lotuses.
              final rotationAnimation = animation.drive(
                Tween<double>(begin: 0.0, end: 1.0),
              );
              return RotationTransition(
                turns: rotationAnimation,
                // Use the widget from the destination Hero as the shuttle
                // so it animates to the final size and position smoothly.
                child: (toHeroContext.widget as Hero).child,
              );
            },
            child: Image.asset(
              'assets/images/lotus_blue12.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: _currentPositionLabelNotifier,
          builder: (context, value, child) {
            return Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            );
          },
        ),
      ],
    );
  }

  // --- NEW: Cycle button for display mode ---
  void _cycleDisplayMode() {
    setState(() {
      final nextIndex = (_displayMode.index + 1) % ParayanDisplayMode.values.length;
      _displayMode = ParayanDisplayMode.values[nextIndex];
    });
  }

  Widget _buildDisplayModeButton() {
    IconData icon;
    String label;

    switch (_displayMode) {
      case ParayanDisplayMode.shlokOnly:
        icon = Icons.article_outlined;
        label = 'Shlok Only';
        break;
      case ParayanDisplayMode.shlokAndAnvay:
        icon = Icons.segment;
        label = 'Shlok & Anvay';
        break;
      case ParayanDisplayMode.all:
        icon = Icons.view_headline;
        label = 'Show All';
        break;
    }

    return OutlinedButton.icon(
      onPressed: _cycleDisplayMode,
      icon: Icon(icon, color: Colors.black54, size: 20),
      label: Text(
        label,
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide(color: Colors.black.withOpacity(0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
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

// --- NEW: Font size control widget (copied from shloka_list_screen) ---
class _FontSizeControl extends StatelessWidget {
  final double currentSize;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color color;

  const _FontSizeControl({
    required this.currentSize,
    required this.onDecrement,
    required this.onIncrement,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.remove, color: color),
          onPressed: onDecrement,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            '${currentSize.toInt()}',
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add, color: color),
          onPressed: onIncrement,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
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
