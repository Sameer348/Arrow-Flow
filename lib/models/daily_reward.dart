import 'package:flutter/material.dart';

import 'booster.dart';

/// One step of the 7-day login reward cycle.
class DailyReward {
  const DailyReward({
    required this.day,
    required this.label,
    required this.icon,
    this.coins = 0,
    this.boosters = const {},
    this.skinId,
    this.premium = false,
  });

  final int day;
  final String label;
  final IconData icon;
  final int coins;
  final Map<Booster, int> boosters;

  /// Rare skin granted (coins instead if already owned).
  final String? skinId;
  final bool premium;

  static const cycle = <DailyReward>[
    DailyReward(day: 1, label: '50 Coins', icon: Icons.monetization_on_rounded, coins: 50),
    DailyReward(day: 2, label: '80 Coins', icon: Icons.monetization_on_rounded, coins: 80),
    DailyReward(day: 3, label: '2 Hints', icon: Icons.lightbulb_rounded, boosters: {Booster.hint: 2}),
    DailyReward(day: 4, label: '120 Coins', icon: Icons.savings_rounded, coins: 120),
    DailyReward(day: 5, label: 'Crystal Skin', icon: Icons.diamond_rounded, skinId: 'crystal'),
    DailyReward(day: 6, label: 'Booster Pack', icon: Icons.inventory_2_rounded,
        boosters: {Booster.undo: 2, Booster.hammer: 1, Booster.shuffle: 1}),
    DailyReward(day: 7, label: 'Grand Prize', icon: Icons.workspace_premium_rounded, premium: true,
        coins: 300, boosters: {Booster.hint: 3, Booster.hammer: 2}),
  ];

  static const skinFallbackCoins = 250;
}
