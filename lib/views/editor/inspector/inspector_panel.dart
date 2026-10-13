import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'inspector_parts.dart';
import 'inspector_target.dart';
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
    final selection = context.select<EditorViewModel, InspectorFocus>(InspectorFocus.of);
    final target = InspectorTarget.resolve(selection);
    final motion = ClayMotion.of(context);
    final double expandedWidth = (MediaQuery.sizeOf(context).width - 220).clamp(240.0, AppDimensions.sidebarWidth);

    return AnimatedContainer(
      duration: motion.enabled ? const Duration(milliseconds: 450) : const Duration(milliseconds: 120),
      curve: motion.enabled ? ClaySpringCurve.gentle : Curves.easeOut,
      width: _isCollapsed ? _collapsedWidth : expandedWidth,
      child: ClayPanel(
        padding: EdgeInsets.zero,
        clipBehavior: Clip.hardEdge,
        child: _isCollapsed
            ? _collapsed(target)
            // Laid out at the full width and clipped while the width animates,
            // so rows never try to fit a half-collapsed panel.
            : OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: expandedWidth,
                maxWidth: expandedWidth,
                child: _expanded(selection, target, motion),
              ),
      ),
    );
  }

  void _setCollapsed(bool value) => setState(() => _isCollapsed = value);

  Widget _collapsed(InspectorTarget target) {
    return Column(
      children: [
        const SizedBox(height: 10),
        ClayIconButton(
          icon: Icons.keyboard_double_arrow_left_rounded,
          tooltip: 'Expand inspector',
          size: 36,
          iconSize: 18,
          iconColor: AppColors.primary,
          onPressed: () => _setCollapsed(false),
        ),
        const SizedBox(height: 10),
        ClayIconButton(
          icon: target.icon,
          tooltip: target.title,
          size: 36,
          iconSize: 20,
          flat: true,
          iconColor: AppColors.primary,
          onPressed: () => _setCollapsed(false),
        ),
      ],
    );
  }

  Widget _expanded(InspectorFocus selection, InspectorTarget target, ClayMotion motion) {
    return Column(
      children: [
        InspectorHeader(selection: selection, onCollapse: () => _setCollapsed(true)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, AppDimensions.spacingLg),
            children: [
              InspectorSectionHeader(
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
                child: _layersOpen ? const LayersList() : const SizedBox(width: double.infinity),
              ),
              const SizedBox(height: AppDimensions.spacingXl),
              // The whole body (target row + panel) crossfades: the old one
              // sinks 8 px and fades, the new one rises from 8 px.
              AnimatedSwitcher(
                duration: ClayDurations.crossfade,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: _bodyTransition,
                layoutBuilder: (current, previous) =>
                    Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
                child: KeyedSubtree(
                  key: ValueKey(selection.bodyKey),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      InspectorTargetRow(target: target, elementSelected: selection.elementId != null),
                      const SizedBox(height: AppDimensions.spacingMd),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: InspectorSafeBody(elementId: target.elementId, child: target.body),
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
    // Incoming rises from +8 px; outgoing runs the same animation in reverse.
    return FadeTransition(
      opacity: animation,
      child: AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Transform.translate(offset: Offset(0, 8 * (1 - animation.value)), child: child),
      ),
    );
  }
}
