import 'package:flutter/widgets.dart';

/// Publishes the workspace zoom to the canvas, so selection chrome (handles,
/// borders) can keep a constant on-screen size whatever the zoom level.
class CanvasViewportZoom extends InheritedNotifier<TransformationController> {
  const CanvasViewportZoom({super.key, required TransformationController controller, required super.child})
    : super(notifier: controller);

  /// Current zoom factor, or 1.0 outside a zoomable workspace. Registers a
  /// dependency, so call it only from widgets that need the live zoom.
  static double of(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<CanvasViewportZoom>();
    return w?.notifier?.value.getMaxScaleOnAxis() ?? 1.0;
  }
}
