import 'package:arrow_flow/game/engine/scoring.dart';
import 'package:arrow_flow/models/arrow_data.dart';
import 'package:arrow_flow/models/direction.dart';
import 'package:arrow_flow/models/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final level = LevelData(id: 1, rows: 3, cols: 3, arrows: const [], starRequirements: const StarRequirements(maxMistakesForTwo: 2));

  test('combo multiplier tiers', () {
    expect([0, 1, 2, 3, 4, 5, 9, 10, 30].map(Scoring.comboMultiplier), [1, 1, 1, 2, 2, 3, 3, 5, 5]);
  });

  test('arrow points scale with length, bonus and multiplier', () {
    const short = ArrowData(id: 0, row: 0, column: 0, direction: Direction.up);
    const long = ArrowData(id: 1, row: 2, column: 0, direction: Direction.up, length: 3);
    const bonus = ArrowData(id: 2, row: 0, column: 1, direction: Direction.up, type: ArrowType.bonus);
    expect(Scoring.arrowPoints(short, 1), 50);
    expect(Scoring.arrowPoints(long, 1), 100);
    expect(Scoring.arrowPoints(bonus, 1), 100);
    expect(Scoring.arrowPoints(short, 3), 150);
  });

  test('stars from mistakes', () {
    expect(Scoring.stars(level, mistakes: 0), 3);
    expect(Scoring.stars(level, mistakes: 1), 2);
    expect(Scoring.stars(level, mistakes: 2), 2);
    expect(Scoring.stars(level, mistakes: 3), 1);
    expect(Scoring.stars(level, mistakes: 0, usedHammer: true), 2);
  });

  test('bonuses', () {
    expect(Scoring.speedBonus(10, 30), 200);
    expect(Scoring.speedBonus(40, 30), 0);
    expect(Scoring.efficiencyBonus(0, 10), 200);
    expect(Scoring.efficiencyBonus(10, 2), 0);
    expect(Scoring.perfectBonus(0), 500);
    expect(Scoring.perfectBonus(1), 0);
  });

  test('coins: replays pay less, daily pays more', () {
    final first = Scoring.coins(stars: 3, perfect: true);
    expect(first, 35);
    expect(Scoring.coins(stars: 3, perfect: true, firstClear: false), lessThan(first));
    expect(Scoring.coins(stars: 3, perfect: true, daily: true), first + 50);
  });
}
