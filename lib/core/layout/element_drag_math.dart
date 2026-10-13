import 'dart:math' as math;
import 'dart:ui';

import 'canvas_geometry.dart';

/// Vertical and horizontal snap guides shown while an element is dragged, in
/// canvas pixels. Either may be null.
class SnapGuides {
  final double? x;
  final double? y;

  const SnapGuides({this.x, this.y});

  static const none = SnapGuides();

  bool get isEmpty => x == null && y == null;

  @override
  bool operator ==(Object other) => other is SnapGuides && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Pure maths behind dragging, resizing and rotating a canvas element.
class ElementDragMath {
  ElementDragMath._();

  /// How close (canvas pixels) a drag must come to a guide to snap to it.
  static const double snapPixels = 6.0;

  /// Rotation snaps to multiples of this many degrees…
  static const double rotationStep = 15.0;

  /// …when within this many degrees of one.
  static const double rotationSnap = 3.0;

  /// Offset (in stored units) for a move drag, snapped to the horizontal
  /// centre and to the element's own anchor line, plus the guides to draw.
  static (Offset, SnapGuides) snapMove({
    required CanvasGeometry geometry,
    required double anchorFraction,
    required Offset startOffset,
    required Offset canvasDelta,
  }) {
    var next = startOffset + geometry.deltaToOffsetUnits(canvasDelta);
    final threshold = geometry.deltaToOffsetUnits(const Offset(snapPixels, snapPixels));
    double? guideX;
    double? guideY;
    if (next.dx.abs() < threshold.dx) {
      next = Offset(0, next.dy);
      guideX = geometry.canvasCenter.dx;
    }
    if (next.dy.abs() < threshold.dy) {
      next = Offset(next.dx, 0);
      guideY = geometry.anchorY(anchorFraction);
    }
    return (next, SnapGuides(x: guideX, y: guideY));
  }

  /// Scale factor for a corner-handle drag: pointer distance from the centre
  /// relative to where the drag started, kept so `value * factor` stays in
  /// [min]..[max].
  static double resizeFactor({
    required double startDistance,
    required double distance,
    required double value,
    required double min,
    required double max,
  }) {
    final raw = distance / math.max(1.0, startDistance);
    return raw.clamp(min / value, max / value);
  }

  /// Rotation in degrees for a rotate-handle drag, snapped to 15° steps when close.
  static double rotation({
    required double startDegrees,
    required double startAngle,
    required Offset pointerFromCenter,
  }) {
    final angle = math.atan2(pointerFromCenter.dy, pointerFromCenter.dx);
    var deg = startDegrees + (angle - startAngle) * 180 / math.pi;
    final nearest = (deg / rotationStep).round() * rotationStep;
    if ((deg - nearest).abs() < rotationSnap) deg = nearest;
    return deg;
  }

  /// Angle (radians) of a pointer relative to the element centre.
  static double angleOf(Offset pointerFromCenter) => math.atan2(pointerFromCenter.dy, pointerFromCenter.dx);
}
