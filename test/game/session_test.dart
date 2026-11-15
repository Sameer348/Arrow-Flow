import 'package:arrow_flow/game/collision/collision_detector.dart';
import 'package:arrow_flow/game/engine/game_session.dart';
import 'package:arrow_flow/game/levels/curated_levels.dart';
import 'package:arrow_flow/game/levels/level_catalog.dart';
import 'package:arrow_flow/game/solver/puzzle_solver.dart';
import 'package:arrow_flow/models/game_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  GameSession classic([int n = 2]) => GameSession(level: CuratedLevels.level(n), mode: GameMode.classic);

  int blockedId(GameSession s) => s.board.ids.firstWhere((id) => !CollisionDetector.canEscape(s.board, id));

  test('tapping a free arrow removes it and scores', () {
    final s = classic();
    final id = PuzzleSolver.legalMoves(s.board).first;
    final r = s.tapArrow(id);
    expect(r.outcome, MoveOutcome.escaped);
    expect(s.board.contains(id), isFalse);
    expect(s.score, greaterThan(0));
    expect(s.moves, 1);
  });

  test('tapping a blocked arrow is a mistake and changes nothing else', () {
    final s = classic();
    final id = blockedId(s);
    final r = s.tapArrow(id);
    expect(r.outcome, MoveOutcome.blocked);
    expect(r.check!.blockerId, isNotNull);
    expect(s.board.contains(id), isTrue);
    expect(s.mistakes, 1);
    expect(s.combo, 0);
  });

  test('playing the solver order wins with 3 stars', () {
    final s = classic(30);
    for (final id in PuzzleSolver.solve(s.board).order) {
      s.tapArrow(id);
    }
    expect(s.status, GameStatus.won);
    expect(s.result!.stars, 3);
    expect(s.result!.perfect, isTrue);
  });

  test('combo multiplier grows with consecutive escapes', () {
    final s = classic(30);
    final order = PuzzleSolver.solve(s.board).order;
    for (final id in order.take(5)) {
      s.tapArrow(id);
    }
    expect(s.combo, 5);
    expect(s.multiplier, 3);
    s.tick(6); // combo window expires
    expect(s.combo, 0);
  });

  test('undo restores the arrow, score and combo', () {
    final s = classic();
    final id = PuzzleSolver.legalMoves(s.board).first;
    s.tapArrow(id);
    expect(s.canUndo, isTrue);
    final restored = s.undo();
    expect(restored!.id, id);
    expect(s.board.contains(id), isTrue);
    expect(s.score, 0);
    expect(s.combo, 0);
    expect(s.canUndo, isFalse);
  });

  test('hint always points at a legal move and survives a full playthrough', () {
    final s = classic(40);
    while (s.status == GameStatus.playing) {
      final h = s.hint();
      expect(h, isNotNull);
      expect(CollisionDetector.canEscape(s.board, h!), isTrue);
      s.tapArrow(h);
    }
    expect(s.status, GameStatus.won);
  });

  test('hammer removes a blocked arrow', () {
    final s = classic();
    final id = blockedId(s);
    s.armHammer(true);
    final r = s.tapArrow(id);
    expect(r.outcome, MoveOutcome.hammered);
    expect(s.board.contains(id), isFalse);
    expect(s.usedHammer, isTrue);
  });

  test('shuffle keeps the board solvable and changes it', () {
    final s = classic(36);
    final before = s.board.arrows.map((a) => a.encode()).toSet();
    final changed = s.shuffle(99);
    expect(changed, isNotEmpty);
    expect(s.board.arrows.map((a) => a.encode()).toSet(), isNot(before));
    expect(PuzzleSolver.isSolvable(s.board), isTrue);
  });

  test('perfect mode fails on the first mistake; revive continues once', () {
    final s = GameSession(level: CuratedLevels.level(10), mode: GameMode.perfect);
    s.tapArrow(blockedId(s));
    expect(s.status, GameStatus.failed);
    expect(s.failReason, FailReason.mistake);
    expect(s.canRevive, isTrue);
    s.revive();
    expect(s.status, GameStatus.playing);
    expect(s.canRevive, isFalse);
  });

  test('timed mode fails when the clock runs out; freeze pauses it', () {
    final s = GameSession(level: LevelCatalog().challenge('timed', 0), mode: GameMode.timed);
    final limit = s.timeLimit!;
    s.freeze(10);
    s.tick(5);
    expect(s.elapsed, 0);
    s.tick(5);
    s.tick(limit - 1);
    expect(s.status, GameStatus.playing);
    s.tick(2);
    expect(s.status, GameStatus.failed);
    expect(s.failReason, FailReason.timeUp);
  });

  test('limited moves mode fails when moves run out; extra moves help', () {
    final s = GameSession(level: CuratedLevels.level(20), mode: GameMode.limitedMoves);
    final blocked = blockedId(s);
    s.addMoves(2);
    final allowed = s.movesLeft!;
    for (var i = 0; i < allowed; i++) {
      s.tapArrow(blocked);
    }
    expect(s.status, GameStatus.failed);
    expect(s.failReason, FailReason.outOfMoves);
  });

  test('paused sessions ignore taps and time', () {
    final s = classic();
    s.pause();
    expect(s.tapArrow(PuzzleSolver.legalMoves(s.board).first).outcome, MoveOutcome.ignored);
    s.tick(5);
    expect(s.elapsed, 0);
  });
}
