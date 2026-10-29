import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/project_template.dart';
import '../models/template_data.dart';
import 'template_package.dart';
import 'storage_service_stub.dart'
    if (dart.library.html) 'storage_service_web.dart';

/// Service providing client-side persistence (Web localStorage / memory).
class StorageService {
  static const String _keyActiveDraft = 'mokuply_active_draft_v1';
  static const String _keyCustomTemplates = 'mokuply_custom_templates_v1';

  /// Save current active project screenshots to local storage
  static Future<void> saveActiveDraft(List<TemplateData> screenshots) async {
    try {
      final jsonList = screenshots.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await PlatformStorage.setString(_keyActiveDraft, jsonString);
    } catch (e) {
      debugPrint('StorageService.saveActiveDraft error: $e');
    }
  }

  /// Load current active project screenshots from local storage
  static Future<List<TemplateData>?> loadActiveDraft() async {
    try {
      final jsonString = await PlatformStorage.getString(_keyActiveDraft);
      if (jsonString == null || jsonString.isEmpty) return null;

      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((item) => TemplateData.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('StorageService.loadActiveDraft error: $e');
      return null;
    }
  }

  /// Clear active draft
  static Future<void> clearActiveDraft() async {
    await PlatformStorage.remove(_keyActiveDraft);
  }

  /// Save user custom templates to local storage
  static Future<void> saveCustomTemplates(List<ProjectTemplate> templates) async {
    try {
      final jsonList = templates.map((t) => t.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await PlatformStorage.setString(_keyCustomTemplates, jsonString);
    } catch (e) {
      debugPrint('StorageService.saveCustomTemplates error: $e');
    }
  }

  /// Keeps [template] with its images (screenshots, backgrounds, image
  /// layers) in the browser's binary storage, as a template zip.
  /// [saveCustomTemplates] keeps only the text, which fits in localStorage.
  static Future<void> saveTemplateImages(ProjectTemplate template) async {
    try {
      await PlatformStorage.setBytes(_templateFileKey(template.id), TemplatePackage.encode(template));
    } catch (e) {
      debugPrint('StorageService.saveTemplateImages error: $e');
    }
  }

  /// The template saved by [saveTemplateImages], or null when there is none
  /// (templates saved before images were kept).
  static Future<ProjectTemplate?> loadTemplateImages(String templateId) async {
    try {
      final bytes = await PlatformStorage.getBytes(_templateFileKey(templateId));
      return bytes == null ? null : TemplatePackage.decode(bytes);
    } catch (e) {
      debugPrint('StorageService.loadTemplateImages error: $e');
      return null;
    }
  }

  static Future<void> deleteTemplateImages(String templateId) =>
      PlatformStorage.removeBytes(_templateFileKey(templateId));

  static String _templateFileKey(String templateId) => 'template_$templateId';

  /// Load user custom templates from local storage
  static Future<List<ProjectTemplate>> loadCustomTemplates() async {
    try {
      final jsonString = await PlatformStorage.getString(_keyCustomTemplates);
      if (jsonString == null || jsonString.isEmpty) return [];

      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((item) => ProjectTemplate.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('StorageService.loadCustomTemplates error: $e');
      return [];
    }
  }
}
