import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../services/link_opener.dart';
import '../../widgets/clay/clay.dart';
import '../../widgets/shared/ambient_background.dart';
import '../../widgets/shared/brand_logo.dart';

/// Shared layout for the text pages opened from the home footer (privacy,
/// terms, AI setup): a floating clay bar with a back button over a centred,
/// scrollable column of sections.
class InfoPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Muted line under the content, e.g. "Last updated …".
  final String? footnote;

  const InfoPage({super.key, required this.title, required this.subtitle, required this.children, this.footnote});

  static const double _maxWidth = 820;
  static const double _topPadding = 110;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sand,
      body: AmbientBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: _topPadding, left: 24, right: 24, bottom: 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClayStagger(index: 0, child: _Header(title: title, subtitle: subtitle)),
                        const SizedBox(height: 28),
                        for (var i = 0; i < children.length; i++) ...[
                          if (i > 0) const SizedBox(height: 20),
                          ClayStagger(index: i + 1, child: children[i]),
                        ],
                        if (footnote != null) ...[
                          const SizedBox(height: 28),
                          Text(
                            footnote!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: AppDimensions.fontSm,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Positioned(top: 0, left: 0, right: 0, child: _InfoBar()),
          ],
        ),
      ),
    );
  }
}

class _InfoBar extends StatelessWidget {
  const _InfoBar();

  @override
  Widget build(BuildContext context) {
    void back() => Navigator.of(context).maybePop();
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 24.0, right: 24.0, bottom: 8.0),
      child: ClayPanel(
        height: AppDimensions.navbarHeight,
        radius: AppDimensions.radiusClayXl,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingLg),
        child: Row(
          children: [
            ClayIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', size: 44, radius: 22, onPressed: back),
            const SizedBox(width: AppDimensions.spacingMd),
            const BrandLogo(size: 36, radius: AppDimensions.radiusMd),
            const SizedBox(width: AppDimensions.spacingMd),
            const Flexible(
              child: Text(
                'Mockuply',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppDimensions.fontXl,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// One clay card: optional step badge, heading, then free content.
class InfoSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  /// Gold number badge before the title (setup steps).
  final int? step;

  const InfoSection({super.key, required this.title, required this.children, this.step});

  @override
  Widget build(BuildContext context) {
    return ClayPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (step != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const ClayDecoration.gold(radius: 16, lift: 6, depth: 3),
                  child: Text(
                    '$step',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: AppDimensions.fontLg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMd),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: AppDimensions.fontXl,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Body paragraph.
class InfoText extends StatelessWidget {
  final String text;

  const InfoText(this.text, {super.key});

  static const TextStyle style = TextStyle(
    color: AppColors.textSecondary,
    fontSize: AppDimensions.fontLg,
    fontWeight: FontWeight.w600,
    height: 1.6,
  );

  @override
  Widget build(BuildContext context) => Text(text, style: style);
}

/// Bulleted list with gold dots. A bullet may start with a bold lead-in,
/// written as "Lead-in: rest of the sentence" via [InfoBullet].
class InfoBullets extends StatelessWidget {
  final List<InfoBullet> items;

  const InfoBullets(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 9, right: 12, left: 2),
                  decoration: const BoxDecoration(color: AppColors.goldDeep, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (item.lead != null)
                          TextSpan(
                            text: '${item.lead} ',
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
                          ),
                        TextSpan(text: item.text),
                      ],
                    ),
                    style: InfoText.style,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class InfoBullet {
  final String? lead;
  final String text;

  const InfoBullet(this.text, {this.lead});
}

/// A row of flat external links.
class InfoLinks extends StatelessWidget {
  final Map<String, String> links;

  const InfoLinks(this.links, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final entry in links.entries)
          ClayButton.text(
            label: entry.key,
            icon: Icons.open_in_new_rounded,
            size: ClayButtonSize.compact,
            color: AppColors.primary,
            onPressed: () => LinkOpener.open(entry.value),
          ),
      ],
    );
  }
}

/// Selectable code in a dark well with a copy button.
class InfoCode extends StatefulWidget {
  final String code;

  /// Small caption above the well ("macOS / Linux / PowerShell").
  final String? label;

  const InfoCode(this.code, {super.key, this.label});

  @override
  State<InfoCode> createState() => _InfoCodeState();
}

class _InfoCodeState extends State<InfoCode> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    ClayToast.show(context, 'Copied');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label != null) ...[
          ClayLabel(widget.label!, padding: const EdgeInsets.only(left: 4)),
          const SizedBox(height: 6),
        ],
        ClayWell.dark(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: SelectableText(
                    widget.code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: AppDimensions.fontBody,
                      color: AppColors.goldLight,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ClayIconButton(
                icon: _copied ? Icons.check_rounded : Icons.copy_rounded,
                tooltip: 'Copy',
                size: 36,
                iconSize: 18,
                onPressed: _copy,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
