import 'dart:ui';

import '../../core/theme/app_colors.dart';
import '../../models/direction.dart';

/// Draws one dimensional arrow: soft shadow, optional glow, gradient body,
/// arrow head and a specular highlight. Paints are reused across calls.
class ArrowRenderer {
  final Paint _shadow = Paint()..color = const Color(0x73000000);
  final Paint _glow = Paint();
  final Paint _body = Paint()..isAntiAlias = true;
  final Paint _highlight = Paint()..color = const Color(0x59FFFFFF);
  final Paint _side = Paint();
  final Paint _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round;
  final Path _path = Path();

  bool highQuality = true;

  /// Builds the arrow outline in local space: +x = direction, origin at the
  /// head cell centre.
  Path _build(int length, double cell) {
    final tailX = -(length - 1) * cell - cell * 0.30;
    final hw = cell * 0.165;
    _path
      ..reset()
      ..addRRect(RRect.fromLTRBR(tailX, -hw, cell * 0.04, hw, Radius.circular(hw)));
    final bw = cell * 0.34;
    final baseX = -cell * 0.10;
    final tipX = cell * 0.40;
    final r = cell * 0.05;
    // Head with softly rounded corners.
    _path
      ..moveTo(baseX, -bw + r)
      ..quadraticBezierTo(baseX, -bw, baseX + r, -bw + r * 0.6)
      ..lineTo(tipX - r, -r * 0.8)
      ..quadraticBezierTo(tipX, 0, tipX - r, r * 0.8)
      ..lineTo(baseX + r, bw - r * 0.6)
      ..quadraticBezierTo(baseX, bw, baseX, bw - r)
      ..close();
    return _path;
  }

  void draw(
    Canvas canvas, {
    required Offset head,
    required Direction direction,
    required int length,
    required double cell,
    required List<Color> colors,
    Color? glowColor,
    double glow = 0,
    double alpha = 1,
    double scale = 1,
    double rotation = 0,
    double desaturate = 0,
    Color? tint,
    double tintAmount = 0,
    double extrude = 0,
    double outline = 0,
    Color outlineColor = AppColors.error,
  }) {
    if (alpha <= 0.01) return;
    final angle = direction.angle + rotation;
    final mid = -(length - 1) * cell / 2;
    final path = _build(length, cell);

    void transform(Offset at) {
      canvas
        ..translate(at.dx, at.dy)
        ..rotate(angle)
        ..translate(mid, 0)
        ..scale(scale)
        ..translate(-mid, 0);
    }

    final cols = <Color>[
      for (final c in colors)
        _mix(_mix(c, AppColors.arrowBlocked, desaturate), tint ?? c, tintAmount).withValues(alpha: alpha),
    ];

    // 1. Shadow (screen-space down).
    canvas.save();
    transform(head + Offset(0, cell * 0.07 + extrude));
    _shadow
      ..color = Color.fromRGBO(0, 0, 0, 0.42 * alpha)
      ..maskFilter = highQuality ? MaskFilter.blur(BlurStyle.normal, cell * 0.05) : null;
    canvas.drawPath(path, _shadow);
    canvas.restore();

    // 2. Extrusion for 2.5D (darker side faces).
    if (extrude > 0) {
      _side.color = _mix(cols.last, const Color(0xFF000000), 0.55).withValues(alpha: alpha);
      final steps = (extrude / 1.5).ceil().clamp(1, 8);
      for (var i = steps; i >= 1; i--) {
        canvas.save();
        transform(head + Offset(0, extrude * i / steps));
        canvas.drawPath(path, _side);
        canvas.restore();
      }
    }

    canvas.save();
    transform(head);

    // 3. Glow.
    if (glow > 0) {
      _glow
        ..color = (glowColor ?? cols.first).withValues(alpha: 0.55 * glow * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * (highQuality ? 0.16 : 0.08));
      canvas.drawPath(path, _glow);
    }

    // 4. Body gradient along the arrow.
    final tail = -(length - 1) * cell - cell * 0.3;
    _body.shader = Gradient.linear(
      Offset(tail, 0),
      Offset(cell * 0.4, 0),
      cols.length >= 2 ? cols : [cols.first, cols.first],
      cols.length > 2 ? [for (var i = 0; i < cols.length; i++) i / (cols.length - 1)] : null,
    );
    canvas.drawPath(path, _body);
    _body.shader = null;

    // 5. Specular highlight on the top edge of the shaft.
    _highlight.color = Color.fromRGBO(255, 255, 255, 0.32 * alpha * (1 - desaturate * 0.6));
    final hw = cell * 0.165;
    canvas.drawRRect(
      RRect.fromLTRBR(tail + hw * 0.6, -hw * 0.72, -cell * 0.14, -hw * 0.3, Radius.circular(hw)),
      _highlight,
    );

    // 6. Optional outline (blocker flash / selection).
    if (outline > 0) {
      _outline
        ..color = outlineColor.withValues(alpha: outline * alpha)
        ..strokeWidth = cell * 0.06
        ..maskFilter = null;
      canvas.drawPath(path, _outline);
    }
    canvas.restore();
  }

  static Color _mix(Color a, Color b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return Color.lerp(a, b, t)!;
  }
}
