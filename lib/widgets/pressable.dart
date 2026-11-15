import 'package:flutter/material.dart';

import '../core/extensions/context_ext.dart';

/// Scales to ~0.96 on press and springs back on release, with feedback.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.pressedScale = 0.96,
    this.feedback = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool feedback;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 90),
    reverseDuration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _down(_) => _c.forward();
  void _up() => _c.reverse();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? _down : null,
        onTapCancel: enabled ? _up : null,
        onTapUp: enabled ? (_) => _up() : null,
        onTap: enabled
            ? () {
                if (widget.feedback) context.tapFeedback();
                widget.onTap!();
              }
            : null,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final t = _c.status == AnimationStatus.reverse
                ? Curves.elasticOut.transform(1 - _c.value)
                : Curves.easeOut.transform(_c.value);
            final scale = _c.status == AnimationStatus.reverse
                ? widget.pressedScale + (1 - widget.pressedScale) * t
                : 1 - (1 - widget.pressedScale) * t;
            return Transform.scale(scale: scale, child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
