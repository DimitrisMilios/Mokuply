import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/canvas_text_item.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/color_swatch_button.dart';
import '../../../widgets/shared/font_picker_field.dart';
import '../../../widgets/shared/labeled_slider.dart';

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

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final target = _TextTarget.resolve(vm, widget.elementId);
    if (target == null) {
      return const Text('This text element no longer exists.', style: TextStyle(color: AppColors.textMuted));
    }

    // Keep the field in sync when selection changes, without fighting the caret while typing.
    if (_controller.text != target.text) {
      _controller.value = TextEditingValue(
        text: target.text,
        selection: TextSelection.collapsed(offset: target.text.length),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: target.setText,
          maxLines: 3,
          minLines: 1,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: AppDimensions.fontMd, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'Text',
            hintText: target.isHeadline ? 'Leave empty to hide' : null,
            labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        FontPickerField(value: target.font, onChanged: target.setFont),
        const SizedBox(height: 12),
        LabeledSlider(
          label: 'Size',
          valueText: '${target.fontSize.toInt()}px',
          value: target.fontSize.clamp(target.minSize, target.maxSize),
          min: target.minSize,
          max: target.maxSize,
          onChanged: target.setFontSize,
        ),
        const SizedBox(height: 10),
        _buildWeightAlignColorRow(target),
        if (target.supportsRotation) ...[
          const SizedBox(height: 10),
          LabeledSlider(
            label: 'Rotation',
            valueText: '${target.rotation.toInt()}°',
            value: target.rotation,
            min: -180.0,
            max: 180.0,
            onChanged: target.setRotation,
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Drag the text on the canvas to move it. Position is shared by both stores.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => target.remove(vm),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
            minimumSize: const Size.fromHeight(36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
          ),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: Text(
            target.isHeadline ? 'Clear text' : 'Delete text element',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentWeightName,
              dropdownColor: Colors.white,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primary, size: 18),
              items: _weightOptions.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
              onChanged: (k) {
                if (k != null && _weightOptions.containsKey(k)) target.setWeight(_weightOptions[k]!);
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        for (final entry in const {
          TextAlign.left: Icons.format_align_left_rounded,
          TextAlign.center: Icons.format_align_center_rounded,
          TextAlign.right: Icons.format_align_right_rounded,
        }.entries)
          InkWell(
            onTap: () => target.setAlignment(entry.key),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.all(5),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: target.alignment == entry.key ? AppColors.primary : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                entry.value,
                size: 14,
                color: target.alignment == entry.key ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        const Spacer(),
        ColorSwatchButton(color: target.color, onColorChanged: target.setColor, size: 30),
      ],
    );
  }
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
        minSize: 40,
        maxSize: 280,
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
        minSize: 20,
        maxSize: 160,
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
      minSize: 16,
      maxSize: 200,
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
