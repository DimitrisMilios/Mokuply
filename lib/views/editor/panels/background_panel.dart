import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import '../../../widgets/shared/color_swatch_button.dart';

/// Background image, preset gradients and solid colour for the active screen.
class BackgroundSection extends StatelessWidget {
  const BackgroundSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<EditorViewModel>(context);
    final bgBytes = vm.customBackgroundImageBytes;
    final hasBgImage = bgBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Background image ---
        const ClayLabel('Background image'),
        const SizedBox(height: 4),
        const Text(
          'One image per screen, shared by both stores.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
        ),
        const SizedBox(height: 10),
        if (hasBgImage) ...[
          ClayWell(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusClaySm - 6),
                  child: SizedBox(
                    width: 84,
                    height: 56,
                    child: Image.memory(bgBytes, fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ClayButton.neutral(
                    label: 'Change',
                    icon: Icons.image_rounded,
                    size: ClayButtonSize.compact,
                    expand: true,
                    onPressed: () => vm.pickCustomBackgroundImage(),
                  ),
                ),
                const SizedBox(width: 4),
                ClayButton.text(
                  label: 'Remove',
                  danger: true,
                  size: ClayButtonSize.compact,
                  onPressed: () => vm.setCustomBackgroundImage(null),
                ),
              ],
            ),
          ),
        ] else
          ClayButton.primary(
            label: 'Upload image',
            icon: Icons.add_photo_alternate_rounded,
            expand: true,
            onPressed: () => vm.pickCustomBackgroundImage(),
          ),

        const SizedBox(height: AppDimensions.spacingXl),

        // --- Preset gradients ---
        const ClayLabel('Gradients'),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          clipBehavior: Clip.none,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
          ),
          itemCount: StoreSpecs.gradientPresets.length,
          itemBuilder: (ctx, index) {
            final preset = StoreSpecs.gradientPresets[index];
            final isSelected = vm.selectedGradientIndex == index && vm.customBackgroundColor == null && !hasBgImage;
            return _GradientSlab(
              preset: preset,
              selected: isSelected,
              onTap: () {
                if (hasBgImage) vm.setCustomBackgroundImage(null);
                vm.setGradientIndex(index);
              },
            );
          },
        ),

        const SizedBox(height: AppDimensions.spacingXl),

        // --- Solid colour ---
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClayLabel('Solid colour'),
                  SizedBox(height: 2),
                  Text(
                    'Replaces the gradient.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ColorSwatchButton(
              color: vm.customBackgroundColor ?? AppColors.clay,
              onColorChanged: (c) {
                if (hasBgImage) vm.setCustomBackgroundImage(null);
                vm.setCustomBackgroundColor(c);
              },
              size: 36,
              showIcon: vm.customBackgroundColor == null,
            ),
          ],
        ),
      ],
    );
  }
}

/// One gradient preset: a small raised clay slab whose fill is the gradient.
/// The selected preset sits sunken in the panel.
///
/// Layers, bottom to top: the floating shadow (its own layer so it never
/// bleeds over the gradient), the clipped gradient, then a transparent clay
/// surface that only draws the inner highlight / shade pair.
class _GradientSlab extends StatefulWidget {
  final ColorGradientPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _GradientSlab({required this.preset, required this.selected, required this.onTap});

  @override
  State<_GradientSlab> createState() => _GradientSlabState();
}

class _GradientSlabState extends State<_GradientSlab> with SingleTickerProviderStateMixin {
  static const double _radius = 14;
  late final AnimationController _sel;

  @override
  void initState() {
    super.initState();
    _sel = AnimationController.unbounded(vsync: this, value: widget.selected ? 1 : 0);
  }

  @override
  void didUpdateWidget(_GradientSlab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      final motion = ClayMotion.of(context);
      _sel.springTo(widget.selected ? 1 : 0, spring: widget.selected ? motion.snappy : motion.bouncy);
    }
  }

  @override
  void dispose() {
    _sel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = widget.preset;
    final labelColor = preset.colors.first.computeLuminance() > 0.5 ? AppColors.textPrimary : Colors.white;

    return Tooltip(
      message: preset.name,
      child: ClayPressable(
        onTap: widget.onTap,
        squash: 0.05,
        builder: (context, hover, press, _) {
          return AnimatedBuilder(
            animation: _sel,
            builder: (context, _) {
              final s = _sel.value.clamp(0.0, 1.0);
              final h = hover.clamp(0.0, 1.0);
              final p = press.clamp(0.0, 1.0);
              // Sunk amount: fully when selected, partly while pressed.
              final sunk = (s + p * (1 - s)).clamp(0.0, 1.0);

              return Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  // 1. Floating shadow, fades out as the slab sinks.
                  DecoratedBox(
                    decoration: ClayDecoration(
                      color: Colors.transparent,
                      radius: _radius,
                      depth: 0,
                      lift: 8 + 4 * h,
                      shadowOpacity: 0.18 * (1 - sunk),
                      highlightOpacity: 0,
                      shadeOpacity: 0,
                    ),
                  ),
                  // 2. The gradient itself.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_radius),
                    child: DecoratedBox(decoration: preset.toDecoration()),
                  ),
                  // 3. Inner lighting pair over the gradient; inverts when sunk.
                  DecoratedBox(
                    decoration: ClayDecoration(
                      color: Colors.transparent,
                      radius: _radius,
                      depth: 4,
                      lift: 0,
                      pressed: sunk,
                      shadowOpacity: 0,
                      highlightOpacity: 0.6,
                      shadeOpacity: 0.32 + 0.1 * sunk,
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        preset.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: labelColor,
                          fontSize: AppDimensions.fontXs,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
