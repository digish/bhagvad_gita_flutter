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

import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/sacred_sutra_quotes.dart';

/// Contextual home card: epic quote first; tap opens Sacred Sutra discover sheet.
class SacredSutraPromoCard extends StatefulWidget {
  final bool isSimpleLight;
  /// App language code (`en`, `hi`, …). Hindi uses HI quote text.
  final String languageCode;

  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=org.komal.sacredsutra';
  static const String appStoreUrl =
      'https://apps.apple.com/app/sacred-sutra/id6798266974';
  static const String _quoteIndexKey = 'sacred_sutra_quote_index';

  const SacredSutraPromoCard({
    super.key,
    required this.isSimpleLight,
    this.languageCode = 'en',
  });

  static String get storeUrl {
    if (!kIsWeb && Platform.isIOS) return appStoreUrl;
    return playStoreUrl;
  }

  static const String iconAsset = 'assets/images/sacred_sutra_icon.png';

  static Future<void> openStore() async {
    final uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Day-based seed used only when no saved index exists yet.
  static int indexForToday() {
    final quotes = beyondOwnedQuotes;
    if (quotes.isEmpty) return 0;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return dayOfYear % quotes.length;
  }

  static BeyondOwnedQuote quoteAt(int index) {
    final quotes = beyondOwnedQuotes;
    if (quotes.isEmpty) {
      return const BeyondOwnedQuote(
        id: 'empty',
        epic: kBeyondOwnedQuoteEpicMahabharat,
        en: '',
        hi: '',
      );
    }
    final i = index % quotes.length;
    return quotes[i < 0 ? i + quotes.length : i];
  }

  static BeyondOwnedQuote quoteForToday() => quoteAt(indexForToday());

  static Future<int> loadSavedIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_quoteIndexKey);
    if (saved != null) {
      final quotes = beyondOwnedQuotes;
      if (quotes.isEmpty) return 0;
      return saved % quotes.length;
    }
    final initial = indexForToday();
    await prefs.setInt(_quoteIndexKey, initial);
    return initial;
  }

  static Future<int> advanceAndSaveIndex(int currentIndex) async {
    final quotes = beyondOwnedQuotes;
    if (quotes.isEmpty) return 0;
    final next = (currentIndex + 1) % quotes.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_quoteIndexKey, next);
    return next;
  }

  static void showDiscoverSheet(
    BuildContext context, {
    BeyondOwnedQuote? quote,
    String languageCode = 'en',
  }) {
    final resolved = quote ?? quoteForToday();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SacredSutraDiscoverSheet(
          quote: resolved,
          languageCode: languageCode,
        );
      },
    );
  }

  @override
  State<SacredSutraPromoCard> createState() => _SacredSutraPromoCardState();
}

class _SacredSutraPromoCardState extends State<SacredSutraPromoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late BeyondOwnedQuote _quote;
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();
    _quote = SacredSutraPromoCard.quoteForToday();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _restoreQuoteIndex();
  }

  Future<void> _restoreQuoteIndex() async {
    final index = await SacredSutraPromoCard.loadSavedIndex();
    if (!mounted) return;
    setState(() {
      _quoteIndex = index;
      _quote = SacredSutraPromoCard.quoteAt(index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openDiscover() {
    SacredSutraPromoCard.showDiscoverSheet(
      context,
      quote: _quote,
      languageCode: widget.languageCode,
    );
  }

  Future<void> _refreshQuote() async {
    final next = await SacredSutraPromoCard.advanceAndSaveIndex(_quoteIndex);
    if (!mounted) return;
    setState(() {
      _quoteIndex = next;
      _quote = SacredSutraPromoCard.quoteAt(next);
    });
  }

  String get _epicLabel {
    if (_quote.epic == kBeyondOwnedQuoteEpicRamayan) {
      return 'From the Ramayana';
    }
    if (_quote.epic == kBeyondOwnedQuoteEpicMahabharat) {
      return 'From the Mahabharata';
    }
    return 'Sacred wisdom';
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.isSimpleLight;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isLight
          ? [
              const Color(0xFFFFF8F0).withOpacity(0.92),
              const Color(0xFFFFE8D0).withOpacity(0.88),
              const Color(0xFFE8F4F8).withOpacity(0.90),
            ]
          : [
              const Color(0xFF2A1A0E).withOpacity(0.55),
              const Color(0xFF1A2438).withOpacity(0.50),
              const Color(0xFF0F1C2E).withOpacity(0.55),
            ],
    );

    final borderColor = isLight
        ? const Color(0xFFC47A3A).withOpacity(0.35)
        : const Color(0xFFE8B86D).withOpacity(0.35);

    final labelColor = isLight
        ? const Color(0xFF9A4E1C)
        : const Color(0xFFE8B86D);

    final quoteColor = isLight
        ? const Color(0xFF2C1810)
        : const Color(0xFFFFF8EE);

    final mutedColor = isLight
        ? const Color(0xFF5C4030).withOpacity(0.7)
        : Colors.white.withOpacity(0.55);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(top: 14.0, left: 16.0, right: 16.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: isLight
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC47A3A).withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.0),
                    onTap: _openDiscover,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -28,
                            top: -24,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFE8B86D)
                                        .withOpacity(isLight ? 0.22 : 0.18),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 12, 8, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 32),
                                    Expanded(
                                      child: Text(
                                        _epicLabel.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: labelColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 32,
                                      width: 32,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.refresh,
                                          size: 18,
                                          color: labelColor.withOpacity(0.85),
                                        ),
                                        onPressed: _refreshQuote,
                                        tooltip: 'Next quote',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 10,
                                    left: 4,
                                  ),
                                  child: Text(
                                    '“${_quote.localized(widget.languageCode)}”',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: quoteColor,
                                      fontSize: 22,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(7),
                                      child: Image.asset(
                                        SacredSutraPromoCard.iconAsset,
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Sacred Sutra · tap to explore',
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full slide-up sheet: sell the bridge first, sticky CTA, then 3 features.
class SacredSutraDiscoverSheet extends StatelessWidget {
  final BeyondOwnedQuote quote;
  final String languageCode;

  const SacredSutraDiscoverSheet({
    super.key,
    required this.quote,
    this.languageCode = 'en',
  });

  String get _sourceLabel {
    if (quote.epic == kBeyondOwnedQuoteEpicRamayan) {
      return 'From the Ramayana';
    }
    if (quote.epic == kBeyondOwnedQuoteEpicMahabharat) {
      return 'From the Mahabharata';
    }
    return 'Sacred wisdom';
  }

  Future<void> _getApp(BuildContext context) async {
    Navigator.of(context).maybePop();
    await SacredSutraPromoCard.openStore();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    final bg = isDark ? const Color(0xFF1A1520) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFFFF6E8) : const Color(0xFF2C1810);
    final bodyColor = isDark
        ? Colors.white.withOpacity(0.78)
        : const Color(0xFF5C4030);
    final accent = isDark ? const Color(0xFFE8B86D) : const Color(0xFF9A4E1C);
    final cardBg = isDark
        ? Colors.white.withOpacity(0.06)
        : const Color(0xFFFFF4E8);
    final ctaFg = isDark ? const Color(0xFF1A1208) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                  children: [
                    // 1. Icon + name + subtitle
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              SacredSutraPromoCard.iconAsset,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sacred Sutra',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Mahabharata & Ramayana · Offline',
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. Headline + short pitch
                    Text(
                      'Read the full texts',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Mahabharata and Ramayana on your device — the same careful reading as the Gita, not summaries.',
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 14.5,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 3. Features (keep 3)
                    _FeatureRow(
                      icon: Icons.menu_book_rounded,
                      title: 'Full epics, offline',
                      body:
                          'Mahabharata and Ramayana on your device — resume anytime, no network needed.',
                      accent: accent,
                      titleColor: titleColor,
                      bodyColor: bodyColor,
                    ),
                    _FeatureRow(
                      icon: Icons.account_tree_outlined,
                      title: 'Stories, characters & places',
                      body:
                          'Browse by narrative, meet figures and locations, and sit with dharma dilemmas in the text.',
                      accent: accent,
                      titleColor: titleColor,
                      bodyColor: bodyColor,
                    ),
                    _FeatureRow(
                      icon: Icons.self_improvement_rounded,
                      title: 'Teachings in context',
                      body:
                          'See the Gita where it sits in the Mahabharata — then go further into the epic.',
                      accent: accent,
                      titleColor: titleColor,
                      bodyColor: bodyColor,
                    ),
                    const SizedBox(height: 8),

                    // 4. Optional secondary quote (bilingual, quieter)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sourceLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '“${quote.en}”',
                            style: TextStyle(
                              color: titleColor.withOpacity(0.9),
                              fontSize: 13.5,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (quote.hi.trim().isNotEmpty &&
                              quote.hi.trim() != quote.en.trim()) ...[
                            const SizedBox(height: 4),
                            Text(
                              quote.hi,
                              style: TextStyle(
                                color: bodyColor.withOpacity(0.85),
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // Sticky CTA above home indicator
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(22, 10, 22, 8 + bottomInset),
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _getApp(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: ctaFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Get Sacred Sutra',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Not now',
                        style: TextStyle(
                          color: bodyColor.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final Color titleColor;
  final Color bodyColor;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    required this.titleColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: bodyColor,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
