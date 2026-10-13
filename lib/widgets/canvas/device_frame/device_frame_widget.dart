import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../core/constants/store_specs.dart';
import 'phone_skin.dart';
import 'realistic_phone_frame.dart';
import 'screenshot_placeholder.dart';
import 'simple_frames.dart';

/// Draws a phone frame around a screenshot.
///
/// All geometry is expressed in design pixels and multiplied by [scale]
/// (design → canvas). Every style, and both realistic chassis, share exactly
/// the same outer footprint and screen inset, so switching store or style never
/// moves or resizes the element on the canvas.
class DeviceFrameWidget extends StatelessWidget {
  final DeviceFrameStyle frameStyle;
  final Uint8List? screenshotBytes;
  final bool hasShadow;
  final TargetPlatformType platform;
  final double scale;

  /// Pixel width to decode the screenshot at. Previews pass a size close to
  /// what is drawn so large screenshots don't cost full-resolution memory;
  /// exports leave it null to decode at native resolution.
  final int? decodeWidth;

  /// True on the editor canvas: the "no screenshot yet" placeholder uses the
  /// clay empty-state. False (the default, and what the export capture
  /// passes) keeps the placeholder's exported pixels exactly as before.
  final bool previewPlaceholder;

  const DeviceFrameWidget({
    super.key,
    required this.frameStyle,
    this.screenshotBytes,
    required this.hasShadow,
    required this.platform,
    required this.scale,
    this.decodeWidth,
    this.previewPlaceholder = false,
  });

  /// Phone body width in design pixels (before [scale]).
  static const double bodyDesignWidth = DesignSpace.width * DesignSpace.deviceWidthFraction;

  /// Screen aspect ratio shared by both realistic chassis.
  static const double screenAspect = 9 / 19.5;

  /// Side-button gutter reserved on both sides so the body is always centred.
  static const double buttonGutterDesign = 10.0;

  static double bodyWidthFor(double scale) => bodyDesignWidth * scale;
  static double bodyHeightFor(double scale) => bodyWidthFor(scale) / screenAspect;
  static double outerWidthFor(double scale) => bodyWidthFor(scale) + (buttonGutterDesign * 2 * scale);

  @override
  Widget build(BuildContext context) {
    final double deviceWidth = bodyWidthFor(scale);
    final double deviceHeight = bodyHeightFor(scale);

    final Widget screenshotWidget = screenshotBytes != null
        ? Image.memory(
            screenshotBytes!,
            fit: BoxFit.cover,
            width: deviceWidth,
            height: deviceHeight,
            cacheWidth: decodeWidth,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          )
        : ScreenshotPlaceholder(
            width: deviceWidth,
            height: deviceHeight,
            scale: scale,
            platform: platform,
            preview: previewPlaceholder,
          );

    final Widget body;
    switch (frameStyle) {
      case DeviceFrameStyle.realistic:
        body = RealisticPhoneFrame(
          skin: platform == TargetPlatformType.appStore ? PhoneSkin.iphone16ProMax : PhoneSkin.galaxyS26Ultra,
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );
        break;
      case DeviceFrameStyle.minimalOutline:
        body = MinimalDarkFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );
        break;
      case DeviceFrameStyle.none:
        body = RawScreenshotFrame(
          deviceWidth: deviceWidth,
          deviceHeight: deviceHeight,
          scale: scale,
          hasShadow: hasShadow,
          screenshotWidget: screenshotWidget,
        );
        break;
    }

    // Identical outer box for every style: body centred inside the button gutters.
    return SizedBox(
      width: outerWidthFor(scale),
      height: deviceHeight,
      child: Center(child: body),
    );
  }
}
