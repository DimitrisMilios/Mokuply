import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/canvas_geometry.dart';
import '../../models/template_data.dart';
import '../../viewmodels/editor_viewmodel.dart';
import 'device_frame_widget.dart';

/// Renders one screen of the project onto a canvas of any size.
///
/// The screen is authored in [DesignSpace]; [CanvasGeometry] maps it onto
/// [canvasSize] with one uniform scale, so the preview card, the Apple export
/// and the Google Play export all show the identical composition. When
/// [isExporting] is false the elements are hoverable, selectable and draggable.
class CanvasMockupWidget extends StatelessWidget {
  final TemplateData data;
  final int itemIndex;
  final Size canvasSize;
  final bool isExporting;

  const CanvasMockupWidget({
    super.key,
    required this.data,
    this.itemIndex = 0,
    required this.canvasSize,
    this.isExporting = false,
  });

  BoxDecoration get _backgroundDecoration {
    if (data.customBackgroundColor != null) {
      return BoxDecoration(color: data.customBackgroundColor);
    }
    if (data.customGradientColors != null && data.customGradientColors!.isNotEmpty) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.customGradientColors!,
        ),
      );
    }
    final preset = StoreSpecs.gradientPresets[data.selectedGradientIndex % StoreSpecs.gradientPresets.length];
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: preset.colors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geometry = CanvasGeometry(canvasSize);
    final vm = isExporting ? null : Provider.of<EditorViewModel>(context, listen: false);
    final decoration = _backgroundDecoration;

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
                  gaplessPlayback: true,
                ),
              ),
            _buildDesignLayer(vm, geometry),
          ],
        ),
      ),
    );

    if (vm != null) {
      // Tapping empty background deselects, so the inspector returns to the
      // screen settings. Elements claim their own pointers, so this never
      // fires for a tap on a phone, image or text.
      canvas = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          vm.selectScreenshot(itemIndex);
          vm.selectElement(null);
        },
        child: canvas,
      );
    }

    return canvas;
  }

  Widget _buildDesignLayer(EditorViewModel? vm, CanvasGeometry geometry) {
    final anchors = _LayoutAnchors.forMode(data.layoutMode);
    final platform = data.platform;

    void select(String id) {
      if (vm == null) return;
      vm.selectScreenshot(itemIndex);
      vm.selectElement(id);
    }

    void move(String id, Offset units) => vm?.moveElement(itemIndex, id, units.dx, units.dy);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. Phone frames
        for (final device in data.effectiveDevices)
          _CanvasElement(
            key: ValueKey(device.id),
            elementId: device.id,
            geometry: geometry,
            anchorFraction: anchors.device,
            offsetX: device.offsetX,
            offsetY: device.offsetY,
            rotation: device.rotation,
            scale: device.scale * (data.layoutMode == LayoutMode.fullBleedHero ? 1.15 : 1.0),
            interactive: vm != null,
            isSelected: vm != null && (vm.selectedElementId == device.id || vm.selectedDeviceId == device.id),
            borderRadius: 32,
            borderWidth: 2.5,
            onSelect: select,
            onMoved: move,
            child: DeviceFrameWidget(
              frameStyle: device.frameStyle,
              screenshotBytes: device.screenshotFor(platform),
              hasShadow: device.hasShadow,
              platform: platform,
              scale: geometry.scale,
            ),
          ),

        // 2. Custom image assets
        for (final image in data.customImageItems)
          _CanvasElement(
            key: ValueKey(image.id),
            elementId: image.id,
            geometry: geometry,
            anchorFraction: 0.5,
            offsetX: image.offsetX,
            offsetY: image.offsetY,
            rotation: image.rotation,
            scale: image.scale,
            interactive: vm != null,
            isSelected: vm != null && (vm.selectedElementId == image.id || vm.selectedImageId == image.id),
            borderRadius: 8,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: image.hasShadow
                    ? [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 40 * geometry.scale,
                          spreadRadius: 4 * geometry.scale,
                          offset: Offset(0, 18 * geometry.scale),
                        ),
                      ]
                    : null,
              ),
              child: Opacity(
                opacity: image.opacity,
                child: SizedBox(
                  // Width fixed in design space; height follows the image aspect ratio.
                  width: DesignSpace.width * DesignSpace.customImageWidthFraction * geometry.scale,
                  child: Image.memory(image.imageBytes, fit: BoxFit.contain, gaplessPlayback: true),
                ),
              ),
            ),
          ),

        // 3. Subtitle
        if (data.subtitleText.isNotEmpty)
          _CanvasElement(
            key: const ValueKey('subtitle'),
            elementId: 'subtitle',
            geometry: geometry,
            anchorFraction: anchors.subtitle,
            offsetX: data.subtitleOffsetX,
            offsetY: data.subtitleOffsetY,
            interactive: vm != null,
            isSelected: vm?.selectedElementId == 'subtitle',
            borderRadius: 6,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            child: _CanvasText(
              text: data.subtitleText,
              font: data.subtitleFont,
              fontSize: data.subtitleSize,
              color: data.subtitleColor,
              weight: data.subtitleWeight,
              alignment: data.subtitleAlignment,
              geometry: geometry,
              horizontalPadding: 24,
            ),
          ),

        // 4. Title
        if (data.titleText.isNotEmpty)
          _CanvasElement(
            key: const ValueKey('title'),
            elementId: 'title',
            geometry: geometry,
            anchorFraction: anchors.title,
            offsetX: data.textOffsetX,
            offsetY: data.textOffsetY,
            interactive: vm != null,
            isSelected: vm?.selectedElementId == 'title',
            borderRadius: 6,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            child: _CanvasText(
              text: data.titleText,
              font: data.titleFont,
              fontSize: data.titleSize,
              color: data.textColor,
              weight: data.titleWeight,
              alignment: data.titleAlignment,
              geometry: geometry,
              horizontalPadding: 16,
            ),
          ),

        // 5. Extra text elements
        for (final item in data.customTextItems)
          _CanvasElement(
            key: ValueKey(item.id),
            elementId: item.id,
            geometry: geometry,
            anchorFraction: 0.5,
            offsetX: item.offsetX,
            offsetY: item.offsetY,
            rotation: item.rotation,
            interactive: vm != null,
            isSelected: vm != null && (vm.selectedElementId == item.id || vm.selectedTextId == item.id),
            borderRadius: 6,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            child: _CanvasText(
              text: item.text,
              font: item.font,
              fontSize: item.fontSize,
              color: item.color,
              weight: item.weight,
              alignment: item.alignment,
              geometry: geometry,
              horizontalPadding: 16,
            ),
          ),
      ],
    );
  }
}

/// Vertical anchors (fractions of the design height) for each layout preset.
class _LayoutAnchors {
  final double title;
  final double subtitle;
  final double device;

  const _LayoutAnchors({required this.title, required this.subtitle, required this.device});

  static _LayoutAnchors forMode(LayoutMode mode) {
    switch (mode) {
      case LayoutMode.angledLeftHero:
      case LayoutMode.angledRightHero:
      case LayoutMode.titleTopDeviceBottom:
        return const _LayoutAnchors(title: 0.08, subtitle: 0.17, device: 0.62);
      case LayoutMode.titleBottomDeviceTop:
        return const _LayoutAnchors(title: 0.74, subtitle: 0.84, device: 0.36);
      case LayoutMode.deviceCentered:
        return const _LayoutAnchors(title: 0.08, subtitle: 0.16, device: 0.54);
      case LayoutMode.fullBleedHero:
        return const _LayoutAnchors(title: 0.08, subtitle: 0.17, device: 0.64);
    }
  }
}

/// A text block sized in design space. Short text hugs its content (so the
/// stored offset is its centre); long text wraps at the design width.
class _CanvasText extends StatelessWidget {
  final String text;
  final String font;
  final double fontSize;
  final Color color;
  final FontWeight weight;
  final TextAlign alignment;
  final CanvasGeometry geometry;
  final double horizontalPadding;

  const _CanvasText({
    required this.text,
    required this.font,
    required this.fontSize,
    required this.color,
    required this.weight,
    required this.alignment,
    required this.geometry,
    required this.horizontalPadding,
  });

  TextStyle _style() {
    final double size = fontSize * geometry.textScale;
    try {
      return GoogleFonts.getFont(
        font,
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: 1.15,
        decoration: TextDecoration.none,
      );
    } catch (_) {
      return TextStyle(
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontFamily: font,
        height: 1.15,
        decoration: TextDecoration.none,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: geometry.maxTextWidth),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding * geometry.textScale),
        child: Text(text, textAlign: alignment, style: _style()),
      ),
    );
  }
}

/// Eager pan recognizer: claims the gesture on pointer down so the outer
/// InteractiveViewer never steals an element drag.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

/// Positions a child at a design-space location and, when interactive, adds
/// hover/selection chrome and drag-to-move. Drag state is local so the canvas
/// stays smooth; the final position is committed once on release.
class _CanvasElement extends StatefulWidget {
  final String elementId;
  final CanvasGeometry geometry;
  final double anchorFraction;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final double scale;
  final bool interactive;
  final bool isSelected;
  final double borderRadius;
  final double borderWidth;
  final void Function(String id)? onSelect;
  final void Function(String id, Offset offsetUnits)? onMoved;
  final Widget child;

  const _CanvasElement({
    super.key,
    required this.elementId,
    required this.geometry,
    required this.anchorFraction,
    required this.offsetX,
    required this.offsetY,
    this.rotation = 0.0,
    this.scale = 1.0,
    required this.interactive,
    required this.isSelected,
    required this.borderRadius,
    required this.borderWidth,
    this.onSelect,
    this.onMoved,
    required this.child,
  });

  @override
  State<_CanvasElement> createState() => _CanvasElementState();
}

class _CanvasElementState extends State<_CanvasElement> {
  bool _hovering = false;
  Offset? _dragOffset;

  bool get _dragging => _dragOffset != null;

  void _startDrag() {
    widget.onSelect?.call(widget.elementId);
    setState(() => _dragOffset = Offset(widget.offsetX, widget.offsetY));
  }

  void _updateDrag(DragUpdateDetails details) {
    final current = _dragOffset ?? Offset(widget.offsetX, widget.offsetY);
    setState(() => _dragOffset = current + widget.geometry.deltaToOffsetUnits(details.delta));
  }

  void _endDrag() {
    final result = _dragOffset;
    setState(() => _dragOffset = null);
    if (result != null) widget.onMoved?.call(widget.elementId, result);
  }

  void _cancelDrag() => setState(() => _dragOffset = null);

  @override
  Widget build(BuildContext context) {
    final offset = _dragOffset ?? Offset(widget.offsetX, widget.offsetY);
    final center = widget.geometry.elementCenter(
      anchorFraction: widget.anchorFraction,
      offsetX: offset.dx,
      offsetY: offset.dy,
    );

    Widget child = widget.child;

    if (widget.interactive) {
      final bool highlighted = widget.isSelected || _hovering || _dragging;
      child = MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
              () => _EagerPanGestureRecognizer(),
              (instance) {
                instance.onStart = (_) => _startDrag();
                instance.onUpdate = _updateDrag;
                instance.onEnd = (_) => _endDrag();
                instance.onCancel = _cancelDrag;
              },
            ),
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: highlighted ? AppColors.primary : Colors.transparent,
                width: highlighted ? widget.borderWidth : 0.0,
              ),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              color: highlighted ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: child,
          ),
        ),
      );
    }

    return Positioned(
      left: center.dx,
      top: center.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(
          angle: widget.rotation * (math.pi / 180),
          child: Transform.scale(scale: widget.scale, child: child),
        ),
      ),
    );
  }
}
