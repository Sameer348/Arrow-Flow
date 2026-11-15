import '../../game/levels/level_catalog.dart';
import '../../models/game_mode.dart';
import '../../models/level_data.dart';

/// Which puzzle to play: a mode plus an index within that mode.
class GameLaunch {
  const GameLaunch(this.mode, this.index, {this.date});

  const GameLaunch.campaign(int level) : this(GameMode.classic, level);

  final GameMode mode;

  /// Campaign level number (1-based) or per-mode puzzle index (0-based).
  final int index;

  /// Date for the daily challenge.
  final DateTime? date;

  bool get isTutorial => mode == GameMode.classic && index <= 2;

  LevelData resolve(LevelCatalog c) => switch (mode) {
        GameMode.classic => c.campaign(index),
        GameMode.endless => c.endless(index),
        GameMode.tower => c.tower(index),
        GameMode.daily => c.daily(date ?? DateTime.now()),
        GameMode.timed || GameMode.limitedMoves || GameMode.perfect => c.challenge(mode.name, index),
      };

  /// The launch that follows this one, or null if the mode has no "next".
  GameLaunch? get next => switch (mode) {
        GameMode.daily => null,
        GameMode.classic when index >= LevelCatalog.campaignLength => null,
        _ => GameLaunch(mode, index + 1),
      };

  String get title => switch (mode) {
        GameMode.classic => 'Level $index',
        GameMode.daily => 'Daily Challenge',
        _ => '${mode.label} ${index + 1}',
      };
}
