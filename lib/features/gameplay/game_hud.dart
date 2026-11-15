import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../game/engine/game_session.dart';
import '../../models/level_data.dart';
import '../../widgets/badges.dart';
import '../../widgets/buttons.dart';

/// Top HUD: pause, title, progress, coins; second row: score + mode stat.
class GameHud extends StatelessWidget {
  const GameHud({super.key, required this.session, required this.title, required this.coins, required this.onPause});

  final GameSession session;
  final String title;
  final int coins;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
        child: Column(children: [
          Row(children: [
            CircleIconButton(icon: Icons.pause_rounded, semanticLabel: 'Pause', onTap: onPause),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(title, style: AppTextStyles.subheading, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  TagChip(label: session.level.difficulty.label, color: _diffColor(session.level.difficulty)),
                ]),
                const SizedBox(height: 6),
                _ProgressBar(value: session.progress),
              ]),
            ),
            const SizedBox(width: AppSpacing.sm),
            CoinBadge(coins: coins, compact: true),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Stat(label: 'SCORE', child: TweenAnimationBuilder<double>(
              tween: Tween(end: session.score.toDouble()),
              duration: const Duration(milliseconds: 350),
              builder: (_, v, _) => Text('${v.round()}', style: AppTextStyles.score),
            )),
            if (session.timeRemaining != null) _TimerPill(session: session),
            if (session.movesLeft != null)
              _Pill(
                icon: Icons.touch_app_rounded,
                text: '${session.movesLeft} moves',
                color: session.movesLeft! <= 3 ? AppColors.error : AppColors.warning,
              ),
            _Stat(
              label: 'ARROWS',
              alignEnd: true,
              child: Text('${session.board.count}', style: AppTextStyles.score.copyWith(color: AppColors.textSecondary)),
            ),
          ]),
        ]),
      ),
    );
  }

  static Color _diffColor(Difficulty d) => switch (d) {
        Difficulty.tutorial || Difficulty.easy => AppColors.success,
        Difficulty.normal => AppColors.primary,
        Difficulty.hard => AppColors.warning,
        Difficulty.expert || Difficulty.master => AppColors.violet,
      };
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progress ${(value * 100).round()} percent',
      child: Container(
        height: 7,
        decoration: BoxDecoration(color: AppColors.backgroundSecondary, borderRadius: BorderRadius.circular(6)),
        child: LayoutBuilder(
          builder: (_, c) => Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: AppDurations.slow,
              curve: Curves.easeOutCubic,
              width: c.maxWidth * value.clamp(0, 1),
              decoration: BoxDecoration(
                gradient: AppGradients.primary,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.5), blurRadius: 8)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.child, this.alignEnd = false});
  final String label;
  final Widget child;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10, letterSpacing: 1.4)), child],
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: AppDurations.normal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.subheading.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      );
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    final left = session.timeRemaining!.ceil();
    final frozen = session.isFrozen;
    final color = frozen ? const Color(0xFF7EE7FF) : (left <= 10 ? AppColors.error : AppColors.warning);
    final mm = (left ~/ 60).toString();
    final ss = (left % 60).toString().padLeft(2, '0');
    return _Pill(icon: frozen ? Icons.ac_unit_rounded : Icons.timer_rounded, text: '$mm:$ss', color: color);
  }
}

/// Center feedback: "COMBO x3" that pops when the tier changes.
class ComboBadge extends StatelessWidget {
  const ComboBadge({super.key, required this.session});
  final GameSession session;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ListenableBuilder(
        listenable: session,
        builder: (_, _) {
          final m = session.multiplier;
          return AnimatedSwitcher(
            duration: AppDurations.normal,
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: m <= 1
                ? const SizedBox(key: ValueKey(0), height: 34)
                : Container(
                    key: ValueKey(m),
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      gradient: m >= 5 ? AppGradients.gold : (m >= 3 ? AppGradients.premium : AppGradients.primary),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: (m >= 5 ? AppColors.warning : AppColors.primary).withValues(alpha: 0.5), blurRadius: 18)],
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text('COMBO x$m', style: AppTextStyles.button.copyWith(fontSize: 15, color: AppColors.background)),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
