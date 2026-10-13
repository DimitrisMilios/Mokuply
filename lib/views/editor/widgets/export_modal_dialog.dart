import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../services/css_spinner.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

/// Which of the three export options is running or just finished.
enum _ExportOption { both, appStore, googlePlay }

class ExportModalDialog extends StatefulWidget {
  const ExportModalDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showClayDialog<void>(
      context: context,
      builder: (ctx) => const ExportModalDialog(),
    );
  }

  @override
  State<ExportModalDialog> createState() => _ExportModalDialogState();
}

class _ExportModalDialogState extends State<ExportModalDialog> {
  /// The option whose button is in the busy state.
  _ExportOption? _busy;

  /// The option whose button shows the check for a moment before the dialog closes.
  _ExportOption? _done;

  /// How long the "Done" check stays on the button before the dialog pops.
  static const Duration _doneHold = Duration(milliseconds: 650);

  Future<void> _run(
    _ExportOption option,
    EditorViewModel vm,
    Future<void> Function() export,
    String successMessage,
    String errorMessage,
  ) async {
    setState(() => _busy = option);
    try {
      await export();
    } catch (e) {
      debugPrint('ExportModalDialog export error: $e');
      if (!mounted) return;
      setState(() => _busy = null);
      ClayToast.show(context, errorMessage, error: true);
      return;
    }
    if (!mounted) return;
    if (vm.isExporting) {
      setState(() => _busy = null);
      return;
    }
    // Label crossfades to a check, then the dialog closes and the toast rises.
    setState(() {
      _busy = null;
      _done = option;
    });
    await Future<void>.delayed(_doneHold);
    if (!mounted) return;
    // The toast lives in the root overlay, so showing it before the pop is safe
    // and keeps it visible while the dialog fades out.
    ClayToast.show(context, successMessage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final busyLabel = vm.exportingTotalSteps > 0
        ? '${vm.exportingProgressIndex} of ${vm.exportingTotalSteps}'
        : 'Working';

    final cards = <Widget>[
      _ExportOptionCard(
        emphasised: true,
        asset: 'assets/clay/export_both.png',
        fallbackIcon: Icons.inventory_2_rounded,
        knobColor: AppColors.butter,
        title: 'Both stores',
        description: 'One zip with an App Store folder and a Google Play folder.',
        button: _button(
          option: _ExportOption.both,
          vm: vm,
          primary: true,
          busyLabel: busyLabel,
          onPressed: () => _run(
            _ExportOption.both,
            vm,
            () => vm.exportBothPlatformsPack(context: context),
            'Your zip is downloading.',
            'The zip could not be made.',
          ),
        ),
      ),
      _ExportOptionCard(
        asset: 'assets/clay/export_apple.png',
        fallbackIcon: Icons.apple,
        knobColor: AppColors.mint,
        title: 'App Store',
        description: '${TargetPlatformType.appStore.dimensionsLabel} PNGs for the 6.9" slot.',
        button: _button(
          option: _ExportOption.appStore,
          vm: vm,
          primary: false,
          busyLabel: busyLabel,
          onPressed: () => _run(
            _ExportOption.appStore,
            vm,
            () => vm.exportPlatformPack(TargetPlatformType.appStore, context: context),
            'Your App Store zip is downloading.',
            'The App Store zip could not be made.',
          ),
        ),
      ),
      _ExportOptionCard(
        asset: 'assets/clay/export_play.png',
        fallbackIcon: Icons.android,
        knobColor: AppColors.clay,
        title: 'Google Play',
        description: 'Same size, Galaxy frame.',
        button: _button(
          option: _ExportOption.googlePlay,
          vm: vm,
          primary: false,
          busyLabel: busyLabel,
          onPressed: () => _run(
            _ExportOption.googlePlay,
            vm,
            () => vm.exportPlatformPack(TargetPlatformType.googlePlay, context: context),
            'Your Google Play zip is downloading.',
            'The Google Play zip could not be made.',
          ),
        ),
      ),
    ];

    return ClayDialog(
      width: 640,
      title: 'Download',
      subtitle: 'Pick a store, or get both in one zip.',
      headerIcon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 24),
      showClose: !vm.isExporting,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (vm.isExporting) ...[
            _ExportProgressWell(
              key: const ValueKey('export_progress_card'),
              statusText: vm.exportingStatusText.isNotEmpty ? vm.exportingStatusText : 'Working on your screenshots',
              progress: vm.exportingTotalSteps > 0
                  ? (vm.exportingProgressIndex / vm.exportingTotalSteps).clamp(0.0, 1.0)
                  : 0.0,
            ),
            const SizedBox(height: 20),
          ],
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            ClayStagger(index: i, child: cards[i]),
          ],
        ],
      ),
    );
  }

  Widget _button({
    required _ExportOption option,
    required EditorViewModel vm,
    required bool primary,
    required String busyLabel,
    required VoidCallback onPressed,
  }) {
    final isBusy = vm.isExporting && _busy == option;
    final isDone = _done == option;
    final enabled = !vm.isExporting && _done == null;

    final Widget button;
    if (isDone) {
      button = ClayButton.primary(
        key: const ValueKey('done'),
        label: 'Done',
        icon: Icons.check_rounded,
        onPressed: null,
      );
    } else if (primary) {
      button = ClayButton.primary(
        key: const ValueKey('download'),
        label: 'Download',
        busy: isBusy,
        busyLabel: busyLabel,
        onPressed: enabled ? onPressed : null,
      );
    } else {
      button = ClayButton.neutral(
        key: const ValueKey('download'),
        label: 'Download',
        busy: isBusy,
        busyLabel: busyLabel,
        onPressed: enabled ? onPressed : null,
      );
    }

    return AnimatedSwitcher(
      duration: ClayDurations.crossfade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: button,
    );
  }
}

/// Sunken well with the status line, the smooth spinner and a spring-filled bar.
class _ExportProgressWell extends StatelessWidget {
  final String statusText;
  final double progress;

  const _ExportProgressWell({super.key, required this.statusText, required this.progress});

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

/// One export option: a round clay knob with the Blender render, title,
/// description and the download button.
class _ExportOptionCard extends StatelessWidget {
  final bool emphasised;
  final String asset;
  final IconData fallbackIcon;
  final Color knobColor;
  final String title;
  final String description;
  final Widget button;

  const _ExportOptionCard({
    this.emphasised = false,
    required this.asset,
    required this.fallbackIcon,
    required this.knobColor,
    required this.title,
    required this.description,
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      emphasised: emphasised,
      padding: EdgeInsets.all(emphasised ? 24 : 18),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: ClayDecoration(
              color: knobColor,
              radius: 24,
              depth: 4,
              lift: 8,
              shadowOpacity: 0.16,
              edgeOpacity: 0.10,
            ),
            child: OverflowBox(
              maxWidth: 56,
              maxHeight: 56,
              child: Image.asset(
                asset,
                width: 56,
                height: 56,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Icon(fallbackIcon, size: 22, color: AppColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: emphasised ? 17 : AppDimensions.fontLg,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppDimensions.fontBody,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          button,
        ],
      ),
    );
  }
}
