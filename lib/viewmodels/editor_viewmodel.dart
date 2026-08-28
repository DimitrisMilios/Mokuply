import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import '../models/canvas_device_item.dart';
import '../models/canvas_image_item.dart';
import '../models/canvas_text_item.dart';
import '../models/project_template.dart';
import '../models/template_data.dart';
import '../services/export_service.dart';
import '../services/file_service.dart';
import '../widgets/canvas/canvas_mockup_widget.dart';

/// Editor ViewModel — manages multi-screenshot project sets, canvas elements, and app flow.
class EditorViewModel extends ChangeNotifier {
  bool _isHomeScreen = true;
  ProjectTemplate? _activeTemplate;
  List<TemplateData> _screenshots = ProjectTemplate.saasModern().initialScreenshots;
  int _selectedIndex = 0;

  // Selected element tracking on active canvas screen
  String? _selectedElementId; // e.g. 'title', 'subtitle', 'dev_123', 'img_123', 'txt_123'
  String? _selectedDeviceId;
  String? _selectedImageId;
  String? _selectedTextId;

  // Export State
  bool _isExporting = false;
  int _exportingProgressIndex = 0;
  int _exportingTotalSteps = 1;
  String _exportingStatusText = '';

  // Flow & State Accessors
  bool get isHomeScreen => _isHomeScreen;
  ProjectTemplate? get activeTemplate => _activeTemplate;
  List<TemplateData> get screenshots => List.unmodifiable(_screenshots);
  int get selectedIndex => _selectedIndex;
  int get screenshotsCount => _screenshots.length;
  bool get isExporting => _isExporting;
  int get exportingProgressIndex => _exportingProgressIndex;
  int get exportingTotalSteps => _exportingTotalSteps;
  String get exportingStatusText => _exportingStatusText;

  // Active Element Selection Accessors
  String? get selectedElementId => _selectedElementId;
  String? get selectedDeviceId => _selectedDeviceId;
  String? get selectedImageId => _selectedImageId;
  String? get selectedTextId => _selectedTextId;

  /// Gets currently active screenshot item
  TemplateData get data => _screenshots[_selectedIndex.clamp(0, _screenshots.length - 1)];

  // Convenience getters delegating to active screenshot item
  TargetPlatformType get platform => data.platform;
  LayoutMode get layoutMode => data.layoutMode;
  DeviceFrameStyle get frameStyle => selectedDevice?.frameStyle ?? data.frameStyle;
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

  // Multi-Element Collections Accessors
  List<CanvasDeviceItem> get devices => data.effectiveDevices;
  List<CanvasImageItem> get customImageItems => data.customImageItems;
  List<CanvasTextItem> get customTextItems => data.customTextItems;

  /// Returns currently selected device frame on canvas
  CanvasDeviceItem? get selectedDevice {
    final devList = devices;
    if (devList.isEmpty) return null;
    if (_selectedDeviceId != null) {
      final match = devList.where((d) => d.id == _selectedDeviceId).firstOrNull;
      if (match != null) return match;
    }
    return devList.first;
  }

  /// Returns currently selected custom image asset on canvas
  CanvasImageItem? get selectedCustomImage {
    final imgList = customImageItems;
    if (imgList.isEmpty) return null;
    if (_selectedImageId != null) {
      final match = imgList.where((i) => i.id == _selectedImageId).firstOrNull;
      if (match != null) return match;
    }
    return imgList.first;
  }

  /// Single Device backward-compatible properties
  Uint8List? get screenshotBytes => selectedDevice?.screenshotBytes ?? data.screenshotBytes;
  Uint8List? get iphoneScreenshotBytes => data.iphoneScreenshotBytes;
  Uint8List? get samsungScreenshotBytes => data.samsungScreenshotBytes;
  Uint8List? get effectiveScreenshotBytes => selectedDevice?.screenshotBytes ?? data.effectiveScreenshotBytes;
  double get deviceScale => selectedDevice?.scale ?? data.deviceScale;
  double get deviceOffsetX => selectedDevice?.offsetX ?? data.deviceOffsetX;
  double get deviceOffsetY => selectedDevice?.offsetY ?? data.deviceOffsetY;
  double get deviceRotation => selectedDevice?.rotation ?? data.deviceRotation;
  bool get hasShadow => selectedDevice?.hasShadow ?? data.hasShadow;

  double get textOffsetX => data.textOffsetX; // Title X offset
  double get textOffsetY => data.textOffsetY; // Title Y offset
  double get subtitleOffsetX => data.subtitleOffsetX;
  double get subtitleOffsetY => data.subtitleOffsetY;

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

  // --- Element Selection Handlers ---

  void selectElement(String? id) {
    _selectedElementId = id;
    if (id == null) {
      _selectedDeviceId = null;
      _selectedImageId = null;
      _selectedTextId = null;
    } else if (id.startsWith('dev_')) {
      _selectedDeviceId = id;
    } else if (id.startsWith('img_')) {
      _selectedImageId = id;
    } else if (id.startsWith('txt_')) {
      _selectedTextId = id;
    }
    notifyListeners();
  }

  void selectDevice(String deviceId) {
    _selectedDeviceId = deviceId;
    _selectedElementId = deviceId;
    notifyListeners();
  }

  void selectCustomImage(String imageId) {
    _selectedImageId = imageId;
    _selectedElementId = imageId;
    notifyListeners();
  }

  // --- Multi-Device Frame Mutators ---

  void addDeviceFrame([DeviceFrameStyle? style]) {
    final currentDevices = List<CanvasDeviceItem>.from(data.effectiveDevices);
    final String newId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
    final double offsetStep = (currentDevices.length * 90.0) - 45.0;

    final newDevice = CanvasDeviceItem(
      id: newId,
      frameStyle: style ?? (platform == TargetPlatformType.googlePlay ? DeviceFrameStyle.samsungS26Ultra : DeviceFrameStyle.iphone16ProMax),
      scale: 0.75,
      offsetX: offsetStep,
      offsetY: 0.0,
      rotation: 0.0,
      hasShadow: true,
    );

    currentDevices.add(newDevice);
    _selectedDeviceId = newId;
    _selectedElementId = newId;
    _updateCurrentScreenshot(data.copyWith(devices: currentDevices));
  }

  void removeDeviceFrame(String deviceId) {
    final currentDevices = List<CanvasDeviceItem>.from(data.effectiveDevices);
    if (currentDevices.length <= 1) return; // Keep at least 1 device frame

    currentDevices.removeWhere((d) => d.id == deviceId);
    if (_selectedDeviceId == deviceId) {
      _selectedDeviceId = currentDevices.isNotEmpty ? currentDevices.first.id : null;
      _selectedElementId = _selectedDeviceId;
    }
    _updateCurrentScreenshot(data.copyWith(devices: currentDevices));
  }

  void updateDeviceFrame(String deviceId, CanvasDeviceItem updated) {
    final updatedList = data.effectiveDevices.map((d) {
      return d.id == deviceId ? updated : d;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(devices: updatedList));
  }

  void setDeviceFrameOffsetsForIndex(int index, String deviceId, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      final currentPlatform = _screenshots[index].platform;
      final currentList = _screenshots[index].effectiveDevices;
      final updatedList = currentList.map((d) {
        if (d.id == deviceId) {
          if (currentPlatform == TargetPlatformType.appStore) {
            return d.copyWith(
              offsetX: offsetX,
              offsetY: offsetY,
              appStoreOffsetX: offsetX,
              appStoreOffsetY: offsetY,
              googlePlayOffsetX: d.googlePlayOffsetX ?? offsetX,
              googlePlayOffsetY: d.googlePlayOffsetY ?? offsetY,
            );
          } else {
            return d.copyWith(
              offsetX: offsetX,
              offsetY: offsetY,
              googlePlayOffsetX: offsetX,
              googlePlayOffsetY: offsetY,
              appStoreOffsetX: d.appStoreOffsetX ?? offsetX,
              appStoreOffsetY: d.appStoreOffsetY ?? offsetY,
            );
          }
        }
        return d;
      }).toList();
      _screenshots[index] = _screenshots[index].copyWith(devices: updatedList);
      notifyListeners();
    }
  }

  Future<void> pickDeviceFrameScreenshot(String deviceId) async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      setDeviceFrameScreenshot(deviceId, bytes);
    }
  }

  void setDeviceFrameScreenshot(String deviceId, Uint8List? bytes) {
    final updatedList = data.effectiveDevices.map((d) {
      return d.id == deviceId ? d.copyWith(screenshotBytes: () => bytes) : d;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(devices: updatedList));
  }

  void setDeviceFrameStyle(String deviceId, DeviceFrameStyle style) {
    final updatedList = data.effectiveDevices.map((d) {
      return d.id == deviceId ? d.copyWith(frameStyle: style) : d;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(devices: updatedList));
  }

  void setDeviceFrameScale(String deviceId, double scale) {
    final updatedList = data.effectiveDevices.map((d) {
      return d.id == deviceId ? d.copyWith(scale: scale) : d;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(devices: updatedList));
  }

  void setDeviceFrameRotation(String deviceId, double rotation) {
    final updatedList = data.effectiveDevices.map((d) {
      return d.id == deviceId ? d.copyWith(rotation: rotation) : d;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(devices: updatedList));
  }

  void setDeviceFrameShadow(String deviceId, bool hasShadow) {
    final updatedList = data.effectiveDevices.map((d) {
      return d.id == deviceId ? d.copyWith(hasShadow: hasShadow) : d;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(devices: updatedList));
  }

  // --- Multi-Custom Image Assets Mutators ---

  Future<void> pickAndAddCustomImageItem() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      addCustomImageItem(bytes);
    }
  }

  void addCustomImageItem(Uint8List bytes) {
    final String newId = 'img_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = CanvasImageItem(
      id: newId,
      imageBytes: bytes,
      scale: 1.0,
      offsetX: 0.0,
      offsetY: 0.0,
      rotation: 0.0,
      opacity: 1.0,
      hasShadow: false,
    );

    final updatedList = List<CanvasImageItem>.from(data.customImageItems)..add(newItem);
    _selectedImageId = newId;
    _selectedElementId = newId;
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  void removeCustomImageItem(String imageId) {
    final updatedList = data.customImageItems.where((i) => i.id != imageId).toList();
    if (_selectedImageId == imageId) {
      _selectedImageId = updatedList.isNotEmpty ? updatedList.first.id : null;
      _selectedElementId = _selectedImageId;
    }
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  void updateCustomImageItem(String imageId, CanvasImageItem updated) {
    final updatedList = data.customImageItems.map((i) {
      return i.id == imageId ? updated : i;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  void setCustomImageOffsetsForIndex(int index, String imageId, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      final currentPlatform = _screenshots[index].platform;
      final currentList = _screenshots[index].customImageItems;
      final updatedList = currentList.map((i) {
        if (i.id == imageId) {
          if (currentPlatform == TargetPlatformType.appStore) {
            return i.copyWith(
              offsetX: offsetX,
              offsetY: offsetY,
              appStoreOffsetX: offsetX,
              appStoreOffsetY: offsetY,
              googlePlayOffsetX: i.googlePlayOffsetX ?? offsetX,
              googlePlayOffsetY: i.googlePlayOffsetY ?? offsetY,
            );
          } else {
            return i.copyWith(
              offsetX: offsetX,
              offsetY: offsetY,
              googlePlayOffsetX: offsetX,
              googlePlayOffsetY: offsetY,
              appStoreOffsetX: i.appStoreOffsetX ?? offsetX,
              appStoreOffsetY: i.appStoreOffsetY ?? offsetY,
            );
          }
        }
        return i;
      }).toList();
      _screenshots[index] = _screenshots[index].copyWith(customImageItems: updatedList);
      notifyListeners();
    }
  }

  void setCustomImageScale(String imageId, double scale) {
    final updatedList = data.customImageItems.map((i) {
      return i.id == imageId ? i.copyWith(scale: scale) : i;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  void setCustomImageRotation(String imageId, double rotation) {
    final updatedList = data.customImageItems.map((i) {
      return i.id == imageId ? i.copyWith(rotation: rotation) : i;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  void setCustomImageOpacity(String imageId, double opacity) {
    final updatedList = data.customImageItems.map((i) {
      return i.id == imageId ? i.copyWith(opacity: opacity) : i;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  void setCustomImageShadow(String imageId, bool hasShadow) {
    final updatedList = data.customImageItems.map((i) {
      return i.id == imageId ? i.copyWith(hasShadow: hasShadow) : i;
    }).toList();
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  // --- Mutators for Canvas Text Items & Offsets ---

  void setDeviceOffsetX(double offsetX) {
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameOffsetsForIndex(_selectedIndex, targetDev.id, offsetX, data.deviceOffsetY);
    } else {
      _updateCurrentScreenshot(data.copyWith(deviceOffsetX: offsetX));
    }
  }

  void setDeviceOffsetY(double offsetY) {
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameOffsetsForIndex(_selectedIndex, targetDev.id, data.deviceOffsetX, offsetY);
    } else {
      _updateCurrentScreenshot(data.copyWith(deviceOffsetY: offsetY));
    }
  }

  void setDeviceOffsets(double offsetX, double offsetY) {
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameOffsetsForIndex(_selectedIndex, targetDev.id, offsetX, offsetY);
    } else {
      _updateCurrentScreenshot(data.copyWith(deviceOffsetX: offsetX, deviceOffsetY: offsetY));
    }
  }

  void setDeviceOffsetsForIndex(int index, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      final targetDev = _screenshots[index].effectiveDevices.firstOrNull;
      if (targetDev != null) {
        setDeviceFrameOffsetsForIndex(index, targetDev.id, offsetX, offsetY);
      } else {
        _screenshots[index] = _screenshots[index].copyWith(deviceOffsetX: offsetX, deviceOffsetY: offsetY);
        notifyListeners();
      }
    }
  }

  void setTextOffsets(double offsetX, double offsetY) {
    _updateCurrentScreenshot(data.copyWith(textOffsetX: offsetX, textOffsetY: offsetY));
  }

  void setTextOffsetsForIndex(int index, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      final p = _screenshots[index].platform;
      if (p == TargetPlatformType.appStore) {
        _screenshots[index] = _screenshots[index].copyWith(
          textOffsetX: offsetX,
          textOffsetY: offsetY,
          appStoreTextOffsetX: offsetX,
          appStoreTextOffsetY: offsetY,
          googlePlayTextOffsetX: _screenshots[index].googlePlayTextOffsetX ?? offsetX,
          googlePlayTextOffsetY: _screenshots[index].googlePlayTextOffsetY ?? offsetY,
        );
      } else {
        _screenshots[index] = _screenshots[index].copyWith(
          textOffsetX: offsetX,
          textOffsetY: offsetY,
          googlePlayTextOffsetX: offsetX,
          googlePlayTextOffsetY: offsetY,
          appStoreTextOffsetX: _screenshots[index].appStoreTextOffsetX ?? offsetX,
          appStoreTextOffsetY: _screenshots[index].appStoreTextOffsetY ?? offsetY,
        );
      }
      notifyListeners();
    }
  }

  void setSubtitleOffsets(double offsetX, double offsetY) {
    _updateCurrentScreenshot(data.copyWith(subtitleOffsetX: offsetX, subtitleOffsetY: offsetY));
  }

  void setSubtitleOffsetsForIndex(int index, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      final p = _screenshots[index].platform;
      if (p == TargetPlatformType.appStore) {
        _screenshots[index] = _screenshots[index].copyWith(
          subtitleOffsetX: offsetX,
          subtitleOffsetY: offsetY,
          appStoreSubtitleOffsetX: offsetX,
          appStoreSubtitleOffsetY: offsetY,
          googlePlaySubtitleOffsetX: _screenshots[index].googlePlaySubtitleOffsetX ?? offsetX,
          googlePlaySubtitleOffsetY: _screenshots[index].googlePlaySubtitleOffsetY ?? offsetY,
        );
      } else {
        _screenshots[index] = _screenshots[index].copyWith(
          subtitleOffsetX: offsetX,
          subtitleOffsetY: offsetY,
          googlePlaySubtitleOffsetX: offsetX,
          googlePlaySubtitleOffsetY: offsetY,
          appStoreSubtitleOffsetX: _screenshots[index].appStoreSubtitleOffsetX ?? offsetX,
          appStoreSubtitleOffsetY: _screenshots[index].appStoreSubtitleOffsetY ?? offsetY,
        );
      }
      notifyListeners();
    }
  }

  void resetCanvasOffsets() {
    final resetDevices = data.effectiveDevices.map((d) {
      return d.copyWith(
        offsetX: 0.0,
        offsetY: 0.0,
        rotation: 0.0,
        scale: 0.85,
        appStoreOffsetX: 0.0,
        appStoreOffsetY: 0.0,
        googlePlayOffsetX: 0.0,
        googlePlayOffsetY: 0.0,
      );
    }).toList();

    _updateCurrentScreenshot(data.copyWith(
      devices: resetDevices,
      deviceOffsetX: 0.0,
      deviceOffsetY: 0.0,
      textOffsetX: 0.0,
      textOffsetY: 0.0,
      subtitleOffsetX: 0.0,
      subtitleOffsetY: 0.0,
      appStoreTextOffsetX: 0.0,
      appStoreTextOffsetY: 0.0,
      googlePlayTextOffsetX: 0.0,
      googlePlayTextOffsetY: 0.0,
      appStoreSubtitleOffsetX: 0.0,
      appStoreSubtitleOffsetY: 0.0,
      googlePlaySubtitleOffsetX: 0.0,
      googlePlaySubtitleOffsetY: 0.0,
      deviceRotation: 0.0,
      deviceScale: 0.85,
    ));
  }

  // --- Mutators for Custom Extra Text Elements ---

  void addCustomTextElement() {
    final newId = 'txt_${DateTime.now().millisecondsSinceEpoch}';
    final newItem = CanvasTextItem(
      id: newId,
      text: 'New Text Element',
      fontSize: 28.0,
      color: Colors.white,
      font: 'Outfit',
      weight: FontWeight.w600,
      alignment: TextAlign.center,
      offsetX: 0.0,
      offsetY: 80.0,
      rotation: 0.0,
    );
    final updatedList = List<CanvasTextItem>.from(data.customTextItems)..add(newItem);
    _selectedTextId = newId;
    _selectedElementId = newId;
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
      final updatedList = currentList.map((item) => item.id == id ? updated : item).toList();
      _screenshots[index] = _screenshots[index].copyWith(customTextItems: updatedList);
      notifyListeners();
    }
  }

  void setCustomTextElementOffsetsForIndex(int index, String id, double offsetX, double offsetY) {
    if (index >= 0 && index < _screenshots.length) {
      final currentPlatform = _screenshots[index].platform;
      final currentList = _screenshots[index].customTextItems;
      final updatedList = currentList.map((item) {
        if (item.id == id) {
          if (currentPlatform == TargetPlatformType.appStore) {
            return item.copyWith(
              offsetX: offsetX,
              offsetY: offsetY,
              appStoreOffsetX: offsetX,
              appStoreOffsetY: offsetY,
              googlePlayOffsetX: item.googlePlayOffsetX ?? offsetX,
              googlePlayOffsetY: item.googlePlayOffsetY ?? offsetY,
            );
          } else {
            return item.copyWith(
              offsetX: offsetX,
              offsetY: offsetY,
              googlePlayOffsetX: offsetX,
              googlePlayOffsetY: offsetY,
              appStoreOffsetX: item.appStoreOffsetX ?? offsetX,
              appStoreOffsetY: item.appStoreOffsetY ?? offsetY,
            );
          }
        }
        return item;
      }).toList();
      _screenshots[index] = _screenshots[index].copyWith(customTextItems: updatedList);
      notifyListeners();
    }
  }

  void removeCustomTextElement(String id) {
    final updatedList = data.customTextItems.where((item) => item.id != id).toList();
    if (_selectedTextId == id) {
      _selectedTextId = updatedList.isNotEmpty ? updatedList.first.id : null;
      _selectedElementId = _selectedTextId;
    }
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
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameScreenshot(targetDev.id, bytes);
    }
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
    _selectedElementId = null;
    _selectedDeviceId = null;
    _selectedImageId = null;
    _selectedTextId = null;
    notifyListeners();
  }

  void openEditorWithNewProject() {
    _activeTemplate = ProjectTemplate.saasModern();
    _screenshots = List.from(_activeTemplate!.initialScreenshots);
    _selectedIndex = 0;
    _isHomeScreen = false;
    _selectedElementId = null;
    _selectedDeviceId = null;
    _selectedImageId = null;
    _selectedTextId = null;
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
      _selectedElementId = null;
      _selectedDeviceId = null;
      _selectedImageId = null;
      _selectedTextId = null;
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
    if (_screenshots.length <= 1) return;
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
    _screenshots = _screenshots.map((s) {
      final targetDefaultFrameStyle = newPlatform == TargetPlatformType.googlePlay
          ? DeviceFrameStyle.samsungS26Ultra
          : DeviceFrameStyle.iphone16ProMax;

      final updatedDevices = s.effectiveDevices.map((d) {
        if (newPlatform == TargetPlatformType.googlePlay && d.frameStyle == DeviceFrameStyle.iphone16ProMax) {
          return d.copyWith(frameStyle: DeviceFrameStyle.samsungS26Ultra);
        }
        if (newPlatform == TargetPlatformType.appStore && d.frameStyle == DeviceFrameStyle.samsungS26Ultra) {
          return d.copyWith(frameStyle: DeviceFrameStyle.iphone16ProMax);
        }
        return d;
      }).toList();

      return s.copyWith(
        platform: newPlatform,
        frameStyle: targetDefaultFrameStyle,
        devices: updatedDevices,
      );
    }).toList();
    notifyListeners();
  }

  void setLayoutMode(LayoutMode mode) {
    _updateCurrentScreenshot(data.copyWith(layoutMode: mode));
  }

  void setFrameStyle(DeviceFrameStyle style) {
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameStyle(targetDev.id, style);
    } else {
      _updateCurrentScreenshot(data.copyWith(frameStyle: style));
    }
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
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameScale(targetDev.id, scale);
    } else {
      _updateCurrentScreenshot(data.copyWith(deviceScale: scale));
    }
  }

  void setDeviceRotation(double degrees) {
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameRotation(targetDev.id, degrees);
    } else {
      _updateCurrentScreenshot(data.copyWith(deviceRotation: degrees));
    }
  }

  void setHasShadow(bool shadow) {
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameShadow(targetDev.id, shadow);
    } else {
      _updateCurrentScreenshot(data.copyWith(hasShadow: shadow));
    }
  }

  void resetToDefaults() {
    _screenshots = ProjectTemplate.saasModern().initialScreenshots;
    _selectedIndex = 0;
    _selectedElementId = null;
    _selectedDeviceId = null;
    _selectedImageId = null;
    _selectedTextId = null;
    notifyListeners();
  }

  /// Pick an image file for currently selected screenshot/device
  Future<void> pickScreenshot() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      final targetDev = selectedDevice;
      if (targetDev != null) {
        setDeviceFrameScreenshot(targetDev.id, bytes);
      } else {
        setScreenshotBytes(bytes);
      }
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
    _exportingTotalSteps = _screenshots.length;
    _exportingStatusText = 'Preparing screenshots...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 16));

    try {
      final Size targetSize = Size(targetPlatform.targetWidth, targetPlatform.targetHeight);
      final String folderName = targetPlatform == TargetPlatformType.appStore
          ? 'Apple_App_Store_1320x2868'
          : 'Google_Play_Store_1440x2560';

      final Map<String, Uint8List> zipFiles = {};

      for (int i = 0; i < _screenshots.length; i++) {
        _exportingProgressIndex = i + 1;
        _exportingStatusText = 'Rendering Screen #${i + 1} of ${_screenshots.length}...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 20));

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
          context: context, // ignore: use_build_context_synchronously
        );

        final filename = '$folderName/Screen_${i + 1}.png';
        zipFiles[filename] = pngBytes;
        await Future.delayed(const Duration(milliseconds: 16));
      }

      _exportingStatusText = 'Packaging 100% Lossless ZIP Archive...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 32));

      final zipBytes = ExportService.createZipArchive(zipFiles);
      final zipFilename = 'Mokuply_$folderName.zip';
      await ExportService.downloadFileWeb(
        bytes: zipBytes,
        filename: zipFilename,
        mimeType: 'application/zip',
      );
    } finally {
      _isExporting = false;
      _exportingProgressIndex = 0;
      _exportingStatusText = '';
      notifyListeners();
    }
  }

  /// Exports BOTH store platform packages (Apple 1320x2868 + Google 1440x2560) in a master ZIP bundle.
  Future<void> exportBothPlatformsPack({required BuildContext context}) async {
    _isExporting = true;
    _exportingProgressIndex = 0;
    _exportingTotalSteps = _screenshots.length * 2;
    _exportingStatusText = 'Preparing store bundles...';
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 16));

    try {
      final Map<String, Uint8List> zipFiles = {};

      // 1. Apple App Store Screens (1320 x 2868)
      final appleSize = Size(TargetPlatformType.appStore.targetWidth, TargetPlatformType.appStore.targetHeight);
      for (int i = 0; i < _screenshots.length; i++) {
        _exportingProgressIndex = i + 1;
        _exportingStatusText = 'Rendering Apple Screen #${i + 1} of ${_screenshots.length}...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 20));

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
          context: context, // ignore: use_build_context_synchronously
        );

        zipFiles['Apple_App_Store_1320x2868/Screen_${i + 1}.png'] = pngBytes;
        await Future.delayed(const Duration(milliseconds: 16));
      }

      // 2. Google Play Store Screens (1440 x 2560)
      final googleSize = Size(TargetPlatformType.googlePlay.targetWidth, TargetPlatformType.googlePlay.targetHeight);
      for (int i = 0; i < _screenshots.length; i++) {
        _exportingProgressIndex = _screenshots.length + i + 1;
        _exportingStatusText = 'Rendering Google Screen #${i + 1} of ${_screenshots.length}...';
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 20));

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
        await Future.delayed(const Duration(milliseconds: 16));
      }

      _exportingStatusText = 'Packaging Complete Dual-Store ZIP Bundle...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 32));

      final zipBytes = ExportService.createZipArchive(zipFiles);
      const zipFilename = 'Mokuply_StoreScreenshots_AllPlatforms.zip';
      await ExportService.downloadFileWeb(
        bytes: zipBytes,
        filename: zipFilename,
        mimeType: 'application/zip',
      );
    } finally {
      _isExporting = false;
      _exportingProgressIndex = 0;
      _exportingStatusText = '';
      notifyListeners();
    }
  }

  /// Sequential High-Res PNG Batch Download for current active platform screenshots.
  Future<void> exportAllScreenshots({required BuildContext context}) async {
    _isExporting = true;
    _exportingProgressIndex = 0;
    _exportingTotalSteps = _screenshots.length;
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
