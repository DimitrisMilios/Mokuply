import 'package:flutter/foundation.dart';
import '../core/constants/store_specs.dart';

/// Data model representing a standalone custom image asset placed on the canvas.
@immutable
class CanvasImageItem {
  final String id;
  final Uint8List imageBytes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final double opacity;
  final bool hasShadow;

  // Platform-independent layout offsets and scales for Apple vs Google Play
  final double? appStoreOffsetX;
  final double? appStoreOffsetY;
  final double? appStoreScale;
  final double? googlePlayOffsetX;
  final double? googlePlayOffsetY;
  final double? googlePlayScale;

  const CanvasImageItem({
    required this.id,
    required this.imageBytes,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.hasShadow = false,
    this.appStoreOffsetX,
    this.appStoreOffsetY,
    this.appStoreScale,
    this.googlePlayOffsetX,
    this.googlePlayOffsetY,
    this.googlePlayScale,
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

  double scaleFor(TargetPlatformType platform) {
    if (platform == TargetPlatformType.appStore) {
      return appStoreScale ?? scale;
    } else {
      return googlePlayScale ?? scale;
    }
  }

  CanvasImageItem copyWith({
    String? id,
    Uint8List? imageBytes,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    double? opacity,
    bool? hasShadow,
    double? appStoreOffsetX,
    double? appStoreOffsetY,
    double? appStoreScale,
    double? googlePlayOffsetX,
    double? googlePlayOffsetY,
    double? googlePlayScale,
  }) {
    return CanvasImageItem(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
      opacity: opacity ?? this.opacity,
      hasShadow: hasShadow ?? this.hasShadow,
      appStoreOffsetX: appStoreOffsetX ?? this.appStoreOffsetX,
      appStoreOffsetY: appStoreOffsetY ?? this.appStoreOffsetY,
      appStoreScale: appStoreScale ?? this.appStoreScale,
      googlePlayOffsetX: googlePlayOffsetX ?? this.googlePlayOffsetX,
      googlePlayOffsetY: googlePlayOffsetY ?? this.googlePlayOffsetY,
      googlePlayScale: googlePlayScale ?? this.googlePlayScale,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasImageItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          imageBytes == other.imageBytes &&
          scale == other.scale &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          rotation == other.rotation &&
          opacity == other.opacity &&
          hasShadow == other.hasShadow &&
          appStoreOffsetX == other.appStoreOffsetX &&
          appStoreOffsetY == other.appStoreOffsetY &&
          appStoreScale == other.appStoreScale &&
          googlePlayOffsetX == other.googlePlayOffsetX &&
          googlePlayOffsetY == other.googlePlayOffsetY &&
          googlePlayScale == other.googlePlayScale;

  @override
  int get hashCode =>
      id.hashCode ^
      imageBytes.hashCode ^
      scale.hashCode ^
      offsetX.hashCode ^
      offsetY.hashCode ^
      rotation.hashCode ^
      opacity.hashCode ^
      hasShadow.hashCode ^
      appStoreOffsetX.hashCode ^
      appStoreOffsetY.hashCode ^
      appStoreScale.hashCode ^
      googlePlayOffsetX.hashCode ^
      googlePlayOffsetY.hashCode ^
      googlePlayScale.hashCode;
}
