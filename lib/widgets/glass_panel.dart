import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_spacing.dart';

/// Frosted glass surface. Blur is optional because it is expensive.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.blur = false,
    this.borderColor = AppColors.glassBorder,
    this.color,
    this.glow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool blur;
  final Color borderColor;
  final Color? color;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        gradient: color == null ? AppGradients.glass : null,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: glow != null ? AppShadows.glow(glow!, strength: 0.6) : null,
      ),
      child: child,
    );
    if (!blur) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: box),
    );
  }
}

/// Elevated solid card used for lists and shop items.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.highlight,
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? highlight;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppGradients.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: highlight?.withValues(alpha: 0.7) ?? AppColors.glassBorder, width: highlight != null ? 1.5 : 1),
        boxShadow: [...AppShadows.card, if (highlight != null) ...AppShadows.glow(highlight!, strength: 0.5)],
      ),
      child: child,
    );
  }
}
