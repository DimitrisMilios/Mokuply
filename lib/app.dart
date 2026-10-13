import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/motion/clay_motion.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/editor_viewmodel.dart';
import 'views/home/home_view.dart';
import 'views/editor/editor_view.dart';

/// Root application widget.
class MockuplyApp extends StatelessWidget {
  const MockuplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditorViewModel()..initStorage(),
      child: MaterialApp(
        title: 'Mockuply — Free App Mockup Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) => ClayMotionScope.fromMediaQuery(child: child ?? const SizedBox.shrink()),
        home: Consumer<EditorViewModel>(
          builder: (context, vm, _) {
            return vm.isHomeScreen ? const HomeView() : const EditorView();
          },
        ),
      ),
    );
  }
}
