import 'package:flutter/material.dart';
import '../core/constants/store_specs.dart';
import 'template_assets.dart';
import 'template_data.dart';

/// A named set of screens shown in the template gallery: a built-in starter
/// (see `BuiltInTemplates`) or one the user saved or imported.
class ProjectTemplate {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<Color> previewGradient;
  final TargetPlatformType platform;
  final List<TemplateData> initialScreenshots;

  const ProjectTemplate({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.previewGradient,
    required this.platform,
    required this.initialScreenshots,
  });

  Map<String, dynamic> toJson({AssetWriter? assets}) {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'previewGradient': previewGradient.map((c) => c.toARGB32()).toList(),
      'platform': platform.name,
      'initialScreenshots': initialScreenshots.map((s) => s.toJson(assets: assets)).toList(),
    };
  }

  factory ProjectTemplate.fromJson(Map<String, dynamic> json, {AssetReader? assets}) {
    return ProjectTemplate(
      id: json['id'] as String? ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title'] as String? ?? 'Custom Template',
      category: json['category'] as String? ?? 'Custom',
      description: json['description'] as String? ?? '',
      previewGradient: (json['previewGradient'] as List?)
              ?.map((c) => Color(c as int))
              .toList() ??
          const [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFF3B82F6)],
      platform: TargetPlatformType.values.firstWhere(
        (e) => e.name == json['platform'],
        orElse: () => TargetPlatformType.appStore,
      ),
      initialScreenshots: (json['initialScreenshots'] as List?)
              ?.map((s) => TemplateData.fromJson(s as Map<String, dynamic>, assets: assets))
              .toList() ??
          const [],
    );
  }

}
