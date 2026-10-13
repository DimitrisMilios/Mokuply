import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_container.dart';
import 'clay_decoration.dart';
import 'jelly_transform.dart';

/// Big raised surface: navbars, inspector, action rail, dialogs.
/// `radiusClayLg`, lift 18, depth 6 by default.
class ClayPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double lift;
  final double depth;
  final Color color;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  /// Pick up a surface ripple from an enclosing [JellyTransform].
  final bool ripple;

  const ClayPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingLg),
    this.margin,
    this.radius = AppDimensions.radiusClayLg,
    this.lift = AppDimensions.clayLift,
    this.depth = AppDimensions.clayDepth,
    this.color = AppColors.clay,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
    this.ripple = false,
  });

  @override
  Widget build(BuildContext context) {
    final rippleTime = ripple ? JellyRipple.of(context) : -1.0;
    return RepaintBoundary(
      child: ClayContainer(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        alignment: alignment,
        clipBehavior: clipBehavior,
        decoration: ClayDecoration(
          color: color,
          radius: radius,
          lift: lift,
          depth: depth,
          rippleTime: rippleTime,
        ),
        child: child,
      ),
    );
  }
}
