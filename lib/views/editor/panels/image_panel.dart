import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';
import '../../../widgets/shared/labeled_slider.dart';

class ImagePanel extends StatelessWidget {
  const ImagePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final imageItems = vm.customImageItems;
    final activeImage = vm.selectedCustomImage;

    return SidebarCard(
      title: '2. Custom Images & Assets',
      icon: Icons.add_photo_alternate_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Upload logos, badges, graphics, or extra screenshots to place anywhere on the canvas:',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),

          // Add New Image Button
          ElevatedButton.icon(
            onPressed: () => vm.pickAndAddCustomImageItem(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
            ),
            icon: const Icon(Icons.upload_rounded, size: 16),
            label: const Text(
              '+ Add Custom Image Asset',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),

          if (imageItems.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacingMd),
            const Text(
              'Canvas Image Assets:',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            // Image Thumbnails Row / List
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageItems.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = imageItems[index];
                  final isSelected = activeImage?.id == item.id;

                  return InkWell(
                    onTap: () => vm.selectCustomImage(item.id),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.glassBorder,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.memory(
                          item.imageBytes,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            if (activeImage != null) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Selected Asset Controls',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => vm.removeCustomImageItem(activeImage.id),
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                          tooltip: 'Delete Custom Image',
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LabeledSlider(
                      label: 'Scale',
                      valueText: '${(activeImage.scale * 100).toInt()}%',
                      value: activeImage.scale,
                      min: 0.2,
                      max: 2.5,
                      onChanged: (val) => vm.setCustomImageScale(activeImage.id, val),
                    ),
                    const SizedBox(height: 8),
                    LabeledSlider(
                      label: 'Rotation Tilt',
                      valueText: '${activeImage.rotation.toInt()}°',
                      value: activeImage.rotation,
                      min: -180.0,
                      max: 180.0,
                      onChanged: (val) => vm.setCustomImageRotation(activeImage.id, val),
                    ),
                    const SizedBox(height: 8),
                    LabeledSlider(
                      label: 'Opacity',
                      valueText: '${(activeImage.opacity * 100).toInt()}%',
                      value: activeImage.opacity,
                      min: 0.1,
                      max: 1.0,
                      onChanged: (val) => vm.setCustomImageOpacity(activeImage.id, val),
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Drop Shadow',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      value: activeImage.hasShadow,
                      activeTrackColor: AppColors.primary,
                      activeThumbColor: Colors.white,
                      onChanged: (val) => vm.setCustomImageShadow(activeImage.id, val),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
