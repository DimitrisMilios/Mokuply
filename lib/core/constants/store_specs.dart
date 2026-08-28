import 'package:flutter/material.dart';

enum TargetPlatformType {
  appStore('Apple App Store', 'iPhone 16 Pro Max', 1320, 2868),
  googlePlay('Google Play Store', 'Samsung S26 Ultra', 1440, 2560);

  final String platformName;
  final String deviceName;
  final double targetWidth;
  final double targetHeight;

  const TargetPlatformType(
    this.platformName,
    this.deviceName,
    this.targetWidth,
    this.targetHeight,
  );

  double get aspectRatio => targetWidth / targetHeight;

  /// Baseline aspect ratio (Apple App Store standard: 1320 / 2868 = 0.46025)
  static const double referenceAspectRatio = 1320.0 / 2868.0;

  /// Baseline canvas height (Apple App Store standard: 2868)
  static const double referenceHeight = 2868.0;

  /// Relative scale correction factor to maintain identical visual occupancy across store aspect ratios
  double get scaleCorrectionFactor => referenceAspectRatio / aspectRatio;

  /// Height scale factor relative to standard reference height
  double get yOffsetScaleFactor => targetHeight / referenceHeight;
}

enum LayoutMode {
  angledLeftHero('Angled Left Hero', 'Top headline with phone tilted left (-15°)'),
  angledRightHero('Angled Right Hero', 'Top headline with phone tilted right (+15°)'),
  titleTopDeviceBottom('Top Headline + Bottom Device', 'Classic store layout with headline above'),
  titleBottomDeviceTop('Top Device + Bottom Headline', 'Modern layout with headline at the bottom'),
  deviceCentered('Centered Frame', 'Minimalist spotlight on the app screenshot'),
  fullBleedHero('Hero Screenshot', 'Large screenshot focus with subtle top title');

  final String title;
  final String description;
  const LayoutMode(this.title, this.description);
}

enum DeviceFrameStyle {
  iphone16ProMax('iPhone 16 Pro Max', 'Dynamic Island, ultra-thin bezels, titanium edge'),
  samsungS26Ultra('Samsung S26 Ultra', 'Sleek hole-punch, flat display, modern industrial frame'),
  minimalOutline('Minimal Dark Frame', 'Universal clean rounded frame'),
  none('Raw Screenshot', 'No frame border, shadow only');

  final String name;
  final String description;
  const DeviceFrameStyle(this.name, this.description);

  static List<DeviceFrameStyle> availableForPlatform(TargetPlatformType platform) {
    if (platform == TargetPlatformType.appStore) {
      return [
        DeviceFrameStyle.iphone16ProMax,
        DeviceFrameStyle.minimalOutline,
        DeviceFrameStyle.none,
      ];
    } else {
      return [
        DeviceFrameStyle.samsungS26Ultra,
        DeviceFrameStyle.minimalOutline,
        DeviceFrameStyle.none,
      ];
    }
  }
}

class ColorGradientPreset {
  final String name;
  final List<Color> colors;
  final Alignment begin;
  final Alignment end;

  const ColorGradientPreset({
    required this.name,
    required this.colors,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  BoxDecoration toDecoration() {
    if (colors.length == 1) {
      return BoxDecoration(color: colors.first);
    }
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ),
    );
  }
}

class StoreSpecs {
  static const List<ColorGradientPreset> gradientPresets = [
    ColorGradientPreset(
      name: 'Midnight Cyber',
      colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF0284C7)],
    ),
    ColorGradientPreset(
      name: 'Aurora Borealis',
      colors: [Color(0xFF064E3B), Color(0xFF0D9488), Color(0xFF3B82F6)],
    ),
    ColorGradientPreset(
      name: 'Sunset Glow',
      colors: [Color(0xFF4C0519), Color(0xFF9F1239), Color(0xFFF97316)],
    ),
    ColorGradientPreset(
      name: 'Neon Violet',
      colors: [Color(0xFF311042), Color(0xFF6B21A8), Color(0xFFEC4899)],
    ),
    ColorGradientPreset(
      name: 'Titanium Dark',
      colors: [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF09090B)],
    ),
    ColorGradientPreset(
      name: 'Clean Studio Light',
      colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
    ),
  ];

  static const List<String> fontFamilies = [
    'Inter',
    'Outfit',
    'Roboto',
    'Poppins',
    'Montserrat',
    'Playfair Display',
    'Space Grotesk',
  ];
}
