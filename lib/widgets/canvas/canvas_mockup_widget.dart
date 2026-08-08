import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/store_specs.dart';
import '../../models/template_data.dart';
import '../../viewmodels/editor_viewmodel.dart';
import 'text_header_widget.dart';
import 'device_frame_widget.dart';

/// Eager gesture recognizer that immediately claims the gesture arena on pointer down,
/// preventing outer scrollable widgets (like horizontal SingleChildScrollView) from cancelling drags.
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _EagerPanDetector extends StatelessWidget {
  final Widget child;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final VoidCallback? onPanCancel;

  const _EagerPanDetector({
    required this.child,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        _EagerPanGestureRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
          () => _EagerPanGestureRecognizer(),
          (_EagerPanGestureRecognizer instance) {
            instance.onStart = onPanStart;
            instance.onUpdate = onPanUpdate;
            instance.onEnd = onPanEnd;
            instance.onCancel = onPanCancel;
          },
        ),
      },
      child: child,
    );
  }
}

class CanvasMockupWidget extends StatefulWidget {
  final TemplateData data;
  final int itemIndex;
  final Size canvasSize;
  final bool isExporting;

  const CanvasMockupWidget({
    super.key,
    required this.data,
    this.itemIndex = 0,
    required this.canvasSize,
    this.isExporting = false,
  });

  @override
  State<CanvasMockupWidget> createState() => _CanvasMockupWidgetState();
}

class _CanvasMockupWidgetState extends State<CanvasMockupWidget> {
  bool _isHoveringText = false;
  bool _isHoveringDevice = false;
  bool _isDraggingText = false;
  bool _isDraggingDevice = false;

  // Local drag offsets to maintain 120 FPS smooth pointer tracking without Provider rebuild glitches
  double? _localTextX;
  double? _localTextY;
  double? _localDeviceX;
  double? _localDeviceY;

  BoxDecoration get _backgroundDecoration {
    if (widget.data.customBackgroundColor != null) {
      return BoxDecoration(color: widget.data.customBackgroundColor);
    }
    if (widget.data.customGradientColors != null && widget.data.customGradientColors!.isNotEmpty) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.data.customGradientColors!,
        ),
      );
    }
    final preset = StoreSpecs.gradientPresets[
      widget.data.selectedGradientIndex % StoreSpecs.gradientPresets.length
    ];
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
    final double baseWidth = widget.data.platform.targetWidth;
    final double scaleRatio = widget.canvasSize.width / baseWidth;
    final decoration = _backgroundDecoration;

    return Container(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      decoration: decoration.copyWith(
        color: decoration.color ?? Colors.black,
      ),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Custom Background Image Layer (if uploaded)
            if (widget.data.customBackgroundImageBytes != null)
              Positioned.fill(
                child: Image.memory(
                  widget.data.customBackgroundImageBytes!,
                  fit: BoxFit.cover,
                  width: widget.canvasSize.width,
                  height: widget.canvasSize.height,
                ),
              ),

            // 2. Pure 2D Freeform Stack Layout
            _buildFreeformCanvasLayout(context, scaleRatio),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeformCanvasLayout(BuildContext context, double scale) {
    final vm = widget.isExporting ? null : Provider.of<EditorViewModel>(context, listen: false);
    final data = widget.data;
    final double canvasHeight = widget.canvasSize.height;

    // Base initial Y top positions based on selected preset layout mode
    double baseTextTop = 0.0;
    double baseDeviceTop = 0.0;

    switch (data.layoutMode) {
      case LayoutMode.titleTopDeviceBottom:
        baseTextTop = canvasHeight * 0.08;
        baseDeviceTop = canvasHeight * 0.32;
        break;
      case LayoutMode.titleBottomDeviceTop:
        baseDeviceTop = canvasHeight * 0.06;
        baseTextTop = canvasHeight * 0.72;
        break;
      case LayoutMode.deviceCentered:
        baseTextTop = canvasHeight * 0.08;
        baseDeviceTop = canvasHeight * 0.24;
        break;
      case LayoutMode.fullBleedHero:
        baseTextTop = canvasHeight * 0.08;
        baseDeviceTop = canvasHeight * 0.38;
        break;
    }

    // Effective offsets: use active local drag position when dragging, else fallback to model data
    final double effectiveTextOffsetX = _localTextX ?? data.textOffsetX;
    final double effectiveTextOffsetY = _localTextY ?? data.textOffsetY;
    final double effectiveDeviceOffsetX = _localDeviceX ?? data.deviceOffsetX;
    final double effectiveDeviceOffsetY = _localDeviceY ?? data.deviceOffsetY;

    final double textX = effectiveTextOffsetX * scale;
    final double textY = baseTextTop + (effectiveTextOffsetY * scale);

    final double deviceX = effectiveDeviceOffsetX * scale;
    final double deviceY = baseDeviceTop + (effectiveDeviceOffsetY * scale);

    Widget textWidget = _buildTextHeader(scale);
    Widget deviceWidget = _buildDeviceFrame(scale);

    // If in interactive editor mode, wrap with _EagerPanDetector and selection handle styling
    if (!widget.isExporting && vm != null) {
      textWidget = MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _isHoveringText = true),
        onExit: (_) => setState(() => _isHoveringText = false),
        child: _EagerPanDetector(
          onPanStart: (_) {
            vm.selectScreenshot(widget.itemIndex);
            setState(() {
              _isDraggingText = true;
              _localTextX = data.textOffsetX;
              _localTextY = data.textOffsetY;
            });
          },
          onPanUpdate: (details) {
            final double dx = details.delta.dx / scale;
            final double dy = details.delta.dy / scale;
            setState(() {
              _localTextX = (_localTextX ?? data.textOffsetX) + dx;
              _localTextY = (_localTextY ?? data.textOffsetY) + dy;
            });
          },
          onPanEnd: (_) {
            if (_localTextX != null && _localTextY != null) {
              vm.setTextOffsetsForIndex(widget.itemIndex, _localTextX!, _localTextY!);
            }
            setState(() {
              _isDraggingText = false;
              _localTextX = null;
              _localTextY = null;
            });
          },
          onPanCancel: () {
            setState(() {
              _isDraggingText = false;
              _localTextX = null;
              _localTextY = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: (_isHoveringText || _isDraggingText)
                    ? AppColors.primary
                    : Colors.transparent,
                width: (_isHoveringText || _isDraggingText) ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(8),
              color: (_isHoveringText || _isDraggingText)
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
            ),
            child: textWidget,
          ),
        ),
      );

      deviceWidget = MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _isHoveringDevice = true),
        onExit: (_) => setState(() => _isHoveringDevice = false),
        child: _EagerPanDetector(
          onPanStart: (_) {
            vm.selectScreenshot(widget.itemIndex);
            setState(() {
              _isDraggingDevice = true;
              _localDeviceX = data.deviceOffsetX;
              _localDeviceY = data.deviceOffsetY;
            });
          },
          onPanUpdate: (details) {
            final double dx = details.delta.dx / scale;
            final double dy = details.delta.dy / scale;
            setState(() {
              _localDeviceX = (_localDeviceX ?? data.deviceOffsetX) + dx;
              _localDeviceY = (_localDeviceY ?? data.deviceOffsetY) + dy;
            });
          },
          onPanEnd: (_) {
            if (_localDeviceX != null && _localDeviceY != null) {
              vm.setDeviceOffsetsForIndex(widget.itemIndex, _localDeviceX!, _localDeviceY!);
            }
            setState(() {
              _isDraggingDevice = false;
              _localDeviceX = null;
              _localDeviceY = null;
            });
          },
          onPanCancel: () {
            setState(() {
              _isDraggingDevice = false;
              _localDeviceX = null;
              _localDeviceY = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(
                color: (_isHoveringDevice || _isDraggingDevice)
                    ? AppColors.primary
                    : Colors.transparent,
                width: (_isHoveringDevice || _isDraggingDevice) ? 2.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(32),
              color: (_isHoveringDevice || _isDraggingDevice)
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : Colors.transparent,
            ),
            child: deviceWidget,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. DEVICE FRAME LAYER (Positioned on 2D Canvas)
        Positioned(
          top: deviceY,
          left: 0,
          right: 0,
          child: Center(
            child: Transform.translate(
              offset: Offset(deviceX, 0),
              child: Transform.rotate(
                angle: data.deviceRotation * (pi / 180),
                child: Transform.scale(
                  scale: data.deviceScale * (data.layoutMode == LayoutMode.fullBleedHero ? 1.15 : 1.0),
                  child: deviceWidget,
                ),
              ),
            ),
          ),
        ),

        // 2. TEXT HEADER LAYER (Positioned on 2D Canvas)
        Positioned(
          top: textY,
          left: 20 * scale,
          right: 20 * scale,
          child: Center(
            child: Transform.translate(
              offset: Offset(textX, 0),
              child: textWidget,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextHeader(double scale) {
    return TextHeaderWidget(
      titleText: widget.data.titleText,
      subtitleText: widget.data.subtitleText,
      titleFont: widget.data.titleFont,
      subtitleFont: widget.data.subtitleFont,
      titleSize: widget.data.titleSize,
      subtitleSize: widget.data.subtitleSize,
      textColor: widget.data.textColor,
      subtitleColor: widget.data.subtitleColor,
      scale: scale,
    );
  }

  Widget _buildDeviceFrame(double scale) {
    return DeviceFrameWidget(
      frameStyle: widget.data.frameStyle,
      screenshotBytes: widget.data.effectiveScreenshotBytes,
      hasShadow: widget.data.hasShadow,
      platform: widget.data.platform,
      scale: scale,
    );
  }
}



