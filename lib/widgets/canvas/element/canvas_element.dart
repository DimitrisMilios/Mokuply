import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/layout/canvas_geometry.dart';
import '../../../core/layout/element_drag_math.dart';
import '../../../models/element_kind.dart';
import '../../clay/clay.dart';
import '../canvas_actions.dart';
import '../canvas_viewport_zoom.dart';
import 'element_chrome.dart';
import 'element_handles.dart';
import 'selection_chrome.dart';

part 'canvas_element_drags.dart';

/// What the corner handles edit: a scale factor for phone frames and images,
/// a font size for text, with its limits.
class ResizeSpec {
  final double value;
  final double min;
  final double max;
  const ResizeSpec(this.value, this.min, this.max);
}

/// Positions a child at a design-space location. With [actions] it is also
/// hoverable, selectable, draggable, resizable (corners) and rotatable (top
/// handle). Drag state stays local so the canvas stays smooth; the final
/// value is committed once on release.
class CanvasElement extends StatefulWidget {
  final String elementId;
  final CanvasGeometry geometry;
  final double anchorFraction;
  final Offset offset;
  final double rotation;
  final double scale;
  final ResizeSpec resize;

  /// Null on exports and in preview mode: nothing reacts, no chrome is built.
  final CanvasActions? actions;
  final bool isSelected;
  final bool canRotate;
  final bool canDuplicate;
  final bool canDelete;
  final bool isText;
  final double borderRadius;
  final double borderWidth;
  final ValueChanged<SnapGuides>? onSnap;
  final Widget child;

  const CanvasElement({
    super.key,
    required this.elementId,
    required this.geometry,
    required this.anchorFraction,
    required this.offset,
    this.rotation = 0.0,
    this.scale = 1.0,
    required this.resize,
    required this.actions,
    required this.isSelected,
    this.canRotate = false,
    this.canDuplicate = false,
    this.canDelete = true,
    this.isText = false,
    required this.borderRadius,
    required this.borderWidth,
    this.onSnap,
    required this.child,
  });

  @override
  State<CanvasElement> createState() => _CanvasElementState();
}

class _CanvasElementState extends State<CanvasElement> with SingleTickerProviderStateMixin, _ElementDrags {
  static const Duration _doubleTapWindow = Duration(milliseconds: 320);

  /// How long deselected handles stay mounted while they scale out.
  static const Duration _handleExit = Duration(milliseconds: 100);

  bool _hovering = false;
  bool _handlesMounted = false;
  Timer? _handleHideTimer;
  DateTime? _lastPointerDown;

  // Preview-only chrome motion; never touches the exported child.
  @override
  final JellyController _jelly = JellyController();
  AnimationController? _liftController;
  @override
  AnimationController get _lift => _liftController ??= AnimationController.unbounded(vsync: this, value: 0);

  bool get _showHandles => widget.isSelected && !_dragging;

  @override
  void initState() {
    super.initState();
    _syncHandles();
  }

  @override
  void didUpdateWidget(CanvasElement oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncHandles();
  }

  @override
  void dispose() {
    _handleHideTimer?.cancel();
    _liftController?.dispose();
    super.dispose();
  }

  /// Handles stay mounted for a moment after they hide so they can scale out.
  @override
  void _syncHandles() {
    if (_showHandles) {
      _handleHideTimer?.cancel();
      _handleHideTimer = null;
      _handlesMounted = true;
    } else if (_handlesMounted && _handleHideTimer == null) {
      _handleHideTimer = Timer(_handleExit, () {
        if (!mounted) return;
        setState(() {
          _handlesMounted = false;
          _handleHideTimer = null;
        });
      });
    }
  }

  // --- Double-click and right-click ---

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons & kSecondaryButton != 0) {
      _select();
      _showContextMenu(event.position);
      return;
    }
    // Own double-click timing: browser harnesses and fast mice click with
    // ~0 ms gaps, which the framework's double-tap recognizer rejects.
    final now = DateTime.now();
    final last = _lastPointerDown;
    _lastPointerDown = now;
    if (widget.isText && last != null && now.difference(last) < _doubleTapWindow) {
      _lastPointerDown = null;
      _actions?.onEditText(widget.elementId);
    }
  }

  Future<void> _showContextMenu(Offset position) async {
    final actions = _actions;
    if (actions == null) return;
    final action = await showElementMenu(
      context: context,
      position: position,
      canDuplicate: widget.canDuplicate,
      canStraighten: widget.canRotate && widget.rotation != 0,
      canDelete: widget.canDelete,
      isHeadline: ElementKind.of(widget.elementId)?.isHeadline ?? false,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case ElementMenuAction.duplicate:
        actions.onDuplicate(widget.elementId);
      case ElementMenuAction.reset:
        actions.onMove(widget.elementId, Offset.zero);
      case ElementMenuAction.straighten:
        actions.onRotate(widget.elementId, 0);
      case ElementMenuAction.delete:
        actions.onDelete(widget.elementId);
    }
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    final center = _center;
    final double effectiveScale = widget.scale * _resizeFactor;
    final double rotationDeg = _dragRotation ?? widget.rotation;
    final Widget content = _actions == null ? widget.child : _interactive(effectiveScale, rotationDeg);

    return Positioned(
      left: center.dx,
      top: center.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(
          angle: rotationDeg * (math.pi / 180),
          child: Transform.scale(scale: effectiveScale, child: content),
        ),
      ),
    );
  }

  Widget _interactive(double effectiveScale, double rotationDeg) {
    // Chrome is drawn inside the element's scale and the workspace zoom, so
    // it is counter-scaled to a constant on-screen size. Only selected
    // elements subscribe to zoom changes.
    final double zoom = (widget.isSelected || _handlesMounted) ? CanvasViewportZoom.of(context) : 1.0;

    return ElementChrome(
      unit: 1 / math.max(effectiveScale * zoom, 0.01),
      highlighted: widget.isSelected || _hovering || _busy,
      borderWidth: widget.borderWidth,
      borderRadius: widget.borderRadius,
      jelly: _jelly,
      lift: _lift,
      handlesMounted: _handlesMounted,
      handlesVisible: _showHandles,
      canRotate: widget.canRotate,
      move: HandleDrag(
        onStart: _startMove,
        onUpdate: _updateMove,
        onEnd: _endMove,
        onCancel: () => _endMove(commit: false),
      ),
      resize: HandleDrag(
        onStart: _startResize,
        onUpdate: _updateResize,
        onEnd: _endResize,
        onCancel: () => _endResize(commit: false),
      ),
      rotate: HandleDrag(
        onStart: _startRotate,
        onUpdate: _updateRotate,
        onEnd: _endRotate,
        onCancel: () => _endRotate(commit: false),
      ),
      rotatingDegrees: _dragRotation == null ? null : rotationDeg,
      onHover: (hovering) => setState(() => _hovering = hovering),
      onPointerDown: _onPointerDown,
      child: widget.child,
    );
  }
}
