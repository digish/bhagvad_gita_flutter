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

import 'dart:ui';

import 'package:bhagvadgeeta/ui/theme/app_colors.dart';
import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/analytics_service.dart';
import '../widgets/sacred_sutra_promo_card.dart';

class _CreditItem {
  final String mark;
  final String title;
  final String source;
  final String description;
  final String? actionLabel;
  final String? actionUrl;

  const _CreditItem({
    required this.mark,
    required this.title,
    required this.source,
    required this.description,
    this.actionLabel,
    this.actionUrl,
  });
}

const List<_CreditItem> _credits = [
  _CreditItem(
    mark: '१',
    title: 'The scripture',
    source: 'Public domain',
    description:
        'The Sanskrit of the Shrimad Bhagavad Gita belongs to no one. This app is a vessel for that wisdom — not a claim upon it.',
  ),
  _CreditItem(
    mark: '२',
    title: 'The recitation',
    source: 'Swami Brahmananda',
    description:
        'Chanted by Swami Brahmananda. Presented here with the verses so you can listen and read together.',
  ),
  _CreditItem(
    mark: '३',
    title: 'The commentaries',
    source: 'Classical bhashya · Public domain',
    description:
        'Adi Shankaracharya, Ramanujacharya, and Madhvacharya — their open-domain commentaries, offered here as they have been received.',
  ),
  _CreditItem(
    mark: '४',
    title: 'The community',
    source: 'Elders, seekers, and readers',
    description:
        'Blessings and guidance from elders, and discourses of great personalities, have quietly shaped this work. Corrections, ideas, and notes from readers help keep it accurate. Thank you.',
  ),
  _CreditItem(
    mark: '५',
    title: 'A humble note',
    source: 'Errors are mine alone',
    description:
        'Any mistake in this app is my responsibility. It does not represent a fault in the scripture, the recitation, the commentaries, or those who blessed this work. If you see one, please point it out openly.',
  ),
  _CreditItem(
    mark: '६',
    title: 'The source',
    source: 'Digish Pandya · MIT License',
    description:
        'The code, emblems, and interface are published so the work can be inspected, trusted, and continued.',
    actionLabel: 'View on GitHub',
    actionUrl: 'https://github.com/digish/bhagvad_gita_flutter',
  ),
];

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen>
    with SingleTickerProviderStateMixin {
  static const _appPageUrl = 'https://digish.github.io/project/gita.html';

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) && _entrance.value < 1) {
      _entrance.value = 1;
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    AnalyticsService.instance.logLinkOpen(url: url, source: 'credits');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _shareApp(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    AnalyticsService.instance.logShare(contentType: 'app');
    SharePlus.instance.share(
      ShareParams(
        text:
            'A free Shrimad Bhagavad Gita app — read, listen, and study.\n\n$_appPageUrl',
        subject: 'Shrimad Bhagavad Gita',
        sharePositionOrigin: box != null
            ? box.localToGlobal(Offset.zero) & box.size
            : null,
      ),
    );
  }

  Animation<double> _itemAnimation(int index, {int extra = 0}) {
    final start = (0.06 * (index + extra)).clamp(0.0, 0.55);
    final end = (start + 0.42).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final showBackButton = MediaQuery.sizeOf(context).width <= 600;
    final isWide = MediaQuery.sizeOf(context).width > 700;
    final accent = isDark ? Colors.amber.shade300 : Colors.brown.shade700;
    final appColors = theme.extension<AppColors>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SimpleGradientBackground(
            startColor: isDark
                ? Colors.amber.shade900.withValues(alpha: 0.2)
                : const Color.fromARGB(255, 240, 255, 126),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            if (showBackButton)
                              Row(
                                children: [
                                  BackButton(color: theme.iconTheme.color),
                                  const Spacer(),
                                  const _LotusMark(),
                                  const Spacer(),
                                  const SizedBox(width: 48),
                                ],
                              )
                            else
                              const _LotusMark(),
                            const SizedBox(height: 20),
                            _FadeSlide(
                              animation: _itemAnimation(0),
                              child: Column(
                                children: [
                                  Text(
                                    'कृतज्ञता',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'NotoSerifDevanagari',
                                      fontSize: 30,
                                      height: 1.2,
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Credits',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cinzel(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2.4,
                                      height: 1.15,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'We stand on the shoulders of giants.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 18,
                                      color: theme
                                          .textTheme
                                          .bodyLarge
                                          ?.color
                                          ?.withValues(alpha: 0.72),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _GoldOrnament(color: accent),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        for (var i = 0; i < _credits.length; i += 2)
                                          _FadeSlide(
                                            animation: _itemAnimation(i + 1),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: _AcknowledgmentCard(
                                                item: _credits[i],
                                                accent: accent,
                                                appColors: appColors,
                                                onOpenUrl: _launchUrl,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        for (var i = 1; i < _credits.length; i += 2)
                                          _FadeSlide(
                                            animation: _itemAnimation(i + 1),
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: _AcknowledgmentCard(
                                                item: _credits[i],
                                                accent: accent,
                                                appColors: appColors,
                                                onOpenUrl: _launchUrl,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  for (var i = 0; i < _credits.length; i++)
                                    _FadeSlide(
                                      animation: _itemAnimation(i + 1),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: _AcknowledgmentCard(
                                          item: _credits[i],
                                          accent: accent,
                                          appColors: appColors,
                                          onOpenUrl: _launchUrl,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _FadeSlide(
                        animation: _itemAnimation(_credits.length + 1),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
                          child: Column(
                            children: [
                              _GoldOrnament(color: accent),
                              const SizedBox(height: 20),
                              Text(
                                'कर्मण्येवाधिकारस्ते मा फलेषु कदाचन',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'NotoSerifDevanagari',
                                  fontSize: 22,
                                  height: 1.5,
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your right is to the work alone,\nnever to its fruits.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Bhagavad Gita 2.47',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  letterSpacing: 1.2,
                                  color: theme
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Wrap(
                                spacing: 12,
                                runSpacing: 10,
                                alignment: WrapAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => _shareApp(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF4E342E)
                                          : const Color(0xFF5D4037),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      size: 20,
                                    ),
                                    label: const Text('Share the app'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () => _launchUrl(
                                      'https://github.com/digish/bhagvad_gita_flutter',
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: isDark
                                          ? const Color(0xFF2C2C2C)
                                          : const Color(0xFFFFF8E1),
                                      foregroundColor: accent,
                                      elevation: 2,
                                      shadowColor: Colors.black.withValues(
                                        alpha: 0.35,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.code_rounded,
                                      size: 20,
                                    ),
                                    label: const Text('View source'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              _EpicExploreCard(
                                accent: accent,
                                appColors: appColors,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LotusMark extends StatelessWidget {
  const _LotusMark();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'creditsLotusHero',
      child: Image.asset(
        'assets/images/lotus_gold.png',
        height: 76,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _GoldOrnament extends StatelessWidget {
  final Color color;

  const _GoldOrnament({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: color.withValues(alpha: 0.28),
            thickness: 0.7,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '॥',
            style: TextStyle(
              fontFamily: 'NotoSerifDevanagari',
              fontSize: 18,
              height: 1,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: color.withValues(alpha: 0.28),
            thickness: 0.7,
          ),
        ),
      ],
    );
  }
}

class _FadeSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _FadeSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _EpicExploreCard extends StatelessWidget {
  final Color accent;
  final AppColors? appColors;

  const _EpicExploreCard({
    required this.accent,
    required this.appColors,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        appColors?.cardBorder ?? accent.withValues(alpha: 0.22);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: SacredSutraPromoCard.openAppOrStoreAndMarkDiscoverDone,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        SacredSutraPromoCard.iconAsset,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _EpicNamesBlock(
                        theme: theme,
                        isDark: isDark,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 28,
                      color: accent.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'They still speak to this day: a promise that costs, a family that pulls two ways, a choice with no clean win. From them you can take how to keep your word, how to use power, and how to stand when it would be easier to leave.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    height: 1.5,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.88,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You do not need the whole epic at once. Sacred Sutra lets you explore them in bits and pieces — a scene, a person, a dilemma — and apply what lands.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color?.withValues(
                      alpha: 0.92,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpicNamesBlock extends StatelessWidget {
  final ThemeData theme;
  final bool isDark;

  const _EpicNamesBlock({
    required this.theme,
    required this.isDark,
  });

  TextStyle _nameStyle(
    Color color, {
    double size = 22,
    FontWeight weight = FontWeight.w700,
    FontStyle fontStyle = FontStyle.normal,
  }) {
    return GoogleFonts.cinzel(
      fontSize: size,
      fontWeight: weight,
      height: 1.12,
      letterSpacing: 0.6,
      fontStyle: fontStyle,
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sutraColor = theme.colorScheme.onSurface;
    final mahabharataColor =
        isDark ? Colors.amber.shade200 : const Color(0xFF5D4037);
    final ramayanaColor =
        isDark ? Colors.deepOrange.shade200 : const Color(0xFF9A3412);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sacred Sutra',
          style: _nameStyle(
            sutraColor,
            size: 26,
            weight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Mahabharata',
          style: _nameStyle(mahabharataColor, size: 23),
        ),
        const SizedBox(height: 5),
        Text(
          'Ramayana',
          style: _nameStyle(
            ramayanaColor,
            size: 23,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Still for the life you are living',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.62),
            height: 1.35,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _AcknowledgmentCard extends StatelessWidget {
  final _CreditItem item;
  final Color accent;
  final AppColors? appColors;
  final Future<void> Function(String url) onOpenUrl;

  const _AcknowledgmentCard({
    required this.item,
    required this.accent,
    required this.appColors,
    required this.onOpenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        appColors?.cardBorder ?? accent.withValues(alpha: 0.22);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.46),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      item.mark,
                      style: TextStyle(
                        fontFamily: 'NotoSerifDevanagari',
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.source,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 16,
                            color: accent,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                item.description,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  height: 1.5,
                  color: theme.textTheme.bodyLarge?.color?.withValues(
                    alpha: 0.88,
                  ),
                ),
              ),
              if (item.actionLabel != null && item.actionUrl != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () => onOpenUrl(item.actionUrl!),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(item.actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
