import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_image_item.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/thumbnail_image.dart';

/// Controls for one custom image asset.
class ImageInspector extends StatelessWidget {
  final String imageId;

  const ImageInspector({super.key, required this.imageId});

  @override
  Widget build(BuildContext context) {
    final image = context.select<EditorViewModel, CanvasImageItem?>(
      (vm) => vm.customImageItems.where((i) => i.id == imageId).firstOrNull,
    );
    final vm = context.read<EditorViewModel>();
    if (image == null) {
      return const Text('This image no longer exists.', style: TextStyle(color: AppColors.textMuted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClayWell(
          padding: const EdgeInsets.all(8),
          height: 136,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusClaySm - 6),
            child: LayoutBuilder(
              builder: (context, box) =>
                  ThumbnailImage(bytes: image.imageBytes, width: box.maxWidth, height: box.maxHeight, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ClaySlider(
          label: 'Scale',
          valueText: '${(image.scale * 100).toInt()}%',
          value: image.scale.clamp(ScaleLimits.imageMin, ScaleLimits.imageMax),
          min: ScaleLimits.imageMin,
          max: ScaleLimits.imageMax,
          onChanged: (v) => vm.setCustomImageScale(image.id, v),
        ),
        const SizedBox(height: 8),
        ClaySlider(
          label: 'Rotation',
          valueText: '${image.rotation.toInt()}°',
          value: image.rotation,
          min: -180.0,
          max: 180.0,
          onChanged: (v) => vm.setCustomImageRotation(image.id, v),
        ),
        const SizedBox(height: 8),
        ClaySlider(
          label: 'Opacity',
          valueText: '${(image.opacity * 100).toInt()}%',
          value: image.opacity,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => vm.setCustomImageOpacity(image.id, v),
        ),
        const SizedBox(height: 10),
        ClayToggle(
          label: 'Shadow',
          value: image.hasShadow,
          onChanged: (v) => vm.setCustomImageShadow(image.id, v),
        ),
        const SizedBox(height: 10),
        const Text(
          'Drag to move, corners to resize, top handle to rotate.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 10),
        ClayButton.text(
          label: 'Delete image',
          icon: Icons.delete_outline_rounded,
          danger: true,
          expand: true,
          onPressed: () => vm.removeCustomImageItem(image.id),
        ),
      ],
    );
  }
}
