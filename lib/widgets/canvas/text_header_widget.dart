import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextHeaderWidget extends StatelessWidget {
  final String titleText;
  final String subtitleText;
  final String titleFont;
  final String subtitleFont;
  final double titleSize;
  final double subtitleSize;
  final Color textColor;
  final Color subtitleColor;
  final double scale;

  const TextHeaderWidget({
    super.key,
    required this.titleText,
    required this.subtitleText,
    required this.titleFont,
    required this.subtitleFont,
    required this.titleSize,
    required this.subtitleSize,
    required this.textColor,
    required this.subtitleColor,
    required this.scale,
  });

  TextStyle getFontTextStyle(String fontName, double fontSize, Color color, FontWeight weight) {
    try {
      return GoogleFonts.getFont(
        fontName,
        fontSize: fontSize * scale,
        color: color,
        fontWeight: weight,
        height: 1.15,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize * scale,
        color: color,
        fontWeight: weight,
        fontFamily: fontName,
        height: 1.15,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 48 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleText.isNotEmpty)
            Text(
              titleText,
              textAlign: TextAlign.center,
              style: getFontTextStyle(
                titleFont,
                titleSize,
                textColor,
                FontWeight.bold,
              ),
            ),
          if (titleText.isNotEmpty && subtitleText.isNotEmpty)
            SizedBox(height: 16 * scale),
          if (subtitleText.isNotEmpty)
            Text(
              subtitleText,
              textAlign: TextAlign.center,
              style: getFontTextStyle(
                subtitleFont,
                subtitleSize,
                subtitleColor,
                FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
