import 'package:flutter/material.dart';
import '../../core/constants/app_links.dart';
import 'info_page.dart';

/// Terms of use. Plain-language terms for a free, open-source, account-free
/// tool; the MIT license covers the code itself.
class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Terms of Use',
      subtitle:
          'Mockuply is free and open source. By using it you agree to these simple terms. There is nothing to sign '
          'up for and nothing to pay.',
      footnote: 'Last updated 31 October 2026',
      children: [
        InfoSection(
          title: 'Your content is yours',
          children: [
            InfoText(
              'You keep every right to the screenshots, text and images you put into Mockuply and to the mockups you '
              'export. We never receive them, so we claim nothing over them.',
            ),
            InfoText(
              'You are responsible for having the rights to what you use (screenshots, logos, images, fonts) and for '
              'following the App Store and Google Play guidelines when you publish your screenshots.',
            ),
          ],
        ),
        InfoSection(
          title: 'Fair use',
          children: [
            InfoBullets([
              InfoBullet('Use Mockuply for any personal or commercial project, including client work.'),
              InfoBullet('Do not use it to create content that is unlawful, deceptive or infringes someone else\'s rights.'),
              InfoBullet('Do not try to disrupt or overload the hosted site.'),
            ]),
          ],
        ),
        InfoSection(
          title: 'Open-source license',
          children: [
            InfoText(
              'The Mockuply source code is released under the MIT License. You may use, copy, modify and distribute '
              'it under that license.',
            ),
            InfoLinks({'MIT License': AppLinks.license, 'Source on GitHub': AppLinks.repo}),
          ],
        ),
        InfoSection(
          title: 'Trademarks',
          children: [
            InfoText(
              'Apple, iPhone and App Store are trademarks of Apple Inc. Google Play is a trademark of Google LLC. '
              'Samsung and Galaxy are trademarks of Samsung Electronics. Mockuply is an independent project and is '
              'not affiliated with or endorsed by any of them. Device frames are provided only to present your own '
              'app. Fonts are served by Google Fonts under their own open licenses.',
            ),
          ],
        ),
        InfoSection(
          title: 'No warranty',
          children: [
            InfoText(
              'Mockuply is provided "as is", without warranty of any kind. Your drafts live only in your browser: '
              'clearing site data, private browsing or switching devices can remove them, so export or download '
              'anything you want to keep. To the extent the law allows, the authors are not liable for any loss or '
              'damage arising from using Mockuply.',
            ),
          ],
        ),
        InfoSection(
          title: 'Changes and contact',
          children: [
            InfoText(
              'These terms may be updated from time to time; the date below shows the latest version. Continuing to '
              'use Mockuply after a change means you accept the new terms. Questions? Open an issue on GitHub.',
            ),
            InfoLinks({'Open a GitHub issue': AppLinks.issues}),
          ],
        ),
      ],
    );
  }
}
