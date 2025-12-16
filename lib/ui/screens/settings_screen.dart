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
                              onPressed: () => context.pop(),
                            ),
                          ),
                        ),
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
                          const SizedBox(height: 16),
                          _buildSettingCard(
                            context,
                            title: 'Share Audio with Shloka',
                            subtitle:
                                'Include the audio file when sharing a shloka.',
                            value: settings.shareWithAudio,
                            onChanged: (value) {
                              settings.setShareWithAudio(value);
                            },
                            icon: Icons.audiotrack,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white24, thickness: 1),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
