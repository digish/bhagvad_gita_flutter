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
    source: 'Acharyas and modern teachers',
    description:
        'Classical bhashya from Adi Shankaracharya, Ramanujacharya, and Madhvacharya. English and Hindi of those bhashyas are AI translations of the Sanskrit, kept separate from the modern AI summary. Later readings from Swami Sivananda, Swami Ramsukhdas, and others remain distinct.',
  ),
  _CreditItem(
    mark: '४',
    title: 'The community',
    source: 'Readers who write back',
    description:
        'Corrections, ideas, and notes from readers help keep the app accurate. Thank you.',
  ),
  _CreditItem(
    mark: '५',
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
                                      fontSize: 22,
                                      height: 1.2,
                                      color: accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Credits',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cinzel(
                                      textStyle: theme.textTheme.headlineSmall,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 3.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'The people and sources behind this app.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme
                                          .textTheme
                                          .bodyMedium
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
                                  fontSize: 16,
                                  height: 1.55,
                                  color: accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your right is to the work alone,\nnever to its fruits.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Bhagavad Gita 2.47',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.4,
                                  color: theme
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 28),
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
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      size: 18,
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
                                        horizontal: 18,
                                        vertical: 12,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.code_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('View source'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 56),
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
              fontSize: 13,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
                    width: 44,
                    height: 44,
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
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.source,
                          style: theme.textTheme.bodySmall?.copyWith(
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
              const SizedBox(height: 12),
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.86,
                  ),
                ),
              ),
              if (item.actionLabel != null && item.actionUrl != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    onPressed: () => onOpenUrl(item.actionUrl!),
                    icon: const Icon(Icons.open_in_new_rounded, size: 14),
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
