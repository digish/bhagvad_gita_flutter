/*
*  © 2025 Digish Pandya. All rights reserved.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/settings_provider.dart';
import '../../services/notification_service.dart';

/// Soft pitch for Daily Wisdom Reminder after the 2nd visit to a key screen.
class ReminderPitch {
  ReminderPitch._();

  /// Call from Parayan, Settings, or chapter shloka list after first frame.
  /// Pass [blocked] true when another modal/coach is visible — visit still counts.
  static Future<void> maybeShow(
    BuildContext context, {
    bool blocked = false,
  }) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    if (!settings.isInitialized) return;
    if (settings.reminderEnabled || settings.reminderNudgeDismissed) return;

    await settings.noteFeatureScreenVisit();
    if (!context.mounted) return;
    if (blocked || !settings.shouldOfferReminderPitch) return;

    final enabled = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: Colors.orange),
              SizedBox(width: 12),
              Flexible(child: Text('Daily reminder?')),
            ],
          ),
          content: const Text(
            'A gentle daily nudge helps you keep your reading streak and return to a verse each day.\n\n'
            'You can change the time anytime in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Not now'),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await settings.setReminderEnabled(true);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, success);
                if (!success && context.mounted) {
                  _showPermissionBlockedDialog(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Turn on'),
            ),
          ],
        );
      },
    );

    // Not now, barrier dismiss, or failed enable → don't ask again via this pitch.
    if (enabled != true && context.mounted) {
      final latest = Provider.of<SettingsProvider>(context, listen: false);
      if (!latest.reminderEnabled) {
        await latest.dismissReminderNudge();
      }
    }
  }

  static void _showPermissionBlockedDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
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
          content: const Text(
            'Notifications are disabled for this app. Enable them in system settings to receive daily wisdom reminders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
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
}
