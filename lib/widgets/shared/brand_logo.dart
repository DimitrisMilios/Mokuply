import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../clay/clay_container.dart';
import '../clay/clay_decoration.dart';

/// The Mockuply mark (gold clay leaf on jungle green), used in the navbars.
///
/// The artwork carries its own green background, so it is clipped to rounded
/// corners and set into a small clay tile so it floats like everything else.
class BrandLogo extends StatelessWidget {
  final double size;
  final double radius;

  const BrandLogo({super.key, this.size = 36, this.radius = 10});

  static const String assetPath = 'assets/branding/mockuply_logo.png';

  static const double _tilePadding = 2;

  @override
  Widget build(BuildContext context) {
    return ClayContainer(
      width: size + _tilePadding * 2,
      height: size + _tilePadding * 2,
      padding: const EdgeInsets.all(_tilePadding),
      decoration: ClayDecoration(
        color: AppColors.clay,
        radius: radius + _tilePadding,
        depth: 3,
        lift: 8,
        shadowOpacity: 0.18,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'Mockuply',
        ),
      ),
    );
  }
}
