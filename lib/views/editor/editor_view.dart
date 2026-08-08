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
          // Background ambient gradient glowing orbs for glass reflection
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

          // Main Content Layout
          Column(
            children: [
              _buildNavbar(context, vm),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: AppDimensions.sidebarWidth,
                      child: ListView(
                        padding: const EdgeInsets.all(AppDimensions.spacingXxl),
                        children: const [
                          ScreenshotPanel(),
                          SizedBox(height: AppDimensions.spacingLg),
                          LayoutPanel(),
                          SizedBox(height: AppDimensions.spacingLg),
                          BackgroundPanel(),
                          SizedBox(height: AppDimensions.spacingLg),
                          TypographyPanel(),
                          SizedBox(height: AppDimensions.spacingLg),
                          FramePanel(),
                        ],
                      ),
                    ),
                    Container(width: 1, color: AppColors.glassBorder),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.art_track_rounded, color: AppColors.textOnPrimary, size: 22),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.badgeBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '100% Free & Client-Side',
                    style: TextStyle(color: AppColors.primary, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.bold),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Text(
                '${vm.platform.targetWidth.toInt()} x ${vm.platform.targetHeight.toInt()} px',
                style: const TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
            TextButton.icon(
              onPressed: () => vm.resetToDefaults(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textPrimary),
              label: const Text('Reset', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppDimensions.spacingLg),
            ElevatedButton.icon(
              onPressed: vm.isExporting ? null : () async {
                try {
                  await vm.exportMockup();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.primary,
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.textOnPrimary),
                            SizedBox(width: 12),
                            Text('Successfully exported mockup!', style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
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
                vm.isExporting ? 'Exporting...' : 'Export High-Res PNG',
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
        final double maxAvailableWidth = constraints.maxWidth - 80;
        final double maxAvailableHeight = constraints.maxHeight - 80;

        final double targetRatio = vm.platform.aspectRatio;

        double previewWidth = maxAvailableWidth;
        double previewHeight = previewWidth / targetRatio;

        if (previewHeight > maxAvailableHeight) {
          previewHeight = maxAvailableHeight;
          previewWidth = previewHeight * targetRatio;
        }

        return Container(
          color: AppColors.canvasViewport,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: CanvasGridPainter(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 36,
                      spreadRadius: 4,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: CanvasMockupWidget(
                    data: vm.data,
                    canvasSize: Size(previewWidth, previewHeight),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                child: GlassContainer(
                  opacity: 0.85,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg, vertical: AppDimensions.spacingSm),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.aspect_ratio_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Text(
                        'Live View (${previewWidth.toInt()}x${previewHeight.toInt()} px)  •  Export Target: ${vm.platform.targetWidth.toInt()}x${vm.platform.targetHeight.toInt()} px',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w600),
                      ),
                    ],
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
