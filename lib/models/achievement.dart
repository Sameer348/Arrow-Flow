import 'package:flutter/material.dart';

import 'player_progress.dart';

/// Static definition of an achievement. [progress] returns (current, goal).
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.reward,
    required this.progress,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int reward;
  final (int, int) Function(PlayerProgress p) progress;

  bool isMet(PlayerProgress p) {
    final (cur, goal) = progress(p);
    return cur >= goal;
  }

  static final all = <Achievement>[
    Achievement(id: 'first_escape', title: 'First Escape', description: 'Clear your first arrow.',
        icon: Icons.north_east_rounded, reward: 20, progress: (p) => (p.stats.arrowsCleared, 1)),
    Achievement(id: 'puzzle_starter', title: 'Puzzle Starter', description: 'Complete your first level.',
        icon: Icons.flag_rounded, reward: 30, progress: (p) => (p.stats.levelsCompleted, 1)),
    Achievement(id: 'levels_10', title: '10 Levels', description: 'Complete 10 levels.',
        icon: Icons.looks_one_rounded, reward: 60, progress: (p) => (p.stats.levelsCompleted, 10)),
    Achievement(id: 'levels_50', title: '50 Levels', description: 'Complete 50 levels.',
        icon: Icons.military_tech_rounded, reward: 150, progress: (p) => (p.stats.levelsCompleted, 50)),
    Achievement(id: 'levels_100', title: '100 Levels', description: 'Complete 100 levels.',
        icon: Icons.workspace_premium_rounded, reward: 300, progress: (p) => (p.stats.levelsCompleted, 100)),
    Achievement(id: 'arrows_500', title: '500 Arrows', description: 'Clear 500 arrows.',
        icon: Icons.trending_up_rounded, reward: 100, progress: (p) => (p.stats.arrowsCleared, 500)),
    Achievement(id: 'arrows_1000', title: '1000 Arrows', description: 'Clear 1,000 arrows.',
        icon: Icons.rocket_launch_rounded, reward: 200, progress: (p) => (p.stats.arrowsCleared, 1000)),
    Achievement(id: 'perfect_solver', title: 'Perfect Solver', description: 'Finish 10 levels without a mistake.',
        icon: Icons.verified_rounded, reward: 150, progress: (p) => (p.stats.perfectLevels, 10)),
    Achievement(id: 'no_mistakes', title: 'No Mistakes', description: 'Finish a level without a single wrong tap.',
        icon: Icons.check_circle_rounded, reward: 40, progress: (p) => (p.stats.perfectLevels, 1)),
    Achievement(id: 'speed_solver', title: 'Speed Solver', description: 'Clear a level in under 10 seconds.',
        icon: Icons.bolt_rounded, reward: 80,
        progress: (p) => (p.stats.fastestSeconds > 0 && p.stats.fastestSeconds < 10 ? 1 : 0, 1)),
    Achievement(id: 'combo_master', title: 'Combo Master', description: 'Reach a x10 combo.',
        icon: Icons.whatshot_rounded, reward: 120, progress: (p) => (p.stats.bestCombo, 10)),
    Achievement(id: 'daily_streak', title: 'Daily Streak', description: 'Play the daily challenge 7 days in a row.',
        icon: Icons.calendar_month_rounded, reward: 250, progress: (p) => (p.stats.dailyStreak, 7)),
    Achievement(id: 'puzzle_master', title: 'Puzzle Master', description: 'Collect 300 stars.',
        icon: Icons.auto_awesome_rounded, reward: 500, progress: (p) => (p.totalStars, 300)),
  ];
}
