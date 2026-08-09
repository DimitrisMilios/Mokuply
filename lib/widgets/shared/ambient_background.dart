import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Reusable ambient glowing background stack for light glassmorphism backdrop reflections.
class AmbientBackground extends StatelessWidget {
  final Widget child;

  const AmbientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-Left Glowing Cream Orb
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 600,
            height: 600,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orbCream,
            ),
          ),
        ),

        // Center-Right Glowing Jungle Orb
        Positioned(
          top: 250,
          right: -100,
          child: Container(
            width: 500,
            height: 500,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orbJungle,
            ),
          ),
        ),

        // Bottom-Left Glowing Sage Orb
        Positioned(
          bottom: -150,
          left: 200,
          child: Container(
            width: 550,
            height: 550,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.orbSage,
            ),
          ),
        ),

        // Foreground Child Content
        child,
      ],
    );
  }
}
