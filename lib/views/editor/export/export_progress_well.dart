import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../services/css_spinner.dart';
import '../../../widgets/clay/clay.dart';

/// Sunken well with the status line, the smooth spinner and a spring-filled bar.
class ExportProgressWell extends StatelessWidget {
  final String statusText;
  final double progress;

  const ExportProgressWell({super.key, required this.statusText, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClayWell(
      padding: const EdgeInsets.all(18),
      radius: AppDimensions.radiusClay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SmoothSpinnerWidget(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: AppDimensions.fontMd,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ClayProgressBar(progress: progress),
        ],
      ),
    );
  }
}

/// A sunken track with a primary gradient fill whose width follows the
/// progress with the gentle spring.
class _ClayProgressBar extends StatefulWidget {
  final double progress;

  const _ClayProgressBar({required this.progress});

  @override
  State<_ClayProgressBar> createState() => _ClayProgressBarState();
}

class _ClayProgressBarState extends State<_ClayProgressBar> with SingleTickerProviderStateMixin {
  static const double _trackH = 12;

  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController.unbounded(vsync: this, value: widget.progress);
  }

  @override
  void didUpdateWidget(_ClayProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _fill.springTo(widget.progress, spring: ClayMotion.of(context).gentle);
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fill,
      builder: (context, _) {
        final t = _fill.value.clamp(0.0, 1.0);
        return Container(
          key: const ValueKey('export_linear_progress'),
          height: _trackH,
          decoration: const ClayDecoration.well(radius: _trackH / 2, depth: 3),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: t,
              heightFactor: 1,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_trackH / 2),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.primary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
