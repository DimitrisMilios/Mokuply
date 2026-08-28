import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/store_specs.dart';
import '../../../models/canvas_device_item.dart';
import '../../../models/canvas_text_item.dart';
import '../../../models/project_template.dart';
import '../../../models/template_data.dart';
import '../../../viewmodels/editor_viewmodel.dart';
import '../../../widgets/shared/glass_container.dart';

/// Modal dialog that allows designing, saving, and exporting the current canvas setup as a reusable ProjectTemplate.
class TemplateBuilderDialog extends StatefulWidget {
  const TemplateBuilderDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
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

    await vm.saveCurrentAsTemplate(
      title: title,
      category: category,
      description: description,
    );

    if (mounted) {
      setState(() {
        _savedToGallery = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Template "$title" saved & persisted to your browser storage!'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportTemplateFile() async {
    final vm = Provider.of<EditorViewModel>(context, listen: false);
    final title = _titleController.text.trim().isEmpty ? 'Custom Template' : _titleController.text.trim();
    final category = _categoryController.text.trim().isEmpty ? 'Custom' : _categoryController.text.trim();
    final description = _descController.text.trim().isEmpty ? 'User-created template' : _descController.text.trim();

    await vm.exportTemplateFile(
      title: title,
      category: category,
      description: description,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded template file for "$title"!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(28),
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.all(28),
        child: SizedBox(
          width: 760,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bookmark_add_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Save Current Design as Template',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Save to browser storage, export .mokuply file, or copy Dart code',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Inputs Row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Template Title',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _categoryController,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _descController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // Generated Dart Code Box
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Generated Template Dart Code',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Ready for project_template.dart',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                height: 180,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _generatedCode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF38BDF8),
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _generatedCode));
                      setState(() => _copied = true);
                      Future.delayed(const Duration(seconds: 2), () {
                        if (mounted) setState(() => _copied = false);
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
                    label: Text(_copied ? 'Copied Code!' : 'Copy Dart Code'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _exportTemplateFile,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_for_offline_rounded, size: 18),
                    label: const Text('Export .mokuply File'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _saveToGallery,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_savedToGallery ? Icons.check_circle_rounded : Icons.save_rounded, size: 18),
                    label: Text(_savedToGallery ? 'Saved to Browser Storage!' : 'Save & Persist to Gallery'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
