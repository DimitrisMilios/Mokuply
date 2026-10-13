import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/clay/clay.dart';

/// Floating zoom bar: fit, zoom out, current zoom (click for 100%), zoom in.
class CanvasZoomBar extends StatefulWidget {
  final TransformationController transformationController;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;
  final VoidCallback onActualSize;

  const CanvasZoomBar({
    super.key,
    required this.transformationController,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
    required this.onActualSize,
  });

  @override
  State<CanvasZoomBar> createState() => _CanvasZoomBarState();
}

class _CanvasZoomBarState extends State<CanvasZoomBar> {
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    widget.transformationController.addListener(_updateScale);
    _updateScale();
  }

  @override
  void didUpdateWidget(CanvasZoomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transformationController != widget.transformationController) {
      oldWidget.transformationController.removeListener(_updateScale);
      widget.transformationController.addListener(_updateScale);
      _updateScale();
    }
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_updateScale);
    super.dispose();
  }

  void _updateScale() {
    final scale = widget.transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.001) {
      setState(() => _currentScale = scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_currentScale * 100).round();

    return ClayPanel(
      radius: AppDimensions.radiusClay,
      padding: const EdgeInsets.all(6),
      lift: 14,
      depth: 5,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClayIconButton(
            icon: Icons.fit_screen_rounded,
            tooltip: 'Fit all screens (0)',
            size: 36,
            iconSize: 18,
            iconColor: AppColors.primary,
            onPressed: widget.onFit,
          ),
          const SizedBox(width: 6),
          ClayIconButton(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom out (−)',
            size: 36,
            iconSize: 18,
            iconColor: AppColors.primary,
            onPressed: widget.onZoomOut,
          ),
          const SizedBox(width: 6),
          Tooltip(
            message: 'Zoom to 100% (1)',
            child: SizedBox(
              width: 68,
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                child: ClayButton.neutral(
                  label: '$percentage%',
                  size: ClayButtonSize.compact,
                  expand: true,
                  textColor: AppColors.primary,
                  onPressed: widget.onActualSize,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          ClayIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Zoom in (+)',
            size: 36,
            iconSize: 18,
            iconColor: AppColors.primary,
            onPressed: widget.onZoomIn,
          ),
        ],
      ),
    );
  }
}
