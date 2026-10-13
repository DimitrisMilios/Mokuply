import 'package:flutter/material.dart';
import '../../clay/clay.dart';
import 'eager_pan_detector.dart';
import 'element_handles.dart';
import 'selection_chrome.dart';

/// The editor-only wrapper around a canvas element: move cursor, drag area,
/// selection outline under the content, corner and rotate handles and the
/// live angle badge. Purely presentational; the element state drives it.
class ElementChrome extends StatelessWidget {
  static const double handleSize = 10.0;
  static const double rotateHandleGap = 26.0;

  /// Corner handles pop in this far apart; the rotate handle comes last.
  static const Duration handleStagger = Duration(milliseconds: 20);

  final Widget child;

  /// Counter-scale so chrome keeps a constant on-screen size.
  final double unit;
  final bool highlighted;
  final double borderWidth;
  final double borderRadius;
  final JellyController jelly;
  final Animation<double> lift;
  final bool handlesMounted;
  final bool handlesVisible;
  final bool canRotate;
  final HandleDrag move;
  final HandleDrag resize;
  final HandleDrag rotate;

  /// The angle shown above the element while rotating, else null.
  final double? rotatingDegrees;
  final ValueChanged<bool> onHover;
  final PointerDownEventListener onPointerDown;

  const ElementChrome({
    super.key,
    required this.child,
    required this.unit,
    required this.highlighted,
    required this.borderWidth,
    required this.borderRadius,
    required this.jelly,
    required this.lift,
    required this.handlesMounted,
    required this.handlesVisible,
    required this.canRotate,
    required this.move,
    required this.resize,
    required this.rotate,
    required this.rotatingDegrees,
    required this.onHover,
    required this.onPointerDown,
  });

  /// Margin around the content that holds the handles, so they stay inside
  /// the element's hit-test bounds and never fall through to the viewer.
  double get padding => (rotateHandleGap + handleSize * 2.2) * unit;

  @override
  Widget build(BuildContext context) {
    final double pad = padding;
    final double size = handleSize * unit;
    final double? degrees = rotatingDegrees;

    return MouseRegion(
      cursor: SystemMouseCursors.move,
      opaque: false,
      hitTestBehavior: HitTestBehavior.deferToChild,
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: Listener(
        onPointerDown: onPointerDown,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.all(pad),
              child: EagerPanDetector(
                onStart: move.onStart,
                onUpdate: move.onUpdate,
                onEnd: move.onEnd,
                onCancel: move.onCancel,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: SelectionOutline(
                        jelly: jelly,
                        lift: lift,
                        highlighted: highlighted,
                        borderWidth: highlighted ? (borderWidth * unit).clamp(0.5, 40.0) : 0.0,
                        borderRadius: borderRadius,
                        unit: unit,
                      ),
                    ),
                    // Own layer: moving, scaling or tilting the element only
                    // re-composites it instead of repainting the phone frame.
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: RepaintBoundary(child: child),
                    ),
                  ],
                ),
              ),
            ),
            if (handlesMounted) ...[
              for (final (i, corner) in HandleCorner.values.indexed)
                ResizeHandle(
                  corner: corner,
                  inset: pad,
                  size: size,
                  visible: handlesVisible,
                  delay: handleStagger * i,
                  drag: resize,
                ),
              if (canRotate)
                RotateHandle(
                  inset: pad,
                  size: size,
                  gap: rotateHandleGap * unit,
                  visible: handlesVisible,
                  delay: handleStagger * HandleCorner.values.length,
                  drag: rotate,
                ),
            ],
            // Appended last so showing it never re-parents the handles above.
            if (degrees != null)
              Positioned(
                top: pad - rotateHandleGap * unit - size * 1.2 - 22 * unit,
                left: 0,
                right: 0,
                child: RotationBadge(degrees: degrees, unit: unit),
              ),
          ],
        ),
      ),
    );
  }
}
