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
}
