import 'package:flutter/material.dart';

/// Immutable model representing an individual text element on the mockup canvas.
@immutable
class CanvasTextItem {
  final String id;
  final String text;
  final String font;
  final double fontSize;
  final Color color;
  final FontWeight weight;
  final TextAlign alignment;
  final double offsetX;
  final double offsetY;
  final double rotation;

  const CanvasTextItem({
    required this.id,
    required this.text,
    this.font = 'Outfit',
    this.fontSize = 32.0,
    this.color = Colors.white,
    this.weight = FontWeight.w600,
    this.alignment = TextAlign.center,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
  });

  CanvasTextItem copyWith({
    String? id,
    String? text,
    String? font,
    double? fontSize,
    Color? color,
    FontWeight? weight,
    TextAlign? alignment,
    double? offsetX,
    double? offsetY,
    double? rotation,
  }) {
    return CanvasTextItem(
      id: id ?? this.id,
      text: text ?? this.text,
      font: font ?? this.font,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      alignment: alignment ?? this.alignment,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
    );
  }
}
