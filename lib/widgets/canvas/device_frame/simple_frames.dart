import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Universal minimal dark frame.
class MinimalDarkFrame extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const MinimalDarkFrame({
    super.key,
    required this.deviceWidth,
    required this.deviceHeight,
    required this.scale,
    required this.hasShadow,
    required this.screenshotWidget,
  });

  @override
  Widget build(BuildContext context) {
    final double cornerRadius = 38 * scale;
    final List<BoxShadow> shadows = hasShadow
        ? [
            BoxShadow(
              color: AppColors.exportGlow.withValues(alpha: 0.25),
              blurRadius: 36 * scale,
              spreadRadius: 4 * scale,
              offset: Offset(0, 18 * scale),
            ),
          ]
        : const [];

    return Container(
      width: deviceWidth,
      height: deviceHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: shadows,
        border: Border.all(color: const Color(0xFF2D303E), width: 5 * scale),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(cornerRadius - (4 * scale)), child: screenshotWidget),
    );
  }
}

/// Raw screenshot without a frame (shadow only).
class RawScreenshotFrame extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const RawScreenshotFrame({
    super.key,
    required this.deviceWidth,
    required this.deviceHeight,
    required this.scale,
    required this.hasShadow,
    required this.screenshotWidget,
  });

  @override
  Widget build(BuildContext context) {
    final List<BoxShadow> shadows = hasShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 28 * scale,
              spreadRadius: 2 * scale,
              offset: Offset(0, 14 * scale),
            ),
          ]
        : const [];

    return Container(
      width: deviceWidth,
      height: deviceHeight,
      decoration: BoxDecoration(boxShadow: shadows),
      child: ClipRRect(borderRadius: BorderRadius.circular(18 * scale), child: screenshotWidget),
    );
  }
}
