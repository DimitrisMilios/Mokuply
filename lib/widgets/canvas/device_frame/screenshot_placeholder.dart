import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/store_specs.dart';

/// Placeholder shown inside a frame until a screenshot is uploaded.
///
/// Two renders: [preview] true is the clay empty-state on the editor canvas;
/// [preview] false is the exported render, pinned to the pre-redesign
/// pixels (colours are literals, not tokens) so exports stay byte-identical.
class ScreenshotPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double scale;
  final TargetPlatformType platform;
  final bool preview;

  const ScreenshotPlaceholder({
    super.key,
    required this.width,
    required this.height,
    required this.scale,
    required this.platform,
    required this.preview,
  });

  /// Pre-redesign `AppColors.primary` / `textPrimary` and `textMuted`.
  static const Color _exportInk = Color(0xFF1A4731);
  static const Color _exportMuted = Color(0xFF5A7B6C);

  @override
  Widget build(BuildContext context) {
    if (!preview) return _buildExport();

    final IconData icon = platform == TargetPlatformType.appStore
        ? Icons.phone_iphone_rounded
        : Icons.phone_android_rounded;

    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.clayDeep],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Blender clay render; the circle is the fallback until it lands.
          Image.asset(
            'assets/clay/empty_frame.png',
            width: 440 * scale,
            height: 440 * scale,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => Container(
              width: 440 * scale,
              height: 440 * scale,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: Icon(icon, size: 96 * scale, color: AppColors.primary),
            ),
          ),
          SizedBox(height: 40 * scale),
          Text(
            'Add a screenshot',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 52 * scale,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Select the frame, then use\nShot in the rail.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 34 * scale,
              fontWeight: FontWeight.w600,
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  /// The exported placeholder. Do not restyle: it is part of the PNG when a
  /// device has no screenshot for either store.
  Widget _buildExport() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.95), const Color(0xFFF7F2E2).withValues(alpha: 0.95)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40 * scale),
            decoration: BoxDecoration(
              color: _exportInk.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: _exportInk.withValues(alpha: 0.2), width: 3 * scale),
            ),
            child: Icon(
              platform == TargetPlatformType.appStore ? Icons.phone_iphone_rounded : Icons.phone_android_rounded,
              size: 140 * scale,
              color: _exportInk,
            ),
          ),
          SizedBox(height: 40 * scale),
          Text(
            'Upload ${platform.screenshotLabel} screenshot',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _exportInk,
              fontSize: 52 * scale,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: 16 * scale),
          Text(
            'Select this frame, then use\n"App Screenshots" in the sidebar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _exportMuted,
              fontSize: 34 * scale,
              fontWeight: FontWeight.w500,
              height: 1.3,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}
