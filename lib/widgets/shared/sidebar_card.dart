import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'glass_container.dart';

/// Reusable sidebar section card styled with glassmorphism.
class SidebarCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SidebarCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      opacity: 0.6,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.all(AppDimensions.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontLg,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          child,
        ],
      ),
    );
  }
}
