import 'arrow_data.dart';
import 'board_shape.dart';

enum Difficulty {
  tutorial('Tutorial'),
  easy('Easy'),
  normal('Normal'),
  hard('Hard'),
  expert('Expert'),
  master('Master');

  const Difficulty(this.label);
  final String label;
}

/// Optional rules a level can enable on top of its game mode.
enum SpecialRule {
  /// Arrows on several layers (2.5D tower).
  layered,

  /// Contains bonus arrows.
  bonusArrows,
}

/// Thresholds for awarding stars.
class StarRequirements {
  const StarRequirements({
    this.maxMistakesForThree = 0,
    this.maxMistakesForTwo = 2,
    this.parSeconds = 60,
  });

  final int maxMistakesForThree;
  final int maxMistakesForTwo;

  /// Target completion time; used for the speed bonus.
  final int parSeconds;
}

/// Immutable description of a puzzle.
class LevelData {
  LevelData({
    required this.id,
    required this.rows,
    required this.cols,
    required this.arrows,
    this.difficulty = Difficulty.normal,
    this.timeLimit,
    this.moveLimit,
    this.theme,
    this.specialRules = const {},
    this.starRequirements = const StarRequirements(),
    this.shape = BoardShape.square,
    this.seed,
    Set<Cell>? mask,
  }) : mask = mask ?? BoardShape.square.mask(rows, cols);

  final int id;
  final int rows;
  final int cols;
  final List<ArrowData> arrows;
  final Difficulty difficulty;

  /// Seconds, used in timed mode (null → derived from arrow count).
  final int? timeLimit;

  /// Taps allowed in limited-moves mode (null → derived).
  final int? moveLimit;

  /// Optional theme override id.
  final String? theme;
  final Set<SpecialRule> specialRules;
  final StarRequirements starRequirements;
  final BoardShape shape;

  /// Seed used to generate this level, if procedural.
  final int? seed;

  /// Playable cells. Cells outside the mask are empty space.
  final Set<Cell> mask;

  int get gridSize => rows > cols ? rows : cols;
  int get layerCount =>
      arrows.fold<int>(0, (m, a) => a.layer > m ? a.layer : m) + 1;

  int get effectiveTimeLimit => timeLimit ?? (20 + arrows.length * 4);
  int get effectiveMoveLimit => moveLimit ?? (arrows.length + 3 + arrows.length ~/ 6);

  LevelData copyWith({int? id, List<ArrowData>? arrows, Difficulty? difficulty}) => LevelData(
        id: id ?? this.id,
        rows: rows,
        cols: cols,
        arrows: arrows ?? this.arrows,
        difficulty: difficulty ?? this.difficulty,
        timeLimit: timeLimit,
        moveLimit: moveLimit,
        theme: theme,
        specialRules: specialRules,
        starRequirements: starRequirements,
        shape: shape,
        seed: seed,
        mask: mask,
      );

  /// Compact arrow list encoding: `r,c,D,len;r,c,D,len;...`.
  String encodeArrows() => arrows.map((a) => a.encode()).join(';');

  static List<ArrowData> decodeArrows(String s) {
    final parts = s.split(';').where((p) => p.trim().isNotEmpty).toList();
    return [for (var i = 0; i < parts.length; i++) ArrowData.decode(i, parts[i])];
  }
}
