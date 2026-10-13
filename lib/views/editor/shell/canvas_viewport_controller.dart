import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import '../../../widgets/clay/clay.dart';
import '../workspace/workspace_layout.dart';

/// Pan / zoom state of the workspace strip: zoom steps about the centre of
/// the visible region and a spring-animated "fit everything".
class CanvasViewportController {
  static const double minZoom = 0.15;
  static const double maxZoom = 4.0;

  CanvasViewportController({required TickerProvider vsync})
    : _fitAnim = AnimationController.unbounded(vsync: vsync, value: 0) {
    transformation.addListener(_onTransformChanged);
    _fitAnim.addListener(_onFitTick);
  }

  final TransformationController transformation = TransformationController();
  final AnimationController _fitAnim;
  Matrix4? _fitFrom;
  Matrix4? _fitTo;
  Matrix4? _lastFitValue;

  double get zoom => transformation.value.getMaxScaleOnAxis();

  void dispose() {
    _fitAnim
      ..removeListener(_onFitTick)
      ..dispose();
    transformation
      ..removeListener(_onTransformChanged)
      ..dispose();
  }

  /// The matrix that fits [content] (strip size including padding) into
  /// [region] of the viewport, centred.
  static Matrix4 fitMatrix(Size content, Rect region) {
    const pad = WorkspaceLayout.contentPadding;
    final inner = Size(content.width - pad.horizontal, content.height - pad.vertical);
    final double scale = math.min(region.width / inner.width, region.height / inner.height).clamp(minZoom, maxZoom);
    final innerCenter = Offset(pad.left + inner.width / 2, pad.top + inner.height / 2);
    return Matrix4.identity()
      ..translateByDouble(region.center.dx - scale * innerCenter.dx, region.center.dy - scale * innerCenter.dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
  }

  /// Fits [content] into [region]: with the gentle spring of [motion], or
  /// instantly when [motion] is null (the very first fit).
  void fit(Size content, Rect region, {ClayMotion? motion}) {
    final target = fitMatrix(content, region);
    if (motion == null) {
      _fitAnim.stop();
      transformation.value = target;
      return;
    }
    _fitFrom = transformation.value.clone();
    _fitTo = target;
    _fitAnim.value = 0;
    _fitAnim.springTo(1, spring: motion.gentle, velocity: 0).then((_) {
      if (_fitTo != target) return;
      // Land exactly on the target; the spring stops within its tolerance.
      _lastFitValue = target;
      transformation.value = target;
      _fitFrom = null;
      _fitTo = null;
    });
  }

  void _onFitTick() {
    final from = _fitFrom;
    final to = _fitTo;
    if (from == null || to == null) return;
    final m = _lerpTransform(from, to, _fitAnim.value);
    _lastFitValue = m;
    transformation.value = m;
  }

  /// A pan or zoom from anywhere else interrupts the fit animation.
  void _onTransformChanged() {
    if (!_fitAnim.isAnimating) return;
    final last = _lastFitValue;
    if (last != null && transformation.value != last) {
      _fitAnim.stop();
      _fitFrom = null;
      _fitTo = null;
    }
  }

  /// The strip matrix is translation × uniform scale, so lerping the two
  /// parts directly is exact and cheaper than a full decomposition.
  static Matrix4 _lerpTransform(Matrix4 a, Matrix4 b, double t) {
    final ta = a.getTranslation();
    final tb = b.getTranslation();
    final s = ui.lerpDouble(a.getMaxScaleOnAxis(), b.getMaxScaleOnAxis(), t)!;
    return Matrix4.identity()
      ..translateByDouble(ui.lerpDouble(ta.x, tb.x, t)!, ui.lerpDouble(ta.y, tb.y, t)!, 0, 1)
      ..scaleByDouble(s, s, s, 1);
  }

  /// Zooms by [factor] keeping [focal] (viewport coordinates) fixed.
  void zoomBy(double factor, Offset focal) {
    final current = zoom;
    final ratio = (current * factor).clamp(minZoom, maxZoom) / current;
    if ((ratio - 1).abs() < 1e-6) return;
    final before = Matrix4.identity()..translateByDouble(focal.dx, focal.dy, 0, 1);
    final scale = Matrix4.identity()..scaleByDouble(ratio, ratio, ratio, 1);
    final after = Matrix4.identity()..translateByDouble(-focal.dx, -focal.dy, 0, 1);
    transformation.value = before * scale * after * transformation.value;
  }

  void zoomTo(double target, Offset focal) => zoomBy(target / zoom, focal);
}
