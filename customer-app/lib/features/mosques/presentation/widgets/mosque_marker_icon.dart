import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sapbaq/core/theme/colors_custom.dart';

/// A circular badge in the brand green with the Material `mosque` glyph in
/// the center — used as a map marker instead of the default red pin. Callers
/// should anchor the marker at `(0.5, 0.5)` so the circle sits centered on
/// the coordinate.
class MosqueMarkerIcon {
  MosqueMarkerIcon._();

  // Cached by device pixel ratio bucket so different DPI screens reuse work.
  static final Map<int, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor> build({double devicePixelRatio = 3}) async {
    final key = (devicePixelRatio * 10).round();
    final cached = _cache[key];
    if (cached != null) return cached;

    final r = devicePixelRatio;
    // Logical size of the badge. A small bleed keeps the soft shadow inside
    // the bitmap bounds.
    const double size = 32;
    const double bleed = 4;
    final pixelSide = ((size + bleed * 2) * r).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset((size / 2 + bleed) * r, (size / 2 + bleed) * r);
    final radius = (size / 2) * r;

    // ---- Soft drop shadow ----
    canvas.drawCircle(
      center.translate(0, 2 * r),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * r),
    );

    // ---- Filled green circle ----
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = ColorsCustom.primary,
    );

    // ---- Subtle outline for definition on light map tiles ----
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ColorsCustom.primaryDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * r,
    );

    // ---- Inner white disc behind the icon (contrast + visual depth) ----
    canvas.drawCircle(center, radius * 0.72, Paint()..color = Colors.white);

    // ---- Mosque glyph ----
    final iconSize = radius * 1.05;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.mosque_rounded.codePoint),
        style: TextStyle(
          fontFamily: Icons.mosque_rounded.fontFamily,
          package: Icons.mosque_rounded.fontPackage,
          fontSize: iconSize,
          color: ColorsCustom.primary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );

    final image =
        await recorder.endRecording().toImage(pixelSide, pixelSide);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      data!.buffer.asUint8List(),
      imagePixelRatio: r,
    );
    _cache[key] = descriptor;
    return descriptor;
  }
}
