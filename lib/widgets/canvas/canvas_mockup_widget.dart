import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/store_specs.dart';
import '../../models/template_data.dart';
import 'text_header_widget.dart';
import 'device_frame_widget.dart';

class CanvasMockupWidget extends StatelessWidget {
  final TemplateData data;
  final Size canvasSize;
  final bool isExporting;

  const CanvasMockupWidget({
    super.key,
    required this.data,
    required this.canvasSize,
    this.isExporting = false,
  });

  BoxDecoration get _backgroundDecoration {
    if (data.customBackgroundColor != null) {
      return BoxDecoration(color: data.customBackgroundColor);
    }
    if (data.customGradientColors != null && data.customGradientColors!.isNotEmpty) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: data.customGradientColors!,
        ),
      );
    }
    // Fallback to preset
    final preset = StoreSpecs.gradientPresets[data.selectedGradientIndex % StoreSpecs.gradientPresets.length];
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: preset.colors,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine relative scale ratio compared to full export resolution (1320x2868)
    final double baseWidth = data.platform.targetWidth;
    final double scaleRatio = canvasSize.width / baseWidth;
    final decoration = _backgroundDecoration;

    return Container(
      width: canvasSize.width,
      height: canvasSize.height,
      decoration: decoration.copyWith(
        // Guarantee opaque solid background for export
        color: decoration.color ?? Colors.black,
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
    switch (data.layoutMode) {
      case LayoutMode.titleTopDeviceBottom:
        return Column(
          children: [
            SizedBox(height: 80 * scale),
            _buildTextHeader(scale),
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, (60 + data.deviceOffsetY) * scale),
                  child: Transform.rotate(
                    angle: data.deviceRotation * (pi / 180),
                    child: Transform.scale(
                      scale: data.deviceScale,
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
                  offset: Offset(0, (-40 + data.deviceOffsetY) * scale),
                  child: Transform.rotate(
                    angle: data.deviceRotation * (pi / 180),
                    child: Transform.scale(
                      scale: data.deviceScale,
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
              offset: Offset(0, data.deviceOffsetY * scale),
              child: Transform.rotate(
                angle: data.deviceRotation * (pi / 180),
                child: Transform.scale(
                  scale: data.deviceScale,
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
              bottom: (-120 + data.deviceOffsetY) * scale,
              child: Transform.rotate(
                angle: data.deviceRotation * (pi / 180),
                child: Transform.scale(
                  scale: data.deviceScale * 1.15,
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
    return TextHeaderWidget(
      titleText: data.titleText,
      subtitleText: data.subtitleText,
      titleFont: data.titleFont,
      subtitleFont: data.subtitleFont,
      titleSize: data.titleSize,
      subtitleSize: data.subtitleSize,
      textColor: data.textColor,
      subtitleColor: data.subtitleColor,
      scale: scale,
    );
  }

  Widget _buildDeviceFrame(double scale) {
    return DeviceFrameWidget(
      frameStyle: data.frameStyle,
      screenshotBytes: data.screenshotBytes,
      hasShadow: data.hasShadow,
      platform: data.platform,
      scale: scale,
    );
  }
}
