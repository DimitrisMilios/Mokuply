import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// An uploaded image drawn small (layer rows, inspector previews), decoded
/// at the size it is shown instead of its full resolution. A 4000 px
/// screenshot shown at 18 px otherwise costs ~64 MB of decoded pixels.
class ThumbnailImage extends StatelessWidget {
  final Uint8List bytes;
  final double width;
  final double height;
  final BoxFit fit;

  const ThumbnailImage({
    super.key,
    required this.bytes,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // `cover` crops one side, so leave headroom for it; `contain` fits inside.
    final int headroom = fit == BoxFit.cover ? 2 : 1;
    return Image(
      image: ResizeImage(
        MemoryImage(bytes),
        width: (width * dpr).ceil() * headroom,
        height: (height * dpr).ceil() * headroom,
        policy: ResizeImagePolicy.fit,
      ),
      width: width,
      height: height,
      fit: fit,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }
}
