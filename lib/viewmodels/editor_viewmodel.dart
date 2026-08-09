import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import '../models/canvas_text_item.dart';
import '../models/project_template.dart';
import '../models/template_data.dart';
import '../services/export_service.dart';
import '../services/file_service.dart';
import '../widgets/canvas/canvas_mockup_widget.dart';

/// Editor ViewModel — manages multi-screenshot project sets and app flow.
class EditorViewModel extends ChangeNotifier {
  bool _isHomeScreen = true;
  ProjectTemplate? _activeTemplate;
  List<TemplateData> _screenshots = ProjectTemplate.saasModern().initialScreenshots;
  int _selectedIndex = 0;
  bool _isExporting = false;
  int _exportingProgressIndex = 0;

  // Flow & State Accessors
  bool get isHomeScreen => _isHomeScreen;
  ProjectTemplate? get activeTemplate => _activeTemplate;
  List<TemplateData> get screenshots => List.unmodifiable(_screenshots);
  int get selectedIndex => _selectedIndex;
  int get screenshotsCount => _screenshots.length;
  bool get isExporting => _isExporting;
  int get exportingProgressIndex => _exportingProgressIndex;

  /// Gets currently active screenshot item
  TemplateData get data => _screenshots[_selectedIndex.clamp(0, _screenshots.length - 1)];

  // Convenience getters delegating to active screenshot item
  TargetPlatformType get platform => data.platform;
  LayoutMode get layoutMode => data.layoutMode;
  DeviceFrameStyle get frameStyle => data.frameStyle;
  String get titleText => data.titleText;
  String get subtitleText => data.subtitleText;
  String get titleFont => data.titleFont;
  String get subtitleFont => data.subtitleFont;
  double get titleSize => data.titleSize;
  double get subtitleSize => data.subtitleSize;
  FontWeight get titleWeight => data.titleWeight;
  FontWeight get subtitleWeight => data.subtitleWeight;
  Color get textColor => data.textColor;
  Color get subtitleColor => data.subtitleColor;
  TextAlign get titleAlignment => data.titleAlignment;
  TextAlign get subtitleAlignment => data.subtitleAlignment;
  int get selectedGradientIndex => data.selectedGradientIndex;
  Color? get customBackgroundColor => data.customBackgroundColor;
  List<Color>? get customGradientColors => data.customGradientColors;
  Uint8List? get customBackgroundImageBytes => data.customBackgroundImageBytes;
  Uint8List? get screenshotBytes => data.screenshotBytes;
  Uint8List? get iphoneScreenshotBytes => data.iphoneScreenshotBytes;
  Uint8List? get samsungScreenshotBytes => data.samsungScreenshotBytes;
  Uint8List? get effectiveScreenshotBytes => data.effectiveScreenshotBytes;
  double get deviceScale => data.deviceScale;
  double get deviceOffsetX => data.deviceOffsetX;
  double get deviceOffsetY => data.deviceOffsetY;
  double get textOffsetX => data.textOffsetX; // Title X offset
  double get textOffsetY => data.textOffsetY; // Title Y offset
  double get subtitleOffsetX => data.subtitleOffsetX;
  double get subtitleOffsetY => data.subtitleOffsetY;
  List<CanvasTextItem> get customTextItems => data.customTextItems;
  double get deviceRotation => data.deviceRotation;
  bool get hasShadow => data.hasShadow;

  /// Computed background decoration for current screenshot
  BoxDecoration get backgroundDecoration {
    final currentData = data;
    if (currentData.customBackgroundColor != null) {
      return BoxDecoration(color: currentData.customBackgroundColor);
    }
    if (currentData.customGradientColors != null && currentData.customGradientColors!.length >= 2) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: currentData.customGradientColors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    return StoreSpecs.gradientPresets[
      currentData.selectedGradientIndex % StoreSpecs.gradientPresets.length
    ].toDecoration();
  }

  // --- Mutators for Canvas Freeform Drag & Offsets ---

  void setDeviceOffsetX(double offsetX) {
    _updateCurrentScreenshot(data.copyWith(deviceOffsetX: offsetX));
  }

  void setDeviceOffsetY(double offsetY) {
    _updateCurrentScreenshot(data.copyWith(deviceOffsetY: offsetY));
  }

  void setDeviceOffsets(double offsetX, double offsetY) {
    _updateCurrentScreenshot(data.copyWith(
      deviceOffsetX: offsetX,
      deviceOffsetY: offsetY,
    ));
  }

  void setDeviceOffsetsForIndex(int index, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      _screenshots[index] = _screenshots[index].copyWith(
        deviceOffsetX: offsetX,
        deviceOffsetY: offsetY,
      );
      notifyListeners();
    }
  }

  void setTextOffsets(double offsetX, double offsetY) {
    _updateCurrentScreenshot(data.copyWith(
      textOffsetX: offsetX,
      textOffsetY: offsetY,
    ));
  }

  void setTextOffsetsForIndex(int index, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      _screenshots[index] = _screenshots[index].copyWith(
        textOffsetX: offsetX,
        textOffsetY: offsetY,
      );
      notifyListeners();
    }
  }

  void setSubtitleOffsets(double offsetX, double offsetY) {
    _updateCurrentScreenshot(data.copyWith(
      subtitleOffsetX: offsetX,
      subtitleOffsetY: offsetY,
    ));
  }

  void setSubtitleOffsetsForIndex(int index, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      _screenshots[index] = _screenshots[index].copyWith(
        subtitleOffsetX: offsetX,
        subtitleOffsetY: offsetY,
      );
      notifyListeners();
    }
  }

  void resetCanvasOffsets() {
    _updateCurrentScreenshot(data.copyWith(
      deviceOffsetX: 0.0,
      deviceOffsetY: 0.0,
      textOffsetX: 0.0,
      textOffsetY: 0.0,
      subtitleOffsetX: 0.0,
      subtitleOffsetY: 0.0,
      deviceRotation: 0.0,
      deviceScale: 0.85,
    ));
  }

  // --- Mutators for Custom Extra Text Elements ---

  void addCustomTextElement() {
    final newItem = CanvasTextItem(
      id: 'txt_${DateTime.now().millisecondsSinceEpoch}',
      text: 'New Text Element',
      fontSize: 28.0,
      color: Colors.white,
      font: 'Outfit',
      weight: FontWeight.w600,
      alignment: TextAlign.center,
      offsetX: 0.0,
      offsetY: 80.0,
    );
    final updatedList = List<CanvasTextItem>.from(data.customTextItems)..add(newItem);
    _updateCurrentScreenshot(data.copyWith(customTextItems: updatedList));
  }

  void updateCustomTextElement(String id, CanvasTextItem updated) {
    final updatedList = data.customTextItems.map((item) {
      return item.id == id ? updated : item;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(customTextItems: updatedList));
  }

  void updateCustomTextElementForIndex(int index, String id, CanvasTextItem updated) {
    if (index >= 0 && index < _screenshots.length) {
      final currentList = _screenshots[index].customTextItems;
      final updatedList = currentList.map((item) {
        return item.id == id ? updated : item;
      }).toList();
      _screenshots[index] = _screenshots[index].copyWith(customTextItems: updatedList);
      notifyListeners();
    }
  }

  void setCustomTextElementOffsetsForIndex(int index, String id, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      final currentList = _screenshots[index].customTextItems;
      final updatedList = currentList.map((item) {
        return item.id == id ? item.copyWith(offsetX: offsetX, offsetY: offsetY) : item;
      }).toList();
      _screenshots[index] = _screenshots[index].copyWith(customTextItems: updatedList);
      notifyListeners();
    }
  }

  void removeCustomTextElement(String id) {
    final updatedList = data.customTextItems.where((item) => item.id != id).toList();
    _updateCurrentScreenshot(data.copyWith(customTextItems: updatedList));
  }

  // --- Typography Mutators ---

  void setTitleWeight(FontWeight weight) {
    _updateCurrentScreenshot(data.copyWith(titleWeight: weight));
  }

  void setSubtitleWeight(FontWeight weight) {
    _updateCurrentScreenshot(data.copyWith(subtitleWeight: weight));
  }

  void setTitleAlignment(TextAlign alignment) {
    _updateCurrentScreenshot(data.copyWith(titleAlignment: alignment));
  }

  void setSubtitleAlignment(TextAlign alignment) {
    _updateCurrentScreenshot(data.copyWith(subtitleAlignment: alignment));
  }

  // --- Mutators for Background & Screenshots ---

  void setCustomBackgroundImage(Uint8List? bytes) {
    _updateCurrentScreenshot(data.copyWith(
      customBackgroundImageBytes: () => bytes,
    ));
  }

  Future<void> pickCustomBackgroundImage() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      setCustomBackgroundImage(bytes);
    }
  }

  void setScreenshotBytes(Uint8List? bytes) {
    _updateCurrentScreenshot(data.copyWith(screenshotBytes: () => bytes));
  }

  void setIphoneScreenshotBytes(Uint8List? bytes) {
    _updateCurrentScreenshot(data.copyWith(iphoneScreenshotBytes: () => bytes));
  }

  void setSamsungScreenshotBytes(Uint8List? bytes) {
    _updateCurrentScreenshot(data.copyWith(samsungScreenshotBytes: () => bytes));
  }

  Future<void> pickIphoneScreenshot() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      setIphoneScreenshotBytes(bytes);
    }
  }

  Future<void> pickSamsungScreenshot() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      setSamsungScreenshotBytes(bytes);
    }
  }


  // --- Flow Navigation ---

  void openEditorWithTemplate(ProjectTemplate template) {
    _activeTemplate = template;
    _screenshots = List.from(template.initialScreenshots);
    _selectedIndex = 0;
    _isHomeScreen = false;
    notifyListeners();
  }

  void openEditorWithNewProject() {
    _activeTemplate = ProjectTemplate.saasModern();
    _screenshots = List.from(_activeTemplate!.initialScreenshots);
    _selectedIndex = 0;
    _isHomeScreen = false;
    notifyListeners();
  }

  void goBackToHome() {
    _isHomeScreen = true;
    notifyListeners();
  }

  // --- Multi-Screenshot Actions ---

  void selectScreenshot(int index) {
    if (index >= 0 && index < _screenshots.length) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void addScreenshot() {
    final newCard = TemplateData(
      platform: platform,
      frameStyle: frameStyle,
      titleText: 'New Screenshot ${_screenshots.length + 1}',
      subtitleText: 'Customize headlines and layout',
      selectedGradientIndex: _screenshots.length % StoreSpecs.gradientPresets.length,
    );
    _screenshots.add(newCard);
    _selectedIndex = _screenshots.length - 1;
    notifyListeners();
  }

  void removeScreenshot(int index) {
    if (_screenshots.length <= 1) return; // Keep at least 1 screenshot
    _screenshots.removeAt(index);
    if (_selectedIndex >= _screenshots.length) {
      _selectedIndex = _screenshots.length - 1;
    }
    notifyListeners();
  }

  void duplicateScreenshot(int index) {
    if (index >= 0 && index < _screenshots.length) {
      final copy = _screenshots[index].copyWith(
        titleText: '${_screenshots[index].titleText} (Copy)',
      );
      _screenshots.insert(index + 1, copy);
      _selectedIndex = index + 1;
      notifyListeners();
    }
  }

  // --- Mutators for Currently Selected Screenshot ---

  void _updateCurrentScreenshot(TemplateData updated) {
    _screenshots[_selectedIndex] = updated;
    notifyListeners();
  }

  void setPlatform(TargetPlatformType newPlatform) {
    // Update platform across ALL screenshots in project for target store consistency
    _screenshots = _screenshots.map((s) {
      return s.copyWith(
        platform: newPlatform,
        frameStyle: newPlatform == TargetPlatformType.googlePlay
            ? DeviceFrameStyle.samsungS26Ultra
            : DeviceFrameStyle.iphone16ProMax,
      );
    }).toList();
    notifyListeners();
  }

  void setLayoutMode(LayoutMode mode) {
    _updateCurrentScreenshot(data.copyWith(layoutMode: mode));
  }

  void setFrameStyle(DeviceFrameStyle style) {
    _updateCurrentScreenshot(data.copyWith(frameStyle: style));
  }

  void setTitleText(String text) {
    _updateCurrentScreenshot(data.copyWith(titleText: text));
  }

  void setSubtitleText(String text) {
    _updateCurrentScreenshot(data.copyWith(subtitleText: text));
  }

  void setTitleFont(String font) {
    _updateCurrentScreenshot(data.copyWith(titleFont: font));
  }

  void setSubtitleFont(String font) {
    _updateCurrentScreenshot(data.copyWith(subtitleFont: font));
  }

  void setTitleSize(double size) {
    _updateCurrentScreenshot(data.copyWith(titleSize: size));
  }

  void setSubtitleSize(double size) {
    _updateCurrentScreenshot(data.copyWith(subtitleSize: size));
  }

  void setTextColor(Color color) {
    _updateCurrentScreenshot(data.copyWith(textColor: color));
  }

  void setSubtitleColor(Color color) {
    _updateCurrentScreenshot(data.copyWith(subtitleColor: color));
  }

  void setGradientIndex(int index) {
    _updateCurrentScreenshot(data.copyWith(
      selectedGradientIndex: index,
      customBackgroundColor: () => null,
      customGradientColors: () => null,
    ));
  }

  void setCustomBackgroundColor(Color color) {
    _updateCurrentScreenshot(data.copyWith(
      customBackgroundColor: () => color,
      customGradientColors: () => null,
    ));
  }

  void setCustomGradientColors(List<Color> colors) {
    _updateCurrentScreenshot(data.copyWith(
      customGradientColors: () => colors,
      customBackgroundColor: () => null,
    ));
  }

  void setDeviceScale(double scale) {
    _updateCurrentScreenshot(data.copyWith(deviceScale: scale));
  }

  void setDeviceRotation(double degrees) {
    _updateCurrentScreenshot(data.copyWith(deviceRotation: degrees));
  }

  void setHasShadow(bool shadow) {
    _updateCurrentScreenshot(data.copyWith(hasShadow: shadow));
  }

  void resetToDefaults() {
    _screenshots = ProjectTemplate.saasModern().initialScreenshots;
    _selectedIndex = 0;
    notifyListeners();
  }

  /// Pick an image file for currently selected screenshot
  Future<void> pickScreenshot() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      setScreenshotBytes(bytes);
    }
  }

  DeviceFrameStyle _resolveFrameStyleForTargetPlatform(DeviceFrameStyle currentStyle, TargetPlatformType targetPlatform) {
    if (currentStyle == DeviceFrameStyle.minimalOutline || currentStyle == DeviceFrameStyle.none) {
      return currentStyle;
    }
    return targetPlatform == TargetPlatformType.googlePlay
        ? DeviceFrameStyle.samsungS26Ultra
        : DeviceFrameStyle.iphone16ProMax;
  }

  /// Exports a single store platform package (Apple App Store or Google Play Store) as a high-res ZIP bundle.
  Future<void> exportPlatformPack(TargetPlatformType targetPlatform, {required BuildContext context}) async {
    _isExporting = true;
    _exportingProgressIndex = 0;
    notifyListeners();

    try {
      final Size targetSize = Size(targetPlatform.targetWidth, targetPlatform.targetHeight);
      final String folderName = targetPlatform == TargetPlatformType.appStore
          ? 'Apple_App_Store_1320x2868'
          : 'Google_Play_Store_1440x2560';

      final Map<String, Uint8List> zipFiles = {};

      for (int i = 0; i < _screenshots.length; i++) {
        _exportingProgressIndex = i + 1;
        notifyListeners();

        final targetFrameStyle = _resolveFrameStyleForTargetPlatform(_screenshots[i].frameStyle, targetPlatform);
        final itemData = _screenshots[i].copyWith(
          platform: targetPlatform,
          frameStyle: targetFrameStyle,
        );
        final widget = CanvasMockupWidget(
          data: itemData,
          canvasSize: targetSize,
          isExporting: true,
        );

        final pngBytes = await ExportService.captureHighResWidget(
          widget: widget,
          targetSize: targetSize,
          context: context,
        );

        final filename = '$folderName/Screen_${i + 1}.png';
        zipFiles[filename] = pngBytes;
      }

      final zipBytes = ExportService.createZipArchive(zipFiles);
      final zipFilename = 'Mokuply_$folderName.zip';
      ExportService.downloadFileWeb(
        bytes: zipBytes,
        filename: zipFilename,
        mimeType: 'application/zip',
      );
    } finally {
      _isExporting = false;
      _exportingProgressIndex = 0;
      notifyListeners();
    }
  }

  /// Exports BOTH store platform packages (Apple 1320x2868 + Google 1440x2560) in a master ZIP bundle.
  Future<void> exportBothPlatformsPack({required BuildContext context}) async {
    _isExporting = true;
    _exportingProgressIndex = 0;
    notifyListeners();

    try {
      final Map<String, Uint8List> zipFiles = {};

      // 1. Apple App Store Screens (1320 x 2868)
      final appleSize = Size(TargetPlatformType.appStore.targetWidth, TargetPlatformType.appStore.targetHeight);
      for (int i = 0; i < _screenshots.length; i++) {
        _exportingProgressIndex = i + 1;
        notifyListeners();

        final appleFrameStyle = _resolveFrameStyleForTargetPlatform(_screenshots[i].frameStyle, TargetPlatformType.appStore);
        final itemData = _screenshots[i].copyWith(
          platform: TargetPlatformType.appStore,
          frameStyle: appleFrameStyle,
        );
        final widget = CanvasMockupWidget(
          data: itemData,
          canvasSize: appleSize,
          isExporting: true,
        );

        final pngBytes = await ExportService.captureHighResWidget(
          widget: widget,
          targetSize: appleSize,
          context: context,
        );

        zipFiles['Apple_App_Store_1320x2868/Screen_${i + 1}.png'] = pngBytes;
      }

      // 2. Google Play Store Screens (1440 x 2560)
      final googleSize = Size(TargetPlatformType.googlePlay.targetWidth, TargetPlatformType.googlePlay.targetHeight);
      for (int i = 0; i < _screenshots.length; i++) {
        _exportingProgressIndex = _screenshots.length + i + 1;
        notifyListeners();

        final googleFrameStyle = _resolveFrameStyleForTargetPlatform(_screenshots[i].frameStyle, TargetPlatformType.googlePlay);
        final itemData = _screenshots[i].copyWith(
          platform: TargetPlatformType.googlePlay,
          frameStyle: googleFrameStyle,
        );
        final widget = CanvasMockupWidget(
          data: itemData,
          canvasSize: googleSize,
          isExporting: true,
        );

        final pngBytes = await ExportService.captureHighResWidget(
          widget: widget,
          targetSize: googleSize,
          context: context, // ignore: use_build_context_synchronously
        );

        zipFiles['Google_Play_Store_1440x2560/Screen_${i + 1}.png'] = pngBytes;
      }

      final zipBytes = ExportService.createZipArchive(zipFiles);
      const zipFilename = 'Mokuply_StoreScreenshots_AllPlatforms.zip';
      ExportService.downloadFileWeb(
        bytes: zipBytes,
        filename: zipFilename,
        mimeType: 'application/zip',
      );
    } finally {
      _isExporting = false;
      _exportingProgressIndex = 0;
      notifyListeners();
    }
  }

  /// Sequential High-Res PNG Batch Download for current active platform screenshots.
  Future<void> exportAllScreenshots({required BuildContext context}) async {
    _isExporting = true;
    _exportingProgressIndex = 0;
    notifyListeners();

    try {
      final targetSize = Size(platform.targetWidth, platform.targetHeight);
      final platformTag = platform.platformName.toLowerCase().replaceAll(' ', '_');

      for (int i = 0; i < _screenshots.length; i++) {
        _exportingProgressIndex = i + 1;
        notifyListeners();

        final itemData = _screenshots[i];
        final widget = CanvasMockupWidget(
          data: itemData,
          canvasSize: targetSize,
          isExporting: true,
        );

        final pngBytes = await ExportService.captureHighResWidget(
          widget: widget,
          targetSize: targetSize,
          context: context, // ignore: use_build_context_synchronously
        );

        final filename = '${platformTag}_mockup_screen_${i + 1}_of_${_screenshots.length}.png';
        ExportService.downloadPngWeb(pngBytes: pngBytes, filename: filename);

        // Small pause between browser download triggers
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } finally {
      _isExporting = false;
      _exportingProgressIndex = 0;
      notifyListeners();
    }
  }
}
