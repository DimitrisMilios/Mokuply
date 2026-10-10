import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/labeled_slider.dart';

/// Controls for one custom image asset.
class ImageInspector extends StatelessWidget {
  final String imageId;

  const ImageInspector({super.key, required this.imageId});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final image = vm.customImageItems.where((i) => i.id == imageId).firstOrNull;
    if (image == null) {
      return const Text('This image no longer exists.', style: TextStyle(color: AppColors.textMuted));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            height: 120,
            color: Colors.black.withValues(alpha: 0.05),
            child: Image.memory(image.imageBytes, fit: BoxFit.contain, gaplessPlayback: true),
          ),
        ),
        const SizedBox(height: 12),
        LabeledSlider(
          label: 'Scale',
          valueText: '${(image.scale * 100).toInt()}%',
          value: image.scale.clamp(0.2, 2.5),
          min: 0.2,
          max: 2.5,
          onChanged: (v) => vm.setCustomImageScale(image.id, v),
        ),
        const SizedBox(height: 8),
        LabeledSlider(
          label: 'Rotation',
          valueText: '${image.rotation.toInt()}°',
          value: image.rotation,
          min: -180.0,
          max: 180.0,
          onChanged: (v) => vm.setCustomImageRotation(image.id, v),
        ),
        const SizedBox(height: 8),
        LabeledSlider(
          label: 'Opacity',
          valueText: '${(image.opacity * 100).toInt()}%',
          value: image.opacity,
          min: 0.1,
          max: 1.0,
          onChanged: (v) => vm.setCustomImageOpacity(image.id, v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text(
            'Drop shadow',
            style: TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
          ),
          value: image.hasShadow,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
          onChanged: (v) => vm.setCustomImageShadow(image.id, v),
        ),
        const SizedBox(height: 4),
        const Text(
          'Drag the image on the canvas to move it.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => vm.removeCustomImageItem(image.id),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            minimumSize: const Size.fromHeight(36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Delete image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
