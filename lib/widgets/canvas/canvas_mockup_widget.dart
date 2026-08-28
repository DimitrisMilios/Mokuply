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
  String? _hoveringDeviceId;
  String? _hoveringImageId;
  String? _hoveringCustomTextId;

  bool _isDraggingTitle = false;
  bool _isDraggingSubtitle = false;
  String? _draggingDeviceId;
  String? _draggingImageId;
  String? _draggingCustomTextId;

  // Local drag offsets for Title, Subtitle, Device Frames, Custom Images, and Custom Text items
  double? _localTitleX;
  double? _localTitleY;
  double? _localSubtitleX;
  double? _localSubtitleY;
  final Map<String, Offset> _localDeviceOffsets = {};
  final Map<String, Offset> _localImageOffsets = {};
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
        decoration: TextDecoration.none,
      );
    } catch (_) {
      return TextStyle(
        fontSize: fontSize * scale,
        color: color,
        fontWeight: weight,
        fontFamily: fontName,
        height: 1.15,
        decoration: TextDecoration.none,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double baseWidth = widget.data.platform.targetWidth;
    final double frameScale = widget.canvasSize.width / baseWidth;
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
    final double canvasWidth = widget.canvasSize.width;
    final double canvasHeight = widget.canvasSize.height;

    // Platform aspect ratio normalization factors
    final double platformScaleCorrection = data.platform.scaleCorrectionFactor;

    // Base initial Y center positions based on selected preset layout mode
    double baseTitleCenterY = canvasHeight * 0.08;
    double baseSubtitleCenterY = canvasHeight * 0.17;
    double baseDeviceCenterY = canvasHeight * 0.62;

    switch (data.layoutMode) {
      case LayoutMode.angledLeftHero:
      case LayoutMode.angledRightHero:
      case LayoutMode.titleTopDeviceBottom:
        baseTitleCenterY = canvasHeight * 0.08;
        baseSubtitleCenterY = canvasHeight * 0.17;
        baseDeviceCenterY = canvasHeight * 0.62;
        break;
      case LayoutMode.titleBottomDeviceTop:
        baseDeviceCenterY = canvasHeight * 0.36;
        baseTitleCenterY = canvasHeight * 0.74;
        baseSubtitleCenterY = canvasHeight * 0.84;
        break;
      case LayoutMode.deviceCentered:
        baseTitleCenterY = canvasHeight * 0.08;
        baseSubtitleCenterY = canvasHeight * 0.16;
        baseDeviceCenterY = canvasHeight * 0.54;
        break;
      case LayoutMode.fullBleedHero:
        baseTitleCenterY = canvasHeight * 0.08;
        baseSubtitleCenterY = canvasHeight * 0.17;
        baseDeviceCenterY = canvasHeight * 0.64;
        break;
    }

    // Effective positions for Title & Subtitle (per-platform)
    final double titleOffsetX = data.textOffsetXFor(data.platform);
    final double titleOffsetY = data.textOffsetYFor(data.platform);
    final double subtitleOffsetX = data.subtitleOffsetXFor(data.platform);
    final double subtitleOffsetY = data.subtitleOffsetYFor(data.platform);

    final double effectiveTitleX = _localTitleX ?? titleOffsetX;
    final double effectiveTitleY = _localTitleY ?? titleOffsetY;

    final double effectiveSubtitleX = _localSubtitleX ?? subtitleOffsetX;
    final double effectiveSubtitleY = _localSubtitleY ?? subtitleOffsetY;

    final double titleCenterX = (canvasWidth / 2) + (canvasWidth * (effectiveTitleX / 1000.0));
    final double titleCenterY = baseTitleCenterY + (canvasHeight * (effectiveTitleY / 2000.0));

    final double subtitleCenterX = (canvasWidth / 2) + (canvasWidth * (effectiveSubtitleX / 1000.0));
    final double subtitleCenterY = baseSubtitleCenterY + (canvasHeight * (effectiveSubtitleY / 2000.0));

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

    // Interactive Wrappers for Title and Subtitle
    if (!widget.isExporting && vm != null) {
      final isTitleSelected = vm.selectedElementId == 'title';
      titleWidget = MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _isHoveringTitle = true),
        onExit: (_) => setState(() => _isHoveringTitle = false),
        child: _EagerPanDetector(
          onPanStart: (_) {
            vm.selectScreenshot(widget.itemIndex);
            vm.selectElement('title');
            setState(() {
              _isDraggingTitle = true;
              _localTitleX = titleOffsetX;
              _localTitleY = titleOffsetY;
            });
          },
          onPanUpdate: (details) {
            final double dx = (details.delta.dx / canvasWidth) * 1000.0;
            final double dy = (details.delta.dy / canvasHeight) * 2000.0;
            setState(() {
              _localTitleX = (_localTitleX ?? titleOffsetX) + dx;
              _localTitleY = (_localTitleY ?? titleOffsetY) + dy;
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
                color: (isTitleSelected || _isHoveringTitle || _isDraggingTitle) ? AppColors.primary : Colors.transparent,
                width: (isTitleSelected || _isHoveringTitle || _isDraggingTitle) ? 2.0 : 0.0,
              ),
              borderRadius: BorderRadius.circular(6),
              color: (isTitleSelected || _isHoveringTitle || _isDraggingTitle) ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: titleWidget,
          ),
        ),
      );

      final isSubtitleSelected = vm.selectedElementId == 'subtitle';
      subtitleWidget = MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) => setState(() => _isHoveringSubtitle = true),
        onExit: (_) => setState(() => _isHoveringSubtitle = false),
        child: _EagerPanDetector(
          onPanStart: (_) {
            vm.selectScreenshot(widget.itemIndex);
            vm.selectElement('subtitle');
            setState(() {
              _isDraggingSubtitle = true;
              _localSubtitleX = subtitleOffsetX;
              _localSubtitleY = subtitleOffsetY;
            });
          },
          onPanUpdate: (details) {
            final double dx = (details.delta.dx / canvasWidth) * 1000.0;
            final double dy = (details.delta.dy / canvasHeight) * 2000.0;
            setState(() {
              _localSubtitleX = (_localSubtitleX ?? subtitleOffsetX) + dx;
              _localSubtitleY = (_localSubtitleY ?? subtitleOffsetY) + dy;
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
                color: (isSubtitleSelected || _isHoveringSubtitle || _isDraggingSubtitle) ? AppColors.primary : Colors.transparent,
                width: (isSubtitleSelected || _isHoveringSubtitle || _isDraggingSubtitle) ? 2.0 : 0.0,
              ),
              borderRadius: BorderRadius.circular(6),
              color: (isSubtitleSelected || _isHoveringSubtitle || _isDraggingSubtitle) ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
            ),
            child: subtitleWidget,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // --- 1. MULTI-DEVICE FRAMES LAYER ---
        ...data.effectiveDevices.map((device) {
          final double devOffsetX = device.offsetXFor(data.platform);
          final double devOffsetY = device.offsetYFor(data.platform);
          final double devScale = device.scaleFor(data.platform);

          final Offset localOffset = _localDeviceOffsets[device.id] ?? Offset(devOffsetX, devOffsetY);
          final double devCenterX = (canvasWidth / 2) + (canvasWidth * (localOffset.dx / 1000.0));
          final double devCenterY = baseDeviceCenterY + (canvasHeight * (localOffset.dy / 2000.0));

          Widget deviceFrameWidget = DeviceFrameWidget(
            frameStyle: device.frameStyle,
            screenshotBytes: device.screenshotBytes,
            hasShadow: device.hasShadow,
            platform: data.platform,
            scale: frameScale,
          );

          if (!widget.isExporting && vm != null) {
            final isSelected = vm.selectedElementId == device.id || vm.selectedDeviceId == device.id;
            final isHovering = _hoveringDeviceId == device.id;
            final isDragging = _draggingDeviceId == device.id;

            deviceFrameWidget = Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: (isSelected || isHovering || isDragging) ? AppColors.primary : Colors.transparent,
                  width: (isSelected || isHovering || isDragging) ? 2.5 : 0.0,
                ),
                borderRadius: BorderRadius.circular(32),
                color: (isSelected || isHovering || isDragging) ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
              ),
              child: deviceFrameWidget,
            );

            deviceFrameWidget = MouseRegion(
              cursor: SystemMouseCursors.move,
              onEnter: (_) => setState(() => _hoveringDeviceId = device.id),
              onExit: (_) => setState(() => _hoveringDeviceId = null),
              child: _EagerPanDetector(
                onPanStart: (_) {
                  vm.selectScreenshot(widget.itemIndex);
                  vm.selectDevice(device.id);
                  setState(() {
                    _draggingDeviceId = device.id;
                    _localDeviceOffsets[device.id] = Offset(devOffsetX, devOffsetY);
                  });
                },
                onPanUpdate: (details) {
                  final double dx = (details.delta.dx / canvasWidth) * 1000.0;
                  final double dy = (details.delta.dy / canvasHeight) * 2000.0;
                  final current = _localDeviceOffsets[device.id] ?? Offset(devOffsetX, devOffsetY);
                  setState(() {
                    _localDeviceOffsets[device.id] = Offset(current.dx + dx, current.dy + dy);
                  });
                },
                onPanEnd: (_) {
                  final finalOffset = _localDeviceOffsets[device.id];
                  if (finalOffset != null) {
                    vm.setDeviceFrameOffsetsForIndex(widget.itemIndex, device.id, finalOffset.dx, finalOffset.dy);
                  }
                  setState(() {
                    _draggingDeviceId = null;
                    _localDeviceOffsets.remove(device.id);
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _draggingDeviceId = null;
                    _localDeviceOffsets.remove(device.id);
                  });
                },
                child: deviceFrameWidget,
              ),
            );
          }

          return Positioned(
            left: devCenterX,
            top: devCenterY,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Transform.rotate(
                angle: device.rotation * (pi / 180),
                child: Transform.scale(
                  scale: devScale * platformScaleCorrection * (data.layoutMode == LayoutMode.fullBleedHero ? 1.15 : 1.0),
                  child: deviceFrameWidget,
                ),
              ),
            ),
          );
        }),

        // --- 2. STANDALONE CUSTOM IMAGES LAYER ---
        ...data.customImageItems.map((imgItem) {
          final double imgOffsetX = imgItem.offsetXFor(data.platform);
          final double imgOffsetY = imgItem.offsetYFor(data.platform);
          final double imgScale = imgItem.scaleFor(data.platform);

          final Offset localOffset = _localImageOffsets[imgItem.id] ?? Offset(imgOffsetX, imgOffsetY);
          final double imgCenterX = (canvasWidth / 2) + (canvasWidth * (localOffset.dx / 1000.0));
          final double imgCenterY = (canvasHeight * 0.5) + (canvasHeight * (localOffset.dy / 2000.0));

          Widget imageWidget = Container(
            decoration: BoxDecoration(
              boxShadow: imgItem.hasShadow
                  ? const [BoxShadow(color: Colors.black38, blurRadius: 18, spreadRadius: 2, offset: Offset(0, 8))]
                  : null,
            ),
            child: Opacity(
              opacity: imgItem.opacity,
              child: Image.memory(
                imgItem.imageBytes,
                fit: BoxFit.contain,
              ),
            ),
          );

          if (!widget.isExporting && vm != null) {
            final isSelected = vm.selectedElementId == imgItem.id || vm.selectedImageId == imgItem.id;
            final isHovering = _hoveringImageId == imgItem.id;
            final isDragging = _draggingImageId == imgItem.id;

            imageWidget = Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: (isSelected || isHovering || isDragging) ? AppColors.primary : Colors.transparent,
                  width: (isSelected || isHovering || isDragging) ? 2.0 : 0.0,
                ),
                borderRadius: BorderRadius.circular(8),
                color: (isSelected || isHovering || isDragging) ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
              ),
              child: imageWidget,
            );

            imageWidget = MouseRegion(
              cursor: SystemMouseCursors.move,
              onEnter: (_) => setState(() => _hoveringImageId = imgItem.id),
              onExit: (_) => setState(() => _hoveringImageId = null),
              child: _EagerPanDetector(
                onPanStart: (_) {
                  vm.selectScreenshot(widget.itemIndex);
                  vm.selectCustomImage(imgItem.id);
                  setState(() {
                    _draggingImageId = imgItem.id;
                    _localImageOffsets[imgItem.id] = Offset(imgOffsetX, imgOffsetY);
                  });
                },
                onPanUpdate: (details) {
                  final double dx = (details.delta.dx / canvasWidth) * 1000.0;
                  final double dy = (details.delta.dy / canvasHeight) * 2000.0;
                  final current = _localImageOffsets[imgItem.id] ?? Offset(imgOffsetX, imgOffsetY);
                  setState(() {
                    _localImageOffsets[imgItem.id] = Offset(current.dx + dx, current.dy + dy);
                  });
                },
                onPanEnd: (_) {
                  final finalOffset = _localImageOffsets[imgItem.id];
                  if (finalOffset != null) {
                    vm.setCustomImageOffsetsForIndex(widget.itemIndex, imgItem.id, finalOffset.dx, finalOffset.dy);
                  }
                  setState(() {
                    _draggingImageId = null;
                    _localImageOffsets.remove(imgItem.id);
                  });
                },
                onPanCancel: () {
                  setState(() {
                    _draggingImageId = null;
                    _localImageOffsets.remove(imgItem.id);
                  });
                },
                child: imageWidget,
              ),
            );
          }

          return Positioned(
            left: imgCenterX,
            top: imgCenterY,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Transform.rotate(
                angle: imgItem.rotation * (pi / 180),
                child: Transform.scale(
                  scale: imgScale * platformScaleCorrection,
                  child: imageWidget,
                ),
              ),
            ),
          );
        }),

        // --- 3. SUBTITLE LAYER ---
        if (data.subtitleText.isNotEmpty)
          Positioned(
            left: subtitleCenterX,
            top: subtitleCenterY,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: subtitleWidget,
            ),
          ),

        // --- 4. TITLE LAYER ---
        if (data.titleText.isNotEmpty)
          Positioned(
            left: titleCenterX,
            top: titleCenterY,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: titleWidget,
            ),
          ),

        // --- 5. EXTRA CUSTOM TEXT ELEMENTS LAYER ---
        ...data.customTextItems.map((item) {
          final double customOffsetX = item.offsetXFor(data.platform);
          final double customOffsetY = item.offsetYFor(data.platform);

          final Offset localOffset = _localCustomTextOffsets[item.id] ?? Offset(customOffsetX, customOffsetY);
          final double customCenterX = (canvasWidth / 2) + (canvasWidth * (localOffset.dx / 1000.0));
          final double customCenterY = (canvasHeight * 0.5) + (canvasHeight * (localOffset.dy / 2000.0));

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
            final isSelected = vm.selectedElementId == item.id || vm.selectedTextId == item.id;
            final isHovering = _hoveringCustomTextId == item.id;
            final isDragging = _draggingCustomTextId == item.id;

            itemWidget = Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(
                  color: (isSelected || isHovering || isDragging) ? AppColors.primary : Colors.transparent,
                  width: (isSelected || isHovering || isDragging) ? 2.0 : 0.0,
                ),
                borderRadius: BorderRadius.circular(6),
                color: (isSelected || isHovering || isDragging) ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
              ),
              child: itemWidget,
            );

            itemWidget = MouseRegion(
              cursor: SystemMouseCursors.move,
              onEnter: (_) => setState(() => _hoveringCustomTextId = item.id),
              onExit: (_) => setState(() => _hoveringCustomTextId = null),
              child: _EagerPanDetector(
                onPanStart: (_) {
                  vm.selectScreenshot(widget.itemIndex);
                  vm.selectElement(item.id);
                  setState(() {
                    _draggingCustomTextId = item.id;
                    _localCustomTextOffsets[item.id] = Offset(customOffsetX, customOffsetY);
                  });
                },
                onPanUpdate: (details) {
                  final double dx = (details.delta.dx / canvasWidth) * 1000.0;
                  final double dy = (details.delta.dy / canvasHeight) * 2000.0;
                  final current = _localCustomTextOffsets[item.id] ?? Offset(customOffsetX, customOffsetY);
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
                child: itemWidget,
              ),
            );
          }

          return Positioned(
            left: customCenterX,
            top: customCenterY,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: Transform.rotate(
                angle: item.rotation * (pi / 180),
                child: itemWidget,
              ),
            ),
          );
        }),
      ],
    );
  }
}
