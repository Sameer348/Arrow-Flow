import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../game/board/board_layout.dart';
import '../../game/board/board_painter.dart';
import '../../game/effects/board_effects.dart';
import '../../game/engine/game_session.dart';
import '../../models/cosmetics.dart';

/// Interactive board: pinch-zoom / pan (large boards), tap-to-escape, and
/// the 2.5D tilted view for Tower mode. Taps are mapped through every
/// transform automatically because the GestureDetector sits *inside* them.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.session,
    required this.effects,
    required this.theme,
    required this.skin,
    required this.showFree,
    required this.onArrowTap,
    required this.transform,
    this.tower = false,
    this.yaw = 0,
    this.onYawDrag,
    this.onYawDragEnd,
    this.highQuality = true,
    this.tutorialArrowId,
  });

  final GameSession session;
  final BoardEffects effects;
  final GameTheme theme;
  final ArrowSkin skin;
  final bool showFree;
  final ValueChanged<int> onArrowTap;
  final TransformationController transform;
  final bool tower;
  final double yaw;
  final ValueChanged<double>? onYawDrag;
  final VoidCallback? onYawDragEnd;
  final bool highQuality;
  final int? tutorialArrowId;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  Size _size = Size.zero;

  void _tap(TapUpDetails d) {
    final level = widget.session.level;
    final layout = BoardLayout(_size, level.rows, level.cols, layers: level.layerCount);
    final id = layout.hitTest(d.localPosition, widget.session.board);
    if (id != null) widget.onArrowTap(id);
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.session.level;
    final zoomable = !widget.tower && level.gridSize >= 7;
    return LayoutBuilder(builder: (context, c) {
      final side = math.min(c.maxWidth, c.maxHeight);
      _size = Size(side, side);

      Widget board = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: _tap,
        child: RepaintBoundary(
          child: CustomPaint(
            size: _size,
            isComplex: true,
            willChange: true,
            painter: BoardPainter(
              session: widget.session,
              effects: widget.effects,
              theme: widget.theme,
              skin: widget.skin,
              showFree: widget.showFree,
              extrude: widget.tower,
              highQuality: widget.highQuality,
            ),
            child: SizedBox.fromSize(
              size: _size,
              child: widget.tutorialArrowId == null ? null : _TutorialFinger(session: widget.session, arrowId: widget.tutorialArrowId!, size: _size),
            ),
          ),
        ),
      );

      if (widget.tower) {
        // Perspective tilt + yaw rotation. Drag horizontally to rotate.
        board = GestureDetector(
          onHorizontalDragUpdate: (d) => widget.onYawDrag?.call(d.delta.dx / side * math.pi),
          onHorizontalDragEnd: (_) => widget.onYawDragEnd?.call(),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: widget.yaw),
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            builder: (_, yaw, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0011)
                ..rotateX(0.62)
                ..rotateZ(yaw)
                ..scaleByDouble(0.86, 0.86, 0.86, 1),
              child: child,
            ),
            child: board,
          ),
        );
      }

      return Center(
        child: SizedBox.fromSize(
          size: _size,
          child: InteractiveViewer(
            transformationController: widget.transform,
            panEnabled: zoomable,
            scaleEnabled: zoomable,
            minScale: 1,
            maxScale: 3,
            boundaryMargin: const EdgeInsets.all(40),
            clipBehavior: Clip.none,
            child: board,
          ),
        ),
      );
    });
  }
}

/// Animated pointing finger used by the interactive tutorial.
class _TutorialFinger extends StatefulWidget {
  const _TutorialFinger({required this.session, required this.arrowId, required this.size});
  final GameSession session;
  final int arrowId;
  final Size size;

  @override
  State<_TutorialFinger> createState() => _TutorialFingerState();
}

class _TutorialFingerState extends State<_TutorialFinger> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.session.board.arrow(widget.arrowId);
    if (a == null) return const SizedBox.shrink();
    final level = widget.session.level;
    final l = BoardLayout(widget.size, level.rows, level.cols, layers: level.layerCount);
    final p = l.center(a.head);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          final press = t < 0.5 ? Curves.easeInOut.transform(t * 2) : 1 - Curves.easeInOut.transform((t - 0.5) * 2);
          return Stack(children: [
            Positioned(
              left: p.dx - l.cell * 0.5,
              top: p.dy - l.cell * 0.5,
              width: l.cell,
              height: l.cell,
              child: Opacity(
                opacity: (1 - t),
                child: Transform.scale(
                  scale: 0.5 + t,
                  child: DecoratedBox(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                  ),
                ),
              ),
            ),
            Positioned(
              left: p.dx - 6,
              top: p.dy + 6 + press * 8,
              child: Icon(Icons.touch_app_rounded, size: 44, color: Colors.white,
                  shadows: [Shadow(color: AppColors.primary.withValues(alpha: 0.8), blurRadius: 16)]),
            ),
          ]);
        },
      ),
    );
  }
}
