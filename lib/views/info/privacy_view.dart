import 'package:flutter/material.dart';
import '../../core/constants/app_links.dart';
import 'info_page.dart';

/// Privacy policy. Mockuply has no backend, so this mostly lists what stays
/// in the browser and which third parties still see a request.
class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoPage(
      title: 'Privacy Policy',
      subtitle:
          'Short version: Mockuply runs entirely in your browser. There are no accounts, no analytics, no ads and '
          'no tracking cookies. Your screenshots and projects never leave your device.',
      footnote: 'Last updated 31 October 2026',
      children: [
        InfoSection(
          title: 'What we collect',
          children: [
            InfoText(
              'Nothing. Mockuply has no server of its own and no database, so there is nowhere for your data to '
              'go. We do not ask for your name or email, and we do not use analytics, advertising or tracking tools.',
            ),
          ],
        ),
        InfoSection(
          title: 'What stays on your device',
          children: [
            InfoBullets([
              InfoBullet(
                'Screenshots, text and layouts you add are processed in your browser\'s memory. Exports are rendered '
                'and downloaded on your device.',
                lead: 'Your work.',
              ),
              InfoBullet(
                'Your current draft and the templates you save are kept in your browser\'s own storage '
                '(localStorage and IndexedDB) so you can pick up where you left off. Only you can see them.',
                lead: 'Drafts and saved templates.',
              ),
              InfoBullet(
                'Delete saved templates in the app, or clear this site\'s data in your browser settings, and they '
                'are gone for good. We have no copy.',
                lead: 'Removing it.',
              ),
            ]),
          ],
        ),
        InfoSection(
          title: 'Services that still see a request',
          children: [
            InfoText(
              'Like every website, Mockuply has to be downloaded from somewhere. These services receive standard '
              'technical data (your IP address, browser type and the file requested), never your projects:',
            ),
            InfoBullets([
              InfoBullet(
                'Firebase Hosting (Google) serves the app files and may keep short-lived server logs.',
                lead: 'Hosting.',
              ),
              InfoBullet(
                'Typefaces come from Google Fonts (fonts.gstatic.com) and the rendering engine from www.gstatic.com.',
                lead: 'Fonts and renderer.',
              ),
              InfoBullet(
                'If you open a link to GitHub or another site, that site\'s own privacy policy applies.',
                lead: 'External links.',
              ),
            ]),
            InfoLinks({
              'Google Privacy Policy': 'https://policies.google.com/privacy',
              'Firebase privacy': 'https://firebase.google.com/support/privacy',
              'GitHub Privacy Statement':
                  'https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement',
            }),
          ],
        ),
        InfoSection(
          title: 'AI assistants and the MCP server',
          children: [
            InfoText(
              'The optional Mockuply MCP server runs on your own computer. It passes a generated project to this '
              'page over a local connection (127.0.0.1), so nothing is uploaded to us. Whatever you share with your '
              'AI assistant (Claude, Cursor and others) is covered by that provider\'s privacy policy.',
            ),
          ],
        ),
        InfoSection(
          title: 'Children',
          children: [
            InfoText(
              'Mockuply is a design tool for app developers and is not aimed at children. Since we collect nothing, '
              'we hold no data about anyone, including children.',
            ),
          ],
        ),
        InfoSection(
          title: 'Changes and contact',
          children: [
            InfoText(
              'If this policy changes, the new version will be posted on this page with a new date. Questions? '
              'Open an issue on GitHub.',
            ),
            InfoLinks({'Open a GitHub issue': AppLinks.issues}),
          ],
        ),
      ],
    );
  }
}
