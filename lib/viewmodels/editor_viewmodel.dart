import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import '../models/template_data.dart';
import '../services/export_service.dart';
import '../services/file_service.dart';
import '../widgets/canvas/canvas_mockup_widget.dart';

/// Editor ViewModel — owns template state and orchestrates business logic.
class EditorViewModel extends ChangeNotifier {
  TemplateData _data = const TemplateData();
  bool _isExporting = false;

  // Core accessors
  TemplateData get data => _data;
  bool get isExporting => _isExporting;

  // Convenience getters (delegate to _data)
  TargetPlatformType get platform => _data.platform;
  LayoutMode get layoutMode => _data.layoutMode;
  DeviceFrameStyle get frameStyle => _data.frameStyle;
  String get titleText => _data.titleText;
  String get subtitleText => _data.subtitleText;
  String get titleFont => _data.titleFont;
  String get subtitleFont => _data.subtitleFont;
  double get titleSize => _data.titleSize;
  double get subtitleSize => _data.subtitleSize;
  Color get textColor => _data.textColor;
  Color get subtitleColor => _data.subtitleColor;
  int get selectedGradientIndex => _data.selectedGradientIndex;
  Color? get customBackgroundColor => _data.customBackgroundColor;
  List<Color>? get customGradientColors => _data.customGradientColors;
  Uint8List? get screenshotBytes => _data.screenshotBytes;
  double get deviceScale => _data.deviceScale;
  double get deviceOffsetY => _data.deviceOffsetY;
  double get deviceRotation => _data.deviceRotation;
  bool get hasShadow => _data.hasShadow;

  /// Computed background decoration from current state.
  BoxDecoration get backgroundDecoration {
    if (_data.customBackgroundColor != null) {
      return BoxDecoration(color: _data.customBackgroundColor);
    }
    if (_data.customGradientColors != null && _data.customGradientColors!.length >= 2) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: _data.customGradientColors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    return StoreSpecs.gradientPresets[
      _data.selectedGradientIndex % StoreSpecs.gradientPresets.length
    ].toDecoration();
  }

  // --- Setters ---

  void setPlatform(TargetPlatformType platform) {
    _data = _data.copyWith(
      platform: platform,
      frameStyle: platform == TargetPlatformType.googlePlay
          ? DeviceFrameStyle.samsungS26Ultra
          : DeviceFrameStyle.iphone16ProMax,
    );
    notifyListeners();
  }

  void setLayoutMode(LayoutMode mode) {
    _data = _data.copyWith(layoutMode: mode);
    notifyListeners();
  }

  void setFrameStyle(DeviceFrameStyle style) {
    _data = _data.copyWith(frameStyle: style);
    notifyListeners();
  }

  void setTitleText(String text) {
    _data = _data.copyWith(titleText: text);
    notifyListeners();
  }

  void setSubtitleText(String text) {
    _data = _data.copyWith(subtitleText: text);
    notifyListeners();
  }

  void setTitleFont(String font) {
    _data = _data.copyWith(titleFont: font);
    notifyListeners();
  }

  void setSubtitleFont(String font) {
    _data = _data.copyWith(subtitleFont: font);
    notifyListeners();
  }

  void setTitleSize(double size) {
    _data = _data.copyWith(titleSize: size);
    notifyListeners();
  }

  void setSubtitleSize(double size) {
    _data = _data.copyWith(subtitleSize: size);
    notifyListeners();
  }

  void setTextColor(Color color) {
    _data = _data.copyWith(textColor: color);
    notifyListeners();
  }

  void setSubtitleColor(Color color) {
    _data = _data.copyWith(subtitleColor: color);
    notifyListeners();
  }

  void setGradientIndex(int index) {
    _data = _data.copyWith(
      selectedGradientIndex: index,
      customBackgroundColor: () => null,
      customGradientColors: () => null,
    );
    notifyListeners();
  }

  void setCustomBackgroundColor(Color color) {
    _data = _data.copyWith(
      customBackgroundColor: () => color,
      customGradientColors: () => null,
    );
    notifyListeners();
  }

  void setCustomGradientColors(List<Color> colors) {
    _data = _data.copyWith(
      customGradientColors: () => colors,
      customBackgroundColor: () => null,
    );
    notifyListeners();
  }

  void setScreenshotBytes(Uint8List? bytes) {
    _data = _data.copyWith(screenshotBytes: () => bytes);
    notifyListeners();
  }

  void setDeviceScale(double scale) {
    _data = _data.copyWith(deviceScale: scale);
    notifyListeners();
  }

  void setDeviceOffsetY(double offsetY) {
    _data = _data.copyWith(deviceOffsetY: offsetY);
    notifyListeners();
  }

  void setDeviceRotation(double degrees) {
    _data = _data.copyWith(deviceRotation: degrees);
    notifyListeners();
  }

  void setHasShadow(bool shadow) {
    _data = _data.copyWith(hasShadow: shadow);
    notifyListeners();
  }

  void resetToDefaults() {
    _data = const TemplateData();
    notifyListeners();
  }

  /// Pick an image file from the local filesystem (browser memory only).
  Future<void> pickScreenshot() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      _data = _data.copyWith(screenshotBytes: () => bytes);
      notifyListeners();
    }
  }

  /// Export the current mockup as a high-resolution PNG.
  /// Throws on failure.
  Future<void> exportMockup() async {
    _isExporting = true;
    notifyListeners();
    try {
      final targetSize = Size(platform.targetWidth, platform.targetHeight);
      final widget = CanvasMockupWidget(
        data: _data,
        canvasSize: targetSize,
        isExporting: true,
      );
      final pngBytes = await ExportService.captureHighResWidget(
        widget: widget,
        targetSize: targetSize,
      );
      final filename =
          '${platform.platformName.toLowerCase().replaceAll(' ', '_')}_mockup_${DateTime.now().millisecondsSinceEpoch}.png';
      ExportService.downloadPngWeb(pngBytes: pngBytes, filename: filename);
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }
}
