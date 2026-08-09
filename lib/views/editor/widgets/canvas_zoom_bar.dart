import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/shared/glass_container.dart';

/// Floating Canvas Navigation & Zoom Control Bar (Figma-style).
class CanvasZoomBar extends StatefulWidget {
  final TransformationController transformationController;
  final VoidCallback? onResetView;

  const CanvasZoomBar({
    super.key,
    required this.transformationController,
    this.onResetView,
  });

  @override
  State<CanvasZoomBar> createState() => _CanvasZoomBarState();
}

class _CanvasZoomBarState extends State<CanvasZoomBar> {
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    widget.transformationController.addListener(_onTransformationChanged);
    _updateScale();
  }

  @override
  void dispose() {
    widget.transformationController.removeListener(_onTransformationChanged);
    super.dispose();
  }

  void _onTransformationChanged() {
    _updateScale();
  }

  void _updateScale() {
    final matrix = widget.transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.01) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _zoomBy(double factor) {
    final matrix = widget.transformationController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final newScale = (currentScale * factor).clamp(0.2, 3.0);
    final scaleRatio = newScale / currentScale;

    // Zoom relative to matrix center
    // ignore: deprecated_member_use
    matrix.scale(scaleRatio, scaleRatio, 1.0);
    widget.transformationController.value = matrix;
  }

  void _resetZoom() {
    if (widget.onResetView != null) {
      widget.onResetView!();
    } else {
      widget.transformationController.value = Matrix4.identity();
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
          // Reset / Fit to Screen Button
          IconButton(
            onPressed: _resetZoom,
            tooltip: 'Fit Canvas / Center View',
            splashRadius: 18,
            icon: const Icon(Icons.center_focus_strong_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 2),
          const SizedBox(
            height: 20,
            child: VerticalDivider(color: AppColors.glassBorder, width: 1),
          ),
          const SizedBox(width: 2),

          // Zoom Out Button
          IconButton(
            onPressed: () => _zoomBy(0.85),
            tooltip: 'Zoom Out (-)',
            splashRadius: 18,
            icon: const Icon(Icons.remove_rounded, color: AppColors.primary, size: 18),
          ),

          // Scale percentage display button (Click to reset)
          InkWell(
            onTap: _resetZoom,
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

          // Zoom In Button
          IconButton(
            onPressed: () => _zoomBy(1.18),
            tooltip: 'Zoom In (+)',
            splashRadius: 18,
            icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
          ),
        ],
      ),
    );
  }
}
