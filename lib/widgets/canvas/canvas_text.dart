import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/layout/canvas_geometry.dart';

/// A text block sized in design space. Short text hugs its content (so the
/// stored offset is its centre); long text wraps at the design width.
class CanvasText extends StatelessWidget {
  final String text;
  final String font;
  final double fontSize;
  final Color color;
  final FontWeight weight;
  final TextAlign alignment;
  final CanvasGeometry geometry;
  final double horizontalPadding;

  const CanvasText({
    super.key,
    required this.text,
    required this.font,
    required this.fontSize,
    required this.color,
    required this.weight,
    required this.alignment,
    required this.geometry,
    required this.horizontalPadding,
  });

  TextStyle _style() {
    final double size = fontSize * geometry.textScale;
    try {
      return GoogleFonts.getFont(
        font,
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.15,
        decoration: TextDecoration.none,
      );
    } catch (_) {
      return TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontFamily: font,
        height: 1.15,
        decoration: TextDecoration.none,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: geometry.maxTextWidth),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding * geometry.textScale),
        child: Text(text, textAlign: alignment, style: _style()),
      ),
    );
  }
}
