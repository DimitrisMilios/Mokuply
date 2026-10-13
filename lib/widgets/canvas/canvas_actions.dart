import 'dart:ui';

/// What happens when the user manipulates a screen on the canvas. The canvas
/// only reports intent; the editor decides what it means.
///
/// Element ids are 'title', 'subtitle' or `dev_` / `img_` / `txt_` ids;
/// offsets are stored design offset units.
class CanvasActions {
  /// An element was clicked, or the empty background (null).
  final void Function(String? id) onSelect;
  final void Function(String id, Offset offset) onMove;

  /// A scale factor for frames and images, a font size for text.
  final void Function(String id, double value) onResize;
  final void Function(String id, double degrees) onRotate;
  final void Function(String id) onDuplicate;
  final void Function(String id) onDelete;

  /// Double-click on a text element.
  final void Function(String id) onEditText;

  const CanvasActions({
    required this.onSelect,
    required this.onMove,
    required this.onResize,
    required this.onRotate,
    required this.onDuplicate,
    required this.onDelete,
    required this.onEditText,
  });
}
