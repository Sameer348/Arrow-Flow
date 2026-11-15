import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../core/utils/seeded_random.dart';
import '../../models/arrow_data.dart';
import '../../models/game_mode.dart';
import '../../models/level_data.dart';
import '../board/board_state.dart';
import '../collision/collision_detector.dart';
import '../solver/puzzle_solver.dart';
import 'scoring.dart';

enum GameStatus { playing, paused, won, failed }

enum FailReason { timeUp, outOfMoves, mistake }

enum MoveOutcome { escaped, blocked, hammered, ignored }

/// What happened when the player tapped an arrow. The UI uses this to drive
/// effects; the session itself never touches rendering.
class MoveResult {
  const MoveResult(this.outcome, {this.arrow, this.check, this.points = 0, this.combo = 0, this.multiplier = 1, this.comboTierUp = false});

  const MoveResult.ignored() : this(MoveOutcome.ignored);

  final MoveOutcome outcome;
  final ArrowData? arrow;
  final MoveCheck? check;
  final int points;
  final int combo;
  final int multiplier;
  final bool comboTierUp;
}

class LevelResult {
  const LevelResult({
    required this.won,
    required this.stars,
    required this.score,
    required this.moves,
    required this.mistakes,
    required this.seconds,
    required this.bestCombo,
    required this.arrowsCleared,
    this.failReason,
  });

  final bool won;
  final int stars;
  final int score;
  final int moves;
  final int mistakes;
  final int seconds;
  final int bestCombo;
  final int arrowsCleared;
  final FailReason? failReason;

  bool get perfect => won && mistakes == 0;
}

class _UndoEntry {
  const _UndoEntry(this.arrow, this.points, this.comboBefore, this.lastEscapeBefore);
  final ArrowData arrow;
  final int points;
  final int comboBefore;
  final double lastEscapeBefore;
}

/// Authoritative game state for one level attempt (spec §68).
///
/// Holds board, arrows, score, moves, timer, combo, status, selection and
/// booster effects. Deliberately UI-agnostic: animations live in
/// [BoardEffects] and are driven by [MoveResult]s.
class GameSession extends ChangeNotifier {
  GameSession({required this.level, required this.mode})
      : board = BoardState.fromLevel(level),
        totalArrows = level.arrows.length {
    movesLeft = mode.hasMoveLimit ? level.effectiveMoveLimit : null;
    timeLimit = mode.hasTimer ? level.effectiveTimeLimit.toDouble() : null;
  }

  final LevelData level;
  final GameMode mode;
  final BoardState board;
  final int totalArrows;

  GameStatus status = GameStatus.playing;
  FailReason? failReason;
  int score = 0;
  int moves = 0;
  int mistakes = 0;
  int combo = 0;
  int bestCombo = 0;
  double elapsed = 0;
  double? timeLimit;
  int? movesLeft;
  int? selectedArrowId;
  int? hintArrowId;
  bool hammerArmed = false;
  bool usedHammer = false;
  bool usedRevive = false;
  double frozenFor = 0;
  double _lastEscapeAt = -100;
  final List<_UndoEntry> _undo = [];
  LevelResult? _result;

  int get cleared => totalArrows - board.count;
  double get progress => totalArrows == 0 ? 1 : cleared / totalArrows;
  bool get canUndo => _undo.isNotEmpty && status == GameStatus.playing;
  bool get isFrozen => frozenFor > 0;
  double? get timeRemaining => timeLimit == null ? null : math.max(0, timeLimit! - elapsed);
  int get multiplier => Scoring.comboMultiplier(combo);
  LevelResult? get result => _result;

  /// Advance the clock. Call every frame while the game screen is visible.
  void tick(double dt) {
    if (status != GameStatus.playing) return;
    if (frozenFor > 0) {
      frozenFor = math.max(0, frozenFor - dt);
      notifyListeners();
      return;
    }
    final prevSecond = elapsed.floor();
    elapsed += dt;
    if (combo > 0 && elapsed - _lastEscapeAt > Scoring.comboWindowSeconds) {
      combo = 0;
      notifyListeners();
    }
    if (timeLimit != null && elapsed >= timeLimit!) {
      _fail(FailReason.timeUp);
      return;
    }
    if (elapsed.floor() != prevSecond) notifyListeners();
  }

  MoveResult tapArrow(int id) {
    if (status != GameStatus.playing) return const MoveResult.ignored();
    final arrow = board.arrow(id);
    if (arrow == null) return const MoveResult.ignored();
    selectedArrowId = id;

    if (hammerArmed) {
      hammerArmed = false;
      usedHammer = true;
      board.remove(id);
      _undo.clear(); // hammer is final
      hintArrowId = null;
      _afterSuccessfulRemoval();
      notifyListeners();
      return MoveResult(MoveOutcome.hammered, arrow: arrow);
    }

    moves++;
    if (movesLeft != null) movesLeft = movesLeft! - 1;
    final check = CollisionDetector.check(board, arrow);

    if (!check.canMove) {
      mistakes++;
      combo = 0;
      if (mode.failsOnMistake) {
        _fail(FailReason.mistake);
      } else if (movesLeft != null && movesLeft! <= 0) {
        _fail(FailReason.outOfMoves);
      } else {
        notifyListeners();
      }
      return MoveResult(MoveOutcome.blocked, arrow: arrow, check: check);
    }

    final comboBefore = combo;
    final lastBefore = _lastEscapeAt;
    final tierBefore = Scoring.comboMultiplier(combo);
    combo++;
    bestCombo = math.max(bestCombo, combo);
    _lastEscapeAt = elapsed;
    final mult = Scoring.comboMultiplier(combo);
    final pts = Scoring.arrowPoints(arrow, mult);
    score += pts;
    board.remove(id);
    _undo.add(_UndoEntry(arrow, pts, comboBefore, lastBefore));
    if (hintArrowId == id) hintArrowId = null;
    _afterSuccessfulRemoval();
    notifyListeners();
    return MoveResult(MoveOutcome.escaped,
        arrow: arrow, check: check, points: pts, combo: combo, multiplier: mult, comboTierUp: mult > tierBefore);
  }

  void _afterSuccessfulRemoval() {
    if (board.isEmpty) {
      _win();
    } else if (movesLeft != null && movesLeft! <= 0) {
      _fail(FailReason.outOfMoves);
    } else if (hintArrowId != null && !CollisionDetector.canEscape(board, hintArrowId!)) {
      hintArrowId = null;
    }
  }

  /// Reverts the last escape. Returns the restored arrow.
  ArrowData? undo() {
    if (!canUndo) return null;
    final e = _undo.removeLast();
    board.add(e.arrow);
    score -= e.points;
    combo = e.comboBefore;
    _lastEscapeAt = e.lastEscapeBefore;
    hintArrowId = null;
    notifyListeners();
    return e.arrow;
  }

  /// Solver-backed hint. Returns the arrow id to highlight.
  int? hint() {
    if (status != GameStatus.playing) return null;
    hintArrowId = PuzzleSolver.hint(board);
    notifyListeners();
    return hintArrowId;
  }

  void armHammer(bool armed) {
    hammerArmed = armed;
    notifyListeners();
  }

  /// Flips arrows in place (same cells, opposite direction), keeping the
  /// board solvable. Each flip is verified by the solver before it is kept,
  /// so the result is always solvable. Returns the ids that changed.
  List<int> shuffle(int seed) {
    final rng = SeededRandom(seed);
    final ids = board.ids.toList()..sort();
    rng.shuffle(ids);
    final target = math.max(1, ids.length ~/ 2);
    final trial = board.clone();
    final flipped = <int>[];
    for (final id in ids) {
      final original = trial.arrow(id)!;
      trial.replace(original.flipped());
      if (PuzzleSolver.isSolvable(trial)) {
        flipped.add(id);
        if (flipped.length >= target) break;
      } else {
        trial.replace(original);
      }
    }
    if (flipped.isEmpty) return const [];
    for (final id in flipped) {
      board.replace(board.arrow(id)!.flipped());
    }
    _undo.clear();
    hintArrowId = null;
    notifyListeners();
    return flipped;
  }

  void freeze(double seconds) {
    frozenFor += seconds;
    notifyListeners();
  }

  void addMoves(int n) {
    if (movesLeft != null) movesLeft = movesLeft! + n;
    notifyListeners();
  }

  void addTime(double seconds) {
    if (timeLimit != null) timeLimit = timeLimit! + seconds;
    notifyListeners();
  }

  bool get canRevive => status == GameStatus.failed && !usedRevive;

  /// Continue after failing (rewarded revive).
  void revive() {
    if (!canRevive) return;
    usedRevive = true;
    switch (failReason) {
      case FailReason.timeUp:
        timeLimit = elapsed + 20;
      case FailReason.outOfMoves:
        movesLeft = 5;
      case FailReason.mistake || null:
        break;
    }
    failReason = null;
    _result = null;
    status = GameStatus.playing;
    notifyListeners();
  }

  void pause() {
    if (status == GameStatus.playing) {
      status = GameStatus.paused;
      notifyListeners();
    }
  }

  void resume() {
    if (status == GameStatus.paused) {
      status = GameStatus.playing;
      notifyListeners();
    }
  }

  void _win() {
    status = GameStatus.won;
    final secs = elapsed.round();
    final bonus = Scoring.speedBonus(secs, level.starRequirements.parSeconds) +
        Scoring.efficiencyBonus(mistakes, totalArrows) +
        Scoring.perfectBonus(mistakes);
    score += bonus;
    _result = LevelResult(
      won: true,
      stars: Scoring.stars(level, mistakes: mistakes, usedHammer: usedHammer),
      score: score,
      moves: moves,
      mistakes: mistakes,
      seconds: secs,
      bestCombo: bestCombo,
      arrowsCleared: cleared,
    );
  }

  void _fail(FailReason reason) {
    status = GameStatus.failed;
    failReason = reason;
    _result = LevelResult(
      won: false,
      stars: 0,
      score: score,
      moves: moves,
      mistakes: mistakes,
      seconds: elapsed.round(),
      bestCombo: bestCombo,
      arrowsCleared: cleared,
      failReason: reason,
    );
    notifyListeners();
  }
}
