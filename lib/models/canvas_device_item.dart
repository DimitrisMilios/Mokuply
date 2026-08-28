import 'package:flutter/foundation.dart';
import '../core/constants/store_specs.dart';

/// Data model representing a phone frame element placed on the canvas.
@immutable
class CanvasDeviceItem {
  final String id;
  final DeviceFrameStyle frameStyle;
  final Uint8List? screenshotBytes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final bool hasShadow;

  // Platform-independent layout offsets and scales for Apple vs Google Play
  final double? appStoreOffsetX;
  final double? appStoreOffsetY;
  final double? appStoreScale;
  final double? googlePlayOffsetX;
  final double? googlePlayOffsetY;
  final double? googlePlayScale;

  const CanvasDeviceItem({
    required this.id,
    this.frameStyle = DeviceFrameStyle.iphone16ProMax,
    this.screenshotBytes,
    this.scale = 0.85,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
    this.hasShadow = true,
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

  CanvasDeviceItem copyWith({
    String? id,
    DeviceFrameStyle? frameStyle,
    Uint8List? Function()? screenshotBytes,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    bool? hasShadow,
    double? appStoreOffsetX,
    double? appStoreOffsetY,
    double? appStoreScale,
    double? googlePlayOffsetX,
    double? googlePlayOffsetY,
    double? googlePlayScale,
  }) {
    return CanvasDeviceItem(
      id: id ?? this.id,
      frameStyle: frameStyle ?? this.frameStyle,
      screenshotBytes: screenshotBytes != null ? screenshotBytes() : this.screenshotBytes,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
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
      other is CanvasDeviceItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          frameStyle == other.frameStyle &&
          screenshotBytes == other.screenshotBytes &&
          scale == other.scale &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          rotation == other.rotation &&
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
      frameStyle.hashCode ^
      screenshotBytes.hashCode ^
      scale.hashCode ^
      offsetX.hashCode ^
      offsetY.hashCode ^
      rotation.hashCode ^
      hasShadow.hashCode ^
      appStoreOffsetX.hashCode ^
      appStoreOffsetY.hashCode ^
      appStoreScale.hashCode ^
      googlePlayOffsetX.hashCode ^
      googlePlayOffsetY.hashCode ^
      googlePlayScale.hashCode;
}
