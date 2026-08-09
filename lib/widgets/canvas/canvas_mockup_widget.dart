import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/store_specs.dart';
import '../../models/template_data.dart';
import '../../viewmodels/editor_viewmodel.dart';
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
  bool _isHoveringTitle = false;
  bool _isHoveringSubtitle = false;
  bool _isHoveringDevice = false;
  String? _hoveringCustomTextId;

  bool _isDraggingTitle = false;
  bool _isDraggingSubtitle = false;
  bool _isDraggingDevice = false;
  String? _draggingCustomTextId;

  // Local drag offsets for Title, Subtitle, Device Frame, and Custom Text items
  double? _localTitleX;
  double? _localTitleY;
  double? _localSubtitleX;
  double? _localSubtitleY;
  double? _localDeviceX;
  double? _localDeviceY;
  final Map<String, Offset> _localCustomTextOffsets = {};

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

  TextStyle _getFontTextStyle({
    required String fontName,
    required double fontSize,
    required Color color,
    required FontWeight weight,
    required double scale,
  }) {
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

  @override
  Widget build(BuildContext context) {
    final double baseWidth = widget.data.platform.targetWidth;
    final double frameScale = widget.canvasSize.width / baseWidth;
    // Normalized reference scale for text font sizes and drag offsets so iPhone and Android match visually
    const double referenceCanvasWidth = 1000.0;
    final double textScale = widget.canvasSize.width / referenceCanvasWidth;
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
            _buildFreeformCanvasLayout(context, textScale: textScale, frameScale: frameScale),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeformCanvasLayout(BuildContext context, {required double textScale, required double frameScale}) {
    final vm = widget.isExporting ? null : Provider.of<EditorViewModel>(context, listen: false);
    final data = widget.data;
    final double canvasHeight = widget.canvasSize.height;

    // Base initial Y top positions based on selected preset layout mode
    double baseTitleTop = 0.0;
    double baseSubtitleTop = 0.0;
    double baseDeviceTop = 0.0;

    switch (data.layoutMode) {
      case LayoutMode.titleTopDeviceBottom:
        baseTitleTop = canvasHeight * 0.06;
        baseSubtitleTop = canvasHeight * 0.16;
        baseDeviceTop = canvasHeight * 0.32;
        break;
      case LayoutMode.titleBottomDeviceTop:
        baseDeviceTop = canvasHeight * 0.06;
        baseTitleTop = canvasHeight * 0.72;
        baseSubtitleTop = canvasHeight * 0.82;
        break;
      case LayoutMode.deviceCentered:
        baseTitleTop = canvasHeight * 0.06;
        baseSubtitleTop = canvasHeight * 0.15;
        baseDeviceTop = canvasHeight * 0.24;
        break;
      case LayoutMode.fullBleedHero:
        baseTitleTop = canvasHeight * 0.06;
        baseSubtitleTop = canvasHeight * 0.16;
        baseDeviceTop = canvasHeight * 0.38;
        break;
    }

    // Effective positions for Title, Subtitle, Device Frame
    final double effectiveTitleX = _localTitleX ?? data.textOffsetX;
    final double effectiveTitleY = _localTitleY ?? data.textOffsetY;

    final double effectiveSubtitleX = _localSubtitleX ?? data.subtitleOffsetX;
    final double effectiveSubtitleY = _localSubtitleY ?? data.subtitleOffsetY;

    final double effectiveDeviceX = _localDeviceX ?? data.deviceOffsetX;
    final double effectiveDeviceY = _localDeviceY ?? data.deviceOffsetY;

    final double titleX = effectiveTitleX * textScale;
    final double titleY = baseTitleTop + (effectiveTitleY * textScale);

    final double subtitleX = effectiveSubtitleX * textScale;
    final double subtitleY = baseSubtitleTop + (effectiveSubtitleY * textScale);

    final double deviceX = effectiveDeviceX * textScale;
    final double deviceY = baseDeviceTop + (effectiveDeviceY * textScale);

    // --- 1. TITLE ELEMENT WIDGET ---
    Widget titleWidget = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * textScale),
      child: Text(
        data.titleText,
        textAlign: data.titleAlignment,
        style: _getFontTextStyle(
          fontName: data.titleFont,
          fontSize: data.titleSize,
          color: data.textColor,
          weight: data.titleWeight,
          scale: textScale,
        ),
      ),
    );

    // --- 2. SUBTITLE ELEMENT WIDGET ---
    Widget subtitleWidget = Padding(
      padding: EdgeInsets.symmetric(horizontal: 24 * textScale),
      child: Text(
        data.subtitleText,
        textAlign: data.subtitleAlignment,
        style: _getFontTextStyle(
          fontName: data.subtitleFont,
          fontSize: data.subtitleSize,
          color: data.subtitleColor,
          weight: data.subtitleWeight,
          scale: textScale,
        ),
      ),
    );

    // --- 3. DEVICE FRAME WIDGET ---
    Widget deviceWidget = _buildDeviceFrame(frameScale);

    // Wrap elements in drag gesture detectors if not exporting
    if (!widget.isExporting && vm != null) {
      // Title Draggable Wrapper
      titleWidget = MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _isHoveringTitle = true),
        onExit: (_) => setState(() => _isHoveringTitle = false),
        child: _EagerPanDetector(
          onPanStart: (_) {
            vm.selectScreenshot(widget.itemIndex);
            setState(() {
              _isDraggingTitle = true;
              _localTitleX = data.textOffsetX;
              _localTitleY = data.textOffsetY;
            });
          },
          onPanUpdate: (details) {
            final double dx = details.delta.dx / textScale;
            final double dy = details.delta.dy / textScale;
            setState(() {
              _localTitleX = (_localTitleX ?? data.textOffsetX) + dx;
              _localTitleY = (_localTitleY ?? data.textOffsetY) + dy;
            });
          },
          onPanEnd: (_) {
            if (_localTitleX != null && _localTitleY != null) {
              vm.setTextOffsetsForIndex(widget.itemIndex, _localTitleX!, _localTitleY!);
            }
            setState(() {
              _isDraggingTitle = false;
              _localTitleX = null;
              _localTitleY = null;
            });
          },
          onPanCancel: () {
            setState(() {
              _isDraggingTitle = false;
              _localTitleX = null;
              _localTitleY = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: (_isHoveringTitle || _isDraggingTitle) ? AppColors.primary : Colors.transparent,
                width: (_isHoveringTitle || _isDraggingTitle) ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(6),
              color: (_isHoveringTitle || _isDraggingTitle) ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: titleWidget,
          ),
        ),
      );

      // Subtitle Draggable Wrapper
      subtitleWidget = MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _isHoveringSubtitle = true),
        onExit: (_) => setState(() => _isHoveringSubtitle = false),
        child: _EagerPanDetector(
          onPanStart: (_) {
            vm.selectScreenshot(widget.itemIndex);
            setState(() {
              _isDraggingSubtitle = true;
              _localSubtitleX = data.subtitleOffsetX;
              _localSubtitleY = data.subtitleOffsetY;
            });
          },
          onPanUpdate: (details) {
            final double dx = details.delta.dx / textScale;
            final double dy = details.delta.dy / textScale;
            setState(() {
              _localSubtitleX = (_localSubtitleX ?? data.subtitleOffsetX) + dx;
              _localSubtitleY = (_localSubtitleY ?? data.subtitleOffsetY) + dy;
            });
          },
          onPanEnd: (_) {
            if (_localSubtitleX != null && _localSubtitleY != null) {
              vm.setSubtitleOffsetsForIndex(widget.itemIndex, _localSubtitleX!, _localSubtitleY!);
            }
            setState(() {
              _isDraggingSubtitle = false;
              _localSubtitleX = null;
              _localSubtitleY = null;
            });
          },
          onPanCancel: () {
            setState(() {
              _isDraggingSubtitle = false;
              _localSubtitleX = null;
              _localSubtitleY = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(
                color: (_isHoveringSubtitle || _isDraggingSubtitle) ? AppColors.primary : Colors.transparent,
                width: (_isHoveringSubtitle || _isDraggingSubtitle) ? 2.0 : 1.0,
              ),
              borderRadius: BorderRadius.circular(6),
              color: (_isHoveringSubtitle || _isDraggingSubtitle) ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: subtitleWidget,
          ),
        ),
      );

      // Device Frame Draggable Wrapper
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
            final double dx = details.delta.dx / textScale;
            final double dy = details.delta.dy / textScale;
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
                color: (_isHoveringDevice || _isDraggingDevice) ? AppColors.primary : Colors.transparent,
                width: (_isHoveringDevice || _isDraggingDevice) ? 2.5 : 1.0,
              ),
              borderRadius: BorderRadius.circular(32),
              color: (_isHoveringDevice || _isDraggingDevice) ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
            ),
            child: deviceWidget,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1. DEVICE FRAME LAYER
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

        // 2. SUBTITLE LAYER
        if (data.subtitleText.isNotEmpty)
          Positioned(
            top: subtitleY,
            left: 20 * textScale,
            right: 20 * textScale,
            child: Center(
              child: Transform.translate(
                offset: Offset(subtitleX, 0),
                child: subtitleWidget,
              ),
            ),
          ),

        // 3. TITLE LAYER
        if (data.titleText.isNotEmpty)
          Positioned(
            top: titleY,
            left: 20 * textScale,
            right: 20 * textScale,
            child: Center(
              child: Transform.translate(
                offset: Offset(titleX, 0),
                child: titleWidget,
              ),
            ),
          ),

        // 4. EXTRA CUSTOM TEXT ELEMENTS LAYER
        ...data.customTextItems.map((item) {
          final Offset localOffset = _localCustomTextOffsets[item.id] ?? Offset(item.offsetX, item.offsetY);
          final double customX = localOffset.dx * textScale;
          final double customY = (canvasHeight * 0.5) + (localOffset.dy * textScale);

          Widget itemWidget = Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * textScale),
            child: Text(
              item.text,
              textAlign: item.alignment,
              style: _getFontTextStyle(
                fontName: item.font,
                fontSize: item.fontSize,
                color: item.color,
                weight: item.weight,
                scale: textScale,
              ),
            ),
          );

          if (!widget.isExporting && vm != null) {
            final isHovering = _hoveringCustomTextId == item.id;
            final isDragging = _draggingCustomTextId == item.id;

            itemWidget = MouseRegion(
              cursor: SystemMouseCursors.move,
              onEnter: (_) => setState(() => _hoveringCustomTextId = item.id),
              onExit: (_) => setState(() => _hoveringCustomTextId = null),
              child: _EagerPanDetector(
                onPanStart: (_) {
                  vm.selectScreenshot(widget.itemIndex);
                  setState(() {
                    _draggingCustomTextId = item.id;
                    _localCustomTextOffsets[item.id] = Offset(item.offsetX, item.offsetY);
                  });
                },
                onPanUpdate: (details) {
                  final double dx = details.delta.dx / textScale;
                  final double dy = details.delta.dy / textScale;
                  final current = _localCustomTextOffsets[item.id] ?? Offset(item.offsetX, item.offsetY);
                  setState(() {
                    _localCustomTextOffsets[item.id] = Offset(current.dx + dx, current.dy + dy);
                  });
                },
                onPanEnd: (_) {
                  final finalOffset = _localCustomTextOffsets[item.id];
                  if (finalOffset != null) {
                    vm.setCustomTextElementOffsetsForIndex(widget.itemIndex, item.id, finalOffset.dx, finalOffset.dy);
                  }
                  setState(() {
                    _draggingCustomTextId = null;
                    _localCustomTextOffsets.remove(item.id);
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _draggingCustomTextId = null;
                    _localCustomTextOffsets.remove(item.id);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: (isHovering || isDragging) ? AppColors.primary : Colors.transparent,
                      width: (isHovering || isDragging) ? 2.0 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    color: (isHovering || isDragging) ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                  ),
                  child: itemWidget,
                ),
              ),
            );
          }

          return Positioned(
            top: customY,
            left: 20 * textScale,
            right: 20 * textScale,
            child: Center(
              child: Transform.translate(
                offset: Offset(customX, 0),
                child: itemWidget,
              ),
            ),
          );
        }),
      ],
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




