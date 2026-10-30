import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_links.dart';
import 'core/motion/clay_motion.dart';
import 'core/theme/app_theme.dart';
import 'viewmodels/editor/editor_viewmodel.dart';
import 'viewmodels/library_viewmodel.dart';
import 'views/editor_loader.dart';
import 'views/home/home_view.dart';
import 'views/info/connect_ai_view.dart';
import 'views/info/privacy_view.dart';
import 'views/info/terms_view.dart';

/// Root application widget: provides the view models and switches between
/// the template gallery and the editor.
class MockuplyApp extends StatelessWidget {
  const MockuplyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EditorViewModel()),
        ChangeNotifierProvider(create: (ctx) => LibraryViewModel(editor: ctx.read<EditorViewModel>())..load()),
      ],
      child: MaterialApp(
        title: 'Mockuply — Free App Mockup Generator',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) => ClayMotionScope.fromMediaQuery(child: child ?? const SizedBox.shrink()),
        home: const _AppRoot(),
        // Text pages over the gallery or editor; on the web they deep-link
        // as /#/privacy, /#/terms and /#/connect-ai.
        routes: {
          AppLinks.privacyRoute: (_) => const PrivacyView(),
          AppLinks.termsRoute: (_) => const TermsView(),
          AppLinks.connectAiRoute: (_) => const ConnectAiView(),
        },
      ),
    );
  }
}

/// Rebuilds only when the app moves between the gallery and the editor.
class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    final isHome = context.select<EditorViewModel, bool>((vm) => vm.isHomeScreen);
    return isHome ? const HomeView() : const EditorLoader();
  }
}
