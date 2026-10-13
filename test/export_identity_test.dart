import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocuply/data/templates/builtin_templates.dart';
import 'package:mocuply/core/constants/store_specs.dart';
import 'package:mocuply/widgets/canvas/canvas_mockup_widget.dart';

/// Renders the export widget tree for the first template's screens and writes
/// the PNG bytes to `EXPORT_OUT`. Run on two commits and diff the folders to
/// prove the exported pixels did not change. Skipped when `EXPORT_OUT` is
/// unset. One test per screen so a late google_fonts error (fonts are not
/// bundled as assets) cannot abort the remaining dumps.
void main() {
  final out = Platform.environment['EXPORT_OUT'];
  if (out == null) {
    test('export render dump (skipped, EXPORT_OUT unset)', () {});
    return;
  }

  final template = BuiltInTemplates.all.first;
  final screens = template.initialScreenshots.take(1).toList();

  for (final target in TargetPlatformType.values) {
    for (var i = 0; i < screens.length; i++) {
      testWidgets('export render dump ${target.name} $i', (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        Directory(out).createSync(recursive: true);
        final size = target.targetSize;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final key = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              type: MaterialType.transparency,
              child: Center(
                child: RepaintBoundary(
                  key: key,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: DefaultTextStyle(
                      style: const TextStyle(decoration: TextDecoration.none),
                      child: CanvasMockupWidget(
                        data: screens[i].copyWith(platform: target),
                        canvasSize: size,
                        isExporting: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        for (var f = 0; f < 5; f++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        File('$out/${target.name}_$i.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  }
}
