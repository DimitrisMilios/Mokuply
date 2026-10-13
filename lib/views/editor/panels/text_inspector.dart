import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_text_item.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/color_swatch_button.dart';
import '../../../widgets/shared/font_picker_field.dart';
import '../widgets/multi_canvas_workspace.dart';

/// Edits the headline, the subtitle, or an extra text element, depending on [elementId].
class TextInspector extends StatefulWidget {
  final String elementId;

  const TextInspector({super.key, required this.elementId});

  @override
  State<TextInspector> createState() => _TextInspectorState();
}

class _TextInspectorState extends State<TextInspector> {
  static const Map<String, FontWeight> _weightOptions = {
    'Light': FontWeight.w300,
    'Regular': FontWeight.w400,
    'Medium': FontWeight.w500,
    'SemiBold': FontWeight.w600,
    'Bold': FontWeight.w700,
    'ExtraBold': FontWeight.w800,
    'Black': FontWeight.w900,
  };

  static const Map<TextAlign, IconData> _alignIcons = {
    TextAlign.left: Icons.format_align_left_rounded,
    TextAlign.center: Icons.format_align_center_rounded,
    TextAlign.right: Icons.format_align_right_rounded,
  };

  late final TextEditingController _controller;
  final FocusNode _textFocus = FocusNode(debugLabel: 'inspector-text');

  /// Last focus request any text inspector handled. Static, so a request
  /// that also mounted this inspector (double-click on an unselected text)
  /// is still seen as new.
  static int _handledFocusRequest = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final target = _TextTarget.resolve(vm, widget.elementId);
    if (target == null) {
      return const Text('This text element no longer exists.', style: TextStyle(color: AppColors.textMuted));
    }

    // Double-clicking a text on the canvas asks us to focus the field.
    if (vm.textFocusRequest > _handledFocusRequest) {
      _handledFocusRequest = vm.textFocusRequest;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _textFocus.requestFocus();
        _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      });
    }

    // Keep the field in sync when selection changes, without fighting the caret while typing.
    if (_controller.text != target.text) {
      _controller.value = TextEditingValue(
        text: target.text,
        selection: TextSelection.collapsed(offset: target.text.length),
      );
    }

    // Sizes are real pixels on the 1320×2868 export; the preview card is much
    // smaller, which is why the canvas text looks tiny next to the number.
    final int previewPx = (target.fontSize * MultiCanvasWorkspace.previewHeight / DesignSpace.height).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClayField(
          controller: _controller,
          focusNode: _textFocus,
          label: 'Text',
          hint: target.isHeadline ? 'Leave empty to hide' : null,
          onChanged: target.setText,
          maxLines: 3,
          minLines: 1,
        ),
        const SizedBox(height: 14),
        FontPickerField(value: target.font, onChanged: target.setFont),
        const SizedBox(height: 14),
        ClaySlider(
          label: 'Size on export',
          valueText: '${target.fontSize.toInt()}px',
          value: target.fontSize.clamp(target.minSize, target.maxSize),
          min: target.minSize,
          max: target.maxSize,
          onChanged: target.setFontSize,
        ),
        Text(
          'Px on the ${DesignSpace.width.toInt()}×${DesignSpace.height.toInt()} export (≈ ${previewPx}px on the card).',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, height: 1.3),
        ),
        const SizedBox(height: 14),
        const ClayLabel('Style', padding: EdgeInsets.only(left: 4, bottom: 6)),
        _buildWeightAlignColorRow(target),
        if (target.supportsRotation) ...[
          const SizedBox(height: 14),
          ClaySlider(
            label: 'Rotation',
            valueText: '${target.rotation.toInt()}°',
            value: target.rotation,
            min: -180.0,
            max: 180.0,
            onChanged: target.setRotation,
          ),
        ],
        const SizedBox(height: 14),
        Text(
          target.supportsRotation
              ? 'Drag to move, corners to resize, top handle to rotate. Double-click to edit.'
              : 'Drag to move, corners to resize. Double-click to edit.',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 10),
        ClayButton.text(
          label: target.isHeadline ? 'Clear text' : 'Delete text element',
          icon: Icons.delete_outline_rounded,
          danger: true,
          expand: true,
          onPressed: () => target.remove(vm),
        ),
      ],
    );
  }

  Widget _buildWeightAlignColorRow(_TextTarget target) {
    final currentWeightName = _weightOptions.entries
        .firstWhere((e) => e.value == target.weight, orElse: () => _weightOptions.entries.first)
        .key;

    return Row(
      children: [
        Expanded(
          child: ClayDropdown<String>(
            value: currentWeightName,
            height: 40,
            items: [for (final k in _weightOptions.keys) ClayDropdownItem(value: k, label: k)],
            onChanged: (k) {
              if (_weightOptions.containsKey(k)) target.setWeight(_weightOptions[k]!);
            },
          ),
        ),
        const SizedBox(width: 8),
        ClaySegmented<TextAlign>(
          height: 40,
          segmentWidth: 38,
          segments: [
            for (final entry in _alignIcons.entries)
              ClaySegment(value: entry.key, icon: entry.value, tooltip: _alignTooltip(entry.key)),
          ],
          selected: _alignIcons.containsKey(target.alignment) ? target.alignment : TextAlign.left,
          onChanged: target.setAlignment,
        ),
        const SizedBox(width: 8),
        ColorSwatchButton(color: target.color, onColorChanged: target.setColor, size: 32),
      ],
    );
  }

  static String _alignTooltip(TextAlign align) => switch (align) {
        TextAlign.center => 'Align centre',
        TextAlign.right => 'Align right',
        _ => 'Align left',
      };
}

/// Uniform read/write access to whichever text element is selected.
class _TextTarget {
  final bool isHeadline;
  final bool supportsRotation;
  final double minSize;
  final double maxSize;
  final String text;
  final String font;
  final double fontSize;
  final FontWeight weight;
  final Color color;
  final TextAlign alignment;
  final double rotation;
  final ValueChanged<String> setText;
  final ValueChanged<String> setFont;
  final ValueChanged<double> setFontSize;
  final ValueChanged<FontWeight> setWeight;
  final ValueChanged<Color> setColor;
  final ValueChanged<TextAlign> setAlignment;
  final ValueChanged<double> setRotation;
  final void Function(EditorViewModel vm) remove;

  const _TextTarget({
    required this.isHeadline,
    required this.supportsRotation,
    required this.minSize,
    required this.maxSize,
    required this.text,
    required this.font,
    required this.fontSize,
    required this.weight,
    required this.color,
    required this.alignment,
    required this.rotation,
    required this.setText,
    required this.setFont,
    required this.setFontSize,
    required this.setWeight,
    required this.setColor,
    required this.setAlignment,
    required this.setRotation,
    required this.remove,
  });

  static _TextTarget? resolve(EditorViewModel vm, String id) {
    if (id == 'title') {
      return _TextTarget(
        isHeadline: true,
        supportsRotation: false,
        minSize: TextSizeLimits.titleMin,
        maxSize: TextSizeLimits.titleMax,
        text: vm.titleText,
        font: vm.titleFont,
        fontSize: vm.titleSize,
        weight: vm.titleWeight,
        color: vm.textColor,
        alignment: vm.titleAlignment,
        rotation: 0,
        setText: vm.setTitleText,
        setFont: vm.setTitleFont,
        setFontSize: vm.setTitleSize,
        setWeight: vm.setTitleWeight,
        setColor: vm.setTextColor,
        setAlignment: vm.setTitleAlignment,
        setRotation: (_) {},
        remove: (vm) => vm.setTitleText(''),
      );
    }
    if (id == 'subtitle') {
      return _TextTarget(
        isHeadline: true,
        supportsRotation: false,
        minSize: TextSizeLimits.subtitleMin,
        maxSize: TextSizeLimits.subtitleMax,
        text: vm.subtitleText,
        font: vm.subtitleFont,
        fontSize: vm.subtitleSize,
        weight: vm.subtitleWeight,
        color: vm.subtitleColor,
        alignment: vm.subtitleAlignment,
        rotation: 0,
        setText: vm.setSubtitleText,
        setFont: vm.setSubtitleFont,
        setFontSize: vm.setSubtitleSize,
        setWeight: vm.setSubtitleWeight,
        setColor: vm.setSubtitleColor,
        setAlignment: vm.setSubtitleAlignment,
        setRotation: (_) {},
        remove: (vm) => vm.setSubtitleText(''),
      );
    }

    final CanvasTextItem? item = vm.customTextItems.where((t) => t.id == id).firstOrNull;
    if (item == null) return null;
    void update(CanvasTextItem updated) => vm.updateCustomTextElement(item.id, updated);

    return _TextTarget(
      isHeadline: false,
      supportsRotation: true,
      minSize: TextSizeLimits.customMin,
      maxSize: TextSizeLimits.customMax,
      text: item.text,
      font: item.font,
      fontSize: item.fontSize,
      weight: item.weight,
      color: item.color,
      alignment: item.alignment,
      rotation: item.rotation,
      setText: (v) => update(item.copyWith(text: v)),
      setFont: (v) => update(item.copyWith(font: v)),
      setFontSize: (v) => update(item.copyWith(fontSize: v)),
      setWeight: (v) => update(item.copyWith(weight: v)),
      setColor: (v) => update(item.copyWith(color: v)),
      setAlignment: (v) => update(item.copyWith(alignment: v)),
      setRotation: (v) => update(item.copyWith(rotation: v)),
      remove: (vm) => vm.removeCustomTextElement(item.id),
    );
  }
}
