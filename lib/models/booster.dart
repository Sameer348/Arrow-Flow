import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'game_mode.dart';

enum Booster {
  hint('Hint', 'Reveals a move that frees the most arrows.', Icons.lightbulb_rounded, 60, AppColors.primary),
  undo('Undo', 'Brings back the last arrow you cleared.', Icons.undo_rounded, 40, AppColors.secondary),
  hammer('Hammer', 'Smash any one arrow off the board.', Icons.gavel_rounded, 120, AppColors.warning),
  shuffle('Shuffle', 'Flips arrows around — always still solvable.', Icons.shuffle_rounded, 80, AppColors.violet),
  freeze('Freeze', 'Stops the clock for 10 seconds.', Icons.ac_unit_rounded, 90, Color(0xFF7EE7FF)),
  extraMoves('+5 Moves', 'Adds five moves in Limited Moves mode.', Icons.add_circle_rounded, 70, AppColors.success);

  const Booster(this.label, this.description, this.icon, this.price, this.color);
  final String label;
  final String description;
  final IconData icon;
  final int price;
  final Color color;

  /// Whether this booster does anything in [mode].
  bool usableIn(GameMode mode) => switch (this) {
        Booster.freeze => mode.hasTimer,
        Booster.extraMoves => mode.hasMoveLimit,
        _ => true,
      };

  /// Boosters that need a confirmation dialog because they're expensive.
  bool get needsConfirm => this == Booster.hammer || this == Booster.shuffle;
}
