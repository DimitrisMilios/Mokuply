import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Spring presets. stiffness / damping / mass. Use these, never raw numbers.
class ClaySprings {
  ClaySprings._();

  /// Press, hover, toggles.
  static const snappy = SpringDescription(mass: 1, stiffness: 520, damping: 32);

  /// Release overshoot, pucks, dialogs.
  static const bouncy = SpringDescription(mass: 1, stiffness: 300, damping: 18);

  /// Leading edge of a stretching blob, jelly release.
  static const liquid = SpringDescription(mass: 1, stiffness: 180, damping: 14);

  /// Panels sliding in, page transitions.
  static const gentle = SpringDescription(mass: 1, stiffness: 160, damping: 24);

  /// No overshoot. Used when reduced motion is on.
  static const still = SpringDescription(mass: 1, stiffness: 520, damping: 60);
}

class ClayDurations {
  ClayDurations._();

  static const press = Duration(milliseconds: 90);
  static const hover = Duration(milliseconds: 140);
  static const stagger = Duration(milliseconds: 35);
  static const crossfade = Duration(milliseconds: 180);
  static const toast = Duration(seconds: 3);
}

/// Drives an AnimationController with a spring instead of a curve. Interruptible:
/// calling again mid-flight starts from the current value and velocity.
extension SpringTo on AnimationController {
  TickerFuture springTo(
    double target, {
    SpringDescription spring = ClaySprings.snappy,
    double? velocity,
  }) {
    final sim = SpringSimulation(spring, value, target, velocity ?? this.velocity);
    return animateWith(sim);
  }
}

/// A [Curve] shaped like a spring, for places that need a curve rather than a
/// controller (route transitions, `AnimatedSize`, implicit widgets).
///
/// The simulation is sampled over [settleDuration]; use that same duration
/// for the animation so the curve lands on 1.0.
class ClaySpringCurve extends Curve {
  final SpringDescription spring;
  final Duration settleDuration;
  final SpringSimulation _sim;

  ClaySpringCurve(this.spring, {this.settleDuration = const Duration(milliseconds: 500)})
      : _sim = SpringSimulation(spring, 0, 1, 0);

  static final bouncy = ClaySpringCurve(ClaySprings.bouncy);
  static final gentle = ClaySpringCurve(ClaySprings.gentle, settleDuration: const Duration(milliseconds: 450));
  static final snappy = ClaySpringCurve(ClaySprings.snappy, settleDuration: const Duration(milliseconds: 300));
  static final liquid = ClaySpringCurve(ClaySprings.liquid, settleDuration: const Duration(milliseconds: 650));

  @override
  double transformInternal(double t) {
    if (t >= 1) return 1;
    final seconds = t * settleDuration.inMicroseconds / Duration.microsecondsPerSecond;
    return _sim.x(seconds);
  }
}

/// Reduced-motion aware settings for the clay kit.
class ClayMotion {
  final bool enabled;

  const ClayMotion({required this.enabled});

  SpringDescription get snappy => enabled ? ClaySprings.snappy : ClaySprings.still;
  SpringDescription get bouncy => enabled ? ClaySprings.bouncy : ClaySprings.still;
  SpringDescription get liquid => enabled ? ClaySprings.liquid : ClaySprings.still;
  SpringDescription get gentle => enabled ? ClaySprings.gentle : ClaySprings.still;

  Duration get stagger => enabled ? ClayDurations.stagger : Duration.zero;

  /// Press squash amplitude (ingredient 1 of the jelly effect).
  double get squash => enabled ? 0.12 : 0.03;

  /// Velocity skew and surface ripple are only on with full motion.
  bool get skew => enabled;
  bool get ripple => enabled;

  Duration staggerFor(int index) => stagger * index;

  static ClayMotion of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ClayMotionScope>();
    if (scope != null) return scope.motion;
    final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ClayMotion(enabled: !disabled);
  }
}

/// Wrap the app in this. It reads `MediaQuery.disableAnimations` and exposes
/// [ClayMotion.of] so every clay control respects reduced motion.
class ClayMotionScope extends InheritedWidget {
  final ClayMotion motion;

  const ClayMotionScope({super.key, required this.motion, required super.child});

  /// Builds the scope from the ambient MediaQuery.
  static Widget fromMediaQuery({required Widget child}) {
    return Builder(
      builder: (context) {
        final disabled = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        return ClayMotionScope(motion: ClayMotion(enabled: !disabled), child: child);
      },
    );
  }

  @override
  bool updateShouldNotify(ClayMotionScope oldWidget) => oldWidget.motion.enabled != motion.enabled;
}

/// Clamp helper for the velocity skew: `skewX = clamp(v * 0.0006, -0.18, 0.18)`.
double skewForVelocity(double velocityPxPerSecond) {
  return (velocityPxPerSecond * 0.0006).clamp(-0.18, 0.18);
}

/// Damped sine used by the surface ripple: `amp * sin(t * 2π * 2.2) * e^(-4t)`.
double rippleAt(double t, {double amp = 3.0}) {
  if (t <= 0) return 0;
  return amp * math.sin(t * 2 * math.pi * 2.2) * math.exp(-4 * t);
}
