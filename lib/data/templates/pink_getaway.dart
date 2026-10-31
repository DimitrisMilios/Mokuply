import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../models/canvas_device_item.dart';
import '../../models/canvas_text_item.dart';
import '../../models/project_template.dart';
import '../../models/template_data.dart';
import 'left_headline.dart';

/// Bold pink screens with white rounded headlines and a small white dot in the
/// corner. Screen 1 shows the left half of a large tilted phone whose right
/// half fills screen 2, so the pair reads as one panorama in the store.
ProjectTemplate pinkGetawayTemplate() {
  return ProjectTemplate(
    id: 'pink_getaway',
    title: 'Pink Getaway',
    category: 'Travel',
    description: 'Bold pink screens with white rounded headlines and a tilted phone that flows into screen two.',
    previewGradient: const [Color(0xFFEC3B74), _PinkScreen.background, Color(0xFFC8124F)],
    previewImage: 'assets/template_previews/pink_getaway.webp',
    platform: TargetPlatformType.appStore,
    initialScreenshots: [
      // 1. Big three-line headline; the tilted phone enters from the right edge.
      _PinkScreen.build(
        title: 'Search,\nBook,\nEnjoy.',
        widestLine: 823,
        titleSize: 220,
        titleTop: 216,
        devices: const [
          CanvasDeviceItem(
            id: 'dev_pink_tilted',
            scale: _PinkScreen.tiltedScale,
            offsetX: _PinkScreen.tiltedOffsetX,
            offsetY: _PinkScreen.tiltedOffsetY,
            rotation: _PinkScreen.tiltRotation,
          ),
        ],
      ),
      // 2. No headline or dot: the rest of the tilted phone.
      _PinkScreen.build(
        dot: false,
        devices: const [
          CanvasDeviceItem(
            id: 'dev_pink_tilted',
            scale: _PinkScreen.tiltedScale,
            offsetX: _PinkScreen.tiltedOffsetX - 1000,
            offsetY: _PinkScreen.tiltedOffsetY,
            rotation: _PinkScreen.tiltRotation,
          ),
        ],
      ),
      // 3–6. Two-line headline over an upright phone cropped by the bottom edge.
      _PinkScreen.build(title: 'Find the\nbest deals', widestLine: 852),
      _PinkScreen.build(title: 'Explore\nevery place', widestLine: 964),
      _PinkScreen.build(title: 'Book in\nseconds', widestLine: 694),
      _PinkScreen.build(title: 'Travel\nwith ease', widestLine: 804),
    ],
  );
}

/// Geometry for the pink set, in design pixels unless noted. Headline widths
/// ([widestLine]) are measured for Poppins Medium at the given size.
class _PinkScreen {
  _PinkScreen._();

  static const Color background = Color(0xFFE11D5E);
  static const String titleFont = 'Poppins';
  static const double titleLeft = 137;

  /// Two-line headline size and top edge (screens 3–6).
  static const double defaultTitleSize = 170;
  static const double defaultTitleTop = 258;

  /// Upright realistic phone, centred, top at 900 px (offset units below).
  static const double uprightScale = 1.09;
  static const double uprightOffsetY = 170;

  /// The tilted hero phone, centred just inside screen 2 (offset units).
  static const double tiltedScale = 1.22;
  static const double tiltedOffsetX = 731;
  static const double tiltedOffsetY = -244;
  static const double tiltRotation = 15;

  /// White dot in the top-left corner, centred at (171, 166) px. The bullet
  /// glyph sits about 0.065 em above its line box centre, hence the lower Y.
  static const CanvasTextItem _dot = CanvasTextItem(
    id: 'txt_pink_dot',
    text: '•',
    font: titleFont,
    fontSize: 400,
    weight: FontWeight.w500,
    offsetX: -370,
    offsetY: -866,
  );

  static TemplateData build({
    String title = '',
    double widestLine = 0,
    double titleSize = defaultTitleSize,
    double titleTop = defaultTitleTop,
    bool dot = true,
    List<CanvasDeviceItem> devices = const [],
  }) {
    return TemplateData(
      titleText: title,
      subtitleText: '',
      titleFont: titleFont,
      titleSize: titleSize,
      titleWeight: FontWeight.w500,
      textColor: Colors.white,
      titleAlignment: TextAlign.left,
      subtitleAlignment: TextAlign.left,
      textOffsetX: LeftHeadline.offsetX(left: titleLeft, widestLine: widestLine),
      textOffsetY: LeftHeadline.offsetY(top: titleTop, text: title, fontSize: titleSize),
      customBackgroundColor: background,
      layoutMode: LayoutMode.titleTopDeviceBottom,
      deviceScale: uprightScale,
      deviceOffsetY: uprightOffsetY,
      devices: devices,
      customTextItems: dot ? const [_dot] : const [],
    );
  }
}
