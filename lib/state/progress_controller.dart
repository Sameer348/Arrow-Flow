import 'dart:async';

import 'package:flutter/foundation.dart';

import '../game/engine/game_session.dart';
import '../game/engine/scoring.dart';
import '../game/levels/level_catalog.dart';
import '../models/achievement.dart';
import '../models/booster.dart';
import '../models/cosmetics.dart';
import '../models/daily_reward.dart';
import '../models/game_mode.dart';
import '../models/player_progress.dart';
import '../repositories/progress_repository.dart';

/// Rewards granted when a level is finished.
class LevelReward {
  const LevelReward({
    required this.coins,
    required this.firstClear,
    required this.newBest,
    required this.unlocked,
  });

  final int coins;
  final bool firstClear;
  final bool newBest;
  final List<Achievement> unlocked;
}

/// App-level (meta) state: coins, stars, inventory, cosmetics, achievements.
/// Separate from the in-level [GameSession].
class ProgressController extends ChangeNotifier {
  ProgressController(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final ProgressRepository _repo;
  final DateTime Function() _clock;
  PlayerProgress _p = PlayerProgress();
  final List<Achievement> _pendingUnlocks = [];

  PlayerProgress get progress => _p;
  int get coins => _p.coins;
  ArrowSkin get skin => ArrowSkin.byId(_p.selectedSkin);
  GameTheme get theme => GameTheme.byId(_p.selectedTheme);

  Future<void> load() async {
    _p = await _repo.loadProgress();
    notifyListeners();
  }

  void _commit() {
    notifyListeners();
    unawaited(_repo.saveProgress(_p).catchError((Object e) => debugPrint('Save failed: $e')));
  }

  // ------------------------------------------------------------------ Coins

  void addCoins(int n) {
    _p.coins += n;
    _commit();
  }

  bool trySpend(int n) {
    if (_p.coins < n) return false;
    _p.coins -= n;
    _commit();
    return true;
  }

  // --------------------------------------------------------------- Boosters

  int boosterCount(Booster b) => _p.boosters[b] ?? 0;

  bool consumeBooster(Booster b) {
    final n = boosterCount(b);
    if (n <= 0) return false;
    _p.boosters[b] = n - 1;
    _commit();
    return true;
  }

  void addBooster(Booster b, [int n = 1]) {
    _p.boosters[b] = boosterCount(b) + n;
    _commit();
  }

  bool buyBooster(Booster b, {int quantity = 1}) {
    if (!trySpend(b.price * quantity)) return false;
    addBooster(b, quantity);
    return true;
  }

  // -------------------------------------------------------------- Cosmetics

  bool ownsSkin(String id) => _p.ownedSkins.contains(id);
  bool ownsTheme(String id) => _p.ownedThemes.contains(id);

  bool buySkin(ArrowSkin s) {
    if (ownsSkin(s.id) || !trySpend(s.price)) return false;
    _p.ownedSkins.add(s.id);
    _p.selectedSkin = s.id;
    _commit();
    return true;
  }

  bool buyTheme(GameTheme t) {
    if (ownsTheme(t.id) || !trySpend(t.price)) return false;
    _p.ownedThemes.add(t.id);
    _p.selectedTheme = t.id;
    _commit();
    return true;
  }

  /// Grants a skin for free (rewards, mystery box) and equips it.
  void grantSkin(String id) {
    _p.ownedSkins.add(id);
    _p.selectedSkin = id;
    _commit();
  }

  void selectSkin(String id) {
    if (!ownsSkin(id)) return;
    _p.selectedSkin = id;
    _commit();
  }

  void selectTheme(String id) {
    if (!ownsTheme(id)) return;
    _p.selectedTheme = id;
    _commit();
  }

  // ----------------------------------------------------------------- Levels

  int modeIndex(GameMode mode) => switch (mode) {
        GameMode.endless => _p.endlessIndex,
        GameMode.tower => _p.towerIndex,
        _ => _p.modeIndex[mode.name] ?? 0,
      };

  int starsFor(int level) => _p.stars[level] ?? 0;
  bool isUnlocked(int level) => level <= _p.unlockedLevel;

  /// Records a finished attempt and returns the rewards.
  LevelReward recordResult({required GameMode mode, required int levelId, required LevelResult result, DateTime? date}) {
    if (!result.won) {
      _commit();
      return const LevelReward(coins: 0, firstClear: false, newBest: false, unlocked: []);
    }
    final s = _p.stats;
    s.levelsCompleted++;
    s.arrowsCleared += result.arrowsCleared;
    s.totalScore += result.score;
    if (result.perfect) s.perfectLevels++;
    if (result.bestCombo > s.bestCombo) s.bestCombo = result.bestCombo;
    if (s.fastestSeconds == 0 || result.seconds < s.fastestSeconds) s.fastestSeconds = result.seconds;

    var firstClear = false;
    var newBest = false;
    var daily = false;
    switch (mode) {
      case GameMode.classic:
        firstClear = !_p.stars.containsKey(levelId);
        if (result.stars > starsFor(levelId)) _p.stars[levelId] = result.stars;
        if (result.score > (_p.bestScores[levelId] ?? 0)) {
          _p.bestScores[levelId] = result.score;
          newBest = true;
        }
        if (levelId >= _p.unlockedLevel) _p.unlockedLevel = levelId + 1;
      case GameMode.daily:
        daily = true;
        final key = LevelCatalog.dailyKey(date ?? _clock());
        final prev = _p.dailyResults[key];
        firstClear = prev == null;
        if (prev == null || result.score > prev.score) {
          _p.dailyResults[key] = DailyResult(score: result.score, stars: result.stars, seconds: result.seconds);
          newBest = true;
        }
        if (firstClear) {
          s.dailyCompleted++;
          final yesterday = LevelCatalog.dailyKey((date ?? _clock()).subtract(const Duration(days: 1)));
          s.dailyStreak = s.lastDailyKey == yesterday ? s.dailyStreak + 1 : 1;
          s.lastDailyKey = key;
        }
      case GameMode.endless:
        _p.endlessIndex++;
        firstClear = true;
        if (_p.endlessIndex > s.endlessBest) s.endlessBest = _p.endlessIndex;
      case GameMode.tower:
        _p.towerIndex++;
        s.towerCompleted++;
        firstClear = true;
      case GameMode.timed || GameMode.limitedMoves || GameMode.perfect:
        _p.modeIndex[mode.name] = modeIndex(mode) + 1;
        firstClear = true;
    }

    final coins = Scoring.coins(stars: result.stars, perfect: result.perfect, firstClear: firstClear, daily: daily && firstClear);
    _p.coins += coins;
    final unlocked = _checkAchievements();
    _commit();
    return LevelReward(coins: coins, firstClear: firstClear, newBest: newBest, unlocked: unlocked);
  }

  // ----------------------------------------------------------- Achievements

  List<Achievement> _checkAchievements() {
    final out = <Achievement>[];
    for (final a in Achievement.all) {
      if (_p.achievements.contains(a.id)) continue;
      if (a.isMet(_p)) {
        _p.achievements.add(a.id);
        _p.coins += a.reward;
        out.add(a);
      }
    }
    _pendingUnlocks.addAll(out);
    return out;
  }

  /// Achievements unlocked since last call (for the unlock modal).
  List<Achievement> takePendingUnlocks() {
    final out = List<Achievement>.of(_pendingUnlocks);
    _pendingUnlocks.clear();
    return out;
  }

  // ---------------------------------------------------------- Daily reward

  String get _todayKey => LevelCatalog.dailyKey(_clock());

  bool get canClaimDailyReward => _p.lastRewardClaimKey != _todayKey;

  /// Day index (0–6) that will be granted by the next claim.
  int get nextRewardIndex {
    final last = _p.lastRewardClaimKey;
    if (last == null) return 0;
    final yesterday = LevelCatalog.dailyKey(_clock().subtract(const Duration(days: 1)));
    if (last != yesterday && last != _todayKey) return 0; // streak broken
    return _p.dailyRewardDay % DailyReward.cycle.length;
  }

  DailyReward? claimDailyReward() {
    if (!canClaimDailyReward) return null;
    final idx = nextRewardIndex;
    final r = DailyReward.cycle[idx];
    _p.coins += r.coins;
    r.boosters.forEach((b, n) => _p.boosters[b] = boosterCount(b) + n);
    if (r.skinId != null) {
      if (_p.ownedSkins.contains(r.skinId)) {
        _p.coins += DailyReward.skinFallbackCoins;
      } else {
        _p.ownedSkins.add(r.skinId!);
      }
    }
    _p.dailyRewardDay = idx + 1;
    _p.lastRewardClaimKey = _todayKey;
    _commit();
    return r;
  }

  DailyResult? dailyResult(DateTime d) => _p.dailyResults[LevelCatalog.dailyKey(d)];

  // ------------------------------------------------------------------ Misc

  void completeTutorial() {
    if (_p.tutorialDone) return;
    _p.tutorialDone = true;
    _commit();
  }

  void setProfile({String? name, int? avatar}) {
    if (name != null && name.trim().isNotEmpty) _p.playerName = name.trim().substring(0, name.trim().length.clamp(0, 16));
    if (avatar != null) _p.avatar = avatar;
    _commit();
  }

  void setAdsEnabled(bool v) {
    _p.adsEnabled = v;
    _commit();
  }

  /// Seeds a mid-game profile for store screenshots
  /// (`--dart-define=SCREENSHOT_MODE=true`). Never used in normal builds.
  void applyScreenshotProgress() {
    _p
      ..unlockedLevel = 47
      ..coins = 2480
      ..playerName = 'Alex'
      ..avatar = 4
      ..tutorialDone = true
      ..lastRewardClaimKey = _todayKey
      ..dailyRewardDay = 4;
    for (var i = 1; i < 47; i++) {
      _p.stars[i] = i % 7 == 0 ? 2 : 3;
      _p.bestScores[i] = 1200 + i * 37;
    }
    for (var d = 1; d <= 6; d++) {
      final key = LevelCatalog.dailyKey(_clock().subtract(Duration(days: d)));
      _p.dailyResults[key] = DailyResult(score: 4200 + d * 311, stars: d == 3 ? 2 : 3, seconds: 70 + d * 9);
    }
    _p.ownedSkins.addAll(['crystal', 'neon', 'fire', 'galaxy']);
    _p.ownedThemes.addAll(['aurora', 'ocean']);
    _p.achievements.addAll(['first_escape', 'puzzle_starter', 'levels_10', 'no_mistakes', 'speed_solver', 'perfect_solver']);
    _p.stats
      ..levelsCompleted = 46
      ..arrowsCleared = 812
      ..perfectLevels = 31
      ..bestCombo = 14
      ..dailyStreak = 6
      ..totalScore = 48210;
    _commit();
  }

  Future<void> resetProgress() async {
    await _repo.reset();
    _p = PlayerProgress();
    _pendingUnlocks.clear();
    notifyListeners();
  }
}
