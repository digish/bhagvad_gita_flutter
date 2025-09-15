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

class AuthorProfile {
  final String author;
  final String? domain;
  final String? emblemAsset;
  final List<String> quotes;
  final List<String> favoriteShlokas;

  const AuthorProfile({
    required this.author,
    this.domain,
    this.emblemAsset,
    required this.quotes,
    this.favoriteShlokas = const [],
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
    source: 'https://sanskritdocuments.org/doc_giitaa/gitAanvayasandhivigraha.html?lang=sa',
    description: 'shloka-anvay and sandhi-vigrah is a derived work from this work done by Sunder Hattangadi',
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
    description: 'All chapter emblems, speaker icons, and app logos were created by the developer with help from AI.',
  ),
  const CreditItem(
    category: 'Lotus Image',
    source: 'Internal desing',
    description: 'Different lotus are generated using AI like copilot',
  ),

  const CreditItem(
    category: 'Source Code',
    source: 'https://github.com/digish/bhagvad_gita_flutter',
    description: 'Source code is open source and available on GitHub under the MIT License.',
  ),
];

final List<AuthorProfile> authorProfilesData = [

  const AuthorProfile(
    author: 'Pandurang Shastri Athavale',
    domain: 'Spiritual Reformer & Founder of Swadhyay',
    emblemAsset: 'assets/emblems/authors/dadaji.png',
    quotes: [
      'Bhakti is a social force. The Gita is a call to awaken divinity in society.',
      'The Gita is not just a religious scripture but a scripture for life, in which, a step ahead of even selfless service to humanity, the message of  सर्वभूतहिते रताः is given.'
    ],
    favoriteShlokas: ['6,30', '9,22', '5,25'],
  ),
  const AuthorProfile(
    author: 'Swami Vivekananda',
    domain: 'Spiritual Reformer',
    emblemAsset: 'assets/emblems/authors/sv.png',
    quotes: [
      'The Gita is the best commentary we have on the Vedanta philosophy.',
    ],
    favoriteShlokas: ['13,28'],
  ),
  const AuthorProfile(
    author: 'Albert Einstein',
    domain: 'Scientist',
    emblemAsset: 'assets/emblems/authors/ae.png',
    quotes: [
      'When I read the Bhagavad-Gita and reflect about how God created this universe everything else seems so superfluous.',
    ],
    favoriteShlokas: ['7,7'],
  ),

  const AuthorProfile(
    author: 'Paramahansa Yogananda',
    domain: 'Yogi & Spiritual Teacher',
    emblemAsset: 'assets/emblems/authors/yp.png',
    quotes: [
      'If devotees do not progress, it is because they discard their weapons of self-control',
      'within the soul is a source of infinite',

    ],
    favoriteShlokas: ['6,5', '2,24'],
  ),

  const AuthorProfile(
    author: 'Henry David Thoreau',
    domain: 'Naturalist & Philosopher',
    emblemAsset: 'assets/emblems/authors/hdt.png',
    quotes: [
      'In the morning I bathe my intellect in the stupendous and cosmogonal philosophy of the Bhagavad-Gita, in comparison with which our modern world and its literature seem puny and trivial.'
    ],
    favoriteShlokas: ['4,38'],
  ),

  const AuthorProfile(
    author: 'Aldous Huxley',
    domain: 'Writer & Philosopher',
    emblemAsset: 'assets/emblems/authors/ah.png',
    quotes: [
      'The Bhagavad-Gita is the most systematic statement of spiritual evolution of endowing value to mankind. It is one of the most clear and comprehensive summaries of perennial philosophy ever revealed.'
    ],
    favoriteShlokas: ['3,35', '18,66'],
  ),
  const AuthorProfile(
    author: 'Swami Chinmayananda',
    domain: 'Vedantic Scholar',
    emblemAsset: 'assets/emblems/authors/sc.png',
    quotes: [
      'The Gita is a bouquet of spiritual truths from the Upanishads.',
    ],
    favoriteShlokas: ['2,13', '15,1'],
  ),
  const AuthorProfile(
    author: 'Dr. A.P.J. Abdul Kalam',
    domain: 'Scientist & Former President',
    emblemAsset: 'assets/emblems/authors/apj.png',
    quotes: [
      'The Bhagavad Gita has always been my companion and guide.',
    ],
    favoriteShlokas: ['18,58'],
  ),
  const AuthorProfile(
    author: 'Ratan Tata',
    domain: 'Business Leader',
    emblemAsset: 'assets/emblems/authors/rt.png',
    quotes: [
      'The Gita teaches us detachment from results, which is vital in business.',
    ],
    favoriteShlokas: ['2,47'],
  ),

  const AuthorProfile(
    author: 'Mahatma Gandhi',
    domain: 'Political Leader & Spiritual Thinker',
    emblemAsset: 'assets/emblems/authors/mkg.png',
    quotes: [
      'When doubts haunt me... I turn to Bhagavad-Gita and find a verse to comfort me.',
    ],
    favoriteShlokas: ['9,31'],
  ),

  const AuthorProfile(
    author: 'Swami Dayananda Saraswati',
    domain: 'Vedantic Teacher',
    emblemAsset: 'assets/emblems/authors/ds.png',
    quotes: [
      'The Gita liberates you from confusion and awakens clarity.',
    ],
    favoriteShlokas: ['18,73'],
  ),
  const AuthorProfile(
    author: 'Neem Karoli Baba',
    domain: 'Mystic & Bhakti Saint',
    emblemAsset: 'assets/emblems/authors/nkb.png',
    quotes: [
      'One who studies the Gita regularly is free and happy in this world.',
    ],
    favoriteShlokas: ['9,22', '18,71'],
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
        'https://play.google.com/store/apps/details?id=org.komal.bhagvadgeeta';
    Share.share(
      'Check out this beautiful Bhagavad Gita app!\n\n$appLink',
      subject: 'Bhagavad Gita App',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB), // A light, warm background
      body: Stack(
        children: [
          SimpleGradientBackground(
              startColor: const Color.fromARGB(255, 240, 255, 126)), // Golden-brown for credits
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24), // Adjusted padding after SafeArea
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Hero(
                          tag: 'creditsLotusHero', // A new unique tag
                          child: Image.asset(
                            'assets/images/lotus_gold.png', // A new golden lotus asset
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Credits & Acknowledgements',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.brown.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                _launchUrl(
                                    'https://play.google.com/store/apps/developer?id=Komal+Pandya');
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
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < creditsData.length) {
                        return _CreditCard(item: creditsData[index]);
                      }
                      // Add a header for quotes section
                      if (index == creditsData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 40.0, bottom: 16.0),
                          child: Text(
                            'Words of Wisdom',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.brown.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      final profileIndex = index - creditsData.length - 1;
                      return _AuthorCard(profile: authorProfilesData[profileIndex]);
                    },
                    childCount: creditsData.length + authorProfilesData.length + 1,
                  ),
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
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.black.withOpacity(0.1), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Source: ${item.source}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
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

// A card for displaying quotes
class _AuthorCard extends StatelessWidget {
  final AuthorProfile profile;
  const _AuthorCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const double emblemRadius = 32.0;

    return Padding(
      // Add top padding to make space for the overlapping emblem
      padding: const EdgeInsets.fromLTRB(16, emblemRadius + 8, 16, 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // The main card content
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                // Add padding inside to push content below the emblem
                padding: const EdgeInsets.fromLTRB(16.0, emblemRadius + 16.0, 16.0, 16.0),
                decoration: BoxDecoration(
                  color: Colors.brown.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...profile.quotes.map((quote) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            '"$quote"',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.black.withOpacity(0.8),
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        )),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (profile.favoriteShlokas.isNotEmpty)
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: profile.favoriteShlokas.map((shloka) {
                              return TextButton.icon(
                                icon: Icon(Icons.menu_book, size: 18, color: Colors.brown.shade600),
                                label: Text(
                                  'Shloka $shloka',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.brown.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  context.push('/shloka-list/$shloka');
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  backgroundColor: Colors.brown.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        if (profile.favoriteShlokas.isNotEmpty) const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '— ${profile.author}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.brown.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (profile.domain != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  profile.domain!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.brown.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // The emblem, positioned to sit on top of the card
          Positioned(
            top: -emblemRadius,
            child: CircleAvatar(
              radius: emblemRadius + 2, // Border
              backgroundColor: const Color(0xFFFDFCFB).withOpacity(0.9),
              child: CircleAvatar(
                radius: emblemRadius,
                backgroundImage: profile.emblemAsset != null ? AssetImage(profile.emblemAsset!) : null,
                backgroundColor: Colors.grey.shade200,
                child: profile.emblemAsset == null ? const Icon(Icons.person, size: 40, color: Colors.grey) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
