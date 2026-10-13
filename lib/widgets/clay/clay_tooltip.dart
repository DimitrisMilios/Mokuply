import 'package:flutter/material.dart';

/// Small clay surface, no arrow. The look comes from `tooltipTheme` in
/// `AppTheme`, so this is a thin wrapper that keeps call sites readable and
/// skips the wrapper entirely when there is no message.
class ClayTooltip extends StatelessWidget {
  final String? message;
  final Widget child;
  final bool preferBelow;

  const ClayTooltip({super.key, required this.message, required this.child, this.preferBelow = true});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return child;
    return Tooltip(message: message!, preferBelow: preferBelow, child: child);
  }
}
