import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Tappable color swatch that opens a color picker dialog.
class ColorSwatchButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final double size;
  final bool showIcon;

  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.size = 28,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: Colors.white54),
        ),
        child: showIcon
            ? const Icon(Icons.colorize, size: 16, color: Colors.white54)
            : null,
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Pick Color', style: TextStyle(color: AppColors.textPrimary)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
