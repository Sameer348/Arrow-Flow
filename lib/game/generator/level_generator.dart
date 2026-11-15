import '../../core/utils/seeded_random.dart';
import '../../models/arrow_data.dart';
import '../../models/board_shape.dart';
import '../../models/direction.dart';
import '../../models/level_data.dart';
import '../board/board_state.dart';
import '../collision/collision_detector.dart';
import '../solver/difficulty_rater.dart';
import '../solver/puzzle_solver.dart';

/// Inputs for procedural generation. Same config ⇒ same level.
class GeneratorConfig {
  const GeneratorConfig({
    required this.seed,
    required this.rows,
    required this.cols,
    this.difficulty = Difficulty.normal,
    this.density = 0.8,
    this.shape = BoardShape.square,
    this.minLength = 1,
    this.maxLength = 4,
    this.layers = 1,
    this.specialRules = const {},
  });

  final int seed;
  final int rows;
  final int cols;
  final Difficulty difficulty;

  /// Target fraction of playable cells covered by arrows.
  final double density;
  final BoardShape shape;
  final int minLength;
  final int maxLength;
  final int layers;
  final Set<SpecialRule> specialRules;

  /// How many candidates compete per placement. More candidates ⇒ the
  /// generator prefers placements that block existing arrows ⇒ deeper
  /// dependency chains.
  int get blockingBias => switch (difficulty) {
        Difficulty.tutorial => 1,
        Difficulty.easy => 2,
        Difficulty.normal => 3,
        Difficulty.hard => 5,
        Difficulty.expert => 7,
        Difficulty.master => 9,
      };
}

/// Report from the validation pipeline (spec §84).
class GenerationReport {
  const GenerationReport(this.level, this.solve, this.score, this.attempts, this.inBand);
  final LevelData level;
  final SolveResult solve;
  final double score;
  final int attempts;
  final bool inBand;
}

/// Procedural level generator.
///
/// Construction guarantees solvability: each new arrow is only placed if its
/// own escape path is clear of all arrows placed before it. Removing arrows
/// in reverse placement order therefore always works. Every candidate is
/// still run through [PuzzleSolver] before acceptance — never trust, verify.
abstract final class LevelGenerator {
  static const maxAttempts = 24;

  static LevelData generate(GeneratorConfig cfg, {int levelId = 0}) =>
      generateWithReport(cfg, levelId: levelId).level;

  static GenerationReport generateWithReport(GeneratorConfig cfg, {int levelId = 0}) {
    final (lo, hi) = DifficultyRater.band(cfg.difficulty);
    final target = (lo + hi) / 2;
    GenerationReport? best;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final rng = SeededRandom(cfg.seed ^ (attempt * 0x9E3779B1));
      final arrows = _build(cfg, rng);
      if (arrows.isEmpty) continue;

      // 2. Validate board (overlaps / bounds throw inside BoardState).
      final BoardState board;
      try {
        board = BoardState.fromArrows(cfg.rows, cfg.cols, arrows);
      } on StateError {
        continue;
      }
      // 3–5. Solve and confirm completion.
      final solve = PuzzleSolver.solve(board);
      if (!solve.solvable) continue;

      // 6. Rate difficulty.
      final score = DifficultyRater.score(solve,
          arrowCount: arrows.length, shape: cfg.shape, layers: cfg.layers);
      final inBand = score >= lo && score <= hi;
      final level = _toLevel(cfg, levelId, arrows, score);
      final report = GenerationReport(level, solve, score, attempt + 1, inBand);
      if (inBand) return report;
      if (best == null || (score - target).abs() < (best.score - target).abs()) {
        best = report;
      }
    }
    // 7. Nothing in band — ship the closest *solvable* candidate.
    return best ?? _fallback(cfg, levelId);
  }

  static LevelData _toLevel(GeneratorConfig cfg, int id, List<ArrowData> arrows, double score) {
    final n = arrows.length;
    return LevelData(
      id: id,
      rows: cfg.rows,
      cols: cfg.cols,
      arrows: arrows,
      difficulty: cfg.difficulty,
      shape: cfg.shape,
      seed: cfg.seed,
      mask: cfg.shape.mask(cfg.rows, cfg.cols),
      specialRules: {
        ...cfg.specialRules,
        if (cfg.layers > 1) SpecialRule.layered,
        if (arrows.any((a) => a.type == ArrowType.bonus)) SpecialRule.bonusArrows,
      },
      starRequirements: StarRequirements(
        maxMistakesForThree: 0,
        maxMistakesForTwo: n < 10 ? 1 : 2,
        parSeconds: (8 + n * 2.2 + score * 0.3).round(),
      ),
    );
  }

  static List<ArrowData> _build(GeneratorConfig cfg, SeededRandom rng) {
    final mask = cfg.shape.mask(cfg.rows, cfg.cols);
    final cells = mask.toList()
      ..sort((a, b) => a.row != b.row ? a.row - b.row : a.col - b.col);
    final arrows = <ArrowData>[];
    // heights[i] = length of the chain of arrows waiting (directly or
    // transitively) on arrow i, including itself. The newest arrow is always
    // free, so its height is exactly the blocking depth it creates.
    final heights = <int>[];
    final paths = <Set<Cell>>[];
    final board = BoardState.fromArrows(cfg.rows, cfg.cols, const []);

    for (var layer = 0; layer < cfg.layers; layer++) {
      final layerDensity = layer == 0 ? cfg.density : cfg.density * 0.45;
      final target = (cells.length * layerDensity).round();
      var filled = 0;
      final budget = cells.length * 40;
      // Upper layers sit on the middle of the board for a "tower" look.
      final layerCells = layer == 0
          ? cells
          : cells.where((c) => _isInner(c, cfg.rows, cfg.cols, layer)).toList();
      if (layerCells.isEmpty) continue;

      for (var t = 0; t < budget && filled < target; t++) {
        ArrowData? chosen;
        var chosenScore = -1.0;
        for (var k = 0; k < cfg.blockingBias; k++) {
          final cand = _candidate(cfg, rng, layerCells, mask, board, arrows.length, layer);
          if (cand == null) continue;
          final s = _blockScore(cand, arrows, paths, heights) + rng.nextDouble() * 0.5;
          if (s > chosenScore) {
            chosen = cand;
            chosenScore = s;
          }
        }
        if (chosen == null) continue;
        heights.add(_height(chosen, arrows, paths, heights));
        paths.add(CollisionDetector.pathCells(chosen, cfg.rows, cfg.cols).toSet());
        board.add(chosen);
        arrows.add(chosen);
        filled += chosen.length;
      }
    }
    // Re-number so ids are dense and stable.
    return [for (var i = 0; i < arrows.length; i++) arrows[i].copyWith(id: i)];
  }

  static bool _isInner(Cell c, int rows, int cols, int layer) {
    final m = layer * (rows >= 8 ? 2 : 1);
    return c.row >= m && c.row < rows - m && c.col >= m && c.col < cols - m;
  }

  static ArrowData? _candidate(GeneratorConfig cfg, SeededRandom rng, List<Cell> cells,
      Set<Cell> mask, BoardState board, int id, int layer) {
    final head = rng.pick(cells);
    if (board.occupant(head, layer: layer) != null) return null;
    final dir = Direction.values[rng.nextInt(4)];
    final maxLen = cfg.maxLength.clamp(cfg.minLength, 6);
    var len = cfg.minLength + rng.nextInt(maxLen - cfg.minLength + 1);
    // Shrink until the body fits.
    while (len >= cfg.minLength) {
      final a = ArrowData(
        id: id,
        row: head.row,
        column: head.col,
        direction: dir,
        length: len,
        layer: layer,
        type: cfg.specialRules.contains(SpecialRule.bonusArrows) && rng.nextBool(0.08)
            ? ArrowType.bonus
            : ArrowType.normal,
      );
      if (_fits(a, mask, board)) {
        // Solvability invariant: own path must be clear right now.
        if (!CollisionDetector.check(board, a).canMove) return null;
        return a;
      }
      len--;
    }
    return null;
  }

  static bool _fits(ArrowData a, Set<Cell> mask, BoardState board) {
    for (final c in a.cells) {
      if (!mask.contains(c)) return false;
      if (board.occupant(c, layer: a.layer) != null) return false;
    }
    // Upper layers must rest on something below (no floating arrows).
    if (a.layer > 0) {
      for (final c in a.cells) {
        if (board.occupant(c, layer: a.layer - 1) == null) return false;
      }
    }
    return true;
  }

  /// Whether [cand] would block existing arrow [i] (sits in its path, or
  /// covers it from the layer above).
  static bool _blocks(ArrowData cand, Set<Cell> candCells, ArrowData e, Set<Cell> ePath) {
    if (e.layer == cand.layer) return ePath.any(candCells.contains);
    return e.layer < cand.layer && e.cells.any(candCells.contains);
  }

  static int _height(ArrowData cand, List<ArrowData> existing, List<Set<Cell>> paths, List<int> heights) {
    final cells = cand.cells.toSet();
    var h = 1;
    for (var i = 0; i < existing.length; i++) {
      if (heights[i] + 1 > h && _blocks(cand, cells, existing[i], paths[i])) h = heights[i] + 1;
    }
    return h;
  }

  /// Prefers placements that deepen the dependency chain, then those that
  /// block many arrows, then longer arrows (they read better).
  static double _blockScore(ArrowData cand, List<ArrowData> existing, List<Set<Cell>> paths, List<int> heights) {
    final cells = cand.cells.toSet();
    var h = 1;
    var blocked = 0;
    for (var i = 0; i < existing.length; i++) {
      if (_blocks(cand, cells, existing[i], paths[i])) {
        blocked++;
        if (heights[i] + 1 > h) h = heights[i] + 1;
      }
    }
    return h * 1.0 + blocked * 0.3 + cand.length * 0.15;
  }

  static GenerationReport _fallback(GeneratorConfig cfg, int levelId) {
    // A trivially solvable single row — only reached if a config is absurd.
    final arrows = [
      ArrowData(id: 0, row: 0, column: cfg.cols - 1, direction: Direction.right, length: 1),
    ];
    final level = _toLevel(
        GeneratorConfig(seed: cfg.seed, rows: cfg.rows, cols: cfg.cols), levelId, arrows, 1);
    final solve = PuzzleSolver.solve(BoardState.fromArrows(cfg.rows, cfg.cols, arrows));
    return GenerationReport(level, solve, 1, maxAttempts, false);
  }
}
