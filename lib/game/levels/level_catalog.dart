import '../../core/utils/seeded_random.dart';
import '../../models/board_shape.dart';
import '../../models/level_data.dart';
import '../generator/level_generator.dart';
import 'curated_levels.dart';

/// Single source of truth for every level in the game.
///
/// Levels 1–50 are curated data ([CuratedLevels]). Levels 51+ are generated
/// deterministically from `seed + configuration`, so 1000+ levels cost no
/// storage. Generated levels are cached in a small LRU.
class LevelCatalog {
  LevelCatalog({this.cacheSize = 24});

  static const int campaignLength = 1200;
  final int cacheSize;
  final _cache = <String, LevelData>{};

  int get curatedCount => CuratedLevels.count;

  LevelData campaign(int number) {
    assert(number >= 1);
    if (number <= CuratedLevels.count) return CuratedLevels.level(number);
    return _cached('c$number', () => LevelGenerator.generate(campaignConfig(number), levelId: number));
  }

  /// Procedural campaign configuration for level [n] (> 50).
  ///
  /// Size grows slowly in chapters of 25; difficulty follows a saw-tooth so
  /// every tenth level is a breather; shapes rotate for variety.
  static GeneratorConfig campaignConfig(int n) {
    final chapter = (n - 51) ~/ 25; // 0-based
    final inChapter = (n - 51) % 25;
    final size = (7 + chapter ~/ 2).clamp(7, 12);
    final ramp = inChapter / 24.0;
    final breather = n % 10 == 0;
    final Difficulty diff;
    if (breather) {
      diff = Difficulty.normal;
    } else if (chapter < 2) {
      diff = ramp < 0.5 ? Difficulty.normal : Difficulty.hard;
    } else if (chapter < 8) {
      diff = ramp < 0.4 ? Difficulty.hard : Difficulty.expert;
    } else {
      diff = ramp < 0.3 ? Difficulty.expert : Difficulty.master;
    }
    final shapes = BoardShape.values;
    final shape = n % 3 == 0 ? shapes[(n ~/ 3) % shapes.length] : BoardShape.square;
    return GeneratorConfig(
      seed: SeededRandom.hashString('campaign:$n'),
      rows: size,
      cols: size,
      difficulty: diff,
      density: 0.78 + (ramp * 0.12),
      shape: size >= 8 ? shape : BoardShape.square,
      maxLength: size >= 9 ? 5 : 4,
      specialRules: n % 7 == 0 ? const {SpecialRule.bonusArrows} : const {},
    );
  }

  /// Timed / Limited Moves / Perfect challenge puzzles.
  LevelData challenge(String mode, int index) => _cached('$mode$index', () {
        final size = (5 + index ~/ 3).clamp(5, 9);
        return LevelGenerator.generate(
          GeneratorConfig(
            seed: SeededRandom.hashString('$mode:$index'),
            rows: size,
            cols: size,
            difficulty: index < 3 ? Difficulty.easy : (index < 10 ? Difficulty.normal : Difficulty.hard),
            density: 0.82,
          ),
          levelId: 400000 + index,
        );
      });

  /// Endless mode: infinite levels from an index.
  LevelData endless(int index) => _cached('e$index', () {
        final size = (5 + index ~/ 4).clamp(5, 10);
        final diff = index < 4
            ? Difficulty.easy
            : index < 12
                ? Difficulty.normal
                : index < 24
                    ? Difficulty.hard
                    : Difficulty.expert;
        return LevelGenerator.generate(
          GeneratorConfig(
            seed: SeededRandom.hashString('endless:$index'),
            rows: size,
            cols: size,
            difficulty: diff,
            density: 0.82,
            shape: size >= 8 && index.isOdd ? BoardShape.values[index % BoardShape.values.length] : BoardShape.square,
          ),
          levelId: 100000 + index,
        );
      });

  /// Daily challenge: seed is the date string, so everyone on the same
  /// configuration gets the same puzzle.
  LevelData daily(DateTime date) {
    final key = dailyKey(date);
    return _cached('d$key', () {
      final shapes = BoardShape.decorative;
      final shape = shapes[date.weekday % shapes.length];
      return LevelGenerator.generate(
        GeneratorConfig(
          seed: SeededRandom.hashString(key),
          rows: 9,
          cols: 9,
          difficulty: date.weekday >= DateTime.saturday ? Difficulty.expert : Difficulty.hard,
          density: 0.85,
          shape: shape,
          specialRules: const {SpecialRule.bonusArrows},
        ),
        levelId: 200000 + date.year * 400 + date.month * 32 + date.day,
      );
    });
  }

  /// Tower (2.5D) levels: two stacked layers.
  LevelData tower(int index) => _cached('t$index', () {
        final size = (6 + index ~/ 5).clamp(6, 9);
        return LevelGenerator.generate(
          GeneratorConfig(
            seed: SeededRandom.hashString('tower:$index'),
            rows: size,
            cols: size,
            difficulty: index < 5 ? Difficulty.normal : Difficulty.hard,
            density: 0.8,
            layers: 2,
            maxLength: 3,
          ),
          levelId: 300000 + index,
        );
      });

  static String dailyKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  LevelData _cached(String key, LevelData Function() build) {
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit; // move to most-recent
      return hit;
    }
    final level = build();
    _cache[key] = level;
    if (_cache.length > cacheSize) _cache.remove(_cache.keys.first);
    return level;
  }
}
