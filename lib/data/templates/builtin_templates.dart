import '../../models/project_template.dart';
import 'pastel_marketplace.dart';
import 'simple_starters.dart';
import 'team_organize.dart';

/// The starter sets shipped with the app, in gallery order.
class BuiltInTemplates {
  BuiltInTemplates._();

  /// Built once: templates are immutable.
  static final List<ProjectTemplate> all = List.unmodifiable([
    pastelMarketplaceTemplate(),
    teamOrganizeTemplate(),
    saasModernTemplate(),
    minimalistCleanTemplate(),
    sunsetGlowTemplate(),
    fitnessPulseTemplate(),
  ]);

  static ProjectTemplate _byId(String id) => all.firstWhere((t) => t.id == id);

  /// The set a new project starts from.
  static final ProjectTemplate starter = _byId('team_organize');

  /// The set "Reset set" restores.
  static final ProjectTemplate resetSet = _byId('saas_modern');
}
