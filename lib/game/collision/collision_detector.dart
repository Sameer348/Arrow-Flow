import '../../models/arrow_data.dart';
import '../board/board_state.dart';

enum BlockReason { none, pathBlocked, covered }

/// Result of checking whether an arrow may escape.
class MoveCheck {
  const MoveCheck._(this.reason, this.blockerId, this.blockCell, this.travelCells);

  const MoveCheck.free(int travel) : this._(BlockReason.none, null, null, travel);

  const MoveCheck.blocked(BlockReason reason, int blocker, Cell at, int travel)
      : this._(reason, blocker, at, travel);

  final BlockReason reason;

  /// The first arrow standing in the way (or covering it).
  final int? blockerId;

  /// Cell where the collision happens.
  final Cell? blockCell;

  /// Free cells the arrow can travel before hitting [blockCell] (or the
  /// distance to the board edge when free).
  final int travelCells;

  bool get canMove => reason == BlockReason.none;
}

/// Deterministic path / collision checks.
abstract final class CollisionDetector {
  /// Cells in front of the arrow's head up to (excluding) the board edge.
  static List<Cell> pathCells(ArrowData a, int rows, int cols) {
    final out = <Cell>[];
    var c = a.head.step(a.direction);
    while (c.row >= 0 && c.row < rows && c.col >= 0 && c.col < cols) {
      out.add(c);
      c = c.step(a.direction);
    }
    return out;
  }

  /// Checks [a] against the current [board].
  ///
  /// An arrow is blocked if any arrow on a higher layer covers one of its
  /// cells, or if any arrow on the same layer occupies a path cell.
  static MoveCheck check(BoardState board, ArrowData a) {
    for (var l = a.layer + 1; l <= a.layer + 3; l++) {
      for (final c in a.cells) {
        final id = board.occupant(c, layer: l);
        if (id != null) return MoveCheck.blocked(BlockReason.covered, id, c, 0);
      }
    }
    var travelled = 0;
    var c = a.head.step(a.direction);
    while (board.inBounds(c)) {
      final id = board.occupant(c, layer: a.layer);
      if (id != null && id != a.id) {
        return MoveCheck.blocked(BlockReason.pathBlocked, id, c, travelled);
      }
      travelled++;
      c = c.step(a.direction);
    }
    return MoveCheck.free(travelled);
  }

  static bool canEscape(BoardState board, int id) {
    final a = board.arrow(id);
    return a != null && check(board, a).canMove;
  }
}
