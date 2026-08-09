import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';

/// Floating bottom screenshot switcher & "+ Add Screenshot" button bar.
class ScreenshotReelBar extends StatelessWidget {
  const ScreenshotReelBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return GlassContainer(
      opacity: 0.85,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Screenshots Set (${vm.screenshotsCount}):',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          ...List.generate(vm.screenshotsCount, (index) {
            final isSelected = vm.selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => vm.selectScreenshot(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.glassBorder),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => vm.addScreenshot(),
            tooltip: 'Add Screenshot to Set',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
            icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
