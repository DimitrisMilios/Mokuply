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
    // Frame base width & height according to platform target
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
      // Placeholder preview image when no file uploaded yet
      screenshotWidget = Container(
        width: deviceWidth,
        height: deviceHeight,
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

    switch (frameStyle) {
      case DeviceFrameStyle.iphone16ProMax:
        return _RealisticIPhone16ProMaxFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );

      case DeviceFrameStyle.samsungS26Ultra:
        return _RealisticSamsungS26UltraFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );

      case DeviceFrameStyle.minimalOutline:
        return _MinimalDarkFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );

      case DeviceFrameStyle.none:
        return _RawScreenshotFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );
    }
  }
}

/// Hyper-realistic iPhone 16 Pro Max Frame with Titanium Finish, Side Buttons, Dynamic Island & Speaker Earpiece
class _RealisticIPhone16ProMaxFrame extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const _RealisticIPhone16ProMaxFrame({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.scale,
    required this.hasShadow,
    required this.screenshotWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Ultra-rounded continuous squircle corners matching real iPhone Pro Max chassis
    final double outerCornerRadius = 160 * scale;
    final double titaniumFrameThickness = 12 * scale; // Bold, thick titanium frame
    final double displayBezelThickness = 16 * scale;  // Bold, thick black screen bezel
    final double totalFramePadding = titaniumFrameThickness + displayBezelThickness;
    final double innerCornerRadius = outerCornerRadius - (totalFramePadding * 0.7);
    final double buttonWidth = 8.0 * scale; // Extra large, prominent side hardware buttons

    // Realistic multi-layered drop shadow
    final List<BoxShadow> shadows = hasShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 40 * scale,
              spreadRadius: 4 * scale,
              offset: Offset(0, 24 * scale),
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.22),
              blurRadius: 80 * scale,
              spreadRadius: 12 * scale,
              offset: Offset(0, 34 * scale),
            ),
          ]
        : [];

    return SizedBox(
      width: deviceWidth + (buttonWidth * 2),
      height: deviceHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. EXTRA LARGE LEFT HARDWARE BUTTONS (Silent Switch, Volume Up, Volume Down)
          // Silent / Action Switch (Top Left)
          Positioned(
            left: 0,
            top: 300 * scale,
            child: _buildSideButton(
              width: buttonWidth,
              height: 100 * scale,
              isLeft: true,
              gradientColors: const [Color(0xFF6B6F78), Color(0xFF2C2E33), Color(0xFF484D55)],
            ),
          ),
          // Volume Up Button (Upper-Left)
          Positioned(
            left: 0,
            top: 450 * scale,
            child: _buildSideButton(
              width: buttonWidth,
              height: 200 * scale,
              isLeft: true,
              gradientColors: const [Color(0xFF6B6F78), Color(0xFF2C2E33), Color(0xFF484D55)],
            ),
          ),
          // Volume Down Button (Middle-Left)
          Positioned(
            left: 0,
            top: 680 * scale,
            child: _buildSideButton(
              width: buttonWidth,
              height: 200 * scale,
              isLeft: true,
              gradientColors: const [Color(0xFF6B6F78), Color(0xFF2C2E33), Color(0xFF484D55)],
            ),
          ),

          // 2. EXTRA LARGE RIGHT HARDWARE BUTTON (Power Key Centered Vertically)
          Positioned(
            right: 0,
            top: 560 * scale, // Centered vertically in exact middle of right edge!
            child: _buildSideButton(
              width: buttonWidth,
              height: 250 * scale,
              isLeft: false,
              gradientColors: const [Color(0xFF727680), Color(0xFF30333A), Color(0xFF50555F)],
            ),
          ),

          // 3. MAIN PHONE BODY CONTAINER
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
                  // Titanium Outer Chassis Frame (Bold Brushed Titanium Outer Rim)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(outerCornerRadius),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF757A84), // Bright specular highlight top left
                          Color(0xFF32353B), // Main dark brushed titanium body
                          Color(0xFF525660), // Specular accent bottom right
                          Color(0xFF181A1D), // Deep shadow edge
                        ],
                        stops: [0.0, 0.35, 0.75, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(titaniumFrameThickness), // Bold Titanium Rim
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(outerCornerRadius - titaniumFrameThickness),
                          color: const Color(0xFF000000), // Deep matte black screen bezel
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(displayBezelThickness),
                          // 4. SCREEN DISPLAY SCREENSHOT
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(innerCornerRadius),
                            child: Stack(
                              children: [
                                Positioned.fill(child: screenshotWidget),

                                // Inner Display Edge Bezel Shadow (Subtle depth overlay)
                                Positioned.fill(
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

                                // 5. EXTRA LARGE DYNAMIC ISLAND (Massive Pill Cutout with Dual Sensors)
                                Positioned(
                                  top: 40 * scale,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      width: 300 * scale, // Extra wide Dynamic Island
                                      height:80 * scale, // Extra tall Dynamic Island
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
                                          // FaceID Infrared Sensor Aperture (Left)
                                          Container(
                                            width: 15 * scale,
                                            height: 15 * scale,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0A0C10),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          // Front Camera Lens with Blue Reflection & Specular Dot (Right)
                                          Container(
                                            width: 20 * scale,
                                            height: 20 * scale,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const RadialGradient(
                                                colors: [
                                                  Color(0xFF1D4275), // Deep blue optical lens reflection
                                                  Color(0xFF0F2648),
                                                  Color(0xFF000000),
                                                ],
                                                stops: [0.2, 0.7, 1.0],
                                              ),
                                              border: Border.all(color: const Color(0xFF2B303D), width: 1.5 * scale),
                                            ),
                                            child: Align(
                                              alignment: const Alignment(0.4, -0.4),
                                              child: Container(
                                                width: 5 * scale,
                                                height: 5 * scale,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.9),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 6. TOP EARPIECE SPEAKER SLIT
                  Positioned(
                    top: 8 * scale,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 60 * scale,
                        height: 3.5 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0C),
                          borderRadius: BorderRadius.circular(2 * scale),
                          border: Border.all(color: const Color(0xFF383C45), width: 0.8 * scale),
                        ),
                      ),
                    ),
                  ),

                  // 7. ANTENNA BREAK LINES (Subtle plastic cutouts on titanium rim)
                  // Left top antenna break
                  Positioned(
                    left: 0,
                    top: 80 * scale,
                    child: Container(width: 4 * scale, height: 3.5 * scale, color: const Color(0xFF4C5058)),
                  ),
                  // Right top antenna break
                  Positioned(
                    right: 0,
                    top: 80 * scale,
                    child: Container(width: 4 * scale, height: 3.5 * scale, color: const Color(0xFF4C5058)),
                  ),
                  // Left bottom antenna break
                  Positioned(
                    left: 0,
                    bottom: 80 * scale,
                    child: Container(width: 4 * scale, height: 3.5 * scale, color: const Color(0xFF4C5058)),
                  ),
                  // Right bottom antenna break
                  Positioned(
                    right: 0,
                    bottom: 80 * scale,
                    child: Container(width: 4 * scale, height: 3.5 * scale, color: const Color(0xFF4C5058)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required double width,
    required double height,
    required bool isLeft,
    required List<Color> gradientColors,
  }) {
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
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4 * scale,
            offset: Offset(isLeft ? -2 : 2, 2),
          ),
        ],
      ),
    );
  }
}

/// Hyper-realistic Samsung S26 Ultra Frame with Warm Titanium Industrial Chassis, Side Buttons & Multi-Ring Camera Lens
class _RealisticSamsungS26UltraFrame extends StatelessWidget {
  final double deviceWidth;
  final double deviceHeight;
  final double scale;
  final bool hasShadow;
  final Widget screenshotWidget;

  const _RealisticSamsungS26UltraFrame({
    required this.deviceWidth,
    required this.deviceHeight,
    required this.scale,
    required this.hasShadow,
    required this.screenshotWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Signature Ultra sharp corners
    final double outerCornerRadius = 70 * scale;
    final double titaniumFrameThickness = 10 * scale;
    final double displayBezelThickness = 12 * scale;
    final double innerCornerRadius = 50 * scale;
    final double buttonWidth = 10.0 * scale; // Prominent side buttons

    final List<BoxShadow> shadows = hasShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 34 * scale,
              spreadRadius: 3 * scale,
              offset: Offset(0, 18 * scale),
            ),
            BoxShadow(
              color: const Color(0xFFDCD4C7).withValues(alpha: 0.18),
              blurRadius: 55 * scale,
              spreadRadius: 8 * scale,
              offset: Offset(0, 26 * scale),
            ),
          ]
        : [];

    return SizedBox(
      width: deviceWidth + buttonWidth,
      height: deviceHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. HARDWARE BUTTONS ON RIGHT SIDE (Volume Rocker + Power Key)
          // Volume Rocker (Upper Right)
          Positioned(
            right: 0,
            top: 200 * scale,
            child: _buildSideButton(
              width: buttonWidth,
              height: 250 * scale,
              gradientColors: const [Color(0xFFF3EDE2), Color(0xFFC4BBB0), Color(0xFFD6CFC3)],
            ),
          ),
          // Power Key (Lower Right)
          Positioned(
            right: 0,
            top: 530 * scale,
            child: _buildSideButton(
              width: buttonWidth,
              height: 125 * scale,
              gradientColors: const [Color(0xFFF3EDE2), Color(0xFFC4BBB0), Color(0xFFD6CFC3)],
            ),
          ),

          // 2. MAIN INDUSTRIAL PHONE BODY
          Positioned(
            left: 0,
            child: Container(
              width: deviceWidth,
              height: deviceHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(outerCornerRadius),
                boxShadow: shadows,
              ),
              child: Stack(
                children: [
                  // Warm Titanium Outer Chassis Frame (Golden Titanium finish matching Galaxy Ultra)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(outerCornerRadius),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF5EFE4), // Bright champagne titanium specular highlight
                          Color(0xFFDCD3C4), // Natural titanium main body
                          Color(0xFFC2B7A6), // Darker chamfer accent
                          Color(0xFFE8E0D4), // Bottom right warm specular
                        ],
                        stops: [0.0, 0.4, 0.8, 1.0],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(titaniumFrameThickness), // Bold Warm Titanium Outer Rim
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(outerCornerRadius - 2),
                          color: const Color(0xFF000000), // Dark screen bezel wall
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(displayBezelThickness),
                          // 3. DISPLAY SCREENSHOT CONTENT
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(innerCornerRadius),
                            child: Stack(
                              children: [
                                Positioned.fill(child: screenshotWidget),

                                // 4. INFINITY-O HOLE-PUNCH CAMERA (Larger Precision Multi-Ring Optical Lens)
                                Positioned(
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
                                        border: Border.all(
                                          color: const Color(0xFF424752), // Metal lens housing ring
                                          width: 1.5 * scale,
                                        ),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 14 * scale,
                                          height: 14 * scale,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const RadialGradient(
                                              colors: [
                                                Color(0xFF1D3B63), // Deep cyan-blue anti-reflective glass coating
                                                Color(0xFF0F223D),
                                                Color(0xFF040A14),
                                              ],
                                              stops: [0.1, 0.6, 1.0],
                                            ),
                                          ),
                                          child: Align(
                                            alignment: const Alignment(0.4, -0.4),
                                            child: Container(
                                              width: 3.5 * scale,
                                              height: 3.5 * scale,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFB0ECFF).withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 5. TOP MICRO EARPIECE SPEAKER SLIT
                  Positioned(
                    top: 4 * scale,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 44 * scale,
                        height: 2.5 * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0F),
                          borderRadius: BorderRadius.circular(1 * scale),
                        ),
                      ),
                    ),
                  ),

                  // 6. ANTENNA PLASTIC BREAK LINES
                  // Top left antenna break
                  Positioned(
                    left: 0,
                    top: 50 * scale,
                    child: Container(width: 3 * scale, height: 3 * scale, color: const Color(0xFF9E9484)),
                  ),
                  // Top right antenna break
                  Positioned(
                    right: 0,
                    top: 50 * scale,
                    child: Container(width: 3 * scale, height: 3 * scale, color: const Color(0xFF9E9484)),
                  ),
                  // Bottom left antenna break
                  Positioned(
                    left: 0,
                    bottom: 50 * scale,
                    child: Container(width: 3 * scale, height: 3 * scale, color: const Color(0xFF9E9484)),
                  ),
                  // Bottom right antenna break
                  Positioned(
                    right: 0,
                    bottom: 50 * scale,
                    child: Container(width: 3 * scale, height: 3 * scale, color: const Color(0xFF9E9484)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required double width,
    required double height,
    required List<Color> gradientColors,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(3 * scale),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3 * scale,
            offset: Offset(1.5 * scale, 1.5 * scale),
          ),
        ],
      ),
    );
  }
}


/// Universal Minimal Dark Frame
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
        : [];

    return Container(
      width: deviceWidth,
      height: deviceHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cornerRadius),
        boxShadow: shadows,
        border: Border.all(
          color: const Color(0xFF2D303E),
          width: 5 * scale,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius - (4 * scale)),
        child: screenshotWidget,
      ),
    );
  }
}

/// Raw Screenshot without frame border (Shadow Only)
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
        : [];

    return Container(
      width: deviceWidth,
      height: deviceHeight,
      decoration: BoxDecoration(
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18 * scale),
        child: screenshotWidget,
      ),
    );
  }
}

