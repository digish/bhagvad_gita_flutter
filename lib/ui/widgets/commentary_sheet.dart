import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/shloka_result.dart';
import '../../data/database_helper.dart';
import '../../utils/commentary_language.dart';
import 'commentary_language_switcher.dart';

class CommentarySheet extends StatefulWidget {
  final List<Commentary> commentaries;
  final String chapterNo;
  final String shlokNo;
  final double topSafeInset;
  final double bottomSafeInset;

  const CommentarySheet({
    super.key,
    required this.commentaries,
    required this.chapterNo,
    required this.shlokNo,
    required this.topSafeInset,
    required this.bottomSafeInset,
  });

  static double _deviceTopInset(BuildContext context) {
    return MediaQueryData.fromView(View.of(context)).viewPadding.top;
  }

  static double _deviceBottomInset(BuildContext context) {
    return MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
  }

  static Future<void> show(
    BuildContext context, {
    required List<Commentary>? commentaries,
    required String chapterNo,
    required String shlokNo,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => CommentarySheet(
        commentaries: commentaries ?? [],
        chapterNo: chapterNo,
        shlokNo: shlokNo,
        topSafeInset: _deviceTopInset(context),
        bottomSafeInset: _deviceBottomInset(context),
      ),
    );
  }

  @override
  State<CommentarySheet> createState() => _CommentarySheetState();
}

class _CommentarySheetState extends State<CommentarySheet> {
  int _selectedAuthorIndex = 0;
  final Map<String, String> _languageByAuthor = {};
  bool _isLoading = false;
  late List<Commentary> _effectiveCommentaries;

  @override
  void initState() {
    super.initState();
    _effectiveCommentaries = widget.commentaries;
    if (_effectiveCommentaries.isEmpty) {
      _fetchCommentaries();
    }
  }

  /// Clears Dynamic Island / notch with extra breathing room.
  static const double _minTopClearance = 64;
  static const double _topBuffer = 28;

  double _topGap(BuildContext context) {
    final inset = [
      widget.topSafeInset,
      MediaQuery.viewPaddingOf(context).top,
      MediaQueryData.fromView(View.of(context)).viewPadding.top,
    ].reduce(math.max);
    return math.max(inset, _minTopClearance) + _topBuffer;
  }

  double _sheetHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height - _topGap(context);
  }

  Widget _buildSheetFrame(
    BuildContext context, {
    required Widget child,
    double? height,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetHeight = height ?? _sheetHeight(context);

    return Padding(
      padding: EdgeInsets.only(top: _topGap(context)),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: sheetHeight,
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.85)
                          : Colors.white.withOpacity(0.95),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchCommentaries() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final db = await getInitializedDatabaseHelper();
      final fetched = await db.getCommentariesForShloka(
        widget.chapterNo,
        widget.shlokNo,
      );
      if (mounted) {
        setState(() {
          _effectiveCommentaries = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching commentaries: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSheetFrame(
        context,
        height: 300,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final groupedByAuthor = groupCommentariesByAuthor(
      _effectiveCommentaries,
      includeAuthor: (authorName) {
        if (settings.showClassicalCommentaries) return true;
        return _getCommentaryType(authorName) != 'Big Three (Classical)';
      },
    );

    final authorNames = groupedByAuthor.keys.toList()..sort();

    if (authorNames.isEmpty) {
      return _buildSheetFrame(
        context,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded, size: 48, color: theme.disabledColor),
              const SizedBox(height: 16),
              Text(
                "No commentaries available for this shloka.",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.disabledColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedAuthorIndex >= authorNames.length) {
      _selectedAuthorIndex = 0;
    }

    final selectedAuthor = authorNames[_selectedAuthorIndex];
    final authorVariants = groupedByAuthor[selectedAuthor]!;
    final availableLanguages = availableLanguageCodesForVariants(authorVariants);

    var selectedLanguage = _languageByAuthor[selectedAuthor] ??
        defaultCommentaryLanguage(
          authorVariants,
          preferredLanguage: settings.language,
        );
    if (!availableLanguages.contains(selectedLanguage)) {
      selectedLanguage = availableLanguages.first;
      _languageByAuthor[selectedAuthor] = selectedLanguage;
    }

    final selectedCommentary = commentaryForAuthorAndLanguage(
          authorVariants,
          selectedAuthor,
          selectedLanguage,
        ) ??
        authorVariants.first;

    return _buildSheetFrame(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                    // Handle bar
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Commentary",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'NotoSerif',
                                  ),
                                ),
                                Text(
                                  "Chapter ${widget.chapterNo}, Shloka ${widget.shlokNo}",
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Author tabs + compact language cycle
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(authorNames.length, (
                                  index,
                                ) {
                                  final author = authorNames[index];
                                  final displayName = commentaryAuthorShortName(
                                    groupedByAuthor[author]!.first
                                        .displayAuthorName,
                                  );
                                  final isSelected =
                                      index == _selectedAuthorIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? theme.colorScheme.onPrimary
                                              : theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        if (selected) {
                                          setState(() {
                                            _selectedAuthorIndex = index;
                                          });
                                        }
                                      },
                                      selectedColor: theme.colorScheme.primary,
                                      backgroundColor: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.grey.shade100,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: BorderSide(
                                          color: isSelected
                                              ? Colors.transparent
                                              : theme.dividerColor
                                                  .withOpacity(0.1),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),
                          CommentaryLanguageCycleButton(
                            availableLanguageCodes: availableLanguages,
                            selectedLanguageCode: selectedLanguage,
                            onCycle: () {
                              final next = nextCommentaryLanguage(
                                availableLanguages,
                                selectedLanguage,
                              );
                              if (next == null) return;
                              setState(() {
                                _languageByAuthor[selectedAuthor] = next;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

          // Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + math.max(widget.bottomSafeInset, 16),
              ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedCommentary.isAI)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceVariant
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: theme.dividerColor.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: 16,
                                      color: Colors.purple,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Modern synthesis',
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // --- NEW: Rich Rendering for AI Commentary ---
                            if (selectedCommentary.isAI &&
                                selectedCommentary.modern != null)
                              _buildModernCommentary(
                                context,
                                selectedCommentary.modern!,
                              )
                            else
                              Text(
                                selectedCommentary.content,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: 18,
                                  height: 1.8,
                                  fontFamily: 'NotoSerif',
                                  color: theme.textTheme.bodyLarge?.color
                                      ?.withOpacity(0.9),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildModernCommentary(BuildContext context, ModernCommentary data) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline
        Text(
          data.headline,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
            fontFamily: 'NotoSerif',
          ),
        ),
        if (data.context != null) ...[
          const SizedBox(height: 8),
          Text(
            data.context!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
        const SizedBox(height: 24),

        _buildSection(
          context,
          "Core Concept",
          data.coreConcept,
          Icons.psychology_outlined,
        ),
        _buildSection(
          context,
          "Modern Relevance",
          data.modernRelevance,
          Icons.update_outlined,
        ),
        _buildSection(
          context,
          "Actionable Takeaway",
          data.actionableTakeaway,
          Icons.directions_run_outlined,
        ),

        if (data.keywords.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: data.keywords
                .map(
                  (kw) => Chip(
                    label: Text(kw, style: const TextStyle(fontSize: 12)),
                    backgroundColor: theme.colorScheme.surfaceVariant,
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.6,
              color: theme.textTheme.bodyLarge?.color?.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  String _getCommentaryType(String author) {
    final name = author.toLowerCase();

    // The Big Three (Acharyas)
    if (name.contains('shankar') || // Adil Shankaracharya
        name.contains('ramanuj') || // Ramanujacharya
        name.contains('madhv') || // Madhvacharya
        name.contains('vallabh') || // Vallabhacharya
        name.contains('nimbark')) {
      // Nimbarkacharya
      return 'Big Three (Classical)';
    }

    // Modern Seekers / Commentators
    if (name.contains('gandhi') ||
        name.contains('chinmayananda') ||
        name.contains('ramsukhdas') ||
        name.contains('vinoba') ||
        name.contains('aurobindo') ||
        name.contains('sivananda') ||
        name.contains('purohit') ||
        name.contains('goyandka') ||
        name.contains('prabhupada') ||
        name.contains('osho')) {
      return 'Modern Seeker';
    }

    // Classical Bhakti / Others
    if (name.contains('sridhara') ||
        name.contains('madhusudan') ||
        name.contains('vishvanath') ||
        name.contains('keshav')) {
      return 'Classical Commentary';
    }

    return 'Standard Commentary';
  }
}
