import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../models/project_template.dart';
import '../../../viewmodels/library_viewmodel.dart';
import '../../../widgets/clay/clay.dart';
import 'empty_gallery.dart';
import 'template_card.dart';

/// The template gallery: header with the import button, then a responsive
/// grid of template cards.
class TemplateGallery extends StatelessWidget {
  const TemplateGallery({super.key});

  Future<void> _import(BuildContext context) async {
    try {
      final imported = await context.read<LibraryViewModel>().importTemplateFile();
      if (imported != null && context.mounted) ClayToast.show(context, 'Loaded "${imported.title}".');
    } on FormatException {
      if (context.mounted) ClayToast.show(context, 'That file could not be read as a template.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = context.select<LibraryViewModel, List<ProjectTemplate>>((lib) => lib.templates);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (ctx, constraints) {
            final bool wide = constraints.maxWidth >= 760;
            const Widget title = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Templates',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Start from a layout and change anything.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: AppDimensions.fontMd,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
            final Widget actions = ClayButton.neutral(
              label: 'Import .mokuply template',
              icon: Icons.file_upload_outlined,
              onPressed: () => _import(context),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(child: title),
                  const SizedBox(width: 24),
                  actions,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [title, const SizedBox(height: 16), actions],
            );
          },
        ),
        const SizedBox(height: 24),
        if (templates.isEmpty)
          const EmptyGallery()
        else
          LayoutBuilder(
            builder: (ctx, constraints) {
              final double width = constraints.maxWidth;
              final int columns = width > 1100 ? 3 : (width > 640 ? 2 : 1);
              // Cards hold a fixed-height preview plus text, so keep their
              // height close to constant instead of scaling with the width.
              final double columnWidth = (width - 20 * (columns - 1)) / columns;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: columnWidth / 420,
                ),
                itemCount: templates.length,
                itemBuilder: (ctx, index) {
                  // Cards stagger after the section header; capped so the
                  // whole entrance stays short on long galleries.
                  return ClayStagger(
                    index: 1 + (index < 6 ? index : 6),
                    child: TemplateCard(template: templates[index]),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
