import 'dart:math' as math;

import '../../models/arrow_data.dart';
import '../../models/level_data.dart';

/// Pure scoring / star / coin rules (spec §38–41). Kept free of state so it
/// is trivially testable.
abstract final class Scoring {
  static const comboWindowSeconds = 5.0;

  /// Combo multiplier: 3 → x2, 5 → x3, 10 → x5.
  static int comboMultiplier(int combo) {
    if (combo >= 10) return 5;
    if (combo >= 5) return 3;
    if (combo >= 3) return 2;
    return 1;
  }

  static int arrowPoints(ArrowData a, int multiplier) {
    final base = 50 + 25 * (a.length - 1);
    final bonus = a.type == ArrowType.bonus ? 2 : 1;
    return base * bonus * multiplier;
  }

  static int speedBonus(int seconds, int parSeconds) => math.max(0, parSeconds - seconds) * 10;

  static int efficiencyBonus(int mistakes, int arrowCount) =>
      math.max(0, arrowCount * 20 - mistakes * 40);

  static int perfectBonus(int mistakes) => mistakes == 0 ? 500 : 0;

  static int stars(LevelData level, {required int mistakes, bool usedHammer = false}) {
    final req = level.starRequirements;
    var s = mistakes <= req.maxMistakesForThree
        ? 3
        : mistakes <= req.maxMistakesForTwo
            ? 2
            : 1;
    if (usedHammer && s == 3) s = 2;
    return s;
  }

  /// Coins earned for a finished level. [firstClear] pays the full amount;
  /// replays pay a fraction so grinding stays fair.
  static int coins({required int stars, required bool perfect, bool firstClear = true, bool daily = false}) {
    var c = 10 + stars * 5 + (perfect ? 10 : 0);
    if (daily) c += 50;
    if (!firstClear) c = (c / 3).ceil();
    return c;
  }
}
