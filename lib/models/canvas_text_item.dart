import 'package:flutter/material.dart';

/// An extra text element on the mockup canvas.
/// Position and tilt are shared by every store.
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
    this.fontSize = 40.0,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'font': font,
      'fontSize': fontSize,
      'color': color.toARGB32(),
      'weightIndex': FontWeight.values.indexOf(weight),
      'alignment': alignment.name,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'rotation': rotation,
    };
  }

  /// Legacy per-store offset keys in older drafts are ignored; the shared
  /// `offsetX`/`offsetY` were always written alongside them. [fontScale]
  /// converts font sizes from drafts saved in the old 1000px-wide unit.
  factory CanvasTextItem.fromJson(Map<String, dynamic> json, {double fontScale = 1.0}) {
    final weightIdx = json['weightIndex'] as int? ?? 5;
    return CanvasTextItem(
      id: json['id'] as String? ?? 'txt_${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
      font: json['font'] as String? ?? 'Outfit',
      fontSize: ((json['fontSize'] as num?)?.toDouble() ?? 32.0) * fontScale,
      color: Color(json['color'] as int? ?? 0xFFFFFFFF),
      weight: (weightIdx >= 0 && weightIdx < FontWeight.values.length)
          ? FontWeight.values[weightIdx]
          : FontWeight.w600,
      alignment: TextAlign.values.firstWhere(
        (e) => e.name == json['alignment'],
        orElse: () => TextAlign.center,
      ),
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
