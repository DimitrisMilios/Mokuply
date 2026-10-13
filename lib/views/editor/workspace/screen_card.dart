import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/template_data.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/canvas/canvas_actions.dart';
import '../../../widgets/canvas/canvas_mockup_widget.dart';
import '../../../widgets/clay/clay.dart';
import 'workspace_layout.dart';

/// One screen of one store row on the workspace strip.
///
/// Subscribes only to its own screen and selection, so editing one screen
/// rebuilds two cards (one per store row) instead of the whole strip.
class ScreenCard extends StatelessWidget {
  final int index;
  final TargetPlatformType store;
  final bool previewing;

  const ScreenCard({super.key, required this.index, required this.store, required this.previewing});

  /// Spring shape used when the OS asks for reduced motion (no overshoot).
  static final Curve _stillCurve = ClaySpringCurve(ClaySprings.still);

  @override
  Widget build(BuildContext context) {
    // The selector can run once more for a screen that was just removed,
    // before the strip rebuilds without it.
    final (screen, selectedId, isActive) = context.select<EditorViewModel, (TemplateData?, String?, bool)>(
      (vm) => index < vm.screenshotsCount
          ? (vm.screenAt(index), vm.selectedElementOn(index), vm.selectedIndex == index)
          : (null, null, false),
    );
    if (screen == null) return const SizedBox.shrink();

    final bool isSelected = isActive && !previewing;
    final double width = WorkspaceLayout.cardWidthFor(store);
    final Curve liftCurve = ClayMotion.of(context).enabled ? ClaySpringCurve.bouncy : _stillCurve;

    return Listener(
      onPointerDown: previewing ? null : (_) => _activate(context.read<EditorViewModel>(), isActive),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: liftCurve,
        // 2px per side = 4px between neighbouring screens, so the strip reads
        // as one continuous store listing.
        margin: const EdgeInsets.symmetric(horizontal: WorkspaceLayout.cardGap / 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          // No border: the selected card floats higher instead.
          boxShadow: [
            BoxShadow(
              color: AppColors.clayShadow.withValues(alpha: isSelected ? 0.24 : 0.12),
              blurRadius: isSelected ? 40 : 20,
              offset: Offset(0, isSelected ? 20 : 12),
            ),
          ],
        ),
        // Each screen repaints on its own, so dragging on one card never
        // re-records the others.
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            child: CanvasMockupWidget(
              data: screen.platform == store ? screen : screen.copyWith(platform: store),
              canvasSize: Size(width, WorkspaceLayout.previewHeight),
              actions: previewing ? null : _actions(context.read<EditorViewModel>()),
              selectedElementId: selectedId,
            ),
          ),
        ),
      ),
    );
  }

  /// A click anywhere on the card makes this screen and store active.
  void _activate(EditorViewModel vm, bool isActive) {
    if (!isActive) vm.selectScreenshot(index);
    if (vm.platform != store) vm.setPlatform(store);
  }

  CanvasActions _actions(EditorViewModel vm) {
    return CanvasActions(
      onSelect: (id) => vm.selectElementOn(index, id),
      onMove: (id, offset) => vm.moveElement(index, id, offset.dx, offset.dy),
      onResize: (id, value) => vm.resizeElement(index, id, value),
      onRotate: (id, degrees) => vm.rotateElement(index, id, degrees),
      onDuplicate: vm.duplicateElement,
      onDelete: vm.removeElement,
      onEditText: (_) => vm.requestTextFocus(),
    );
  }
}
