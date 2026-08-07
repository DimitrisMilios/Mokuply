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

    return SidebarCard(
      title: '3. Canvas Background',
      icon: Icons.palette_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preset Gradients', style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600)),
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
              final isSelected = vm.selectedGradientIndex == index && vm.customBackgroundColor == null;
              return InkWell(
                onTap: () => vm.setGradientIndex(index),
                child: Container(
                  decoration: preset.toDecoration().copyWith(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isSelected ? AppColors.textPrimary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      preset.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontXs, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.spacingLg),
          Row(
            children: [
              const Text('Custom Solid Color:', style: TextStyle(color: AppColors.textSecondary, fontSize: AppDimensions.fontBody)),
              const Spacer(),
              ColorSwatchButton(
                color: vm.customBackgroundColor ?? AppColors.surface,
                onColorChanged: (c) => vm.setCustomBackgroundColor(c),
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
