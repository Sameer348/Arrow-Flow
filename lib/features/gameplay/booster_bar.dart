import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/booster.dart';
import '../../models/game_mode.dart';
import '../../state/progress_controller.dart';
import '../../widgets/badges.dart';
import '../../widgets/pressable.dart';

/// Bottom booster tray. Shows owned count, or a "+" when empty.
class BoosterBar extends StatelessWidget {
  const BoosterBar({super.key, required this.mode, required this.onUse, this.armed});

  final GameMode mode;
  final ValueChanged<Booster> onUse;

  /// Booster currently armed (hammer) — drawn highlighted.
  final Booster? armed;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final items = Booster.values.where((b) => b.usableIn(mode)).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final b in items)
            Flexible(
              child: _BoosterButton(
                booster: b,
                count: progress.boosterCount(b),
                armed: armed == b,
                onTap: () => onUse(b),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({required this.booster, required this.count, required this.armed, required this.onTap});
  final Booster booster;
  final int count;
  final bool armed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = booster.color;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${booster.label}, $count left',
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(clipBehavior: Clip.none, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(19),
              color: armed ? c.withValues(alpha: 0.25) : AppColors.surface,
              border: Border.all(color: armed ? c : c.withValues(alpha: 0.28), width: armed ? 2 : 1),
              boxShadow: [
                const BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4)),
                if (armed) BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 18),
              ],
            ),
            child: Icon(booster.icon, color: c, size: 27),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: count > 0
                ? Container(
                    constraints: const BoxConstraints(minWidth: 22),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.withValues(alpha: 0.6)),
                    ),
                    child: Text('$count', textAlign: TextAlign.center, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800)),
                  )
                : Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, size: 16, color: AppColors.background),
                  ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(booster.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: AppTextStyles.caption.copyWith(fontSize: 10.5)),
      ]),
    );
  }
}

/// Sheet offered when a booster is empty: buy with coins or watch an ad.
class BoosterRefillSheet extends StatelessWidget {
  const BoosterRefillSheet({super.key, required this.booster, required this.adAvailable});
  final Booster booster;
  final bool adAvailable;

  static const adBoosters = {Booster.hint, Booster.undo, Booster.extraMoves};

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<ProgressController>().coins;
    final canBuy = coins >= booster.price;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(booster.icon, size: 44, color: booster.color),
          const SizedBox(height: AppSpacing.sm),
          Text('Out of ${booster.label}', style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text(booster.description, textAlign: TextAlign.center, style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.lg),
          _SheetOption(
            icon: const CoinIcon(size: 26),
            title: 'Buy 1 for ${booster.price}',
            subtitle: canBuy ? 'You have $coins coins' : 'Not enough coins',
            enabled: canBuy,
            onTap: () => Navigator.pop(context, 'buy'),
          ),
          if (adBoosters.contains(booster)) ...[
            const SizedBox(height: AppSpacing.sm),
            _SheetOption(
              icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.violet, size: 28),
              title: 'Watch a video',
              subtitle: adAvailable ? 'Get 1 free' : 'No video available offline',
              enabled: adAvailable,
              onTap: () => Navigator.pop(context, 'ad'),
            ),
          ],
        ]),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({required this.icon, required this.title, required this.subtitle, required this.enabled, required this.onTap});
  final Widget icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(children: [
            icon,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.subheading),
                Text(subtitle, style: AppTextStyles.caption),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ]),
        ),
      ),
    );
  }
}
