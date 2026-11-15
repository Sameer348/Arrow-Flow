import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transitions.dart';
import '../../models/game_mode.dart';
import '../../state/progress_controller.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_scaffold.dart';
import '../daily_challenge/daily_challenge_screen.dart';
import '../gameplay/game_launch.dart';
import '../gameplay/game_screen.dart';

class ModesScreen extends StatelessWidget {
  const ModesScreen({super.key});

  static const _accents = {
    GameMode.timed: AppColors.warning,
    GameMode.limitedMoves: AppColors.success,
    GameMode.perfect: AppColors.violet,
    GameMode.endless: AppColors.primary,
    GameMode.daily: AppColors.warning,
    GameMode.tower: AppColors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final modes = GameMode.values.where((m) => m != GameMode.classic).toList();
    return ScreenScaffold(
      title: 'Game Modes',
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: modes.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, i) {
          final m = modes[i];
          final accent = _accents[m] ?? AppColors.primary;
          final idx = progress.modeIndex(m);
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + i * 60),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child)),
            child: Pressable(
              semanticLabel: m.label,
              onTap: () {
                if (m == GameMode.daily) {
                  Navigator.of(context).push(Transitions.slideFade(const DailyChallengeScreen()));
                } else {
                  Navigator.of(context).push(Transitions.zoom(GameScreen(launch: GameLaunch(m, idx))));
                }
              },
              child: SurfaceCard(
                child: Row(children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: accent.withValues(alpha: 0.35)),
                    ),
                    child: Icon(m.icon, color: accent, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.label, style: AppTextStyles.subheading),
                      const SizedBox(height: 2),
                      Text(m.tagline, style: AppTextStyles.caption),
                    ]),
                  ),
                  if (m != GameMode.daily)
                    Text(m == GameMode.endless ? 'Best ${progress.progress.stats.endlessBest}' : '#${idx + 1}',
                        style: AppTextStyles.label.copyWith(color: accent)),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
