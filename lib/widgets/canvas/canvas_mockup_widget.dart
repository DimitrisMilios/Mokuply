import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
/// [isExporting] is false and [interactive] is true the elements are
/// hoverable, selectable, draggable, resizable and rotatable.
class CanvasMockupWidget extends StatelessWidget {
  final TemplateData data;
  final int itemIndex;
  final Size canvasSize;
  final bool isExporting;

  /// False in preview mode: the editor view model is present but nothing on
  /// the canvas reacts to the pointer and no selection chrome is drawn.
  final bool interactive;

  const CanvasMockupWidget({
    super.key,
    required this.data,
    this.itemIndex = 0,
    required this.canvasSize,
    this.isExporting = false,
    this.interactive = true,
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
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: preset.colors),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geometry = CanvasGeometry(canvasSize);
    final EditorViewModel? vm = (isExporting || !interactive)
        ? null
        : Provider.of<EditorViewModel>(context, listen: false);
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
            _DesignLayer(data: data, itemIndex: itemIndex, vm: vm, geometry: geometry, decodeFactor: decodeFactor),
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
}

/// Publishes the workspace zoom to the canvas, so selection chrome (handles,
/// borders) can keep a constant on-screen size whatever the zoom level.
class CanvasViewportZoom extends InheritedNotifier<TransformationController> {
  const CanvasViewportZoom({super.key, required TransformationController controller, required super.child})
    : super(notifier: controller);

  /// Current zoom factor, or 1.0 outside a zoomable workspace.
  static double of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<CanvasViewportZoom>();
    return w?.notifier?.value.getMaxScaleOnAxis() ?? 1.0;
  }
}

/// Vertical and horizontal snap guides shown while an element is dragged, in
/// canvas pixels. Either may be null.
class _SnapGuides {
  final double? x;
  final double? y;
  const _SnapGuides({this.x, this.y});
  static const none = _SnapGuides();

  bool get isEmpty => x == null && y == null;
}

/// All design elements of one screen plus the snap-guide overlay.
class _DesignLayer extends StatefulWidget {
  final TemplateData data;
  final int itemIndex;
  final EditorViewModel? vm;
  final CanvasGeometry geometry;
  final double? decodeFactor;

  const _DesignLayer({
    required this.data,
    required this.itemIndex,
    required this.vm,
    required this.geometry,
    required this.decodeFactor,
  });

  @override
  State<_DesignLayer> createState() => _DesignLayerState();
}

class _DesignLayerState extends State<_DesignLayer> {
  final ValueNotifier<_SnapGuides> _guides = ValueNotifier(_SnapGuides.none);

  @override
  void dispose() {
    _guides.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final vm = widget.vm;
    final geometry = widget.geometry;
    final anchors = _LayoutAnchors.forMode(data.layoutMode);
    final platform = data.platform;
    final double customImageWidth = DesignSpace.width * DesignSpace.customImageWidthFraction * geometry.scale;
    int? decodeWidthFor(double drawnWidth, double elementScale) =>
        widget.decodeFactor == null ? null : (drawnWidth * elementScale * widget.decodeFactor!).round();

    void select(String id) {
      if (vm == null) return;
      vm.selectScreenshot(widget.itemIndex);
      vm.selectElement(id);
    }

    void move(String id, Offset units) => vm?.moveElement(widget.itemIndex, id, units.dx, units.dy);
    void resize(String id, double value) => vm?.resizeElement(widget.itemIndex, id, value);
    void rotate(String id, double deg) => vm?.rotateElement(widget.itemIndex, id, deg);
    void snap(_SnapGuides g) => _guides.value = g;
    final bool interactive = vm != null;
    // Starter templates reuse element ids across screens, so a selection is
    // only a selection on the active screen.
    final bool activeScreen = vm != null && vm.selectedIndex == widget.itemIndex;

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
            resizeValue: device.scale,
            resizeMin: ScaleLimits.deviceMin,
            resizeMax: ScaleLimits.deviceMax,
            interactive: interactive,
            isSelected: activeScreen && (vm.selectedElementId == device.id || vm.selectedDeviceId == device.id),
            borderRadius: 32,
            borderWidth: 2.5,
            onSelect: select,
            onMoved: move,
            onResized: resize,
            onRotated: rotate,
            onDuplicate: vm?.duplicateElement,
            onDelete: data.effectiveDevices.length > 1 ? vm?.removeElement : null,
            onSnap: snap,
            child: DeviceFrameWidget(
              frameStyle: device.frameStyle,
              screenshotBytes: device.screenshotFor(platform),
              hasShadow: device.hasShadow,
              platform: platform,
              scale: geometry.scale,
              decodeWidth: decodeWidthFor(DeviceFrameWidget.bodyWidthFor(geometry.scale), device.scale),
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
            resizeValue: image.scale,
            resizeMin: ScaleLimits.imageMin,
            resizeMax: ScaleLimits.imageMax,
            interactive: interactive,
            isSelected: activeScreen && (vm.selectedElementId == image.id || vm.selectedImageId == image.id),
            borderRadius: 8,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            onResized: resize,
            onRotated: rotate,
            onDuplicate: vm?.duplicateElement,
            onDelete: vm?.removeElement,
            onSnap: snap,
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
                  width: customImageWidth,
                  child: Image.memory(
                    image.imageBytes,
                    fit: BoxFit.contain,
                    cacheWidth: decodeWidthFor(customImageWidth, image.scale),
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                  ),
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
            resizeValue: data.subtitleSize,
            resizeMin: TextSizeLimits.subtitleMin,
            resizeMax: TextSizeLimits.subtitleMax,
            interactive: interactive,
            isSelected: activeScreen && vm.selectedElementId == 'subtitle',
            borderRadius: 6,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            onResized: resize,
            onDoubleTap: vm == null ? null : (_) => vm.requestTextFocus(),
            onDelete: vm?.removeElement,
            onSnap: snap,
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
            resizeValue: data.titleSize,
            resizeMin: TextSizeLimits.titleMin,
            resizeMax: TextSizeLimits.titleMax,
            interactive: interactive,
            isSelected: activeScreen && vm.selectedElementId == 'title',
            borderRadius: 6,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            onResized: resize,
            onDoubleTap: vm == null ? null : (_) => vm.requestTextFocus(),
            onDelete: vm?.removeElement,
            onSnap: snap,
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
            resizeValue: item.fontSize,
            resizeMin: TextSizeLimits.customMin,
            resizeMax: TextSizeLimits.customMax,
            interactive: interactive,
            isSelected: activeScreen && (vm.selectedElementId == item.id || vm.selectedTextId == item.id),
            borderRadius: 6,
            borderWidth: 2.0,
            onSelect: select,
            onMoved: move,
            onResized: resize,
            onRotated: rotate,
            onDoubleTap: vm == null ? null : (_) => vm.requestTextFocus(),
            onDuplicate: vm?.duplicateElement,
            onDelete: vm?.removeElement,
            onSnap: snap,
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

        // 6. Snap guides (editor only)
        if (interactive)
          Positioned.fill(
            child: IgnorePointer(
              child: ValueListenableBuilder<_SnapGuides>(
                valueListenable: _guides,
                builder: (context, guides, child) =>
                    guides.isEmpty ? const SizedBox.shrink() : CustomPaint(painter: _SnapGuidePainter(guides)),
              ),
            ),
          ),
      ],
    );
  }
}

class _SnapGuidePainter extends CustomPainter {
  final _SnapGuides guides;
  const _SnapGuidePainter(this.guides);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.snapGuide
      ..strokeWidth = 1.0;
    final x = guides.x;
    final y = guides.y;
    if (x != null) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    if (y != null) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _SnapGuidePainter old) => old.guides.x != guides.x || old.guides.y != guides.y;
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
/// hover/selection chrome, drag-to-move, corner handles to resize and a
/// rotation handle. Drag state is local so the canvas stays smooth; the
/// final value is committed once on release.
class _CanvasElement extends StatefulWidget {
  final String elementId;
  final CanvasGeometry geometry;
  final double anchorFraction;
  final double offsetX;
  final double offsetY;
  final double rotation;
  final double scale;

  /// The model value the corner handles edit: a scale factor for phone
  /// frames and images, a font size for text.
  final double resizeValue;
  final double resizeMin;
  final double resizeMax;

  final bool interactive;
  final bool isSelected;
  final double borderRadius;
  final double borderWidth;
  final void Function(String id)? onSelect;
  final void Function(String id, Offset offsetUnits)? onMoved;
  final void Function(String id, double value)? onResized;
  final void Function(String id, double degrees)? onRotated;
  final void Function(String id)? onDoubleTap;
  final void Function(String id)? onDuplicate;
  final void Function(String id)? onDelete;
  final void Function(_SnapGuides guides)? onSnap;
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
    required this.resizeValue,
    required this.resizeMin,
    required this.resizeMax,
    required this.interactive,
    required this.isSelected,
    required this.borderRadius,
    required this.borderWidth,
    this.onSelect,
    this.onMoved,
    this.onResized,
    this.onRotated,
    this.onDoubleTap,
    this.onDuplicate,
    this.onDelete,
    this.onSnap,
    required this.child,
  });

  @override
  State<_CanvasElement> createState() => _CanvasElementState();
}

class _CanvasElementState extends State<_CanvasElement> {
  static const double _handleSize = 10.0;
  static const double _rotateHandleGap = 26.0;
  static const double _snapPixels = 6.0;
  static const Duration _doubleTapWindow = Duration(milliseconds: 320);

  bool _hovering = false;

  // Move drag
  Offset? _dragOffset;
  Offset _dragStartPointer = Offset.zero;
  Offset _dragStartOffset = Offset.zero;

  // Resize drag
  double _resizeFactor = 1.0;
  bool _resizing = false;
  double _resizeStartDistance = 1.0;

  // Rotate drag
  double? _dragRotation;
  double _rotateStartAngle = 0.0;
  double _rotateStartDegrees = 0.0;

  DateTime? _lastPointerDown;

  bool get _dragging => _dragOffset != null;
  bool get _busy => _dragging || _resizing || _dragRotation != null;

  Offset get _currentOffset => _dragOffset ?? Offset(widget.offsetX, widget.offsetY);

  /// Canvas-pixel centre of the element as currently displayed.
  Offset get _center => widget.geometry.elementCenter(
    anchorFraction: widget.anchorFraction,
    offsetX: _currentOffset.dx,
    offsetY: _currentOffset.dy,
  );

  /// Converts a global pointer position into canvas pixels. Using the canvas
  /// box (not the element's own, rotated and scaled box) keeps drags correct
  /// whatever the element's tilt, size or the viewport zoom.
  Offset _toCanvas(Offset global) {
    final box = context.findAncestorRenderObjectOfType<RenderStack>();
    if (box == null) return global;
    return box.globalToLocal(global);
  }

  // --- Move ---

  void _startMove(DragStartDetails d) {
    widget.onSelect?.call(widget.elementId);
    _dragStartPointer = _toCanvas(d.globalPosition);
    _dragStartOffset = Offset(widget.offsetX, widget.offsetY);
    setState(() => _dragOffset = _dragStartOffset);
  }

  void _updateMove(DragUpdateDetails d) {
    final canvasDelta = _toCanvas(d.globalPosition) - _dragStartPointer;
    Offset next = _dragStartOffset + widget.geometry.deltaToOffsetUnits(canvasDelta);

    // Snap to the horizontal centre and to the element's natural anchor line.
    final threshold = widget.geometry.deltaToOffsetUnits(const Offset(_snapPixels, _snapPixels));
    double? guideX;
    double? guideY;
    if (next.dx.abs() < threshold.dx) {
      next = Offset(0, next.dy);
      guideX = widget.geometry.canvasCenter.dx;
    }
    if (next.dy.abs() < threshold.dy) {
      next = Offset(next.dx, 0);
      guideY = widget.geometry.anchorY(widget.anchorFraction);
    }
    widget.onSnap?.call(_SnapGuides(x: guideX, y: guideY));
    setState(() => _dragOffset = next);
  }

  void _endMove() {
    final result = _dragOffset;
    widget.onSnap?.call(_SnapGuides.none);
    setState(() => _dragOffset = null);
    if (result != null) widget.onMoved?.call(widget.elementId, result);
  }

  void _cancelMove() {
    widget.onSnap?.call(_SnapGuides.none);
    setState(() => _dragOffset = null);
  }

  // --- Resize (corner handles) ---

  void _startResize(DragStartDetails d) {
    widget.onSelect?.call(widget.elementId);
    _resizeStartDistance = math.max(1.0, (_toCanvas(d.globalPosition) - _center).distance);
    setState(() {
      _resizing = true;
      _resizeFactor = 1.0;
    });
  }

  void _updateResize(DragUpdateDetails d) {
    final distance = (_toCanvas(d.globalPosition) - _center).distance;
    final raw = distance / _resizeStartDistance;
    final minFactor = widget.resizeMin / widget.resizeValue;
    final maxFactor = widget.resizeMax / widget.resizeValue;
    setState(() => _resizeFactor = raw.clamp(minFactor, maxFactor));
  }

  void _endResize() {
    final factor = _resizeFactor;
    setState(() {
      _resizing = false;
      _resizeFactor = 1.0;
    });
    if ((factor - 1.0).abs() > 0.001) {
      widget.onResized?.call(widget.elementId, widget.resizeValue * factor);
    }
  }

  void _cancelResize() => setState(() {
    _resizing = false;
    _resizeFactor = 1.0;
  });

  // --- Rotate (top handle) ---

  void _startRotate(DragStartDetails d) {
    widget.onSelect?.call(widget.elementId);
    final v = _toCanvas(d.globalPosition) - _center;
    _rotateStartAngle = math.atan2(v.dy, v.dx);
    _rotateStartDegrees = widget.rotation;
    setState(() => _dragRotation = widget.rotation);
  }

  void _updateRotate(DragUpdateDetails d) {
    final v = _toCanvas(d.globalPosition) - _center;
    final angle = math.atan2(v.dy, v.dx);
    double deg = _rotateStartDegrees + (angle - _rotateStartAngle) * 180 / math.pi;
    // Snap to 15° steps when close, so 0°, ±15° and ±90° are easy to hit.
    final nearest = (deg / 15).round() * 15.0;
    if ((deg - nearest).abs() < 3) deg = nearest;
    setState(() => _dragRotation = deg);
  }

  void _endRotate() {
    final result = _dragRotation;
    setState(() => _dragRotation = null);
    if (result != null) widget.onRotated?.call(widget.elementId, result);
  }

  void _cancelRotate() => setState(() => _dragRotation = null);

  // --- Pointer bookkeeping: double-click and right-click ---

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons & kSecondaryButton != 0) {
      widget.onSelect?.call(widget.elementId);
      _showContextMenu(event.position);
      return;
    }
    final now = DateTime.now();
    final last = _lastPointerDown;
    _lastPointerDown = now;
    if (last != null && now.difference(last) < _doubleTapWindow) {
      _lastPointerDown = null;
      widget.onDoubleTap?.call(widget.elementId);
    }
  }

  Future<void> _showContextMenu(Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final local = overlay.globalToLocal(globalPosition);
    final position = RelativeRect.fromLTRB(
      local.dx,
      local.dy,
      overlay.size.width - local.dx,
      overlay.size.height - local.dy,
    );
    final bool isHeadline = widget.elementId == 'title' || widget.elementId == 'subtitle';

    final action = await showMenu<String>(
      context: context,
      position: position,
      items: [
        if (widget.onDuplicate != null)
          const PopupMenuItem(value: 'duplicate', height: 36, child: _MenuRow(Icons.content_copy_rounded, 'Duplicate')),
        const PopupMenuItem(
          value: 'reset',
          height: 36,
          child: _MenuRow(Icons.center_focus_weak_rounded, 'Reset position'),
        ),
        if (widget.onRotated != null && widget.rotation != 0)
          const PopupMenuItem(
            value: 'straighten',
            height: 36,
            child: _MenuRow(Icons.straighten_rounded, 'Straighten (0°)'),
          ),
        if (widget.onDelete != null)
          PopupMenuItem(
            value: 'delete',
            height: 36,
            child: _MenuRow(Icons.delete_outline_rounded, isHeadline ? 'Clear text' : 'Delete', danger: true),
          ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'duplicate':
        widget.onDuplicate?.call(widget.elementId);
      case 'reset':
        widget.onMoved?.call(widget.elementId, Offset.zero);
      case 'straighten':
        widget.onRotated?.call(widget.elementId, 0);
      case 'delete':
        widget.onDelete?.call(widget.elementId);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final center = _center;
    final double effectiveScale = widget.scale * _resizeFactor;
    final double rotationDeg = _dragRotation ?? widget.rotation;

    Widget child = widget.child;

    if (widget.interactive) {
      final bool highlighted = widget.isSelected || _hovering || _busy;
      final bool showHandles = widget.isSelected && !_dragging;
      // Handles and borders are drawn inside the element's scale transform and
      // the workspace zoom, so they are counter-scaled to keep a constant
      // on-screen size. Only selected elements subscribe to zoom changes.
      final double zoom = widget.isSelected ? CanvasViewportZoom.of(context) : 1.0;
      final double u = 1 / math.max(effectiveScale * zoom, 0.01);

      // The handles live inside this margin, so they stay inside the element's
      // hit-test bounds and never fall through to the pan/zoom viewer.
      final double pad = (_rotateHandleGap + _handleSize * 2.2) * u;

      child = MouseRegion(
        cursor: SystemMouseCursors.move,
        opaque: false,
        hitTestBehavior: HitTestBehavior.deferToChild,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: Listener(
          onPointerDown: _onPointerDown,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.all(pad),
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
                      () => _EagerPanGestureRecognizer(),
                      (instance) {
                        instance.onStart = _startMove;
                        instance.onUpdate = _updateMove;
                        instance.onEnd = (_) => _endMove();
                        instance.onCancel = _cancelMove;
                      },
                    ),
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: highlighted ? AppColors.primary : Colors.transparent,
                        width: highlighted ? (widget.borderWidth * u).clamp(0.5, 40.0) : 0.0,
                      ),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      color: highlighted ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                    ),
                    child: child,
                  ),
                ),
              ),
              if (showHandles && widget.onResized != null) ...[
                for (final corner in _Corner.values)
                  _ResizeHandle(
                    corner: corner,
                    inset: pad,
                    size: _handleSize * u,
                    onStart: _startResize,
                    onUpdate: _updateResize,
                    onEnd: _endResize,
                    onCancel: _cancelResize,
                  ),
              ],
              if (showHandles && widget.onRotated != null)
                _RotateHandle(
                  inset: pad,
                  size: _handleSize * u,
                  gap: _rotateHandleGap * u,
                  onStart: _startRotate,
                  onUpdate: _updateRotate,
                  onEnd: _endRotate,
                  onCancel: _cancelRotate,
                ),
              // Appended last so showing it never re-parents the handles above.
              if (_dragRotation != null)
                Positioned(
                  top: pad - _rotateHandleGap * u - _handleSize * 1.2 * u - 22 * u,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Transform.scale(
                        scale: u,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            '${rotationDeg.round()}°',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
          angle: rotationDeg * (math.pi / 180),
          child: Transform.scale(scale: effectiveScale, child: child),
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;
  const _MenuRow(this.icon, this.label, {this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

/// Square corner handle; dragging it scales the element about its centre.
class _ResizeHandle extends StatelessWidget {
  final _Corner corner;

  /// Distance from the stack edge to the element box the handle sits on.
  final double inset;
  final double size;
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  const _ResizeHandle({
    required this.corner,
    required this.inset,
    required this.size,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final double edge = inset - size / 2;
    final bool top = corner == _Corner.topLeft || corner == _Corner.topRight;
    final bool left = corner == _Corner.topLeft || corner == _Corner.bottomLeft;
    final cursor = (corner == _Corner.topLeft || corner == _Corner.bottomRight)
        ? SystemMouseCursors.resizeUpLeftDownRight
        : SystemMouseCursors.resizeUpRightDownLeft;

    return Positioned(
      top: top ? edge : null,
      bottom: top ? null : edge,
      left: left ? edge : null,
      right: left ? null : edge,
      child: MouseRegion(
        cursor: cursor,
        child: RawGestureDetector(
          behavior: HitTestBehavior.opaque,
          gestures: {
            _EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
              () => _EagerPanGestureRecognizer(),
              (instance) {
                instance.onStart = onStart;
                instance.onUpdate = onUpdate;
                instance.onEnd = (_) => onEnd();
                instance.onCancel = onCancel;
              },
            ),
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(size * 0.25),
              border: Border.all(color: AppColors.primary, width: size * 0.16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: size * 0.4)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round handle above the element; dragging it rotates the element about
/// its centre. Shows the live angle while dragging.
class _RotateHandle extends StatelessWidget {
  final double inset;
  final double size;
  final double gap;
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  const _RotateHandle({
    required this.inset,
    required this.size,
    required this.gap,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final double knob = size * 1.2;
    return Positioned(
      top: inset - gap - knob,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: {
                _EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
                  () => _EagerPanGestureRecognizer(),
                  (instance) {
                    instance.onStart = onStart;
                    instance.onUpdate = onUpdate;
                    instance.onEnd = (_) => onEnd();
                    instance.onCancel = onCancel;
                  },
                ),
              },
              child: Container(
                width: knob,
                height: knob,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: size * 0.16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: size * 0.4)],
                ),
                child: Icon(Icons.rotate_right_rounded, size: size * 0.75, color: AppColors.primary),
              ),
            ),
          ),
          // Stem connecting the handle to the element.
          Container(width: math.max(1.0, size * 0.12), height: gap, color: AppColors.primary),
        ],
      ),
    );
  }
}
