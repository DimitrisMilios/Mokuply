import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';

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

  // Platform-independent layout offsets for Apple vs Google Play
  final double? appStoreOffsetX;
  final double? appStoreOffsetY;
  final double? googlePlayOffsetX;
  final double? googlePlayOffsetY;

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
    this.appStoreOffsetX,
    this.appStoreOffsetY,
    this.googlePlayOffsetX,
    this.googlePlayOffsetY,
  });

  double offsetXFor(TargetPlatformType platform) {
    if (platform == TargetPlatformType.appStore) {
      return appStoreOffsetX ?? offsetX;
    } else {
      return googlePlayOffsetX ?? offsetX;
    }
  }

  double offsetYFor(TargetPlatformType platform) {
    if (platform == TargetPlatformType.appStore) {
      return appStoreOffsetY ?? offsetY;
    } else {
      return googlePlayOffsetY ?? offsetY;
    }
  }

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
    double? appStoreOffsetX,
    double? appStoreOffsetY,
    double? googlePlayOffsetX,
    double? googlePlayOffsetY,
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
      appStoreOffsetX: appStoreOffsetX ?? this.appStoreOffsetX,
      appStoreOffsetY: appStoreOffsetY ?? this.appStoreOffsetY,
      googlePlayOffsetX: googlePlayOffsetX ?? this.googlePlayOffsetX,
      googlePlayOffsetY: googlePlayOffsetY ?? this.googlePlayOffsetY,
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
      'appStoreOffsetX': appStoreOffsetX,
      'appStoreOffsetY': appStoreOffsetY,
      'googlePlayOffsetX': googlePlayOffsetX,
      'googlePlayOffsetY': googlePlayOffsetY,
    };
  }

  factory CanvasTextItem.fromJson(Map<String, dynamic> json) {
    final weightIdx = json['weightIndex'] as int? ?? 5;
    return CanvasTextItem(
      id: json['id'] as String? ?? 'txt_${DateTime.now().millisecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
      font: json['font'] as String? ?? 'Outfit',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 32.0,
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
      appStoreOffsetX: (json['appStoreOffsetX'] as num?)?.toDouble(),
      appStoreOffsetY: (json['appStoreOffsetY'] as num?)?.toDouble(),
      googlePlayOffsetX: (json['googlePlayOffsetX'] as num?)?.toDouble(),
      googlePlayOffsetY: (json['googlePlayOffsetY'] as num?)?.toDouble(),
    );
  }
}
