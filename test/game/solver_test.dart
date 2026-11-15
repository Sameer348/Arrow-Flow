import 'package:arrow_flow/game/board/board_state.dart';
import 'package:arrow_flow/game/collision/collision_detector.dart';
import 'package:arrow_flow/game/solver/puzzle_solver.dart';
import 'package:arrow_flow/models/arrow_data.dart';
import 'package:arrow_flow/models/direction.dart';
import 'package:flutter_test/flutter_test.dart';

ArrowData a(int id, int r, int c, Direction d, [int len = 1]) =>
    ArrowData(id: id, row: r, column: c, direction: d, length: len);

void main() {
  // A blocked by B, B blocked by C (spec §1 example).
  BoardState chain() => BoardState.fromArrows(1, 4, [
        a(0, 0, 0, Direction.right), // A
        a(1, 0, 1, Direction.right), // B
        a(2, 0, 2, Direction.right), // C
      ]);

  test('legal moves: only the unblocked arrow', () {
    expect(PuzzleSolver.legalMoves(chain()), [2]);
  });

  test('solver finds the C → B → A order and depth 3', () {
    final r = PuzzleSolver.solve(chain());
    expect(r.solvable, isTrue);
    expect(r.order, [2, 1, 0]);
    expect(r.depth, 3);
    expect(r.initialMoves, 1);
    expect(r.minMoves, 1);
  });

  test('solver does not mutate its input', () {
    final b = chain();
    PuzzleSolver.solve(b);
    expect(b.count, 3);
  });

  test('deadlock: two arrows facing each other', () {
    final b = BoardState.fromArrows(1, 2, [a(0, 0, 0, Direction.right), a(1, 0, 1, Direction.left)]);
    expect(PuzzleSolver.isDeadlocked(b), isTrue);
    final r = PuzzleSolver.solve(b);
    expect(r.solvable, isFalse);
    expect(r.deadlocked, [0, 1]);
  });

  test('deadlock: four-arrow cycle with free arrows elsewhere', () {
    // 2x2 pinwheel: each arrow points into the next.
    final b = BoardState.fromArrows(3, 3, [
      a(0, 0, 0, Direction.right),
      a(1, 0, 1, Direction.down),
      a(2, 1, 1, Direction.left),
      a(3, 1, 0, Direction.up),
      a(4, 2, 2, Direction.right), // free
    ]);
    final r = PuzzleSolver.solve(b);
    expect(r.solvable, isFalse);
    expect(r.order, [4]);
    expect(r.deadlocked, [0, 1, 2, 3]);
  });

  test('hint picks a legal move that frees the most arrows', () {
    // Arrow 2 frees 0 and 1; arrow 3 frees nothing.
    final b = BoardState.fromArrows(3, 4, [
      a(0, 0, 0, Direction.down),
      a(1, 0, 1, Direction.down),
      a(2, 1, 1, Direction.right, 2), // occupies (1,1) and (1,0)
      a(3, 0, 3, Direction.up),
    ]);
    // 0 and 1 both point down into arrow 2.
    expect(CollisionDetector.canEscape(b, 0), isFalse);
    expect(CollisionDetector.canEscape(b, 1), isFalse);
    final hint = PuzzleSolver.hint(b);
    expect(hint, 2);
    expect(CollisionDetector.canEscape(b, hint!), isTrue);
  });

  test('hint is null when deadlocked', () {
    final b = BoardState.fromArrows(1, 2, [a(0, 0, 0, Direction.right), a(1, 0, 1, Direction.left)]);
    expect(PuzzleSolver.hint(b), isNull);
  });

  test('countSolutions counts topological orders', () {
    // Chain has exactly one order.
    expect(PuzzleSolver.countSolutions(chain()), 1);
    // Two independent free arrows: 2 orders.
    final b = BoardState.fromArrows(2, 2, [a(0, 0, 0, Direction.up), a(1, 1, 1, Direction.down)]);
    expect(PuzzleSolver.countSolutions(b), 2);
  });
}
