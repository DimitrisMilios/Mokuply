// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

/// Opens [url] in a new browser tab, without giving it a handle on this one.
void openExternalLink(String url) {
  html.window.open(url, '_blank', 'noopener,noreferrer');
}
