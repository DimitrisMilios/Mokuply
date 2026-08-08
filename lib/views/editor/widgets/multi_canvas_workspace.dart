import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/canvas/canvas_mockup_widget.dart';
import '../../../widgets/shared/canvas_grid_painter.dart';
import 'screenshot_reel_bar.dart';

/// Center horizontal multi-screenshot canvas workspace.
class MultiCanvasWorkspace extends StatelessWidget {
  const MultiCanvasWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final double maxCardHeight = constraints.maxHeight - 140;
        final double targetRatio = vm.platform.aspectRatio;

        double previewHeight = maxCardHeight;
        double previewWidth = previewHeight * targetRatio;

        return Container(
          color: AppColors.canvasViewport,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: CanvasGridPainter(),
                ),
              ),

              // Multi-Screenshot Horizontal Side-by-Side Viewport
              Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(vm.screenshotsCount, (index) {
                      final itemData = vm.screenshots[index];
                      final isSelected = vm.selectedIndex == index;

                      return GestureDetector(
                        onTap: () => vm.selectScreenshot(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: isSelected ? 4 : 0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: isSelected ? 32 : 16,
                                spreadRadius: isSelected ? 4 : 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimensions.radiusLg - 2),
                                child: CanvasMockupWidget(
                                  data: itemData,
                                  canvasSize: Size(previewWidth, previewHeight),
                                ),
                              ),

                              // Screen Index Badge Overlay
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Screen #${index + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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

              // Bottom Screenshot Reel Switcher & Add Button Bar
              const Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: ScreenshotReelBar(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
