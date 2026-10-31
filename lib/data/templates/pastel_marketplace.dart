import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../models/canvas_device_item.dart';
import '../../models/project_template.dart';
import '../../models/template_data.dart';
import 'left_headline.dart';

/// One pastel colour per screen, big left-aligned headlines and frameless
/// phones. Screen 1 opens with a large tilted phone that runs off its right
/// edge and continues on screen 2, so the first two screens read as one
/// panorama in the store.
ProjectTemplate pastelMarketplaceTemplate() {
  const mint = Color(0xFFD3F0EA);
  const lavender = Color(0xFFDAD7F6);
  const pink = Color(0xFFFDDEE7);
  const butter = Color(0xFFF1F0D1);
  const stone = Color(0xFFEEE6E5);
  const peach = Color(0xFFFCE5D2);

  return ProjectTemplate(
    id: 'pastel_marketplace',
    title: 'Pastel Marketplace',
    category: 'Shopping',
    description: 'Soft pastel screens with big left-aligned headlines and a tilted hero phone that flows into screen two.',
    previewGradient: const [mint, lavender, pink],
    platform: TargetPlatformType.appStore,
    initialScreenshots: [
      // 1. Four-line headline over a big tilted phone bleeding off the right edge.
      _PastelScreen.build(
        background: mint,
        title: 'Discover\nUnique\nHandmade\nFinds',
        widestLine: 744,
        titleTop: 95,
        devices: const [
          CanvasDeviceItem(
            id: 'dev_pastel_tilted',
            frameStyle: DeviceFrameStyle.none,
            scale: _PastelScreen.tiltedScale,
            offsetX: _PastelScreen.tiltedOffsetX,
            offsetY: _PastelScreen.tiltedOffsetY,
            rotation: _PastelScreen.tiltRotation,
          ),
        ],
      ),
      // 2. No headline: an upright phone, with the tilted phone from screen 1
      //    entering from the left edge on top of it.
      _PastelScreen.build(
        background: lavender,
        devices: const [
          CanvasDeviceItem(
            id: 'dev_pastel_upright',
            frameStyle: DeviceFrameStyle.none,
            scale: _PastelScreen.uprightScale,
            offsetY: _PastelScreen.uprightTopOffsetY,
          ),
          CanvasDeviceItem(
            id: 'dev_pastel_tilted',
            frameStyle: DeviceFrameStyle.none,
            scale: _PastelScreen.tiltedScale,
            offsetX: _PastelScreen.tiltedOffsetX - 1000,
            offsetY: _PastelScreen.tiltedOffsetY,
            rotation: _PastelScreen.tiltRotation,
          ),
        ],
      ),
      // 3–6. Two-line headline, upright phone cropped by the bottom edge.
      _PastelScreen.build(background: pink, title: 'Shop\nLocal Makers', widestLine: 903),
      _PastelScreen.build(background: butter, title: 'Easy\nTracking', widestLine: 596),
      _PastelScreen.build(background: stone, title: 'Secure\nCheckout', widestLine: 657),
      _PastelScreen.build(background: peach, title: 'Gifts for\nEveryone', widestLine: 629),
    ],
  );
}

/// Geometry for the pastel set, in design pixels unless noted. Headline
/// widths ([widestLine]) are measured for Inter SemiBold at [titleSize].
class _PastelScreen {
  _PastelScreen._();

  static const String titleFont = 'Inter';
  static const double titleSize = 144;
  static const Color titleColor = Color(0xFF161616);

  /// Left edge of every headline and the default top of a two-line headline.
  static const double titleLeft = 137;
  static const double defaultTitleTop = 162;

  /// Upright phone: about 80 % of the screen width, centred.
  static const double uprightScale = 1.12;

  /// Offset units: phone top at 684 px, cropped by the bottom edge.
  static const double uprightBleedOffsetY = 41;

  /// Offset units: phone top at 147 px, fully visible (screen 2).
  static const double uprightTopOffsetY = -333;

  /// The tilted hero phone, centred near screen 1's right edge (offset units).
  static const double tiltedScale = 1.5;
  static const double tiltedOffsetX = 558;
  static const double tiltedOffsetY = 431;
  static const double tiltRotation = -24;

  static TemplateData build({
    required Color background,
    String title = '',
    double widestLine = 0,
    double titleTop = defaultTitleTop,
    List<CanvasDeviceItem> devices = const [],
  }) {
    return TemplateData(
      titleText: title,
      subtitleText: '',
      titleFont: titleFont,
      titleSize: titleSize,
      titleWeight: FontWeight.w600,
      textColor: titleColor,
      titleAlignment: TextAlign.left,
      subtitleAlignment: TextAlign.left,
      textOffsetX: LeftHeadline.offsetX(left: titleLeft, widestLine: widestLine),
      textOffsetY: LeftHeadline.offsetY(top: titleTop, text: title, fontSize: titleSize),
      customBackgroundColor: background,
      layoutMode: LayoutMode.titleTopDeviceBottom,
      frameStyle: DeviceFrameStyle.none,
      deviceScale: uprightScale,
      deviceOffsetY: uprightBleedOffsetY,
      devices: devices,
    );
  }
}
