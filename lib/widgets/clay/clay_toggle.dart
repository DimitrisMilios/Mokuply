import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';

/// Sunken pill track, raised clay knob. Replaces `SwitchListTile`.
///
/// The knob squashes while travelling, skews with velocity and settles with
/// a jelly spring. The track crossfades `clayDeep` ↔ `primary`.
class ClayToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Optional label row: label on the left, toggle on the right.
  final String? label;
  final String? subtitle;

  const ClayToggle({super.key, required this.value, this.onChanged, this.label, this.subtitle});

  @override
  State<ClayToggle> createState() => _ClayToggleState();
}

class _ClayToggleState extends State<ClayToggle> with TickerProviderStateMixin {
  static const double _w = 52;
  static const double _h = 30;
  static const double _knob = 22;
  static const double _pad = 4;

  late final AnimationController _lead; // 0..1 leading edge
  late final AnimationController _trail; // 0..1 trailing edge
  late final AnimationController _squash;
  late final AnimationController _skew;
  late final AnimationController _trackSquash;

  @override
  void initState() {
    super.initState();
    final v = widget.value ? 1.0 : 0.0;
    _lead = AnimationController.unbounded(vsync: this, value: v);
    _trail = AnimationController.unbounded(vsync: this, value: v);
    _squash = AnimationController.unbounded(vsync: this, value: 0);
    _skew = AnimationController.unbounded(vsync: this, value: 0);
    _trackSquash = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didUpdateWidget(ClayToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _travel();
  }

  void _travel() {
    final motion = ClayMotion.of(context);
    final target = widget.value ? 1.0 : 0.0;
    final dir = widget.value ? 1.0 : -1.0;
    _squash.springTo(1, spring: motion.snappy);
    if (motion.skew) _skew.springTo(dir * 0.14, spring: motion.snappy);
    _lead.springTo(target, spring: motion.liquid);
    _trail.springTo(target, spring: motion.snappy).then((_) {
      if (!mounted) return;
      _squash.springTo(0, spring: motion.liquid);
      _skew.springTo(0, spring: motion.bouncy);
      _trackSquash.springTo(1, spring: motion.snappy).then((_) {
        if (mounted) _trackSquash.springTo(0, spring: motion.bouncy);
      });
    });
  }

  @override
  void dispose() {
    _lead.dispose();
    _trail.dispose();
    _squash.dispose();
    _skew.dispose();
    _trackSquash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;

    final toggle = MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => widget.onChanged!(!widget.value) : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_lead, _trail, _squash, _skew, _trackSquash]),
          builder: (context, _) {
            final a = _lead.value;
            final b = _trail.value;
            final lo = (a < b ? a : b).clamp(-0.1, 1.1);
            final hi = (a > b ? a : b).clamp(-0.1, 1.1);
            final travel = _w - _pad * 2 - _knob;
            final left = _pad + lo * travel;
            final width = _knob + (hi - lo) * travel;
            final t = ((a + b) / 2).clamp(0.0, 1.0);
            final sq = _squash.value.clamp(0.0, 1.0);
            final ts = _trackSquash.value.clamp(0.0, 1.0);

            final trackColor = Color.lerp(AppColors.clayDeep, AppColors.primary, t)!;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(1 + 0.01 * ts, 1 - 0.01 * ts, 1),
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Container(
                  width: _w,
                  height: _h,
                  decoration: ClayDecoration.well(
                    color: trackColor,
                    radius: _h / 2,
                    depth: 4,
                    shadeOpacity: 0.14 + 0.3 * t,
                    highlightOpacity: 0.8 - 0.5 * t,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: left,
                        top: _pad,
                        width: width,
                        height: _knob,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(0, 1, _skew.value)
                            ..multiply(Matrix4.diagonal3Values(1 + 0.25 * sq, 1 - 0.15 * sq, 1)),
                          child: const DecoratedBox(
                            decoration: ClayDecoration(
                              color: AppColors.clay,
                              radius: _knob / 2,
                              depth: 3,
                              lift: 4,
                              shadowOpacity: 0.22,
                              edgeOpacity: 0.12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.label == null) return toggle;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.subtitle!,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontSm),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        toggle,
      ],
    );
  }
}
