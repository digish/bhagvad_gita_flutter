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
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/settings_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../widgets/simple_gradient_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const SimpleGradientBackground(startColor: Colors.white),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (MediaQuery.of(context).size.width <= 600)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.3),
                            child: BackButton(
                              color: Colors.white,
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/');
                                }
                              },
                            ),
                          ),
                        ),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<SettingsProvider>(
                    builder: (context, settings, child) {
                      return ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: [
                          // --- Language Section ---
                          _buildSectionHeader('Language'),
                          Card(
                            color: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.abc,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Script (Lipi)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'For Shloka & Anvay',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: settings.script,
                                    underline: const SizedBox(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        settings.setScript(newValue);
                                      }
                                    },
                                    items: SettingsProvider
                                        .supportedScripts
                                        .entries
                                        .map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(
                                              entry.value,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16), // Spacing between cards
                          // --- Translation Language Card (No Header) ---
                          Card(
                            color: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.translate,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Meaning (Bhavarth)',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          settings.language == 'en'
                                              ? 'In English'
                                              : 'In Hindi (follows Lipi)',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: settings.language,
                                    underline: const SizedBox(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        settings.setLanguage(newValue);
                                      }
                                    },
                                    items: SettingsProvider
                                        .supportedLanguages
                                        .entries
                                        .map((entry) {
                                          return DropdownMenuItem<String>(
                                            value: entry.key,
                                            child: Text(entry.value),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- Content Section ---
                          _buildSectionHeader('Content'),
                          Card(
                            color: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: SwitchListTile(
                              secondary: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.history_edu,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              title: const Text(
                                'Classical Commentaries',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Show Big Three (Shankaracharya, Ramanujacharya, Madhvacharya)',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                              value: settings.showClassicalCommentaries,
                              onChanged: (bool value) {
                                settings.setShowClassicalCommentaries(value);
                              },
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // --- Daily Inspiration Section ---
                          _buildSectionHeader('Daily Inspiration'),
                          Card(
                            color: Colors.white.withOpacity(0.9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            child: Column(
                              children: [
                                SwitchListTile(
                                  secondary: CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  title: const Text(
                                    'Gita Wisdom',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Show a random shloka on the search screen.',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                  value: settings.showRandomShloka,
                                  onChanged: (bool value) {
                                    settings.setShowRandomShloka(value);
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                                if (settings.showRandomShloka) ...[
                                  const Divider(height: 1, indent: 72),
                                  Consumer<SettingsProvider>(
                                    builder: (context, settings, _) {
                                      // Multi-selection UI
                                      final selectedSources =
                                          settings.randomShlokaSources;
                                      String subtitleText;
                                      if (selectedSources.contains(-1)) {
                                        subtitleText = 'Entire Gita';
                                      } else if (selectedSources.isEmpty) {
                                        subtitleText = 'No sources selected';
                                      } else {
                                        subtitleText =
                                            '${selectedSources.length} source(s) selected';
                                      }

                                      return ListTile(
                                        leading: const SizedBox(
                                          width: 40,
                                          height: 40,
                                        ), // Spacer for alignment
                                        title: const Text(
                                          'Source',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          subtitleText,
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_drop_down,
                                        ), // mimic dropdown
                                        onTap: () {
                                          _showSourceSelectionDialog(context);
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // --- Preferences Section ---
                          _buildSectionHeader('Preferences'),
                          _buildSettingCard(
                            context,
                            title: 'Simple Theme',
                            subtitle:
                                'Enable a cleaner look by removing background illustrations.',
                            value: !settings.showBackground,
                            onChanged: (value) {
                              settings.setShowBackground(!value);
                            },
                            icon: Icons.format_paint_outlined,
                          ),

                          const SizedBox(height: 32),

                          // --- Support Section ---
                          _buildSectionHeader('Support'),
                          _buildActionTile(
                            context,
                            title: 'Send Feedback',
                            subtitle:
                                'Have a suggestion or found a bug? Let us know!',
                            icon: Icons.mail_outline,
                            onTap: (innerContext) async {
                              final Uri emailLaunchUri = Uri(
                                scheme: 'mailto',
                                path: 'digish.pandya@gmail.com',
                                query: 'subject=Feedback for Bhagavad Gita App',
                              );
                              if (!await launchUrl(emailLaunchUri)) {
                                debugPrint('Could not launch email');
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildActionTile(
                            context,
                            title: 'Share App',
                            subtitle:
                                'Share the wisdom with your friends and family.',
                            icon: Icons.share_outlined,
                            onTap: (innerContext) {
                              final box =
                                  innerContext.findRenderObject() as RenderBox?;
                              Share.share(
                                'Check out this Shrimad Bhagavad Gita app:\nhttps://play.google.com/store/apps/details?id=org.komal.bhagvadgeeta',
                                sharePositionOrigin: box != null
                                    ? box.localToGlobal(Offset.zero) & box.size
                                    : null,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildActionTile(
                            context,
                            title: 'More Apps',
                            subtitle: 'Explore other apps by the developer.',
                            icon: Icons.apps,
                            onTap: (innerContext) async {
                              final Uri developerPageUri = Uri.parse(
                                'https://digish.github.io/project/',
                              );
                              if (!await launchUrl(
                                developerPageUri,
                                mode: LaunchMode.externalApplication,
                              )) {
                                debugPrint('Could not launch developer page');
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: SwitchListTile(
        secondary: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required void Function(BuildContext) onTap,
  }) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Builder(
        builder: (innerContext) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Icon(icon, color: Theme.of(context).primaryColor),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            onTap: () => onTap(innerContext),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Changed from Colors.white
            ),
          ),
          const SizedBox(height: 4),
          const Divider(
            color: Colors.black12,
            thickness: 1,
          ), // Changed from Colors.white24
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showSourceSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Sources'),
          content: SizedBox(
            width: double.maxFinite,
            child: Consumer2<SettingsProvider, BookmarkProvider>(
              builder: (context, settings, bookmarks, child) {
                final seenIds = <int>{};
                final selectedSources = settings.randomShlokaSources;

                return ListView(
                  shrinkWrap: true,
                  children: [
                    // 1. Entire Gita Option
                    CheckboxListTile(
                      title: const Text('Entire Gita'),
                      value: selectedSources.contains(-1),
                      onChanged: (bool? value) {
                        settings.toggleRandomShlokaSource(-1);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                    const Divider(),

                    // 2. User Lists
                    if (bookmarks.lists.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Text(
                          'MY COLLECTIONS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...bookmarks.lists.map((list) {
                        if (seenIds.contains(list.id)) {
                          return const SizedBox.shrink();
                        }
                        seenIds.add(list.id);
                        return CheckboxListTile(
                          title: Text(list.name),
                          value: selectedSources.contains(list.id),
                          onChanged: (bool? value) {
                            settings.toggleRandomShlokaSource(list.id);
                          },
                          activeColor: Theme.of(context).primaryColor,
                        );
                      }),
                    ],

                    // 3. Curated Lists
                    if (bookmarks.predefinedLists.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 16.0,
                        ),
                        child: Text(
                          'CURATED LISTS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      ...bookmarks.predefinedLists.map((list) {
                        if (seenIds.contains(list.id)) {
                          return const SizedBox.shrink();
                        }
                        seenIds.add(list.id);
                        return CheckboxListTile(
                          title: Text(list.name),
                          value: selectedSources.contains(list.id),
                          onChanged: (bool? value) {
                            settings.toggleRandomShlokaSource(list.id);
                          },
                          activeColor: Theme.of(context).primaryColor,
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }
}
