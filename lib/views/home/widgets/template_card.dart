import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/project_template.dart';
import '../../../viewmodels/library_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

/// Template card: a clay card with a sunken preview tray holding six tiny
/// clay phones, the category as a muted caps line, title, description and a
/// green "Use template" button. Tapping anywhere on the card uses it.
class TemplateCard extends StatelessWidget {
  final ProjectTemplate template;

  const TemplateCard({
    super.key,
    required this.template,
  });

  static const double _previewHeight = 140;
  static const double _hoverTiltRad = 2 * math.pi / 180;

  void _use(BuildContext context) => context.read<LibraryViewModel>().openTemplate(template);

  @override
  Widget build(BuildContext context) {
    final count = template.initialScreenshots.length;
    final meta = '$count ${count == 1 ? 'screen' : 'screens'} · ${template.platform.shortName}';

    // The static part is passed as the card child so it is not rebuilt while
    // the hover spring runs; only the preview tray is rebuilt with the value.
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClayLabel(template.category),
        const SizedBox(height: 6),
        Text(
          template.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          template.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: AppDimensions.fontSm,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meta,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: AppDimensions.fontSm,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        ClayButton.primary(
          label: 'Use template',
          icon: Icons.edit_note_rounded,
          expand: true,
          onPressed: () => _use(context),
        ),
      ],
    );

    return ClayCard(
      onTap: () => _use(context),
      padding: const EdgeInsets.all(AppDimensions.spacingXl),
      hoverBuilder: (context, hover, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PreviewTray(template: template, tilt: hover * _hoverTiltRad, height: _previewHeight),
            const SizedBox(height: AppDimensions.spacingLg),
            Expanded(child: child),
          ],
        );
      },
      child: details,
    );
  }
}

/// Sunken well with the template gradient inside and six tiny clay phones.
class _PreviewTray extends StatelessWidget {
  final ProjectTemplate template;
  final double tilt;
  final double height;

  const _PreviewTray({required this.template, required this.tilt, required this.height});

  @override
  Widget build(BuildContext context) {
    final phones = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(template.initialScreenshots.length, (i) {
        final screenData = template.initialScreenshots[i];
        final isRotatedLeft = screenData.deviceRotation < -5;
        final isRotatedRight = screenData.deviceRotation > 5;
        return Transform.rotate(
          angle: isRotatedLeft ? -0.12 : (isRotatedRight ? 0.12 : 0.0),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: _ClayPhone(),
          ),
        );
      }),
    );

    // Tilt the phones back 2° toward the pointer and lift them 2 px so the
    // tray reads as holding real slabs.
    final tilted = Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..translateByDouble(0.0, -2.0 * (tilt / (2 * math.pi / 180)), 0.0, 1.0)
        ..rotateX(-tilt),
      child: phones,
    );

    return ClayWell(
      height: height,
      padding: EdgeInsets.zero,
      radius: AppDimensions.radiusClay,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The gradient sits inside the well.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: template.previewGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Re-apply the inset lighting over the gradient so it still reads
          // as sunken (the gradient would otherwise cover the well's shading).
          const IgnorePointer(
            child: DecoratedBox(
              decoration: ClayDecoration.well(
                color: Colors.transparent,
                radius: AppDimensions.radiusClay,
                depth: 5,
                shadeOpacity: 0.18,
                highlightOpacity: 0.55,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: tilted,
            ),
          ),
        ],
      ),
    );
  }
}

/// One tiny fake phone, drawn as a small clay slab.
class _ClayPhone extends StatelessWidget {
  const _ClayPhone();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 90,
      alignment: Alignment.center,
      decoration: ClayDecoration(
        color: AppColors.clay.withValues(alpha: 0.72),
        radius: 10,
        depth: 2,
        lift: 4,
        shadowOpacity: 0.16,
        highlightOpacity: 0.8,
        shadeOpacity: 0.14,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 28,
            height: 50,
            alignment: Alignment.center,
            decoration: ClayDecoration.well(
              color: AppColors.clayDeep.withValues(alpha: 0.7),
              radius: 6,
              depth: 2,
              shadeOpacity: 0.12,
              highlightOpacity: 0.6,
            ),
            child: Icon(
              Icons.phone_iphone_rounded,
              size: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
