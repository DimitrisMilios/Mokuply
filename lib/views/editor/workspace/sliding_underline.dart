import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../widgets/clay/clay.dart';
import 'workspace_layout.dart';

/// The one gold bar under the selected tab. Its two edges are separate
/// springs: the edge facing the target leads with a bounce, the trailing edge
/// follows gently, so the bar stretches while it travels and settles round.
class SlidingUnderline extends StatefulWidget {
  final double left;
  final double right;
  final bool visible;

  const SlidingUnderline({super.key, required this.left, required this.right, required this.visible});

  @override
  State<SlidingUnderline> createState() => _SlidingUnderlineState();
}

class _SlidingUnderlineState extends State<SlidingUnderline> with TickerProviderStateMixin {
  late final AnimationController _l = AnimationController.unbounded(vsync: this, value: widget.left);
  late final AnimationController _r = AnimationController.unbounded(vsync: this, value: widget.right);

  @override
  void didUpdateWidget(SlidingUnderline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.left == widget.left && oldWidget.right == widget.right) return;
    final motion = ClayMotion.of(context);
    final bool movingRight = widget.left > oldWidget.left;
    _l.springTo(widget.left, spring: movingRight ? motion.gentle : motion.bouncy);
    _r.springTo(widget.right, spring: movingRight ? motion.bouncy : motion.gentle);
  }

  @override
  void dispose() {
    _l.dispose();
    _r.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: widget.visible ? 1 : 0,
          duration: ClayDurations.crossfade,
          child: AnimatedBuilder(
            animation: Listenable.merge([_l, _r]),
            builder: (context, _) {
              final double left = _l.value;
              final double width = math.max(0.0, _r.value - left);
              return Transform.translate(
                offset: Offset(left, 0),
                child: SizedBox(
                  width: width,
                  height: WorkspaceLayout.underlineHeight,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
