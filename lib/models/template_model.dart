import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/store_specs.dart';

class TemplateModel extends ChangeNotifier {
  TargetPlatformType _platform = TargetPlatformType.appStore;
  LayoutMode _layoutMode = LayoutMode.titleTopDeviceBottom;
  DeviceFrameStyle _frameStyle = DeviceFrameStyle.iphone16ProMax;

  String _titleText = 'Build Stunning Apps';
  String _subtitleText = 'Design high-res store screenshots in seconds';
  String _titleFont = 'Outfit';
  String _subtitleFont = 'Inter';
  double _titleSize = 54.0;
  double _subtitleSize = 26.0;
  Color _textColor = Colors.white;
  Color _subtitleColor = const Color(0xFFE2E8F0);

  int _selectedGradientIndex = 0;
  Color? _customBackgroundColor;
  List<Color>? _customGradientColors;

  Uint8List? _screenshotBytes;
  double _deviceScale = 0.85;
  double _deviceOffsetY = 0.0;
  double _deviceRotation = 0.0; // in degrees
  bool _hasShadow = true;

  // Getters
  TargetPlatformType get platform => _platform;
  LayoutMode get layoutMode => _layoutMode;
  DeviceFrameStyle get frameStyle => _frameStyle;

  String get titleText => _titleText;
  String get subtitleText => _subtitleText;
  String get titleFont => _titleFont;
  String get subtitleFont => _subtitleFont;
  double get titleSize => _titleSize;
  double get subtitleSize => _subtitleSize;
  Color get textColor => _textColor;
  Color get subtitleColor => _subtitleColor;

  int get selectedGradientIndex => _selectedGradientIndex;
  Color? get customBackgroundColor => _customBackgroundColor;
  List<Color>? get customGradientColors => _customGradientColors;

  Uint8List? get screenshotBytes => _screenshotBytes;
  double get deviceScale => _deviceScale;
  double get deviceOffsetY => _deviceOffsetY;
  double get deviceRotation => _deviceRotation;
  bool get hasShadow => _hasShadow;

  BoxDecoration get backgroundDecoration {
    if (_customBackgroundColor != null) {
      return BoxDecoration(color: _customBackgroundColor);
    }
    if (_customGradientColors != null && _customGradientColors!.length >= 2) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: _customGradientColors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    final preset = StoreSpecs.gradientPresets[_selectedGradientIndex % StoreSpecs.gradientPresets.length];
    return preset.toDecoration();
  }

  // Setters with notifyListeners
  void setPlatform(TargetPlatformType platform) {
    _platform = platform;
    if (platform == TargetPlatformType.googlePlay) {
      _frameStyle = DeviceFrameStyle.samsungS26Ultra;
    } else {
      _frameStyle = DeviceFrameStyle.iphone16ProMax;
    }
    notifyListeners();
  }

  void setLayoutMode(LayoutMode mode) {
    _layoutMode = mode;
    notifyListeners();
  }

  void setFrameStyle(DeviceFrameStyle style) {
    _frameStyle = style;
    notifyListeners();
  }

  void setTitleText(String text) {
    _titleText = text;
    notifyListeners();
  }

  void setSubtitleText(String text) {
    _subtitleText = text;
    notifyListeners();
  }

  void setTitleFont(String font) {
    _titleFont = font;
    notifyListeners();
  }

  void setSubtitleFont(String font) {
    _subtitleFont = font;
    notifyListeners();
  }

  void setTitleSize(double size) {
    _titleSize = size;
    notifyListeners();
  }

  void setSubtitleSize(double size) {
    _subtitleSize = size;
    notifyListeners();
  }

  void setTextColor(Color color) {
    _textColor = color;
    notifyListeners();
  }

  void setSubtitleColor(Color color) {
    _subtitleColor = color;
    notifyListeners();
  }

  void setGradientIndex(int index) {
    _selectedGradientIndex = index;
    _customBackgroundColor = null;
    _customGradientColors = null;
    notifyListeners();
  }

  void setCustomBackgroundColor(Color color) {
    _customBackgroundColor = color;
    _customGradientColors = null;
    notifyListeners();
  }

  void setCustomGradientColors(List<Color> colors) {
    _customGradientColors = colors;
    _customBackgroundColor = null;
    notifyListeners();
  }

  void setScreenshotBytes(Uint8List? bytes) {
    _screenshotBytes = bytes;
    notifyListeners();
  }

  void setDeviceScale(double scale) {
    _deviceScale = scale;
    notifyListeners();
  }

  void setDeviceOffsetY(double offsetY) {
    _deviceOffsetY = offsetY;
    notifyListeners();
  }

  void setDeviceRotation(double degrees) {
    _deviceRotation = degrees;
    notifyListeners();
  }

  void setHasShadow(bool shadow) {
    _hasShadow = shadow;
    notifyListeners();
  }

  void resetToDefaults() {
    _platform = TargetPlatformType.appStore;
    _layoutMode = LayoutMode.titleTopDeviceBottom;
    _frameStyle = DeviceFrameStyle.iphone16ProMax;
    _titleText = 'Build Stunning Apps';
    _subtitleText = 'Design high-res store screenshots in seconds';
    _titleFont = 'Outfit';
    _subtitleFont = 'Inter';
    _titleSize = 54.0;
    _subtitleSize = 26.0;
    _textColor = Colors.white;
    _subtitleColor = const Color(0xFFE2E8F0);
    _selectedGradientIndex = 0;
    _customBackgroundColor = null;
    _customGradientColors = null;
    _screenshotBytes = null;
    _deviceScale = 0.85;
    _deviceOffsetY = 0.0;
    _deviceRotation = 0.0;
    _hasShadow = true;
    notifyListeners();
  }
}
