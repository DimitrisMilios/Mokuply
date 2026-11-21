import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocuply/data/templates/builtin_templates.dart';
import 'package:mocuply/core/theme/app_theme.dart';
import 'package:mocuply/viewmodels/editor/editor_viewmodel.dart';
import 'package:mocuply/views/editor/editor_entry.dart';
import 'package:mocuply/views/editor/workspace/multi_canvas_workspace.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('MultiCanvasWorkspace lays out without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final vm = EditorViewModel();
    vm.openEditorWithTemplate(BuiltInTemplates.all.first);
    final controller = TransformationController();

    await tester.pumpWidget(
      ChangeNotifierProvider<EditorViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: MultiCanvasWorkspace(transformationController: controller, previewing: false),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Download button opens ExportModalDialog without ProviderNotFoundException', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final vm = EditorViewModel();
    vm.openEditorWithTemplate(BuiltInTemplates.all.first);

    await tester.pumpWidget(
      ChangeNotifierProvider<EditorViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: buildEditor(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.textContaining('Download ('));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Both stores'), findsOneWidget);
  });
}
