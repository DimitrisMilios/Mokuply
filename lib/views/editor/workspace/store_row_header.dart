import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../widgets/clay/clay.dart';
import 'workspace_layout.dart';

/// Header above a store row: store, device and export size. The active
/// store (the one uploads target) is a raised primary clay pill; the other
/// is flat muted text. Click a row to activate it.
class StoreRowHeader extends StatefulWidget {
  final TargetPlatformType store;
  final bool active;
  final bool showBoth;
  final bool previewing;
  final VoidCallback onTap;
  final VoidCallback onToggleBoth;

  const StoreRowHeader({
    super.key,
    required this.store,
    required this.active,
    required this.showBoth,
    required this.previewing,
    required this.onTap,
    required this.onToggleBoth,
  });

  @override
  State<StoreRowHeader> createState() => _StoreRowHeaderState();
}

class _StoreRowHeaderState extends State<StoreRowHeader> with SingleTickerProviderStateMixin {
  late final AnimationController _active;
  late bool _wasHighlighted;

  bool get _highlighted => widget.active && !widget.previewing;

  @override
  void initState() {
    super.initState();
    _wasHighlighted = _highlighted;
    _active = AnimationController.unbounded(vsync: this, value: _wasHighlighted ? 1 : 0);
  }

  @override
  void didUpdateWidget(StoreRowHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final on = _highlighted;
    if (on != _wasHighlighted) {
      _wasHighlighted = on;
      final motion = ClayMotion.of(context);
      _active.springTo(on ? 1 : 0, spring: on ? motion.bouncy : motion.snappy);
    }
  }

  @override
  void dispose() {
    _active.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    const double radius = WorkspaceLayout.rowHeaderHeight / 2;

    Widget pill = ClayPressable(
      onTap: widget.previewing ? null : widget.onTap,
      squash: 0.05,
      builder: (context, hover, press, _) {
        final double h = hover.clamp(0.0, 1.0);
        final double p = press.clamp(0.0, 1.0);
        return AnimatedBuilder(
          animation: _active,
          builder: (context, _) {
            final double t = _active.value.clamp(0.0, 1.15);
            final raised = ClayDecoration.primary(radius: radius, lift: 8, pressed: p);
            final idle = ClayDecoration(
              color: AppColors.mint.withValues(alpha: 0.4 * h),
              radius: radius,
              depth: 5,
              lift: 0,
              shadowOpacity: 0,
              highlightOpacity: 0,
              shadeOpacity: 0,
              edgeOpacity: 0,
            );
            final deco = ClayDecoration.lerp(idle, raised, t)!;
            final Color fg = Color.lerp(AppColors.textMuted, AppColors.textOnPrimary, t.clamp(0.0, 1.0))!;

            return Container(
              height: WorkspaceLayout.rowHeaderHeight,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: deco,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(store == TargetPlatformType.appStore ? Icons.apple : Icons.android, size: 14, color: fg),
                  const SizedBox(width: 6),
                  Text(
                    '${store.shortName} · ${store.deviceName}',
                    style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    store.dimensionsLabel,
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!widget.previewing) {
      pill = Tooltip(
        message: widget.active ? 'Active store: uploads go here' : 'Click to make this the active store',
        child: pill,
      );
    }

    return SizedBox(
      height: WorkspaceLayout.rowHeaderHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill,
          if (!widget.previewing && !widget.showBoth) ...[
            const SizedBox(width: 6),
            ClayButton.text(
              label: 'Both stores',
              icon: Icons.view_agenda_outlined,
              size: ClayButtonSize.compact,
              onPressed: widget.onToggleBoth,
            ),
          ],
        ],
      ),
    );
  }
}
