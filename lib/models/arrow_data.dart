import 'direction.dart';

/// A cell coordinate on the board.
class Cell {
  const Cell(this.row, this.col);
  final int row;
  final int col;

  Cell step(Direction d, [int n = 1]) => Cell(row + d.dRow * n, col + d.dCol * n);

  @override
  bool operator ==(Object other) =>
      other is Cell && other.row == row && other.col == col;

  @override
  int get hashCode => row * 4099 + col;

  @override
  String toString() => '($row,$col)';
}

enum ArrowType {
  /// Regular arrow.
  normal,

  /// Bonus arrow — worth extra score, rendered with the special gradient.
  bonus,
}

/// Immutable description of one arrow.
///
/// `(row, column)` is the HEAD cell. The body extends `length - 1` cells
/// behind the head (opposite to [direction]). `layer` is used by the 2.5D
/// tower mode: an arrow on a higher layer covers arrows below it.
class ArrowData {
  const ArrowData({
    required this.id,
    required this.row,
    required this.column,
    required this.direction,
    this.length = 1,
    this.layer = 0,
    this.type = ArrowType.normal,
  }) : assert(length >= 1);

  final int id;
  final int row;
  final int column;
  final Direction direction;
  final int length;
  final int layer;
  final ArrowType type;

  Cell get head => Cell(row, column);
  Cell get tail => head.step(direction.opposite, length - 1);

  /// Cells occupied by this arrow, head first.
  List<Cell> get cells =>
      List.generate(length, (i) => head.step(direction.opposite, i), growable: false);

  ArrowData copyWith({int? id, Direction? direction, int? row, int? column}) => ArrowData(
        id: id ?? this.id,
        row: row ?? this.row,
        column: column ?? this.column,
        direction: direction ?? this.direction,
        length: length,
        layer: layer,
        type: type,
      );

  /// Same cells, opposite direction (used by Shuffle).
  ArrowData flipped() => ArrowData(
        id: id,
        row: tail.row,
        column: tail.col,
        direction: direction.opposite,
        length: length,
        layer: layer,
        type: type,
      );

  /// Compact encoding: `row,col,DIR,len[,layer[,b]]`.
  String encode() {
    final b = StringBuffer('$row,$column,${direction.code},$length');
    if (layer != 0 || type != ArrowType.normal) b.write(',$layer');
    if (type == ArrowType.bonus) b.write(',b');
    return b.toString();
  }

  static ArrowData decode(int id, String s) {
    final p = s.trim().split(',');
    return ArrowData(
      id: id,
      row: int.parse(p[0]),
      column: int.parse(p[1]),
      direction: Direction.fromCode(p[2]),
      length: int.parse(p[3]),
      layer: p.length > 4 ? int.parse(p[4]) : 0,
      type: p.length > 5 && p[5] == 'b' ? ArrowType.bonus : ArrowType.normal,
    );
  }

  @override
  String toString() => 'Arrow#$id ${encode()}';
}
