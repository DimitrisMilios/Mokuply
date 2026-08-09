import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
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

                    // Standard high-resolution base dimensions for artboard cards
                    const double previewHeight = 620.0;
                    final double previewWidth = previewHeight * vm.platform.aspectRatio;

                    return Listener(
                      onPointerDown: (_) {
                        if (!isSelected) vm.selectScreenshot(index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
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
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppDimensions.radiusLg - 2),
                              child: CanvasMockupWidget(
                                data: itemData,
                                itemIndex: index,
                                canvasSize: Size(previewWidth, previewHeight),
                              ),
                            ),

                            // Screen Index Badge Overlay
                            Positioned(
                              top: 14,
                              left: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  'Screen #${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
