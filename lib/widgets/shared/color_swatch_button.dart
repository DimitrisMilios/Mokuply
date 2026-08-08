import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'glass_container.dart';

/// Tappable color swatch button and glass color picker dialog.
class ColorSwatchButton extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;
  final double size;
  final bool showIcon;

  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.onColorChanged,
    this.size = 32,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openPicker(context),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: showIcon
            ? Icon(Icons.colorize_rounded, size: 16, color: color.computeLuminance() > 0.5 ? AppColors.primary : Colors.white)
            : null,
      ),
    );
  }

  void _openPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        child: GlassContainer(
          width: 320,
          opacity: 0.85,
          borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
          borderColor: AppColors.glassBorder,
          padding: const EdgeInsets.all(AppDimensions.spacingXxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pick Color',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppDimensions.fontXl,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ColorPicker(
                pickerColor: color,
                onColorChanged: onColorChanged,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                labelTypes: const [],
                pickerAreaBorderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              const SizedBox(height: AppDimensions.spacingLg),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  elevation: 2,
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
