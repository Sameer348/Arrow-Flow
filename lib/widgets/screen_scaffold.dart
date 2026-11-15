import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../services/ads/banner_ad_widget.dart';
import '../state/progress_controller.dart';
import 'animated_background.dart';
import 'badges.dart';
import 'buttons.dart';

/// Shared chrome for menu screens: themed background, header with back +
/// title + coins, optional banner ad at the bottom.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showCoins = true,
    this.showBanner = false,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final bool showCoins;
  final bool showBanner;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();
    return Scaffold(
      body: AnimatedBackground(
        theme: progress.theme,
        intensity: 0.6,
        child: SafeArea(
          bottom: !showBanner,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
                child: Row(children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(title, style: AppTextStyles.heading, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ...actions,
                  if (showCoins) CoinBadge(coins: progress.coins),
                ]),
              ),
              Expanded(child: child),
              if (showBanner) const BannerAdWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
