import 'package:flutter/material.dart';

/// Game modes. Add a value + rules in [GameRules] to introduce a new mode.
enum GameMode {
  classic('Classic', 'Clear the board at your own pace.', Icons.grid_view_rounded),
  timed('Timed', 'Beat the clock.', Icons.timer_rounded),
  limitedMoves('Limited Moves', 'Every tap counts.', Icons.touch_app_rounded),
  perfect('Perfect', 'One wrong tap and it\'s over.', Icons.verified_rounded),
  endless('Endless', 'Infinite generated puzzles.', Icons.all_inclusive_rounded),
  daily('Daily Challenge', 'One puzzle a day, same for everyone.', Icons.today_rounded),
  tower('Tower 2.5D', 'Rotate the board and clear stacked layers.', Icons.view_in_ar_rounded);

  const GameMode(this.label, this.tagline, this.icon);
  final String label;
  final String tagline;
  final IconData icon;

  bool get hasTimer => this == GameMode.timed || this == GameMode.daily;
  bool get hasMoveLimit => this == GameMode.limitedMoves;
  bool get failsOnMistake => this == GameMode.perfect;

  /// Whether the board hints which arrows are free (disabled in Perfect).
  bool get allowsFreeHighlight => this != GameMode.perfect;

  /// Modes reached from the level map advance campaign progress.
  bool get isCampaign => this == GameMode.classic;
}
