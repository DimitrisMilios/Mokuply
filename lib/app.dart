import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/editor_viewmodel.dart';
import 'views/editor/editor_view.dart';

/// Root application widget.
class MocuplyApp extends StatelessWidget {
  const MocuplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorViewModel(),
      child: MaterialApp(
        title: 'Mocuply — Free App Mockup Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const EditorView(),
      ),
    );
  }
}
