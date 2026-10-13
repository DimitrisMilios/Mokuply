import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/layout/element_drag_math.dart';

/// Draws the live snap guides of a drag over the whole canvas.
class SnapGuideOverlay extends StatelessWidget {
  final ValueListenable<SnapGuides> guides;

  const SnapGuideOverlay({super.key, required this.guides});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<SnapGuides>(
        valueListenable: guides,
        builder: (context, g, _) => g.isEmpty ? const SizedBox.shrink() : CustomPaint(painter: _SnapGuidePainter(g)),
      ),
    );
  }
}

class _SnapGuidePainter extends CustomPainter {
  final SnapGuides guides;
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
  bool shouldRepaint(covariant _SnapGuidePainter old) => old.guides != guides;
}
