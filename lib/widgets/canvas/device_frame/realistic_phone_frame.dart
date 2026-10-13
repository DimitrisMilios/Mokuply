import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'device_frame_widget.dart';
import 'phone_skin.dart';

/// One chassis implementation for both realistic phones. The rim, bezel and
/// button gutters are identical so the screenshot area matches exactly.
class RealisticPhoneFrame extends StatelessWidget {
  final PhoneSkin skin;
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const RealisticPhoneFrame({
    super.key,
    required this.skin,
    required this.deviceWidth,
    required this.deviceHeight,
    required this.scale,
    required this.hasShadow,
    required this.screenshotWidget,
  });

  static const double rimDesign = 12.0;
  static const double bezelDesign = 14.0;

  @override
  Widget build(BuildContext context) {
    final double outerCornerRadius = skin.outerCornerRadius * scale;
    final double rim = rimDesign * scale;
    final double bezel = bezelDesign * scale;
    final double inset = rim + bezel;
    final double innerCornerRadius = math.max(outerCornerRadius - inset * 0.7, 6 * scale);
    final double buttonWidth = DeviceFrameWidget.buttonGutterDesign * scale;

    final List<BoxShadow> shadows = hasShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 40 * scale,
              spreadRadius: 4 * scale,
              offset: Offset(0, 24 * scale),
            ),
            BoxShadow(
              color: skin.glowColor.withValues(alpha: 0.22),
              blurRadius: 80 * scale,
              spreadRadius: 12 * scale,
              offset: Offset(0, 34 * scale),
            ),
          ]
        : const [];

    return SizedBox(
      width: deviceWidth + (buttonWidth * 2),
      height: deviceHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Hardware keys protruding into the gutters
          for (final button in skin.buttons)
            Positioned(
              left: button.isLeft ? 0 : null,
              right: button.isLeft ? null : 0,
              top: button.top * scale,
              child: SideButton(
                width: buttonWidth,
                height: button.height * scale,
                isLeft: button.isLeft,
                colors: skin.buttonColors,
                scale: scale,
              ),
            ),

          // Phone body
          Positioned(
            left: buttonWidth,
            child: Container(
              width: deviceWidth,
              height: deviceHeight,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(outerCornerRadius), boxShadow: shadows),
              child: Stack(
                children: [
                  // Outer chassis rim
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(outerCornerRadius),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: skin.chassisColors,
                        stops: skin.chassisStops,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(rim),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(math.max(outerCornerRadius - rim, 4 * scale)),
                          color: const Color(0xFF000000),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(bezel),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(innerCornerRadius),
                            child: Stack(
                              children: [
                                Positioned.fill(child: screenshotWidget),
                                // Subtle inner display edge
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(innerCornerRadius),
                                        border: Border.all(
                                          color: Colors.black.withValues(alpha: 0.22),
                                          width: 2.5 * scale,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                skin.buildCameraCutout(scale),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Earpiece speaker slit
                  Positioned(
                    top: skin.speakerTop * scale,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: skin.speakerWidth * scale,
                        height: skin.speakerHeight * scale,
                        decoration: BoxDecoration(
                          color: skin.speakerColor,
                          borderRadius: BorderRadius.circular(2 * scale),
                          border: skin.speakerBorderColor != null
                              ? Border.all(color: skin.speakerBorderColor!, width: 0.8 * scale)
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Antenna break lines on the rim
                  for (final alignment in const [
                    Alignment.topLeft,
                    Alignment.topRight,
                    Alignment.bottomLeft,
                    Alignment.bottomRight,
                  ])
                    Positioned(
                      left: alignment.x < 0 ? 0 : null,
                      right: alignment.x > 0 ? 0 : null,
                      top: alignment.y < 0 ? 80 * scale : null,
                      bottom: alignment.y > 0 ? 80 * scale : null,
                      child: Container(width: 4 * scale, height: 3.5 * scale, color: skin.antennaColor),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SideButton extends StatelessWidget {
  final double width;
  final double height;
  final bool isLeft;
  final List<Color> colors;
  final double scale;

  const SideButton({
    super.key,
    required this.width,
    required this.height,
    required this.isLeft,
    required this.colors,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? Radius.circular(4 * scale) : Radius.zero,
          right: !isLeft ? Radius.circular(4 * scale) : Radius.zero,
        ),
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4 * scale,
            offset: Offset((isLeft ? -2 : 2) * scale, 2 * scale),
          ),
        ],
      ),
    );
  }
}
