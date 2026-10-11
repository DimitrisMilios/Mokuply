import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// The Mokuply mark (phone + canvas on jungle green), used in the navbars.
/// The artwork already carries its own green background, so it is only
/// clipped to rounded corners and given a soft shadow.
class BrandLogo extends StatelessWidget {
  final double size;
  final double radius;
  final bool shadow;

  const BrandLogo({super.key, this.size = 36, this.radius = 10, this.shadow = false});

  static const String assetPath = 'assets/branding/mokuply_logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          semanticLabel: 'Mokuply',
        ),
      ),
    );
  }
}
