import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/extensions/context_ext.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../models/achievement.dart';
import '../services/audio/audio_service.dart';
import 'badges.dart';
import 'buttons.dart';
import 'glass_panel.dart';

/// Blurred, scaling modal used for every dialog in the game.
Future<T?> showAppDialog<T>(BuildContext context, WidgetBuilder builder, {bool dismissible = true}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn);
      return Stack(children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: anim,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: const ColoredBox(color: AppColors.scrim),
            ),
          ),
        ),
        Center(
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(scale: Tween(begin: 0.88, end: 1.0).animate(curved), child: child),
          ),
        ),
      ]);
    },
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.iconColor = AppColors.primary,
    this.content,
    this.actions = const [],
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Color iconColor;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width - 48, 380.0);
    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: width,
        child: GlassPanel(
          color: AppColors.surface.withValues(alpha: 0.96),
          radius: AppRadius.xl,
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                  boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.3), blurRadius: 24)],
                ),
                child: Icon(icon, color: iconColor, size: 34),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(title, textAlign: TextAlign.center, style: AppTextStyles.heading),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(message!, textAlign: TextAlign.center, style: AppTextStyles.body),
            ],
            if (content != null) ...[const SizedBox(height: AppSpacing.md), content!],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              for (var i = 0; i < actions.length; i++) ...[
                actions[i],
                if (i < actions.length - 1) const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ]),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  IconData icon = Icons.help_rounded,
  Color color = AppColors.primary,
  bool destructive = false,
}) async {
  final r = await showAppDialog<bool>(
    context,
    (ctx) => AppDialog(
      title: title,
      message: message,
      icon: icon,
      iconColor: destructive ? AppColors.error : color,
      actions: [
        PrimaryButton(
          label: confirmLabel,
          height: 50,
          gradient: destructive ? AppGradients.error : AppGradients.primary,
          glowColor: destructive ? AppColors.error : AppColors.primary,
          onTap: () => Navigator.pop(ctx, true),
        ),
        SecondaryButton(label: 'Cancel', height: 46, onTap: () => Navigator.pop(ctx, false)),
      ],
    ),
  );
  return r ?? false;
}

/// "Watch a short video to get X" → Watch Ad / Cancel. Returns true only if
/// the reward callback fired.
Future<bool> rewardedFlow(
  BuildContext context, {
  required String placement,
  required String rewardLabel,
  IconData icon = Icons.play_circle_fill_rounded,
}) async {
  final watch = await showAppDialog<bool>(
    context,
    (ctx) => AppDialog(
      title: 'Free Reward',
      message: 'Watch a short video to get $rewardLabel.',
      icon: icon,
      iconColor: AppColors.violet,
      actions: [
        PrimaryButton(
          label: 'Watch Ad',
          icon: Icons.play_arrow_rounded,
          height: 50,
          gradient: AppGradients.premium,
          glowColor: AppColors.violet,
          textColor: AppColors.textPrimary,
          onTap: () => Navigator.pop(ctx, true),
        ),
        SecondaryButton(label: 'Cancel', height: 46, onTap: () => Navigator.pop(ctx, false)),
      ],
    ),
  );
  if (watch != true || !context.mounted) return false;
  final ads = context.services.ads;
  if (!ads.ready) {
    context.toast('No video available right now. Try again later.', icon: Icons.wifi_off_rounded, color: AppColors.textSecondary);
    return false;
  }
  final earned = await ads.showRewarded(placement: placement);
  if (!context.mounted) return earned;
  if (earned) {
    showRewardPopup(context, '+$rewardLabel', icon);
  } else {
    context.toast('Video not completed — no reward this time.', icon: Icons.info_rounded, color: AppColors.textSecondary);
  }
  return earned;
}

/// Small floating "+1 Hint" style popup.
void showRewardPopup(BuildContext context, String label, IconData icon, {Color color = AppColors.success}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  context.services.audio.play(Sfx.coin);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => IgnorePointer(
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1400),
          onEnd: () => entry.remove(),
          builder: (_, t, child) {
            final inK = Curves.easeOutBack.transform((t / 0.25).clamp(0, 1));
            final out = t > 0.75 ? (t - 0.75) / 0.25 : 0.0;
            return Opacity(
              opacity: (1 - out).clamp(0, 1),
              child: Transform.translate(
                offset: Offset(0, -40 * out),
                child: Transform.scale(scale: 0.6 + 0.4 * inK, child: child),
              ),
            );
          },
          child: Material(
            type: MaterialType.transparency,
            child: GlassPanel(
              color: AppColors.surfaceElevated.withValues(alpha: 0.95),
              glow: color,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Text(label, style: AppTextStyles.heading.copyWith(color: color)),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
}

/// Achievement unlock modal with an animated icon and sparkle ring.
Future<void> showAchievementUnlocked(BuildContext context, Achievement a) {
  context.services.audio.play(Sfx.unlock);
  context.services.haptics.strong();
  return showAppDialog<void>(
    context,
    (ctx) => AppDialog(
      title: 'Achievement Unlocked',
      message: a.title,
      content: Column(children: [
        _AchievementBadge(icon: a.icon),
        const SizedBox(height: AppSpacing.sm),
        Text(a.description, textAlign: TextAlign.center, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.sm),
        Row(mainAxisSize: MainAxisSize.min, children: [
          const CoinIcon(size: 20),
          const SizedBox(width: 6),
          Text('+${a.reward}', style: AppTextStyles.subheading.copyWith(color: AppColors.warning)),
        ]),
      ]),
      actions: [PrimaryButton(label: 'Awesome', height: 50, onTap: () => Navigator.pop(ctx))],
    ),
  );
}

class _AchievementBadge extends StatefulWidget {
  const _AchievementBadge({required this.icon});
  final IconData icon;

  @override
  State<_AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<_AchievementBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final pop = Curves.elasticOut.transform((_c.value / 0.6).clamp(0, 1));
          return CustomPaint(
            painter: _SparkleRing(_c.value),
            child: Center(
              child: Transform.scale(
                scale: pop,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.premium,
                    boxShadow: [BoxShadow(color: AppColors.violet.withValues(alpha: 0.6), blurRadius: 30)],
                  ),
                  child: Icon(widget.icon, size: 42, color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SparkleRing extends CustomPainter {
  _SparkleRing(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final p = Paint()..blendMode = BlendMode.plus;
    const n = 14;
    for (var i = 0; i < n; i++) {
      final a = i / n * math.pi * 2;
      final r = 30 + 45 * Curves.easeOut.transform(t);
      final alpha = (1 - t).clamp(0.0, 1.0);
      p.color = (i.isEven ? AppColors.primary : AppColors.purple).withValues(alpha: alpha);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 3 * (1 - t) + 1, p);
    }
  }

  @override
  bool shouldRepaint(_SparkleRing old) => old.t != t;
}
