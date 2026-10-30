import 'link_opener_stub.dart' if (dart.library.html) 'link_opener_web.dart';

/// Opens external pages (GitHub, docs, policies) in a new browser tab.
class LinkOpener {
  LinkOpener._();

  static void open(String url) => openExternalLink(url);
}
