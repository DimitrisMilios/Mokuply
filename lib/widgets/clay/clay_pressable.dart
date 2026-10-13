import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/motion/clay_motion.dart';
import 'jelly_transform.dart';

/// The pointer layer shared by every clay control: hover and press springs,
/// the jelly squash, cursor, hit testing without Material splashes.
///
/// [builder] receives `hover` and `press` in 0..1 (press may overshoot
/// slightly below 0 on release, so clamp if you lerp colours).
class ClayPressable extends StatefulWidget {
  final Widget Function(BuildContext context, double hover, double press, Widget? child) builder;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final bool enabled;

  /// Squash amplitude for the jelly. `null` uses the motion default. 0 disables.
  final double? squash;

  /// Forward the surface ripple to the builder through [JellyRipple].
  final bool surfaceRipple;

  /// Extra controller if the parent wants to poke/wobble the control itself.
  final JellyController? jelly;

  final MouseCursor cursor;
  final HitTestBehavior behavior;

  const ClayPressable({
    super.key,
    required this.builder,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.enabled = true,
    this.squash,
    this.surfaceRipple = false,
    this.jelly,
    this.cursor = SystemMouseCursors.click,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<ClayPressable> createState() => _ClayPressableState();
}

class _ClayPressableState extends State<ClayPressable> with TickerProviderStateMixin {
  late final AnimationController _hover;
  late final AnimationController _press;
  late final JellyController _ownJelly;

  JellyController get _jelly => widget.jelly ?? _ownJelly;

  @override
  void initState() {
    super.initState();
    _hover = AnimationController.unbounded(vsync: this, value: 0);
    _press = AnimationController.unbounded(vsync: this, value: 0);
    _ownJelly = JellyController();
  }

  @override
  void dispose() {
    _hover.dispose();
    _press.dispose();
    super.dispose();
  }

  ClayMotion get _motion => ClayMotion.of(context);

  bool get _interactive => widget.enabled && (widget.onTap != null || widget.onLongPress != null);

  void _onEnter(PointerEnterEvent _) {
    if (!_interactive) return;
    _hover.springTo(1, spring: _motion.snappy);
  }

  void _onExit(PointerExitEvent _) {
    _hover.springTo(0, spring: _motion.snappy);
  }

  void _down(TapDownDetails d) {
    if (!_interactive) return;
    _press.springTo(1, spring: _motion.snappy);
    if (widget.squash != 0) _jelly.poke(squash: widget.squash);
    widget.onTapDown?.call(d);
  }

  void _up() {
    if (!_interactive) return;
    _press.springTo(0, spring: _motion.bouncy);
    if (widget.squash != 0) _jelly.release();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = AnimatedBuilder(
      animation: Listenable.merge([_hover, _press]),
      child: widget.child,
      builder: (context, child) => widget.builder(context, _hover.value, _press.value, child),
    );

    if (widget.squash != 0) {
      content = JellyTransform(
        controller: _jelly,
        squash: widget.squash,
        surfaceRipple: widget.surfaceRipple,
        child: content,
      );
    }

    return MouseRegion(
      cursor: _interactive ? widget.cursor : MouseCursor.defer,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        behavior: widget.behavior,
        onTapDown: _down,
        onTapUp: (_) => _up(),
        onTapCancel: _up,
        onTap: _interactive ? widget.onTap : null,
        onLongPress: _interactive ? widget.onLongPress : null,
        child: content,
      ),
    );
  }
}
