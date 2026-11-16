import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/achievement.dart';
import '../../state/progress_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/glass_panel.dart';
import '../../widgets/pressable.dart';
import '../../widgets/screen_scaffold.dart';
import '../home/home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _edit(BuildContext context) async {
    final progress = context.progress;
    final ctrl = TextEditingController(text: progress.progress.playerName);
    var avatar = progress.progress.avatar;
    await showAppDialog<void>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AppDialog(
          title: 'Edit Profile',
          content: Column(children: [
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              for (var i = 0; i < AvatarBubble.gradients.length; i++)
                Pressable(
                  onTap: () => setState(() => avatar = i),
                  semanticLabel: 'Avatar ${i + 1}',
                  child: AnimatedContainer(
                    duration: AppDurations.fast,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: avatar == i ? AppColors.primary : Colors.transparent, width: 2),
                    ),
                    child: AvatarBubble(index: i, size: 50),
                  ),
                ),
            ]),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: ctrl,
              maxLength: 16,
              textAlign: TextAlign.center,
              style: AppTextStyles.subheading,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Your name',
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
              ),
            ),
          ]),
          actions: [
            PrimaryButton(
              label: 'Save',
              height: 50,
              onTap: () {
                progress.setProfile(name: ctrl.text, avatar: avatar);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProgressController>().progress;
    final s = p.stats;
    final stats = <(IconData, String, String, Color)>[
      (Icons.star_rounded, 'Stars', '${p.totalStars}', AppColors.warning),
      (Icons.monetization_on_rounded, 'Coins', '${p.coins}', AppColors.warning),
      (Icons.flag_rounded, 'Levels', '${s.levelsCompleted}', AppColors.primary),
      (Icons.verified_rounded, 'Perfect', '${s.perfectLevels}', AppColors.violet),
      (Icons.whatshot_rounded, 'Best Combo', 'x${s.bestCombo}', AppColors.error),
      (Icons.north_east_rounded, 'Arrows', '${s.arrowsCleared}', AppColors.success),
      (Icons.emoji_events_rounded, 'Awards', '${p.achievements.length}/${Achievement.all.length}', AppColors.purple),
      (Icons.today_rounded, 'Dailies', '${s.dailyCompleted}', AppColors.warning),
    ];
    return ScreenScaffold(
      title: 'Profile',
      child: ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [
        GlassPanel(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            AvatarBubble(index: p.avatar, size: 92),
            const SizedBox(height: AppSpacing.sm),
            Text(p.playerName, style: AppTextStyles.title),
            const SizedBox(height: 4),
            Text('Player Level ${p.playerLevel} · ${s.totalScore} pts', style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.md),
            SecondaryButton(label: 'Edit Profile', icon: Icons.edit_rounded, height: 44, onTap: () => _edit(context)),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth > 520 ? 4 : 2;
          return GridView.count(
            crossAxisCount: cols,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.9,
            children: [
              for (final (icon, label, value, color) in stats)
                SurfaceCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(children: [
                    Icon(icon, color: color, size: 26),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(value, style: AppTextStyles.heading),
                          Text(label, style: AppTextStyles.caption),
                        ]),
                      ),
                    ),
                  ]),
                ),
            ],
          );
        }),
      ]),
    );
  }
}
