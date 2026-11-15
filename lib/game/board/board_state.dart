import '../../models/arrow_data.dart';
import '../../models/level_data.dart';

/// Mutable logical board: which arrows remain and which cells they occupy.
///
/// Pure Dart (no Flutter) so the solver, generator and tests can use it.
class BoardState {
  BoardState._(this.rows, this.cols, this.mask, this._arrows, this._occupancy);

  factory BoardState.fromLevel(LevelData level) =>
      BoardState.fromArrows(level.rows, level.cols, level.arrows, mask: level.mask);

  factory BoardState.fromArrows(int rows, int cols, Iterable<ArrowData> arrows,
      {Set<Cell>? mask}) {
    final board = BoardState._(rows, cols, mask ?? const {}, {}, {});
    for (final a in arrows) {
      board.add(a);
    }
    return board;
  }

  final int rows;
  final int cols;
  final Set<Cell> mask;
  final Map<int, ArrowData> _arrows;
  final Map<int, int> _occupancy;

  static int _key(int layer, int row, int col) => (layer << 20) | (row << 10) | col;

  Iterable<ArrowData> get arrows => _arrows.values;
  Iterable<int> get ids => _arrows.keys;
  int get count => _arrows.length;
  bool get isEmpty => _arrows.isEmpty;
  bool contains(int id) => _arrows.containsKey(id);
  ArrowData? arrow(int id) => _arrows[id];

  bool inBounds(Cell c) => c.row >= 0 && c.row < rows && c.col >= 0 && c.col < cols;

  /// Arrow id at [cell] on [layer], or null.
  int? occupant(Cell cell, {int layer = 0}) => _occupancy[_key(layer, cell.row, cell.col)];

  /// Topmost arrow at a cell across all layers.
  int? topOccupant(Cell cell, {int maxLayer = 3}) {
    for (var l = maxLayer; l >= 0; l--) {
      final id = occupant(cell, layer: l);
      if (id != null) return id;
    }
    return null;
  }

  /// Adds an arrow. Throws [StateError] on overlap or out-of-bounds.
  void add(ArrowData a) {
    for (final c in a.cells) {
      if (!inBounds(c)) throw StateError('$a out of bounds');
      final k = _key(a.layer, c.row, c.col);
      if (_occupancy.containsKey(k)) throw StateError('$a overlaps #${_occupancy[k]}');
    }
    _arrows[a.id] = a;
    for (final c in a.cells) {
      _occupancy[_key(a.layer, c.row, c.col)] = a.id;
    }
  }

  ArrowData remove(int id) {
    final a = _arrows.remove(id);
    if (a == null) throw StateError('No arrow #$id');
    for (final c in a.cells) {
      _occupancy.remove(_key(a.layer, c.row, c.col));
    }
    return a;
  }

  /// Replaces an arrow with a modified version occupying the same id.
  void replace(ArrowData a) {
    remove(a.id);
    add(a);
  }

  BoardState clone() => BoardState._(rows, cols, mask, Map.of(_arrows), Map.of(_occupancy));
}
