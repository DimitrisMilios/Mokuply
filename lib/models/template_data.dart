import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import 'canvas_device_item.dart';
import 'canvas_image_item.dart';
import 'canvas_text_item.dart';

/// Pure immutable data model for a mockup template screen.
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
  final FontWeight titleWeight;
  final FontWeight subtitleWeight;
  final Color textColor;
  final Color subtitleColor;
  final TextAlign titleAlignment;
  final TextAlign subtitleAlignment;
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
  final double textOffsetX; // Title X offset
  final double textOffsetY; // Title Y offset
  final double subtitleOffsetX;
  final double subtitleOffsetY;
  final double deviceRotation;
  final bool hasShadow;

  /// Multi-Element Collections per Canvas Screen
  final List<CanvasDeviceItem> devices;
  final List<CanvasImageItem> customImageItems;
  final List<CanvasTextItem> customTextItems;

  const TemplateData({
    this.platform = TargetPlatformType.appStore,
    this.layoutMode = LayoutMode.titleTopDeviceBottom,
    this.frameStyle = DeviceFrameStyle.iphone16ProMax,
    this.titleText = 'Build Stunning Apps',
    this.subtitleText = 'Design high-res store screenshots in seconds',
    this.titleFont = 'Outfit',
    this.subtitleFont = 'Inter',
    this.titleSize = 64.0,
    this.subtitleSize = 30.0,
    this.titleWeight = FontWeight.w700,
    this.subtitleWeight = FontWeight.w500,
    this.textColor = Colors.white,
    this.subtitleColor = const Color(0xFFE2E8F0),
    this.titleAlignment = TextAlign.center,
    this.subtitleAlignment = TextAlign.center,
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
    this.subtitleOffsetX = 0.0,
    this.subtitleOffsetY = 0.0,
    this.deviceRotation = 0.0,
    this.hasShadow = true,
    this.appStoreTextOffsetX,
    this.appStoreTextOffsetY,
    this.googlePlayTextOffsetX,
    this.googlePlayTextOffsetY,
    this.appStoreSubtitleOffsetX,
    this.appStoreSubtitleOffsetY,
    this.googlePlaySubtitleOffsetX,
    this.googlePlaySubtitleOffsetY,
    this.devices = const [],
    this.customImageItems = const [],
    this.customTextItems = const [],
  });

  final double? appStoreTextOffsetX;
  final double? appStoreTextOffsetY;
  final double? googlePlayTextOffsetX;
  final double? googlePlayTextOffsetY;

  final double? appStoreSubtitleOffsetX;
  final double? appStoreSubtitleOffsetY;
  final double? googlePlaySubtitleOffsetX;
  final double? googlePlaySubtitleOffsetY;

  double textOffsetXFor(TargetPlatformType p) =>
      p == TargetPlatformType.appStore ? (appStoreTextOffsetX ?? textOffsetX) : (googlePlayTextOffsetX ?? textOffsetX);

  double textOffsetYFor(TargetPlatformType p) =>
      p == TargetPlatformType.appStore ? (appStoreTextOffsetY ?? textOffsetY) : (googlePlayTextOffsetY ?? textOffsetY);

  double subtitleOffsetXFor(TargetPlatformType p) =>
      p == TargetPlatformType.appStore ? (appStoreSubtitleOffsetX ?? subtitleOffsetX) : (googlePlaySubtitleOffsetX ?? subtitleOffsetX);

  double subtitleOffsetYFor(TargetPlatformType p) =>
      p == TargetPlatformType.appStore ? (appStoreSubtitleOffsetY ?? subtitleOffsetY) : (googlePlaySubtitleOffsetY ?? subtitleOffsetY);

  /// Computes effective screenshot bytes for active primary device model style
  Uint8List? get effectiveScreenshotBytes {
    if (frameStyle == DeviceFrameStyle.iphone16ProMax && iphoneScreenshotBytes != null) {
      return iphoneScreenshotBytes;
    }
    if (frameStyle == DeviceFrameStyle.samsungS26Ultra && samsungScreenshotBytes != null) {
      return samsungScreenshotBytes;
    }
    return screenshotBytes;
  }

  /// Returns effective list of phone frames on this canvas screen.
  /// If [devices] is non-empty, returns [devices].
  /// Otherwise, falls back to a primary device frame constructed from top-level properties.
  List<CanvasDeviceItem> get effectiveDevices {
    if (devices.isNotEmpty) return devices;
    return [
      CanvasDeviceItem(
        id: 'dev_primary',
        frameStyle: frameStyle,
        screenshotBytes: effectiveScreenshotBytes,
        scale: deviceScale,
        offsetX: deviceOffsetX,
        offsetY: deviceOffsetY,
        rotation: deviceRotation,
        hasShadow: hasShadow,
      ),
    ];
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
    FontWeight? titleWeight,
    FontWeight? subtitleWeight,
    Color? textColor,
    Color? subtitleColor,
    TextAlign? titleAlignment,
    TextAlign? subtitleAlignment,
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
    double? subtitleOffsetX,
    double? subtitleOffsetY,
    double? deviceRotation,
    bool? hasShadow,
    double? appStoreTextOffsetX,
    double? appStoreTextOffsetY,
    double? googlePlayTextOffsetX,
    double? googlePlayTextOffsetY,
    double? appStoreSubtitleOffsetX,
    double? appStoreSubtitleOffsetY,
    double? googlePlaySubtitleOffsetX,
    double? googlePlaySubtitleOffsetY,
    List<CanvasDeviceItem>? devices,
    List<CanvasImageItem>? customImageItems,
    List<CanvasTextItem>? customTextItems,
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
      titleWeight: titleWeight ?? this.titleWeight,
      subtitleWeight: subtitleWeight ?? this.subtitleWeight,
      textColor: textColor ?? this.textColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      titleAlignment: titleAlignment ?? this.titleAlignment,
      subtitleAlignment: subtitleAlignment ?? this.subtitleAlignment,
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
      subtitleOffsetX: subtitleOffsetX ?? this.subtitleOffsetX,
      subtitleOffsetY: subtitleOffsetY ?? this.subtitleOffsetY,
      deviceRotation: deviceRotation ?? this.deviceRotation,
      hasShadow: hasShadow ?? this.hasShadow,
      appStoreTextOffsetX: appStoreTextOffsetX ?? this.appStoreTextOffsetX,
      appStoreTextOffsetY: appStoreTextOffsetY ?? this.appStoreTextOffsetY,
      googlePlayTextOffsetX: googlePlayTextOffsetX ?? this.googlePlayTextOffsetX,
      googlePlayTextOffsetY: googlePlayTextOffsetY ?? this.googlePlayTextOffsetY,
      appStoreSubtitleOffsetX: appStoreSubtitleOffsetX ?? this.appStoreSubtitleOffsetX,
      appStoreSubtitleOffsetY: appStoreSubtitleOffsetY ?? this.appStoreSubtitleOffsetY,
      googlePlaySubtitleOffsetX: googlePlaySubtitleOffsetX ?? this.googlePlaySubtitleOffsetX,
      googlePlaySubtitleOffsetY: googlePlaySubtitleOffsetY ?? this.googlePlaySubtitleOffsetY,
      devices: devices ?? this.devices,
      customImageItems: customImageItems ?? this.customImageItems,
      customTextItems: customTextItems ?? this.customTextItems,
    );
  }
}
