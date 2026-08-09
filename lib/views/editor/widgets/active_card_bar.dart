import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';

/// Sidebar card indicator showing current card index, duplicate, and delete actions.
class ActiveCardBar extends StatelessWidget {
  const ActiveCardBar({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);

    return GlassContainer(
      opacity: 0.8,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              'Screen #${vm.selectedIndex + 1}',
              style: const TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Editing Active Card',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => vm.duplicateScreenshot(vm.selectedIndex),
            tooltip: 'Duplicate Screen',
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
          ),
          if (vm.screenshotsCount > 1)
            IconButton(
              onPressed: () => vm.removeScreenshot(vm.selectedIndex),
              tooltip: 'Delete Screen',
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
            ),
        ],
      ),
    );
  }
}
