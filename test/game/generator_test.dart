import 'package:arrow_flow/core/utils/seeded_random.dart';
import 'package:arrow_flow/game/board/board_state.dart';
import 'package:arrow_flow/game/generator/level_generator.dart';
import 'package:arrow_flow/game/levels/curated_levels.dart';
import 'package:arrow_flow/game/levels/level_catalog.dart';
import 'package:arrow_flow/game/solver/puzzle_solver.dart';
import 'package:arrow_flow/models/board_shape.dart';
import 'package:arrow_flow/models/level_data.dart';
import 'package:flutter_test/flutter_test.dart';

void expectValid(LevelData l) {
  final board = BoardState.fromLevel(l); // throws on overlap / bounds
  expect(board.count, l.arrows.length);
  for (final a in l.arrows) {
    for (final c in a.cells) {
      expect(l.mask.contains(c), isTrue, reason: 'level ${l.id}: $a outside mask');
    }
  }
  final r = PuzzleSolver.solve(board);
  expect(r.solvable, isTrue, reason: 'level ${l.id} unsolvable: ${r.deadlocked}');
  expect(r.order.length, l.arrows.length);
}

void main() {
  test('SeededRandom is deterministic and well spread', () {
    final a = SeededRandom(42), b = SeededRandom(42);
    final xs = List.generate(100, (_) => a.nextInt(1000));
    expect(List.generate(100, (_) => b.nextInt(1000)), xs);
    expect(xs.toSet().length, greaterThan(80));
    expect(SeededRandom.hashString('2026-11-15'), SeededRandom.hashString('2026-11-15'));
    expect(SeededRandom.hashString('2026-11-15'), isNot(SeededRandom.hashString('2026-11-16')));
  });

  test('same seed + config ⇒ identical level', () {
    const cfg = GeneratorConfig(seed: 1234, rows: 8, cols: 8, difficulty: Difficulty.hard, shape: BoardShape.heart);
    expect(LevelGenerator.generate(cfg).encodeArrows(), LevelGenerator.generate(cfg).encodeArrows());
  });

  test('different seeds ⇒ different levels', () {
    const a = GeneratorConfig(seed: 1, rows: 6, cols: 6);
    const b = GeneratorConfig(seed: 2, rows: 6, cols: 6);
    expect(LevelGenerator.generate(a).encodeArrows(), isNot(LevelGenerator.generate(b).encodeArrows()));
  });

  test('all 50 curated levels are valid and solvable', () {
    for (var n = 1; n <= CuratedLevels.count; n++) {
      expectValid(CuratedLevels.level(n));
    }
  });

  test('curated difficulty progresses (arrow count trend rises)', () {
    double avg(int from, int to) =>
        [for (var n = from; n <= to; n++) CuratedLevels.level(n).arrows.length].reduce((a, b) => a + b) / (to - from + 1);
    expect(avg(11, 20), greaterThan(avg(1, 10)));
    expect(avg(21, 35), greaterThan(avg(11, 20)));
    expect(avg(36, 45), greaterThan(avg(21, 35)));
  });

  test('procedural campaign levels 51–1200 are all solvable', () {
    final cat = LevelCatalog(cacheSize: 2);
    for (var n = 51; n <= LevelCatalog.campaignLength; n++) {
      expectValid(cat.campaign(n));
    }
  });

  test('every board shape × difficulty generates a solvable level', () {
    for (final shape in BoardShape.values) {
      for (final d in Difficulty.values) {
        final l = LevelGenerator.generate(GeneratorConfig(seed: shape.index * 31 + d.index, rows: 9, cols: 9, shape: shape, difficulty: d));
        expectValid(l);
        expect(l.arrows, isNotEmpty);
      }
    }
  });

  test('layered tower levels are solvable and actually layered', () {
    final cat = LevelCatalog();
    for (var i = 0; i < 20; i++) {
      final l = cat.tower(i);
      expectValid(l);
      expect(l.layerCount, 2);
    }
  });

  test('harder difficulty produces deeper dependency chains on average', () {
    double depth(Difficulty d) {
      var sum = 0;
      for (var i = 0; i < 12; i++) {
        final r = LevelGenerator.generateWithReport(GeneratorConfig(seed: 900 + i, rows: 8, cols: 8, difficulty: d));
        sum += r.solve.depth;
      }
      return sum / 12;
    }

    expect(depth(Difficulty.expert), greaterThan(depth(Difficulty.easy)));
  });

  test('daily challenge is deterministic per date and differs across dates', () {
    final a = LevelCatalog().daily(DateTime(2026, 11, 15));
    final b = LevelCatalog().daily(DateTime(2026, 11, 15, 23, 59));
    final c = LevelCatalog().daily(DateTime(2026, 11, 16));
    expect(a.encodeArrows(), b.encodeArrows());
    expect(a.encodeArrows(), isNot(c.encodeArrows()));
    expectValid(a);
    expect(LevelCatalog.dailyKey(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('endless and challenge modes are solvable', () {
    final cat = LevelCatalog();
    for (var i = 0; i < 40; i++) {
      expectValid(cat.endless(i));
      expectValid(cat.challenge('timed', i));
    }
  });
}
