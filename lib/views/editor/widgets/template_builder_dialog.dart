import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/template_data.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/clay/clay.dart';

/// Modal dialog that allows designing, saving, and exporting the current canvas setup as a reusable ProjectTemplate.
class TemplateBuilderDialog extends StatefulWidget {
  const TemplateBuilderDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showClayDialog<void>(
      context: context,
      builder: (_) => const TemplateBuilderDialog(),
    );
  }

  @override
  State<TemplateBuilderDialog> createState() => _TemplateBuilderDialogState();
}

class _TemplateBuilderDialogState extends State<TemplateBuilderDialog> {
  final TextEditingController _titleController = TextEditingController(text: 'My Custom Template');
  final TextEditingController _categoryController = TextEditingController(text: 'Productivity');
  final TextEditingController _descController = TextEditingController(text: 'Custom crafted mockup showcase template.');
  bool _copied = false;
  bool _savedToGallery = false;
  late String _generatedCode;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateGeneratedCode);
    _categoryController.addListener(_updateGeneratedCode);
    _descController.addListener(_updateGeneratedCode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateGeneratedCode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _updateGeneratedCode() {
    final vm = Provider.of<EditorViewModel>(context, listen: false);
    final code = _generateDartCode(
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      description: _descController.text.trim(),
      platform: vm.platform,
      screenshots: vm.screenshots,
    );
    setState(() {
      _generatedCode = code;
    });
  }

  String _formatColor(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
    return 'Color(0x$hex)';
  }

  String _generateDartCode({
    required String title,
    required String category,
    required String description,
    required TargetPlatformType platform,
    required List<TemplateData> screenshots,
  }) {
    final methodName = title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final safeMethodName = methodName.isEmpty ? 'customTemplate' : '${methodName[0].toLowerCase()}${methodName.substring(1)}';
    final templateId = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

    final buffer = StringBuffer();
    buffer.writeln('  /// $title ($category)');
    buffer.writeln('  static ProjectTemplate $safeMethodName() {');
    buffer.writeln('    return ProjectTemplate(');
    buffer.writeln("      id: '$templateId',");
    buffer.writeln("      title: '$title',");
    buffer.writeln("      category: '$category',");
    buffer.writeln("      description: '$description',");
    buffer.writeln('      previewGradient: const [Color(0xFFEFF6FF), Color(0xFFDBEAFE), Color(0xFF3B82F6)],');
    buffer.writeln('      platform: TargetPlatformType.${platform.name},');
    buffer.writeln('      initialScreenshots: [');

    for (int i = 0; i < screenshots.length; i++) {
      final s = screenshots[i];
      buffer.writeln('        // Screenshot ${i + 1}');
      buffer.writeln('        const TemplateData(');
      buffer.writeln("          titleText: '${s.titleText.replaceAll("'", r"\'")}',");
      buffer.writeln("          subtitleText: '${s.subtitleText.replaceAll("'", r"\'")}',");
      buffer.writeln("          titleFont: '${s.titleFont}',");
      buffer.writeln("          subtitleFont: '${s.subtitleFont}',");
      buffer.writeln('          titleSize: ${s.titleSize},');
      buffer.writeln('          subtitleSize: ${s.subtitleSize},');
      buffer.writeln('          titleWeight: FontWeight.${s.titleWeight.toString().split('.').last},');
      buffer.writeln('          subtitleWeight: FontWeight.${s.subtitleWeight.toString().split('.').last},');
      buffer.writeln('          textColor: ${_formatColor(s.textColor)},');
      buffer.writeln('          subtitleColor: ${_formatColor(s.subtitleColor)},');
      buffer.writeln('          titleAlignment: TextAlign.${s.titleAlignment.name},');
      buffer.writeln('          subtitleAlignment: TextAlign.${s.subtitleAlignment.name},');
      buffer.writeln('          textOffsetX: ${s.textOffsetX},');
      buffer.writeln('          textOffsetY: ${s.textOffsetY},');
      buffer.writeln('          subtitleOffsetX: ${s.subtitleOffsetX},');
      buffer.writeln('          subtitleOffsetY: ${s.subtitleOffsetY},');
      buffer.writeln('          selectedGradientIndex: ${s.selectedGradientIndex},');

      if (s.customGradientColors != null && s.customGradientColors!.isNotEmpty) {
        final colorsList = s.customGradientColors!.map((c) => _formatColor(c)).join(', ');
        buffer.writeln('          customGradientColors: [$colorsList],');
      }
      buffer.writeln('          layoutMode: LayoutMode.${s.layoutMode.name},');

      if (s.devices.isNotEmpty) {
        buffer.writeln('          devices: [');
        for (final d in s.devices) {
          buffer.writeln('            CanvasDeviceItem(');
          buffer.writeln("              id: '${d.id}',");
          buffer.writeln('              frameStyle: DeviceFrameStyle.${d.frameStyle.name},');
          buffer.writeln('              scale: ${d.scale},');
          buffer.writeln('              offsetX: ${d.offsetX},');
          buffer.writeln('              offsetY: ${d.offsetY},');
          buffer.writeln('              rotation: ${d.rotation},');
          buffer.writeln('              hasShadow: ${d.hasShadow},');
          buffer.writeln('            ),');
        }
        buffer.writeln('          ],');
      } else {
        buffer.writeln('          deviceRotation: ${s.deviceRotation},');
        buffer.writeln('          deviceScale: ${s.deviceScale},');
        buffer.writeln('          deviceOffsetX: ${s.deviceOffsetX},');
        buffer.writeln('          deviceOffsetY: ${s.deviceOffsetY},');
      }

      if (s.customTextItems.isNotEmpty) {
        buffer.writeln('          customTextItems: [');
        for (final t in s.customTextItems) {
          buffer.writeln('            CanvasTextItem(');
          buffer.writeln("              id: '${t.id}',");
          buffer.writeln("              text: '${t.text.replaceAll("'", r"\'")}',");
          buffer.writeln("              font: '${t.font}',");
          buffer.writeln('              fontSize: ${t.fontSize},');
          buffer.writeln('              color: ${_formatColor(t.color)},');
          buffer.writeln('              weight: FontWeight.${t.weight.toString().split('.').last},');
          buffer.writeln('              alignment: TextAlign.${t.alignment.name},');
          buffer.writeln('              offsetX: ${t.offsetX},');
          buffer.writeln('              offsetY: ${t.offsetY},');
          buffer.writeln('              rotation: ${t.rotation},');
          buffer.writeln('            ),');
        }
        buffer.writeln('          ],');
      }

      buffer.writeln('        ),');
    }

    buffer.writeln('      ],');
    buffer.writeln('    );');
    buffer.writeln('  }');
    return buffer.toString();
  }

  Future<void> _saveToGallery() async {
    final vm = Provider.of<EditorViewModel>(context, listen: false);
    final title = _titleController.text.trim().isEmpty ? 'Custom Template' : _titleController.text.trim();
    final category = _categoryController.text.trim().isEmpty ? 'Custom' : _categoryController.text.trim();
    final description = _descController.text.trim().isEmpty ? 'User-created template' : _descController.text.trim();

    try {
      await vm.saveCurrentAsTemplate(
        title: title,
        category: category,
        description: description,
      );
    } catch (e) {
      debugPrint('TemplateBuilderDialog save error: $e');
      if (mounted) ClayToast.show(context, 'Could not save "$title".', error: true);
      return;
    }

    if (mounted) {
      setState(() {
        _savedToGallery = true;
      });
      ClayToast.show(context, 'Saved "$title".');
    }
  }

  Future<void> _exportTemplateFile() async {
    final vm = Provider.of<EditorViewModel>(context, listen: false);
    final title = _titleController.text.trim().isEmpty ? 'Custom Template' : _titleController.text.trim();
    final category = _categoryController.text.trim().isEmpty ? 'Custom' : _categoryController.text.trim();
    final description = _descController.text.trim().isEmpty ? 'User-created template' : _descController.text.trim();

    try {
      await vm.exportTemplateFile(
        title: title,
        category: category,
        description: description,
      );
    } catch (e) {
      debugPrint('TemplateBuilderDialog export error: $e');
      if (mounted) ClayToast.show(context, 'Could not download "$title".', error: true);
      return;
    }

    if (mounted) {
      ClayToast.show(context, 'Your template file is downloading.');
    }
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: _generatedCode));
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
          // Name + category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: ClayField(
                  controller: _titleController,
                  label: 'Name',
                  hint: 'My template',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ClayField(
                  controller: _categoryController,
                  label: 'Category',
                  hint: 'Productivity',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClayField(
            controller: _descController,
            label: 'Description',
            hint: 'One line about this layout',
          ),

          const SizedBox(height: 20),

          // Dart snippet
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              ClayLabel('Dart snippet', padding: EdgeInsets.only(left: 4)),
              Spacer(),
              Text(
                'For contributors adding a built-in template',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: AppDimensions.fontSm,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClayWell.dark(
            height: 180,
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              child: SelectableText(
                _generatedCode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: AppColors.goldLight,
                  height: 1.4,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ClayButton.text(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              ClayButton.neutral(
                label: _copied ? 'Copied' : 'Copy',
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                onPressed: _copyCode,
              ),
              ClayButton.neutral(
                label: 'Download .mokuply',
                icon: Icons.download_rounded,
                onPressed: _exportTemplateFile,
              ),
              ClayButton.primary(
                label: _savedToGallery ? 'Saved' : 'Save',
                icon: _savedToGallery ? Icons.check_rounded : Icons.save_rounded,
                onPressed: _saveToGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
