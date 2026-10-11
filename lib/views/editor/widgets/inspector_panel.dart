import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';
import '../panels/frame_inspector.dart';
import '../panels/image_inspector.dart';
import '../panels/screen_inspector.dart';
import '../panels/text_inspector.dart';
import 'layers_list.dart';

/// Right-hand inspector: the active screen's layers on top (always visible),
/// then the properties of whatever is selected — a text element, a phone
/// frame, an image, or (nothing selected) the screen itself.
class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key});

  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  bool _isCollapsed = false;
  bool _layersOpen = true;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double expandedWidth = (screenWidth - 220).clamp(240.0, AppDimensions.sidebarWidth);
    final target = _InspectorTarget.resolve(vm);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutCubic,
      width: _isCollapsed ? 56.0 : expandedWidth,
      child: GlassContainer(
        opacity: 0.85,
        blurX: 16.0,
        blurY: 16.0,
        borderRadius: BorderRadius.circular(AppDimensions.radiusGlassLg),
        borderColor: AppColors.glassBorder,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        padding: EdgeInsets.zero,
        child: _isCollapsed
            ? _buildCollapsed(target)
            // Laid out at the full width and clipped while the width animates, so
            // rows never try to fit a half-collapsed panel.
            : OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: expandedWidth,
                maxWidth: expandedWidth,
                child: _buildExpanded(vm, target),
              ),
      ),
    );
  }

  Widget _buildCollapsed(_InspectorTarget target) {
    return Column(
      children: [
        const SizedBox(height: 8),
        IconButton(
          onPressed: () => setState(() => _isCollapsed = false),
          tooltip: 'Expand inspector',
          icon: const Icon(Icons.keyboard_double_arrow_left_rounded, color: AppColors.primary, size: 20),
        ),
        const Divider(color: AppColors.glassBorder, indent: 10, endIndent: 10),
        IconButton(
          onPressed: () => setState(() => _isCollapsed = false),
          tooltip: target.title,
          icon: Icon(target.icon, color: AppColors.primary, size: 22),
        ),
      ],
    );
  }

  Widget _buildExpanded(EditorViewModel vm, _InspectorTarget target) {
    return Column(
      children: [
        // Screen header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.glassBorder, width: 1.0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.crop_portrait_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vm.screenNameAt(vm.selectedIndex),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                '${vm.selectedIndex + 1}/${vm.screenshotsCount}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
              ),
              IconButton(
                onPressed: () => setState(() => _isCollapsed = true),
                tooltip: 'Collapse inspector',
                splashRadius: 18,
                icon: const Icon(Icons.keyboard_double_arrow_right_rounded, color: AppColors.primary, size: 20),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, AppDimensions.spacingMd),
            children: [
              // Layers
              _SectionHeader(
                label: 'Layers',
                trailing: IconButton(
                  onPressed: () => setState(() => _layersOpen = !_layersOpen),
                  tooltip: _layersOpen ? 'Hide layers' : 'Show layers',
                  splashRadius: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  icon: Icon(
                    _layersOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              if (_layersOpen) LayersList(vm: vm),
              const SizedBox(height: 8),
              const Divider(color: AppColors.glassBorder, height: 1),
              const SizedBox(height: 8),

              // Properties of the selection
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Icon(target.icon, color: AppColors.primary, size: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          target.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          target.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  if (vm.selectedElementId != null)
                    IconButton(
                      onPressed: () => vm.selectElement(null),
                      tooltip: 'Back to screen settings (Esc)',
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: target.body),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Which inspector to show for the current selection.
class _InspectorTarget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget body;

  const _InspectorTarget({required this.icon, required this.title, required this.subtitle, required this.body});

  static _InspectorTarget resolve(EditorViewModel vm) {
    final id = vm.selectedElementId;

    if (id == 'title') {
      return const _InspectorTarget(
        icon: Icons.title_rounded,
        title: 'Headline',
        subtitle: 'Drag to move · corner handles resize',
        body: TextInspector(elementId: 'title'),
      );
    }
    if (id == 'subtitle') {
      return const _InspectorTarget(
        icon: Icons.notes_rounded,
        title: 'Subtitle',
        subtitle: 'Drag to move · corner handles resize',
        body: TextInspector(elementId: 'subtitle'),
      );
    }
    if (id != null && id.startsWith('txt_') && vm.customTextItems.any((t) => t.id == id)) {
      return _InspectorTarget(
        icon: Icons.text_fields_rounded,
        title: 'Text element',
        subtitle: 'Drag, resize and rotate on the canvas',
        body: TextInspector(elementId: id),
      );
    }
    if (id != null && id.startsWith('dev_') && vm.devices.any((d) => d.id == id)) {
      final index = vm.devices.indexWhere((d) => d.id == id);
      return _InspectorTarget(
        icon: Icons.smartphone_rounded,
        title: 'Phone frame #${index + 1}',
        subtitle: 'Screenshots, style, size and tilt',
        body: FrameInspector(deviceId: id),
      );
    }
    if (id != null && id.startsWith('img_') && vm.customImageItems.any((i) => i.id == id)) {
      final index = vm.customImageItems.indexWhere((i) => i.id == id);
      return _InspectorTarget(
        icon: Icons.image_rounded,
        title: 'Image #${index + 1}',
        subtitle: 'Size, tilt, opacity and shadow',
        body: ImageInspector(imageId: id),
      );
    }

    return const _InspectorTarget(
      icon: Icons.tune_rounded,
      title: 'Screen',
      subtitle: 'Layout and backdrop · click anything on the canvas to edit it',
      body: ScreenInspector(),
    );
  }
}
