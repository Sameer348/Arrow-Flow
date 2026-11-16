import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../game/engine/game_session.dart';
import '../../services/audio/audio_service.dart';
import '../../state/progress_controller.dart';
import '../../widgets/badges.dart';
import '../../widgets/buttons.dart';
import '../../widgets/glass_panel.dart';

/// Full-screen blurred scrim + centered glass card, animated in.
class _OverlayShell extends StatelessWidget {
  const _OverlayShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Stack(children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14 * t, sigmaY: 14 * t),
            child: ColoredBox(color: AppColors.scrim.withValues(alpha: 0.7 * t)),
          ),
        ),
        Center(
          child: Opacity(
            opacity: t,
            child: Transform.scale(scale: 0.92 + 0.08 * Curves.easeOutBack.transform(t), child: child),
          ),
        ),
      ]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: LayoutBuilder(
            // Fixed design width, then scaled down as a whole if the screen
            // is too short, so nothing ever clips or overflows.
            builder: (context, c) => FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: c.maxWidth.clamp(0.0, 400.0),
                child: GlassPanel(
                  color: AppColors.surface.withValues(alpha: 0.92),
                  radius: AppRadius.xl,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({super.key, required this.onResume, required this.onRestart, required this.onSettings, required this.onExit});
  final VoidCallback onResume, onRestart, onSettings, onExit;

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.pause_circle_filled_rounded, color: AppColors.primary, size: 52),
        const SizedBox(height: AppSpacing.sm),
        const Text('Paused', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Resume', icon: Icons.play_arrow_rounded, onTap: onResume),
        const SizedBox(height: AppSpacing.sm),
        SecondaryButton(label: 'Restart', icon: Icons.replay_rounded, onTap: onRestart),
        const SizedBox(height: AppSpacing.xs),
        SecondaryButton(label: 'Settings', icon: Icons.tune_rounded, onTap: onSettings),
        const SizedBox(height: AppSpacing.xs),
        SecondaryButton(label: 'Exit', icon: Icons.home_rounded, onTap: onExit),
      ]),
    );
  }
}

/// LEVEL COMPLETE → stars one by one → stats count up → actions.
class LevelCompleteOverlay extends StatefulWidget {
  const LevelCompleteOverlay({
    super.key,
    required this.result,
    required this.reward,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
  });

  final LevelResult result;
  final LevelReward reward;
  final VoidCallback? onNext;
  final VoidCallback onReplay;
  final VoidCallback onHome;

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  int _soundedStars = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(_starSounds);
    _c.forward();
  }

  void _starSounds() {
    for (var i = _soundedStars; i < widget.result.stars; i++) {
      if (_c.value >= 0.2 + i * 0.14) {
        _soundedStars = i + 1;
        context.services.audio.play(Sfx.star, volume: 0.6 + i * 0.15);
        context.services.haptics.light();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return _OverlayShell(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = _c.value;
          double seg(double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Opacity(
              opacity: seg(0, 0.15),
              child: ShaderMask(
                shaderCallback: (rect) => AppGradients.success.createShader(rect),
                child: const Text('LEVEL COMPLETE', textAlign: TextAlign.center, style: AppTextStyles.title),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == 1 ? 14 : 0, left: 4, right: 4),
                  child: Transform.scale(
                    scale: i < r.stars ? Curves.elasticOut.transform(seg(0.2 + i * 0.14, 0.45 + i * 0.14)) : 1,
                    child: Icon(
                      Icons.star_rounded,
                      size: i == 1 ? 72 : 58,
                      color: i < r.stars ? AppColors.warning : AppColors.textDisabled,
                      shadows: i < r.stars ? [Shadow(color: AppColors.warning.withValues(alpha: 0.7), blurRadius: 24)] : null,
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: AppSpacing.md),
            Opacity(
              opacity: seg(0.6, 0.75),
              child: Column(children: [
                Text('${(r.score * Curves.easeOut.transform(seg(0.6, 0.9))).round()}', style: AppTextStyles.bigNumber),
                if (widget.reward.newBest)
                  const Padding(padding: EdgeInsets.only(top: 4), child: TagChip(label: 'New best', color: AppColors.success, icon: Icons.emoji_events_rounded)),
                const SizedBox(height: AppSpacing.md),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  _Metric(icon: Icons.touch_app_rounded, label: 'Moves', value: '${r.moves}'),
                  _Metric(icon: Icons.timer_rounded, label: 'Time', value: _fmt(r.seconds)),
                  _Metric(icon: Icons.whatshot_rounded, label: 'Best Streak', value: '${r.bestCombo}'),
                ]),
                const SizedBox(height: AppSpacing.md),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const CoinIcon(size: 24),
                  const SizedBox(width: 8),
                  Text('+${(widget.reward.coins * seg(0.7, 0.95)).round()}', style: AppTextStyles.heading.copyWith(color: AppColors.warning)),
                  if (r.perfect) ...[
                    const SizedBox(width: 12),
                    const Flexible(child: TagChip(label: 'Perfect', color: AppColors.violet, icon: Icons.verified_rounded)),
                  ],
                ]),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),
            Opacity(
              opacity: seg(0.8, 1),
              child: IgnorePointer(
                ignoring: v < 0.8,
                child: Column(children: [
                  if (widget.onNext != null)
                    PrimaryButton(label: 'Next Level', icon: Icons.arrow_forward_rounded, pulse: true, onTap: widget.onNext),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(child: SecondaryButton(label: 'Replay', icon: Icons.replay_rounded, onTap: widget.onReplay)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: SecondaryButton(label: 'Home', icon: Icons.home_rounded, onTap: widget.onHome)),
                  ]),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  static String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(height: 4),
            Text(value, style: AppTextStyles.subheading),
            Text(label, style: AppTextStyles.caption),
          ]),
        ),
      );
}

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.result,
    required this.best,
    required this.canContinue,
    required this.onRetry,
    required this.onContinue,
    required this.onHome,
  });

  final LevelResult result;
  final int best;
  final bool canContinue;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final VoidCallback onHome;

  String get _reason => switch (result.failReason) {
        FailReason.timeUp => 'The clock ran out — so close!',
        FailReason.outOfMoves => 'Out of moves. Plan a little further ahead.',
        FailReason.mistake => 'Perfect mode allows no blocked taps.',
        null => '',
      };

  @override
  Widget build(BuildContext context) {
    return _OverlayShell(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.sentiment_satisfied_alt_rounded, color: AppColors.error, size: 56),
        const SizedBox(height: AppSpacing.sm),
        const Text('Level Failed', style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.xs),
        Text(_reason, textAlign: TextAlign.center, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.md),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _Metric(icon: Icons.bar_chart_rounded, label: 'Score', value: '${result.score}'),
          _Metric(icon: Icons.emoji_events_rounded, label: 'Best', value: '$best'),
          _Metric(icon: Icons.check_rounded, label: 'Cleared', value: '${result.arrowsCleared}'),
        ]),
        const SizedBox(height: AppSpacing.lg),
        PrimaryButton(label: 'Retry', icon: Icons.replay_rounded, onTap: onRetry),
        if (canContinue) ...[
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(label: 'Use Booster · Continue', icon: Icons.bolt_rounded, accent: AppColors.violet, onTap: onContinue),
        ],
        const SizedBox(height: AppSpacing.xs),
        SecondaryButton(label: 'Home', icon: Icons.home_rounded, onTap: onHome),
      ]),
    );
  }
}

/// Speech-bubble used by the interactive tutorial.
class TutorialBubble extends StatelessWidget {
  const TutorialBubble({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedSwitcher(
        duration: AppDurations.normal,
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a), child: c),
        ),
        child: Container(
          key: ValueKey(text),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
            boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 20)],
          ),
          child: Text(text, textAlign: TextAlign.center, style: AppTextStyles.subheading),
        ),
      ),
    );
  }
}
