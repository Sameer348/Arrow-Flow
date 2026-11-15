import 'package:arrow_flow/game/board/board_state.dart';
import 'package:arrow_flow/game/collision/collision_detector.dart';
import 'package:arrow_flow/models/arrow_data.dart';
import 'package:arrow_flow/models/direction.dart';
import 'package:flutter_test/flutter_test.dart';

ArrowData a(int id, int r, int c, Direction d, [int len = 1, int layer = 0]) =>
    ArrowData(id: id, row: r, column: c, direction: d, length: len, layer: layer);

void main() {
  group('ArrowData geometry', () {
    test('body extends behind the head', () {
      final x = a(0, 2, 3, Direction.right, 3);
      expect(x.cells, const [Cell(2, 3), Cell(2, 2), Cell(2, 1)]);
      expect(x.tail, const Cell(2, 1));
    });

    test('flipped keeps cells and reverses direction', () {
      final x = a(0, 1, 1, Direction.down, 2);
      final f = x.flipped();
      expect(f.cells.toSet(), x.cells.toSet());
      expect(f.direction, Direction.up);
    });

    test('encode/decode round-trip', () {
      final x = ArrowData(id: 3, row: 4, column: 2, direction: Direction.left, length: 2, layer: 1, type: ArrowType.bonus);
      final y = ArrowData.decode(3, x.encode());
      expect(y.encode(), x.encode());
      expect(y.type, ArrowType.bonus);
    });
  });

  group('Path validation', () {
    test('path runs from head to the edge', () {
      final x = a(0, 1, 1, Direction.up);
      expect(CollisionDetector.pathCells(x, 4, 4), const [Cell(0, 1)]);
      final y = a(1, 1, 1, Direction.right);
      expect(CollisionDetector.pathCells(y, 4, 4), const [Cell(1, 2), Cell(1, 3)]);
    });

    test('free arrow on empty board', () {
      final b = BoardState.fromArrows(4, 4, [a(0, 2, 2, Direction.left, 2)]);
      final r = CollisionDetector.check(b, b.arrow(0)!);
      expect(r.canMove, isTrue);
      // Head (2,2) pointing left, body at (2,3); path is (2,1), (2,0).
      expect(r.travelCells, 2);
    });
  });

  group('Collision detection', () {
    test('arrow blocked by another in its path reports blocker and distance', () {
      final b = BoardState.fromArrows(5, 5, [
        a(0, 2, 0, Direction.right),
        a(1, 2, 3, Direction.up),
      ]);
      final r = CollisionDetector.check(b, b.arrow(0)!);
      expect(r.canMove, isFalse);
      expect(r.reason, BlockReason.pathBlocked);
      expect(r.blockerId, 1);
      expect(r.blockCell, const Cell(2, 3));
      expect(r.travelCells, 2);
    });

    test('removing the blocker frees the arrow', () {
      final b = BoardState.fromArrows(5, 5, [a(0, 2, 0, Direction.right), a(1, 2, 3, Direction.up)]);
      b.remove(1);
      expect(CollisionDetector.canEscape(b, 0), isTrue);
    });

    test('arrows on other layers do not block the path', () {
      final b = BoardState.fromArrows(4, 4, [a(0, 1, 0, Direction.right), a(1, 2, 2, Direction.up, 1, 1)]);
      expect(CollisionDetector.check(b, b.arrow(0)!).canMove, isTrue);
    });

    test('arrow covered by an upper layer is blocked', () {
      final b = BoardState.fromArrows(4, 4, [a(0, 1, 1, Direction.right), a(1, 1, 1, Direction.up, 1, 1)]);
      final r = CollisionDetector.check(b, b.arrow(0)!);
      expect(r.reason, BlockReason.covered);
      expect(r.blockerId, 1);
    });

    test('overlapping arrows are rejected', () {
      expect(
        () => BoardState.fromArrows(3, 3, [a(0, 1, 1, Direction.right, 2), a(1, 1, 0, Direction.up)]),
        throwsStateError,
      );
    });

    test('out-of-bounds arrows are rejected', () {
      expect(() => BoardState.fromArrows(3, 3, [a(0, 0, 0, Direction.right, 2)]), throwsStateError);
    });
  });
}
