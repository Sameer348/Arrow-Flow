import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/achievement.dart';
import '../../state/progress_controller.dart';
import '../../widgets/badges.dart';
import '../../widgets/screen_scaffold.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final p = progress.progress;
    final unlocked = Achievement.all.where((a) => p.achievements.contains(a.id)).length;
    return ScreenScaffold(
      title: 'Achievements',
      child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        Row(children: [
          Text('$unlocked / ${Achievement.all.length} unlocked', style: AppTextStyles.label),
          const Spacer(),
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: unlocked / Achievement.all.length,
                minHeight: 7,
                color: AppColors.violet,
                backgroundColor: AppColors.backgroundSecondary,
              ),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < Achievement.all.length; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 250 + i * 40),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child)),
            child: _AchievementTile(achievement: Achievement.all[i], unlocked: p.achievements.contains(Achievement.all[i].id), progress: Achievement.all[i].progress(p)),
          ),
      ]),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement, required this.unlocked, required this.progress});
  final Achievement achievement;
  final bool unlocked;
  final (int, int) progress;

  @override
  Widget build(BuildContext context) {
    final (cur, goal) = progress;
    final frac = (cur / goal).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: unlocked ? AppColors.violet.withValues(alpha: 0.5) : AppColors.glassBorder),
      ),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: unlocked ? AppGradients.premium : null,
            color: unlocked ? null : AppColors.backgroundSecondary,
            boxShadow: unlocked ? [BoxShadow(color: AppColors.violet.withValues(alpha: 0.4), blurRadius: 14)] : null,
          ),
          child: Icon(achievement.icon, color: unlocked ? Colors.white : AppColors.textDisabled),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(achievement.title, style: AppTextStyles.subheading.copyWith(color: unlocked ? AppColors.textPrimary : AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(achievement.description, style: AppTextStyles.caption),
            if (!unlocked) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(value: frac, minHeight: 5, color: AppColors.primary, backgroundColor: AppColors.backgroundSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${cur.clamp(0, goal)}/$goal', style: AppTextStyles.caption.copyWith(fontSize: 11)),
              ]),
            ],
          ]),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(children: [
          if (unlocked) const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20) else const CoinIcon(size: 18),
          const SizedBox(height: 2),
          Text('${achievement.reward}', style: AppTextStyles.caption.copyWith(color: unlocked ? AppColors.textMuted : AppColors.warning)),
        ]),
      ]),
    );
  }
}
