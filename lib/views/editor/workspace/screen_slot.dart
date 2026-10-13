import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import '../../../widgets/clay/clay.dart';

/// One slot of the strip (a tab or a card). A new slot grows in from width 0
/// with a bounce; a leaving slot fades, shrinks to 0.9 and collapses so its
/// neighbours close the gap gently.
class ScreenSlot extends StatefulWidget {
  final double width;
  final bool enter;
  final bool leaving;
  final Widget child;

  const ScreenSlot({super.key, required this.width, required this.enter, required this.leaving, required this.child});

  @override
  State<ScreenSlot> createState() => _ScreenSlotState();
}

class _ScreenSlotState extends State<ScreenSlot> {
  static final Curve _stillCurve = ClaySpringCurve(
    ClaySprings.still,
    settleDuration: const Duration(milliseconds: 450),
  );

  late bool _grown = !widget.enter;

  @override
  void initState() {
    super.initState();
    if (widget.enter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _grown = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final motion = ClayMotion.of(context);
    final bool collapsed = widget.leaving || !_grown;
    final Curve sizeCurve = !motion.enabled
        ? _stillCurve
        : widget.leaving
        ? ClaySpringCurve.gentle
        : ClaySpringCurve.bouncy;
    return AnimatedSize(
      duration: const Duration(milliseconds: 450),
      curve: sizeCurve,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: collapsed ? 0 : widget.width,
        child: OverflowBox(
          minWidth: widget.width,
          maxWidth: widget.width,
          fit: OverflowBoxFit.deferToChild,
          alignment: Alignment.centerLeft,
          // Pure crossfade on the way out (and hidden on the width-0 frame a
          // new slot starts on), so an eased curve is fine here.
          child: AnimatedOpacity(
            opacity: collapsed ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              scale: widget.leaving ? 0.9 : 1,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
