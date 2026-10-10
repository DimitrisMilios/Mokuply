import 'package:flutter/material.dart';

/// Store targets the project can be previewed and exported for.
///
/// Every screen is authored once in [DesignSpace] coordinates; a target only
/// decides the output pixel size (and which realistic phone chassis is drawn).
enum TargetPlatformType {
  appStore('Apple App Store', 'App Store', 'iPhone 16 Pro Max', 'iPhone', 1320, 2868),
  googlePlay('Google Play Store', 'Google Play', 'Galaxy S26 Ultra', 'Android', 1320, 2868);

  final String platformName;
  final String shortName;
  final String deviceName;
  final String screenshotLabel;
  final double targetWidth;
  final double targetHeight;

  const TargetPlatformType(
    this.platformName,
    this.shortName,
    this.deviceName,
    this.screenshotLabel,
    this.targetWidth,
    this.targetHeight,
  );

  double get aspectRatio => targetWidth / targetHeight;

  Size get targetSize => Size(targetWidth, targetHeight);

  String get dimensionsLabel => '${targetWidth.toInt()}×${targetHeight.toInt()}';

  String get exportFolderName => this == TargetPlatformType.appStore
      ? 'Apple_App_Store_${targetWidth.toInt()}x${targetHeight.toInt()}'
      : 'Google_Play_Store_${targetWidth.toInt()}x${targetHeight.toInt()}';

  TargetPlatformType get other =>
      this == TargetPlatformType.appStore ? TargetPlatformType.googlePlay : TargetPlatformType.appStore;
}

/// The single, store-independent coordinate system every screen is designed in.
///
/// It matches the Apple App Store 6.9" canvas so the Apple export is a 1:1
/// render. Other targets (Google Play) render the same design with one uniform
/// scale, centred on their canvas, so the composition is identical everywhere.
class DesignSpace {
  DesignSpace._();

  static const double width = 1320.0;
  static const double height = 2868.0;
  static const Size size = Size(width, height);
  static const double aspectRatio = width / height;

  /// Stored element offsets are expressed in these units: X in 1/1000 of the
  /// design width, Y in 1/2000 of the design height.
  static const double offsetUnitX = width / 1000.0;
  static const double offsetUnitY = height / 2000.0;

  /// Font sizes in the models are real pixels on the 1320×2868 export.
  static const double textScale = 1.0;

  /// Drafts saved before font sizes became export pixels used a 1000px-wide
  /// reference, so their values are multiplied by this on load.
  static const double legacyTextScale = width / 1000.0;

  /// Marker written to JSON so loaders can tell the two font units apart.
  static const String textUnitKey = 'textUnit';
  static const String textUnitPixels = 'px';

  /// Phone frame body width as a fraction of the design width.
  static const double deviceWidthFraction = 0.72;

  /// Width of a custom image asset at scale 1.0, as a fraction of the design width.
  static const double customImageWidthFraction = 0.4;

  /// Maximum width a headline may take before it wraps, as a fraction of the design width.
  static const double maxTextWidthFraction = 0.92;
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

/// Visual style of a phone frame. [realistic] is store-aware: it draws an
/// iPhone on the App Store and a Galaxy on Google Play with the exact same
/// footprint, so the layout never shifts between stores.
enum DeviceFrameStyle {
  realistic('Realistic Phone', 'iPhone 16 Pro Max on the App Store, Galaxy S26 Ultra on Google Play'),
  minimalOutline('Minimal Dark Frame', 'Universal clean rounded frame'),
  none('Raw Screenshot', 'No frame border, shadow only');

  /// Display label. (Deliberately not called `name`, which is the enum identifier used in JSON.)
  final String label;
  final String description;
  const DeviceFrameStyle(this.label, this.description);

  /// Human label for the current preview store (e.g. "iPhone 16 Pro Max").
  String labelFor(TargetPlatformType platform) => this == DeviceFrameStyle.realistic ? platform.deviceName : label;

  /// Parses a serialized style. Accepts the enum identifier, the legacy
  /// per-device identifiers, and the display labels older drafts stored.
  static DeviceFrameStyle fromName(String? value) {
    switch (value) {
      case 'realistic':
      case 'iphone16ProMax':
      case 'samsungS26Ultra':
      case 'Realistic Phone':
      case 'iPhone 16 Pro Max':
      case 'Samsung S26 Ultra':
        return DeviceFrameStyle.realistic;
      case 'minimalOutline':
      case 'Minimal Dark Frame':
        return DeviceFrameStyle.minimalOutline;
      case 'none':
      case 'Raw Screenshot':
        return DeviceFrameStyle.none;
      default:
        return DeviceFrameStyle.realistic;
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
    // Softer, lower-contrast stops so headlines and phones stay the focus.
    ColorGradientPreset(
      name: 'Midnight Cyber',
      colors: [Color(0xFF0B1220), Color(0xFF15224A), Color(0xFF0E7490)],
    ),
    ColorGradientPreset(
      name: 'Aurora Borealis',
      colors: [Color(0xFF052E2B), Color(0xFF0F766E), Color(0xFF2563EB)],
    ),
    ColorGradientPreset(
      name: 'Sunset Glow',
      colors: [Color(0xFF2B0E1E), Color(0xFF8F2A4D), Color(0xFFF08A4B)],
    ),
    ColorGradientPreset(
      name: 'Neon Violet',
      colors: [Color(0xFF1E0B33), Color(0xFF5B21B6), Color(0xFFDB2777)],
    ),
    ColorGradientPreset(
      name: 'Titanium Dark',
      colors: [Color(0xFF111113), Color(0xFF1F1F23), Color(0xFF0A0A0B)],
    ),
    ColorGradientPreset(
      name: 'Clean Studio Light',
      colors: [Color(0xFFFAFAF9), Color(0xFFF1F2F4), Color(0xFFE2E6EB)],
    ),
  ];

  /// Suggested families shown at the top of the font picker; any Google Font is allowed.
  static const List<String> popularFonts = [
    'Inter',
    'Outfit',
    'Roboto',
    'Poppins',
    'Montserrat',
    'Playfair Display',
    'Space Grotesk',
  ];
}
