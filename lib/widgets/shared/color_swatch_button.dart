import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../core/constants/app_colors.dart';
import '../clay/clay.dart';

/// A round clay knob showing [color]. Tapping it squashes the knob and opens
/// a clay colour picker that grows out of the knob.
///
/// The picker updates live through [onColorChanged] (so the canvas previews
/// the colour); Cancel puts the original colour back, Apply keeps it.
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

  /// Lighter / darker versions of [c] for the inner highlight and shade so the
  /// knob reads as clay made of that colour.
  static Color _lighter(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation * 0.85).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _darker(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.28).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = color.computeLuminance() > 0.5 ? AppColors.textPrimary : Colors.white;
    return Tooltip(
      message: 'Colour',
      child: ClayPressable(
        onTap: () => _openPicker(context),
        builder: (context, hover, press, _) {
          final h = hover.clamp(0.0, 1.0);
          return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: ClayDecoration(
              color: color,
              radius: size / 2,
              depth: (size * 0.14).clamp(3.0, 6.0),
              lift: 6 + 4 * h,
              pressed: press.clamp(0.0, 1.0),
              shadowOpacity: 0.24,
              edgeOpacity: 0.12,
              highlightColor: _lighter(color),
              highlightOpacity: 0.85,
              shadeColor: _darker(color),
              shadeOpacity: 0.55,
              shadowColor: _darker(color),
            ),
            child: showIcon ? Icon(Icons.colorize_rounded, size: size * 0.5, color: iconColor) : null,
          );
        },
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final original = color;
    var touched = false;
    Offset? origin;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      origin = box.localToGlobal(box.size.center(Offset.zero));
    }

    final applied = await showClayDialog<bool>(
      context: context,
      origin: origin,
      builder: (dialogCtx) => ClayDialog(
        title: 'Colour',
        width: 340,
        padding: const EdgeInsets.all(24),
        actions: [
          ClayButton.text(label: 'Cancel', onPressed: () => Navigator.of(dialogCtx).pop(false)),
          ClayButton.primary(label: 'Apply', onPressed: () => Navigator.of(dialogCtx).pop(true)),
        ],
        child: ClayWell(
          padding: const EdgeInsets.all(6),
          radius: 20,
          child: ColorPicker(
            pickerColor: original,
            onColorChanged: (c) {
              touched = true;
              onColorChanged(c);
            },
            colorPickerWidth: 280,
            portraitOnly: true,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaBorderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );

    // Dismissed or cancelled after a live change: put the colour back.
    if (applied != true && touched) onColorChanged(original);
  }
}
