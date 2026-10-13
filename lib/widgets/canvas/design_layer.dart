import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../core/layout/canvas_geometry.dart';
import '../../core/layout/element_drag_math.dart';
import '../../core/layout/layout_anchors.dart';
import '../../models/canvas_device_item.dart';
import '../../models/canvas_image_item.dart';
import '../../models/canvas_text_item.dart';
import '../../models/element_kind.dart';
import '../../models/template_data.dart';
import 'canvas_actions.dart';
import 'canvas_text.dart';
import 'device_frame/device_frame_widget.dart';
import 'element/canvas_element.dart';
import 'snap_guide_overlay.dart';

/// Every design element of one screen, bottom to top (frames, images,
/// subtitle, title, extra text), plus the snap-guide overlay in the editor.
class DesignLayer extends StatefulWidget {
  final TemplateData data;
  final CanvasGeometry geometry;

  /// Null on exports and in preview mode.
  final CanvasActions? actions;
  final String? selectedElementId;

  /// Device-pixel decode factor for previews; null decodes at native size.
  final double? decodeFactor;

  /// True on the export capture: no preview-only placeholder or chrome.
  final bool isExporting;

  const DesignLayer({
    super.key,
    required this.data,
    required this.geometry,
    required this.actions,
    required this.selectedElementId,
    required this.decodeFactor,
    required this.isExporting,
  });

  @override
  State<DesignLayer> createState() => _DesignLayerState();
}

class _DesignLayerState extends State<DesignLayer> {
  final ValueNotifier<SnapGuides> _guides = ValueNotifier(SnapGuides.none);

  @override
  void dispose() {
    _guides.dispose();
    super.dispose();
  }

  TemplateData get _data => widget.data;
  CanvasGeometry get _geometry => widget.geometry;

  int? _decodeWidth(double drawnWidth, double elementScale) {
    final factor = widget.decodeFactor;
    return factor == null ? null : (drawnWidth * elementScale * factor).round();
  }

  void _snap(SnapGuides g) => _guides.value = g;

  @override
  Widget build(BuildContext context) {
    final anchors = LayoutAnchors.forMode(_data.layoutMode);
    final devices = _data.effectiveDevices;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final device in devices) _device(device, anchors, canDelete: devices.length > 1),
        for (final image in _data.customImageItems) _image(image),
        if (_data.subtitleText.isNotEmpty) _subtitle(anchors),
        if (_data.titleText.isNotEmpty) _title(anchors),
        for (final item in _data.customTextItems) _text(item),
        if (widget.actions != null) Positioned.fill(child: SnapGuideOverlay(guides: _guides)),
      ],
    );
  }

  CanvasElement _element({
    required String id,
    required double anchor,
    required Offset offset,
    double rotation = 0.0,
    double scale = 1.0,
    required ResizeSpec resize,
    required double radius,
    required double border,
    bool canDelete = true,
    required Widget child,
  }) {
    final kind = ElementKind.of(id);
    return CanvasElement(
      key: ValueKey(id),
      elementId: id,
      geometry: _geometry,
      anchorFraction: anchor,
      offset: offset,
      rotation: rotation,
      scale: scale,
      resize: resize,
      actions: widget.actions,
      isSelected: widget.selectedElementId == id,
      canRotate: kind?.isFreeform ?? false,
      canDuplicate: kind?.isFreeform ?? false,
      canDelete: canDelete,
      isText: kind == ElementKind.title || kind == ElementKind.subtitle || kind == ElementKind.text,
      borderRadius: radius,
      borderWidth: border,
      onSnap: _snap,
      child: child,
    );
  }

  Widget _device(CanvasDeviceItem device, LayoutAnchors anchors, {required bool canDelete}) {
    return _element(
      id: device.id,
      anchor: anchors.device,
      offset: Offset(device.offsetX, device.offsetY),
      rotation: device.rotation,
      scale: device.scale * LayoutAnchors.deviceScaleBoost(_data.layoutMode),
      resize: ResizeSpec(device.scale, ScaleLimits.deviceMin, ScaleLimits.deviceMax),
      radius: 32,
      border: 2.5,
      canDelete: canDelete,
      child: DeviceFrameWidget(
        frameStyle: device.frameStyle,
        screenshotBytes: device.screenshotFor(_data.platform),
        hasShadow: device.hasShadow,
        platform: _data.platform,
        scale: _geometry.scale,
        decodeWidth: _decodeWidth(DeviceFrameWidget.bodyWidthFor(_geometry.scale), device.scale),
        previewPlaceholder: !widget.isExporting,
      ),
    );
  }

  Widget _image(CanvasImageItem image) {
    // Width fixed in design space; height follows the image aspect ratio.
    final double width = DesignSpace.width * DesignSpace.customImageWidthFraction * _geometry.scale;
    final double s = _geometry.scale;
    return _element(
      id: image.id,
      anchor: LayoutAnchors.freeElement,
      offset: Offset(image.offsetX, image.offsetY),
      rotation: image.rotation,
      scale: image.scale,
      resize: ResizeSpec(image.scale, ScaleLimits.imageMin, ScaleLimits.imageMax),
      radius: 8,
      border: 2.0,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: image.hasShadow
              ? [BoxShadow(color: Colors.black38, blurRadius: 40 * s, spreadRadius: 4 * s, offset: Offset(0, 18 * s))]
              : null,
        ),
        child: Opacity(
          opacity: image.opacity,
          child: SizedBox(
            width: width,
            child: Image.memory(
              image.imageBytes,
              fit: BoxFit.contain,
              cacheWidth: _decodeWidth(width, image.scale),
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }

  Widget _subtitle(LayoutAnchors anchors) {
    return _element(
      id: ElementKind.subtitleId,
      anchor: anchors.subtitle,
      offset: Offset(_data.subtitleOffsetX, _data.subtitleOffsetY),
      resize: ResizeSpec(_data.subtitleSize, TextSizeLimits.subtitleMin, TextSizeLimits.subtitleMax),
      radius: 6,
      border: 2.0,
      child: CanvasText(
        text: _data.subtitleText,
        font: _data.subtitleFont,
        fontSize: _data.subtitleSize,
        color: _data.subtitleColor,
        weight: _data.subtitleWeight,
        alignment: _data.subtitleAlignment,
        geometry: _geometry,
        horizontalPadding: 24,
      ),
    );
  }

  Widget _title(LayoutAnchors anchors) {
    return _element(
      id: ElementKind.titleId,
      anchor: anchors.title,
      offset: Offset(_data.textOffsetX, _data.textOffsetY),
      resize: ResizeSpec(_data.titleSize, TextSizeLimits.titleMin, TextSizeLimits.titleMax),
      radius: 6,
      border: 2.0,
      child: CanvasText(
        text: _data.titleText,
        font: _data.titleFont,
        fontSize: _data.titleSize,
        color: _data.textColor,
        weight: _data.titleWeight,
        alignment: _data.titleAlignment,
        geometry: _geometry,
        horizontalPadding: 16,
      ),
    );
  }

  Widget _text(CanvasTextItem item) {
    return _element(
      id: item.id,
      anchor: LayoutAnchors.freeElement,
      offset: Offset(item.offsetX, item.offsetY),
      rotation: item.rotation,
      resize: ResizeSpec(item.fontSize, TextSizeLimits.customMin, TextSizeLimits.customMax),
      radius: 6,
      border: 2.0,
      child: CanvasText(
        text: item.text,
        font: item.font,
        fontSize: item.fontSize,
        color: item.color,
        weight: item.weight,
        alignment: item.alignment,
        geometry: _geometry,
        horizontalPadding: 16,
      ),
    );
  }
}
