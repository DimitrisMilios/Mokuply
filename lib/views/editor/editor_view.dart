import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../widgets/shared/ambient_background.dart';
import 'panels/screenshot_panel.dart';
import 'panels/layout_panel.dart';
import 'panels/background_panel.dart';
import 'panels/typography_panel.dart';
import 'panels/frame_panel.dart';
import 'widgets/active_card_bar.dart';
import 'widgets/editor_navbar.dart';
import 'widgets/multi_canvas_workspace.dart';

/// Clean declarative EditorView composed of modular subwidgets.
class EditorView extends StatelessWidget {
  const EditorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: Column(
          children: [
            const EditorNavbar(),
            Expanded(
              child: Row(
                children: [
                  // Left Customization Sidebar
                  SizedBox(
                    width: AppDimensions.sidebarWidth,
                    child: ListView(
                      padding: const EdgeInsets.all(AppDimensions.spacingXxl),
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
                  Container(width: 1, color: AppColors.glassBorder),

                  // Center Multi-Screenshot Workspace
                  const Expanded(
                    child: MultiCanvasWorkspace(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
