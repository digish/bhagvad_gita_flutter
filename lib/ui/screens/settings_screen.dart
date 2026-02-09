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
import '../../services/ad_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/credit_provider.dart';
import '../../services/notification_service.dart';
import '../widgets/simple_gradient_background.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Only show gradient in light mode or if specific flag is set, otherwise plain background from Scaffold
          if (Theme.of(context).brightness == Brightness.light)
            const SimpleGradientBackground(startColor: Colors.white),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
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
                                  color: Theme.of(context).iconTheme.color,
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
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
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
                                color: Theme.of(context).cardTheme.color,
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
                                        flex: 2,
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
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 2,
                                        child: DropdownButton<String>(
                                          value: settings.script,
                                          underline: const SizedBox(),
                                          isExpanded: true,
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
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 16,
                              ), // Spacing between cards
                              // --- Translation Language Card (No Header) ---
                              Card(
                                color: Theme.of(context).cardTheme.color,
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
                                        flex: 2,
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
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 2,
                                        child: DropdownButton<String>(
                                          value: settings.language,
                                          underline: const SizedBox(),
                                          isExpanded: true,
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
                                                  child: Text(
                                                    entry.value,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.bodyMedium,
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // --- Daily Journey Section ---
                              _buildSectionHeader('Daily Journey'),
                              // 1. Gita Wisdom (Daily Inspiration)
                              Card(
                                color: Theme.of(context).cardTheme.color,
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
                                        'Daily Gita Wisdom',
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
                                      activeColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                    ),
                                    if (settings.showRandomShloka) ...[
                                      const Divider(height: 1, indent: 72),
                                      Consumer<SettingsProvider>(
                                        builder: (context, settings, _) {
                                          final selectedSources =
                                              settings.randomShlokaSources;
                                          String subtitleText;
                                          if (selectedSources.contains(-1)) {
                                            subtitleText = 'Entire Gita';
                                          } else if (selectedSources.isEmpty) {
                                            subtitleText =
                                                'No sources selected';
                                          } else {
                                            subtitleText =
                                                '${selectedSources.length} source(s) selected';
                                          }

                                          return ListTile(
                                            leading: const SizedBox(
                                              width: 40,
                                              height: 40,
                                            ),
                                            title: const Text(
                                              'Source for Inspiration',
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
                                            ),
                                            onTap: () {
                                              _showSourceSelectionDialog(
                                                context,
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                    const Divider(height: 1, indent: 72),
                                    ListTile(
                                      leading: const SizedBox(
                                        width: 40,
                                        height: 40,
                                      ),
                                      title: const Text(
                                        'Home Screen Widget',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Show daily shlokas on your home screen.',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.help_outline,
                                        size: 20,
                                      ),
                                      onTap: () {
                                        _showWidgetInstructionsDialog(context);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Daily Wisdom Reminder
                              Card(
                                color: Theme.of(context).cardTheme.color,
                                elevation: 4,
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      secondary: CircleAvatar(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                        child: Icon(
                                          Icons.notifications_active_outlined,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      title: const Text(
                                        'Daily Wisdom Reminder',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Get a nudge at your preferred time.',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: settings.reminderEnabled,
                                      onChanged: (bool value) async {
                                        final success = await settings
                                            .setReminderEnabled(value);
                                        if (!success && value) {
                                          if (context.mounted) {
                                            _showNotificationPermissionDialog(
                                              context,
                                            );
                                          }
                                        }
                                      },
                                      activeColor: Theme.of(
                                        context,
                                      ).primaryColor,
                                    ),
                                    if (settings.reminderEnabled) ...[
                                      const Divider(height: 1, indent: 72),
                                      ListTile(
                                        leading: const SizedBox(
                                          width: 40,
                                          height: 40,
                                        ),
                                        title: const Text(
                                          'Reminder Time',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          settings.reminderTime.format(context),
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                          ),
                                        ),
                                        trailing: const Icon(Icons.access_time),
                                        onTap: () async {
                                          final TimeOfDay? picked =
                                              await showTimePicker(
                                                context: context,
                                                initialTime:
                                                    settings.reminderTime,
                                              );
                                          if (picked != null) {
                                            settings.setReminderTime(picked);
                                          }
                                        },
                                      ),
                                    ],
                                    // 🧪 DEBUG: Test notification buttons
                                    if (kDebugMode &&
                                        settings.reminderEnabled) ...[
                                      const Divider(height: 1, indent: 72),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 72,
                                          right: 16,
                                          top: 12,
                                          bottom: 12,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Test Notifications (Debug)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      await NotificationService
                                                          .instance
                                                          .showTestNotificationAfterDelay();
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Notification in 5 sec! Background the app now! 🔔',
                                                            ),
                                                            duration: Duration(
                                                              seconds: 4,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.timer,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      'In 5 Sec',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.orange,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      await NotificationService
                                                          .instance
                                                          .scheduleTestNotificationInOneMinute();
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Notification scheduled for 1 min! ⏰',
                                                            ),
                                                            duration: Duration(
                                                              seconds: 2,
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.schedule,
                                                      size: 16,
                                                    ),
                                                    label: const Text(
                                                      'In 1 Min',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.deepOrange,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 3. Consistency Roadmap
                              _buildSettingCard(
                                context,
                                title: 'Consistency Roadmap',
                                subtitle:
                                    'Visualize your daily progress, earn milestones, and use lifelines to maintain consistency.',
                                value: settings.streakSystemEnabled,
                                onChanged: (value) {
                                  settings.setStreakSystemEnabled(value);
                                },
                                icon: Icons.auto_awesome_rounded,
                              ),
                              const SizedBox(height: 32),

                              // --- Content Section ---
                              _buildSectionHeader('Content'),
                              Card(
                                color: Theme.of(context).cardTheme.color,
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
                                    settings.setShowClassicalCommentaries(
                                      value,
                                    );
                                  },
                                  activeColor: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // --- Preferences Section ---
                              _buildSectionHeader('Preferences'),
                              Card(
                                color: Theme.of(context).cardTheme.color,
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
                                          Icons.brightness_6,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'App Theme',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Light, Dark, or System',
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        flex: 2,
                                        child: DropdownButton<ThemeMode>(
                                          value: settings.themeMode,
                                          underline: const SizedBox(),
                                          isExpanded: true,
                                          onChanged: (ThemeMode? newValue) {
                                            if (newValue != null) {
                                              settings.setThemeMode(newValue);
                                            }
                                          },
                                          items: const [
                                            DropdownMenuItem(
                                              value: ThemeMode.system,
                                              child: Text('System'),
                                            ),
                                            DropdownMenuItem(
                                              value: ThemeMode.light,
                                              child: Text('Light'),
                                            ),
                                            DropdownMenuItem(
                                              value: ThemeMode.dark,
                                              child: Text('Dark'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
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

                              // --- AI Settings Section ---
                              _buildSectionHeader('AI credits for Ask GITA'),
                              Card(
                                color: Theme.of(context).cardTheme.color,
                                elevation: 4,
                                clipBehavior: Clip.antiAlias,
                                child: Consumer<CreditProvider>(
                                  builder: (context, credits, _) {
                                    final hasCustomKey =
                                        settings.customAiApiKey != null;

                                    return Column(
                                      children: [
                                        // 1. Credit Balance / Status Card
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: hasCustomKey
                                                  ? [
                                                      Colors.purple.shade700,
                                                      Colors
                                                          .deepPurple
                                                          .shade900,
                                                    ]
                                                  : [
                                                      const Color(0xFFFFB75E),
                                                      const Color(0xFFED8F03),
                                                    ], // Gold gradient
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                hasCustomKey
                                                    ? Icons.all_inclusive
                                                    : Icons.auto_awesome,
                                                size: 48,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                hasCustomKey
                                                    ? 'Unlimited Access'
                                                    : '${credits.balance}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                hasCustomKey
                                                    ? 'Using Personal Key'
                                                    : 'Divine Credits Available',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 2. Actions (If no custom key)
                                        if (!hasCustomKey) ...[
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              16,
                                              24,
                                              16,
                                              16,
                                            ),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 54,
                                                  child: FilledButton.icon(
                                                    onPressed: () {
                                                      AdService.instance.showRewardedAd(
                                                        onRewardEarned: (reward) {
                                                          context
                                                              .read<
                                                                CreditProvider
                                                              >()
                                                              .addCredits(3);
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Karma earned! +3 Credits added. 🙏',
                                                              ),
                                                              behavior:
                                                                  SnackBarBehavior
                                                                      .floating,
                                                            ),
                                                          );
                                                        },
                                                        onAdFailedToShow: () {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                'Ad not ready yet. Please try again.',
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.amber[800],
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation: 2,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons
                                                          .play_circle_filled_rounded,
                                                    ),
                                                    label: Text(
                                                      'Watch Ad to add ${CreditProvider.adRewardAmount} Credits',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'it helps supports cloud costs for using AI',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        // 3. Custom Key Option (Always visible but subtle)
                                        const Divider(height: 1),
                                        ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 4,
                                              ),
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.grey[100],
                                            radius: 16,
                                            child: Icon(
                                              Icons.key,
                                              size: 16,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          title: const Text(
                                            'Custom Gemini Key',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          subtitle: Text(
                                            hasCustomKey
                                                ? 'Tap to edit or remove'
                                                : 'Use your own key',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                            size: 20,
                                            color: Colors.grey,
                                          ),
                                          onTap: () => _showApiKeyDialog(
                                            context,
                                            settings,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 8.0,
                                  left: 4.0,
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    final url = Uri.parse(
                                      'https://aistudio.google.com/app/apikey',
                                    );
                                    if (!await launchUrl(
                                      url,
                                      mode: LaunchMode.externalApplication,
                                    )) {
                                      debugPrint('Could not launch AI Studio');
                                    }
                                  },
                                  child: const Text(
                                    'Get your own free key from Google AI Studio',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
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
                                    query:
                                        'subject=Feedback for Bhagavad Gita App',
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
                                      innerContext.findRenderObject()
                                          as RenderBox?;
                                  Share.share(
                                    'Check out this Shrimad Bhagavad Gita app:\nhttps://digish.github.io/project/index.html#bhagvadgita',
                                    sharePositionOrigin: box != null
                                        ? box.localToGlobal(Offset.zero) &
                                              box.size
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              _buildActionTile(
                                context,
                                title: 'More Apps',
                                subtitle:
                                    'Explore other apps by the developer.',
                                icon: Icons.apps,
                                onTap: (innerContext) async {
                                  final Uri developerPageUri = Uri.parse(
                                    'https://digish.github.io/project/',
                                  );
                                  if (!await launchUrl(
                                    developerPageUri,
                                    mode: LaunchMode.externalApplication,
                                  )) {
                                    debugPrint(
                                      'Could not launch developer page',
                                    );
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
      color: Theme.of(context).cardTheme.color,
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
      color: Theme.of(context).cardTheme.color,
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
              // color: Colors.black87, // Removed hardcoded color
            ),
          ),
          const SizedBox(height: 4),
          const Divider(thickness: 1),
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

  void _showApiKeyDialog(BuildContext context, SettingsProvider settings) {
    final controller = TextEditingController(
      text: settings.customAiApiKey ?? '',
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom Gemini API Key'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter your personal Gemini API key. This will be stored only on your device and used instead of the app\'s default key.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Gemini API Key',
                    border: OutlineInputBorder(),
                    hintText: 'AIzaSy...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (settings.customAiApiKey != null)
              TextButton(
                onPressed: () {
                  settings.clearCustomAiApiKey();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Clear Key',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final key = controller.text.trim();
                if (key.isNotEmpty) {
                  settings.setCustomAiApiKey(key);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_off_outlined, color: Colors.orange),
              SizedBox(width: 12),
              Flexible(child: Text('Notifications Blocked')),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'It seems notifications are disabled for this app. We need them to send you daily wisdom reminders.',
                ),
                SizedBox(height: 16),
                Text(
                  'Please enable them in your system settings to maintain your spiritual streak!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                NotificationService.instance.openNotificationSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  void _showWidgetInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.widgets, color: Colors.amber),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Home Screen Widget',
                style: TextStyle(fontSize: 18), // Slightly smaller if needed
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a widget to your home screen to see a new Shloka every day without opening the app.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              _buildInstructionStep(
                '1',
                'On Home Screen, long press any empty area.',
              ),
              _buildInstructionStep('2', 'Tap the (+) or "Widgets" button.'),
              _buildInstructionStep(
                '3',
                'Search for "Gita" and add the widget!',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Perfect for your morning commute or a quick moment of peace.',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.amber.withOpacity(0.2),
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
