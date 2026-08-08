import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/sidebar_card.dart';
import '../../../widgets/shared/color_swatch_button.dart';

class BackgroundPanel extends StatelessWidget {
  const BackgroundPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final hasBgImage = vm.customBackgroundImageBytes != null;

    return SidebarCard(
      title: '3. Canvas Background',
      icon: Icons.palette_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Custom Background Image Section ---
          const Text(
            'Background Image',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: AppDimensions.fontBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          ElevatedButton.icon(
            onPressed: () => vm.pickCustomBackgroundImage(),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasBgImage ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary,
              foregroundColor: hasBgImage ? AppColors.primary : AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                side: hasBgImage ? const BorderSide(color: AppColors.primary, width: 1.5) : BorderSide.none,
              ),
              elevation: hasBgImage ? 0 : 2,
            ),
            icon: Icon(hasBgImage ? Icons.image_rounded : Icons.add_photo_alternate_rounded, size: 20),
            label: Text(
              hasBgImage ? 'Change BG Image' : 'Upload Background Image',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          if (hasBgImage) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Image Active',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => vm.setCustomBackgroundImage(null),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Clear Image',
                      style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.spacingLg),
          const Text(
            'Preset Gradients',
            style: TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppDimensions.spacingSm),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppDimensions.spacingSm,
              mainAxisSpacing: AppDimensions.spacingSm,
              childAspectRatio: 2.2,
            ),
            itemCount: StoreSpecs.gradientPresets.length,
            itemBuilder: (ctx, index) {
              final preset = StoreSpecs.gradientPresets[index];
              final isSelected = vm.selectedGradientIndex == index && vm.customBackgroundColor == null && !hasBgImage;
              return InkWell(
                onTap: () {
                  if (hasBgImage) vm.setCustomBackgroundImage(null);
                  vm.setGradientIndex(index);
                },
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                child: Container(
                  decoration: preset.toDecoration().copyWith(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.glassBorder,
                      width: isSelected ? 2.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      preset.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: preset.colors.first.computeLuminance() > 0.5 ? AppColors.textPrimary : Colors.white,
                        fontSize: AppDimensions.fontXs,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              const Text(
                'Custom Solid Color:',
                style: TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ColorSwatchButton(
                color: vm.customBackgroundColor ?? AppColors.surface,
                onColorChanged: (c) {
                  if (hasBgImage) vm.setCustomBackgroundImage(null);
                  vm.setCustomBackgroundColor(c);
                },
                size: 32,
                showIcon: vm.customBackgroundColor == null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

