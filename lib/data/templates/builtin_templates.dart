import '../../models/project_template.dart';
import 'simple_starters.dart';
import 'team_organize.dart';

/// The starter sets shipped with the app, in gallery order.
class BuiltInTemplates {
  BuiltInTemplates._();

  /// Built once: templates are immutable.
  static final List<ProjectTemplate> all = List.unmodifiable([
    teamOrganizeTemplate(),
    saasModernTemplate(),
    minimalistCleanTemplate(),
    sunsetGlowTemplate(),
  ]);

  /// The set a new project starts from.
  static ProjectTemplate get starter => all.first;

  /// The set "Reset set" restores.
  static ProjectTemplate get resetSet => all[1];
}
