import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/motion/clay_motion.dart';
import 'clay_decoration.dart';
import 'clay_icon_button.dart';

/// Shows a clay dialog: barrier is `sandDeep` at 0.6 instead of black, the
/// panel scales 0.92 → 1.0 and rises 24 px with a bouncy spring.
Future<T?> showClayDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,

  /// Global position the dialog grows from (the colour knob). Defaults to centre.
  Offset? origin,
}) {
  final motion = ClayMotion.of(context);
  final size = MediaQuery.sizeOf(context);
  final alignment = origin == null
      ? Alignment.center
      : Alignment((origin.dx / size.width) * 2 - 1, (origin.dy / size.height) * 2 - 1);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: AppColors.sandDeep.withValues(alpha: 0.6),
    transitionDuration: motion.enabled ? const Duration(milliseconds: 480) : const Duration(milliseconds: 140),
    pageBuilder: (context, animation, secondary) => Center(child: builder(context)),
    transitionBuilder: (context, animation, secondary, child) {
      final reverse = animation.status == AnimationStatus.reverse;
      final spring = motion.enabled
          ? ClaySpringCurve(ClaySprings.bouncy, settleDuration: const Duration(milliseconds: 480))
          : Curves.easeOut;
      final t = reverse ? Curves.easeIn.transform(animation.value) : spring.transform(animation.value);
      final scale = reverse ? 0.96 + 0.04 * t : 0.92 + 0.08 * t;
      final rise = reverse ? 0.0 : 24.0 * (1 - t);
      return Opacity(
        opacity: Curves.easeOut.transform(animation.value.clamp(0.0, 1.0)),
        child: Transform.translate(
          offset: Offset(0, rise),
          child: Transform.scale(scale: scale, alignment: alignment, child: child),
        ),
      );
    },
  );
}

/// `Dialog` wrapper: a clay panel with an optional header row (icon tile,
/// title, subtitle, close button) and staggered content.
class ClayDialog extends StatelessWidget {
  final Widget child;
  final double width;
  final String? title;
  final String? subtitle;
  final Widget? headerIcon;
  final bool showClose;
  final EdgeInsetsGeometry padding;
  final List<Widget>? actions;

  /// Wrap the contents in a scroll view. Set false when the child owns its
  /// own scrolling (a lazy list).
  final bool scrollable;

  const ClayDialog({
    super.key,
    required this.child,
    this.width = 560,
    this.title,
    this.subtitle,
    this.headerIcon,
    this.showClose = true,
    this.padding = const EdgeInsets.all(28),
    this.actions,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final motion = ClayMotion.of(context);
    final children = <Widget>[
      if (title != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerIcon != null) ...[
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: const ClayDecoration.well(radius: AppDimensions.radiusClaySm, depth: 4),
                  child: headerIcon,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: AppDimensions.fontXl,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: AppDimensions.fontMd,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (showClose) ...[
                const SizedBox(width: 12),
                ClayIconButton(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  size: 36,
                  iconSize: 18,
                  flat: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ],
          ),
        ),
      child,
      if (actions != null && actions!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (var i = 0; i < actions!.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                actions![i],
              ],
            ],
          ),
        ),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 32),
        padding: padding,
        decoration: const ClayDecoration(
          color: AppColors.clay,
          radius: AppDimensions.radiusClayLg,
          depth: AppDimensions.clayDepth,
          lift: 24,
          shadowOpacity: 0.26,
        ),
        child: _maybeScroll(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++)
                ClayStagger(index: i, delay: motion.stagger, child: children[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _maybeScroll(Widget child) => scrollable ? SingleChildScrollView(child: child) : child;
}

/// Fades and rises a child in after `index * delay`. Used for dialog
/// contents, layer rows and panel entrances.
class ClayStagger extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final double rise;

  const ClayStagger({
    super.key,
    required this.child,
    required this.index,
    this.delay = ClayDurations.stagger,
    this.rise = 10,
  });

  @override
  State<ClayStagger> createState() => _ClayStaggerState();
}

class _ClayStaggerState extends State<ClayStagger> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    final delay = widget.delay * widget.index;
    if (widget.delay == Duration.zero) {
      _c.value = 1;
    } else {
      Future<void>.delayed(delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = ClaySpringCurve.gentle.transform(_c.value);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, widget.rise * (1 - t)), child: child),
        );
      },
    );
  }
}
