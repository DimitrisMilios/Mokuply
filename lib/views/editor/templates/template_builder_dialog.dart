import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/template_code_generator.dart';
import '../../../viewmodels/editor/editor_viewmodel.dart';
import '../../../viewmodels/library_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'template_dialog_parts.dart';

/// "Save as template": keep the open project in this browser's gallery,
/// download it as a `.mokuply` file, or copy a Dart snippet.
class TemplateBuilderDialog extends StatefulWidget {
  const TemplateBuilderDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showClayDialog<void>(context: context, builder: (_) => const TemplateBuilderDialog());
  }

  @override
  State<TemplateBuilderDialog> createState() => _TemplateBuilderDialogState();
}

class _TemplateBuilderDialogState extends State<TemplateBuilderDialog> {
  final TextEditingController _title = TextEditingController(text: 'My Custom Template');
  final TextEditingController _category = TextEditingController(text: 'Productivity');
  final TextEditingController _description = TextEditingController(text: 'Custom crafted mockup showcase template.');
  bool _copied = false;
  bool _savedToGallery = false;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _description.dispose();
    super.dispose();
  }

  String _or(TextEditingController c, String fallback) => c.text.trim().isEmpty ? fallback : c.text.trim();
  String get _titleText => _or(_title, 'Custom Template');
  String get _categoryText => _or(_category, 'Custom');
  String get _descriptionText => _or(_description, 'User-created template');

  String _snippet() {
    final vm = context.read<EditorViewModel>();
    return TemplateCodeGenerator.generate(
      title: _title.text.trim(),
      category: _category.text.trim(),
      description: _description.text.trim(),
      platform: vm.platform,
      screenshots: vm.screenshots,
    );
  }

  Future<void> _save() async {
    final title = _titleText;
    try {
      await context.read<LibraryViewModel>().saveCurrentAsTemplate(
        title: title,
        category: _categoryText,
        description: _descriptionText,
      );
    } catch (e) {
      debugPrint('TemplateBuilderDialog save error: $e');
      if (mounted) ClayToast.show(context, 'Could not save "$title".', error: true);
      return;
    }
    if (!mounted) return;
    setState(() => _savedToGallery = true);
    ClayToast.show(context, 'Saved "$title".');
  }

  Future<void> _download() async {
    final title = _titleText;
    try {
      await context.read<LibraryViewModel>().exportTemplateFile(
        title: title,
        category: _categoryText,
        description: _descriptionText,
      );
    } catch (e) {
      debugPrint('TemplateBuilderDialog export error: $e');
      if (mounted) ClayToast.show(context, 'Could not download "$title".', error: true);
      return;
    }
    if (mounted) ClayToast.show(context, 'Your template file is downloading.');
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _copied = true);
    ClayToast.show(context, 'Copied');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClayDialog(
      width: 760,
      title: 'Save as template',
      subtitle: 'Keep it in this browser, download a .mokuply file, or copy the Dart snippet.',
      headerIcon: Image.asset(
        'assets/clay/icon_bookmark.png',
        width: 40,
        height: 40,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const Icon(Icons.bookmark_rounded, color: AppColors.goldDeep, size: 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TemplateFields(title: _title, category: _category, description: _description),
          const SizedBox(height: 20),
          // The snippet follows the fields as they are typed.
          ListenableBuilder(
            listenable: Listenable.merge([_title, _category, _description]),
            builder: (context, _) => DartSnippetWell(code: _snippet()),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ClayButton.text(label: 'Cancel', onPressed: () => Navigator.of(context).maybePop()),
              ClayButton.neutral(
                label: _copied ? 'Copied' : 'Copy',
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                onPressed: () => _copy(_snippet()),
              ),
              ClayButton.neutral(label: 'Download .mokuply', icon: Icons.download_rounded, onPressed: _download),
              ClayButton.primary(
                label: _savedToGallery ? 'Saved' : 'Save',
                icon: _savedToGallery ? Icons.check_rounded : Icons.save_rounded,
                onPressed: _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
