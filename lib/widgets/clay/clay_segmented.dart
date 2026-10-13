import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';

class ClaySegment<T> {
  final T value;
  final String? label;
  final IconData? icon;
  final String? tooltip;

  const ClaySegment({required this.value, this.label, this.icon, this.tooltip})
      : assert(label != null || icon != null);
}

/// A sunken track with a raised clay puck that slides to the active option.
/// Replaces every `SegmentedButton`.
///
/// The puck is the liquid blob: its leading edge moves with the `liquid`
/// spring and the trailing edge with `snappy`, so it stretches toward the
/// target and then catches up. Tapping the selected option pokes the puck.
class ClaySegmented<T> extends StatefulWidget {
  final List<ClaySegment<T>> segments;
  final T selected;
  final ValueChanged<T>? onChanged;
  final double height;
  final bool expand;

  /// Puck colour. Defaults to clay; pass `AppColors.primary` for a green puck.
  final Color puckColor;
  final Color? selectedForeground;
  final double? segmentWidth;

  const ClaySegmented({
    super.key,
    required this.segments,
    required this.selected,
    this.onChanged,
    this.height = 40,
    this.expand = false,
    this.puckColor = AppColors.clay,
    this.selectedForeground,
    this.segmentWidth,
  });

  @override
  State<ClaySegmented<T>> createState() => _ClaySegmentedState<T>();
}

class _ClaySegmentedState<T> extends State<ClaySegmented<T>> with TickerProviderStateMixin {
  late final AnimationController _left;
  late final AnimationController _right;
  late final AnimationController _poke;
  late final AnimationController _skew;
  int _index = 0;
  double _lastLeft = 0;

  @override
  void initState() {
    super.initState();
    _index = _indexOf(widget.selected);
    _left = AnimationController.unbounded(vsync: this, value: _index.toDouble());
    _right = AnimationController.unbounded(vsync: this, value: _index + 1.0);
    _poke = AnimationController.unbounded(vsync: this, value: 0);
    _skew = AnimationController.unbounded(vsync: this, value: 0);
    _left.addListener(_trackVelocity);
  }

  int _indexOf(T value) {
    final i = widget.segments.indexWhere((s) => s.value == value);
    return i < 0 ? 0 : i;
  }

  void _trackVelocity() {
    final motion = ClayMotion.of(context);
    if (!motion.skew) return;
    // Velocity in "segments per second"; scale to roughly px/s for the skew.
    final v = (_left.value - _lastLeft) * 60 * 90;
    _lastLeft = _left.value;
    if (_left.isAnimating) {
      _skew.value = skewForVelocity(v);
    }
  }

  @override
  void didUpdateWidget(ClaySegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = _indexOf(widget.selected);
    if (newIndex != _index) {
      _moveTo(newIndex);
    }
  }

  void _moveTo(int newIndex) {
    final motion = ClayMotion.of(context);
    final forward = newIndex > _index;
    _index = newIndex;
    // Leading edge is liquid (fast, soft), trailing is snappy.
    if (forward) {
      _right.springTo(newIndex + 1.0, spring: motion.liquid);
      _left.springTo(newIndex.toDouble(), spring: motion.snappy);
    } else {
      _left.springTo(newIndex.toDouble(), spring: motion.liquid);
      _right.springTo(newIndex + 1.0, spring: motion.snappy);
    }
    _left.springTo(newIndex.toDouble(), spring: forward ? motion.snappy : motion.liquid).then((_) {
      if (mounted) _skew.springTo(0, spring: motion.bouncy);
    });
  }

  void _tap(int i) {
    if (widget.onChanged == null) return;
    final motion = ClayMotion.of(context);
    if (i == _index) {
      _poke.springTo(1, spring: motion.snappy).then((_) {
        if (mounted) _poke.springTo(0, spring: motion.liquid);
      });
      return;
    }
    widget.onChanged!(widget.segments[i].value);
    if (_indexOf(widget.selected) == _index) {
      // Parent might not rebuild synchronously; animate optimistically.
      _moveTo(i);
    }
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    _poke.dispose();
    _skew.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.segments.length;
    final selectedFg = widget.selectedForeground ??
        (widget.puckColor.computeLuminance() < 0.4 ? AppColors.textOnPrimary : AppColors.primaryDeep);
    const pad = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final segW = widget.segmentWidth ??
            (widget.expand && constraints.hasBoundedWidth
                ? (constraints.maxWidth - pad * 2) / n
                : _intrinsicSegmentWidth());
        final trackW = segW * n + pad * 2;
        final puckH = widget.height - pad * 2;

        return Container(
          width: trackW,
          height: widget.height,
          decoration: ClayDecoration.well(radius: widget.height / 2, depth: 4),
          child: AnimatedBuilder(
            animation: Listenable.merge([_left, _right, _poke, _skew]),
            builder: (context, _) {
              final l = pad + _left.value * segW;
              final r = pad + _right.value * segW;
              final moving = _left.isAnimating || _right.isAnimating;
              final poke = _poke.value;
              final puckDeco = ClayDecoration(
                color: widget.puckColor,
                radius: puckH / 2,
                depth: 4,
                lift: 6,
                shadowOpacity: 0.18,
                edgeOpacity: 0.10,
                highlightColor:
                    widget.puckColor == AppColors.primary ? AppColors.primaryLight : AppColors.clayLight,
                shadeColor: widget.puckColor == AppColors.primary ? AppColors.primaryDeep : AppColors.clayShade,
                highlightOpacity: widget.puckColor == AppColors.primary ? 0.5 : 0.9,
                shadeOpacity: widget.puckColor == AppColors.primary ? 0.5 : 0.16,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Track tint while moving.
                  if (moving)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(widget.height / 2),
                          color: AppColors.clayShade.withValues(alpha: 0.02),
                        ),
                      ),
                    ),
                  Positioned(
                    left: l,
                    top: pad,
                    width: (r - l).clamp(4.0, trackW),
                    height: puckH,
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(0, 1, _skew.value)
                        ..multiply(Matrix4.diagonal3Values(1 + 0.08 * poke, 1 - 0.08 * poke, 1)),
                      child: DecoratedBox(decoration: puckDeco),
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: pad),
                      for (var i = 0; i < n; i++)
                        _SegmentLabel(
                          width: segW,
                          height: puckH,
                          segment: widget.segments[i],
                          // Crossfade over the last 40 % of travel.
                          t: _coverage(i, _left.value, _right.value),
                          selectedColor: selectedFg,
                          onTap: widget.onChanged == null ? null : () => _tap(i),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  double _intrinsicSegmentWidth() {
    var maxW = 0.0;
    for (final s in widget.segments) {
      var w = 24.0;
      if (s.icon != null) w += 18;
      if (s.label != null) {
        final tp = TextPainter(
          text: TextSpan(
            text: s.label,
            style: const TextStyle(fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w800),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        w += tp.width + (s.icon != null ? 6 : 0);
      }
      if (w > maxW) maxW = w;
    }
    return maxW;
  }

  static double _coverage(int i, double l, double r) {
    // How much of segment i is under the puck (0..1), sharpened so the
    // label colour only crosses over near the end of travel.
    final overlap = (r.clamp(i.toDouble(), i + 1.0)) - (l.clamp(i.toDouble(), i + 1.0));
    final c = overlap.clamp(0.0, 1.0);
    return ((c - 0.6) / 0.4).clamp(0.0, 1.0);
  }
}

class _SegmentLabel extends StatelessWidget {
  final double width;
  final double height;
  final ClaySegment segment;
  final double t;
  final Color selectedColor;
  final VoidCallback? onTap;

  const _SegmentLabel({
    required this.width,
    required this.height,
    required this.segment,
    required this.t,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(AppColors.textMuted, selectedColor, t)!;
    Widget child = SizedBox(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (segment.icon != null) Icon(segment.icon, size: 16, color: color),
          if (segment.icon != null && segment.label != null) const SizedBox(width: 6),
          if (segment.label != null)
            Text(
              segment.label!,
              style: TextStyle(color: color, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
    if (segment.tooltip != null) child = Tooltip(message: segment.tooltip!, child: child);
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
    );
  }
}
