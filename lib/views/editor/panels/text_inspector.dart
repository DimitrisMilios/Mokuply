import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/text_element.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/font_picker_field.dart';
import '../workspace/workspace_layout.dart';
import 'text_style_row.dart';

/// Edits the headline, the subtitle, or an extra text element, depending on [elementId].
class TextInspector extends StatefulWidget {
  final String elementId;

  const TextInspector({super.key, required this.elementId});

  @override
  State<TextInspector> createState() => _TextInspectorState();
}

class _TextInspectorState extends State<TextInspector> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _textFocus = FocusNode(debugLabel: 'inspector-text');

  /// Last focus request any text inspector handled. Static, so a request
  /// that also mounted this inspector (double-click on an unselected text)
  /// is still seen as new.
  static int _handledFocusRequest = 0;

  @override
  void dispose() {
    _controller.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  /// Double-clicking a text on the canvas asks us to focus the field.
  void _handleFocusRequest(int request) {
    if (request <= _handledFocusRequest) return;
    _handledFocusRequest = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _textFocus.requestFocus();
      _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    });
  }

  /// Keeps the field in sync when the text changes elsewhere, without
  /// fighting the caret while typing.
  void _syncField(String text) {
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (element, focusRequest) = context.select<EditorViewModel, (TextElement?, int)>(
      (vm) => (vm.textElement(widget.elementId), vm.textFocusRequest),
    );
    if (element == null) {
      return const Text('This text element no longer exists.', style: TextStyle(color: AppColors.textMuted));
    }
    _handleFocusRequest(focusRequest);
    _syncField(element.text);

    final vm = context.read<EditorViewModel>();
    final id = widget.elementId;
    // Sizes are real pixels on the 1320×2868 export; the preview card is much
    // smaller, which is why the canvas text looks tiny next to the number.
    final int previewPx = (element.fontSize * WorkspaceLayout.previewHeight / DesignSpace.height).round();
    final String hint = element.supportsRotation
        ? 'Drag to move, corners to resize, top handle to rotate. Double-click to edit.'
        : 'Drag to move, corners to resize. Double-click to edit.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClayField(
          controller: _controller,
          focusNode: _textFocus,
          label: 'Text',
          hint: element.isHeadline ? 'Leave empty to hide' : null,
          onChanged: (v) => vm.editText(id, text: v),
          maxLines: 3,
          minLines: 1,
        ),
        const SizedBox(height: 14),
        FontPickerField(
          value: element.font,
          onChanged: (v) => vm.editText(id, font: v),
        ),
        const SizedBox(height: 14),
        ClaySlider(
          label: 'Size on export',
          valueText: '${element.fontSize.toInt()}px',
          value: element.fontSize.clamp(element.minSize, element.maxSize),
          min: element.minSize,
          max: element.maxSize,
          onChanged: (v) => vm.editText(id, fontSize: v),
        ),
        Text(
          'Px on the ${DesignSpace.width.toInt()}×${DesignSpace.height.toInt()} export (≈ ${previewPx}px on the card).',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.3),
        ),
        const SizedBox(height: 14),
        const ClayLabel('Style', padding: EdgeInsets.only(left: 4, bottom: 6)),
        TextStyleRow(
          weight: element.weight,
          alignment: element.alignment,
          color: element.color,
          onWeight: (v) => vm.editText(id, weight: v),
          onAlignment: (v) => vm.editText(id, alignment: v),
          onColor: (v) => vm.editText(id, color: v),
        ),
        if (element.supportsRotation) ...[
          const SizedBox(height: 14),
          ClaySlider(
            label: 'Rotation',
            valueText: '${element.rotation.toInt()}°',
            value: element.rotation,
            min: -180.0,
            max: 180.0,
            onChanged: (v) => vm.editText(id, rotation: v),
          ),
        ],
        const SizedBox(height: 14),
        Text(hint, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3)),
        const SizedBox(height: 10),
        ClayButton.text(
          label: element.isHeadline ? 'Clear text' : 'Delete text element',
          icon: Icons.delete_outline_rounded,
          danger: true,
          expand: true,
          onPressed: () => element.isHeadline ? vm.editText(id, text: '') : vm.removeCustomTextElement(id),
        ),
      ],
    );
  }
}
