import 'package:flutter/material.dart';

class SoulStatus {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int threshold;
  final String? imageAssetName;

  const SoulStatus({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.threshold,
    this.imageAssetName,
  });

  /// Warm gold used for the day-1 spark icon and ring.
  static const Color sparkGold = Color(0xFFFFD54F);

  static const List<SoulStatus> allMilestones = [
    SoulStatus(
      title: 'First Spark',
      description: 'Your daily reading habit begins here.',
      icon: Icons.flare,
      color: sparkGold,
      threshold: 0,
    ),
    SoulStatus(
      title: 'Warming Up',
      description: 'Three days in. Keep showing up.',
      icon: Icons.explore,
      color: Colors.grey,
      threshold: 3,
      imageAssetName: 'seeking_soul.png',
    ),
    SoulStatus(
      title: 'In Rhythm',
      description: 'A full week of returning to the text.',
      icon: Icons.wb_incandescent_outlined,
      color: Colors.blueAccent,
      threshold: 7,
      imageAssetName: 'awakening_soul.png',
    ),
    SoulStatus(
      title: 'Steady Habit',
      description: 'Two weeks of consistent practice.',
      icon: Icons.self_improvement,
      color: Colors.cyan,
      threshold: 14,
      imageAssetName: 'steady_soul.png',
    ),
    SoulStatus(
      title: 'Habit Formed',
      description: 'Twenty-one days—your rhythm is settling in.',
      icon: Icons.volunteer_activism,
      color: Colors.green,
      threshold: 21,
      imageAssetName: 'faithful_follower.png',
    ),
    SoulStatus(
      title: 'One Month In',
      description: 'A month of daily practice.',
      icon: Icons.favorite,
      color: Colors.teal,
      threshold: 30,
      imageAssetName: 'devoted_disciple.png',
    ),
    SoulStatus(
      title: 'Deepening',
      description: 'Fifty days of returning to the Gita.',
      icon: Icons.school,
      color: Colors.amber,
      threshold: 50,
      imageAssetName: 'radiant_student.png',
    ),
    SoulStatus(
      title: 'Anchored',
      description: 'Seventy-five days of steady attention.',
      icon: Icons.shield,
      color: Colors.orange,
      threshold: 75,
      imageAssetName: 'resilient_seeker.png',
    ),
    SoulStatus(
      title: 'Century Mark',
      description: 'One hundred days of practice.',
      icon: Icons.psychology,
      color: Colors.deepOrange,
      threshold: 100,
      imageAssetName: 'wise_soul.png',
    ),
    SoulStatus(
      title: 'Quiet Consistency',
      description: 'One hundred fifty days, still showing up.',
      icon: Icons.spa,
      color: Colors.indigo,
      threshold: 150,
      imageAssetName: 'tranquil_heart.png',
    ),
    SoulStatus(
      title: 'Long Commitment',
      description: 'Two hundred days of daily return.',
      icon: Icons.music_note,
      color: Colors.purple,
      threshold: 200,
      imageAssetName: 'divine_instrument.png',
    ),
    SoulStatus(
      title: 'Near a Year',
      description: 'Three hundred days of daily practice.',
      icon: Icons.auto_awesome,
      color: Colors.deepPurple,
      threshold: 300,
      imageAssetName: 'evolved_essence.png',
    ),
    SoulStatus(
      title: 'Almost There',
      description: 'Approaching a full year of practice.',
      icon: Icons.verified_user,
      color: Colors.pink,
      threshold: 330,
      imageAssetName: 'master_of_self.png',
    ),
    SoulStatus(
      title: 'Full Year',
      description: 'Three hundred sixty-five days of daily practice.',
      icon: Icons.waves,
      color: Colors.amberAccent,
      threshold: 365,
      imageAssetName: 'paramahansa.png',
    ),
  ];

  static SoulStatus getStatus(int streak) {
    SoulStatus current = allMilestones.first;
    for (final milestone in allMilestones) {
      if (streak >= milestone.threshold) {
        current = milestone;
      } else {
        break;
      }
    }
    return current;
  }

  static String getDropMessage(int prevStreak) {
    if (prevStreak >= 30) {
      return 'You missed a day, so your streak reset. Your past progress still counts—start again whenever you\'re ready.';
    } else if (prevStreak >= 7) {
      return 'You missed a day and your streak reset. Come back tomorrow and build it up again.';
    } else {
      return 'Your streak reset after a missed day. No worries—you can start fresh today.';
    }
  }
}
