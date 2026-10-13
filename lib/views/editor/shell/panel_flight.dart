import 'package:flutter/material.dart';
import '../../../widgets/clay/clay.dart';

/// One floating panel's entrance / exit state: a spring from 0 (hidden, off
/// along [direction] by [travel]) to 1 (in place), plus a skew along the
/// travel axis that follows the velocity and settles with a bounce.
class PanelFlight {
  final AnimationController progress;
  final AnimationController skew;

  /// Unit vector pointing to where the panel hides.
  final Offset direction;

  double travel = 0;
  bool fade = true;
  bool _skewEnabled = false;
  int _generation = 0;
  bool _disposed = false;

  PanelFlight({required TickerProvider vsync, required this.direction})
    : progress = AnimationController.unbounded(vsync: vsync, value: 0),
      skew = AnimationController.unbounded(vsync: vsync, value: 0) {
    progress.addListener(_trackVelocity);
  }

  bool get horizontal => direction.dx != 0;

  void _trackVelocity() {
    if (!_skewEnabled || !progress.isAnimating) return;
    // Position along the axis = -dir * travel * (1 - value), so the velocity
    // in px/s is -dir * travel * progress.velocity. Halved so a panel-sized
    // surface leans without hitting the 10° clamp on every flight.
    final axis = horizontal ? direction.dx : direction.dy;
    final v = -axis * travel * progress.velocity;
    skew.value = skewForVelocity(v * 0.5);
  }

  void fly({
    required bool show,
    required double travel,
    required bool fade,
    required ClayMotion motion,
    Duration delay = Duration.zero,
  }) {
    final gen = ++_generation;
    void start() {
      if (_disposed || gen != _generation) return;
      this.travel = travel;
      this.fade = fade;
      _skewEnabled = motion.skew;
      final target = show ? 1.0 : 0.0;
      progress.springTo(target, spring: motion.gentle).then((_) {
        if (_disposed || gen != _generation) return;
        progress.value = target;
        if (_skewEnabled) skew.springTo(0, spring: motion.bouncy);
      });
    }

    if (delay == Duration.zero) {
      start();
    } else {
      Future<void>.delayed(delay, start);
    }
  }

  void dispose() {
    _disposed = true;
    progress.removeListener(_trackVelocity);
    progress.dispose();
    skew.dispose();
  }
}

/// Paints a panel at its flight offset. Fully hidden panels are taken
/// offstage with their tickers stopped (F.6) but keep their state, so the
/// inspector remembers its collapse and scroll position across preview.
class FlyingPanel extends StatelessWidget {
  final PanelFlight flight;
  final Widget child;

  const FlyingPanel({super.key, required this.flight, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([flight.progress, flight.skew]),
      child: child,
      builder: (context, child) {
        final t = flight.progress.value;
        final hidden = !flight.progress.isAnimating && t < 0.01;
        if (hidden) {
          return Offstage(offstage: true, child: TickerMode(enabled: false, child: child!));
        }

        final remaining = 1 - t;
        final offset = Offset(
          flight.direction.dx * flight.travel * remaining,
          flight.direction.dy * flight.travel * remaining,
        );

        Widget w = child!;
        final k = flight.skew.value;
        if (k.abs() > 0.0005) {
          final m = Matrix4.identity();
          if (flight.horizontal) {
            m.setEntry(0, 1, k);
          } else {
            m.setEntry(1, 0, k);
          }
          w = Transform(transform: m, alignment: Alignment.center, child: w);
        }
        if (offset != Offset.zero) {
          w = Transform.translate(offset: offset, child: w);
        }
        if (flight.fade && t < 1) {
          w = Opacity(opacity: t.clamp(0.0, 1.0), child: w);
        }
        return IgnorePointer(ignoring: t < 0.6, child: w);
      },
    );
  }
}
