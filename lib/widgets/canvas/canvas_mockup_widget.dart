import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/canvas_geometry.dart';
import '../../models/template_data.dart';
import 'canvas_actions.dart';
import 'design_layer.dart';

/// Renders one screen of the project onto a canvas of any size.
///
/// The screen is authored in [DesignSpace]; [CanvasGeometry] maps it onto
/// [canvasSize] with one uniform scale, so the preview card, the Apple export
/// and the Google Play export all show the identical composition. With
/// [actions] (editor only) the elements are hoverable, selectable,
/// draggable, resizable and rotatable.
class CanvasMockupWidget extends StatelessWidget {
  final TemplateData data;
  final Size canvasSize;
  final bool isExporting;

  /// Null on exports and in preview mode: nothing reacts to the pointer and
  /// no selection chrome is drawn.
  final CanvasActions? actions;

  /// The element drawn as selected on this screen.
  final String? selectedElementId;

  const CanvasMockupWidget({
    super.key,
    required this.data,
    required this.canvasSize,
    this.isExporting = false,
    this.actions,
    this.selectedElementId,
  });

  BoxDecoration get _backgroundDecoration {
    if (data.customBackgroundColor != null) {
      return BoxDecoration(color: data.customBackgroundColor);
    }
    final colors = data.customGradientColors?.isNotEmpty == true
        ? data.customGradientColors!
        : StoreSpecs.gradientPresets[data.selectedGradientIndex % StoreSpecs.gradientPresets.length].colors;
    return BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = isExporting ? null : this.actions;
    final decoration = _backgroundDecoration;
    // Previews decode images near their drawn size (with headroom for canvas
    // zoom); exports decode at native resolution.
    final double? decodeFactor = isExporting ? null : MediaQuery.devicePixelRatioOf(context) * 2.0;

    Widget canvas = Container(
      width: canvasSize.width,
      height: canvasSize.height,
      decoration: decoration.copyWith(color: decoration.color ?? Colors.black),
      child: ClipRect(
        child: Stack(
          children: [
            if (data.customBackgroundImageBytes != null)
              Positioned.fill(
                child: Image.memory(
                  data.customBackgroundImageBytes!,
                  fit: BoxFit.cover,
                  cacheWidth: decodeFactor == null ? null : (canvasSize.width * decodeFactor).round(),
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            DesignLayer(
              data: data,
              geometry: CanvasGeometry(canvasSize),
              actions: actions,
              selectedElementId: actions == null ? null : selectedElementId,
              decodeFactor: decodeFactor,
              isExporting: isExporting,
            ),
          ],
        ),
      ),
    );

    if (actions != null) {
      // Tapping empty background deselects, so the inspector returns to the
      // screen settings. Elements claim their own pointers first.
      canvas = GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => actions.onSelect(null), child: canvas);
    }
    return canvas;
  }
}
