import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/template_data.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/thumbnail_image.dart';
import 'layer_entry.dart';

/// Compact, always-visible list of everything on the active screen, sitting
/// in a sunken well. Click a row to select it on the canvas; hover for
/// delete. Rows stagger in when the active screen changes.
class LayersList extends StatelessWidget {
  const LayersList({super.key});

  @override
  Widget build(BuildContext context) {
    final (screen, screenIndex, selected, platform) = context
        .select<EditorViewModel, (TemplateData, int, String?, TargetPlatformType)>(
          (vm) => (vm.data, vm.selectedIndex, vm.selectedElementId, vm.platform),
        );
    final vm = context.read<EditorViewModel>();
    final entries = LayerEntry.of(screen, platform);
    final staggerDelay = ClayMotion.of(context).enabled ? const Duration(milliseconds: 20) : Duration.zero;

    return ClayWell(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, entry) in entries.indexed)
            // Keyed by the active screen so the stagger replays on screen
            // change but not on every selection change.
            ClayStagger(
              key: ValueKey('layers-$screenIndex-${entry.id}'),
              index: i,
              delay: staggerDelay,
              rise: 6,
              child: Padding(
                padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 2),
                child: _LayerRow(
                  entry: entry,
                  selected: selected == entry.id,
                  onTap: () => vm.selectElement(entry.id),
                  onDelete: entry.canDelete ? () => vm.removeElement(entry.id) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LayerRow extends StatefulWidget {
  final LayerEntry entry;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _LayerRow({required this.entry, required this.selected, required this.onTap, required this.onDelete});

  @override
  State<_LayerRow> createState() => _LayerRowState();
}

class _LayerRowState extends State<_LayerRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final bool sel = widget.selected;
    final Color fg = sel ? AppColors.primaryDeep : AppColors.textPrimary;
    final Color sub = sel ? AppColors.textSecondary : AppColors.textMuted;
    final bool showDelete = widget.onDelete != null && (_hover || sel);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: ClayTile(
        selected: sel,
        onTap: widget.onTap,
        radius: 12,
        height: 34,
        padding: const EdgeInsets.only(left: 8, right: 4),
        child: Row(
          children: [
            if (entry.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: ThumbnailImage(bytes: entry.thumbnail!, width: 18, height: 18),
              )
            else
              Icon(entry.icon, size: 16, color: entry.muted && !sel ? AppColors.textMuted : fg),
            const SizedBox(width: 8),
            Text(
              entry.name,
              style: TextStyle(color: fg, fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: sub,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  fontStyle: entry.muted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
            SizedBox(
              width: 26,
              height: 26,
              child: showDelete
                  ? ClayIconButton(
                      icon: Icons.delete_outline_rounded,
                      tooltip: entry.deleteTooltip,
                      size: 26,
                      iconSize: 15,
                      radius: 9,
                      flat: true,
                      danger: true,
                      onPressed: widget.onDelete,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
