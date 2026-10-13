/// The kinds of element a screen can hold, read from the element id.
///
/// Ids are `title`, `subtitle`, or a kind prefix followed by a unique stamp
/// (`dev_…`, `img_…`, `txt_…`). Starter templates reuse ids across screens,
/// so an id is only unique within one screen.
enum ElementKind {
  title,
  subtitle,
  device,
  image,
  text;

  static const String titleId = 'title';
  static const String subtitleId = 'subtitle';

  /// The kind of the element called [id], or null for an unknown id.
  static ElementKind? of(String? id) {
    if (id == null) return null;
    if (id == titleId) return ElementKind.title;
    if (id == subtitleId) return ElementKind.subtitle;
    if (id.startsWith('dev_')) return ElementKind.device;
    if (id.startsWith('img_')) return ElementKind.image;
    if (id.startsWith('txt_')) return ElementKind.text;
    return null;
  }

  /// The headline and subtitle: unique per screen, cleared instead of removed.
  bool get isHeadline => this == ElementKind.title || this == ElementKind.subtitle;

  /// Phone frames, images and extra text can be rotated and duplicated.
  bool get isFreeform => !isHeadline;

  /// A fresh id for a new element of this kind.
  String newId([String suffix = '']) {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return switch (this) {
      ElementKind.title => titleId,
      ElementKind.subtitle => subtitleId,
      ElementKind.device => 'dev_$stamp$suffix',
      ElementKind.image => 'img_$stamp$suffix',
      ElementKind.text => 'txt_$stamp$suffix',
    };
  }
}
