import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';

/// A box painted with [ClayDecoration]. Replaces `GlassContainer`.
class ClayContainer extends StatelessWidget {
  final Widget? child;
  final ClayDecoration decoration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final BoxConstraints? constraints;
  final Clip clipBehavior;

  const ClayContainer({
    super.key,
    this.child,
    this.decoration = const ClayDecoration(),
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
    this.clipBehavior = Clip.none,
  });

  /// Convenience: a raised clay box.
  ClayContainer.raised({
    super.key,
    this.child,
    Color color = AppColors.clay,
    double radius = AppDimensions.radiusClay,
    double depth = AppDimensions.clayDepth,
    double lift = AppDimensions.clayLift,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
    this.clipBehavior = Clip.none,
  }) : decoration = ClayDecoration(color: color, radius: radius, depth: depth, lift: lift);

  /// Convenience: a sunken well.
  ClayContainer.sunken({
    super.key,
    this.child,
    Color color = AppColors.clayDeep,
    double radius = AppDimensions.radiusClaySm,
    double depth = 5,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
    this.constraints,
    this.clipBehavior = Clip.none,
  }) : decoration = ClayDecoration.well(color: color, radius: radius, depth: depth);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      constraints: constraints,
      clipBehavior: clipBehavior,
      decoration: decoration,
      child: child,
    );
  }
}

/// Implicitly animates between two [ClayDecoration]s. Use for state changes
/// that are not driven by a pointer (selected, enabled, mode). Pointer-driven
/// motion lives in `ClayPressable`, which uses springs.
class AnimatedClay extends ImplicitlyAnimatedWidget {
  final Widget? child;
  final ClayDecoration decoration;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const AnimatedClay({
    super.key,
    required this.decoration,
    this.child,
    this.padding,
    this.width,
    this.height,
    this.alignment,
    super.duration = const Duration(milliseconds: 120),
    super.curve = Curves.easeOut,
    super.onEnd,
  });

  @override
  AnimatedWidgetBaseState<AnimatedClay> createState() => _AnimatedClayState();
}

class _ClayTween extends Tween<ClayDecoration?> {
  _ClayTween({super.begin});

  @override
  ClayDecoration? lerp(double t) => ClayDecoration.lerp(begin, end, t);
}

class _AnimatedClayState extends AnimatedWidgetBaseState<AnimatedClay> {
  _ClayTween? _decoration;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _decoration = visitor(
      _decoration,
      widget.decoration,
      (dynamic value) => _ClayTween(begin: value as ClayDecoration?),
    ) as _ClayTween?;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding,
      alignment: widget.alignment,
      decoration: _decoration?.evaluate(animation) ?? widget.decoration,
      child: widget.child,
    );
  }
}
