import 'package:flutter/material.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/color_swatch_button.dart';

/// Weight dropdown, alignment segments and colour swatch of a text element.
class TextStyleRow extends StatelessWidget {
  final FontWeight weight;
  final TextAlign alignment;
  final Color color;
  final ValueChanged<FontWeight> onWeight;
  final ValueChanged<TextAlign> onAlignment;
  final ValueChanged<Color> onColor;

  const TextStyleRow({
    super.key,
    required this.weight,
    required this.alignment,
    required this.color,
    required this.onWeight,
    required this.onAlignment,
    required this.onColor,
  });

  static const Map<String, FontWeight> _weights = {
    'Light': FontWeight.w300,
    'Regular': FontWeight.w400,
    'Medium': FontWeight.w500,
    'SemiBold': FontWeight.w600,
    'Bold': FontWeight.w700,
    'ExtraBold': FontWeight.w800,
    'Black': FontWeight.w900,
  };

  static const Map<TextAlign, (IconData, String)> _alignments = {
    TextAlign.left: (Icons.format_align_left_rounded, 'Align left'),
    TextAlign.center: (Icons.format_align_center_rounded, 'Align centre'),
    TextAlign.right: (Icons.format_align_right_rounded, 'Align right'),
  };

  @override
  Widget build(BuildContext context) {
    final weightName = _weights.entries.firstWhere((e) => e.value == weight, orElse: () => _weights.entries.first).key;

    return Row(
      children: [
        Expanded(
          child: ClayDropdown<String>(
            value: weightName,
            height: 40,
            items: [for (final k in _weights.keys) ClayDropdownItem(value: k, label: k)],
            onChanged: (k) {
              final w = _weights[k];
              if (w != null) onWeight(w);
            },
          ),
        ),
        const SizedBox(width: 8),
        ClaySegmented<TextAlign>(
          height: 40,
          segmentWidth: 38,
          segments: [
            for (final MapEntry(key: align, value: (icon, tip)) in _alignments.entries)
              ClaySegment(value: align, icon: icon, tooltip: tip),
          ],
          selected: _alignments.containsKey(alignment) ? alignment : TextAlign.left,
          onChanged: onAlignment,
        ),
        const SizedBox(width: 8),
        ColorSwatchButton(color: color, onColorChanged: onColor, size: 32),
      ],
    );
  }
}
