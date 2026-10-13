import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/clay/clay.dart';

/// Shown when there is nothing in the gallery.
class EmptyGallery extends StatelessWidget {
  const EmptyGallery({super.key});

  static const String _asset = 'assets/clay/empty_gallery.png';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Image.asset(
            _asset,
            width: 240,
            height: 240,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => const ClayWell(
              width: 240,
              height: 240,
              radius: AppDimensions.radiusClayLg,
              alignment: Alignment.center,
              child: Icon(Icons.auto_awesome_mosaic_outlined, size: 64, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No templates yet. Import one, or start a project from scratch.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontMd, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
