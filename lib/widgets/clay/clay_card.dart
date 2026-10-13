import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';
import 'clay_pressable.dart';

/// Template cards, export option cards. `radiusClayLg`, hover lifts +6.
///
/// When [onTap] is set the card is pressable (scale 0.97 on press). The
/// [hoverBuilder] variant receives the hover value so inner content (the
/// template preview phones) can tilt with the pointer.
class ClayCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double lift;
  final Color color;
  final double? width;
  final double? height;
  final Clip clipBehavior;
  final Widget Function(BuildContext context, double hover, Widget child)? hoverBuilder;

  /// Emphasised card (first export option): slightly more lift.
  final bool emphasised;

  const ClayCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppDimensions.spacingXl),
    this.radius = AppDimensions.radiusClayLg,
    this.lift = AppDimensions.clayLift,
    this.color = AppColors.clay,
    this.width,
    this.height,
    this.clipBehavior = Clip.none,
    this.hoverBuilder,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClayPressable(
        onTap: onTap,
        squash: 0.03,
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: child,
        builder: (context, hover, press, child) {
          final h = hover.clamp(0.0, 1.0);
          final p = press.clamp(0.0, 1.0);
          final baseLift = emphasised ? lift + 4 : lift;
          Widget inner = child!;
          if (hoverBuilder != null) inner = hoverBuilder!(context, h, inner);
          return Transform.scale(
            scale: 1 + 0.015 * h - 0.03 * p,
            child: Container(
              width: width,
              height: height,
              padding: padding,
              clipBehavior: clipBehavior,
              decoration: ClayDecoration(
                color: color,
                radius: radius,
                depth: AppDimensions.clayDepth,
                lift: ui.lerpDouble(baseLift, baseLift + 8, h)!,
                pressed: p * 0.4,
                shadowOpacity: ui.lerpDouble(0.18, 0.24, h)!,
              ),
              child: inner,
            ),
          );
        },
      ),
    );
  }
}
