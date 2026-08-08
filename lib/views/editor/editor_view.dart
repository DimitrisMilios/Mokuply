import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/store_specs.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../../widgets/shared/canvas_grid_painter.dart';
import '../../widgets/shared/glass_container.dart';
import '../../widgets/canvas/canvas_mockup_widget.dart';
import 'panels/screenshot_panel.dart';
import 'panels/layout_panel.dart';
import 'panels/background_panel.dart';
import 'panels/typography_panel.dart';
import 'panels/frame_panel.dart';

class EditorView extends StatelessWidget {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background ambient glowing reflections for glass background
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbCream,
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: 100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbJungle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.orbSage,
              ),
            ),
          ),

          // Main Layout
          Column(
            children: [
              _buildNavbar(context, vm),
              Expanded(
                child: Row(
                  children: [
                    // Left Customization Sidebar
                    SizedBox(
                      width: AppDimensions.sidebarWidth,
                      child: ListView(
                        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
                        children: [
                          _buildActiveCardHeader(context, vm),
                          const SizedBox(height: AppDimensions.spacingLg),
                          const ScreenshotPanel(),
                          const SizedBox(height: AppDimensions.spacingLg),
                          const LayoutPanel(),
                          const SizedBox(height: AppDimensions.spacingLg),
                          const BackgroundPanel(),
                          const SizedBox(height: AppDimensions.spacingLg),
                          const TypographyPanel(),
                          const SizedBox(height: AppDimensions.spacingLg),
                          const FramePanel(),
                        ],
                      ),
                    ),
                    Container(width: 1, color: AppColors.glassBorder),

                    // Center Multi-Screenshot Workspace
                    Expanded(
                      child: _buildCanvasWorkspace(context, vm),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCardHeader(BuildContext context, EditorViewModel vm) {
    return GlassContainer(
      opacity: 0.8,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              'Screen #${vm.selectedIndex + 1}',
              style: const TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Editing Active Card',
            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => vm.duplicateScreenshot(vm.selectedIndex),
            tooltip: 'Duplicate Screen',
            icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
          ),
          if (vm.screenshotsCount > 1)
            IconButton(
              onPressed: () => vm.removeScreenshot(vm.selectedIndex),
              tooltip: 'Delete Screen',
              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
            ),
        ],
      ),
    );
  }

  Widget _buildNavbar(BuildContext context, EditorViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GlassContainer(
        height: AppDimensions.navbarHeight,
        opacity: 0.75,
        borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
        child: Row(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => vm.goBackToHome(),
                  tooltip: 'Back to Store Templates',
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(Icons.art_track_rounded, color: AppColors.textOnPrimary, size: 20),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                const Text(
                  'Mocuply',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${vm.screenshotsCount} Screenshots Set',
                    style: const TextStyle(color: AppColors.primary, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SegmentedButton<TargetPlatformType>(
              segments: const [
                ButtonSegment(
                  value: TargetPlatformType.appStore,
                  label: Text('iPhone 16 Pro Max'),
                  icon: Icon(Icons.apple, size: 18),
                ),
                ButtonSegment(
                  value: TargetPlatformType.googlePlay,
                  label: Text('Samsung S26 Ultra'),
                  icon: Icon(Icons.android, size: 18),
                ),
              ],
              selected: {vm.platform},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  vm.setPlatform(selected.first);
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.primary;
                  }
                  return Colors.white.withValues(alpha: 0.6);
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppColors.textOnPrimary;
                  }
                  return AppColors.textPrimary;
                }),
                side: WidgetStateProperty.all(const BorderSide(color: AppColors.glassBorder)),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
            TextButton.icon(
              onPressed: () => vm.resetToDefaults(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimary),
              label: const Text('Reset Set', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppDimensions.spacingLg),

            // Batch Export Button
            ElevatedButton.icon(
              onPressed: vm.isExporting ? null : () async {
                try {
                  await vm.exportAllScreenshots();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.textOnPrimary),
                            const SizedBox(width: 12),
                            Text(
                              'Exported all ${vm.screenshotsCount} high-res store PNGs!',
                              style: const TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.error,
                        content: Text('Export failed: $e'),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
                elevation: 3,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
              ),
              icon: vm.isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: AppColors.textOnPrimary, strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              label: Text(
                vm.isExporting
                    ? 'Exporting ${vm.exportingProgressIndex}/${vm.screenshotsCount}...'
                    : 'Download All (${vm.screenshotsCount}) PNGs',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontLg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasWorkspace(BuildContext context, EditorViewModel vm) {
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
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: GlassContainer(
                    opacity: 0.85,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Screenshots Set (${vm.screenshotsCount}):',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        ...List.generate(vm.screenshotsCount, (index) {
                          final isSelected = vm.selectedIndex == index;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => vm.selectScreenshot(index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.glassBorder),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 6),
                        IconButton(
                          onPressed: () => vm.addScreenshot(),
                          tooltip: 'Add Screenshot to Set',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
