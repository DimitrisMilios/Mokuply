import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

bool _isCssSpinnerRegistered = false;

void _ensureCssSpinnerRegistered() {
  if (kIsWeb && !_isCssSpinnerRegistered) {
    try {
      if (html.document.getElementById('mockuply-spinner-style') == null) {
        final style = html.StyleElement()
          ..id = 'mockuply-spinner-style'
          ..innerHtml = '''
            @keyframes mockuplyGpuSpin {
              0% { transform: rotate(0deg); }
              100% { transform: rotate(360deg); }
            }
            .mockuply-gpu-spinner {
              width: 22px;
              height: 22px;
              box-sizing: border-box;
              border: 4px solid #CDE7D6;
              border-top: 4px solid #2D6A4F;
              border-radius: 50%;
              animation: mockuplyGpuSpin 0.7s linear infinite;
              will-change: transform;
            }
          ''';
        html.document.head?.children.add(style);
      }

      ui_web.platformViewRegistry.registerViewFactory('mockuply-css-spinner', (int viewId) {
        final container = html.DivElement()
          ..style.width = '22px'
          ..style.height = '22px'
          ..style.display = 'flex'
          ..style.alignItems = 'center'
          ..style.justifyContent = 'center';
        final spinner = html.DivElement()..className = 'mockuply-gpu-spinner';
        container.children.add(spinner);
        return container;
      });

      _isCssSpinnerRegistered = true;
    } catch (_) {
      _isCssSpinnerRegistered = true;
    }
  }
}

/// Hardware-accelerated GPU CSS Spinner for Web (runs on browser compositor thread
/// so it NEVER freezes or stutters during heavy JS PNG/ZIP encoding).
/// Falls back to standard [CircularProgressIndicator] on desktop platforms.
class SmoothSpinnerWidget extends StatefulWidget {
  const SmoothSpinnerWidget({super.key});

  @override
  State<SmoothSpinnerWidget> createState() => _SmoothSpinnerWidgetState();
}

class _SmoothSpinnerWidgetState extends State<SmoothSpinnerWidget> {
  @override
  void initState() {
    super.initState();
    _ensureCssSpinnerRegistered();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && _isCssSpinnerRegistered) {
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
