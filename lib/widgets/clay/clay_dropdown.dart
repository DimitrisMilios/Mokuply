import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import 'clay_decoration.dart';
import 'clay_popover.dart';
import 'clay_pressable.dart';

class ClayDropdownItem<T> {
  final T value;
  final String label;
  final Widget? leading;
  final IconData? icon;

  const ClayDropdownItem({required this.value, required this.label, this.leading, this.icon});
}

/// Raised clay button that opens a clay popover with the options.
/// Replaces `DropdownButton`. For a custom popover body (the font picker),
/// pass [onOpen] instead of [items] and the field only renders the button.
class ClayDropdown<T> extends StatelessWidget {
  final T? value;
  final List<ClayDropdownItem<T>> items;
  final ValueChanged<T>? onChanged;
  final String? label;
  final String? placeholder;
  final Widget? leading;
  final VoidCallback? onOpen;
  final bool expand;
  final double height;

  /// Text shown in the button when [value] is set but not in [items]
  /// (e.g. a font name with a lazy preview).
  final String? displayText;

  const ClayDropdown({
    super.key,
    this.value,
    this.items = const [],
    this.onChanged,
    this.label,
    this.placeholder,
    this.leading,
    this.onOpen,
    this.expand = true,
    this.height = 44,
    this.displayText,
  });

  Future<void> _open(BuildContext context) async {
    if (onOpen != null) {
      onOpen!();
      return;
    }
    final box = context.findRenderObject() as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    final picked = await showClayMenu<T>(
      context: context,
      anchorRect: rect,
      width: rect.width.clamp(180.0, 360.0),
      items: [
        for (final it in items)
          ClayMenuItem<T>(
            value: it.value,
            label: it.label,
            icon: it.icon,
            leading: it.leading,
            selected: it.value == value,
          ),
      ],
    );
    if (picked != null) onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null || onOpen != null;
    final current = items.where((i) => i.value == value).cast<ClayDropdownItem<T>?>().firstOrNull;
    final text = displayText ?? current?.label ?? placeholder ?? '';
    final lead = leading ?? current?.leading ?? (current?.icon != null ? Icon(current!.icon, size: 16, color: AppColors.textPrimary) : null);

    final button = Opacity(
      opacity: enabled ? 1 : 0.55,
      child: ClayPressable(
        onTap: enabled ? () => _open(context) : null,
        builder: (context, hover, press, _) {
          final h = hover.clamp(0.0, 1.0);
          return Container(
            height: height,
            padding: const EdgeInsets.only(left: 14, right: 10),
            decoration: ClayDecoration(
              radius: height / 2,
              depth: 5,
              lift: ui.lerpDouble(10, 14, h)!,
              pressed: press.clamp(0.0, 1.0),
              shadowOpacity: 0.16,
              edgeOpacity: 0.10,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (lead != null) ...[lead, const SizedBox(width: 8)],
                if (expand)
                  Expanded(child: _label(text, current == null && displayText == null))
                else
                  _label(text, current == null && displayText == null),
                const SizedBox(width: 6),
                const Icon(Icons.expand_more_rounded, size: 18, color: AppColors.textMuted),
              ],
            ),
          );
        },
      ),
    );

    if (label == null) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label!.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: AppDimensions.fontXs + 0.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
        button,
      ],
    );
  }

  Widget _label(String text, bool placeholder) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: placeholder ? AppColors.textMuted : AppColors.textPrimary,
        fontSize: AppDimensions.fontMd,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
