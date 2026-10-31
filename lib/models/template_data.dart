import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import 'canvas_device_item.dart';
import 'canvas_image_item.dart';
import 'canvas_text_item.dart';
import 'template_assets.dart';

/// Pure immutable data model for one mockup screen.
///
/// Everything is authored once in [DesignSpace] coordinates and rendered
/// identically for every store. [platform] only records which store is being
/// previewed; exports override it per target.
@immutable
class TemplateData {
  final TargetPlatformType platform;

  /// Optional user-given name shown on the screen tab above the canvas.
  final String name;
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

  /// Optional flat band over the lower part of the backdrop, drawn behind
  /// every element: from [backgroundBandTop] (fraction of the design height)
  /// down to the bottom edge. Null colour means no band.
  final Color? backgroundBandColor;
  final double backgroundBandTop;

  /// Defaults for the primary phone frame when [devices] is empty.
  final double deviceScale;
  final double deviceOffsetX;
  final double deviceOffsetY;
  final double deviceRotation;
  final bool hasShadow;

  final double textOffsetX; // Title X offset
  final double textOffsetY; // Title Y offset
  final double subtitleOffsetX;
  final double subtitleOffsetY;

  /// Multi-element collections per canvas screen.
  final List<CanvasDeviceItem> devices;
  final List<CanvasImageItem> customImageItems;
  final List<CanvasTextItem> customTextItems;

  const TemplateData({
    this.platform = TargetPlatformType.appStore,
    this.name = '',
    this.layoutMode = LayoutMode.titleTopDeviceBottom,
    this.frameStyle = DeviceFrameStyle.realistic,
    this.titleText = 'Build Stunning Apps',
    this.subtitleText = 'Design high-res store screenshots in seconds',
    this.titleFont = 'Outfit',
    this.subtitleFont = 'Inter',
    this.titleSize = 96.0,
    this.subtitleSize = 42.0,
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
    this.backgroundBandColor,
    this.backgroundBandTop = 0.7,
    this.deviceScale = 0.92,
    this.deviceOffsetX = 0.0,
    this.deviceOffsetY = 0.0,
    this.deviceRotation = 0.0,
    this.hasShadow = true,
    this.textOffsetX = 0.0,
    this.textOffsetY = 0.0,
    this.subtitleOffsetX = 0.0,
    this.subtitleOffsetY = 0.0,
    this.devices = const [],
    this.customImageItems = const [],
    this.customTextItems = const [],
  });

  /// Phone frames on this screen. When [devices] is empty a primary frame is
  /// synthesised from the top-level device defaults (used by built-in templates).
  List<CanvasDeviceItem> get effectiveDevices {
    if (devices.isNotEmpty) return devices;
    return [
      CanvasDeviceItem(
        id: 'dev_primary',
        frameStyle: frameStyle,
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
    String? name,
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
    Color? Function()? backgroundBandColor,
    double? backgroundBandTop,
    double? deviceScale,
    double? deviceOffsetX,
    double? deviceOffsetY,
    double? deviceRotation,
    bool? hasShadow,
    double? textOffsetX,
    double? textOffsetY,
    double? subtitleOffsetX,
    double? subtitleOffsetY,
    List<CanvasDeviceItem>? devices,
    List<CanvasImageItem>? customImageItems,
    List<CanvasTextItem>? customTextItems,
  }) {
    return TemplateData(
      platform: platform ?? this.platform,
      name: name ?? this.name,
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
      customBackgroundImageBytes:
          customBackgroundImageBytes != null ? customBackgroundImageBytes() : this.customBackgroundImageBytes,
      backgroundBandColor: backgroundBandColor != null ? backgroundBandColor() : this.backgroundBandColor,
      backgroundBandTop: backgroundBandTop ?? this.backgroundBandTop,
      deviceScale: deviceScale ?? this.deviceScale,
      deviceOffsetX: deviceOffsetX ?? this.deviceOffsetX,
      deviceOffsetY: deviceOffsetY ?? this.deviceOffsetY,
      deviceRotation: deviceRotation ?? this.deviceRotation,
      hasShadow: hasShadow ?? this.hasShadow,
      textOffsetX: textOffsetX ?? this.textOffsetX,
      textOffsetY: textOffsetY ?? this.textOffsetY,
      subtitleOffsetX: subtitleOffsetX ?? this.subtitleOffsetX,
      subtitleOffsetY: subtitleOffsetY ?? this.subtitleOffsetY,
      devices: devices ?? this.devices,
      customImageItems: customImageItems ?? this.customImageItems,
      customTextItems: customTextItems ?? this.customTextItems,
    );
  }

  /// Images (screenshots, background, image layers) are written only through
  /// [assets]; see [AssetWriter].
  Map<String, dynamic> toJson({AssetWriter? assets}) {
    return {
      'platform': platform.name,
      'name': name,
      'layoutMode': layoutMode.name,
      'frameStyle': frameStyle.name,
      'titleText': titleText,
      'subtitleText': subtitleText,
      'titleFont': titleFont,
      'subtitleFont': subtitleFont,
      'titleSize': titleSize,
      'subtitleSize': subtitleSize,
      'titleWeightIndex': FontWeight.values.indexOf(titleWeight),
      'subtitleWeightIndex': FontWeight.values.indexOf(subtitleWeight),
      'textColor': textColor.toARGB32(),
      'subtitleColor': subtitleColor.toARGB32(),
      'titleAlignment': titleAlignment.name,
      'subtitleAlignment': subtitleAlignment.name,
      'selectedGradientIndex': selectedGradientIndex,
      'customBackgroundColor': customBackgroundColor?.toARGB32(),
      'customGradientColors': customGradientColors?.map((c) => c.toARGB32()).toList(),
      if (assets != null && customBackgroundImageBytes != null)
        'customBackgroundImage': assets(customBackgroundImageBytes!),
      'backgroundBandColor': backgroundBandColor?.toARGB32(),
      'backgroundBandTop': backgroundBandTop,
      'deviceScale': deviceScale,
      'deviceOffsetX': deviceOffsetX,
      'deviceOffsetY': deviceOffsetY,
      'deviceRotation': deviceRotation,
      'hasShadow': hasShadow,
      'textOffsetX': textOffsetX,
      'textOffsetY': textOffsetY,
      'subtitleOffsetX': subtitleOffsetX,
      'subtitleOffsetY': subtitleOffsetY,
      'devices': devices.map((d) => d.toJson(assets: assets)).toList(),
      if (assets != null) 'customImageItems': customImageItems.map((i) => i.toJson(assets)).toList(),
      'customTextItems': customTextItems.map((t) => t.toJson()).toList(),
      DesignSpace.textUnitKey: DesignSpace.textUnitPixels,
    };
  }

  /// Legacy per-store keys (`appStoreTextOffsetX`, ...) from older drafts are
  /// ignored; the shared offsets were always written alongside them.
  factory TemplateData.fromJson(Map<String, dynamic> json, {AssetReader? assets}) {
    // Drafts saved before font sizes became export pixels carry no unit marker.
    final double fontScale =
        json[DesignSpace.textUnitKey] == DesignSpace.textUnitPixels ? 1.0 : DesignSpace.legacyTextScale;
    final titleWeightIdx = json['titleWeightIndex'] as int? ?? 6;
    final subWeightIdx = json['subtitleWeightIndex'] as int? ?? 4;

    return TemplateData(
      platform: TargetPlatformType.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => TargetPlatformType.appStore,
      ),
      name: json['name'] as String? ?? '',
      layoutMode: LayoutMode.values.firstWhere(
        (e) => e.name == json['layoutMode'],
        orElse: () => LayoutMode.titleTopDeviceBottom,
      ),
      frameStyle: DeviceFrameStyle.fromName(json['frameStyle'] as String?),
      titleText: json['titleText'] as String? ?? '',
      subtitleText: json['subtitleText'] as String? ?? '',
      titleFont: json['titleFont'] as String? ?? 'Outfit',
      subtitleFont: json['subtitleFont'] as String? ?? 'Inter',
      titleSize: ((json['titleSize'] as num?)?.toDouble() ?? 70.0) * fontScale,
      subtitleSize: ((json['subtitleSize'] as num?)?.toDouble() ?? 32.0) * fontScale,
      titleWeight: (titleWeightIdx >= 0 && titleWeightIdx < FontWeight.values.length)
          ? FontWeight.values[titleWeightIdx]
          : FontWeight.w700,
      subtitleWeight: (subWeightIdx >= 0 && subWeightIdx < FontWeight.values.length)
          ? FontWeight.values[subWeightIdx]
          : FontWeight.w500,
      textColor: Color(json['textColor'] as int? ?? 0xFFFFFFFF),
      subtitleColor: Color(json['subtitleColor'] as int? ?? 0xFFE2E8F0),
      titleAlignment: TextAlign.values.firstWhere(
        (e) => e.name == json['titleAlignment'],
        orElse: () => TextAlign.center,
      ),
      subtitleAlignment: TextAlign.values.firstWhere(
        (e) => e.name == json['subtitleAlignment'],
        orElse: () => TextAlign.center,
      ),
      selectedGradientIndex: json['selectedGradientIndex'] as int? ?? 0,
      customBackgroundColor:
          json['customBackgroundColor'] != null ? Color(json['customBackgroundColor'] as int) : null,
      customGradientColors: json['customGradientColors'] != null
          ? (json['customGradientColors'] as List).map((c) => Color(c as int)).toList()
          : null,
      customBackgroundImageBytes: readAsset(json['customBackgroundImage'], assets),
      backgroundBandColor: json['backgroundBandColor'] != null ? Color(json['backgroundBandColor'] as int) : null,
      backgroundBandTop: (json['backgroundBandTop'] as num?)?.toDouble() ?? 0.7,
      deviceScale: (json['deviceScale'] as num?)?.toDouble() ?? 0.92,
      deviceOffsetX: (json['deviceOffsetX'] as num?)?.toDouble() ?? 0.0,
      deviceOffsetY: (json['deviceOffsetY'] as num?)?.toDouble() ?? 0.0,
      deviceRotation: (json['deviceRotation'] as num?)?.toDouble() ?? 0.0,
      hasShadow: json['hasShadow'] as bool? ?? true,
      textOffsetX: (json['textOffsetX'] as num?)?.toDouble() ?? 0.0,
      textOffsetY: (json['textOffsetY'] as num?)?.toDouble() ?? 0.0,
      subtitleOffsetX: (json['subtitleOffsetX'] as num?)?.toDouble() ?? 0.0,
      subtitleOffsetY: (json['subtitleOffsetY'] as num?)?.toDouble() ?? 0.0,
      devices: (json['devices'] as List?)
              ?.map((d) => CanvasDeviceItem.fromJson(d as Map<String, dynamic>, assets: assets))
              .toList() ??
          const [],
      customImageItems: (json['customImageItems'] as List?)
              ?.map((i) => CanvasImageItem.fromJson(i as Map<String, dynamic>, assets))
              .nonNulls
              .toList() ??
          const [],
      customTextItems: (json['customTextItems'] as List?)
              ?.map((t) => CanvasTextItem.fromJson(t as Map<String, dynamic>, fontScale: fontScale))
              .toList() ??
          const [],
    );
  }
}
