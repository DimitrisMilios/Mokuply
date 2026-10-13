import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';
import '../../../viewmodels/export_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'export_option_card.dart';
import 'export_progress_well.dart';

/// One download option of the dialog. [target] null means both stores.
class _ExportChoice {
  final TargetPlatformType? target;
  final String asset;
  final IconData fallbackIcon;
  final Color knobColor;
  final String title;
  final String description;
  final String success;
  final String failure;

  const _ExportChoice({
    required this.target,
    required this.asset,
    required this.fallbackIcon,
    required this.knobColor,
    required this.title,
    required this.description,
    required this.success,
    required this.failure,
  });
}

/// "Download": both stores in one zip, or one store at a time.
class ExportModalDialog extends StatefulWidget {
  const ExportModalDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showClayDialog<void>(context: context, builder: (ctx) => const ExportModalDialog());
  }

  @override
  State<ExportModalDialog> createState() => _ExportModalDialogState();
}

class _ExportModalDialogState extends State<ExportModalDialog> {
  static final List<_ExportChoice> _choices = [
    const _ExportChoice(
      target: null,
      asset: 'assets/clay/export_both.png',
      fallbackIcon: Icons.inventory_2_rounded,
      knobColor: AppColors.butter,
      title: 'Both stores',
      description: 'One zip with an App Store folder and a Google Play folder.',
      success: 'Your zip is downloading.',
      failure: 'The zip could not be made.',
    ),
    _ExportChoice(
      target: TargetPlatformType.appStore,
      asset: 'assets/clay/export_apple.png',
      fallbackIcon: Icons.apple,
      knobColor: AppColors.mint,
      title: 'App Store',
      description: '${TargetPlatformType.appStore.dimensionsLabel} PNGs for the 6.9" slot.',
      success: 'Your App Store zip is downloading.',
      failure: 'The App Store zip could not be made.',
    ),
    const _ExportChoice(
      target: TargetPlatformType.googlePlay,
      asset: 'assets/clay/export_play.png',
      fallbackIcon: Icons.android,
      knobColor: AppColors.clay,
      title: 'Google Play',
      description: 'Same size, Galaxy frame.',
      success: 'Your Google Play zip is downloading.',
      failure: 'The Google Play zip could not be made.',
    ),
  ];

  /// How long the "Done" check stays on the button before the dialog pops.
  static const Duration _doneHold = Duration(milliseconds: 650);

  /// The option whose button is busy, and the one showing the check.
  _ExportChoice? _busy;
  _ExportChoice? _done;

  Future<void> _run(_ExportChoice choice) async {
    final export = context.read<ExportViewModel>();
    setState(() => _busy = choice);
    try {
      final target = choice.target;
      if (target == null) {
        await export.exportBothPlatformsPack(context: context);
      } else {
        await export.exportPlatformPack(target, context: context);
      }
    } catch (e) {
      debugPrint('ExportModalDialog export error: $e');
      if (!mounted) return;
      setState(() => _busy = null);
      ClayToast.show(context, choice.failure, error: true);
      return;
    }
    if (!mounted) return;
    // Label crossfades to a check, then the dialog closes and the toast rises.
    setState(() {
      _busy = null;
      _done = choice;
    });
    await Future<void>.delayed(_doneHold);
    if (!mounted) return;
    // The toast lives in the root overlay, so it stays while the dialog fades.
    ClayToast.show(context, choice.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final export = context.watch<ExportViewModel>();
    final busyLabel = export.totalSteps > 0 ? '${export.progressIndex} of ${export.totalSteps}' : 'Working';

    return ClayDialog(
      width: 640,
      title: 'Download',
      subtitle: 'Pick a store, or get both in one zip.',
      headerIcon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 24),
      showClose: !export.isExporting,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (export.isExporting) ...[
            ExportProgressWell(
              key: const ValueKey('export_progress_card'),
              statusText: export.statusText.isNotEmpty ? export.statusText : 'Working on your screenshots',
              progress: export.progress,
            ),
            const SizedBox(height: 20),
          ],
          for (final (i, choice) in _choices.indexed) ...[
            if (i > 0) const SizedBox(height: 14),
            ClayStagger(
              index: i,
              child: ExportOptionCard(
                emphasised: i == 0,
                asset: choice.asset,
                fallbackIcon: choice.fallbackIcon,
                knobColor: choice.knobColor,
                title: choice.title,
                description: choice.description,
                button: _button(choice, primary: i == 0, exporting: export.isExporting, busyLabel: busyLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _button(_ExportChoice choice, {required bool primary, required bool exporting, required String busyLabel}) {
    final bool busy = exporting && _busy == choice;
    final VoidCallback? onPressed = !exporting && _done == null ? () => _run(choice) : null;
    final Widget button = _done == choice
        ? ClayButton.primary(key: const ValueKey('done'), label: 'Done', icon: Icons.check_rounded, onPressed: null)
        : primary
        ? ClayButton.primary(
            key: const ValueKey('download'),
            label: 'Download',
            busy: busy,
            busyLabel: busyLabel,
            onPressed: onPressed,
          )
        : ClayButton.neutral(
            key: const ValueKey('download'),
            label: 'Download',
            busy: busy,
            busyLabel: busyLabel,
            onPressed: onPressed,
          );

    return AnimatedSwitcher(
      duration: ClayDurations.crossfade,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: button,
    );
  }
}
