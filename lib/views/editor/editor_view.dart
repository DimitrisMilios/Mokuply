import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/store_specs.dart';
import '../../viewmodels/editor_viewmodel.dart';
import '../../widgets/shared/canvas_grid_painter.dart';
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
      body: Column(
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
                Container(width: 1, color: AppColors.surfaceBorder),
                Expanded(
                  child: _buildCanvasWorkspace(context, vm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar(BuildContext context, EditorViewModel vm) {
    return Container(
      height: AppDimensions.navbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                ),
                child: const Icon(Icons.art_track_rounded, color: AppColors.textPrimary, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              const Text(
                'Mocuply',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Text(
                  '100% Free & Client-Side',
                  style: TextStyle(color: AppColors.primaryLight, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600),
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
                  return AppColors.primaryDark;
                }
                return AppColors.background;
              }),
              foregroundColor: WidgetStateProperty.all(AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Text(
              '${vm.platform.targetWidth.toInt()} x ${vm.platform.targetHeight.toInt()} px',
              style: const TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          TextButton.icon(
            onPressed: () => vm.resetToDefaults(),
            icon: const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
            label: const Text('Reset', style: TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(width: AppDimensions.spacingLg),
          ElevatedButton.icon(
            onPressed: vm.isExporting ? null : () async {
              try {
                await vm.exportMockup();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.success,
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: AppColors.textPrimary),
                          SizedBox(width: 12),
                          Text('Successfully exported mockup!'),
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
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLg)),
              elevation: 4,
            ),
            icon: vm.isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppColors.textPrimary, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(
              vm.isExporting ? 'Exporting...' : 'Export High-Res PNG',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: AppDimensions.fontLg),
            ),
          ),
        ],
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CanvasMockupWidget(
                  data: vm.data,
                  canvasSize: Size(previewWidth, previewHeight),
                ),
              ),
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg, vertical: AppDimensions.spacingSm),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.aspect_ratio_rounded, color: AppColors.primaryLight, size: 16),
                      const SizedBox(width: AppDimensions.spacingSm),
                      Text(
                        'Live View (${previewWidth.toInt()}x${previewHeight.toInt()} px)  •  Export Native Target: ${vm.platform.targetWidth.toInt()}x${vm.platform.targetHeight.toInt()} px',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: AppDimensions.fontBody),
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
