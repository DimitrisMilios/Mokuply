import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/store_specs.dart';

/// Draws a phone frame around a screenshot.
///
/// All geometry is expressed in design pixels and multiplied by [scale]
/// (design → canvas). Every style, and both realistic chassis, share exactly
/// the same outer footprint and screen inset, so switching store or style never
/// moves or resizes the element on the canvas.
class DeviceFrameWidget extends StatelessWidget {
  final DeviceFrameStyle frameStyle;
  final Uint8List? screenshotBytes;
  final bool hasShadow;
  final TargetPlatformType platform;
  final double scale;

  /// Pixel width to decode the screenshot at. Previews pass a size close to
  /// what is drawn so large screenshots don't cost full-resolution memory;
  /// exports leave it null to decode at native resolution.
  final int? decodeWidth;

  const DeviceFrameWidget({
    super.key,
    required this.frameStyle,
    this.screenshotBytes,
    required this.hasShadow,
    required this.platform,
    required this.scale,
    this.decodeWidth,
  });

  /// Phone body width in design pixels (before [scale]).
  static const double bodyDesignWidth = DesignSpace.width * DesignSpace.deviceWidthFraction;

  /// Screen aspect ratio shared by both realistic chassis.
  static const double screenAspect = 9 / 19.5;

  /// Side-button gutter reserved on both sides so the body is always centred.
  static const double buttonGutterDesign = 10.0;

  static double bodyWidthFor(double scale) => bodyDesignWidth * scale;
  static double bodyHeightFor(double scale) => bodyWidthFor(scale) / screenAspect;
  static double outerWidthFor(double scale) => bodyWidthFor(scale) + (buttonGutterDesign * 2 * scale);

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = bodyWidthFor(scale);
    final double deviceHeight = bodyHeightFor(scale);

    final Widget screenshotWidget = screenshotBytes != null
        ? Image.memory(
            screenshotBytes!,
            fit: BoxFit.cover,
            width: deviceWidth,
            height: deviceHeight,
            cacheWidth: decodeWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          )
        : _ScreenshotPlaceholder(
            width: deviceWidth,
            height: deviceHeight,
            scale: scale,
            platform: platform,
          );

    final Widget body;
    switch (frameStyle) {
      case DeviceFrameStyle.realistic:
        body = _RealisticPhoneFrame(
          skin: platform == TargetPlatformType.appStore ? _PhoneSkin.iphone16ProMax : _PhoneSkin.galaxyS26Ultra,
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );
        break;
      case DeviceFrameStyle.minimalOutline:
        body = _MinimalDarkFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );
        break;
      case DeviceFrameStyle.none:
        body = _RawScreenshotFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );
        break;
    }

    // Identical outer box for every style: body centred inside the button gutters.
    return SizedBox(
      width: outerWidthFor(scale),
      height: deviceHeight,
      child: Center(child: body),
    );
  }
}

/// Placeholder shown inside a frame until a screenshot is uploaded.
class _ScreenshotPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double scale;
  final TargetPlatformType platform;

  const _ScreenshotPlaceholder({
    required this.width,
    required this.height,
    required this.scale,
    required this.platform,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.95),
            const Color(0xFFF7F2E2).withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40 * scale),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3 * scale),
            ),
            child: Icon(
              platform == TargetPlatformType.appStore ? Icons.phone_iphone_rounded : Icons.phone_android_rounded,
              size: 140 * scale,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 40 * scale),
          Text(
            'Upload ${platform.screenshotLabel} screenshot',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 52 * scale,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Select this frame, then use\n"App Screenshots" in the sidebar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 34 * scale,
              fontWeight: FontWeight.w500,
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButtonSpec {
  final bool isLeft;
  final double top;
  final double height;
  const _SideButtonSpec({required this.isLeft, required this.top, required this.height});
}

/// Cosmetic differences between the two realistic chassis. Everything that
/// affects size (body, inset, gutters) is shared and lives in [_RealisticPhoneFrame].
class _PhoneSkin {
  final double outerCornerRadius;
  final List<Color> chassisColors;
  final List<double> chassisStops;
  final Color antennaColor;
  final List<Color> buttonColors;
  final List<_SideButtonSpec> buttons;
  final Color glowColor;
  final double speakerTop;
  final double speakerWidth;
  final double speakerHeight;
  final Color speakerColor;
  final Color? speakerBorderColor;
  final Widget Function(double scale) buildCameraCutout;

  const _PhoneSkin({
    required this.outerCornerRadius,
    required this.chassisColors,
    required this.chassisStops,
    required this.antennaColor,
    required this.buttonColors,
    required this.buttons,
    required this.glowColor,
    required this.speakerTop,
    required this.speakerWidth,
    required this.speakerHeight,
    required this.speakerColor,
    required this.speakerBorderColor,
    required this.buildCameraCutout,
  });

  /// Titanium iPhone with Dynamic Island and left/right hardware keys.
  static final _PhoneSkin iphone16ProMax = _PhoneSkin(
    outerCornerRadius: 160,
    chassisColors: const [Color(0xFF757A84), Color(0xFF32353B), Color(0xFF525660), Color(0xFF181A1D)],
    chassisStops: const [0.0, 0.35, 0.75, 1.0],
    antennaColor: const Color(0xFF4C5058),
    buttonColors: const [Color(0xFF6B6F78), Color(0xFF2C2E33), Color(0xFF484D55)],
    buttons: const [
      _SideButtonSpec(isLeft: true, top: 300, height: 100), // Action switch
      _SideButtonSpec(isLeft: true, top: 450, height: 200), // Volume up
      _SideButtonSpec(isLeft: true, top: 680, height: 200), // Volume down
      _SideButtonSpec(isLeft: false, top: 560, height: 250), // Power
    ],
    glowColor: AppColors.primary,
    speakerTop: 8,
    speakerWidth: 60,
    speakerHeight: 3.5,
    speakerColor: const Color(0xFF0A0A0C),
    speakerBorderColor: const Color(0xFF383C45),
    buildCameraCutout: (scale) => Positioned(
      top: 40 * scale,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 300 * scale,
          height: 80 * scale,
          padding: EdgeInsets.symmetric(horizontal: 18 * scale),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(38 * scale),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 8 * scale,
                offset: Offset(0, 3 * scale),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 15 * scale,
                height: 15 * scale,
                decoration: const BoxDecoration(color: Color(0xFF0A0C10), shape: BoxShape.circle),
              ),
              _CameraLens(diameter: 20 * scale, scale: scale),
            ],
          ),
        ),
      ),
    ),
  );

  /// Champagne-titanium Galaxy Ultra with a hole-punch camera and right-side keys.
  static final _PhoneSkin galaxyS26Ultra = _PhoneSkin(
    outerCornerRadius: 70,
    chassisColors: const [Color(0xFFF5EFE4), Color(0xFFDCD3C4), Color(0xFFC2B7A6), Color(0xFFE8E0D4)],
    chassisStops: const [0.0, 0.4, 0.8, 1.0],
    antennaColor: const Color(0xFF9E9484),
    buttonColors: const [Color(0xFFF3EDE2), Color(0xFFC4BBB0), Color(0xFFD6CFC3)],
    buttons: const [
      _SideButtonSpec(isLeft: false, top: 200, height: 250), // Volume rocker
      _SideButtonSpec(isLeft: false, top: 530, height: 125), // Power
    ],
    glowColor: const Color(0xFFDCD4C7),
    speakerTop: 4,
    speakerWidth: 44,
    speakerHeight: 2.5,
    speakerColor: const Color(0xFF0D0D0F),
    speakerBorderColor: null,
    buildCameraCutout: (scale) => Positioned(
      top: 30 * scale,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 36 * scale,
          height: 36 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: const Color(0xFF424752), width: 1.5 * scale),
          ),
          child: Center(child: _CameraLens(diameter: 14 * scale, scale: scale)),
        ),
      ),
    ),
  );
}

class _CameraLens extends StatelessWidget {
  final double diameter;
  final double scale;
  const _CameraLens({required this.diameter, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF1D4275), Color(0xFF0F2648), Color(0xFF000000)],
          stops: [0.2, 0.7, 1.0],
        ),
        border: Border.all(color: const Color(0xFF2B303D), width: 1.5 * scale),
      ),
      child: Align(
        alignment: const Alignment(0.4, -0.4),
        child: Container(
          width: diameter * 0.25,
          height: diameter * 0.25,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// One chassis implementation for both realistic phones. The rim, bezel and
/// button gutters are identical so the screenshot area matches exactly.
class _RealisticPhoneFrame extends StatelessWidget {
  final _PhoneSkin skin;
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const _RealisticPhoneFrame({
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
              child: _SideButton(
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(outerCornerRadius),
                boxShadow: shadows,
              ),
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

class _SideButton extends StatelessWidget {
  final double width;
  final double height;
  final bool isLeft;
  final List<Color> colors;
  final double scale;

  const _SideButton({
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
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
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

/// Universal minimal dark frame.
class _MinimalDarkFrame extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const _MinimalDarkFrame({
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
              color: AppColors.primary.withValues(alpha: 0.25),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius - (4 * scale)),
        child: screenshotWidget,
      ),
    );
  }
}

/// Raw screenshot without a frame (shadow only).
class _RawScreenshotFrame extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const _RawScreenshotFrame({
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18 * scale),
        child: screenshotWidget,
      ),
    );
  }
}
