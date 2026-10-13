import 'package:flutter/material.dart';
import '../../../widgets/clay/clay.dart';

/// Slides the navbar down 16 px and fades it in with the gentle spring.
class NavbarEntrance extends StatefulWidget {
  final Widget child;

  const NavbarEntrance({super.key, required this.child});

  @override
  State<NavbarEntrance> createState() => _NavbarEntranceState();
}

class _NavbarEntranceState extends State<NavbarEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final motion = ClayMotion.of(context);
    if (!motion.enabled) {
      _c.value = 1;
      return;
    }
    _c.springTo(1, spring: motion.gentle);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, -16 * (1 - t)), child: child),
        );
      },
    );
  }
}
