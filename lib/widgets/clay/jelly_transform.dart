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
  // Controllers are created on first use: most controls are never poked,
  // and six controllers per control add up to hundreds of tickers in the
  // editor. [_tick] relays their frames to the builder.
  final _Tick _tick = _Tick();
  AnimationController? _x;
  AnimationController? _y;
  AnimationController? _skewX;
  AnimationController? _skewY;
  AnimationController? _rot;
  AnimationController? _rippleController;

  bool _pressed = false;

  AnimationController _spring(double value) =>
      AnimationController.unbounded(vsync: this, value: value)..addListener(_tick.ping);

  AnimationController get _scaleX => _x ??= _spring(1.0);
  AnimationController get _scaleY => _y ??= _spring(1.0);
  AnimationController get _skewXc => _skewX ??= _spring(0.0);
  AnimationController get _skewYc => _skewY ??= _spring(0.0);
  AnimationController get _rotation => _rot ??= _spring(0.0);
  AnimationController get _ripple =>
      _rippleController ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..addListener(_onRippleTick)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) widget.onRipple?.call(-1);
        });

  @override
  void initState() {
    super.initState();
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
    for (final c in [_x, _y, _skewX, _skewY, _rot, _rippleController]) {
      c?.dispose();
    }
    _tick.dispose();
    super.dispose();
  }

  ClayMotion get _motion => ClayMotion.of(context);

  double get _squash => widget.squash ?? _motion.squash;
  SpringDescription get _releaseSpring => widget.spring ?? _motion.liquid;

  void _onRippleTick() {
    final t = _ripple.value * 0.7;
    widget.onRipple?.call(t);
    if (widget.surfaceRipple && widget.onRipple == null) setState(() {});
  }

  void _poke(double? squash) {
    _pressed = true;
    final s = squash ?? _squash;
    _scaleX.springTo(1 + s, spring: _motion.snappy);
    _scaleY.springTo(1 - s, spring: _motion.snappy);
  }

  void _release() {
    if (!_pressed && (_x?.value ?? 1) == 1 && (_y?.value ?? 1) == 1) return;
    _pressed = false;
    _scaleX.springTo(1.0, spring: _releaseSpring);
    // One frame later, so X and Y are out of phase and the element wobbles
    // wide / tall / wide instead of pulsing.
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (mounted) _scaleY.springTo(1.0, spring: _releaseSpring);
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
    _skewXc.value = skewForVelocity(vx);
    _skewYc.value = skewForVelocity(vy);
  }

  void _settle() {
    // Nothing to settle if no drag ever skewed this control.
    if (_skewX == null && _skewY == null) return;
    _skewXc.springTo(0, spring: _motion.bouncy);
    _skewYc.springTo(0, spring: _motion.bouncy);
  }

  void _wobble(double radians) {
    if (!_motion.enabled) return;
    _rotation.springTo(radians, spring: _motion.snappy).then((_) {
      if (mounted) _rotation.springTo(0, spring: _releaseSpring);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;
    if (widget.surfaceRipple && widget.onRipple == null) {
      final ripple = _rippleController;
      child = JellyRipple(time: ripple != null && ripple.isAnimating ? ripple.value * 0.7 : -1, child: child);
    }
    return AnimatedBuilder(
      animation: _tick,
      child: child,
      builder: (context, child) {
        final m = Matrix4.identity()
          ..setEntry(0, 1, _skewX?.value ?? 0)
          ..setEntry(1, 0, _skewY?.value ?? 0);
        final rot = _rot?.value ?? 0;
        if (rot != 0) m.multiply(Matrix4.rotationZ(rot));
        m.multiply(Matrix4.diagonal3Values(_x?.value ?? 1, _y?.value ?? 1, 1));
        return Transform(transform: m, alignment: widget.alignment, filterQuality: null, child: child);
      },
    );
  }
}

/// Relays controller frames to the builder without merging listenables.
class _Tick extends ChangeNotifier {
  void ping() => notifyListeners();
}
