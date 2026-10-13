import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../../models/element_kind.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';

/// View-level actions the keyboard can trigger.
class EditorShortcutActions {
  final VoidCallback exitPreview;
  final VoidCallback releaseTextFocus;
  final VoidCallback zoomIn;
  final VoidCallback zoomOut;
  final VoidCallback fit;
  final VoidCallback actualSize;

  const EditorShortcutActions({
    required this.exitPreview,
    required this.releaseTextFocus,
    required this.zoomIn,
    required this.zoomOut,
    required this.fit,
    required this.actualSize,
  });
}

/// Editor keyboard shortcuts: arrows nudge the selection (Shift = ×10),
/// Delete removes it, Esc deselects / leaves preview / leaves a text field,
/// Ctrl+D duplicates the selection (or the screen), + / − zoom, 0 fits the
/// strip, 1 is 100%.
KeyEventResult handleEditorKey(
  KeyEvent event, {
  required EditorViewModel vm,
  required EditorShortcutActions actions,
  required bool previewing,
  required bool typing,
}) {
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
  final key = event.logicalKey;
  final keyboard = HardwareKeyboard.instance;

  if (key == LogicalKeyboardKey.escape) {
    if (previewing) {
      actions.exitPreview();
    } else if (typing) {
      actions.releaseTextFocus();
    } else {
      vm.selectElement(null);
    }
    return KeyEventResult.handled;
  }
  if (typing || previewing) return KeyEventResult.ignored;

  final double step = keyboard.isShiftPressed ? 10 : 1;
  final bool ctrl = keyboard.isControlPressed || keyboard.isMetaPressed;
  final VoidCallback? action = switch (key) {
    LogicalKeyboardKey.delete || LogicalKeyboardKey.backspace => vm.removeSelectedElement,
    LogicalKeyboardKey.arrowLeft => () => vm.nudgeSelected(-step, 0),
    LogicalKeyboardKey.arrowRight => () => vm.nudgeSelected(step, 0),
    LogicalKeyboardKey.arrowUp => () => vm.nudgeSelected(0, -step),
    LogicalKeyboardKey.arrowDown => () => vm.nudgeSelected(0, step),
    LogicalKeyboardKey.keyD when ctrl => () => _duplicate(vm),
    LogicalKeyboardKey.equal || LogicalKeyboardKey.add || LogicalKeyboardKey.numpadAdd => actions.zoomIn,
    LogicalKeyboardKey.minus || LogicalKeyboardKey.numpadSubtract => actions.zoomOut,
    LogicalKeyboardKey.digit0 || LogicalKeyboardKey.numpad0 => actions.fit,
    LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => actions.actualSize,
    _ => null,
  };
  if (action == null) return KeyEventResult.ignored;
  action();
  return KeyEventResult.handled;
}

/// Ctrl+D: the selected frame, image or text, or else the whole screen.
void _duplicate(EditorViewModel vm) {
  final id = vm.selectedElementId;
  if (ElementKind.of(id)?.isFreeform ?? false) {
    vm.duplicateElement(id!);
  } else {
    vm.duplicateScreenshot(vm.selectedIndex);
  }
}

/// True while a text field (not the editor itself) has keyboard focus.
bool isTypingInTextField(FocusNode editorFocus) {
  final focused = FocusManager.instance.primaryFocus;
  if (focused == null || focused == editorFocus) return false;
  final ctx = focused.context;
  return ctx != null && ctx.findAncestorStateOfType<EditableTextState>() != null;
}
