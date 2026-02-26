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

import 'package:bhagvadgeeta/ui/widgets/simple_gradient_background.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

// Data models for clarity
class CreditItem {
  final String category;
  final String source;
  final String description;

  const CreditItem({
    required this.category,
    required this.source,
    required this.description,
  });
}

final List<CreditItem> acknowledgmentsData = [
  const CreditItem(
    category: 'Divine Community 🤝',
    source: 'Seekers & Users',
    description:
        'A heartfelt thanks to our users who actively contribute via feedback, bug reports, and feature suggestions. Your dedication helps maintain the integrity of this spiritual tool.',
  ),
  const CreditItem(
    category: 'Sacred Sanskrit Text 📖',
    source: 'Public Domain',
    description:
        'The original Sanskrit verses of the Shrimad Bhagavad Gita are in the public domain. This app serves as a medium to bring this timeless wisdom to the digital age.',
  ),
  const CreditItem(
    category: 'Divine Sound 🎵',
    source: 'Public Digital Archives',
    description:
        'The soul-stirring recitations by Swami Brahmananda are shared here in a spirit of Seva. These are sourced from open archives (archive.org) and have been locally synchronized with the text to create a seamless learning experience.',
  ),
  const CreditItem(
    category: 'Open Source Spirit 🛠️',
    source: 'MIT License (GitHub)',
    description:
        'The codebase, custom chakra emblems, and UI designs are open-source. This ensures the app remains a transparent and community-driven resource.',
  ),
];

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // Could show a snackbar or dialog
      debugPrint('Could not launch $url');
    }
  }

  void _shareApp(BuildContext context) {
    // You can customize the share text and link
    final box = context.findRenderObject() as RenderBox?;
    const String appLink =
        'https://digish.github.io/project/index.html#bhagvadgita';
    Share.share(
      'Check out this beautiful Bhagavad Gita app!\n\n$appLink',
      subject: 'Bhagavad Gita App',
      sharePositionOrigin: box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Theme aware
      body: Stack(
        children: [
          SimpleGradientBackground(
            startColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.amber.shade900.withOpacity(0.2)
                : const Color.fromARGB(255, 240, 255, 126),
          ), // Golden-brown for credits
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                BackButton(
                                  color: Theme.of(context).iconTheme.color,
                                ),
                                Hero(
                                  tag: 'creditsLotusHero',
                                  child: Image.asset(
                                    'assets/images/lotus_gold.png',
                                    height: 80,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(
                                  width: 48,
                                ), // Balance for back button
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Divine Acknowledgements',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'In the spirit of Seva and Karma Yoga',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.brown.shade400),
                            ),
                            const SizedBox(height: 32),
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _launchUrl(
                                      'https://digish.github.io/project/',
                                    );
                                  },
                                  icon: const Icon(Icons.public),
                                  label: const Text('Developer Portfolio'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _shareApp(context),
                                  icon: const Icon(Icons.share_outlined),
                                  label: const Text('Share the Wisdom'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              MediaQuery.of(context).size.width > 700 ? 2 : 1,
                          mainAxisExtent: 160,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _AcknowledgmentCard(
                            item: acknowledgmentsData[index],
                          );
                        }, childCount: acknowledgmentsData.length),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          'This application is a humble offering built in the spirit of Seva. All third-party assets are used with respect for their creators and respective open-source guidelines.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withOpacity(0.5),
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

// A card for displaying credit information
class _AcknowledgmentCard extends StatelessWidget {
  final CreditItem item;
  const _AcknowledgmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.category,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.source,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? Colors.orange.shade300
                      : Colors.brown.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                item.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.4,
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
