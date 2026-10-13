import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/constants/store_specs.dart';
import '../models/template_data.dart';
import '../widgets/canvas/canvas_mockup_widget.dart';
import 'export_service.dart';

/// Renders screens to store-sized PNGs with the same widget tree the editor
/// previews, so the export always matches the canvas.
class ScreenRenderer {
  ScreenRenderer._();

  /// PNG bytes of [screen] for [target] at the store's export size.
  /// [context] must stay mounted until the render completes (it hosts the
  /// off-screen overlay).
  static Future<Uint8List> renderPng(TemplateData screen, TargetPlatformType target, BuildContext context) {
    final size = target.targetSize;
    return ExportService.captureHighResWidget(
      widget: CanvasMockupWidget(
        data: screen.copyWith(platform: target),
        canvasSize: size,
        isExporting: true,
      ),
      targetSize: size,
      context: context,
    );
  }

  /// Path of screen [index] (0-based) inside a store zip.
  static String zipPath(TargetPlatformType target, int index) => '${target.exportFolderName}/Screen_${index + 1}.png';
}
