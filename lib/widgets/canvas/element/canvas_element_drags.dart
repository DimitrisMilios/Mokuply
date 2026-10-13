part of 'canvas_element.dart';

/// Move, resize and rotate drags of a canvas element. Drag values stay
/// local, so the canvas stays smooth; the result is committed once on release.
mixin _ElementDrags on State<CanvasElement> {
  JellyController get _jelly;
  AnimationController get _lift;
  void _syncHandles();

  CanvasActions? get _actions => widget.actions;

  DateTime? _lastDragTime;
  Offset _velocity = Offset.zero;
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

  bool get _dragging => _dragOffset != null;
  bool get _busy => _dragging || _resizing || _dragRotation != null;

  Offset get _currentOffset => _dragOffset ?? widget.offset;

  /// Canvas-pixel centre of the element as currently displayed.
  Offset get _center => widget.geometry.elementCenter(
    anchorFraction: widget.anchorFraction,
    offsetX: _currentOffset.dx,
    offsetY: _currentOffset.dy,
  );

  /// Global pointer → canvas pixels. Using the canvas box (not the element's
  /// rotated, scaled box) keeps drags right at any tilt, size or zoom.
  Offset _toCanvas(Offset global) {
    final box = context.findAncestorRenderObjectOfType<RenderStack>();
    return box == null ? global : box.globalToLocal(global);
  }

  void _select() => _actions?.onSelect(widget.elementId);

  // --- Move ---

  void _startMove(DragStartDetails d) {
    _select();
    _dragStartPointer = _toCanvas(d.globalPosition);
    _dragStartOffset = widget.offset;
    _lastDragTime = DateTime.now();
    _velocity = Offset.zero;
    // The selection box lifts (its shadow spreads) while the element is held.
    _lift.springTo(1, spring: ClayMotion.of(context).snappy);
    setState(() => _dragOffset = _dragStartOffset);
    _syncHandles();
  }

  void _updateMove(DragUpdateDetails d) {
    _feedVelocity(d.delta);
    final (next, guides) = ElementDragMath.snapMove(
      geometry: widget.geometry,
      anchorFraction: widget.anchorFraction,
      startOffset: _dragStartOffset,
      canvasDelta: _toCanvas(d.globalPosition) - _dragStartPointer,
    );
    widget.onSnap?.call(guides);
    setState(() => _dragOffset = next);
  }

  void _endMove({bool commit = true}) {
    final result = _dragOffset;
    widget.onSnap?.call(SnapGuides.none);
    _jelly.settle();
    _lift.springTo(0, spring: ClayMotion.of(context).bouncy);
    setState(() => _dragOffset = null);
    _syncHandles();
    if (commit && result != null) _actions?.onMove(widget.elementId, result);
  }

  /// Feeds a smoothed pointer velocity to the jelly, at half amplitude so the
  /// content under the chrome stays readable.
  void _feedVelocity(Offset delta) {
    final now = DateTime.now();
    final last = _lastDragTime;
    _lastDragTime = now;
    if (last == null) return;
    final double dt = now.difference(last).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return;
    _velocity = _velocity * 0.6 + (delta / dt) * 0.4;
    _jelly.velocity(_velocity.dx * 0.5, velocityY: _velocity.dy * 0.5);
  }

  // --- Resize (corner handles) ---

  void _startResize(DragStartDetails d) {
    _select();
    _resizeStartDistance = (_toCanvas(d.globalPosition) - _center).distance;
    setState(() {
      _resizing = true;
      _resizeFactor = 1.0;
    });
  }

  void _updateResize(DragUpdateDetails d) {
    final r = widget.resize;
    setState(() {
      _resizeFactor = ElementDragMath.resizeFactor(
        startDistance: _resizeStartDistance,
        distance: (_toCanvas(d.globalPosition) - _center).distance,
        value: r.value,
        min: r.min,
        max: r.max,
      );
    });
  }

  void _endResize({bool commit = true}) {
    final factor = _resizeFactor;
    setState(() {
      _resizing = false;
      _resizeFactor = 1.0;
    });
    if (commit && (factor - 1.0).abs() > 0.001) _actions?.onResize(widget.elementId, widget.resize.value * factor);
  }

  // --- Rotate (top handle) ---

  void _startRotate(DragStartDetails d) {
    _select();
    _rotateStartAngle = ElementDragMath.angleOf(_toCanvas(d.globalPosition) - _center);
    _rotateStartDegrees = widget.rotation;
    setState(() => _dragRotation = widget.rotation);
  }

  void _updateRotate(DragUpdateDetails d) {
    final deg = ElementDragMath.rotation(
      startDegrees: _rotateStartDegrees,
      startAngle: _rotateStartAngle,
      pointerFromCenter: _toCanvas(d.globalPosition) - _center,
    );
    setState(() => _dragRotation = deg);
  }

  void _endRotate({bool commit = true}) {
    final result = _dragRotation;
    setState(() => _dragRotation = null);
    if (commit && result != null) _actions?.onRotate(widget.elementId, result);
  }
}
