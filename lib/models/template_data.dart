import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';

/// Pure immutable data model for a mockup template.
@immutable
class TemplateData {
  final TargetPlatformType platform;
  final LayoutMode layoutMode;
  final DeviceFrameStyle frameStyle;
  final String titleText;
  final String subtitleText;
  final String titleFont;
  final String subtitleFont;
  final double titleSize;
  final double subtitleSize;
  final Color textColor;
  final Color subtitleColor;
  final int selectedGradientIndex;
  final Color? customBackgroundColor;
  final List<Color>? customGradientColors;
  final Uint8List? customBackgroundImageBytes;
  final Uint8List? screenshotBytes;
  final Uint8List? iphoneScreenshotBytes;
  final Uint8List? samsungScreenshotBytes;
  final double deviceScale;
  final double deviceOffsetX;
  final double deviceOffsetY;
  final double textOffsetX;
  final double textOffsetY;
  final double deviceRotation;
  final bool hasShadow;

  const TemplateData({
    this.platform = TargetPlatformType.appStore,
    this.layoutMode = LayoutMode.titleTopDeviceBottom,
    this.frameStyle = DeviceFrameStyle.iphone16ProMax,
    this.titleText = 'Build Stunning Apps',
    this.subtitleText = 'Design high-res store screenshots in seconds',
    this.titleFont = 'Outfit',
    this.subtitleFont = 'Inter',
    this.titleSize = 54.0,
    this.subtitleSize = 26.0,
    this.textColor = Colors.white,
    this.subtitleColor = const Color(0xFFE2E8F0),
    this.selectedGradientIndex = 0,
    this.customBackgroundColor,
    this.customGradientColors,
    this.customBackgroundImageBytes,
    this.screenshotBytes,
    this.iphoneScreenshotBytes,
    this.samsungScreenshotBytes,
    this.deviceScale = 0.85,
    this.deviceOffsetX = 0.0,
    this.deviceOffsetY = 0.0,
    this.textOffsetX = 0.0,
    this.textOffsetY = 0.0,
    this.deviceRotation = 0.0,
    this.hasShadow = true,
  });

  /// Computes effective screenshot bytes for active device model style (per-platform override or shared screenshot)
  Uint8List? get effectiveScreenshotBytes {
    if (frameStyle == DeviceFrameStyle.iphone16ProMax && iphoneScreenshotBytes != null) {
      return iphoneScreenshotBytes;
    }
    if (frameStyle == DeviceFrameStyle.samsungS26Ultra && samsungScreenshotBytes != null) {
      return samsungScreenshotBytes;
    }
    return screenshotBytes;
  }

  TemplateData copyWith({
    TargetPlatformType? platform,
    LayoutMode? layoutMode,
    DeviceFrameStyle? frameStyle,
    String? titleText,
    String? subtitleText,
    String? titleFont,
    String? subtitleFont,
    double? titleSize,
    double? subtitleSize,
    Color? textColor,
    Color? subtitleColor,
    int? selectedGradientIndex,
    Color? Function()? customBackgroundColor,
    List<Color>? Function()? customGradientColors,
    Uint8List? Function()? customBackgroundImageBytes,
    Uint8List? Function()? screenshotBytes,
    Uint8List? Function()? iphoneScreenshotBytes,
    Uint8List? Function()? samsungScreenshotBytes,
    double? deviceScale,
    double? deviceOffsetX,
    double? deviceOffsetY,
    double? textOffsetX,
    double? textOffsetY,
    double? deviceRotation,
    bool? hasShadow,
  }) {
    return TemplateData(
      platform: platform ?? this.platform,
      layoutMode: layoutMode ?? this.layoutMode,
      frameStyle: frameStyle ?? this.frameStyle,
      titleText: titleText ?? this.titleText,
      subtitleText: subtitleText ?? this.subtitleText,
      titleFont: titleFont ?? this.titleFont,
      subtitleFont: subtitleFont ?? this.subtitleFont,
      titleSize: titleSize ?? this.titleSize,
      subtitleSize: subtitleSize ?? this.subtitleSize,
      textColor: textColor ?? this.textColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      selectedGradientIndex: selectedGradientIndex ?? this.selectedGradientIndex,
      customBackgroundColor: customBackgroundColor != null ? customBackgroundColor() : this.customBackgroundColor,
      customGradientColors: customGradientColors != null ? customGradientColors() : this.customGradientColors,
      customBackgroundImageBytes: customBackgroundImageBytes != null ? customBackgroundImageBytes() : this.customBackgroundImageBytes,
      screenshotBytes: screenshotBytes != null ? screenshotBytes() : this.screenshotBytes,
      iphoneScreenshotBytes: iphoneScreenshotBytes != null ? iphoneScreenshotBytes() : this.iphoneScreenshotBytes,
      samsungScreenshotBytes: samsungScreenshotBytes != null ? samsungScreenshotBytes() : this.samsungScreenshotBytes,
      deviceScale: deviceScale ?? this.deviceScale,
      deviceOffsetX: deviceOffsetX ?? this.deviceOffsetX,
      deviceOffsetY: deviceOffsetY ?? this.deviceOffsetY,
      textOffsetX: textOffsetX ?? this.textOffsetX,
      textOffsetY: textOffsetY ?? this.textOffsetY,
      deviceRotation: deviceRotation ?? this.deviceRotation,
      hasShadow: hasShadow ?? this.hasShadow,
    );
  }
}

