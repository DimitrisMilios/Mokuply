import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';
import '../panels/screenshot_panel.dart';
import '../panels/layout_panel.dart';
import '../panels/background_panel.dart';
import '../panels/typography_panel.dart';
import '../panels/frame_panel.dart';
import 'active_card_bar.dart';

/// Floating Glassmorphic Action Sidebar for the Editor Canvas.
/// Supports smooth Expand / Collapse transitions.
class FloatingSidebar extends StatefulWidget {
  const FloatingSidebar({super.key});

  @override
  State<FloatingSidebar> createState() => _FloatingSidebarState();
}

class _FloatingSidebarState extends State<FloatingSidebar> {
  bool _isCollapsed = false;

  void _toggleCollapsed() {
    setState(() {
      _isCollapsed = !_isCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: _isCollapsed ? 64.0 : AppDimensions.sidebarWidth,
      child: GlassContainer(
        opacity: 0.85,
        blurX: 16.0,
        blurY: 16.0,
        borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
        borderColor: AppColors.glassBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Floating Sidebar Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.glassBorder, width: 1.0),
                ),
              ),
              child: Row(
                children: [
                  if (!_isCollapsed) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Customization',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                  ],
                  IconButton(
                    onPressed: _toggleCollapsed,
                    tooltip: _isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                    splashRadius: 20,
                    icon: Icon(
                      _isCollapsed
                          ? Icons.keyboard_double_arrow_right_rounded
                          : Icons.keyboard_double_arrow_left_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Sidebar Body Content
            Expanded(
              child: _isCollapsed
                  ? _buildCollapsedIcons(vm)
                  : ListView(
                      padding: const EdgeInsets.all(AppDimensions.spacingLg),
                      children: const [
                        ActiveCardBar(),
                        SizedBox(height: AppDimensions.spacingLg),
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
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedIcons(EditorViewModel vm) {
    return Column(
      children: [
        const SizedBox(height: 12),
        IconButton(
          onPressed: _toggleCollapsed,
          tooltip: 'Active Screen #${vm.selectedIndex + 1}',
          icon: CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              '${vm.selectedIndex + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const Divider(color: AppColors.glassBorder, indent: 12, endIndent: 12),
        IconButton(
          onPressed: _toggleCollapsed,
          tooltip: 'Screenshots',
          icon: const Icon(Icons.image_outlined, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 8),
        IconButton(
          onPressed: _toggleCollapsed,
          tooltip: 'Layout',
          icon: const Icon(Icons.dashboard_customize_outlined, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 8),
        IconButton(
          onPressed: _toggleCollapsed,
          tooltip: 'Background',
          icon: const Icon(Icons.palette_outlined, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 8),
        IconButton(
          onPressed: _toggleCollapsed,
          tooltip: 'Typography',
          icon: const Icon(Icons.text_fields_rounded, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 8),
        IconButton(
          onPressed: _toggleCollapsed,
          tooltip: 'Device Frame',
          icon: const Icon(Icons.phone_iphone_rounded, color: AppColors.primary, size: 22),
        ),
      ],
    );
  }
}
