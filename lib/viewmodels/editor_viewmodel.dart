import 'dart:async';
import 'dart:convert';
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
import '../services/storage_service.dart';
import '../widgets/canvas/canvas_mockup_widget.dart';

/// Sections of the screen inspector shown when no element is selected.
/// (Layers are always listed at the top of the inspector.)
enum ScreenInspectorSection { layout, background }

/// Editor ViewModel — manages the multi-screen project, canvas elements and app flow.
///
/// Every screen is authored once in [DesignSpace]; [platform] only selects
/// which store is previewed. Positions, sizes and tilts are shared by both
/// stores, while each phone frame carries its own iPhone and Android screenshot.
class EditorViewModel extends ChangeNotifier {
  bool _isHomeScreen = true;
  ProjectTemplate? _activeTemplate;
  List<TemplateData> _screenshots = ProjectTemplate.teamOrganize().initialScreenshots;
  int _selectedIndex = 0;

  // Local persistence draft state
  List<TemplateData>? _savedDraftScreenshots;
  bool _isAutoSaving = false;

  // Selected element tracking on the active screen
  String? _selectedElementId; // 'title', 'subtitle', 'dev_*', 'img_*', 'txt_*'
  String? _selectedDeviceId;
  String? _selectedImageId;
  String? _selectedTextId;

  // Inspector section shown while nothing on the canvas is selected
  ScreenInspectorSection _screenSection = ScreenInspectorSection.layout;

  // Canvas rows: both stores live side by side, or only the active one.
  bool _showBothStores = true;

  // Bumped when the canvas asks the inspector to focus its text field
  // (double-click on a text element).
  int _textFocusRequest = 0;

  // Export state
  bool _isExporting = false;
  int _exportingProgressIndex = 0;
  int _exportingTotalSteps = 1;
  String _exportingStatusText = '';

  // --- Flow & state accessors ---

  bool get isHomeScreen => _isHomeScreen;
  ProjectTemplate? get activeTemplate => _activeTemplate;
  List<TemplateData> get screenshots => List.unmodifiable(_screenshots);
  int get selectedIndex => _selectedIndex;
  int get screenshotsCount => _screenshots.length;
  bool get isExporting => _isExporting;
  int get exportingProgressIndex => _exportingProgressIndex;
  int get exportingTotalSteps => _exportingTotalSteps;
  String get exportingStatusText => _exportingStatusText;
  bool get hasSavedDraft => _savedDraftScreenshots != null && _savedDraftScreenshots!.isNotEmpty;
  bool get isAutoSaving => _isAutoSaving;

  String? get selectedElementId => _selectedElementId;
  String? get selectedDeviceId => _selectedDeviceId;
  String? get selectedImageId => _selectedImageId;
  String? get selectedTextId => _selectedTextId;
  ScreenInspectorSection get screenSection => _screenSection;
  bool get showBothStores => _showBothStores;
  int get textFocusRequest => _textFocusRequest;

  /// Store rows drawn on the canvas, top to bottom.
  List<TargetPlatformType> get visibleStores =>
      _showBothStores ? const [TargetPlatformType.appStore, TargetPlatformType.googlePlay] : [platform];

  /// The active screen.
  TemplateData get data => _screenshots[_selectedIndex.clamp(0, _screenshots.length - 1)];

  /// Display name of screen [index] (falls back to its number).
  String screenNameAt(int index) {
    final name = _screenshots[index].name.trim();
    return name.isEmpty ? 'Screen ${index + 1}' : name;
  }

  /// Active store: the row last clicked on the canvas. Screenshot uploads and
  /// single-store downloads target it. Both stores are always exported.
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

  List<CanvasDeviceItem> get devices => data.effectiveDevices;
  List<CanvasImageItem> get customImageItems => data.customImageItems;
  List<CanvasTextItem> get customTextItems => data.customTextItems;

  /// Selected phone frame on the active screen (falls back to the first one).
  CanvasDeviceItem? get selectedDevice {
    final devList = devices;
    if (devList.isEmpty) return null;
    if (_selectedDeviceId != null) {
      final match = devList.where((d) => d.id == _selectedDeviceId).firstOrNull;
      if (match != null) return match;
    }
    return devList.first;
  }

  /// Selected custom image asset on the active screen (falls back to the first one).
  CanvasImageItem? get selectedCustomImage {
    final imgList = customImageItems;
    if (imgList.isEmpty) return null;
    if (_selectedImageId != null) {
      final match = imgList.where((i) => i.id == _selectedImageId).firstOrNull;
      if (match != null) return match;
    }
    return imgList.first;
  }

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
    return StoreSpecs.gradientPresets[currentData.selectedGradientIndex % StoreSpecs.gradientPresets.length]
        .toDecoration();
  }

  // --- Element selection ---

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

  void selectDevice(String deviceId) => selectElement(deviceId);

  void selectCustomImage(String imageId) => selectElement(imageId);

  /// Deselects everything and opens [section] of the screen inspector.
  void showScreenSection(ScreenInspectorSection section) {
    _screenSection = section;
    _clearSelection();
    notifyListeners();
  }

  void setShowBothStores(bool value) {
    if (_showBothStores == value) return;
    _showBothStores = value;
    notifyListeners();
  }

  /// Asks the inspector to focus the text field of the selected text element.
  void requestTextFocus() {
    _textFocusRequest++;
    notifyListeners();
  }

  // --- Generic element operations (any element type, by id) ---

  /// True when [id] refers to an element that can be scaled with the corner handles.
  bool elementExists(String id) {
    if (id == 'title' || id == 'subtitle') return true;
    return devices.any((d) => d.id == id) ||
        customImageItems.any((i) => i.id == id) ||
        customTextItems.any((t) => t.id == id);
  }

  /// Resizes any element of screen [index]: phone frames and images take a
  /// scale factor, text elements take a font size in export pixels.
  void resizeElement(int index, String id, double value) {
    if (index < 0 || index >= _screenshots.length) return;
    final screen = _screenshots[index];
    final TemplateData updated;

    if (id == 'title') {
      updated = screen.copyWith(titleSize: value.clamp(TextSizeLimits.titleMin, TextSizeLimits.titleMax));
    } else if (id == 'subtitle') {
      updated = screen.copyWith(subtitleSize: value.clamp(TextSizeLimits.subtitleMin, TextSizeLimits.subtitleMax));
    } else if (id.startsWith('dev_')) {
      final v = value.clamp(ScaleLimits.deviceMin, ScaleLimits.deviceMax);
      updated = screen.copyWith(
        devices: screen.effectiveDevices.map((d) => d.id == id ? d.copyWith(scale: v) : d).toList(),
      );
    } else if (id.startsWith('img_')) {
      final v = value.clamp(ScaleLimits.imageMin, ScaleLimits.imageMax);
      updated = screen.copyWith(
        customImageItems: screen.customImageItems.map((i) => i.id == id ? i.copyWith(scale: v) : i).toList(),
      );
    } else if (id.startsWith('txt_')) {
      final v = value.clamp(TextSizeLimits.customMin, TextSizeLimits.customMax);
      updated = screen.copyWith(
        customTextItems: screen.customTextItems.map((t) => t.id == id ? t.copyWith(fontSize: v) : t).toList(),
      );
    } else {
      return;
    }

    _screenshots[index] = updated;
    _scheduleAutoSave();
    notifyListeners();
  }

  /// Rotates a phone frame, image or extra text element of screen [index].
  /// The headline and subtitle cannot rotate.
  void rotateElement(int index, String id, double degrees) {
    if (index < 0 || index >= _screenshots.length) return;
    final screen = _screenshots[index];
    final TemplateData updated;
    final double deg = _normalizeDegrees(degrees);

    if (id.startsWith('dev_')) {
      updated = screen.copyWith(
        devices: screen.effectiveDevices.map((d) => d.id == id ? d.copyWith(rotation: deg) : d).toList(),
      );
    } else if (id.startsWith('img_')) {
      updated = screen.copyWith(
        customImageItems: screen.customImageItems.map((i) => i.id == id ? i.copyWith(rotation: deg) : i).toList(),
      );
    } else if (id.startsWith('txt_')) {
      updated = screen.copyWith(
        customTextItems: screen.customTextItems.map((t) => t.id == id ? t.copyWith(rotation: deg) : t).toList(),
      );
    } else {
      return;
    }

    _screenshots[index] = updated;
    _scheduleAutoSave();
    notifyListeners();
  }

  static double _normalizeDegrees(double deg) {
    double d = deg % 360.0;
    if (d > 180.0) d -= 360.0;
    if (d <= -180.0) d += 360.0;
    return d;
  }

  /// Removes any element of the active screen. The headline and subtitle are
  /// cleared instead of removed; the last phone frame is kept.
  void removeElement(String id) {
    if (id == 'title') {
      setTitleText('');
      if (_selectedElementId == id) selectElement(null);
    } else if (id == 'subtitle') {
      setSubtitleText('');
      if (_selectedElementId == id) selectElement(null);
    } else if (id.startsWith('dev_')) {
      if (devices.length <= 1) return;
      removeDeviceFrame(id);
      selectElement(null);
    } else if (id.startsWith('img_')) {
      removeCustomImageItem(id);
      selectElement(null);
    } else if (id.startsWith('txt_')) {
      removeCustomTextElement(id);
      selectElement(null);
    }
  }

  void removeSelectedElement() {
    final id = _selectedElementId;
    if (id != null) removeElement(id);
  }

  /// Duplicates a phone frame, image or extra text element next to the
  /// original and selects the copy. The headline and subtitle are unique.
  void duplicateElement(String id) {
    final String stamp = DateTime.now().millisecondsSinceEpoch.toString();
    const double nudge = 40.0;

    if (id.startsWith('dev_')) {
      final source = devices.where((d) => d.id == id).firstOrNull;
      if (source == null) return;
      final copy = source.copyWith(id: 'dev_$stamp', offsetX: source.offsetX + nudge, offsetY: source.offsetY + nudge);
      _selectedDeviceId = copy.id;
      _selectedElementId = copy.id;
      _updateCurrentScreenshot(data.copyWith(devices: [...data.effectiveDevices, copy]));
    } else if (id.startsWith('img_')) {
      final source = customImageItems.where((i) => i.id == id).firstOrNull;
      if (source == null) return;
      final copy = source.copyWith(id: 'img_$stamp', offsetX: source.offsetX + nudge, offsetY: source.offsetY + nudge);
      _selectedImageId = copy.id;
      _selectedElementId = copy.id;
      _updateCurrentScreenshot(data.copyWith(customImageItems: [...data.customImageItems, copy]));
    } else if (id.startsWith('txt_')) {
      final source = customTextItems.where((t) => t.id == id).firstOrNull;
      if (source == null) return;
      final copy = source.copyWith(id: 'txt_$stamp', offsetX: source.offsetX + nudge, offsetY: source.offsetY + nudge);
      _selectedTextId = copy.id;
      _selectedElementId = copy.id;
      _updateCurrentScreenshot(data.copyWith(customTextItems: [...data.customTextItems, copy]));
    }
  }

  /// Moves the selected element by ([dx], [dy]) offset units (keyboard arrows).
  void nudgeSelected(double dx, double dy) {
    final id = _selectedElementId;
    if (id == null) return;
    final current = elementOffset(id);
    if (current == null) return;
    moveElement(_selectedIndex, id, current.dx + dx, current.dy + dy);
  }

  /// Stored offset of any element on the active screen, or null if it is gone.
  Offset? elementOffset(String id) {
    if (id == 'title') return Offset(data.textOffsetX, data.textOffsetY);
    if (id == 'subtitle') return Offset(data.subtitleOffsetX, data.subtitleOffsetY);
    final dev = devices.where((d) => d.id == id).firstOrNull;
    if (dev != null) return Offset(dev.offsetX, dev.offsetY);
    final img = customImageItems.where((i) => i.id == id).firstOrNull;
    if (img != null) return Offset(img.offsetX, img.offsetY);
    final txt = customTextItems.where((t) => t.id == id).firstOrNull;
    if (txt != null) return Offset(txt.offsetX, txt.offsetY);
    return null;
  }

  /// Uploads a screenshot for the store being previewed into the selected
  /// (or first) phone frame and keeps that frame selected.
  Future<void> uploadScreenshotToSelectedFrame() async {
    final device = selectedDevice;
    if (device == null) return;
    _selectedDeviceId = device.id;
    _selectedElementId = device.id;
    notifyListeners();
    await pickDeviceScreenshot(device.id, platform);
  }

  void _clearSelection() {
    _selectedElementId = null;
    _selectedDeviceId = null;
    _selectedImageId = null;
    _selectedTextId = null;
  }

  // --- Phone frames ---

  void addDeviceFrame([DeviceFrameStyle? style]) {
    final currentDevices = List<CanvasDeviceItem>.from(data.effectiveDevices);
    final String newId = 'dev_${DateTime.now().millisecondsSinceEpoch}';
    final double offsetStep = (currentDevices.length * 90.0) - 45.0;

    currentDevices.add(CanvasDeviceItem(
      id: newId,
      frameStyle: style ?? DeviceFrameStyle.realistic,
      scale: 0.75,
      offsetX: offsetStep,
    ));

    _selectedDeviceId = newId;
    _selectedElementId = newId;
    _updateCurrentScreenshot(data.copyWith(devices: currentDevices));
  }

  void removeDeviceFrame(String deviceId) {
    final currentDevices = List<CanvasDeviceItem>.from(data.effectiveDevices);
    if (currentDevices.length <= 1) return; // Keep at least one frame

    currentDevices.removeWhere((d) => d.id == deviceId);
    if (_selectedDeviceId == deviceId) {
      _selectedDeviceId = currentDevices.first.id;
      _selectedElementId = _selectedDeviceId;
    }
    _updateCurrentScreenshot(data.copyWith(devices: currentDevices));
  }

  void updateDeviceFrame(String deviceId, CanvasDeviceItem updated) {
    _updateDevice(deviceId, (_) => updated);
  }

  void setDeviceFrameStyle(String deviceId, DeviceFrameStyle style) {
    _updateDevice(deviceId, (d) => d.copyWith(frameStyle: style));
  }

  void setDeviceFrameScale(String deviceId, double scale) {
    _updateDevice(deviceId, (d) => d.copyWith(scale: scale));
  }

  void setDeviceFrameRotation(String deviceId, double rotation) {
    _updateDevice(deviceId, (d) => d.copyWith(rotation: rotation));
  }

  void setDeviceFrameShadow(String deviceId, bool hasShadow) {
    _updateDevice(deviceId, (d) => d.copyWith(hasShadow: hasShadow));
  }

  void setDeviceFrameOffsets(String deviceId, double offsetX, double offsetY) {
    _updateDevice(deviceId, (d) => d.copyWith(offsetX: offsetX, offsetY: offsetY));
  }

  /// Stores the screenshot shown inside [deviceId] on [target] (iPhone for the
  /// App Store, Android for Google Play). Pass null to remove it.
  void setDeviceScreenshot(String deviceId, TargetPlatformType target, Uint8List? bytes) {
    _updateDevice(deviceId, (d) => d.withScreenshotFor(target, bytes));
  }

  Future<void> pickDeviceScreenshot(String deviceId, TargetPlatformType target) async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      setDeviceScreenshot(deviceId, target, bytes);
    }
  }

  void _updateDevice(String deviceId, CanvasDeviceItem Function(CanvasDeviceItem) transform) {
    final updatedList = data.effectiveDevices.map((d) => d.id == deviceId ? transform(d) : d).toList();
    _updateCurrentScreenshot(data.copyWith(devices: updatedList));
  }

  // --- Custom image assets ---

  Future<void> pickAndAddCustomImageItem() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      addCustomImageItem(bytes);
    }
  }

  void addCustomImageItem(Uint8List bytes) {
    final String newId = 'img_${DateTime.now().millisecondsSinceEpoch}';
    final updatedList = List<CanvasImageItem>.from(data.customImageItems)
      ..add(CanvasImageItem(id: newId, imageBytes: bytes));
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
    _updateImage(imageId, (_) => updated);
  }

  void setCustomImageScale(String imageId, double scale) {
    _updateImage(imageId, (i) => i.copyWith(scale: scale));
  }

  void setCustomImageRotation(String imageId, double rotation) {
    _updateImage(imageId, (i) => i.copyWith(rotation: rotation));
  }

  void setCustomImageOpacity(String imageId, double opacity) {
    _updateImage(imageId, (i) => i.copyWith(opacity: opacity));
  }

  void setCustomImageShadow(String imageId, bool hasShadow) {
    _updateImage(imageId, (i) => i.copyWith(hasShadow: hasShadow));
  }

  void _updateImage(String imageId, CanvasImageItem Function(CanvasImageItem) transform) {
    final updatedList = data.customImageItems.map((i) => i.id == imageId ? transform(i) : i).toList();
    _updateCurrentScreenshot(data.copyWith(customImageItems: updatedList));
  }

  // --- Extra text elements ---

  void addCustomTextElement() {
    final newId = 'txt_${DateTime.now().millisecondsSinceEpoch}';
    final updatedList = List<CanvasTextItem>.from(data.customTextItems)
      ..add(CanvasTextItem(id: newId, text: 'New Text Element', fontSize: 28.0, offsetY: 80.0));
    _selectedTextId = newId;
    _selectedElementId = newId;
    _updateCurrentScreenshot(data.copyWith(customTextItems: updatedList));
  }

  void updateCustomTextElement(String id, CanvasTextItem updated) {
    final updatedList = data.customTextItems.map((item) => item.id == id ? updated : item).toList();
    _updateCurrentScreenshot(data.copyWith(customTextItems: updatedList));
  }

  void removeCustomTextElement(String id) {
    final updatedList = data.customTextItems.where((item) => item.id != id).toList();
    if (_selectedTextId == id) {
      _selectedTextId = updatedList.isNotEmpty ? updatedList.first.id : null;
      _selectedElementId = _selectedTextId;
    }
    _updateCurrentScreenshot(data.copyWith(customTextItems: updatedList));
  }

  // --- Positioning (shared by both stores) ---

  /// Moves any canvas element of screen [index] to ([offsetX], [offsetY]) in
  /// design offset units. Because positions are shared, the element moves on
  /// both stores at once.
  void moveElement(int index, String id, double offsetX, double offsetY) {
    if (index < 0 || index >= _screenshots.length) return;
    final screen = _screenshots[index];
    final TemplateData updated;

    if (id == 'title') {
      updated = screen.copyWith(textOffsetX: offsetX, textOffsetY: offsetY);
    } else if (id == 'subtitle') {
      updated = screen.copyWith(subtitleOffsetX: offsetX, subtitleOffsetY: offsetY);
    } else if (id.startsWith('dev_')) {
      updated = screen.copyWith(
        devices: screen.effectiveDevices
            .map((d) => d.id == id ? d.copyWith(offsetX: offsetX, offsetY: offsetY) : d)
            .toList(),
      );
    } else if (id.startsWith('img_')) {
      updated = screen.copyWith(
        customImageItems: screen.customImageItems
            .map((i) => i.id == id ? i.copyWith(offsetX: offsetX, offsetY: offsetY) : i)
            .toList(),
      );
    } else if (id.startsWith('txt_')) {
      updated = screen.copyWith(
        customTextItems: screen.customTextItems
            .map((t) => t.id == id ? t.copyWith(offsetX: offsetX, offsetY: offsetY) : t)
            .toList(),
      );
    } else {
      return;
    }

    _screenshots[index] = updated;
    _scheduleAutoSave();
    notifyListeners();
  }

  void resetCanvasOffsets() {
    final resetDevices = data.effectiveDevices
        .map((d) => d.copyWith(offsetX: 0.0, offsetY: 0.0, rotation: 0.0, scale: 0.92))
        .toList();

    _updateCurrentScreenshot(data.copyWith(
      devices: resetDevices,
      deviceOffsetX: 0.0,
      deviceOffsetY: 0.0,
      deviceRotation: 0.0,
      deviceScale: 0.92,
      textOffsetX: 0.0,
      textOffsetY: 0.0,
      subtitleOffsetX: 0.0,
      subtitleOffsetY: 0.0,
    ));
  }

  // --- Typography ---

  void setTitleText(String text) => _updateCurrentScreenshot(data.copyWith(titleText: text));
  void setSubtitleText(String text) => _updateCurrentScreenshot(data.copyWith(subtitleText: text));
  void setTitleFont(String font) => _updateCurrentScreenshot(data.copyWith(titleFont: font));
  void setSubtitleFont(String font) => _updateCurrentScreenshot(data.copyWith(subtitleFont: font));
  void setTitleSize(double size) => _updateCurrentScreenshot(data.copyWith(titleSize: size));
  void setSubtitleSize(double size) => _updateCurrentScreenshot(data.copyWith(subtitleSize: size));
  void setTextColor(Color color) => _updateCurrentScreenshot(data.copyWith(textColor: color));
  void setSubtitleColor(Color color) => _updateCurrentScreenshot(data.copyWith(subtitleColor: color));
  void setTitleWeight(FontWeight weight) => _updateCurrentScreenshot(data.copyWith(titleWeight: weight));
  void setSubtitleWeight(FontWeight weight) => _updateCurrentScreenshot(data.copyWith(subtitleWeight: weight));
  void setTitleAlignment(TextAlign alignment) => _updateCurrentScreenshot(data.copyWith(titleAlignment: alignment));
  void setSubtitleAlignment(TextAlign alignment) =>
      _updateCurrentScreenshot(data.copyWith(subtitleAlignment: alignment));

  // --- Background ---

  void setCustomBackgroundImage(Uint8List? bytes) {
    _updateCurrentScreenshot(data.copyWith(customBackgroundImageBytes: () => bytes));
  }

  Future<void> pickCustomBackgroundImage() async {
    final bytes = await FileService.pickImageBytes();
    if (bytes != null) {
      setCustomBackgroundImage(bytes);
    }
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

  // --- Flow navigation ---

  void openEditorWithTemplate(ProjectTemplate template) {
    _activeTemplate = template;
    _openScreens(List.from(template.initialScreenshots));
  }

  void openEditorWithNewProject() {
    _activeTemplate = ProjectTemplate.teamOrganize();
    _openScreens(List.from(_activeTemplate!.initialScreenshots));
  }

  void _openScreens(List<TemplateData> screens) {
    _screenshots = screens;
    _selectedIndex = 0;
    _isHomeScreen = false;
    _clearSelection();
    notifyListeners();
  }

  void goBackToHome() {
    _isHomeScreen = true;
    notifyListeners();
  }

  // --- Persistence ---

  Future<void> initStorage() async {
    try {
      final customTemplates = await StorageService.loadCustomTemplates();
      if (customTemplates.isNotEmpty) {
        ProjectTemplate.setCustomTemplates(customTemplates);
      }

      final draft = await StorageService.loadActiveDraft();
      if (draft != null && draft.isNotEmpty) {
        _savedDraftScreenshots = draft;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('EditorViewModel.initStorage error: $e');
    }
  }

  void restoreSavedDraft() {
    if (_savedDraftScreenshots != null && _savedDraftScreenshots!.isNotEmpty) {
      _openScreens(List.from(_savedDraftScreenshots!));
    }
  }

  void discardSavedDraft() {
    _savedDraftScreenshots = null;
    StorageService.clearActiveDraft();
    notifyListeners();
  }

  Timer? _autoSaveTimer;
  static const Duration _autoSaveDelay = Duration(milliseconds: 700);

  /// Debounced: slider drags and typing fire dozens of changes per second, so
  /// the draft is serialised once, shortly after the last change.
  void _scheduleAutoSave() {
    _isAutoSaving = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(_autoSaveDelay, () {
      _autoSaveTimer = null;
      StorageService.saveActiveDraft(_screenshots).then((_) {
        _isAutoSaving = false;
      });
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  ProjectTemplate _buildTemplate({
    required String title,
    required String category,
    required String description,
  }) {
    return ProjectTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: category,
      description: description,
      previewGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFF3B82F6)],
      platform: platform,
      initialScreenshots: List.from(_screenshots),
    );
  }

  Future<void> saveCurrentAsTemplate({
    required String title,
    required String category,
    required String description,
  }) async {
    ProjectTemplate.addCustomTemplate(_buildTemplate(title: title, category: category, description: description));
    await StorageService.saveCustomTemplates(ProjectTemplate.customTemplates);
    notifyListeners();
  }

  Future<ProjectTemplate?> importTemplateFromJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final template = ProjectTemplate.fromJson(decoded);

      ProjectTemplate.addCustomTemplate(template);
      await StorageService.saveCustomTemplates(ProjectTemplate.customTemplates);
      openEditorWithTemplate(template);
      return template;
    } catch (e) {
      debugPrint('EditorViewModel.importTemplateFromJson error: $e');
      return null;
    }
  }

  Future<void> exportTemplateFile({
    required String title,
    required String category,
    required String description,
  }) async {
    final template = _buildTemplate(title: title, category: category, description: description);
    final jsonStr = jsonEncode(template.toJson());
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final filename = '${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}.mokuply';

    await ExportService.downloadFileWeb(
      bytes: bytes,
      filename: filename,
      mimeType: 'application/json',
    );
  }

  // --- Multi-screen actions ---

  void selectScreenshot(int index) {
    if (index < 0 || index >= _screenshots.length) return;
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    _clearSelection();
    notifyListeners();
  }

  /// Appends a screen that inherits the look of the active one (same layout,
  /// background and typography) with placeholder words and no screenshots.
  void addScreenshot() {
    final src = data;
    _screenshots.add(src.copyWith(
      name: '',
      titleText: 'New headline',
      subtitleText: 'Describe this feature',
      customBackgroundImageBytes: () => src.customBackgroundImageBytes,
      devices: src.effectiveDevices
          .map((d) => d.copyWith(
                id: 'dev_${DateTime.now().millisecondsSinceEpoch}_${d.id.hashCode}',
                iosScreenshotBytes: () => null,
                androidScreenshotBytes: () => null,
              ))
          .toList(),
      customImageItems: const [],
      customTextItems: const [],
    ));
    _selectedIndex = _screenshots.length - 1;
    _clearSelection();
    _scheduleAutoSave();
    notifyListeners();
  }

  void removeScreenshot(int index) {
    if (_screenshots.length <= 1) return;
    _screenshots.removeAt(index);
    if (_selectedIndex >= _screenshots.length) {
      _selectedIndex = _screenshots.length - 1;
    }
    _clearSelection();
    _scheduleAutoSave();
    notifyListeners();
  }

  void duplicateScreenshot(int index) {
    if (index >= 0 && index < _screenshots.length) {
      final source = _screenshots[index];
      final copy = source.copyWith(name: source.name.isEmpty ? '' : '${source.name} copy');
      _screenshots.insert(index + 1, copy);
      _selectedIndex = index + 1;
      _clearSelection();
      _scheduleAutoSave();
      notifyListeners();
    }
  }

  void setScreenName(int index, String name) {
    if (index < 0 || index >= _screenshots.length) return;
    _screenshots[index] = _screenshots[index].copyWith(name: name.trim());
    _scheduleAutoSave();
    notifyListeners();
  }

  /// Moves screen [from] to position [to], keeping it selected.
  void moveScreenshot(int from, int to) {
    if (from < 0 || from >= _screenshots.length) return;
    if (to < 0 || to >= _screenshots.length || from == to) return;
    final item = _screenshots.removeAt(from);
    _screenshots.insert(to, item);
    _selectedIndex = to;
    _scheduleAutoSave();
    notifyListeners();
  }

  /// Copies the look of screen [sourceIndex] (layout, background, typography,
  /// frame style, positions, sizes and tilts) onto every other screen. Each
  /// screen keeps its own words, screenshots, images and extra text.
  void applyStyleToAllScreens(int sourceIndex) {
    if (sourceIndex < 0 || sourceIndex >= _screenshots.length) return;
    final src = _screenshots[sourceIndex];
    final srcDevices = src.effectiveDevices;

    for (int i = 0; i < _screenshots.length; i++) {
      if (i == sourceIndex) continue;
      final target = _screenshots[i];
      final targetDevices = target.effectiveDevices;

      // Frames pair up by position; extra source frames are not created, so
      // no screen gains a frame without a screenshot.
      final styledDevices = <CanvasDeviceItem>[];
      for (int d = 0; d < targetDevices.length; d++) {
        final ref = srcDevices[d < srcDevices.length ? d : srcDevices.length - 1];
        styledDevices.add(targetDevices[d].copyWith(
          frameStyle: ref.frameStyle,
          scale: ref.scale,
          offsetX: ref.offsetX,
          offsetY: ref.offsetY,
          rotation: ref.rotation,
          hasShadow: ref.hasShadow,
        ));
      }

      _screenshots[i] = target.copyWith(
        layoutMode: src.layoutMode,
        frameStyle: src.frameStyle,
        titleFont: src.titleFont,
        subtitleFont: src.subtitleFont,
        titleSize: src.titleSize,
        subtitleSize: src.subtitleSize,
        titleWeight: src.titleWeight,
        subtitleWeight: src.subtitleWeight,
        textColor: src.textColor,
        subtitleColor: src.subtitleColor,
        titleAlignment: src.titleAlignment,
        subtitleAlignment: src.subtitleAlignment,
        selectedGradientIndex: src.selectedGradientIndex,
        customBackgroundColor: () => src.customBackgroundColor,
        customGradientColors: () => src.customGradientColors,
        customBackgroundImageBytes: () => src.customBackgroundImageBytes,
        deviceScale: src.deviceScale,
        deviceOffsetX: src.deviceOffsetX,
        deviceOffsetY: src.deviceOffsetY,
        deviceRotation: src.deviceRotation,
        hasShadow: src.hasShadow,
        textOffsetX: src.textOffsetX,
        textOffsetY: src.textOffsetY,
        subtitleOffsetX: src.subtitleOffsetX,
        subtitleOffsetY: src.subtitleOffsetY,
        devices: styledDevices,
      );
    }
    _scheduleAutoSave();
    notifyListeners();
  }

  // --- Active screen mutators ---

  void _updateCurrentScreenshot(TemplateData updated) {
    _screenshots[_selectedIndex] = updated;
    _scheduleAutoSave();
    notifyListeners();
  }

  /// Switches the active store for every screen. Nothing else changes: the
  /// design is shared and realistic frames resolve per store.
  void setPlatform(TargetPlatformType newPlatform) {
    if (_screenshots.every((s) => s.platform == newPlatform)) return;
    _screenshots = _screenshots.map((s) => s.copyWith(platform: newPlatform)).toList();
    notifyListeners();
  }

  void setLayoutMode(LayoutMode mode) {
    double targetRotation = 0.0;
    double targetScale = 0.92;
    double targetOffsetY = 0.0;

    switch (mode) {
      case LayoutMode.angledLeftHero:
        targetRotation = -15.0;
        targetScale = 0.94;
        targetOffsetY = 280.0;
        break;
      case LayoutMode.angledRightHero:
        targetRotation = 15.0;
        targetScale = 0.94;
        targetOffsetY = 260.0;
        break;
      case LayoutMode.fullBleedHero:
        targetScale = 1.0;
        break;
      case LayoutMode.titleTopDeviceBottom:
      case LayoutMode.titleBottomDeviceTop:
      case LayoutMode.deviceCentered:
        break;
    }

    final updatedDevices = data.effectiveDevices
        .map((d) => d.copyWith(rotation: targetRotation, scale: targetScale, offsetY: targetOffsetY))
        .toList();

    _updateCurrentScreenshot(data.copyWith(
      layoutMode: mode,
      deviceRotation: targetRotation,
      deviceScale: targetScale,
      deviceOffsetY: targetOffsetY,
      devices: updatedDevices,
    ));
  }

  void setFrameStyle(DeviceFrameStyle style) {
    final targetDev = selectedDevice;
    if (targetDev != null) {
      setDeviceFrameStyle(targetDev.id, style);
    } else {
      _updateCurrentScreenshot(data.copyWith(frameStyle: style));
    }
  }

  void resetToDefaults() {
    _screenshots = ProjectTemplate.saasModern().initialScreenshots;
    _selectedIndex = 0;
    _clearSelection();
    notifyListeners();
  }

  // --- Export ---

  Future<Map<String, Uint8List>> _renderStore(
    TargetPlatformType target, {
    required BuildContext context,
    required int progressOffset,
  }) async {
    final Map<String, Uint8List> files = {};
    final Size targetSize = target.targetSize;

    for (int i = 0; i < _screenshots.length; i++) {
      _exportingProgressIndex = progressOffset + i + 1;
      _exportingStatusText = 'Rendering ${target.shortName} screen #${i + 1} of ${_screenshots.length}...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 20));

      final widget = CanvasMockupWidget(
        data: _screenshots[i].copyWith(platform: target),
        canvasSize: targetSize,
        isExporting: true,
      );

      final pngBytes = await ExportService.captureHighResWidget(
        widget: widget,
        targetSize: targetSize,
        context: context, // ignore: use_build_context_synchronously
      );

      files['${target.exportFolderName}/Screen_${i + 1}.png'] = pngBytes;
      await Future.delayed(const Duration(milliseconds: 16));
    }
    return files;
  }

  Future<void> _runExport(
    int totalSteps,
    String preparingText,
    Future<void> Function() body,
  ) async {
    _isExporting = true;
    _exportingProgressIndex = 0;
    _exportingTotalSteps = totalSteps;
    _exportingStatusText = preparingText;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 16));

    try {
      await body();
    } finally {
      _isExporting = false;
      _exportingProgressIndex = 0;
      _exportingStatusText = '';
      notifyListeners();
    }
  }

  /// Exports one store as a ZIP bundle (both stores share the 1320×2868 canvas).
  Future<void> exportPlatformPack(TargetPlatformType target, {required BuildContext context}) {
    return _runExport(_screenshots.length, 'Preparing screenshots...', () async {
      final files = await _renderStore(target, context: context, progressOffset: 0);

      _exportingStatusText = 'Packaging 100% lossless ZIP archive...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 32));

      await ExportService.downloadFileWeb(
        bytes: ExportService.createZipArchive(files),
        filename: 'Mockuply_${target.exportFolderName}.zip',
        mimeType: 'application/zip',
      );
    });
  }

  /// Exports both stores in one master ZIP bundle.
  Future<void> exportBothPlatformsPack({required BuildContext context}) {
    return _runExport(_screenshots.length * 2, 'Preparing store bundles...', () async {
      final files = <String, Uint8List>{};
      // The export overlay keeps the editor mounted for the whole run, so the
      // context stays valid between the two store renders.
      files.addAll(await _renderStore(TargetPlatformType.appStore, context: context, progressOffset: 0));
      // ignore: use_build_context_synchronously
      files.addAll(await _renderStore(TargetPlatformType.googlePlay, context: context, progressOffset: _screenshots.length));

      _exportingStatusText = 'Packaging complete dual-store ZIP bundle...';
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 32));

      await ExportService.downloadFileWeb(
        bytes: ExportService.createZipArchive(files),
        filename: 'Mockuply_StoreScreenshots_AllPlatforms.zip',
        mimeType: 'application/zip',
      );
    });
  }

  /// Sequential PNG downloads for the store currently previewed.
  Future<void> exportAllScreenshots({required BuildContext context}) {
    final target = platform;
    return _runExport(_screenshots.length, 'Preparing screenshots...', () async {
      final files = await _renderStore(target, context: context, progressOffset: 0);
      final platformTag = target.platformName.toLowerCase().replaceAll(' ', '_');
      int i = 0;
      for (final entry in files.entries) {
        i++;
        ExportService.downloadPngWeb(
          pngBytes: entry.value,
          filename: '${platformTag}_mockup_screen_${i}_of_${files.length}.png',
        );
        // Small pause between browser download triggers
        await Future.delayed(const Duration(milliseconds: 300));
      }
    });
  }
}
