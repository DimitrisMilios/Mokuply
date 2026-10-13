import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../widgets/clay/clay.dart';

/// Name, category and description of a template being saved.
class TemplateFields extends StatelessWidget {
  final TextEditingController title;
  final TextEditingController category;
  final TextEditingController description;

  const TemplateFields({super.key, required this.title, required this.category, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClayField(controller: title, label: 'Name', hint: 'My template'),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ClayField(controller: category, label: 'Category', hint: 'Productivity'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClayField(controller: description, label: 'Description', hint: 'One line about this layout'),
      ],
    );
  }
}

/// The generated Dart snippet in a dark well, selectable.
class DartSnippetWell extends StatelessWidget {
  final String code;

  const DartSnippetWell({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClayLabel('Dart snippet', padding: EdgeInsets.only(left: 4)),
            Spacer(),
            Text(
              'For contributors adding a built-in template',
              style: TextStyle(color: AppColors.textMuted, fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClayWell.dark(
          height: 180,
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: SelectableText(
              code,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.goldLight, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
