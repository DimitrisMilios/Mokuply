import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/color_swatch_button.dart';
import '../../../widgets/shared/thumbnail_image.dart';
import 'gradient_slab.dart';

/// Background image, preset gradients and solid colour for the active screen.
class BackgroundSection extends StatelessWidget {
  const BackgroundSection({super.key});

  @override
  Widget build(BuildContext context) {
    final (bgBytes, gradientIndex, solidColor) = context.select<EditorViewModel, (Uint8List?, int, Color?)>(
      (vm) => (vm.customBackgroundImageBytes, vm.selectedGradientIndex, vm.customBackgroundColor),
    );
    final vm = context.read<EditorViewModel>();
    final hasBgImage = bgBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Background image ---
        const ClayLabel('Background image'),
        const SizedBox(height: 4),
        const Text(
          'One image per screen, shared by both stores.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 10),
        if (hasBgImage) ...[
          ClayWell(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusClaySm - 6),
                  child: SizedBox(
                    width: 84,
                    height: 56,
                    child: ThumbnailImage(bytes: bgBytes, width: 84, height: 56),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClayButton.neutral(
                    label: 'Change',
                    icon: Icons.image_rounded,
                    size: ClayButtonSize.compact,
                    expand: true,
                    onPressed: () => vm.pickCustomBackgroundImage(),
                  ),
                ),
                const SizedBox(width: 4),
                ClayButton.text(
                  label: 'Remove',
                  danger: true,
                  size: ClayButtonSize.compact,
                  onPressed: () => vm.setCustomBackgroundImage(null),
                ),
              ],
            ),
          ),
        ] else
          ClayButton.primary(
            label: 'Upload image',
            icon: Icons.add_photo_alternate_rounded,
            expand: true,
            onPressed: () => vm.pickCustomBackgroundImage(),
          ),

        const SizedBox(height: AppDimensions.spacingXl),

        // --- Preset gradients ---
        const ClayLabel('Gradients'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          clipBehavior: Clip.none,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemCount: StoreSpecs.gradientPresets.length,
          itemBuilder: (ctx, index) {
            final preset = StoreSpecs.gradientPresets[index];
            final isSelected = gradientIndex == index && solidColor == null && !hasBgImage;
            return GradientSlab(
              preset: preset,
              selected: isSelected,
              onTap: () => vm.chooseGradient(index),
            );
          },
        ),

        const SizedBox(height: AppDimensions.spacingXl),

        // --- Solid colour ---
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClayLabel('Solid colour'),
                  SizedBox(height: 2),
                  Text(
                    'Replaces the gradient.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ColorSwatchButton(
              color: solidColor ?? AppColors.clay,
              onColorChanged: vm.chooseSolidColor,
              size: 36,
              showIcon: solidColor == null,
            ),
          ],
        ),
      ],
    );
  }
}
