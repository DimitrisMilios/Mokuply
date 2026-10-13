import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import 'element_kind.dart';

/// One text element of a screen (the headline, the subtitle or an extra text)
/// seen through a single shape, so the inspector edits all three alike.
@immutable
class TextElement {
  final String id;
  final ElementKind kind;
  final String text;
  final String font;
  final double fontSize;
  final FontWeight weight;
  final Color color;
  final TextAlign alignment;

  /// Always 0 for the headline and subtitle, which cannot rotate.
  final double rotation;

  const TextElement({
    required this.id,
    required this.kind,
    required this.text,
    required this.font,
    required this.fontSize,
    required this.weight,
    required this.color,
    required this.alignment,
    this.rotation = 0,
  });

  @override
  bool operator ==(Object other) =>
      other is TextElement &&
      other.id == id &&
      other.kind == kind &&
      other.text == text &&
      other.font == font &&
      other.fontSize == fontSize &&
      other.weight == weight &&
      other.color == color &&
      other.alignment == alignment &&
      other.rotation == rotation;

  @override
  int get hashCode => Object.hash(id, kind, text, font, fontSize, weight, color, alignment, rotation);

  bool get isHeadline => kind.isHeadline;
  bool get supportsRotation => kind == ElementKind.text;

  /// Font size range in export pixels, shared by the slider and the corner handles.
  double get minSize => switch (kind) {
    ElementKind.title => TextSizeLimits.titleMin,
    ElementKind.subtitle => TextSizeLimits.subtitleMin,
    _ => TextSizeLimits.customMin,
  };

  double get maxSize => switch (kind) {
    ElementKind.title => TextSizeLimits.titleMax,
    ElementKind.subtitle => TextSizeLimits.subtitleMax,
    _ => TextSizeLimits.customMax,
  };
}
