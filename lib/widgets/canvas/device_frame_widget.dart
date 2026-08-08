import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/store_specs.dart';

class DeviceFrameWidget extends StatelessWidget {
  final DeviceFrameStyle frameStyle;
  final Uint8List? screenshotBytes;
  final bool hasShadow;
  final TargetPlatformType platform;
  final double scale;

  const DeviceFrameWidget({
    super.key,
    required this.frameStyle,
    this.screenshotBytes,
    required this.hasShadow,
    required this.platform,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    // Frame base width & height according to platform ratio
    final double deviceWidth = (platform.targetWidth * 0.72) * scale;
    final double deviceHeight = deviceWidth / (9 / 19.5); // phone screen aspect ratio

    Widget screenshotWidget;
    if (screenshotBytes != null) {
      screenshotWidget = Image.memory(
        screenshotBytes!,
        fit: BoxFit.cover,
        width: deviceWidth,
        height: deviceHeight,
      );
    } else {
      // Placeholder preview image when no file uploaded yet (light glass aesthetic)
      screenshotWidget = Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.9),
              const Color(0xFFF7F2E2).withValues(alpha: 0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16 * scale),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1.5 * scale),
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 54 * scale,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 16 * scale),
            Text(
              "Upload App Screenshot",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              "Click upload in left sidebar",
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // Shadow decoration
    final List<BoxShadow> shadows = hasShadow
        ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 36 * scale,
              spreadRadius: 6 * scale,
              offset: Offset(0, 18 * scale),
            ),
          ]
        : [];

    switch (frameStyle) {
      case DeviceFrameStyle.iphone16ProMax:
        final double cornerRadius = 46 * scale;
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: shadows,
            border: Border.all(
              color: AppColors.frameIphone,
              width: 8 * scale,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - (6 * scale)),
            child: Stack(
              children: [
                Positioned.fill(child: screenshotWidget),
                // Dynamic Island notch
                Positioned(
                  top: 14 * scale,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 110 * scale,
                      height: 30 * scale,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case DeviceFrameStyle.samsungS26Ultra:
        final double cornerRadius = 24 * scale;
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: shadows,
            border: Border.all(
              color: AppColors.frameSamsung,
              width: 7 * scale,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - (5 * scale)),
            child: Stack(
              children: [
                Positioned.fill(child: screenshotWidget),
                // Hole punch camera notch
                Positioned(
                  top: 12 * scale,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 16 * scale,
                      height: 16 * scale,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case DeviceFrameStyle.minimalOutline:
        final double cornerRadius = 32 * scale;
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: shadows,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              width: 4 * scale,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - (3 * scale)),
            child: screenshotWidget,
          ),
        );

      case DeviceFrameStyle.none:
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16 * scale),
            child: screenshotWidget,
          ),
        );
    }
  }
}
