/* 
*  © 2025 Digish Pandya. All rights reserved.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../data/database_helper_interface.dart';
import '../../models/shloka_result.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../data/static_data.dart';
import '../../utils/commentary_language.dart';
import '../../utils/scroll_focus_runway.dart';
import '../widgets/font_size_control.dart';
import '../widgets/commentary_language_switcher.dart';

class BookReadingScreen extends StatefulWidget {
  final int chapterNumber;
  final int? initialShlokaNo;
  /// When true, hide the AppBar — parent chrome (chapter title / mode toggle) owns navigation.
  final bool embedded;

  const BookReadingScreen({
    super.key,
    required this.chapterNumber,
    this.initialShlokaNo,
    this.embedded = false,
  });

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
  String _selectedCommentaryLanguage = 'en';
  List<String> _availableAuthors = [];

  // Typography Constants
  static const double _kPadding = 24.0;
  static const double _kRefFontSize = 20.0;
  /// Target line for scroll-to-shloka (verse center lands here).
  static const double _kFocusLine = kDefaultFocusLine;
  static const int _kTrailingRunwayItems = 1;
  double _scaledFont(double size, double base) => size * (base / _kRefFontSize);

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
        shlokaScript: settings.shlokaScript,
      );

      // Extract unique authors available in this chapter
      final Set<String> authors = {};
      for (var s in shlokas) {
        if (s.commentaries != null) {
          for (var c in s.commentaries!) {
            authors.add(c.canonicalAuthorName);
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
        _syncCommentaryLanguageForAuthor(settings.language);
        _isLoading = false;

        // Handle initial scroll
        if (widget.initialShlokaNo != null) {
          final targetNo = widget.initialShlokaNo!;
          final targetIndex = _shlokas.indexWhere(
            (s) => int.tryParse(s.shlokNo) == targetNo,
          );
          if (targetIndex != -1) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final ok = await _scrollToShloka(targetIndex);
              if (!ok && mounted) {
                await Future<void>.delayed(const Duration(milliseconds: 200));
                if (mounted) await _scrollToShloka(targetIndex);
              }
            });
          }
        }
      });
    } catch (e) {
      debugPrint("Error loading book data: $e");
      setState(() => _isLoading = false);
    }
  }

  double? _alignmentForItemCenter(int index, {bool requireVisible = false}) {
    final positions = _itemPositionsListener.itemPositions.value;
    for (final p in positions) {
      if (p.index == index) {
        final halfHeight =
            (p.itemTrailingEdge - p.itemLeadingEdge).abs() / 2;
        return (_kFocusLine - halfHeight).clamp(0.0, 1.0);
      }
    }
    if (requireVisible) return null;
    return (_kFocusLine - 0.09).clamp(0.0, 1.0);
  }

  Future<bool> _scrollToShloka(int index) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted) return false;
      if (!_itemScrollController.isAttached) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
        continue;
      }

      final alignment = _alignmentForItemCenter(index) ??
          (_kFocusLine - 0.09).clamp(0.0, 1.0);

      await _itemScrollController.scrollTo(
        index: index,
        duration: Duration(milliseconds: attempt == 0 ? 500 : 220),
        curve: Curves.easeInOutCubic,
        alignment: alignment,
      );

      await Future<void>.delayed(const Duration(milliseconds: 48));
      if (!mounted || !_itemScrollController.isAttached) return false;

      final refined = _alignmentForItemCenter(index, requireVisible: true);
      if (refined == null) {
        continue;
      }

      final positions = _itemPositionsListener.itemPositions.value;
      ItemPosition? item;
      for (final p in positions) {
        if (p.index == index) {
          item = p;
          break;
        }
      }
      if (item == null) {
        continue;
      }

      final center = (item.itemLeadingEdge + item.itemTrailingEdge) / 2;
      final delta = (center - _kFocusLine).abs();
      if (delta <= 0.03) {
        return true;
      }
      if (delta <= 0.06 &&
          center <= _kFocusLine + 0.06 &&
          item.itemTrailingEdge <= 1.02) {
        return true;
      }

      await _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        alignment: refined,
      );
      await Future<void>.delayed(const Duration(milliseconds: 32));
      if (!mounted) return false;

      final positionsAfter = _itemPositionsListener.itemPositions.value;
      for (final p in positionsAfter) {
        if (p.index == index) {
          final c = (p.itemLeadingEdge + p.itemTrailingEdge) / 2;
          if ((c - _kFocusLine).abs() <= 0.04) {
            return true;
          }
          if (c <= _kFocusLine + 0.06 && p.itemTrailingEdge <= 1.02) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Topmost visible verse — used to hold scroll steady when commentary reflows.
  ({int index, double alignment})? _readScrollAnchor() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return null;

    final visible = positions
        .where((p) => p.itemTrailingEdge > 0 && p.itemLeadingEdge < 1)
        .toList();
    if (visible.isEmpty) return null;

    visible.sort((a, b) => a.itemLeadingEdge.compareTo(b.itemLeadingEdge));
    final anchor = visible.first;
    return (index: anchor.index, alignment: anchor.itemLeadingEdge);
  }

  void _restoreScrollAnchor(({int index, double alignment}) anchor) {
    void apply() {
      if (!mounted || !_itemScrollController.isAttached) return;
      _itemScrollController.jumpTo(
        index: anchor.index,
        alignment: anchor.alignment.clamp(-0.5, 1.0),
      );
    }

    // Two frames: first after rebuild, second after commentary text relayout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apply();
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
    });
  }

  void _updateCommentaryView(VoidCallback update) {
    final anchor = _readScrollAnchor();
    setState(update);
    if (anchor != null) {
      _restoreScrollAnchor(anchor);
    }
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

  List<String> _languagesForSelectedAuthor() {
    return availableLanguagesForAuthorInChapter(_shlokas, _selectedAuthor);
  }

  void _syncCommentaryLanguageForAuthor(String preferredLanguage) {
    final langs = _languagesForSelectedAuthor();
    if (langs.isEmpty) return;
    if (langs.contains(_selectedCommentaryLanguage)) return;

    var sample = <Commentary>[];
    for (final shloka in _shlokas) {
      sample = variantsForAuthor(shloka.commentaries, _selectedAuthor);
      if (sample.isNotEmpty) break;
    }

    _selectedCommentaryLanguage = defaultCommentaryLanguage(
      sample,
      preferredLanguage: preferredLanguage,
    );
    if (!langs.contains(_selectedCommentaryLanguage)) {
      _selectedCommentaryLanguage = langs.first;
    }
  }

  void _onAuthorSelected(String author, String preferredLanguage) {
    _updateCommentaryView(() {
      _selectedAuthor = author;
      _syncCommentaryLanguageForAuthor(preferredLanguage);
    });
  }

  Commentary? _commentaryForShloka(ShlokaResult shloka) {
    return resolveCommentaryVariant(
      shloka.commentaries,
      _selectedAuthor,
      _selectedCommentaryLanguage,
    );
  }

  void _cycleCommentaryLanguage() {
    final langs = _languagesForSelectedAuthor();
    final next = nextCommentaryLanguage(langs, _selectedCommentaryLanguage);
    if (next == null) return;
    _updateCommentaryView(() => _selectedCommentaryLanguage = next);
  }

  Widget _buildCommentaryControls({
    required Color textColor,
    required String preferredLanguage,
  }) {
    final langs = _languagesForSelectedAuthor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CommentaryAuthorMenuButton(
          authors: _availableAuthors,
          selectedAuthor: _selectedAuthor,
          onAuthorSelected: (value) => _onAuthorSelected(value, preferredLanguage),
          foregroundColor: textColor,
          borderColor: textColor.withValues(alpha: 0.18),
          backgroundColor: textColor.withValues(alpha: 0.05),
        ),
        if (langs.length > 1) ...[
          const SizedBox(width: 8),
          CommentaryLanguageCycleButton(
            availableLanguageCodes: langs,
            selectedLanguageCode: _selectedCommentaryLanguage,
            onCycle: _cycleCommentaryLanguage,
            foregroundColor: textColor,
            borderColor: textColor.withValues(alpha: 0.18),
            backgroundColor: textColor.withValues(alpha: 0.05),
          ),
        ],
      ],
    );
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
    final baseFont = settings.fontSize;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: widget.embedded
          ? null
          : AppBar(
        toolbarHeight: 100,
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chapters');
            }
          },
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
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
          ],
        ),
        centerTitle: true,
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (_availableAuthors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildCommentaryControls(
                textColor: textColor,
                preferredLanguage: settings.language,
              ),
            ),
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
      body: Stack(
        children: [
          SafeArea(
        top: !widget.embedded,
        left: !widget.embedded,
        right: true,
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (widget.embedded) ...[
                    SizedBox(
                      height: MediaQuery.paddingOf(context).top + 56,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      child: Row(
                        children: [
                          _buildCommentaryControls(
                            textColor: textColor,
                            preferredLanguage: settings.language,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode,
                              color: textColor,
                            ),
                            tooltip: 'Toggle Reading Mode',
                            onPressed: () => setState(
                              () => _isNightModeOverride = !isDark,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.apps, color: textColor),
                            tooltip: 'Jump to Shloka',
                            onPressed: _showJumpToShlokaSheet,
                          ),
                        ],
                      ),
                    ),
                  ] else if (_availableAuthors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildCommentaryControls(
                          textColor: textColor,
                          preferredLanguage: settings.language,
                        ),
                      ),
                    ),
                  Expanded(
                    child: RepaintBoundary(
                child: ScrollablePositionedList.separated(
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  padding: EdgeInsets.fromLTRB(
                    0,
                    _kPadding,
                    0,
                    _kPadding + 72 + MediaQuery.paddingOf(context).bottom,
                  ),
                  itemCount: _shlokas.length + _kTrailingRunwayItems,
                  separatorBuilder: (context, index) {
                    if (index >= _shlokas.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return Divider(
                      color: separatorColor,
                      height: 48,
                      thickness: 1,
                      indent: _kPadding,
                      endIndent: _kPadding,
                    );
                  },
                  itemBuilder: (context, index) {
                    if (index >= _shlokas.length) {
                      return SizedBox(
                        height: trailingRunwayHeightForFocusLine(
                          context,
                          focusLine: _kFocusLine,
                        ),
                      );
                    }
                    final shloka = _shlokas[index];
                    final commentary = _commentaryForShloka(shloka);
                    final usingFallback = commentary != null &&
                        commentary.languageCode.toLowerCase() !=
                            _selectedCommentaryLanguage.toLowerCase();

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _kPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                  fontSize: _scaledFont(14, baseFont),
                                  color: accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _processShlokaText(shloka.shlok),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSerif(
                              fontSize: baseFont,
                              height: 1.8,
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                                fontSize: _scaledFont(16, baseFont),
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
                                    commentary.sectionHeading,
                                    style: GoogleFonts.cinzel(
                                      fontSize: _scaledFont(11, baseFont),
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
                                      commentaryLanguageLabel(
                                        commentary.languageCode,
                                      ),
                                      style: GoogleFonts.notoSerif(
                                        fontSize: _scaledFont(9, baseFont),
                                        fontWeight: FontWeight.bold,
                                        color: textColor.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (usingFallback) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${commentaryLanguageLabel(_selectedCommentaryLanguage)} not available for this shloka — showing ${commentaryLanguageLabel(commentary.languageCode)}.',
                                style: GoogleFonts.notoSerif(
                                  fontSize: _scaledFont(11, baseFont),
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                  color: textColor.withOpacity(0.45),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (commentary.isAI && commentary.modern != null)
                              _buildModernCommentary(
                                context,
                                commentary.modern!,
                                textColor,
                                accentColor,
                                baseFont,
                              )
                            else
                              Text(
                                commentary.content,
                                style: GoogleFonts.notoSerif(
                                  fontSize: _scaledFont(17, baseFont),
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
                  ),
                ],
              ),
      ),
          Consumer<AudioProvider>(
            builder: (context, audio, _) {
              final miniPlayerVisible =
                  audio.playbackState != PlaybackState.stopped &&
                  audio.currentPlayingShlokaId != null;
              final bottomSafe = MediaQuery.paddingOf(context).bottom;
              return Positioned(
                left: MediaQuery.paddingOf(context).left,
                bottom: miniPlayerVisible ? 96 + bottomSafe : 12 + bottomSafe,
                child: FontSizeDock(
                  currentSize: settings.fontSize,
                  onSizeChanged: settings.setFontSize,
                  iconColor: textColor,
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFF7F4EE),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernCommentary(
    BuildContext context,
    ModernCommentary data,
    Color textColor,
    Color accentColor,
    double baseFont,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          data.headline,
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            fontSize: _scaledFont(18, baseFont),
            fontWeight: FontWeight.bold,
            color: accentColor,
          ),
        ),
        if (data.context != null) ...[
          const SizedBox(height: 12),
          Text(
            data.context!,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              fontSize: _scaledFont(14, baseFont),
              fontStyle: FontStyle.italic,
              color: textColor.withOpacity(0.6),
            ),
          ),
        ],
        const SizedBox(height: 32),
        _buildSection(
          "Core Concept",
          data.coreConcept,
          Icons.psychology_outlined,
          textColor,
          accentColor,
          baseFont,
        ),
        _buildSection(
          "Modern Relevance",
          data.modernRelevance,
          Icons.update_outlined,
          textColor,
          accentColor,
          baseFont,
        ),
        _buildSection(
          "Actionable Takeaway",
          data.actionableTakeaway,
          Icons.directions_run_outlined,
          textColor,
          accentColor,
          baseFont,
        ),
        if (data.keywords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: data.keywords
                .map(
                  (kw) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentColor.withOpacity(0.2)),
                    ),
                    child: Text(
                      kw,
                      style: GoogleFonts.notoSerif(
                        fontSize: _scaledFont(11, baseFont),
                        color: accentColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(
    String title,
    String content,
    IconData icon,
    Color textColor,
    Color accentColor,
    double baseFont,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accentColor),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.cinzel(
                  fontSize: _scaledFont(12, baseFont),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.notoSerif(
              fontSize: _scaledFont(16, baseFont),
              height: 1.6,
              color: textColor.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
