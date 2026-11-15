import '../board/board_state.dart';
import '../collision/collision_detector.dart';

/// Outcome of solving a board.
class SolveResult {
  const SolveResult({
    required this.solvable,
    required this.order,
    required this.depth,
    required this.initialMoves,
    required this.averageMoves,
    required this.minMoves,
    required this.deadlocked,
  });

  final bool solvable;

  /// One valid removal order (complete only when [solvable]).
  final List<int> order;

  /// Number of "waves" needed when removing every free arrow at once —
  /// the length of the longest blocking chain.
  final int depth;

  /// Legal moves available on the untouched board.
  final int initialMoves;

  /// Average number of legal choices along the solution (lower = harder).
  final double averageMoves;

  /// Fewest legal choices seen at any point of the solution.
  final int minMoves;

  /// Arrows that can never escape (non-empty ⇒ deadlock).
  final List<int> deadlocked;
}

/// Solver for arrow-escape boards.
///
/// Key property: removing an arrow can only ever *free* cells, never block
/// one. Legal moves therefore stay legal, so the puzzle is solvable iff the
/// greedy "remove anything free" process empties the board. This makes the
/// solver exact and O(n² · path) instead of a search.
abstract final class PuzzleSolver {
  static List<int> legalMoves(BoardState board) {
    final out = <int>[];
    for (final a in board.arrows) {
      if (CollisionDetector.check(board, a).canMove) out.add(a.id);
    }
    out.sort();
    return out;
  }

  static bool isDeadlocked(BoardState board) =>
      !board.isEmpty && legalMoves(board).isEmpty;

  static SolveResult solve(BoardState input) {
    final board = input.clone();
    final order = <int>[];
    var depth = 0;
    var totalChoices = 0;
    var steps = 0;
    var minMoves = 1 << 30;
    final initial = legalMoves(board).length;

    while (!board.isEmpty) {
      final wave = legalMoves(board);
      if (wave.isEmpty) break;
      depth++;
      // Remove one at a time to measure branching faithfully.
      for (final id in wave) {
        final choices = legalMoves(board).length;
        totalChoices += choices;
        if (choices < minMoves) minMoves = choices;
        steps++;
        board.remove(id);
        order.add(id);
      }
    }
    final deadlocked = board.ids.toList()..sort();
    return SolveResult(
      solvable: deadlocked.isEmpty,
      order: order,
      depth: depth,
      initialMoves: initial,
      averageMoves: steps == 0 ? 0 : totalChoices / steps,
      minMoves: steps == 0 ? 0 : minMoves,
      deadlocked: deadlocked,
    );
  }

  static bool isSolvable(BoardState board) => solve(board).solvable;

  /// The most useful legal move: the one that frees the most arrows,
  /// tie-broken by lowest id so hints are deterministic. Null if stuck.
  static int? hint(BoardState board) {
    final moves = legalMoves(board);
    if (moves.isEmpty) return null;
    final before = moves.length;
    int? best;
    var bestGain = -1;
    for (final id in moves) {
      final b = board.clone()..remove(id);
      final gain = legalMoves(b).length - (before - 1);
      if (gain > bestGain) {
        bestGain = gain;
        best = id;
      }
    }
    return best;
  }

  /// Counts distinct complete removal orders, capped at [cap].
  /// Memoised over remaining-set bitmasks; only for boards ≤ 20 arrows.
  static int countSolutions(BoardState board, {int cap = 100000}) {
    final ids = board.ids.toList()..sort();
    if (ids.length > 20) return -1;
    final memo = <int, int>{};
    final full = (1 << ids.length) - 1;

    int count(int mask, BoardState b) {
      if (mask == 0) return 1;
      final cached = memo[mask];
      if (cached != null) return cached;
      var total = 0;
      for (var i = 0; i < ids.length; i++) {
        if (mask & (1 << i) == 0) continue;
        if (!CollisionDetector.canEscape(b, ids[i])) continue;
        final removed = b.remove(ids[i]);
        total += count(mask & ~(1 << i), b);
        b.add(removed);
        if (total >= cap) break;
      }
      final v = total > cap ? cap : total;
      memo[mask] = v;
      return v;
    }

    return count(full, board.clone());
  }
}
