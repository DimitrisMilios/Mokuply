import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/canvas/canvas_mockup_widget.dart';
import '../../../widgets/shared/canvas_grid_painter.dart';

/// Center Figma-like interactive multi-screenshot canvas workspace.
/// Enables 2D panning, zooming, and card selections with strict boundaries.
class MultiCanvasWorkspace extends StatelessWidget {
  final TransformationController transformationController;

  const MultiCanvasWorkspace({
    super.key,
    required this.transformationController,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return Container(
      color: AppColors.canvasViewport,
      child: Stack(
        children: [
          // Infinite Canvas Background Grid
          Positioned.fill(
            child: CustomPaint(
              painter: CanvasGridPainter(),
            ),
          ),

          // 2D Pan & Zoom Figma-style Interactive Workspace
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: 0.2,
              maxScale: 3.0,
              // Enforce strict boundaries so cards cannot be panned infinitely off-screen
              boundaryMargin: const EdgeInsets.symmetric(horizontal: 600, vertical: 400),
              constrained: false,
              panEnabled: true,
              scaleEnabled: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 160, vertical: 140),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(vm.screenshotsCount, (index) {
                    final itemData = vm.screenshots[index];
                    final isSelected = vm.selectedIndex == index;

                    // All cards share one height, so the shared design renders at the
                    // same scale on both stores; only the card width follows the store.
                    const double previewHeight = 620.0;
                    final double previewWidth = previewHeight * itemData.platform.aspectRatio;

                    return Listener(
                      onPointerDown: (_) {
                        if (!isSelected) vm.selectScreenshot(index);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Labels live above the frame so they never cover the
                          // artwork or get in the way while editing.
                          SizedBox(
                            width: previewWidth,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _CanvasChip(
                                  label: 'Screen ${index + 1}',
                                  highlighted: isSelected,
                                ),
                                _CanvasChip(
                                  icon: itemData.platform == TargetPlatformType.appStore
                                      ? Icons.apple
                                      : Icons.android,
                                  label: itemData.platform.dimensionsLabel,
                                  tabular: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            // 2px per side = 4px between neighbouring screens, so the strip
                            // reads as one continuous store listing.
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                width: isSelected ? 4 : 0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.45)
                                      : AppColors.primary.withValues(alpha: 0.12),
                                  blurRadius: isSelected ? 36 : 20,
                                  spreadRadius: isSelected ? 4 : 0,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            // Each screen repaints on its own, so dragging on one
                            // card never re-rasterises the others.
                            child: RepaintBoundary(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusLg - 2),
                                child: CanvasMockupWidget(
                                  data: itemData,
                                  itemIndex: index,
                                  canvasSize: Size(previewWidth, previewHeight),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small pill shown above a canvas card (screen number, store dimensions).
class _CanvasChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool highlighted;
  final bool tabular;

  const _CanvasChip({
    required this.label,
    this.icon,
    this.highlighted = false,
    this.tabular = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = highlighted ? AppColors.textOnPrimary : AppColors.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? AppColors.primary : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
            ),
          ),
        ],
      ),
    );
  }
}
