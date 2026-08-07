import 'dart:async';
import 'dart:ui' as ui;
// Conditional import for Flutter Web browser download
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ExportService {
  /// Renders a given Widget off-screen at the exact target [targetSize] (e.g., 1320x2868 px or 1080x2340 px)
  /// using Flutter's pipeline and [RenderRepaintBoundary], completely independent of screen scaling or display DPI.
  ///
  /// Returns high-resolution PNG image bytes with 100% opaque background (no transparency/alpha).
  static Future<Uint8List> captureHighResWidget({
    required Widget widget,
    required Size targetSize,
    double pixelRatio = 1.0,
  }) async {
    final BuildOwner buildOwner = BuildOwner(focusManager: FocusManager());
    final PipelineOwner pipelineOwner = PipelineOwner();

    final RenderRepaintBoundary repaintBoundary = RenderRepaintBoundary();
    pipelineOwner.rootNode = repaintBoundary;
    repaintBoundary.attach(pipelineOwner);

    final RenderObjectToWidgetAdapter<RenderBox> rootAdapter = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(
            size: targetSize,
            devicePixelRatio: pixelRatio,
          ),
          child: Material(
            type: MaterialType.canvas,
            color: Colors.black, // Opaque base layer to prevent any alpha channel transparency
            child: SizedBox(
              width: targetSize.width,
              height: targetSize.height,
              child: widget,
            ),
          ),
        ),
      ),
    );

    final RenderObjectToWidgetElement<RenderBox> element = rootAdapter.attachToRenderTree(buildOwner);

    buildOwner.buildScope(element);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    // Allow dynamic fonts or image frames to resolve layout frames if needed
    await Future.delayed(const Duration(milliseconds: 50));

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final ui.Image image = await repaintBoundary.toImage(pixelRatio: pixelRatio);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      throw Exception("Failed to encode off-screen capture to PNG byte data.");
    }

    return byteData.buffer.asUint8List();
  }

  /// Triggers 100% client-side browser file download for the generated PNG [pngBytes].
  static void downloadPngWeb({
    required Uint8List pngBytes,
    required String filename,
  }) {
    if (kIsWeb) {
      final blob = html.Blob([pngBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
    } else {
      debugPrint("Download triggered outside web environment. Filename: $filename (${pngBytes.length} bytes)");
    }
  }
}
