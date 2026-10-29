import 'package:flutter/foundation.dart';
import 'template_assets.dart';

/// A standalone custom image asset placed on the canvas.
/// Position, size and tilt are shared by every store.
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

  const CanvasImageItem({
    required this.id,
    required this.imageBytes,
    this.scale = 1.0,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.rotation = 0.0,
    this.opacity = 1.0,
    this.hasShadow = false,
  });

  CanvasImageItem copyWith({
    String? id,
    Uint8List? imageBytes,
    double? scale,
    double? offsetX,
    double? offsetY,
    double? rotation,
    double? opacity,
    bool? hasShadow,
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
    );
  }

  /// Image layers only exist in template zips, so the bytes always go
  /// through [assets].
  Map<String, dynamic> toJson(AssetWriter assets) {
    return {
      'id': id,
      'image': assets(imageBytes),
      'scale': scale,
      'offsetX': offsetX,
      'offsetY': offsetY,
      'rotation': rotation,
      'opacity': opacity,
      'hasShadow': hasShadow,
    };
  }

  /// Null when the image itself is missing from the zip.
  static CanvasImageItem? fromJson(Map<String, dynamic> json, AssetReader? assets) {
    final bytes = readAsset(json['image'], assets);
    if (bytes == null) return null;
    return CanvasImageItem(
      id: json['id'] as String? ?? 'img_${DateTime.now().millisecondsSinceEpoch}',
      imageBytes: bytes,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0.0,
      offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      hasShadow: json['hasShadow'] as bool? ?? false,
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
          hasShadow == other.hasShadow;

  @override
  int get hashCode => Object.hash(id, imageBytes, scale, offsetX, offsetY, rotation, opacity, hasShadow);
}
