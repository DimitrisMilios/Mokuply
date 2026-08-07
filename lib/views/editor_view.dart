import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../constants/store_specs.dart';
import '../models/template_model.dart';
import '../services/export_service.dart';
import '../widgets/canvas_mockup_widget.dart';

class EditorView extends StatefulWidget {
  const EditorView({super.key});

  @override
  State<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<EditorView> {
  bool _isExporting = false;

  Future<void> _pickImage(TemplateModel model) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          model.setScreenshotBytes(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }

  Future<void> _exportPng(TemplateModel model) async {
    setState(() => _isExporting = true);

    try {
      final Size targetSize = Size(
        model.platform.targetWidth,
        model.platform.targetHeight,
      );

      final pngBytes = await ExportService.captureHighResWidget(
        widget: CanvasMockupWidget(
          model: model,
          canvasSize: targetSize,
          isExporting: true,
        ),
        targetSize: targetSize,
        pixelRatio: 1.0,
      );

      final filename =
          '${model.platform.name.toLowerCase().replaceAll(' ', '_')}_mockup_${DateTime.now().millisecondsSinceEpoch}.png';

      ExportService.downloadPngWeb(
        pngBytes: pngBytes,
        filename: filename,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Successfully exported ${targetSize.width.toInt()}x${targetSize.height.toInt()} PNG!'),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Export failed: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _openColorPicker(BuildContext context, Color currentColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Pick Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: currentColor,
            onColorChanged: onColorChanged,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false, // Ensure solid colors (no alpha)
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<TemplateModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark studio theme
      body: Column(
        children: [
          // Top Navigation & Action Bar
          _buildNavbar(context, model),

          // Main Editor Split Screen
          Expanded(
            child: Row(
              children: [
                // Sidebar controls
                SizedBox(
                  width: 380,
                  child: _buildControlSidebar(context, model),
                ),

                // Vertical Divider
                Container(width: 1, color: const Color(0xFF1E293B)),

                // Preview Canvas Workspace
                Expanded(
                  child: _buildCanvasWorkspace(context, model),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavbar(BuildContext context, TemplateModel model) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(bottom: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          // Logo & Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.art_track_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'StoreCraft Studio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF312E81),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6366F1)),
                ),
                child: const Text(
                  '100% Free & Client-Side',
                  style: TextStyle(color: Color(0xFFA5B4FC), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Target Platform Selector
          SegmentedButton<TargetPlatformType>(
            segments: const [
              ButtonSegment(
                value: TargetPlatformType.appStore,
                label: Text('iPhone 16 Pro Max'),
                icon: Icon(Icons.apple, size: 18),
              ),
              ButtonSegment(
                value: TargetPlatformType.googlePlay,
                label: Text('Samsung S26 Ultra'),
                icon: Icon(Icons.android, size: 18),
              ),
            ],
            selected: {model.platform},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) {
                model.setPlatform(selected.first);
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF4F46E5);
                }
                return const Color(0xFF0F172A);
              }),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
          ),

          const SizedBox(width: 16),

          // Dimensions badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Text(
              '${model.platform.targetWidth.toInt()} x ${model.platform.targetHeight.toInt()} px',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),

          const SizedBox(width: 16),

          // Reset button
          TextButton.icon(
            onPressed: () => model.resetToDefaults(),
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
            label: const Text('Reset', style: TextStyle(color: Colors.white70)),
          ),

          const SizedBox(width: 16),

          // High-Res Export PNG Button
          ElevatedButton.icon(
            onPressed: _isExporting ? null : () => _exportPng(model),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 20),
            label: Text(
              _isExporting ? 'Exporting...' : 'Export High-Res PNG',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSidebar(BuildContext context, TemplateModel model) {
    return Container(
      color: const Color(0xFF0F172A),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Upload Screenshot
          _buildSidebarCard(
            title: '1. App Screenshot',
            icon: Icons.upload_file_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(model),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(model.screenshotBytes == null ? 'Upload Screenshot' : 'Change Screenshot'),
                ),
                if (model.screenshotBytes != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 6),
                      const Text('Image loaded in memory', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => model.setScreenshotBytes(null),
                        child: const Text('Remove', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 2: Preset Layout Mode
          _buildSidebarCard(
            title: '2. Preset Store Layout',
            icon: Icons.dashboard_customize_rounded,
            child: Column(
              children: LayoutMode.values.map((mode) {
                final isSelected = model.layoutMode == mode;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF334155),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    tileColor: isSelected ? const Color(0xFF1E1B4B) : const Color(0xFF1E293B),
                    title: Text(
                      mode.title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      mode.description,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    onTap: () => model.setLayoutMode(mode),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Section 3: Background & Gradients
          _buildSidebarCard(
            title: '3. Canvas Background',
            icon: Icons.palette_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Preset Gradients', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: StoreSpecs.gradientPresets.length,
                  itemBuilder: (ctx, index) {
                    final preset = StoreSpecs.gradientPresets[index];
                    final isSelected = model.selectedGradientIndex == index && model.customBackgroundColor == null;
                    return InkWell(
                      onTap: () => model.setGradientIndex(index),
                      child: Container(
                        decoration: preset.toDecoration().copyWith(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            preset.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Custom Solid Color:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    InkWell(
                      onTap: () => _openColorPicker(
                        context,
                        model.customBackgroundColor ?? Colors.indigo,
                        (c) => model.setCustomBackgroundColor(c),
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: model.customBackgroundColor ?? Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: model.customBackgroundColor == null
                            ? const Icon(Icons.colorize, size: 16, color: Colors.white54)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 4: Typography & Headers
          _buildSidebarCard(
            title: '4. Headlines & Text',
            icon: Icons.title_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                TextField(
                  controller: TextEditingController(text: model.titleText)..selection = TextSelection.collapsed(offset: model.titleText.length),
                  onChanged: (val) => model.setTitleText(val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Main Headline',
                    labelStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle Field
                TextField(
                  controller: TextEditingController(text: model.subtitleText)..selection = TextSelection.collapsed(offset: model.subtitleText.length),
                  onChanged: (val) => model.setSubtitleText(val),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Subtitle',
                    labelStyle: TextStyle(color: Colors.white60),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Font Family Dropdown
                Row(
                  children: [
                    const Text('Headline Font:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    DropdownButton<String>(
                      value: StoreSpecs.fontFamilies.contains(model.titleFont) ? model.titleFont : StoreSpecs.fontFamilies.first,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      items: StoreSpecs.fontFamilies
                          .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                          .toList(),
                      onChanged: (f) {
                        if (f != null) model.setTitleFont(f);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title Color Picker
                Row(
                  children: [
                    const Text('Title Color:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const Spacer(),
                    InkWell(
                      onTap: () => _openColorPicker(context, model.textColor, (c) => model.setTextColor(c)),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: model.textColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white54),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 5: Device Frame & Transform
          _buildSidebarCard(
            title: '5. Frame & Transform',
            icon: Icons.phone_iphone_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Frame Model
                const Text('Device Model:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                DropdownButtonFormField<DeviceFrameStyle>(
                  initialValue: model.frameStyle,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: DeviceFrameStyle.values
                      .map((style) => DropdownMenuItem(
                            value: style,
                            child: Text(style.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) model.setFrameStyle(val);
                  },
                ),
                const SizedBox(height: 12),

                // Device Scale Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Device Scale:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${(model.deviceScale * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: model.deviceScale,
                  min: 0.5,
                  max: 1.2,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) => model.setDeviceScale(val),
                ),

                // Rotation Tilt Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rotation Tilt:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('${model.deviceRotation.toInt()}°', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
                Slider(
                  value: model.deviceRotation,
                  min: -30.0,
                  max: 30.0,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (val) => model.setDeviceRotation(val),
                ),

                // Drop Shadow Switch
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Drop Shadow', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  value: model.hasShadow,
                  activeTrackColor: const Color(0xFF6366F1),
                  onChanged: (val) => model.setHasShadow(val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFA5B4FC)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCanvasWorkspace(BuildContext context, TemplateModel model) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Calculate preview bounds keeping target platform aspect ratio
        final double maxAvailableWidth = constraints.maxWidth - 80;
        final double maxAvailableHeight = constraints.maxHeight - 80;

        final double targetRatio = model.platform.aspectRatio;

        double previewWidth = maxAvailableWidth;
        double previewHeight = previewWidth / targetRatio;

        if (previewHeight > maxAvailableHeight) {
          previewHeight = maxAvailableHeight;
          previewWidth = previewHeight * targetRatio;
        }

        return Container(
          color: const Color(0xFF0B0F19), // Dark preview viewport background
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle background grid pattern line visual
              Positioned.fill(
                child: CustomPaint(
                  painter: CanvasGridPainter(),
                ),
              ),

              // Mockup Canvas Frame
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: CanvasMockupWidget(
                  model: model,
                  canvasSize: Size(previewWidth, previewHeight),
                ),
              ),

              // Bottom status bar info overlay
              Positioned(
                bottom: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.aspect_ratio_rounded, color: Color(0xFFA5B4FC), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Live View (${previewWidth.toInt()}x${previewHeight.toInt()} px)  •  Export Native Target: ${model.platform.targetWidth.toInt()}x${model.platform.targetHeight.toInt()} px',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class CanvasGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    const double step = 32.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
