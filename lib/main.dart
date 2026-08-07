import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/template_model.dart';
import 'views/editor_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StoreCraftStudioApp());
}

class StoreCraftStudioApp extends StatelessWidget {
  const StoreCraftStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TemplateModel(),
      child: MaterialApp(
        title: 'StoreCraft Studio - Free Client-Side App Mockup Generator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            secondary: Color(0xFFA855F7),
            surface: Color(0xFF1E293B),
          ),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        ),
        home: const EditorView(),
      ),
    );
  }
}
