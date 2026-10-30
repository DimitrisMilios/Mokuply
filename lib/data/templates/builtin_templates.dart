import '../../models/project_template.dart';
import 'messenger_dark.dart';
import 'pastel_marketplace.dart';
import 'pink_getaway.dart';
import 'simple_starters.dart';
import 'team_organize.dart';

/// The starter sets shipped with the app, in gallery order.
class BuiltInTemplates {
  BuiltInTemplates._();

  /// Built once: templates are immutable.
  static final List<ProjectTemplate> all = List.unmodifiable([
    pastelMarketplaceTemplate(),
    pinkGetawayTemplate(),
    teamOrganizeTemplate(),
    messengerDarkTemplate(),
    minimalistCleanTemplate(),
    sunsetGlowTemplate(),
  ]);

  static ProjectTemplate _byId(String id) => all.firstWhere((t) => t.id == id);

  /// The set a new project starts from.
  static final ProjectTemplate starter = _byId('team_organize');

  /// The set "Reset set" restores: the same one new projects start from.
  static ProjectTemplate get resetSet => starter;
}
