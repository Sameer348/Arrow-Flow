import 'package:flutter/material.dart';

import '../core/extensions/context_ext.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'pressable.dart';

/// Primary gradient CTA with soft glow and an optional idle pulse.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.gradient = AppGradients.primary,
    this.glowColor = AppColors.primary,
    this.height = 58,
    this.pulse = false,
    this.expand = true,
    this.textColor = AppColors.background,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Gradient gradient;
  final Color glowColor;
  final double height;
  final bool pulse;
  final bool expand;
  final Color textColor;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final reduce = context.reduceMotion;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: widget.textColor, size: widget.height * 0.42),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            widget.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(color: widget.textColor, fontSize: widget.height * 0.3),
          ),
        ),
      ],
    );
    return Pressable(
      onTap: widget.onTap,
      semanticLabel: widget.label,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final v = widget.pulse && !reduce ? Curves.easeInOut.transform(_pulse.value) : 0.0;
          return Transform.scale(
            scale: 1 + v * 0.025,
            child: Opacity(
              opacity: disabled ? 0.45 : 1,
              child: Container(
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(widget.height / 2.4),
                  boxShadow: [
                    ...AppShadows.button,
                    if (!disabled) ...AppShadows.glow(widget.glowColor, strength: 0.8 + v * 0.5),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top sheen for a soft 3D feel.
                    Positioned(
                      top: 3,
                      left: 14,
                      right: 14,
                      height: widget.height * 0.36,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.height),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                    child!,
                  ],
                ),
              ),
            ),
          );
        },
        child: content,
      ),
    );
  }
}

/// Quiet glass button for secondary actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52,
    this.accent = AppColors.textPrimary,
    this.trailing,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final double height;
  final Color accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(height / 2.6),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.subheading.copyWith(color: AppColors.textPrimary)),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpacing.xs), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Round icon button used in headers and the HUD.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 46,
    this.color = AppColors.textPrimary,
    this.semanticLabel,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? semanticLabel;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface.withValues(alpha: 0.8),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: AppShadows.soft,
            ),
            child: Icon(icon, color: color, size: size * 0.48),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
