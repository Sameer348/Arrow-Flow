import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/extensions/context_ext.dart';
import '../core/theme/app_colors.dart';
import '../models/cosmetics.dart';

/// Deep gradient with slow floating light blobs, tiny arrows and motes.
/// Subtle by design; freezes when Reduce Motion is on.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key, this.theme = GameTheme.midnight, this.intensity = 1, this.child});

  final GameTheme theme;
  final double intensity;
  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: widget.theme.backgroundGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _BackgroundPainter(_c, widget.theme, widget.intensity)),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.anim, this.theme, this.intensity) : super(repaint: anim);

  final Animation<double> anim;
  final GameTheme theme;
  final double intensity;

  static final _blob = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
  static final _mote = Paint();
  static final _arrow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  static final _seeds = List.generate(18, (i) {
    final r = math.Random(i * 97 + 3);
    return (r.nextDouble(), r.nextDouble(), r.nextDouble(), r.nextInt(4));
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value * math.pi * 2;
    final accent = theme.arrowStart;

    // Ambient blobs.
    void blob(double fx, double fy, double radius, Color c, double phase) {
      final o = Offset(
        size.width * (fx + 0.06 * math.sin(t + phase)),
        size.height * (fy + 0.04 * math.cos(t * 0.8 + phase)),
      );
      _blob.color = c.withValues(alpha: 0.16 * intensity);
      canvas.drawCircle(o, radius, _blob);
    }

    blob(0.15, 0.18, size.width * 0.45, accent, 0);
    blob(0.9, 0.42, size.width * 0.38, AppColors.violet, 2);
    blob(0.35, 0.9, size.width * 0.5, theme.arrowEnd, 4);

    // Floating motes and arrows drifting upward.
    for (var i = 0; i < _seeds.length; i++) {
      final (sx, sy, sp, dirIdx) = _seeds[i];
      final y = (sy - anim.value * (0.4 + sp * 0.6)) % 1.0;
      final x = sx + 0.02 * math.sin(t * 2 + i);
      final p = Offset(x * size.width, y * size.height);
      if (i % 3 == 0) {
        final len = 8 + sp * 10;
        final angle = dirIdx * math.pi / 2 - math.pi / 2;
        _arrow
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.10 * intensity + 0.05 * math.sin(t * 3 + i).abs());
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(angle);
        canvas.drawLine(Offset(-len, 0), Offset(len * 0.6, 0), _arrow);
        canvas.drawPath(
          Path()
            ..moveTo(len * 0.1, -len * 0.45)
            ..lineTo(len * 0.7, 0)
            ..lineTo(len * 0.1, len * 0.45),
          _arrow,
        );
        canvas.restore();
      } else {
        _mote.color = Colors.white.withValues(alpha: (0.05 + 0.08 * sp) * intensity);
        canvas.drawCircle(p, 1 + sp * 1.8, _mote);
      }
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.theme != theme || old.intensity != intensity;
}
