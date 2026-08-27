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

  const CanvasDeviceItem({
    required this.id,
    this.frameStyle = DeviceFrameStyle.iphone16ProMax,
    this.screenshotBytes,
    this.scale = 0.85,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
    this.hasShadow = true,
  });

  CanvasDeviceItem copyWith({
    String? id,
    DeviceFrameStyle? frameStyle,
    Uint8List? Function()? screenshotBytes,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    bool? hasShadow,
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
          hasShadow == other.hasShadow;

  @override
  int get hashCode =>
      id.hashCode ^
      frameStyle.hashCode ^
      screenshotBytes.hashCode ^
      scale.hashCode ^
      offsetX.hashCode ^
      offsetY.hashCode ^
      rotation.hashCode ^
      hasShadow.hashCode;
}
