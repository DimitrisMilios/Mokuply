import 'package:flutter/material.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

enum ScreenTabAction { rename, duplicate, applyStyle, moveLeft, moveRight, delete }

/// The "…" menu of screen tab [index], anchored under [anchor].
Future<ScreenTabAction?> showScreenTabMenu({
  required BuildContext anchor,
  required int index,
  required int screenCount,
}) {
  final box = anchor.findRenderObject() as RenderBox;
  // Global corners (the strip is zoomed, so the size goes through the transform too).
  final rect = Rect.fromPoints(box.localToGlobal(Offset.zero), box.localToGlobal(box.size.bottomRight(Offset.zero)));

  return showClayMenu<ScreenTabAction>(
    context: anchor,
    anchorRect: rect,
    items: [
      const ClayMenuItem(value: ScreenTabAction.rename, label: 'Rename', icon: Icons.drive_file_rename_outline_rounded),
      const ClayMenuItem(value: ScreenTabAction.duplicate, label: 'Duplicate', icon: Icons.content_copy_rounded),
      const ClayMenuItem(
        value: ScreenTabAction.applyStyle,
        label: 'Apply this style to all screens',
        icon: Icons.auto_fix_high_rounded,
      ),
      const ClayMenuItem.divider(),
      ClayMenuItem(
        value: ScreenTabAction.moveLeft,
        label: 'Move left',
        icon: Icons.arrow_back_rounded,
        enabled: index > 0,
      ),
      ClayMenuItem(
        value: ScreenTabAction.moveRight,
        label: 'Move right',
        icon: Icons.arrow_forward_rounded,
        enabled: index < screenCount - 1,
      ),
      const ClayMenuItem.divider(),
      ClayMenuItem(
        value: ScreenTabAction.delete,
        label: 'Delete screen',
        icon: Icons.delete_outline_rounded,
        danger: true,
        enabled: screenCount > 1,
      ),
    ],
  );
}

/// Runs the menu actions that are plain view-model calls. Rename and delete
/// are animated by the tab and strip, so they are handled there.
void runScreenTabAction(BuildContext context, EditorViewModel vm, ScreenTabAction action, int index) {
  switch (action) {
    case ScreenTabAction.duplicate:
      vm.duplicateScreenshot(index);
    case ScreenTabAction.applyStyle:
      vm.applyStyleToAllScreens(index);
      ClayToast.show(context, 'Applied the style of ${vm.screenNameAt(index)} to all screens');
    case ScreenTabAction.moveLeft:
      vm.moveScreenshot(index, index - 1);
    case ScreenTabAction.moveRight:
      vm.moveScreenshot(index, index + 1);
    case ScreenTabAction.rename || ScreenTabAction.delete:
      break;
  }
}
