import 'dart:ui' show Color;

import '../core/constants/store_specs.dart';
import 'canvas_device_item.dart';
import 'element_kind.dart';
import 'template_data.dart';

/// Phone placement applied by a layout preset.
class LayoutPreset {
  final double rotation;
  final double scale;
  final double offsetY;

  const LayoutPreset({this.rotation = 0.0, this.scale = 0.92, this.offsetY = 0.0});

  static LayoutPreset of(LayoutMode mode) => switch (mode) {
    LayoutMode.angledLeftHero => const LayoutPreset(rotation: -15.0, scale: 0.94, offsetY: 280.0),
    LayoutMode.angledRightHero => const LayoutPreset(rotation: 15.0, scale: 0.94, offsetY: 260.0),
    LayoutMode.fullBleedHero => const LayoutPreset(scale: 1.0),
    LayoutMode.titleTopDeviceBottom ||
    LayoutMode.titleBottomDeviceTop ||
    LayoutMode.deviceCentered => const LayoutPreset(),
  };
}

/// Pure screen-wide edits: layout presets, resets, style copies and new screens.
extension ScreenLayoutEdits on TemplateData {
  /// Applies layout [mode] and its phone placement to every frame.
  TemplateData withLayout(LayoutMode mode) {
    final preset = LayoutPreset.of(mode);
    return copyWith(
      layoutMode: mode,
      deviceRotation: preset.rotation,
      deviceScale: preset.scale,
      deviceOffsetY: preset.offsetY,
      devices: [
        for (final d in effectiveDevices)
          d.copyWith(rotation: preset.rotation, scale: preset.scale, offsetY: preset.offsetY),
      ],
    );
  }

  /// Puts every frame and both headlines back at their default position,
  /// size and tilt.
  TemplateData withResetPositions() {
    return copyWith(
      devices: [for (final d in effectiveDevices) d.copyWith(offsetX: 0.0, offsetY: 0.0, rotation: 0.0, scale: 0.92)],
      deviceOffsetX: 0.0,
      deviceOffsetY: 0.0,
      deviceRotation: 0.0,
      deviceScale: 0.92,
      textOffsetX: 0.0,
      textOffsetY: 0.0,
      subtitleOffsetX: 0.0,
      subtitleOffsetY: 0.0,
    );
  }

  /// A new screen with this screen's look (layout, background, typography and
  /// frames), placeholder words and no screenshots, images or extra text.
  TemplateData asNewScreen() {
    return copyWith(
      name: '',
      titleText: 'New headline',
      subtitleText: 'Describe this feature',
      devices: [
        for (final d in effectiveDevices)
          d.copyWith(
            id: ElementKind.device.newId('_${d.id.hashCode}'),
            iosScreenshotBytes: () => null,
            androidScreenshotBytes: () => null,
          ),
      ],
      customImageItems: const [],
      customTextItems: const [],
    );
  }

  /// This screen restyled like [source]: layout, background, typography,
  /// frame style, positions, sizes and tilts. Words, screenshots, images and
  /// extra text stay. Frames pair up by position; no frame is added.
  TemplateData withStyleOf(TemplateData source) {
    final srcDevices = source.effectiveDevices;
    final targetDevices = effectiveDevices;
    final styled = <CanvasDeviceItem>[
      for (int i = 0; i < targetDevices.length; i++)
        _styledLike(targetDevices[i], srcDevices[i < srcDevices.length ? i : srcDevices.length - 1]),
    ];

    return copyWith(
      layoutMode: source.layoutMode,
      frameStyle: source.frameStyle,
      titleFont: source.titleFont,
      subtitleFont: source.subtitleFont,
      titleSize: source.titleSize,
      subtitleSize: source.subtitleSize,
      titleWeight: source.titleWeight,
      subtitleWeight: source.subtitleWeight,
      textColor: source.textColor,
      subtitleColor: source.subtitleColor,
      titleAlignment: source.titleAlignment,
      subtitleAlignment: source.subtitleAlignment,
      selectedGradientIndex: source.selectedGradientIndex,
      customBackgroundColor: () => source.customBackgroundColor,
      customGradientColors: () => source.customGradientColors,
      customBackgroundImageBytes: () => source.customBackgroundImageBytes,
      deviceScale: source.deviceScale,
      deviceOffsetX: source.deviceOffsetX,
      deviceOffsetY: source.deviceOffsetY,
      deviceRotation: source.deviceRotation,
      hasShadow: source.hasShadow,
      textOffsetX: source.textOffsetX,
      textOffsetY: source.textOffsetY,
      subtitleOffsetX: source.subtitleOffsetX,
      subtitleOffsetY: source.subtitleOffsetY,
      devices: styled,
    );
  }

  static CanvasDeviceItem _styledLike(CanvasDeviceItem target, CanvasDeviceItem ref) => target.copyWith(
    frameStyle: ref.frameStyle,
    scale: ref.scale,
    offsetX: ref.offsetX,
    offsetY: ref.offsetY,
    rotation: ref.rotation,
    hasShadow: ref.hasShadow,
  );

  // --- Background ---

  TemplateData withGradientPreset(int index) =>
      copyWith(selectedGradientIndex: index, customBackgroundColor: () => null, customGradientColors: () => null);

  TemplateData withSolidBackground(Color color) =>
      copyWith(customBackgroundColor: () => color, customGradientColors: () => null);
}
