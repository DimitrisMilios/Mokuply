import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'css_spinner_stub.dart' if (dart.library.html) 'css_spinner_web.dart';

/// Hardware-accelerated GPU CSS Spinner for Web (runs on browser compositor thread
/// so it NEVER freezes or stutters during heavy JS PNG/ZIP encoding).
/// Falls back to standard [CircularProgressIndicator] on desktop platforms.
class SmoothSpinnerWidget extends StatefulWidget {
  const SmoothSpinnerWidget({super.key});

  @override
  State<SmoothSpinnerWidget> createState() => _SmoothSpinnerWidgetState();
}

class _SmoothSpinnerWidgetState extends State<SmoothSpinnerWidget> {
  bool _registered = false;

  @override
  void initState() {
    super.initState();
    _registered = ensureCssSpinnerRegistered();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _registered) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: HtmlElementView(viewType: 'mockuply-css-spinner'),
      );
    }
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        key: ValueKey('export_fallback_spinner'),
        color: AppColors.primary,
        strokeWidth: 2.5,
      ),
    );
  }
}
