import 'package:flutter/material.dart';

import '../../core/motion/clay_motion.dart';

/// Handle for a [JellyTransform]. Create one per control, hand it to the
/// widget, then call [poke] on press, [release] on release and feed
/// [velocity] while dragging.
class JellyController {
  _JellyTransformState? _state;

  /// Squash: scaleX 1+squash, scaleY 1-squash. Pass `null` for the default.
  void poke({double? squash}) => _state?._poke(squash);

  /// Spring back to round with the jelly spring, X first, Y one frame later.
  void release() => _state?._release();

  /// Tap acknowledgement: poke then release on the next frame.
  void tap({double? squash}) => _state?._tap(squash);

  /// Feed pointer velocity (px/s) while dragging; the child skews with it.
  void velocity(double velocityX, {double velocityY = 0}) => _state?._velocity(velocityX, velocityY);

  /// Settle any skew back to zero with overshoot.
  void settle() => _state?._settle();

  /// Idle wobble: a quick rotate wobble, used for Blender rail icons on hover.
  void wobble({double radians = 0.1}) => _state?._wobble(radians);

  bool get isAttached => _state != null;
}

/// Wraps a child and wobbles it like a soft body (part F.7).
///
/// Three ingredients: out-of-phase squash and stretch on X and Y, a skew
/// proportional to velocity, and an optional surface ripple phase that is
/// forwarded to [onRipple] so a `ClayDecoration` can deform its outline.
/// Every motion is a spring on an unbounded controller, so a second poke
/// mid-wobble redirects instead of restarting.
class JellyTransform extends StatefulWidget {
  final Widget child;
  final JellyController? controller;

  /// Default squash amplitude. 0.12 = scaleX 1.12, scaleY 0.88 on poke.
  final double? squash;

  /// Release spring. Defaults to the liquid preset from [ClayMotion].
  final SpringDescription? spring;

  /// Called every frame with seconds since the last poke while the ripple is
  /// live, so a parent can forward it to `ClayDecoration.rippleTime`.
  final ValueChanged<double>? onRipple;

  /// Only used if [onRipple] is null and [surfaceRipple] is true: the ripple
  /// time is exposed through [JellyRipple] to descendants.
  final bool surfaceRipple;

  final Alignment alignment;

  const JellyTransform({
    super.key,
    required this.child,
    this.controller,
    this.squash,
    this.spring,
    this.onRipple,
    this.surfaceRipple = false,
    this.alignment = Alignment.center,
  });

  @override
  State<JellyTransform> createState() => _JellyTransformState();
}

/// Exposes the ripple time (seconds since poke, or -1) to descendants.
class JellyRipple extends InheritedWidget {
  final double time;

  const JellyRipple({super.key, required this.time, required super.child});

  static double of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<JellyRipple>()?.time ?? -1;
  }

  @override
  bool updateShouldNotify(JellyRipple oldWidget) => oldWidget.time != time;
}

class _JellyTransformState extends State<JellyTransform> with TickerProviderStateMixin {
  late final AnimationController _x;
  late final AnimationController _y;
  late final AnimationController _skewX;
  late final AnimationController _skewY;
  late final AnimationController _rot;
  late final AnimationController _ripple;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _x = AnimationController.unbounded(vsync: this, value: 1.0);
    _y = AnimationController.unbounded(vsync: this, value: 1.0);
    _skewX = AnimationController.unbounded(vsync: this, value: 0.0);
    _skewY = AnimationController.unbounded(vsync: this, value: 0.0);
    _rot = AnimationController.unbounded(vsync: this, value: 0.0);
    _ripple = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _ripple.addListener(_onRippleTick);
    _ripple.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onRipple?.call(-1);
    });
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(JellyTransform oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _x.dispose();
    _y.dispose();
    _skewX.dispose();
    _skewY.dispose();
    _rot.dispose();
    _ripple.dispose();
    super.dispose();
  }

  ClayMotion get _motion => ClayMotion.of(context);

  double get _squash => widget.squash ?? _motion.squash;
  SpringDescription get _spring => widget.spring ?? _motion.liquid;

  void _onRippleTick() {
    final t = _ripple.value * 0.7;
    widget.onRipple?.call(t);
    if (widget.surfaceRipple && widget.onRipple == null) setState(() {});
  }

  void _poke(double? squash) {
    _pressed = true;
    final s = squash ?? _squash;
    _x.springTo(1 + s, spring: _motion.snappy);
    _y.springTo(1 - s, spring: _motion.snappy);
  }

  void _release() {
    if (!_pressed && _x.value == 1 && _y.value == 1) return;
    _pressed = false;
    _x.springTo(1.0, spring: _spring);
    // One frame later, so X and Y are out of phase and the element wobbles
    // wide / tall / wide instead of pulsing.
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (mounted) _y.springTo(1.0, spring: _spring);
    });
    if (_motion.ripple && (widget.onRipple != null || widget.surfaceRipple)) {
      _ripple.forward(from: 0);
    }
  }

  void _tap(double? squash) {
    _poke(squash);
    Future<void>.delayed(const Duration(milliseconds: 60), () {
      if (mounted) _release();
    });
  }

  void _velocity(double vx, double vy) {
    if (!_motion.skew) return;
    final kx = skewForVelocity(vx);
    final ky = skewForVelocity(vy);
    _skewX.value = kx;
    _skewY.value = ky;
  }

  void _settle() {
    _skewX.springTo(0, spring: _motion.bouncy);
    _skewY.springTo(0, spring: _motion.bouncy);
  }

  void _wobble(double radians) {
    if (!_motion.enabled) return;
    _rot.springTo(radians, spring: _motion.snappy).then((_) {
      if (mounted) _rot.springTo(0, spring: _spring);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (widget.surfaceRipple && widget.onRipple == null) {
      child = JellyRipple(time: _ripple.isAnimating ? _ripple.value * 0.7 : -1, child: child);
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_x, _y, _skewX, _skewY, _rot]),
      child: child,
      builder: (context, child) {
        final m = Matrix4.identity()
          ..setEntry(0, 1, _skewX.value)
          ..setEntry(1, 0, _skewY.value);
        m.multiply(Matrix4.rotationZ(_rot.value));
        m.multiply(Matrix4.diagonal3Values(_x.value, _y.value, 1));
        return Transform(
          transform: m,
          alignment: widget.alignment,
          filterQuality: null,
          child: child,
        );
      },
    );
  }
}
