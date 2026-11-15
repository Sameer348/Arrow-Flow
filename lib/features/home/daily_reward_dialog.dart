import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/daily_reward.dart';
import '../../state/progress_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';

Future<void> showDailyRewardDialog(BuildContext context) => showAppDialog<void>(context, (_) => const _DailyRewardDialog());

class _DailyRewardDialog extends StatelessWidget {
  const _DailyRewardDialog();

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final can = progress.canClaimDailyReward;
    final next = progress.nextRewardIndex;
    // When already claimed today, the "current" cell is the last claimed one.
    final claimedThrough = can ? next : progress.progress.dailyRewardDay;

    return AppDialog(
      title: 'Daily Reward',
      message: can ? 'Come back every day for bigger prizes.' : 'Claimed! Your next reward unlocks tomorrow.',
      icon: Icons.card_giftcard_rounded,
      iconColor: AppColors.warning,
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < DailyReward.cycle.length; i++)
            _DayCell(
              reward: DailyReward.cycle[i],
              claimed: i < claimedThrough,
              current: can && i == next,
            ),
        ],
      ),
      actions: [
        if (can)
          PrimaryButton(
            label: 'Claim',
            icon: Icons.redeem_rounded,
            pulse: true,
            gradient: AppGradients.gold,
            glowColor: AppColors.warning,
            height: 52,
            onTap: () {
              final r = progress.claimDailyReward();
              Navigator.pop(context);
              if (r != null) {
                context.services.haptics.strong();
                showRewardPopup(context, r.label, r.icon, color: AppColors.warning);
              }
            },
          )
        else
          SecondaryButton(label: 'Close', height: 48, onTap: () => Navigator.pop(context)),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.reward, required this.claimed, required this.current});
  final DailyReward reward;
  final bool claimed;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final big = reward.premium;
    final accent = big ? AppColors.violet : AppColors.warning;
    return Container(
      width: big ? 156 : 74,
      height: 84,
      decoration: BoxDecoration(
        gradient: current ? (big ? AppGradients.premium : AppGradients.gold) : null,
        color: current ? null : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: current ? Colors.transparent : (claimed ? AppColors.success.withValues(alpha: 0.4) : AppColors.glassBorder)),
        boxShadow: current ? [BoxShadow(color: accent.withValues(alpha: 0.45), blurRadius: 16)] : null,
      ),
      child: Stack(children: [
        Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('DAY ${reward.day}', style: AppTextStyles.caption.copyWith(fontSize: 10, color: current ? AppColors.background : AppColors.textMuted, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Icon(reward.icon, size: 26, color: current ? AppColors.background : (claimed ? AppColors.textMuted : accent)),
            const SizedBox(height: 2),
            Text(reward.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(fontSize: 10, color: current ? AppColors.background : AppColors.textSecondary)),
          ]),
        ),
        if (claimed)
          const Positioned(right: 4, top: 4, child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success)),
      ]),
    );
  }
}
