import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../clay/clay.dart';
import 'fonts/font_picker_dialog.dart';

/// Shows the current font and opens a searchable picker over the whole free
/// Google Fonts catalogue.
class FontPickerField extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const FontPickerField({super.key, required this.value, required this.onChanged, this.label = 'Font'});

  static TextStyle styleFor(String family, {double fontSize = 14, FontWeight weight = FontWeight.w600, Color? color}) {
    try {
      return GoogleFonts.getFont(family, fontSize: fontSize, fontWeight: weight, color: color);
    } catch (_) {
      return TextStyle(fontFamily: family, fontSize: fontSize, fontWeight: weight, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayDropdown<String>(
      value: value,
      displayText: value,
      label: label,
      // A small sample glyph rendered in the font itself, so the field still
      // previews the choice.
      leading: Text(
        'Aa',
        style: styleFor(value, fontSize: 15, weight: FontWeight.w700, color: AppColors.primary),
      ),
      onOpen: () async {
        final picked = await FontPickerDialog.show(context, current: value);
        if (picked != null && picked != value) onChanged(picked);
      },
    );
  }
}
