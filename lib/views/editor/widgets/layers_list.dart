import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../viewmodels/editor_viewmodel.dart';

/// Compact, always-visible list of everything on the active screen. Click a
/// row to select it on the canvas; hover for delete.
class LayersList extends StatelessWidget {
  final EditorViewModel vm;

  const LayersList({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final selected = vm.selectedElementId;
    final rows = <Widget>[
      _LayerRow(
        icon: Icons.title_rounded,
        name: 'Headline',
        detail: vm.titleText.isEmpty ? 'Empty' : vm.titleText,
        muted: vm.titleText.isEmpty,
        selected: selected == 'title',
        onTap: () => vm.selectElement('title'),
        onDelete: vm.titleText.isEmpty ? null : () => vm.removeElement('title'),
        deleteTooltip: 'Clear headline',
      ),
      _LayerRow(
        icon: Icons.notes_rounded,
        name: 'Subtitle',
        detail: vm.subtitleText.isEmpty ? 'Empty' : vm.subtitleText,
        muted: vm.subtitleText.isEmpty,
        selected: selected == 'subtitle',
        onTap: () => vm.selectElement('subtitle'),
        onDelete: vm.subtitleText.isEmpty ? null : () => vm.removeElement('subtitle'),
        deleteTooltip: 'Clear subtitle',
      ),
      for (final (i, d) in vm.devices.indexed)
        _LayerRow(
          icon: Icons.smartphone_rounded,
          name: 'Phone frame #${i + 1}',
          detail: d.hasAnyScreenshot ? d.frameStyle.labelFor(vm.platform) : 'No screenshot yet',
          muted: !d.hasAnyScreenshot,
          selected: selected == d.id,
          onTap: () => vm.selectElement(d.id),
          onDelete: vm.devices.length > 1 ? () => vm.removeElement(d.id) : null,
          deleteTooltip: 'Remove frame',
        ),
      for (final (i, img) in vm.customImageItems.indexed)
        _LayerRow(
          icon: Icons.image_rounded,
          name: 'Image #${i + 1}',
          detail: '${(img.scale * 100).toInt()}% · ${img.rotation.toInt()}°',
          selected: selected == img.id,
          onTap: () => vm.selectElement(img.id),
          onDelete: () => vm.removeElement(img.id),
          deleteTooltip: 'Delete image',
          thumbnail: img.imageBytes,
        ),
      for (final (i, t) in vm.customTextItems.indexed)
        _LayerRow(
          icon: Icons.text_fields_rounded,
          name: 'Text #${i + 1}',
          detail: t.text,
          selected: selected == t.id,
          onTap: () => vm.selectElement(t.id),
          onDelete: () => vm.removeElement(t.id),
          deleteTooltip: 'Delete text',
        ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }
}

class _LayerRow extends StatefulWidget {
  final IconData icon;
  final String name;
  final String detail;
  final bool muted;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String deleteTooltip;
  final Uint8List? thumbnail;

  const _LayerRow({
    required this.icon,
    required this.name,
    required this.detail,
    this.muted = false,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.deleteTooltip,
    this.thumbnail,
  });

  @override
  State<_LayerRow> createState() => _LayerRowState();
}

class _LayerRowState extends State<_LayerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bool sel = widget.selected;
    final Color fg = sel ? AppColors.textOnPrimary : AppColors.textPrimary;
    final Color sub = sel ? AppColors.textOnPrimary.withValues(alpha: 0.75) : AppColors.textMuted;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 32,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.only(left: 8, right: 2),
          decoration: BoxDecoration(
            color: sel
                ? AppColors.primary
                : (_hover ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.thumbnail != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(width: 18, height: 18, child: Image.memory(widget.thumbnail!, fit: BoxFit.cover)),
                )
              else
                Icon(widget.icon, size: 16, color: widget.muted && !sel ? AppColors.textMuted : fg),
              const SizedBox(width: 8),
              Text(
                widget.name,
                style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 10.5,
                    fontStyle: widget.muted ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              if (widget.onDelete != null && (_hover || sel))
                IconButton(
                  onPressed: widget.onDelete,
                  tooltip: widget.deleteTooltip,
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  icon: Icon(Icons.delete_outline_rounded, size: 15, color: sel ? fg : AppColors.error),
                )
              else
                const SizedBox(width: 26),
            ],
          ),
        ),
      ),
    );
  }
}
