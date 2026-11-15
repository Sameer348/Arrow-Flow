import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_typography.dart';

/// Coin pill that bounces whenever the value changes.
class CoinBadge extends StatefulWidget {
  const CoinBadge({super.key, required this.coins, this.onTap, this.compact = false});
  final int coins;
  final VoidCallback? onTap;
  final bool compact;

  @override
  State<CoinBadge> createState() => _CoinBadgeState();
}

class _CoinBadgeState extends State<CoinBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void didUpdateWidget(CoinBadge old) {
    super.didUpdateWidget(old);
    if (old.coins != widget.coins) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${widget.coins} coins',
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final s = 1 + 0.18 * Curves.elasticOut.transform(_c.value) * (1 - _c.value);
            return Transform.scale(scale: s, child: child);
          },
          child: Container(
            padding: EdgeInsets.fromLTRB(5, 5, widget.compact ? 10 : 14, 5),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const CoinIcon(size: 24),
              const SizedBox(width: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(end: widget.coins.toDouble()),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => Text(
                  v.round().toString(),
                  style: AppTextStyles.subheading.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.gold,
        boxShadow: [BoxShadow(color: AppColors.warning.withValues(alpha: 0.4), blurRadius: size * 0.4)],
      ),
      alignment: Alignment.center,
      child: Icon(Icons.navigation_rounded, size: size * 0.55, color: const Color(0xFF8A4B00)),
    );
  }
}

/// 0–3 stars; optional staggered pop-in animation.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 18, this.spacing = 2, this.dimColor = AppColors.textDisabled});
  final int stars;
  final double size;
  final double spacing;
  final Color dimColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars of 3 stars',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing),
              child: Icon(
                Icons.star_rounded,
                size: size,
                color: i < stars ? AppColors.warning : dimColor,
                shadows: i < stars ? [Shadow(color: AppColors.warning.withValues(alpha: 0.6), blurRadius: size * 0.5)] : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// Small rounded chip for labels like difficulty or rarity.
class TagChip extends StatelessWidget {
  const TagChip({super.key, required this.label, this.color = AppColors.primary, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Text(label.toUpperCase(), style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w800, fontSize: 10.5)),
      ]),
    );
  }
}
