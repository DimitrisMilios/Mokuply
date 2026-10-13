import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/clay/clay.dart';

/// One export option: a round clay knob with the Blender render, title,
/// description and the download button.
class ExportOptionCard extends StatelessWidget {
  final bool emphasised;
  final String asset;
  final IconData fallbackIcon;
  final Color knobColor;
  final String title;
  final String description;
  final Widget button;

  const ExportOptionCard({
    super.key,
    this.emphasised = false,
    required this.asset,
    required this.fallbackIcon,
    required this.knobColor,
    required this.title,
    required this.description,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      emphasised: emphasised,
      padding: EdgeInsets.all(emphasised ? 24 : 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: ClayDecoration(
              color: knobColor,
              radius: 24,
              depth: 4,
              lift: 8,
              shadowOpacity: 0.16,
              edgeOpacity: 0.10,
            ),
            child: OverflowBox(
              maxWidth: 56,
              maxHeight: 56,
              child: Image.asset(
                asset,
                width: 56,
                height: 56,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Icon(fallbackIcon, size: 22, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: emphasised ? 17 : AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppDimensions.fontBody,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          button,
        ],
      ),
    );
  }
}
