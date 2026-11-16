import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/extensions/context_ext.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transitions.dart';
import '../../game/levels/level_catalog.dart';
import '../../services/ads/banner_ad_widget.dart';
import '../../state/progress_controller.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/badges.dart';
import '../../widgets/buttons.dart';
import '../../widgets/pressable.dart';
import '../achievements/achievements_screen.dart';
import '../daily_challenge/daily_challenge_screen.dart';
import '../gameplay/game_launch.dart';
import '../gameplay/game_screen.dart';
import '../level_map/level_map_screen.dart';
import '../modes/modes_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../shop/shop_screen.dart';
import 'daily_reward_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _rewardChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_rewardChecked) {
      _rewardChecked = true;
      // Offer the daily login reward once the home screen has settled.
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        final p = context.progress;
        if (p.canClaimDailyReward && p.progress.tutorialDone) showDailyRewardDialog(context);
      });
    }
  }

  void _play() {
    final p = context.progress;
    final level = p.progress.tutorialDone ? p.progress.unlockedLevel.clamp(1, LevelCatalog.campaignLength) : 1;
    Navigator.of(context).push(Transitions.zoom(GameScreen(launch: GameLaunch.campaign(level))));
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    final p = progress.progress;
    final unlocked = p.unlockedLevel.clamp(1, LevelCatalog.campaignLength);
    final dailyDone = progress.dailyResult(DateTime.now()) != null;

    return Scaffold(
      body: AnimatedBackground(
        theme: progress.theme,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final s = c.uiScale;
              final compact = c.maxHeight < 700;
              return Column(
                children: [
                  // Top bar: avatar + level, coins.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Pressable(
                              onTap: () => Navigator.of(context).push(Transitions.slideFade(const ProfileScreen())),
                              semanticLabel: 'Profile',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AvatarBubble(index: p.avatar, size: 46),
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.playerName,
                                          style: AppTextStyles.subheading,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'LVL ${p.playerLevel} · ${p.totalStars} ★',
                                          style: AppTextStyles.caption,
                                          maxLines: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        CoinBadge(
                          coins: progress.coins,
                          onTap: () => Navigator.of(context).push(Transitions.slide(const ShopScreen())),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: math.min(c.maxWidth, 560),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppLogo(scale: compact ? 0.8 * s : s),
                              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl * s),
                                child: Column(
                                  children: [
                                    PrimaryButton(
                                      label: p.tutorialDone ? 'Play' : 'Start',
                                      icon: Icons.play_arrow_rounded,
                                      height: 66 * s.clamp(0.9, 1.15),
                                      pulse: true,
                                      onTap: _play,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      p.tutorialDone ? 'Level $unlocked' : 'Learn in 30 seconds',
                                      style: AppTextStyles.caption,
                                    ),
                                    SizedBox(height: compact ? AppSpacing.md : AppSpacing.lg),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MenuTile(
                                            icon: Icons.map_rounded,
                                            label: 'Level Map',
                                            onTap: () =>
                                                Navigator.of(context)
                                                    .push(Transitions.slideFade(const LevelMapScreen())),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: _MenuTile(
                                            icon: Icons.today_rounded,
                                            label: 'Daily',
                                            accent: AppColors.warning,
                                            badge: dailyDone ? null : 'NEW',
                                            onTap: () =>
                                                Navigator.of(context)
                                                    .push(Transitions.slideFade(const DailyChallengeScreen())),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: _MenuTile(
                                            icon: Icons.dashboard_customize_rounded,
                                            label: 'Modes',
                                            accent: AppColors.violet,
                                            onTap: () =>
                                                Navigator.of(context).push(Transitions.slideFade(const ModesScreen())),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bottom nav.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _NavButton(
                          icon: Icons.storefront_rounded,
                          label: 'Shop',
                          onTap: () => Navigator.of(context).push(Transitions.slide(const ShopScreen())),
                        ),
                        _NavButton(
                          icon: Icons.emoji_events_rounded,
                          label: 'Awards',
                          onTap: () => Navigator.of(context).push(Transitions.slide(const AchievementsScreen())),
                        ),
                        _NavButton(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Reward',
                          badge: progress.canClaimDailyReward,
                          onTap: () => showDailyRewardDialog(context),
                        ),
                        _NavButton(
                          icon: Icons.settings_rounded,
                          label: 'Settings',
                          onTap: () => Navigator.of(context).push(Transitions.slide(const SettingsScreen())),
                        ),
                      ],
                    ),
                  ),
                  const BannerAdWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent = AppColors.primary,
    this.badge,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 84,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppGradients.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 14, offset: Offset(0, 6))],
            ),
            padding: const EdgeInsets.all(AppSpacing.xs),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                children: [
                  Icon(icon, color: accent, size: 28),
                  const SizedBox(height: 6),
                  Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: -4,
              child: TagChip(label: badge!, color: AppColors.warning),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.onTap, this.badge = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    // Flexible so four buttons share narrow screens instead of overflowing.
    return Flexible(
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 72),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(icon, color: AppColors.textSecondary, size: 24),
                  ),
                  if (badge)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: AppTextStyles.caption, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple generated avatar: gradient disc with an arrow glyph.
class AvatarBubble extends StatelessWidget {
  const AvatarBubble({super.key, required this.index, this.size = 44});
  final int index;
  final double size;

  static const gradients = [
    AppGradients.primary,
    AppGradients.secondary,
    AppGradients.gold,
    AppGradients.success,
    AppGradients.premium,
    AppGradients.error,
  ];
  static const icons = [
    Icons.north_east_rounded,
    Icons.bolt_rounded,
    Icons.auto_awesome_rounded,
    Icons.explore_rounded,
    Icons.rocket_launch_rounded,
    Icons.favorite_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final i = index % gradients.length;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradients[i],
        border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
        boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Icon(icons[i], color: Colors.white, size: size * 0.5),
    );
  }
}
