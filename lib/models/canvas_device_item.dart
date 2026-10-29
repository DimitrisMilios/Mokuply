import 'package:flutter/foundation.dart';
import '../core/constants/store_specs.dart';
import 'template_assets.dart';

/// A phone frame placed on the canvas.
///
/// Position, size and tilt are shared by every store. Only the screenshot
/// inside the frame differs: [iosScreenshotBytes] is shown on the App Store
/// and [androidScreenshotBytes] on Google Play, each falling back to the other
/// when it has not been uploaded yet.
@immutable
class CanvasDeviceItem {
  final String id;
  final DeviceFrameStyle frameStyle;
  final Uint8List? iosScreenshotBytes;
  final Uint8List? androidScreenshotBytes;
  final double scale;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final bool hasShadow;

  const CanvasDeviceItem({
    required this.id,
    this.frameStyle = DeviceFrameStyle.realistic,
    this.iosScreenshotBytes,
    this.androidScreenshotBytes,
    this.scale = 0.92,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
    this.hasShadow = true,
  });

  /// Screenshot rendered for [platform], falling back to the other store's image.
  Uint8List? screenshotFor(TargetPlatformType platform) {
    return platform == TargetPlatformType.appStore
        ? (iosScreenshotBytes ?? androidScreenshotBytes)
        : (androidScreenshotBytes ?? iosScreenshotBytes);
  }

  /// True when a screenshot was uploaded specifically for [platform].
  bool hasOwnScreenshotFor(TargetPlatformType platform) {
    return platform == TargetPlatformType.appStore ? iosScreenshotBytes != null : androidScreenshotBytes != null;
  }

  bool get hasAnyScreenshot => iosScreenshotBytes != null || androidScreenshotBytes != null;

  CanvasDeviceItem withScreenshotFor(TargetPlatformType platform, Uint8List? bytes) {
    return platform == TargetPlatformType.appStore
        ? copyWith(iosScreenshotBytes: () => bytes)
        : copyWith(androidScreenshotBytes: () => bytes);
  }

  CanvasDeviceItem copyWith({
    String? id,
    DeviceFrameStyle? frameStyle,
    Uint8List? Function()? iosScreenshotBytes,
    Uint8List? Function()? androidScreenshotBytes,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    bool? hasShadow,
  }) {
    return CanvasDeviceItem(
      id: id ?? this.id,
      frameStyle: frameStyle ?? this.frameStyle,
      iosScreenshotBytes: iosScreenshotBytes != null ? iosScreenshotBytes() : this.iosScreenshotBytes,
      androidScreenshotBytes: androidScreenshotBytes != null ? androidScreenshotBytes() : this.androidScreenshotBytes,
      scale: scale ?? this.scale,
      offsetX: offsetX ?? this.offsetX,
      offsetY: offsetY ?? this.offsetY,
      rotation: rotation ?? this.rotation,
      hasShadow: hasShadow ?? this.hasShadow,
    );
  }

  /// Screenshots are written only through [assets] (see [AssetWriter]).
  Map<String, dynamic> toJson({AssetWriter? assets}) {
    return {
      'id': id,
      'frameStyle': frameStyle.name,
      if (assets != null && iosScreenshotBytes != null) 'iosScreenshot': assets(iosScreenshotBytes!),
      if (assets != null && androidScreenshotBytes != null) 'androidScreenshot': assets(androidScreenshotBytes!),
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'rotation': rotation,
      'hasShadow': hasShadow,
    };
  }

  /// Reads both the current format and the legacy per-store format
  /// (`appStoreOffsetX`, `iphone16ProMax`, ...) produced by older drafts.
  factory CanvasDeviceItem.fromJson(Map<String, dynamic> json, {AssetReader? assets}) {
    return CanvasDeviceItem(
      id: json['id'] as String? ?? 'dev_${DateTime.now().millisecondsSinceEpoch}',
      frameStyle: DeviceFrameStyle.fromName(json['frameStyle'] as String?),
      iosScreenshotBytes: readAsset(json['iosScreenshot'], assets),
      androidScreenshotBytes: readAsset(json['androidScreenshot'], assets),
      scale: (json['scale'] as num?)?.toDouble() ?? 0.92,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      hasShadow: json['hasShadow'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasDeviceItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          frameStyle == other.frameStyle &&
          iosScreenshotBytes == other.iosScreenshotBytes &&
          androidScreenshotBytes == other.androidScreenshotBytes &&
          scale == other.scale &&
          offsetX == other.offsetX &&
          offsetY == other.offsetY &&
          rotation == other.rotation &&
          hasShadow == other.hasShadow;

  @override
  int get hashCode => Object.hash(
        id,
        frameStyle,
        iosScreenshotBytes,
        androidScreenshotBytes,
        scale,
        offsetX,
        offsetY,
        rotation,
        hasShadow,
      );
}
