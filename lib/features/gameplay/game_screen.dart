import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transitions.dart';
import '../../game/board/board_layout.dart';
import '../../game/effects/board_effects.dart';
import '../../game/engine/game_session.dart';
import '../../models/app_settings.dart';
import '../../models/booster.dart';
import '../../models/game_mode.dart';
import '../../services/analytics/analytics_service.dart';
import '../../services/audio/audio_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';
import '../settings/settings_screen.dart';
import 'board_view.dart';
import 'booster_bar.dart';
import 'game_hud.dart';
import 'game_launch.dart';
import 'overlays.dart';

enum _Overlay { none, paused, complete, failed }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.launch});
  final GameLaunch launch;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late GameLaunch _launch = widget.launch;
  late GameSession _session;
  final BoardEffects _effects = BoardEffects();
  final TransformationController _view = TransformationController();
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  _Overlay _overlay = _Overlay.none;
  LevelReward? _reward;
  double _yaw = 0;
  bool _zoomed = false;
  bool _finishing = false;

  // Tutorial
  bool _tutorial = false;
  String? _tutorialText;
  int? _tutorialArrow;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _view.addListener(() {
      final z = _view.value.getMaxScaleOnAxis() > 1.01;
      if (z != _zoomed) setState(() => _zoomed = z);
    });
    _start(_launch);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _session.dispose();
    _effects.dispose();
    _view.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ Flow

  void _start(GameLaunch launch) {
    final services = context.services;
    final level = launch.resolve(services.levels);
    _launch = launch;
    _session = GameSession(level: level, mode: launch.mode);
    _effects
      ..reset()
      ..reduceMotion = context.reduceMotion;
    _effects.particles.intensity = context.settings.graphics == GraphicsQuality.low ? 0.5 : 1;
    _overlay = _Overlay.none;
    _reward = null;
    _yaw = 0;
    _finishing = false;
    _view.value = Matrix4.identity();
    _tutorial = launch.isTutorial && !context.progress.progress.tutorialDone;
    _tutorialArrow = null;
    _tutorialText = null;
    if (_tutorial) _tutorialStep();
    services.analytics.log(
      launch.mode == GameMode.daily ? AnalyticsEvent.dailyChallengeStarted : AnalyticsEvent.levelStarted,
      {'mode': launch.mode.name, 'level': launch.index},
    );
  }

  void _restart() => setState(() {
        _session.dispose();
        _start(_launch);
      });

  void _onTick(Duration now) {
    final dt = ((now - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = now;
    if (_overlay == _Overlay.none && !_tutorial) _session.tick(dt);
    _effects.hintActive = _session.hintArrowId != null;
    _effects.update(dt);
  }

  // -------------------------------------------------------------- Tutorial

  void _tutorialStep() {
    final cleared = _session.cleared;
    final hint = _session.hint();
    setState(() {
      _tutorialArrow = hint;
      _tutorialText = switch ((_launch.index, cleared)) {
        (1, 0) => 'This arrow has a clear path.\nTap it!',
        (1, _) => 'This arrow is now free.',
        _ => 'Clear the board — free arrows first!',
      };
    });
    if (_launch.index == 2 && cleared > 0) {
      setState(() {
        _tutorialArrow = null;
        _tutorialText = null;
        _tutorial = false;
      });
    }
  }

  // ----------------------------------------------------------------- Input

  void _onArrowTap(int id) {
    if (_overlay != _Overlay.none || _finishing) return;
    final services = context.services;
    final level = _session.level;
    final layout = BoardLayout(Size.square(_boardSide), level.rows, level.cols, layers: level.layerCount);
    final res = _session.tapArrow(id);

    switch (res.outcome) {
      case MoveOutcome.escaped:
        final a = res.arrow!;
        _effects.addEscape(a, layout.escapeDistance(a));
        services.audio.escape();
        services.haptics.medium();
        final p = layout.center(a.head, layer: a.layer);
        _effects.addFloat(p, '+${res.points}', res.multiplier > 1 ? AppColors.warning : AppColors.primary, res.multiplier > 1 ? 22 : 18);
        if (res.comboTierUp) {
          services.audio.combo(res.multiplier);
          _effects.particles.burst(p, AppColors.warning, count: 10 + res.multiplier * 3, speed: 240, size: 3);
        }
        if (_tutorial && _session.status == GameStatus.playing) _tutorialStep();
      case MoveOutcome.blocked:
        _effects.addBlocked(id, res.check!.travelCells, res.check!.blockerId);
        services.audio.play(Sfx.blocked, volume: 0.5);
        services.haptics.subtle();
      case MoveOutcome.hammered:
        context.progress.consumeBooster(Booster.hammer);
        services.analytics.log(AnalyticsEvent.boosterUsed, {'booster': 'hammer'});
        _effects
          ..addShatter(res.arrow!)
          ..hammerBurst(res.arrow!);
        services.audio.play(Sfx.booster);
        services.haptics.strong();
      case MoveOutcome.ignored:
        return;
    }
    if (_session.status == GameStatus.won) _onWin();
    if (_session.status == GameStatus.failed) _onFail();
  }

  double _boardSide = 300;

  // ------------------------------------------------------------ Win / fail

  Future<void> _onWin() async {
    _finishing = true;
    final services = context.services;
    final progress = context.progress;
    final result = _session.result!;
    if (_tutorial || _launch.isTutorial) {
      if (_launch.index == 2) progress.completeTutorial();
      setState(() {
        _tutorial = false;
        _tutorialText = null;
        _tutorialArrow = null;
      });
    }
    final reward = progress.recordResult(mode: _launch.mode, levelId: _launch.index, result: result, date: _launch.date);
    services.ads.onLevelCompleted();
    services.analytics.log(
      _launch.mode == GameMode.daily ? AnalyticsEvent.dailyChallengeCompleted : AnalyticsEvent.levelCompleted,
      {'mode': _launch.mode.name, 'level': _launch.index, 'stars': result.stars, 'score': result.score},
    );
    // Let the last arrow fly before celebrating.
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    final skin = progress.skin;
    _effects.celebrate([...skin.resolveColors(progress.theme), AppColors.warning, AppColors.success]);
    services.audio.play(Sfx.levelComplete);
    services.haptics.strong();
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    setState(() {
      _reward = reward;
      _overlay = _Overlay.complete;
    });
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    for (final a in progress.takePendingUnlocks()) {
      if (!mounted) return;
      await showAchievementUnlocked(context, a);
    }
  }

  Future<void> _onFail() async {
    _finishing = true;
    final services = context.services;
    context.progress.recordResult(mode: _launch.mode, levelId: _launch.index, result: _session.result!);
    services.analytics.log(AnalyticsEvent.levelFailed, {'mode': _launch.mode.name, 'reason': _session.failReason?.name});
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;
    services.audio.play(Sfx.gameOver, volume: 0.6);
    setState(() => _overlay = _Overlay.failed);
  }

  /// Natural transition: maybe show an interstitial, then continue.
  Future<void> _transition(VoidCallback then) async {
    await context.services.ads.maybeShowInterstitial(inTutorial: _launch.isTutorial);
    if (mounted) then();
  }

  void _next() {
    final n = _launch.next;
    if (n == null) return _home();
    _transition(() => setState(() {
          _session.dispose();
          _start(n);
        }));
  }

  void _home() => _transition(() => Navigator.of(context).popUntil((r) => r.isFirst));

  Future<void> _continueAfterFail() async {
    final progress = context.progress;
    final choice = await showAppDialog<String>(
      context,
      (ctx) => AppDialog(
        title: 'Keep Going?',
        message: switch (_session.failReason) {
          FailReason.timeUp => 'Continue with +20 seconds.',
          FailReason.outOfMoves => 'Continue with +5 moves.',
          _ => 'Continue as if that tap never happened.',
        },
        icon: Icons.bolt_rounded,
        iconColor: AppColors.violet,
        actions: [
          PrimaryButton(label: 'Watch Ad', icon: Icons.play_arrow_rounded, height: 50, onTap: () => Navigator.pop(ctx, 'ad')),
          SecondaryButton(label: 'Use 100 coins', height: 46, onTap: progress.coins >= 100 ? () => Navigator.pop(ctx, 'coins') : null),
          SecondaryButton(label: 'Cancel', height: 46, onTap: () => Navigator.pop(ctx)),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    var ok = false;
    if (choice == 'coins') {
      ok = progress.trySpend(100);
    } else {
      final ads = context.services.ads;
      if (!ads.ready) {
        context.toast('No video available right now.', icon: Icons.wifi_off_rounded);
        return;
      }
      ok = await ads.showRewarded(placement: 'revive');
    }
    if (!mounted || !ok) return;
    setState(() {
      _session.revive();
      _overlay = _Overlay.none;
      _finishing = false;
    });
  }

  // -------------------------------------------------------------- Boosters

  Future<void> _useBooster(Booster b) async {
    if (_overlay != _Overlay.none || _finishing) return;
    final progress = context.progress;
    final services = context.services;

    if (b == Booster.hammer && _session.hammerArmed) {
      _session.armHammer(false);
      return;
    }
    // Pre-check so we never consume a booster that can't do anything.
    final blockedReason = switch (b) {
      Booster.undo when !_session.canUndo => 'Nothing to undo yet.',
      Booster.hint when _session.hintArrowId != null => 'Hint is already showing.',
      _ => null,
    };
    if (blockedReason != null) {
      context.toast(blockedReason, icon: b.icon, color: b.color);
      return;
    }

    if (progress.boosterCount(b) <= 0) {
      final pick = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
        builder: (_) => BoosterRefillSheet(booster: b, adAvailable: services.ads.ready),
      );
      if (!mounted || pick == null) return;
      if (pick == 'buy') {
        if (!progress.buyBooster(b)) return;
        services.audio.play(Sfx.coin);
      } else {
        _session.pause();
        final earned = await rewardedFlow(context, placement: 'booster_${b.name}', rewardLabel: '1 ${b.label}', icon: b.icon);
        _session.resume();
        if (!mounted || !earned) return;
        progress.addBooster(b);
      }
    }
    if (!mounted) return;

    if (b.needsConfirm && b != Booster.hammer) {
      _session.pause();
      final ok = await confirmDialog(context, title: 'Use ${b.label}?', message: b.description, confirmLabel: 'Use', icon: b.icon, color: b.color);
      _session.resume();
      if (!ok || !mounted) return;
    }

    var applied = true;
    switch (b) {
      case Booster.hint:
        applied = _session.hint() != null;
      case Booster.undo:
        final a = _session.undo();
        applied = a != null;
        if (a != null) _effects.addAppear(a.id);
      case Booster.hammer:
        _session.armHammer(true); // consumed when it actually smashes
        services.haptics.light();
        return;
      case Booster.shuffle:
        final ids = _session.shuffle(DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF);
        applied = ids.isNotEmpty;
        if (applied) _effects.addSpin(ids);
      case Booster.freeze:
        _session.freeze(10);
      case Booster.extraMoves:
        _session.addMoves(5);
    }
    if (!applied) {
      context.toast('That booster can\'t help right now.', icon: b.icon, color: b.color);
      return;
    }
    progress.consumeBooster(b);
    services.audio.play(Sfx.booster);
    services.haptics.light();
    services.analytics.log(b == Booster.hint ? AnalyticsEvent.hintUsed : AnalyticsEvent.boosterUsed, {'booster': b.name});
  }

  // ----------------------------------------------------------------- Build

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final settings = context.watch<SettingsController>().settings;
    final tower = _launch.mode == GameMode.tower;

    return PopScope(
      canPop: _overlay != _Overlay.none,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _overlay == _Overlay.none && !_finishing) {
          _session.pause();
          setState(() => _overlay = _Overlay.paused);
        }
      },
      child: Scaffold(
        body: AnimatedBackground(
          theme: progress.theme,
          intensity: 0.35, // background stays tertiary during play
          child: SafeArea(
            child: Stack(children: [
              Column(children: [
                GameHud(
                  session: _session,
                  title: _launch.title,
                  coins: progress.coins,
                  onPause: () {
                    if (_finishing) return;
                    _session.pause();
                    setState(() => _overlay = _Overlay.paused);
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                ComboBadge(session: _session),
                Expanded(
                  child: LayoutBuilder(builder: (context, c) {
                    _boardSide = math.min(c.maxWidth - 8, c.maxHeight);
                    return Stack(alignment: Alignment.center, children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: BoardView(
                          session: _session,
                          effects: _effects,
                          theme: progress.theme,
                          skin: progress.skin,
                          showFree: settings.showFreeArrows,
                          highQuality: settings.graphics == GraphicsQuality.high,
                          transform: _view,
                          tower: tower,
                          yaw: _yaw,
                          onYawDrag: (d) => setState(() => _yaw += d),
                          onYawDragEnd: () => setState(() => _yaw = (_yaw / (math.pi / 2)).round() * (math.pi / 2)),
                          onArrowTap: _onArrowTap,
                          tutorialArrowId: _tutorial ? _tutorialArrow : null,
                        ),
                      ),
                      if (_tutorialText != null) Positioned(top: 0, child: TutorialBubble(text: _tutorialText!)),
                      ListenableBuilder(
                        listenable: _session,
                        builder: (_, _) => _session.hammerArmed
                            ? const Positioned(top: 0, child: TutorialBubble(text: 'Tap any arrow to smash it'))
                            : const SizedBox.shrink(),
                      ),
                      if (_zoomed)
                        Positioned(
                          right: AppSpacing.md,
                          bottom: AppSpacing.xs,
                          child: CircleIconButton(
                            icon: Icons.center_focus_strong_rounded,
                            semanticLabel: 'Reset view',
                            size: 42,
                            onTap: () => _view.value = Matrix4.identity(),
                          ),
                        ),
                      if (tower)
                        Positioned(
                          bottom: AppSpacing.xs,
                          child: Row(children: [
                            CircleIconButton(icon: Icons.rotate_left_rounded, size: 42, semanticLabel: 'Rotate left',
                                onTap: () => setState(() => _yaw -= math.pi / 2)),
                            const SizedBox(width: AppSpacing.sm),
                            Text('Drag to rotate', style: AppTextStyles.caption),
                            const SizedBox(width: AppSpacing.sm),
                            CircleIconButton(icon: Icons.rotate_right_rounded, size: 42, semanticLabel: 'Rotate right',
                                onTap: () => setState(() => _yaw += math.pi / 2)),
                          ]),
                        ),
                    ]);
                  }),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListenableBuilder(
                  listenable: _session,
                  builder: (_, _) => AnimatedOpacity(
                    duration: AppDurations.normal,
                    opacity: _tutorial ? 0.25 : 1,
                    child: IgnorePointer(
                      ignoring: _tutorial,
                      child: BoosterBar(
                        mode: _launch.mode,
                        armed: _session.hammerArmed ? Booster.hammer : null,
                        onUse: _useBooster,
                      ),
                    ),
                  ),
                ),
              ]),
              if (_overlay == _Overlay.paused)
                PauseOverlay(
                  onResume: () => setState(() {
                    _overlay = _Overlay.none;
                    _session.resume();
                  }),
                  onRestart: _restart,
                  onSettings: () => Navigator.of(context).push(Transitions.slide(const SettingsScreen())),
                  onExit: () => Navigator.of(context).pop(),
                ),
              if (_overlay == _Overlay.complete && _session.result != null && _reward != null)
                LevelCompleteOverlay(
                  result: _session.result!,
                  reward: _reward!,
                  onNext: _launch.next == null ? null : _next,
                  onReplay: () => _transition(_restart),
                  onHome: _home,
                ),
              if (_overlay == _Overlay.failed && _session.result != null)
                GameOverOverlay(
                  result: _session.result!,
                  best: _launch.mode == GameMode.classic ? (progress.progress.bestScores[_launch.index] ?? 0) : 0,
                  canContinue: _session.canRevive,
                  onRetry: _restart,
                  onContinue: _continueAfterFail,
                  onHome: () => Navigator.of(context).popUntil((r) => r.isFirst),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
