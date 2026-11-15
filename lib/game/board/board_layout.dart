import 'dart:math' as math;
import 'dart:ui';

import '../../models/arrow_data.dart';
import 'board_state.dart';

/// Maps between board cells and pixels inside the board widget.
///
/// Because the board lives inside an InteractiveViewer, gesture positions
/// arrive in this local (un-zoomed) space — so this mapping stays valid at
/// any zoom/pan.
class BoardLayout {
  BoardLayout(this.size, this.rows, this.cols, {this.layers = 1}) {
    final pad = 0.4;
    cell = math.min(size.width / (cols + pad * 2), size.height / (rows + pad * 2 + (layers - 1) * layerLiftCells));
    final w = cell * cols;
    final h = cell * rows;
    origin = Offset((size.width - w) / 2, (size.height - h) / 2 + (layers - 1) * layerLiftCells * cell / 2);
    grid = origin & Size(w, h);
    boardRect = grid.inflate(cell * pad);
  }

  static const layerLiftCells = 0.22;

  final Size size;
  final int rows;
  final int cols;
  final int layers;
  late final double cell;
  late final Offset origin;
  late final Rect grid;
  late final Rect boardRect;

  double layerLift(int layer) => layer * layerLiftCells * cell;

  Offset cellCenter(int row, int col, {int layer = 0}) =>
      Offset(origin.dx + (col + 0.5) * cell, origin.dy + (row + 0.5) * cell - layerLift(layer));

  Offset center(Cell c, {int layer = 0}) => cellCenter(c.row, c.col, layer: layer);

  Cell? cellAt(Offset p, {int layer = 0}) {
    final q = p + Offset(0, layerLift(layer));
    final c = ((q.dx - origin.dx) / cell).floor();
    final r = ((q.dy - origin.dy) / cell).floor();
    if (r < 0 || r >= rows || c < 0 || c >= cols) return null;
    return Cell(r, c);
  }

  /// Topmost arrow under [p]. Falls back to the nearest arrow cell within
  /// ~0.6 cells so slightly-off taps on small boards still register.
  int? hitTest(Offset p, BoardState board) {
    for (var l = layers - 1; l >= 0; l--) {
      final cell = cellAt(p, layer: l);
      if (cell == null) continue;
      final id = board.occupant(cell, layer: l);
      if (id != null) return id;
    }
    int? best;
    var bestD = (cell * 0.6) * (cell * 0.6);
    for (final a in board.arrows) {
      for (final c in a.cells) {
        final d = (center(c, layer: a.layer) - p).distanceSquared;
        if (d < bestD) {
          bestD = d;
          best = a.id;
        }
      }
    }
    return best;
  }

  /// Distance in cells from the head to just past the board edge, plus the
  /// arrow's own length so the tail fully leaves.
  double escapeDistance(ArrowData a) {
    final d = a.direction;
    final toEdge = switch (d) {
      _ when d.dRow < 0 => a.row + 1,
      _ when d.dRow > 0 => rows - a.row,
      _ when d.dCol < 0 => a.column + 1,
      _ => cols - a.column,
    };
    return toEdge + a.length + 0.6;
  }
}
