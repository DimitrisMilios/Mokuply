import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/shared/ambient_background.dart';
import 'widgets/action_rail.dart';
import 'widgets/canvas_zoom_bar.dart';
import 'widgets/editor_navbar.dart';
import 'widgets/inspector_panel.dart';
import 'widgets/multi_canvas_workspace.dart';
import 'widgets/screenshot_reel_bar.dart';

/// Full-screen Editor View with floating glassmorphism UI overlays and 2D canvas navigation.
class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetCanvasView() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: Stack(
          children: [
            // Layer 0: Full-Screen 2D Interactive Canvas Workspace
            Positioned.fill(
              child: MultiCanvasWorkspace(
                transformationController: _transformationController,
              ),
            ),

            // Layer 1: Floating Top Navigation Header
            const Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: EditorNavbar(),
            ),

            // Layer 2: Left action rail (add things, open screen sections)
            const Positioned(
              top: 98,
              bottom: 16,
              left: 16,
              child: ActionRail(),
            ),

            // Layer 3: Right inspector (edits whatever is selected)
            const Positioned(
              top: 98,
              bottom: 86,
              right: 16,
              child: InspectorPanel(),
            ),

            // Layer 4: Floating Bottom Screenshot Reel Switcher
            // (keeps clear of the rail on the left and the zoom bar on the right)
            const Positioned(
              bottom: 20,
              left: 108,
              right: 200,
              child: Center(
                child: ScreenshotReelBar(),
              ),
            ),

            // Layer 5: Floating Bottom-Right Canvas Zoom & Navigation Bar
            Positioned(
              bottom: 20,
              right: 20,
              child: CanvasZoomBar(
                transformationController: _transformationController,
                onResetView: _resetCanvasView,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
