import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../clay/clay.dart';
import 'eager_pan_detector.dart';

enum HandleCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Drag callbacks shared by every handle.
class HandleDrag {
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  const HandleDrag({required this.onStart, required this.onUpdate, required this.onEnd, required this.onCancel});
}

/// Square corner handle; dragging it scales the element about its centre.
class ResizeHandle extends StatelessWidget {
  final HandleCorner corner;

  /// Distance from the stack edge to the element box the handle sits on.
  final double inset;
  final double size;
  final bool visible;
  final Duration delay;
  final HandleDrag drag;

  const ResizeHandle({
    super.key,
    required this.corner,
    required this.inset,
    required this.size,
    required this.visible,
    required this.delay,
    required this.drag,
  });

  @override
  Widget build(BuildContext context) {
    final double edge = inset - size / 2;
    final bool top = corner == HandleCorner.topLeft || corner == HandleCorner.topRight;
    final bool left = corner == HandleCorner.topLeft || corner == HandleCorner.bottomLeft;
    final cursor = (corner == HandleCorner.topLeft || corner == HandleCorner.bottomRight)
        ? SystemMouseCursors.resizeUpLeftDownRight
        : SystemMouseCursors.resizeUpRightDownLeft;

    return Positioned(
      top: top ? edge : null,
      bottom: top ? null : edge,
      left: left ? edge : null,
      right: left ? null : edge,
      child: _HandlePop(
        visible: visible,
        delay: delay,
        child: MouseRegion(
          cursor: cursor,
          child: _drag(Container(width: size, height: size, decoration: _bead(size))),
        ),
      ),
    );
  }

  Widget _drag(Widget child) => EagerPanDetector(
    onStart: drag.onStart,
    onUpdate: drag.onUpdate,
    onEnd: drag.onEnd,
    onCancel: drag.onCancel,
    child: child,
  );
}

/// Round handle above the element on a short stem; dragging it rotates the
/// element about its centre.
class RotateHandle extends StatelessWidget {
  final double inset;
  final double size;
  final double gap;
  final bool visible;
  final Duration delay;
  final HandleDrag drag;

  const RotateHandle({
    super.key,
    required this.inset,
    required this.size,
    required this.gap,
    required this.visible,
    required this.delay,
    required this.drag,
  });

  @override
  Widget build(BuildContext context) {
    final double knob = size * 1.2;
    return Positioned(
      top: inset - gap - knob,
      left: 0,
      right: 0,
      child: _HandlePop(
        visible: visible,
        delay: delay,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: EagerPanDetector(
                onStart: drag.onStart,
                onUpdate: drag.onUpdate,
                onEnd: drag.onEnd,
                onCancel: drag.onCancel,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: _bead(size, round: true),
                  child: Icon(Icons.rotate_right_rounded, size: size * 0.75, color: AppColors.goldDeep),
                ),
              ),
            ),
            // Stem connecting the handle to the element.
            Container(width: math.max(1.0, size * 0.12), height: gap, color: AppColors.gold),
          ],
        ),
      ),
    );
  }
}

/// The handle bead: white clay with a gold rim and a soft 2 px shadow.
BoxDecoration _bead(double size, {bool round = false}) {
  return BoxDecoration(
    color: Colors.white,
    shape: round ? BoxShape.circle : BoxShape.rectangle,
    borderRadius: round ? null : BorderRadius.circular(size * 0.4),
    border: Border.all(color: AppColors.gold, width: size * 0.16),
    boxShadow: [
      BoxShadow(
        color: AppColors.clayShadow.withValues(alpha: 0.3),
        blurRadius: size * 0.2,
        offset: Offset(0, size * 0.1),
      ),
    ],
  );
}

/// Scales a handle in from 0 after [delay] (bouncy), and out together with
/// the others in 100 ms when [visible] turns false. A hidden handle ignores
/// pointers.
class _HandlePop extends StatefulWidget {
  final bool visible;
  final Duration delay;
  final Alignment alignment;
  final Widget child;

  const _HandlePop({
    required this.visible,
    required this.delay,
    this.alignment = Alignment.center,
    required this.child,
  });

  @override
  State<_HandlePop> createState() => _HandlePopState();
}

class _HandlePopState extends State<_HandlePop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.visible) _show();
  }

  @override
  void didUpdateWidget(_HandlePop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      _show();
    } else {
      _timer?.cancel();
      _timer = null;
      _c.animateTo(0, duration: const Duration(milliseconds: 100), curve: ClaySpringCurve.snappy);
    }
  }

  void _show() {
    _timer?.cancel();
    _timer = Timer(widget.delay, () {
      _timer = null;
      if (mounted) _c.springTo(1, spring: ClayMotion.of(context).bouncy);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) =>
            Transform.scale(scale: math.max(0.0, _c.value), alignment: widget.alignment, child: child),
      ),
    );
  }
}
