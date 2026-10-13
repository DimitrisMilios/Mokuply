import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SideButtonSpec {
  final bool isLeft;
  final double top;
  final double height;
  const SideButtonSpec({required this.isLeft, required this.top, required this.height});
}

/// Cosmetic differences between the two realistic chassis. Everything that
/// affects size (body, inset, gutters) is shared and lives in [RealisticPhoneFrame].
class PhoneSkin {
  final double outerCornerRadius;
  final List<Color> chassisColors;
  final List<double> chassisStops;
  final Color antennaColor;
  final List<Color> buttonColors;
  final List<SideButtonSpec> buttons;
  final Color glowColor;
  final double speakerTop;
  final double speakerWidth;
  final double speakerHeight;
  final Color speakerColor;
  final Color? speakerBorderColor;
  final Widget Function(double scale) buildCameraCutout;

  const PhoneSkin({
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
  static final PhoneSkin iphone16ProMax = PhoneSkin(
    outerCornerRadius: 160,
    chassisColors: const [Color(0xFF757A84), Color(0xFF32353B), Color(0xFF525660), Color(0xFF181A1D)],
    chassisStops: const [0.0, 0.35, 0.75, 1.0],
    antennaColor: const Color(0xFF4C5058),
    buttonColors: const [Color(0xFF6B6F78), Color(0xFF2C2E33), Color(0xFF484D55)],
    buttons: const [
      SideButtonSpec(isLeft: true, top: 300, height: 100), // Action switch
      SideButtonSpec(isLeft: true, top: 450, height: 200), // Volume up
      SideButtonSpec(isLeft: true, top: 680, height: 200), // Volume down
      SideButtonSpec(isLeft: false, top: 560, height: 250), // Power
    ],
    glowColor: AppColors.exportGlow,
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
              CameraLens(diameter: 20 * scale, scale: scale),
            ],
          ),
        ),
      ),
    ),
  );

  /// Champagne-titanium Galaxy Ultra with a hole-punch camera and right-side keys.
  static final PhoneSkin galaxyS26Ultra = PhoneSkin(
    outerCornerRadius: 70,
    chassisColors: const [Color(0xFFF5EFE4), Color(0xFFDCD3C4), Color(0xFFC2B7A6), Color(0xFFE8E0D4)],
    chassisStops: const [0.0, 0.4, 0.8, 1.0],
    antennaColor: const Color(0xFF9E9484),
    buttonColors: const [Color(0xFFF3EDE2), Color(0xFFC4BBB0), Color(0xFFD6CFC3)],
    buttons: const [
      SideButtonSpec(isLeft: false, top: 200, height: 250), // Volume rocker
      SideButtonSpec(isLeft: false, top: 530, height: 125), // Power
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
          child: Center(
            child: CameraLens(diameter: 14 * scale, scale: scale),
          ),
        ),
      ),
    ),
  );
}

class CameraLens extends StatelessWidget {
  final double diameter;
  final double scale;
  const CameraLens({super.key, required this.diameter, required this.scale});

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
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
        ),
      ),
    );
  }
}
