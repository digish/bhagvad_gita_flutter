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

  static const List<SoulStatus> allMilestones = [
    SoulStatus(
      title: 'Sacred Spark',
      description: 'Your journey has begun. A tiny flame of curiosity is lit.',
      icon: Icons.auto_awesome_outlined,
      color: Colors.white24,
      threshold: 0,
    ),
    SoulStatus(
      title: 'Seeking Soul',
      description: 'Three days of dedication! You are now a true Seeker.',
      icon: Icons.explore,
      color: Colors.grey,
      threshold: 3,
      imageAssetName: 'seeking_soul.png',
    ),
    SoulStatus(
      title: 'Awakening Soul',
      description: 'One full week! Your soul is waking up to divine wisdom.',
      icon: Icons.wb_incandescent_outlined,
      color: Colors.blueAccent,
      threshold: 7,
      imageAssetName: 'awakening_soul.png',
    ),
    SoulStatus(
      title: 'Steady Soul',
      description: 'Two weeks of consistency. You are building inner strength.',
      icon: Icons.self_improvement,
      color: Colors.cyan,
      threshold: 14,
      imageAssetName: 'steady_soul.png',
    ),
    SoulStatus(
      title: 'Faithful Follower',
      description:
          '21 days of focus—a habit is born! You are walking the path.',
      icon: Icons.volunteer_activism,
      color: Colors.green,
      threshold: 21,
      imageAssetName: 'faithful_follower.png',
    ),
    SoulStatus(
      title: 'Devoted Disciple',
      description: 'One month of evolution. Your devotion shines bright.',
      icon: Icons.favorite,
      color: Colors.teal,
      threshold: 30,
      imageAssetName: 'devoted_disciple.png',
    ),
    SoulStatus(
      title: 'Radiant Student',
      description: '50 days of light! You are glowing with Gita wisdom.',
      icon: Icons.school,
      color: Colors.amber,
      threshold: 50,
      imageAssetName: 'radiant_student.png',
    ),
    SoulStatus(
      title: 'Resilient Seeker',
      description: '75 days of peace. Maya cannot disturb your focus.',
      icon: Icons.shield,
      color: Colors.orange,
      threshold: 75,
      imageAssetName: 'resilient_seeker.png',
    ),
    SoulStatus(
      title: 'Wise Soul',
      description: '100 days of wisdom. Your heart understands the dharma.',
      icon: Icons.psychology,
      color: Colors.deepOrange,
      threshold: 100,
      imageAssetName: 'wise_soul.png',
    ),
    SoulStatus(
      title: 'Tranquil Heart',
      description: '150 days of stillness. You have found the spring within.',
      icon: Icons.spa,
      color: Colors.indigo,
      threshold: 150,
      imageAssetName: 'tranquil_heart.png',
    ),
    SoulStatus(
      title: 'Divine Instrument',
      description: '200 days! You are a vessel for timeless truths.',
      icon: Icons.music_note,
      color: Colors.purple,
      threshold: 200,
      imageAssetName: 'divine_instrument.png',
    ),
    SoulStatus(
      title: 'Evolved Essence',
      description: '300 days of evolution. Your essence is pure and light.',
      icon: Icons.auto_awesome,
      color: Colors.deepPurple,
      threshold: 300,
      imageAssetName: 'evolved_essence.png',
    ),
    SoulStatus(
      title: 'Master of Self',
      description: 'Approaching one year. You have mastered your inner world.',
      icon: Icons.verified_user,
      color: Colors.pink,
      threshold: 330,
      imageAssetName: 'master_of_self.png',
    ),
    SoulStatus(
      title: 'Paramahansa',
      description: 'A full year of evolution! Divine light, absolute Zen.',
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
      return 'Maya blinked, and a day was missed. But don\'t worry—the wisdom you\'ve gained is yours forever. Krishna is walking with you again.';
    } else if (prevStreak >= 7) {
      return 'A brief pause in the journey. Come back to the light, your soul misses the shlokas! Every moment is a new awakening.';
    } else {
      return 'The path is still right here. Take a breath and start again; your spiritual evolution is a marathon, not a sprint.';
    }
  }
}
