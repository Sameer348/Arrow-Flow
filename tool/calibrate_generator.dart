// Prints generator depth/score statistics per difficulty and size.
// Run: dart run tool/calibrate_generator.dart
// ignore_for_file: avoid_print

import 'package:arrow_flow/core/utils/seeded_random.dart';
import 'package:arrow_flow/game/generator/level_generator.dart';
import 'package:arrow_flow/models/level_data.dart';

void main() {
  for (final d in Difficulty.values) {
    for (final size in [4, 6, 8, 10]) {
      final sw = Stopwatch()..start();
      var depth = 0, arrows = 0, score = 0.0, inBand = 0;
      const n = 10;
      for (var i = 0; i < n; i++) {
        final r = LevelGenerator.generateWithReport(GeneratorConfig(seed: SeededRandom.hashString('x$i$size'), rows: size, cols: size, difficulty: d));
        depth += r.solve.depth; arrows += r.level.arrows.length; score += r.score; if (r.inBand) inBand++;
      }
      print('${d.name.padRight(8)} $size: depth ${(depth / n).toStringAsFixed(1)} arrows ${(arrows / n).toStringAsFixed(1)} score ${(score / n).toStringAsFixed(0)} inBand $inBand/$n  ${sw.elapsedMilliseconds ~/ n}ms');
    }
  }
}
