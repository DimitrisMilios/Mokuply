import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/editor/editor_viewmodel.dart';
import '../../viewmodels/export_viewmodel.dart';
import 'editor_view.dart';

/// Entry point of the deferred editor bundle (see `EditorLoader`): the
/// editor screen with its export view model, which lives as long as the
/// editor is open.
Widget buildEditor() {
  return ChangeNotifierProvider(
    create: (ctx) => ExportViewModel(editor: ctx.read<EditorViewModel>()),
    child: const EditorView(),
  );
}
