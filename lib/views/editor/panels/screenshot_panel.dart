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
      title: '1. App Screenshots',
      icon: Icons.upload_file_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mode toggle info tag
          const Text(
            'Upload same screenshot for both devices or customize per device:',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // 1. Shared Universal Screenshot
          _buildScreenshotItemTile(
            title: 'Universal Screenshot',
            subtitle: 'Shared by default across all devices',
            icon: Icons.smartphone_rounded,
            hasImage: vm.screenshotBytes != null,
            onUpload: () => vm.pickScreenshot(),
            onRemove: () => vm.setScreenshotBytes(null),
          ),
          const SizedBox(height: 12),

          // 2. iPhone Specific Override
          _buildScreenshotItemTile(
            title: 'iPhone Screenshot',
            subtitle: 'Specific image for iPhone 16 Pro Max',
            icon: Icons.phone_iphone_rounded,
            hasImage: vm.iphoneScreenshotBytes != null,
            badgeTag: vm.iphoneScreenshotBytes != null ? 'iPhone Custom' : null,
            onUpload: () => vm.pickIphoneScreenshot(),
            onRemove: () => vm.setIphoneScreenshotBytes(null),
          ),
          const SizedBox(height: 12),

          // 3. Samsung Specific Override
          _buildScreenshotItemTile(
            title: 'Samsung Screenshot',
            subtitle: 'Specific image for Samsung S26 Ultra',
            icon: Icons.phone_android_rounded,
            hasImage: vm.samsungScreenshotBytes != null,
            badgeTag: vm.samsungScreenshotBytes != null ? 'Samsung Custom' : null,
            onUpload: () => vm.pickSamsungScreenshot(),
            onRemove: () => vm.setSamsungScreenshotBytes(null),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotItemTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool hasImage,
    String? badgeTag,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasImage ? AppColors.primary.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: hasImage ? AppColors.primary : AppColors.glassBorder,
          width: hasImage ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: hasImage ? AppColors.primary : AppColors.textPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: hasImage ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasImage)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasImage ? AppColors.surface : AppColors.primary,
                    foregroundColor: hasImage ? AppColors.textPrimary : AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: hasImage ? const BorderSide(color: AppColors.glassBorder) : BorderSide.none,
                    ),
                  ),
                  icon: Icon(hasImage ? Icons.sync_rounded : Icons.upload_rounded, size: 14),
                  label: Text(
                    hasImage ? 'Replace Image' : 'Upload',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                  tooltip: 'Remove Screenshot',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

