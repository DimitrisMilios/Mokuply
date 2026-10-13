import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/canvas/canvas_viewport_zoom.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/canvas_grid_painter.dart';
import 'screen_card.dart';
import 'screen_slot.dart';
import 'screen_tabs_row.dart';
import 'store_row_header.dart';
import 'workspace_layout.dart';

/// Centre workspace: the screens of the project laid out as one continuous
/// store strip, with a named tab above each screen and one live row per
/// store (App Store on top, Google Play below). Pan and zoom like Figma.
///
/// The strip itself only rebuilds when screens are added, removed or
/// reordered, or the rows change; each card and tab follows its own screen.
class MultiCanvasWorkspace extends StatefulWidget {
  final TransformationController transformationController;

  /// Preview mode: no menus, no selection chrome, nothing draggable.
  final bool previewing;

  const MultiCanvasWorkspace({super.key, required this.transformationController, this.previewing = false});

  @override
  State<MultiCanvasWorkspace> createState() => _MultiCanvasWorkspaceState();
}

class _MultiCanvasWorkspaceState extends State<MultiCanvasWorkspace> {
  /// How long a deleted screen takes to fade and collapse before the view
  /// model actually removes it.
  static const Duration _leaveDuration = Duration(milliseconds: 420);

  int _lastCount = -1;

  /// Index of the screen that was just added (grows in, tab wobbles once).
  int? _enterIndex;

  /// Index of the screen that is fading out before removal.
  int? _leavingIndex;

  /// Per-index key generation. Bumped when a fresh slot must be created at an
  /// index (a new screen entering, or the neighbour shifting into a deleted
  /// slot) so slot state never leaks between screens.
  int _generation = 0;
  final Map<int, int> _slotGeneration = {};

  Key _slotKey(String kind, int index) => ValueKey('${kind}_${index}_${_slotGeneration[index] ?? 0}');

  void _trackCount(int count, int selectedIndex) {
    if (_lastCount >= 0 && count > _lastCount && _leavingIndex == null) {
      // Add and duplicate both select the new screen.
      _enterIndex = selectedIndex;
      _slotGeneration[selectedIndex] = ++_generation;
    } else if (count < _lastCount) {
      _enterIndex = null;
    }
    _lastCount = count;
  }

  /// Fades and collapses the card and tab, then removes the screen.
  Future<void> _deleteScreen(int index) async {
    final vm = context.read<EditorViewModel>();
    if (_leavingIndex != null) return;
    if (!ClayMotion.of(context).enabled) {
      vm.removeScreenshot(index);
      return;
    }
    setState(() {
      _leavingIndex = index;
      _enterIndex = null;
    });
    await Future<void>.delayed(_leaveDuration);
    if (!mounted) return;
    setState(() {
      _leavingIndex = null;
      // The screen that shifts into this index gets a fresh, full-width slot.
      _slotGeneration[index] = ++_generation;
    });
    vm.removeScreenshot(index);
  }

  @override
  Widget build(BuildContext context) {
    final (count, selectedIndex, platform, showBoth) = context
        .select<EditorViewModel, (int, int, TargetPlatformType, bool)>(
          (vm) => (vm.screenshotsCount, vm.selectedIndex, vm.platform, vm.showBothStores),
        );
    _trackCount(count, selectedIndex);
    final rows = showBoth ? const [TargetPlatformType.appStore, TargetPlatformType.googlePlay] : [platform];

    return ColoredBox(
      color: AppColors.sandDeep,
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(child: CustomPaint(painter: CanvasGridPainter())),
          ),
          Positioned.fill(
            child: CanvasViewportZoom(
              controller: widget.transformationController,
              child: InteractiveViewer(
                transformationController: widget.transformationController,
                minScale: 0.15,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.symmetric(horizontal: 900, vertical: 700),
                constrained: false,
                child: Padding(
                  padding: WorkspaceLayout.contentPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScreenTabsRow(
                        screenCount: count,
                        selectedIndex: selectedIndex,
                        previewing: widget.previewing,
                        cardWidth: WorkspaceLayout.cardWidthFor(rows.first),
                        enterIndex: _enterIndex,
                        leavingIndex: _leavingIndex,
                        keyFor: _slotKey,
                        onDelete: _deleteScreen,
                      ),
                      const SizedBox(height: WorkspaceLayout.tabsGap),
                      for (final (r, store) in rows.indexed) ...[
                        if (r > 0) const SizedBox(height: WorkspaceLayout.rowSpacing),
                        _storeRow(store, active: platform == store, showBoth: showBoth, count: count),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storeRow(TargetPlatformType store, {required bool active, required bool showBoth, required int count}) {
    final vm = context.read<EditorViewModel>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StoreRowHeader(
          store: store,
          active: active,
          showBoth: showBoth,
          previewing: widget.previewing,
          onTap: () => vm.setPlatform(store),
          onToggleBoth: () => vm.setShowBothStores(!showBoth),
        ),
        const SizedBox(height: WorkspaceLayout.rowHeaderGap),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < count; i++)
              ScreenSlot(
                key: _slotKey('card_${store.name}', i),
                width: WorkspaceLayout.slotWidthFor(store),
                enter: i == _enterIndex,
                leaving: i == _leavingIndex,
                child: ScreenCard(index: i, store: store, previewing: widget.previewing),
              ),
          ],
        ),
      ],
    );
  }
}
