import 'arrow_data.dart';

/// Board silhouettes. Each shape is a 10×10 template sampled (nearest
/// neighbour) to the target grid size, so the same shape works at any size.
enum BoardShape {
  square('Square', null),
  heart('Heart', [
    '.###..###.',
    '##########',
    '##########',
    '##########',
    '##########',
    '.########.',
    '..######..',
    '...####...',
    '....##....',
    '....##....',
  ]),
  star('Star', [
    '....##....',
    '...####...',
    '...####...',
    '##########',
    '.########.',
    '..######..',
    '..######..',
    '.###..###.',
    '.##....##.',
    '##......##',
  ]),
  diamond('Diamond', [
    '....##....',
    '...####...',
    '..######..',
    '.########.',
    '##########',
    '##########',
    '.########.',
    '..######..',
    '...####...',
    '....##....',
  ]),
  circle('Circle', [
    '...####...',
    '.########.',
    '.########.',
    '##########',
    '##########',
    '##########',
    '##########',
    '.########.',
    '.########.',
    '...####...',
  ]),
  spiral('Spiral', [
    '##########',
    '##......##',
    '#..####..#',
    '#.##..##.#',
    '#.#.##.#.#',
    '#.#.####.#',
    '#.##....##',
    '#..######.',
    '##........',
    '##########',
  ]),
  crown('Crown', [
    '#...##...#',
    '##..##..##',
    '###.##.###',
    '##########',
    '##########',
    '##########',
    '.########.',
    '.########.',
    '##########',
    '##########',
  ]),
  butterfly('Butterfly', [
    '##......##',
    '###....###',
    '####..####',
    '##########',
    '.########.',
    '.########.',
    '##########',
    '####..####',
    '###....###',
    '##......##',
  ]),
  flower('Flower', [
    '.##.##.##.',
    '##########',
    '.########.',
    '##########',
    '####..####',
    '####..####',
    '##########',
    '.########.',
    '##########',
    '.##.##.##.',
  ]),
  rocket('Rocket', [
    '....##....',
    '...####...',
    '...####...',
    '..######..',
    '..######..',
    '..######..',
    '..######..',
    '.########.',
    '##########',
    '##.#..#.##',
  ]),
  castle('Castle', [
    '#.#.##.#.#',
    '##########',
    '##########',
    '.########.',
    '.########.',
    '.###..###.',
    '.###..###.',
    '.########.',
    '##########',
    '##########',
  ]);

  const BoardShape(this.label, this._template);

  final String label;
  final List<String>? _template;

  /// Set of active cells for a `rows × cols` board.
  Set<Cell> mask(int rows, int cols) {
    final t = _template;
    final out = <Cell>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (t == null) {
          out.add(Cell(r, c));
          continue;
        }
        final tr = ((r + 0.5) * t.length / rows).floor().clamp(0, t.length - 1);
        final line = t[tr];
        final tc = ((c + 0.5) * line.length / cols).floor().clamp(0, line.length - 1);
        if (line[tc] == '#') out.add(Cell(r, c));
      }
    }
    return out;
  }

  static List<BoardShape> get decorative =>
      values.where((s) => s != BoardShape.square).toList(growable: false);
}
