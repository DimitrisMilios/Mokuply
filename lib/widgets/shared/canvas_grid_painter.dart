import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Soft dot grid for the canvas viewport: 2 px dots at [AppColors.clayShade]
/// with 0.08 alpha, every 40 px, on the `sandDeep` viewport.
class CanvasGridPainter extends CustomPainter {
  static const double step = 40.0;
  static const double dotSize = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paint = Paint()
      ..color = AppColors.clayShade.withValues(alpha: 0.08)
      ..strokeWidth = dotSize
      ..strokeCap = StrokeCap.round;

    final cols = (size.width / step).ceil() + 1;
    final rows = (size.height / step).ceil() + 1;
    final points = Float32List(cols * rows * 2);
    var i = 0;
    for (var r = 0; r < rows; r++) {
      final y = r * step;
      for (var c = 0; c < cols; c++) {
        points[i++] = c * step;
        points[i++] = y;
      }
    }
    canvas.drawRawPoints(ui.PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
