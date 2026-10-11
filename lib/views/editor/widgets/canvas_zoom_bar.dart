import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/shared/glass_container.dart';

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

    return GlassContainer(
      opacity: 0.85,
      blurX: 14.0,
      blurY: 14.0,
      borderRadius: BorderRadius.circular(AppDimensions.radiusGlass),
      borderColor: AppColors.glassBorder,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.12),
          blurRadius: 20,
          spreadRadius: 1,
          offset: const Offset(0, 6),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: widget.onFit,
            tooltip: 'Fit all screens (0)',
            splashRadius: 18,
            icon: const Icon(Icons.fit_screen_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 2),
          const SizedBox(height: 20, child: VerticalDivider(color: AppColors.glassBorder, width: 1)),
          const SizedBox(width: 2),
          IconButton(
            onPressed: widget.onZoomOut,
            tooltip: 'Zoom out (−)',
            splashRadius: 18,
            icon: const Icon(Icons.remove_rounded, color: AppColors.primary, size: 18),
          ),
          Tooltip(
            message: 'Zoom to 100% (1)',
            child: InkWell(
              onTap: widget.onActualSize,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onZoomIn,
            tooltip: 'Zoom in (+)',
            splashRadius: 18,
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }
}
