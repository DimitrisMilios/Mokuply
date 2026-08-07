import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/store_specs.dart';
import '../models/template_model.dart';

class CanvasMockupWidget extends StatelessWidget {
  final TemplateModel model;
  final Size canvasSize;
  final bool isExporting;

  const CanvasMockupWidget({
    super.key,
    required this.model,
    required this.canvasSize,
    this.isExporting = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine relative scale ratio compared to full export resolution (1320x2868)
    final double baseWidth = model.platform.targetWidth;
    final double scaleRatio = canvasSize.width / baseWidth;

    return Container(
      width: canvasSize.width,
      height: canvasSize.height,
      decoration: model.backgroundDecoration.copyWith(
        // Guarantee opaque solid background for export
        color: model.backgroundDecoration.color ?? Colors.black,
      ),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Layout modes
            _buildLayoutContent(context, scaleRatio),
          ],
        ),
      ),
    );
  }

  Widget _buildLayoutContent(BuildContext context, double scale) {
    switch (model.layoutMode) {
      case LayoutMode.titleTopDeviceBottom:
        return Column(
          children: [
            SizedBox(height: 80 * scale),
            _buildTextHeader(scale),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, (60 + model.deviceOffsetY) * scale),
                  child: Transform.rotate(
                    angle: model.deviceRotation * (pi / 180),
                    child: Transform.scale(
                      scale: model.deviceScale,
                      child: _buildDeviceFrame(scale),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );

      case LayoutMode.titleBottomDeviceTop:
        return Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, (-40 + model.deviceOffsetY) * scale),
                  child: Transform.rotate(
                    angle: model.deviceRotation * (pi / 180),
                    child: Transform.scale(
                      scale: model.deviceScale,
                      child: _buildDeviceFrame(scale),
                    ),
                  ),
                ),
              ),
            ),
            _buildTextHeader(scale),
            SizedBox(height: 80 * scale),
          ],
        );

      case LayoutMode.deviceCentered:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 60 * scale),
            _buildTextHeader(scale),
            const Spacer(),
            Transform.translate(
              offset: Offset(0, model.deviceOffsetY * scale),
              child: Transform.rotate(
                angle: model.deviceRotation * (pi / 180),
                child: Transform.scale(
                  scale: model.deviceScale,
                  child: _buildDeviceFrame(scale),
                ),
              ),
            ),
            const Spacer(),
          ],
        );

      case LayoutMode.fullBleedHero:
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              bottom: (-120 + model.deviceOffsetY) * scale,
              child: Transform.rotate(
                angle: model.deviceRotation * (pi / 180),
                child: Transform.scale(
                  scale: model.deviceScale * 1.15,
                  child: _buildDeviceFrame(scale),
                ),
              ),
            ),
            Positioned(
              top: 60 * scale,
              left: 40 * scale,
              right: 40 * scale,
              child: _buildTextHeader(scale),
            ),
          ],
        );
    }
  }

  Widget _buildTextHeader(double scale) {
    TextStyle getFontTextStyle(String fontName, double fontSize, Color color, FontWeight weight) {
      try {
        return GoogleFonts.getFont(
          fontName,
          fontSize: fontSize * scale,
          color: color,
          fontWeight: weight,
          height: 1.15,
        );
      } catch (_) {
        return TextStyle(
          fontSize: fontSize * scale,
          color: color,
          fontWeight: weight,
          fontFamily: fontName,
          height: 1.15,
        );
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 48 * scale),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (model.titleText.isNotEmpty)
            Text(
              model.titleText,
              textAlign: TextAlign.center,
              style: getFontTextStyle(
                model.titleFont,
                model.titleSize,
                model.textColor,
                FontWeight.bold,
              ),
            ),
          if (model.titleText.isNotEmpty && model.subtitleText.isNotEmpty)
            SizedBox(height: 16 * scale),
          if (model.subtitleText.isNotEmpty)
            Text(
              model.subtitleText,
              textAlign: TextAlign.center,
              style: getFontTextStyle(
                model.subtitleFont,
                model.subtitleSize,
                model.subtitleColor,
                FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDeviceFrame(double scale) {
    // Frame base width & height according to platform ratio
    final double deviceWidth = (model.platform.targetWidth * 0.72) * scale;
    final double deviceHeight = deviceWidth / (9 / 19.5); // phone screen aspect ratio

    Widget screenshotWidget;
    if (model.screenshotBytes != null) {
      screenshotWidget = Image.memory(
        model.screenshotBytes!,
        fit: BoxFit.cover,
        width: deviceWidth,
        height: deviceHeight,
      );
    } else {
      // Placeholder preview image when no file uploaded yet
      screenshotWidget = Container(
        width: deviceWidth,
        height: deviceHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 64 * scale,
              color: Colors.white54,
            ),
            SizedBox(height: 16 * scale),
            Text(
              "Upload App Screenshot",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 20 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              "Click upload in left sidebar",
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14 * scale,
              ),
            ),
          ],
        ),
      );
    }

    // Shadow decoration
    final List<BoxShadow> shadows = model.hasShadow
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 40 * scale,
              spreadRadius: 10 * scale,
              offset: Offset(0, 20 * scale),
            ),
          ]
        : [];

    switch (model.frameStyle) {
      case DeviceFrameStyle.iphone16ProMax:
        final double cornerRadius = 46 * scale;
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: shadows,
            border: Border.all(
              color: const Color(0xFF334155),
              width: 8 * scale,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - (6 * scale)),
            child: Stack(
              children: [
                Positioned.fill(child: screenshotWidget),
                // Dynamic Island notch
                Positioned(
                  top: 14 * scale,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 110 * scale,
                      height: 30 * scale,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case DeviceFrameStyle.samsungS26Ultra:
        final double cornerRadius = 24 * scale;
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: shadows,
            border: Border.all(
              color: const Color(0xFF475569),
              width: 7 * scale,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - (5 * scale)),
            child: Stack(
              children: [
                Positioned.fill(child: screenshotWidget),
                // Hole punch camera notch
                Positioned(
                  top: 12 * scale,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 16 * scale,
                      height: 16 * scale,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case DeviceFrameStyle.minimalOutline:
        final double cornerRadius = 32 * scale;
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(cornerRadius),
            boxShadow: shadows,
            border: Border.all(
              color: Colors.white30,
              width: 4 * scale,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius - (3 * scale)),
            child: screenshotWidget,
          ),
        );

      case DeviceFrameStyle.none:
        return Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: BoxDecoration(
            boxShadow: shadows,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16 * scale),
            child: screenshotWidget,
          ),
        );
    }
  }
}
