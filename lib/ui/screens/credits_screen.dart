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
import '../widgets/responsive_wrapper.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
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

// --- Static Data for the screen ---
final List<CreditItem> creditsData = [
  const CreditItem(
    category: 'Bhagvad gita audio recitations',
    source: 'https://archive.org/details/bhagavad-gita-1-18',
    description: 'Audio resourece as provided by Swami Brahmananda',
  ),

  const CreditItem(
    category: 'Geeta Text',
    source:
        'https://sanskritdocuments.org/doc_giitaa/gitAanvayasandhivigraha.html?lang=sa',
    description:
        'shloka-anvay and sandhi-vigrah is a derived work from this work done by Sunder Hattangadi',
  ),

  const CreditItem(
    category: 'Commentary & Translations',
    source: 'https://www.gitasupersite.iitk.ac.in/srimad',
    description:
        'Comprehensive commentary and multiple translations sourced from Gita Supersite (IIT Kanpur).',
  ),

  const CreditItem(
    category: 'Transliteration Tool',
    source: 'http://www.learnsanskrit.org/tools/sanscript',
    description: 'Transliteration tool used.',
  ),

  const CreditItem(
    category: 'Lotus mandala Image',
    source: 'www.freepik.com',
    description: 'Lotus mandala image from artist on Freepik.com',
  ),
  const CreditItem(
    category: 'Emblems',
    source: 'Internal Design',
    description:
        'All chapter emblems, speaker icons, and app logos were created by the developer with help from AI.',
  ),
  const CreditItem(
    category: 'Lotus Image',
    source: 'Internal desing',
    description: 'Different lotus are generated using AI like copilot',
  ),

  const CreditItem(
    category: 'Source Code',
    source: 'https://github.com/digish/bhagvad_gita_flutter',
    description:
        'Source code is open source and available on GitHub under the MIT License.',
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32.0),
                    child: ResponsiveWrapper(
                      maxWidth:
                          450, // ✨ Tighter constraint for clear sidebar look
                      alignment: Alignment.topRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment
                            .end, // ✨ Align text/children to right
                        children: [
                          const SizedBox(
                            height: 24,
                          ), // Adjusted padding after SafeArea
                          Stack(
                            alignment:
                                Alignment.centerRight, // ✨ Align Lotus to right
                            children: [
                              // ✨ FIX: Uniform Back Button Logic (iOS + Narrow only)
                              if (Theme.of(context).platform ==
                                      TargetPlatform.iOS &&
                                  MediaQuery.of(context).size.width <= 600)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: BackButton(
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                  ),
                                ),
                              GestureDetector(
                                onTap: MediaQuery.of(context).size.width > 600
                                    ? null
                                    : () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go('/');
                                        }
                                      },
                                child: Hero(
                                  tag: 'creditsLotusHero', // A new unique tag
                                  child: Image.asset(
                                    'assets/images/lotus_gold.png', // A new golden lotus asset
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Credits & Acknowledgements',
                            textAlign: TextAlign.right, // ✨ Right align text
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                            ), // Remove horiz padding to align with edge
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              alignment:
                                  WrapAlignment.end, // ✨ Align buttons to right
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _launchUrl(
                                      'https://digish.github.io/project/',
                                    );
                                  },
                                  icon: const Icon(Icons.shop_2_outlined),
                                  label: const Text('More Apps'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _shareApp(context),
                                  icon: const Icon(Icons.share_outlined),
                                  label: const Text('Share App'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.brown.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 32.0),
                      child: ResponsiveWrapper(
                        maxWidth: 450, // ✨ Match tighter width
                        alignment: Alignment.topRight,
                        child: _CreditCard(item: creditsData[index]),
                      ),
                    );
                  }, childCount: creditsData.length),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// A card for displaying credit information
class _CreditCard extends StatelessWidget {
  final CreditItem item;
  const _CreditCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade900.withOpacity(0.6)
                  : Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12.0),
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.titleMedium?.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                item.source.startsWith('http') || item.source.startsWith('www')
                    ? InkWell(
                        onTap: () async {
                          String url = item.source;
                          if (url.startsWith('www')) {
                            url = 'https://$url';
                          }
                          final Uri uri = Uri.parse(url);
                          if (!await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          )) {
                            debugPrint('Could not launch $url');
                          }
                        },
                        child: Text(
                          'Source: ${item.source}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.blue.shade700,
                            fontStyle: FontStyle.italic,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(
                        'Source: ${item.source}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
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
