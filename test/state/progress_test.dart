import 'package:arrow_flow/game/engine/game_session.dart';
import 'package:arrow_flow/models/booster.dart';
import 'package:arrow_flow/models/cosmetics.dart';
import 'package:arrow_flow/models/game_mode.dart';
import 'package:arrow_flow/models/player_progress.dart';
import 'package:arrow_flow/repositories/progress_repository.dart';
import 'package:arrow_flow/state/progress_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LevelResult win({int stars = 3, int mistakes = 0, int score = 1000, int arrows = 10, int secs = 20, int combo = 4}) => LevelResult(
    won: true, stars: stars, score: score, moves: arrows + mistakes, mistakes: mistakes, seconds: secs, bestCombo: combo, arrowsCleared: arrows);

void main() {
  group('PlayerProgress JSON', () {
    test('round-trips everything', () {
      final p = PlayerProgress(coins: 77, unlockedLevel: 12, selectedSkin: 'fire')
        ..stars[3] = 2
        ..bestScores[3] = 999
        ..ownedSkins.add('fire')
        ..achievements.add('first_escape')
        ..stats.arrowsCleared = 42
        ..modeIndex['timed'] = 4
        ..dailyResults['2026-11-15'] = const DailyResult(score: 5, stars: 3, seconds: 9);
      p.boosters[Booster.hammer] = 7;
      final q = PlayerProgress.fromJson(p.toJson());
      expect(q.toJson(), p.toJson());
    });
  });

  group('LocalProgressRepository', () {
    test('persists across instances and survives corrupt data', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = await LocalProgressRepository.create();
      await repo.saveProgress(PlayerProgress(coins: 321));
      final again = await LocalProgressRepository.create();
      expect((await again.loadProgress()).coins, 321);

      SharedPreferences.setMockInitialValues({'arrowflow.progress.v1': '{not json'});
      final broken = await LocalProgressRepository.create();
      expect((await broken.loadProgress()).unlockedLevel, 1);
    });
  });

  group('ProgressController', () {
    late InMemoryProgressRepository repo;
    late ProgressController c;
    var now = DateTime(2026, 11, 15, 10);

    setUp(() async {
      repo = InMemoryProgressRepository();
      now = DateTime(2026, 11, 15, 10);
      c = ProgressController(repo, clock: () => now);
      await c.load();
    });

    test('completing a level unlocks the next, stores stars and pays coins', () async {
      final before = c.coins;
      final r = c.recordResult(mode: GameMode.classic, levelId: 1, result: win());
      expect(c.progress.unlockedLevel, 2);
      expect(c.starsFor(1), 3);
      expect(r.firstClear, isTrue);
      expect(c.coins, greaterThan(before));
      expect(r.unlocked.map((a) => a.id), containsAll(['first_escape', 'puzzle_starter', 'no_mistakes']));
      // Persisted.
      final reloaded = ProgressController(repo);
      await reloaded.load();
      expect(reloaded.progress.unlockedLevel, 2);
    });

    test('best stars are kept on a worse replay', () {
      c.recordResult(mode: GameMode.classic, levelId: 1, result: win(stars: 3));
      final r = c.recordResult(mode: GameMode.classic, levelId: 1, result: win(stars: 1, mistakes: 4, score: 10));
      expect(c.starsFor(1), 3);
      expect(r.firstClear, isFalse);
      expect(r.newBest, isFalse);
    });

    test('spending and boosters', () {
      c.addCoins(1000);
      final coins = c.coins;
      expect(c.buyBooster(Booster.hint), isTrue);
      expect(c.coins, coins - Booster.hint.price);
      final n = c.boosterCount(Booster.hint);
      expect(c.consumeBooster(Booster.hint), isTrue);
      expect(c.boosterCount(Booster.hint), n - 1);
      expect(c.trySpend(999999), isFalse);
    });

    test('skins: buy, own, select', () {
      c.addCoins(5000);
      final fire = ArrowSkin.byId('fire');
      expect(c.buySkin(fire), isTrue);
      expect(c.ownsSkin('fire'), isTrue);
      expect(c.progress.selectedSkin, 'fire');
      expect(c.buySkin(fire), isFalse); // already owned
      c.selectSkin('classic');
      expect(c.progress.selectedSkin, 'classic');
      c.selectSkin('gold'); // not owned → ignored
      expect(c.progress.selectedSkin, 'classic');
    });

    test('daily reward: once per day, advances, resets after a missed day', () {
      expect(c.canClaimDailyReward, isTrue);
      final r1 = c.claimDailyReward()!;
      expect(r1.day, 1);
      expect(c.canClaimDailyReward, isFalse);
      expect(c.claimDailyReward(), isNull);

      now = now.add(const Duration(days: 1));
      expect(c.claimDailyReward()!.day, 2);

      now = now.add(const Duration(days: 3)); // missed days
      expect(c.claimDailyReward()!.day, 1);
    });

    test('day 5 grants the Crystal skin', () {
      for (var i = 0; i < 5; i++) {
        c.claimDailyReward();
        now = now.add(const Duration(days: 1));
      }
      expect(c.ownsSkin('crystal'), isTrue);
    });

    test('daily challenge streak and stored result', () {
      c.recordResult(mode: GameMode.daily, levelId: 0, result: win(score: 500), date: now);
      expect(c.dailyResult(now)!.score, 500);
      expect(c.progress.stats.dailyStreak, 1);
      final next = now.add(const Duration(days: 1));
      c.recordResult(mode: GameMode.daily, levelId: 0, result: win(score: 300), date: next);
      expect(c.progress.stats.dailyStreak, 2);
    });

    test('failed attempts give nothing', () {
      final coins = c.coins;
      final r = c.recordResult(
          mode: GameMode.classic,
          levelId: 1,
          result: const LevelResult(won: false, stars: 0, score: 10, moves: 3, mistakes: 3, seconds: 5, bestCombo: 0, arrowsCleared: 1));
      expect(r.coins, 0);
      expect(c.coins, coins);
      expect(c.progress.unlockedLevel, 1);
    });

    test('reset wipes progress', () async {
      c.recordResult(mode: GameMode.classic, levelId: 1, result: win());
      await c.resetProgress();
      expect(c.progress.unlockedLevel, 1);
      expect(c.progress.achievements, isEmpty);
    });
  });
}
