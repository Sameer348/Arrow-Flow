import 'package:flutter/material.dart';

import '../core/constants/app_info.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_gradients.dart';
import '../core/theme/app_typography.dart';

/// Original wordmark: an arrow glyph escaping a rounded tile + gradient title.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.scale = 1});
  final double scale;

  @override
  Widget build(BuildContext context) {
    final words = AppInfo.name.split(' ');
    return Semantics(
      label: AppInfo.shortName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 92 * scale, height: 92 * scale, child: CustomPaint(painter: LogoMarkPainter())),
          SizedBox(height: 18 * scale),
          ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [AppColors.textPrimary, Color(0xFFD9F9FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(r),
            child: Text(words.first, style: AppTextStyles.logo.copyWith(fontSize: 46 * scale)),
          ),
          if (words.length > 1)
            ShaderMask(
              shaderCallback: (r) => AppGradients.primary.createShader(r),
              child: Text(
                words.sublist(1).join(' '),
                style: AppTextStyles.logo.copyWith(
                  fontSize: 46 * scale,
                  letterSpacing: 10 * scale,
                  shadows: [Shadow(color: AppColors.primary.withValues(alpha: 0.6), blurRadius: 24)],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// App mark: tilted tile with a cyan arrow breaking out of the corner.
class LogoMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final tile = RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.06, s * 0.14, s * 0.72, s * 0.72), Radius.circular(s * 0.2));
    canvas.drawRRect(tile.shift(Offset(0, s * 0.05)), Paint()..color = Colors.black.withValues(alpha: 0.35)..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06));
    canvas.drawRRect(
        tile,
        Paint()
          ..shader = const LinearGradient(colors: [AppColors.surfaceElevated, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight)
              .createShader(tile.outerRect));
    canvas.drawRRect(tile, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.white.withValues(alpha: 0.14));

    // Grid dots.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.12);
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        canvas.drawCircle(Offset(s * (0.2 + c * 0.22), s * (0.28 + r * 0.22)), s * 0.025, dot);
      }
    }

    // Escaping arrow (diagonal, up-right).
    final from = Offset(s * 0.22, s * 0.72);
    final to = Offset(s * 0.84, s * 0.10);
    final glow = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.55)
      ..strokeWidth = s * 0.16
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.08);
    canvas.drawLine(from, to - Offset(s * 0.08, -s * 0.08), glow);
    final body = Paint()
      ..shader = const LinearGradient(colors: [AppColors.secondary, AppColors.primary]).createShader(Rect.fromPoints(from, to))
      ..strokeWidth = s * 0.11
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to - Offset(s * 0.1, -s * 0.1), body);
    final head = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(to.dx - s * 0.32, to.dy + s * 0.04)
      ..lineTo(to.dx - s * 0.04, to.dy + s * 0.32)
      ..close();
    canvas.drawPath(head, Paint()..color = AppColors.primary..strokeJoin = StrokeJoin.round);
    canvas.drawPath(head, Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = s * 0.03..strokeJoin = StrokeJoin.round);
    // Trail sparks.
    final spark = Paint()..color = Colors.white.withValues(alpha: 0.8);
    canvas.drawCircle(Offset(s * 0.12, s * 0.86), s * 0.025, spark);
    canvas.drawCircle(Offset(s * 0.06, s * 0.76), s * 0.016, spark..color = AppColors.primary.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
