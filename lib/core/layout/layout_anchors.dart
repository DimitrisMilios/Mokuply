import '../constants/store_specs.dart';

/// Vertical anchors (fractions of the design height) where each layout
/// preset places the headline, the subtitle and the phone frames. Stored
/// element offsets are relative to these anchors.
class LayoutAnchors {
  final double title;
  final double subtitle;
  final double device;

  const LayoutAnchors({required this.title, required this.subtitle, required this.device});

  static LayoutAnchors forMode(LayoutMode mode) => switch (mode) {
    LayoutMode.angledLeftHero ||
    LayoutMode.angledRightHero ||
    LayoutMode.titleTopDeviceBottom => const LayoutAnchors(title: 0.08, subtitle: 0.17, device: 0.62),
    LayoutMode.titleBottomDeviceTop => const LayoutAnchors(title: 0.74, subtitle: 0.84, device: 0.36),
    LayoutMode.deviceCentered => const LayoutAnchors(title: 0.08, subtitle: 0.16, device: 0.54),
    LayoutMode.fullBleedHero => const LayoutAnchors(title: 0.08, subtitle: 0.17, device: 0.64),
  };

  /// Images and extra text are anchored at the vertical centre.
  static const double freeElement = 0.5;

  /// The full-bleed hero draws phones larger than their stored scale.
  static double deviceScaleBoost(LayoutMode mode) => mode == LayoutMode.fullBleedHero ? 1.15 : 1.0;
}
