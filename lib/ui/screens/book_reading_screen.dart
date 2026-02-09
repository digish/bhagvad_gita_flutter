/* 
*  © 2025 Digish Pandya. All rights reserved.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/database_helper_interface.dart';
import '../../models/shloka_result.dart';
import '../../providers/settings_provider.dart';
import '../../data/static_data.dart';

class BookReadingScreen extends StatefulWidget {
  final int chapterNumber;

  const BookReadingScreen({super.key, required this.chapterNumber});

  @override
  State<BookReadingScreen> createState() => _BookReadingScreenState();
}

class _BookReadingScreenState extends State<BookReadingScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  bool _isLoading = true;
  List<ShlokaResult> _shlokas = [];
  String _selectedAuthor = 'Swami Ramsukhdas'; // Default
  List<String> _availableAuthors = [];

  // Typography Constants
  static const double _kPadding = 24.0;

  // Local theme override
  bool? _isNightModeOverride;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbHelper = Provider.of<DatabaseHelperInterface>(
      context,
      listen: false,
    );
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    setState(() => _isLoading = true);

    try {
      final shlokas = await dbHelper.getShlokasByChapter(
        widget.chapterNumber,
        language: settings.language,
        script: settings.script,
      );

      // Extract unique authors available in this chapter
      final Set<String> authors = {};
      for (var s in shlokas) {
        if (s.commentaries != null) {
          for (var c in s.commentaries!) {
            authors.add(c.authorName);
          }
        }
      }

      setState(() {
        _shlokas = shlokas;
        _availableAuthors = authors.toList()..sort();
        if (_availableAuthors.isNotEmpty &&
            !_availableAuthors.contains(_selectedAuthor)) {
          _selectedAuthor = _availableAuthors.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading book data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _scrollToShloka(int index) {
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  String _processShlokaText(String rawText) {
    String processed = rawText.replaceAll(RegExp(r'॥\s?[०-९\-]+॥'), '॥');
    final couplets = processed.split('*');
    final allLines = <String>[];

    for (var couplet in couplets) {
      final parts = couplet.split('<C>');
      for (int i = 0; i < parts.length; i++) {
        String line = parts[i].trim();
        if (line.isNotEmpty) {
          allLines.add(line);
        }
      }
    }
    return allLines.join('\n');
  }

  Commentary? _getBestCommentary(
    List<Commentary>? variants,
    String selectedAuthor,
    String preferredScript,
    String preferredLang,
  ) {
    if (variants == null || variants.isEmpty) return null;

    final authorVariants = variants
        .where((c) => c.authorName == selectedAuthor)
        .toList();
    if (authorVariants.isEmpty) return null;

    // Smart Match Logic (Similar to CommentarySheet)
    Commentary? bestMatch;

    // 1. Try User's Preferred Script (e.g. 'gu' for Gujarati)
    try {
      bestMatch = authorVariants.firstWhere(
        (c) => c.languageCode == preferredScript,
      );
    } catch (_) {}

    // 2. Try User's Preferred Language
    if (bestMatch == null) {
      if (preferredLang == 'en') {
        try {
          bestMatch = authorVariants.firstWhere((c) => c.languageCode == 'en');
        } catch (_) {}
      } else if (preferredLang == 'hi') {
        try {
          bestMatch = authorVariants.firstWhere((c) => c.languageCode == 'hi');
        } catch (_) {
          try {
            bestMatch = authorVariants.firstWhere(
              (c) => c.languageCode == 'sa',
            );
          } catch (_) {}
        }
      }
    }

    // 3. Fallbacks
    bestMatch ??= authorVariants.firstWhere(
      (c) => c.languageCode == 'en',
      orElse: () => authorVariants.firstWhere(
        (c) => c.languageCode == 'sa',
        orElse: () => authorVariants.first,
      ),
    );

    return bestMatch;
  }

  void _showJumpToShlokaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Jump to Shloka",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: _shlokas.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _scrollToShloka(index);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final bool isDark =
        _isNightModeOverride ??
        (Theme.of(context).brightness == Brightness.dark);

    // Paper-like background for "Book" feel
    final backgroundColor = isDark
        ? const Color(0xFF121212) // Deeper black for reading
        : const Color(0xFFFAF9F6); // Off-white/Cream
    final textColor = isDark
        ? const Color(0xFFE0E0E0)
        : const Color(0xFF2C2C2C); // Soft Black
    final separatorColor = isDark ? Colors.white12 : Colors.black12;
    final accentColor = isDark
        ? Colors.orange.shade200
        : Colors.orange.shade700;

    final script = settings.script;
    final chapterName = StaticData.getChapterName(widget.chapterNumber, script);
    final localizedNum = StaticData.localizeNumber(
      widget.chapterNumber,
      script,
    );
    final localizedLabel = StaticData.getChapterLabel(script);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              "$localizedLabel $localizedNum",
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor.withOpacity(0.7),
              ),
            ),
            Text(
              chapterName,
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                "Commentary by $_selectedAuthor",
                style: GoogleFonts.notoSerif(
                  fontSize: 10,
                  color: textColor.withOpacity(0.5),
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          // Author Selection
          if (_availableAuthors.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.style, color: textColor),
              tooltip: "Select Commentary",
              initialValue: _selectedAuthor,
              onSelected: (value) => setState(() => _selectedAuthor = value),
              itemBuilder: (context) {
                return _availableAuthors.map((author) {
                  return PopupMenuItem(
                    value: author,
                    child: Text(author, style: GoogleFonts.notoSerif()),
                  );
                }).toList();
              },
            ),

          // Theme Toggle
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode),
            tooltip: "Toggle Reading Mode",
            onPressed: () => setState(() => _isNightModeOverride = !isDark),
          ),

          // Jump to Shloka
          IconButton(
            icon: const Icon(Icons.apps),
            tooltip: "Jump to Shloka",
            onPressed: _showJumpToShlokaSheet,
          ),
        ],
      ),
      body: SafeArea(
        left: true,
        right: true,
        bottom:
            false, // Let the list handle bottom padding if needed, or keep true. Usually false for lists with bottom padding.
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ScrollablePositionedList.separated(
                itemScrollController: _itemScrollController,
                itemPositionsListener: _itemPositionsListener,
                padding: const EdgeInsets.symmetric(vertical: _kPadding),
                itemCount: _shlokas.length,
                separatorBuilder: (context, index) => Divider(
                  color: separatorColor,
                  height: 48,
                  thickness: 1,
                  indent: _kPadding,
                  endIndent: _kPadding,
                ),
                itemBuilder: (context, index) {
                  final shloka = _shlokas[index];
                  final commentary = _getBestCommentary(
                    shloka.commentaries,
                    _selectedAuthor,
                    settings.script,
                    settings.language,
                  );

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _kPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Shloka Number
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: accentColor.withOpacity(0.4),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${shloka.chapterNo}.${shloka.shlokNo}",
                              style: GoogleFonts.notoSerif(
                                fontSize: 14,
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sanskrit Shloka
                        Text(
                          _processShlokaText(shloka.shlok),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.notoSerif(
                            fontSize: 20,
                            height: 1.8,
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bhavarth (Summary) - Distinguished by style
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: textColor.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(color: accentColor, width: 3),
                            ),
                          ),
                          child: Text(
                            shloka.bhavarth,
                            style: GoogleFonts.notoSerif(
                              fontSize: 16,
                              height: 1.6,
                              color: textColor.withOpacity(0.9),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (commentary != null &&
                            commentary.content.isNotEmpty) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  "Commentary by $_selectedAuthor",
                                  style: GoogleFonts.cinzel(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: textColor.withOpacity(0.5),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (commentary.languageCode.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: textColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    commentary.languageCode.toUpperCase(),
                                    style: GoogleFonts.notoSerif(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: textColor.withOpacity(0.4),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            commentary.content,
                            style: GoogleFonts.notoSerif(
                              fontSize: 17,
                              height: 1.7,
                              color: textColor.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
