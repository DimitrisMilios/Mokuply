import 'dart:async';
import 'dart:ui' as ui;
// Conditional import for Flutter Web browser download
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'desktop_saver.dart';

class ExportService {
  /// Renders a widget at exact [targetSize] using the live Flutter binding
  /// via an Overlay insertion, then captures it with [RenderRepaintBoundary.toImage].
  ///
  /// This ensures Image.memory, GoogleFonts, Material widgets, CustomPaint, and
  /// all inherited widget infrastructure works identically to the on-screen preview.
  static Future<Uint8List> captureHighResWidget({
    required Widget widget,
    required Size targetSize,
    required BuildContext context,
    double pixelRatio = 1.0,
  }) async {
    final Completer<Uint8List> completer = Completer<Uint8List>();
    final GlobalKey repaintKey = GlobalKey();
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (ctx) {
        // Position the widget far off-screen so user never sees it
        return Positioned(
          left: -99999,
          top: -99999,
          child: RepaintBoundary(
            key: repaintKey,
            child: SizedBox(
              width: targetSize.width,
              height: targetSize.height,
              child: MediaQuery(
                data: MediaQueryData(
                  size: targetSize,
                  devicePixelRatio: pixelRatio,
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      decoration: TextDecoration.none,
                    ),
                    child: widget,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Insert into the live Overlay
    final overlayState = Overlay.of(context);
    overlayState.insert(overlayEntry);

    // Wait for multiple frames so images decode, fonts load, and layout settles
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      // ignore: await_only_futures
      await WidgetsBinding.instance.endOfFrame;
    }

    try {
      final RenderRepaintBoundary boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) {
        throw Exception("Failed to encode capture to PNG byte data.");
      }

      completer.complete(byteData.buffer.asUint8List());
    } catch (e) {
      completer.completeError(e);
    } finally {
      overlayEntry.remove();
    }

    return completer.future;
  }

  /// Packages a map of filepath/filename -> Uint8List into a ZIP archive.
  static Uint8List createZipArchive(Map<String, Uint8List> files) {
    final archive = Archive();
    for (final entry in files.entries) {
      final archiveFile = ArchiveFile(
        entry.key,
        entry.value.length,
        entry.value,
      );
      archive.addFile(archiveFile);
    }
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    return Uint8List.fromList(zipBytes);
  }

  /// Triggers a client-side browser or desktop file download.
  static Future<void> downloadFileWeb({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();

      // Delay revoking Object URL so browser has time to finish saving
      Future.delayed(const Duration(seconds: 4), () {
        html.Url.revokeObjectUrl(url);
      });
    } else {
      final String? savedPath =
          await DesktopSaver.saveToDownloads(bytes, filename);
      debugPrint("Desktop save complete. Saved to: $savedPath");
    }
  }

  /// Legacy helper for single PNG download
  static void downloadPngWeb({
    required Uint8List pngBytes,
    required String filename,
  }) {
    downloadFileWeb(
        bytes: pngBytes, filename: filename, mimeType: 'image/png');
  }
}
