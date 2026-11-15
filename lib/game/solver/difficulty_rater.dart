import '../../models/board_shape.dart';
import '../../models/level_data.dart';
import 'puzzle_solver.dart';

/// Converts solver metrics into a 0–100+ difficulty score and band.
///
/// Difficulty is driven by blocking depth, arrow count and how few choices
/// the player has — not just board size.
abstract final class DifficultyRater {
  static double score(SolveResult r, {required int arrowCount, BoardShape shape = BoardShape.square, int layers = 1}) {
    if (!r.solvable || arrowCount == 0) return 0;
    final scarcity = (arrowCount / (r.averageMoves + 1)).clamp(0, 12);
    final s = r.depth * 6.0 +
        arrowCount * 0.9 +
        scarcity * 2.5 +
        (shape == BoardShape.square ? 0 : 3) +
        (layers - 1) * 8;
    return s;
  }

  /// Score band for each difficulty. Used by the validation pipeline.
  static (double, double) band(Difficulty d) => switch (d) {
        Difficulty.tutorial => (0, 22),
        Difficulty.easy => (14, 38),
        Difficulty.normal => (30, 58),
        Difficulty.hard => (48, 82),
        Difficulty.expert => (68, 120),
        Difficulty.master => (90, 1000),
      };

  static Difficulty classify(double s) {
    if (s < 18) return Difficulty.tutorial;
    if (s < 34) return Difficulty.easy;
    if (s < 52) return Difficulty.normal;
    if (s < 74) return Difficulty.hard;
    if (s < 100) return Difficulty.expert;
    return Difficulty.master;
  }
}
