import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

/// Hero for HomeView: headline, subtitle and the two calls to action on the
/// left, the Blender hero render on the right. Below 960 px the render drops
/// under the text at 60 % of the available width.
class HeroSection extends StatelessWidget {
  /// Scrolls the page to the template grid ("Browse templates").
  final VoidCallback? onBrowseTemplates;

  const HeroSection({super.key, this.onBrowseTemplates});

  static const double _twoColumnBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool wide = constraints.maxWidth >= _twoColumnBreakpoint;
        final Widget copy = _HeroCopy(centered: !wide, onBrowseTemplates: onBrowseTemplates);

        if (wide) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: copy),
                const SizedBox(width: 40),
                const Expanded(flex: 6, child: HeroRender()),
              ],
            ),
          );
        }

        return Column(
          children: [
            const SizedBox(height: 16),
            copy,
            const SizedBox(height: 32),
            FractionallySizedBox(widthFactor: 0.6, child: const HeroRender()),
          ],
        );
      },
    );
  }
}

class _HeroCopy extends StatelessWidget {
  final bool centered;
  final VoidCallback? onBrowseTemplates;

  const _HeroCopy({required this.centered, this.onBrowseTemplates});

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    final cross = centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Store screenshots,\nmade by hand.',
          textAlign: align,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1.05,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Lay out your App Store and Google Play screenshots on one canvas. '
            'Free, open source, and nothing leaves your browser.',
            textAlign: align,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: AppDimensions.spacingLg,
          runSpacing: AppDimensions.spacingMd,
          alignment: centered ? WrapAlignment.center : WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ClayButton.primary(
              label: 'Start a project',
              icon: Icons.arrow_forward_rounded,
              size: ClayButtonSize.large,
              ripple: true,
              onPressed: () => context.read<EditorViewModel>().openEditorWithNewProject(),
            ),
            ClayButton.text(
              label: 'Browse templates',
              icon: Icons.arrow_downward_rounded,
              onPressed: onBrowseTemplates,
            ),
          ],
        ),
      ],
    );
  }
}

/// The Blender hero render (`assets/clay/hero_phone_stack.png`, 720×560),
/// scaled down with the available width.
///
/// Idle: a slow 4 s float of 6 px plus a 1.5° rotate loop. Pointer near:
/// tilts up to 4° toward the pointer. Click: jelly squash. All of it is off
/// when reduced motion is on. Falls back to a labelled clay panel while the
/// render is still being produced.
class HeroRender extends StatefulWidget {
  const HeroRender({super.key});

  static const String assetPath = 'assets/clay/hero_phone_stack.png';
  static const double renderWidth = 720;
  static const double renderHeight = 560;

  @override
  State<HeroRender> createState() => _HeroRenderState();
}

class _HeroRenderState extends State<HeroRender> with TickerProviderStateMixin {
  static const double _floatPx = 6;
  static const double _floatRad = 1.5 * math.pi / 180;
  static const double _tiltRad = 4 * math.pi / 180;

  late final AnimationController _float;
  late final AnimationController _tiltX;
  late final AnimationController _tiltY;
  final JellyController _jelly = JellyController();
  bool _motionEnabled = true;

  @override
  void initState() {
    super.initState();
    // A loop, not a control, so a linear repeat with a sine is fine here.
    _float = AnimationController(vsync: this, duration: const Duration(seconds: 4));
    _tiltX = AnimationController.unbounded(vsync: this, value: 0);
    _tiltY = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = ClayMotion.of(context).enabled;
    if (enabled != _motionEnabled || (enabled && !_float.isAnimating)) {
      _motionEnabled = enabled;
      if (enabled) {
        _float.repeat();
      } else {
        _float.stop();
        _float.value = 0;
        _tiltX.value = 0;
        _tiltY.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _float.dispose();
    _tiltX.dispose();
    _tiltY.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event, Size size) {
    if (!_motionEnabled || size.isEmpty) return;
    final nx = ((event.localPosition.dx / size.width) * 2 - 1).clamp(-1.0, 1.0);
    final ny = ((event.localPosition.dy / size.height) * 2 - 1).clamp(-1.0, 1.0);
    final spring = ClayMotion.of(context).gentle;
    // Tilt toward the pointer: pointer right → rotate about Y so the right
    // edge dips; pointer down → rotate about X so the bottom edge dips.
    _tiltY.springTo(nx * _tiltRad, spring: spring);
    _tiltX.springTo(-ny * _tiltRad, spring: spring);
  }

  void _onExit() {
    final spring = ClayMotion.of(context).gentle;
    _tiltX.springTo(0, spring: spring);
    _tiltY.springTo(0, spring: spring);
  }

  @override
  Widget build(BuildContext context) {
    const aspect = HeroRender.renderWidth / HeroRender.renderHeight;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: HeroRender.renderWidth),
      child: AspectRatio(
        aspectRatio: aspect,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            return MouseRegion(
              onHover: (e) => _onHover(e, size),
              onExit: (_) => _onExit(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _jelly.tap(squash: 0.06),
                child: AnimatedBuilder(
                  animation: Listenable.merge([_float, _tiltX, _tiltY]),
                  builder: (context, child) {
                    final phase = _float.value * 2 * math.pi;
                    final dy = _motionEnabled ? _floatPx * math.sin(phase) : 0.0;
                    final rz = _motionEnabled ? _floatRad * math.sin(phase + math.pi / 3) : 0.0;
                    final m = Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..translateByDouble(0.0, dy, 0.0, 1.0)
                      ..rotateX(_tiltX.value)
                      ..rotateY(_tiltY.value)
                      ..rotateZ(rz);
                    return Transform(
                      transform: m,
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: JellyTransform(
                    controller: _jelly,
                    child: RepaintBoundary(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: HeroRender.renderWidth,
                          height: HeroRender.renderHeight,
                          child: Image.asset(
                            HeroRender.assetPath,
                            width: HeroRender.renderWidth,
                            height: HeroRender.renderHeight,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                            semanticLabel: 'A stack of phones showing store screenshots',
                            errorBuilder: (_, _, _) => const _HeroRenderPlaceholder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shown while `hero_phone_stack.png` has not landed yet: a clay panel of
/// the same aspect with a muted label.
class _HeroRenderPlaceholder extends StatelessWidget {
  const _HeroRenderPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ClayPanel(
      width: HeroRender.renderWidth,
      height: HeroRender.renderHeight,
      radius: AppDimensions.radiusClayXl,
      alignment: Alignment.center,
      child: Text(
        'hero render',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}
