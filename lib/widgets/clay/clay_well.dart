import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_container.dart';
import 'clay_decoration.dart';

/// Sunken container for grouping: layers list background, image preview,
/// the dark code box.
class ClayWell extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double depth;
  final Color color;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;
  final Clip clipBehavior;

  const ClayWell({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingMd),
    this.margin,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 5,
    this.color = AppColors.clayDeep,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  });

  /// Dark well for code (`primaryDeep` fill, gold text expected inside).
  const ClayWell.dark({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(AppDimensions.spacingLg),
    this.margin,
    this.radius = AppDimensions.radiusClaySm,
    this.depth = 6,
    this.width,
    this.height,
    this.alignment,
    this.clipBehavior = Clip.none,
  }) : color = AppColors.primaryDeep;

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < 0.3;
    return ClayContainer(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      alignment: alignment,
      clipBehavior: clipBehavior,
      decoration: ClayDecoration.well(
        color: color,
        radius: radius,
        depth: depth,
        shadeOpacity: dark ? 0.5 : 0.14,
        highlightOpacity: dark ? 0.12 : 0.8,
      ),
      child: child,
    );
  }
}
