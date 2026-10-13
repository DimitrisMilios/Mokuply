import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';

/// Sunken track, raised round knob, filled portion in primary.
/// Replaces `LabeledSlider` and the theme slider.
///
/// The label row is kept; the value is plain muted tabular text (no pill).
/// Grabbing scales the knob to 1.3 and pops a value bubble above it.
class ClaySlider extends StatefulWidget {
  final String? label;
  final String? valueText;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// Fill the track from the left (default) or show no fill.
  final bool filled;

  const ClaySlider({
    super.key,
    this.label,
    this.valueText,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.onChangeEnd,
    this.filled = true,
  });

  @override
  State<ClaySlider> createState() => _ClaySliderState();
}

class _ClaySliderState extends State<ClaySlider> with TickerProviderStateMixin {
  static const double _trackH = 12;
  static const double _knob = 22;
  static const double _hitH = 32;

  late final AnimationController _grab;
  late final AnimationController _skew;
  late final AnimationController _fill;
  late final AnimationController _sqX;
  late final AnimationController _sqY;
  bool _dragging = false;
  double _lastDx = 0;
  Duration? _lastTime;

  @override
  void initState() {
    super.initState();
    _grab = AnimationController.unbounded(vsync: this, value: 0);
    _skew = AnimationController.unbounded(vsync: this, value: 0);
    _fill = AnimationController.unbounded(vsync: this, value: _t(widget.value));
    _sqX = AnimationController.unbounded(vsync: this, value: 1);
    _sqY = AnimationController.unbounded(vsync: this, value: 1);
  }

  double _t(double v) {
    if (widget.max <= widget.min) return 0;
    return ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(ClaySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging && oldWidget.value != widget.value) {
      _fill.springTo(_t(widget.value), spring: ClayMotion.of(context).gentle);
    } else if (_dragging) {
      _fill.value = _t(widget.value);
    }
  }

  @override
  void dispose() {
    _grab.dispose();
    _skew.dispose();
    _fill.dispose();
    _sqX.dispose();
    _sqY.dispose();
    super.dispose();
  }

  void _setFromDx(double dx, double width) {
    final t = ((dx - _knob / 2) / (width - _knob)).clamp(0.0, 1.0);
    final v = widget.min + t * (widget.max - widget.min);
    _fill.value = t;
    widget.onChanged?.call(v);
  }

  void _start(DragStartDetails d, double width) {
    final motion = ClayMotion.of(context);
    _dragging = true;
    _grab.springTo(1, spring: motion.snappy);
    _sqX.springTo(1 + motion.squash, spring: motion.snappy);
    _sqY.springTo(1 - motion.squash, spring: motion.snappy);
    _lastDx = d.localPosition.dx;
    _lastTime = d.sourceTimeStamp;
    _setFromDx(d.localPosition.dx, width);
  }

  void _update(DragUpdateDetails d, double width) {
    final motion = ClayMotion.of(context);
    if (motion.skew && d.sourceTimeStamp != null && _lastTime != null) {
      final dt = (d.sourceTimeStamp! - _lastTime!).inMicroseconds / 1e6;
      if (dt > 0) {
        final v = (d.localPosition.dx - _lastDx) / dt;
        _skew.value = skewForVelocity(v);
      }
    }
    _lastDx = d.localPosition.dx;
    _lastTime = d.sourceTimeStamp;
    _setFromDx(d.localPosition.dx, width);
  }

  void _end() {
    final motion = ClayMotion.of(context);
    _dragging = false;
    _grab.springTo(0, spring: motion.bouncy);
    _skew.springTo(0, spring: motion.bouncy);
    _sqX.springTo(1, spring: motion.liquid);
    Future<void>.delayed(const Duration(milliseconds: 16), () {
      if (mounted) _sqY.springTo(1, spring: motion.liquid);
    });
    widget.onChangeEnd?.call(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;

    final slider = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: enabled ? (d) => _start(d, width) : null,
            onHorizontalDragUpdate: enabled ? (d) => _update(d, width) : null,
            onHorizontalDragEnd: enabled ? (_) => _end() : null,
            onHorizontalDragCancel: enabled ? _end : null,
            onTapDown: enabled
                ? (d) {
                    final motion = ClayMotion.of(context);
                    _setFromDx(d.localPosition.dx, width);
                    _fill.springTo(_fill.value, spring: motion.snappy);
                    _sqX.springTo(1 + motion.squash, spring: motion.snappy);
                    _sqY.springTo(1 - motion.squash, spring: motion.snappy);
                  }
                : null,
            onTapUp: enabled ? (_) => _end() : null,
            onTapCancel: enabled ? _end : null,
            child: SizedBox(
              height: _hitH,
              child: AnimatedBuilder(
                animation: Listenable.merge([_grab, _skew, _fill, _sqX, _sqY]),
                builder: (context, _) {
                  final t = _fill.value.clamp(0.0, 1.0);
                  final g = _grab.value.clamp(0.0, 1.0);
                  final knobX = t * (width - _knob);
                  final scale = 1 + 0.3 * g;
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Track
                      Positioned(
                        left: 0,
                        right: 0,
                        top: (_hitH - _trackH) / 2,
                        height: _trackH,
                        child: DecoratedBox(
                          decoration: ClayDecoration.well(radius: _trackH / 2, depth: 3),
                          child: widget.filled
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: ((knobX + _knob / 2) / width).clamp(0.0, 1.0),
                                    heightFactor: 1,
                                    child: Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(_trackH / 2),
                                        gradient: const LinearGradient(
                                          colors: [AppColors.primaryLight, AppColors.primary],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      // Value bubble
                      if (widget.valueText != null)
                        Positioned(
                          left: knobX + _knob / 2 - 28,
                          top: -26,
                          width: 56,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: g,
                              child: Transform.scale(
                                scale: 0.6 + 0.4 * g,
                                alignment: Alignment.bottomCenter,
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()..setEntry(0, 1, _skew.value * 0.5),
                                  child: Container(
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: const ClayDecoration(
                                      color: AppColors.clay,
                                      radius: 12,
                                      depth: 3,
                                      lift: 6,
                                      shadowOpacity: 0.18,
                                    ),
                                    child: Text(
                                      widget.valueText!,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: AppDimensions.fontSm,
                                        fontWeight: FontWeight.w800,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Knob
                      Positioned(
                        left: knobX,
                        top: (_hitH - _knob) / 2,
                        width: _knob,
                        height: _knob,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(0, 1, _skew.value)
                            ..multiply(Matrix4.diagonal3Values(scale * _sqX.value, scale * _sqY.value, 1)),
                          child: Opacity(
                            opacity: enabled ? 1 : 0.5,
                            child: const DecoratedBox(
                              decoration: ClayDecoration(
                                color: AppColors.clay,
                                radius: _knob / 2,
                                depth: 3,
                                lift: 5,
                                shadowOpacity: 0.26,
                                edgeOpacity: 0.14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );

    if (widget.label == null && widget.valueText == null) return slider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.label != null)
              Text(
                widget.label!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontBody,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (widget.valueText != null)
              Text(
                widget.valueText!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppDimensions.fontSm,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        slider,
      ],
    );
  }
}
