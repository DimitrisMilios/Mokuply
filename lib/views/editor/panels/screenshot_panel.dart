import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';

class ScreenshotPanel extends StatelessWidget {
  const ScreenshotPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);

    return SidebarCard(
      title: '1. App Screenshot',
      icon: Icons.upload_file_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () => vm.pickScreenshot(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(vm.screenshotBytes == null ? 'Upload Screenshot' : 'Change Screenshot'),
          ),
          if (vm.screenshotBytes != null) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                const SizedBox(width: AppDimensions.spacingSm),
                const Text('Image loaded in memory', style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimensions.fontBody)),
                const Spacer(),
                TextButton(
                  onPressed: () => vm.setScreenshotBytes(null),
                  child: const Text('Remove', style: TextStyle(color: AppColors.error, fontSize: AppDimensions.fontBody)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
