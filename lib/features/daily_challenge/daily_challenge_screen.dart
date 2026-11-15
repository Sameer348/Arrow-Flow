import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transitions.dart';
import '../../game/levels/level_catalog.dart';
import '../../models/game_mode.dart';
import '../../state/progress_controller.dart';
import '../../widgets/badges.dart';
import '../../widgets/buttons.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/screen_scaffold.dart';
import '../gameplay/game_launch.dart';
import '../gameplay/game_screen.dart';

/// Today's deterministic puzzle (seed = YYYY-MM-DD). Results are stored
/// locally; the shape of [DailyResult] is ready for an online leaderboard.
class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final today = DateTime.now();
    final level = context.services.levels.daily(today);
    final result = progress.dailyResult(today);
    final stats = progress.progress.stats;

    // Time until midnight.
    final midnight = DateTime(today.year, today.month, today.day + 1);
    final left = midnight.difference(today);

    return ScreenScaffold(
      title: 'Daily Challenge',
      child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        GlassPanel(
          glow: AppColors.warning,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            Text("TODAY'S CHALLENGE", style: AppTextStyles.caption.copyWith(letterSpacing: 2, color: AppColors.warning)),
            const SizedBox(height: AppSpacing.xs),
            Text('${_months[today.month - 1]} ${today.day}, ${today.year}', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
              TagChip(label: level.difficulty.label, color: AppColors.violet, icon: Icons.local_fire_department_rounded),
              TagChip(label: level.shape.label, color: AppColors.primary, icon: Icons.category_rounded),
              TagChip(label: '${level.arrows.length} arrows', color: AppColors.textSecondary),
              TagChip(label: '${level.effectiveTimeLimit}s', color: AppColors.warning, icon: Icons.timer_rounded),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _Info(label: 'Best Score', value: result == null ? '—' : '${result.score}'),
              _Info(label: 'Reward', value: result == null ? 'Up to 85' : 'Claimed', color: AppColors.warning),
              _Info(label: 'Streak', value: '${stats.dailyStreak} days'),
            ]),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: result == null ? 'Play' : 'Improve Score',
              icon: Icons.play_arrow_rounded,
              gradient: AppGradients.gold,
              glowColor: AppColors.warning,
              pulse: result == null,
              onTap: () => Navigator.of(context).push(Transitions.zoom(GameScreen(launch: GameLaunch(GameMode.daily, 0, date: today)))),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('New puzzle in ${left.inHours}h ${left.inMinutes % 60}m', style: AppTextStyles.caption),
          ]),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('RECENT', style: AppTextStyles.caption.copyWith(letterSpacing: 2)),
        const SizedBox(height: AppSpacing.xs),
        for (var d = 1; d <= 6; d++) _HistoryRow(date: today.subtract(Duration(days: d))),
      ]),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value, this.color = AppColors.textPrimary});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: AppTextStyles.subheading.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.caption),
      ]);
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final r = context.watch<ProgressController>().dailyResult(date);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(children: [
          Icon(r == null ? Icons.radio_button_unchecked_rounded : Icons.check_circle_rounded,
              color: r == null ? AppColors.textDisabled : AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(LevelCatalog.dailyKey(date), style: AppTextStyles.body)),
          if (r != null) ...[StarRow(stars: r.stars, size: 14), const SizedBox(width: 8), Text('${r.score}', style: AppTextStyles.label)],
          if (r == null) Text('Missed', style: AppTextStyles.caption),
        ]),
      ),
    );
  }
}
