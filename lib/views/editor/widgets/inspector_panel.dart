import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
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
  static const double _collapsedWidth = 56.0;

  bool _isCollapsed = false;
  bool _layersOpen = true;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final motion = ClayMotion.of(context);
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double expandedWidth = (screenWidth - 220).clamp(240.0, AppDimensions.sidebarWidth);
    final target = _InspectorTarget.resolve(vm);

    return AnimatedContainer(
      duration: motion.enabled ? const Duration(milliseconds: 450) : const Duration(milliseconds: 120),
      curve: motion.enabled ? ClaySpringCurve.gentle : Curves.easeOut,
      width: _isCollapsed ? _collapsedWidth : expandedWidth,
      child: ClayPanel(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
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
        const SizedBox(height: 10),
        ClayIconButton(
          icon: Icons.keyboard_double_arrow_left_rounded,
          tooltip: 'Expand inspector',
          size: 36,
          iconSize: 18,
          iconColor: AppColors.primary,
          onPressed: () => setState(() => _isCollapsed = false),
        ),
        const SizedBox(height: 10),
        ClayIconButton(
          icon: target.icon,
          tooltip: target.title,
          size: 36,
          iconSize: 20,
          flat: true,
          iconColor: AppColors.primary,
          onPressed: () => setState(() => _isCollapsed = false),
        ),
      ],
    );
  }

  Widget _buildExpanded(EditorViewModel vm, _InspectorTarget target) {
    final motion = ClayMotion.of(context);
    final selectionKey = ValueKey('${vm.selectedIndex}:${vm.selectedElementId ?? 'screen:${vm.screenSection.name}'}');

    return Column(
      children: [
        // Screen header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 10, 4),
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
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Text(
                '${vm.selectedIndex + 1}/${vm.screenshotsCount}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 8),
              ClayIconButton(
                icon: Icons.keyboard_double_arrow_right_rounded,
                tooltip: 'Collapse inspector',
                size: 32,
                iconSize: 18,
                flat: true,
                iconColor: AppColors.primary,
                onPressed: () => setState(() => _isCollapsed = true),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, AppDimensions.spacingLg),
            children: [
              // Layers
              _SectionHeader(
                label: 'Layers',
                trailing: ClayIconButton(
                  icon: _layersOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  tooltip: _layersOpen ? 'Hide layers' : 'Show layers',
                  size: 26,
                  iconSize: 18,
                  radius: 9,
                  flat: true,
                  iconColor: AppColors.textMuted,
                  onPressed: () => setState(() => _layersOpen = !_layersOpen),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSize(
                duration: motion.enabled ? const Duration(milliseconds: 450) : const Duration(milliseconds: 120),
                curve: motion.enabled ? ClaySpringCurve.gentle : Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _layersOpen ? LayersList(vm: vm) : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: AppDimensions.spacingXl),

              // Properties of the selection. The whole body (target row + panel)
              // crossfades: old slides down 8 px and fades, new rises from 8 px.
              AnimatedSwitcher(
                duration: ClayDurations.crossfade,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: _bodyTransition,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...previous, ?current],
                ),
                child: KeyedSubtree(
                  key: selectionKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TargetRow(target: target, vm: vm),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _SafeBody(elementId: target.elementId, child: target.body),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _bodyTransition(Widget child, Animation<double> animation) {
    // Incoming: 0 → 1 rises from +8 px. Outgoing runs the same animation in
    // reverse, so it sinks back down 8 px while it fades.
    final slide = Tween<Offset>(begin: const Offset(0, 8), end: Offset.zero).animate(animation);
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: slide,
        child: child,
        builder: (context, child) => Transform.translate(offset: slide.value, child: child),
      ),
    );
  }
}

class _TargetRow extends StatelessWidget {
  final _InspectorTarget target;
  final EditorViewModel vm;

  const _TargetRow({required this.target, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClayContainer(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const ClayDecoration.well(radius: 12, depth: 4),
          child: Icon(target.icon, color: AppColors.primary, size: 17),
        ),
        const SizedBox(width: 10),
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
                  fontSize: AppDimensions.fontBody,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                target.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (vm.selectedElementId != null)
          ClayIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Back to screen settings (Esc)',
            size: 28,
            iconSize: 16,
            radius: 10,
            flat: true,
            iconColor: AppColors.textMuted,
            onPressed: () => vm.selectElement(null),
          ),
      ],
    );
  }
}

/// The outgoing body of the crossfade stays mounted for 180 ms after the
/// selection changes. If its element was just deleted, build nothing instead
/// of asking a panel for an element that no longer exists.
class _SafeBody extends StatelessWidget {
  final String? elementId;
  final Widget child;

  const _SafeBody({required this.elementId, required this.child});

  @override
  Widget build(BuildContext context) {
    final id = elementId;
    if (id == null) return child;
    final exists = context.select<EditorViewModel, bool>((vm) => vm.elementExists(id));
    return exists ? child : const SizedBox.shrink();
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
          Expanded(child: ClayLabel(label)),
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

  /// The canvas element this body edits, or null for the screen itself.
  final String? elementId;

  const _InspectorTarget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    this.elementId,
  });

  static const String _canvasHint = 'Drag to move, corners to resize, top handle to rotate.';

  static _InspectorTarget resolve(EditorViewModel vm) {
    final id = vm.selectedElementId;

    if (id == 'title') {
      return const _InspectorTarget(
        icon: Icons.title_rounded,
        title: 'Headline',
        subtitle: _canvasHint,
        body: TextInspector(elementId: 'title'),
      );
    }
    if (id == 'subtitle') {
      return const _InspectorTarget(
        icon: Icons.notes_rounded,
        title: 'Subtitle',
        subtitle: _canvasHint,
        body: TextInspector(elementId: 'subtitle'),
      );
    }
    if (id != null && id.startsWith('txt_') && vm.customTextItems.any((t) => t.id == id)) {
      return _InspectorTarget(
        icon: Icons.text_fields_rounded,
        title: 'Text element',
        subtitle: _canvasHint,
        body: TextInspector(elementId: id),
        elementId: id,
      );
    }
    if (id != null && id.startsWith('dev_') && vm.devices.any((d) => d.id == id)) {
      final index = vm.devices.indexWhere((d) => d.id == id);
      return _InspectorTarget(
        icon: Icons.smartphone_rounded,
        title: 'Phone frame #${index + 1}',
        subtitle: 'Screenshots, style, size and tilt',
        body: FrameInspector(deviceId: id),
        elementId: id,
      );
    }
    if (id != null && id.startsWith('img_') && vm.customImageItems.any((i) => i.id == id)) {
      final index = vm.customImageItems.indexWhere((i) => i.id == id);
      return _InspectorTarget(
        icon: Icons.image_rounded,
        title: 'Image #${index + 1}',
        subtitle: 'Size, tilt, opacity and shadow',
        body: ImageInspector(imageId: id),
        elementId: id,
      );
    }

    return const _InspectorTarget(
      icon: Icons.tune_rounded,
      title: 'Screen',
      subtitle: 'Layout and backdrop. Click anything on the canvas to edit it.',
      body: ScreenInspector(),
    );
  }
}
