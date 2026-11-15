/// Cardinal direction an arrow points (and escapes) toward.
enum Direction {
  up(-1, 0, 'U'),
  down(1, 0, 'D'),
  left(0, -1, 'L'),
  right(0, 1, 'R');

  const Direction(this.dRow, this.dCol, this.code);

  final int dRow;
  final int dCol;
  final String code;

  Direction get opposite => switch (this) {
        Direction.up => Direction.down,
        Direction.down => Direction.up,
        Direction.left => Direction.right,
        Direction.right => Direction.left,
      };

  bool get isHorizontal => dRow == 0;

  /// Angle in radians for rendering (0 = pointing right).
  double get angle => switch (this) {
        Direction.right => 0,
        Direction.down => 1.5707963267948966,
        Direction.left => 3.141592653589793,
        Direction.up => -1.5707963267948966,
      };

  static Direction fromCode(String code) =>
      Direction.values.firstWhere((d) => d.code == code.toUpperCase());
}
