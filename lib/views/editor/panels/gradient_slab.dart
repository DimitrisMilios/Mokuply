import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../widgets/clay/clay.dart';

/// One gradient preset: a small raised clay slab whose fill is the gradient.
/// The selected preset sits sunken in the panel.
///
/// Layers, bottom to top: the floating shadow (its own layer so it never
/// bleeds over the gradient), the clipped gradient, then a transparent clay
/// surface that only draws the inner highlight / shade pair.
class GradientSlab extends StatefulWidget {
  final ColorGradientPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const GradientSlab({super.key, required this.preset, required this.selected, required this.onTap});

  @override
  State<GradientSlab> createState() => _GradientSlabState();
}

class _GradientSlabState extends State<GradientSlab> with SingleTickerProviderStateMixin {
  static const double _radius = 14;
  late final AnimationController _sel;

  @override
  void initState() {
    super.initState();
    _sel = AnimationController.unbounded(vsync: this, value: widget.selected ? 1 : 0);
  }

  @override
  void didUpdateWidget(GradientSlab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final motion = ClayMotion.of(context);
      _sel.springTo(widget.selected ? 1 : 0, spring: widget.selected ? motion.snappy : motion.bouncy);
    }
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final labelColor = preset.colors.first.computeLuminance() > 0.5 ? AppColors.textPrimary : Colors.white;

    return Tooltip(
      message: preset.name,
      child: ClayPressable(
        onTap: widget.onTap,
        squash: 0.05,
        builder: (context, hover, press, _) {
          return AnimatedBuilder(
            animation: _sel,
            builder: (context, _) {
              final s = _sel.value.clamp(0.0, 1.0);
              final h = hover.clamp(0.0, 1.0);
              final p = press.clamp(0.0, 1.0);
              // Sunk amount: fully when selected, partly while pressed.
              final sunk = (s + p * (1 - s)).clamp(0.0, 1.0);

              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  // 1. Floating shadow, fades out as the slab sinks.
                  DecoratedBox(
                    decoration: ClayDecoration(
                      color: Colors.transparent,
                      radius: _radius,
                      depth: 0,
                      lift: 8 + 4 * h,
                      shadowOpacity: 0.18 * (1 - sunk),
                      highlightOpacity: 0,
                      shadeOpacity: 0,
                    ),
                  ),
                  // 2. The gradient itself.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_radius),
                    child: DecoratedBox(decoration: preset.toDecoration()),
                  ),
                  // 3. Inner lighting pair over the gradient; inverts when sunk.
                  DecoratedBox(
                    decoration: ClayDecoration(
                      color: Colors.transparent,
                      radius: _radius,
                      depth: 4,
                      lift: 0,
                      pressed: sunk,
                      shadowOpacity: 0,
                      highlightOpacity: 0.6,
                      shadeOpacity: 0.32 + 0.1 * sunk,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        preset.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
