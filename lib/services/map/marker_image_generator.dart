import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../config/theme/app_typography.dart';

/// Generates marker images for the map using Canvas/PictureRecorder.
/// Returns Uint8List PNG data suitable for PointAnnotationOptions.image.
class MarkerImageGenerator {
  static const Color _purple = Color(0xFF9044FF);
  static const double _devicePixelRatio = 2.0;

  // Cache to avoid regenerating identical images.
  static final Map<String, Uint8List> _cache = {};

  /// Generates a small purple dot marker with white border and shadow.
  static Future<Uint8List> generateDotMarker({
    double radius = 7.0,
    double borderWidth = 2.0,
  }) async {
    final cacheKey = 'dot_${radius}_$borderWidth';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    final totalRadius = (radius + borderWidth) * _devicePixelRatio;
    final size = totalRadius * 2 + 6 * _devicePixelRatio; // extra for shadow

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final center = Offset(size / 2, size / 2 - 1 * _devicePixelRatio);

    // Shadow
    canvas.drawCircle(
      center + Offset(0, 2 * _devicePixelRatio),
      radius * _devicePixelRatio,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );

    // White border
    canvas.drawCircle(
      center,
      (radius + borderWidth) * _devicePixelRatio,
      Paint()..color = const ui.Color.fromARGB(255, 235, 235, 235),
    );

    // Purple fill
    canvas.drawCircle(
      center,
      radius * _devicePixelRatio,
      Paint()..color = _purple,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.ceil(), size.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = byteData!.buffer.asUint8List();

    _cache[cacheKey] = result;
    return result;
  }

  /// Generates a pill-shaped marker with venue name and pointer triangle.
  static Future<Uint8List> generatePillMarker({
    required String title,
    double fontSize = 11.5,
    double horizontalPadding = 12.0,
    double verticalPadding = 7.0,
    double pointerHeight = 7.0,
    double borderRadius = 14.0,
  }) async {
    final cacheKey = 'pill_$title';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    // Truncate long names
    String displayTitle = title;
    if (displayTitle.length > 26) {
      displayTitle = '${displayTitle.substring(0, 24)}…';
    }

    // Measure text
    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: fontSize * _devicePixelRatio,
      fontWeight: FontWeight.w700,
      fontFamily: AppTypography.headingFontFamily,
    );

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: 1),
    )
      ..pushStyle(textStyle)
      ..addText(displayTitle);

    final paragraph = paragraphBuilder.build();
    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    final textWidth = paragraph.longestLine.ceilToDouble();
    final textHeight = paragraph.height.ceilToDouble();

    // Calculate dimensions
    final hPad = horizontalPadding * _devicePixelRatio;
    final vPad = verticalPadding * _devicePixelRatio;
    final ptrH = pointerHeight * _devicePixelRatio;
    final ptrW = 12.0 * _devicePixelRatio;
    final rad = borderRadius * _devicePixelRatio;
    final shadowExtra = 6.0 * _devicePixelRatio;

    final pillWidth = textWidth + hPad * 2;
    final pillHeight = textHeight + vPad * 2;
    final totalWidth = pillWidth + shadowExtra * 2;
    final totalHeight = pillHeight + ptrH + shadowExtra;

    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, totalWidth, totalHeight));

    final pillLeft = (totalWidth - pillWidth) / 2;
    final pillTop = shadowExtra / 2;
    final pillRect = RRect.fromLTRBR(
      pillLeft,
      pillTop,
      pillLeft + pillWidth,
      pillTop + pillHeight,
      Radius.circular(rad),
    );

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowExtra / 2);
    canvas.drawRRect(pillRect.shift(const Offset(0, 2)), shadowPaint);

    // Pill body
    final fillPaint = Paint()..color = _purple;
    canvas.drawRRect(pillRect, fillPaint);

    // Pointer triangle
    final cx = totalWidth / 2;
    final pointerTop = pillTop + pillHeight;
    final pointerPath = Path()
      ..moveTo(cx - ptrW / 2, pointerTop)
      ..lineTo(cx, pointerTop + ptrH)
      ..lineTo(cx + ptrW / 2, pointerTop)
      ..close();
    canvas.drawPath(pointerPath, fillPaint);

    // Text centered in pill
    paragraph.layout(ui.ParagraphConstraints(width: pillWidth));
    canvas.drawParagraph(
      paragraph,
      Offset(pillLeft, pillTop + vPad),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(totalWidth.ceil(), totalHeight.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = byteData!.buffer.asUint8List();

    _cache[cacheKey] = result;
    return result;
  }

  /// Clear the image cache (call when navigating away from map).
  static void clearCache() => _cache.clear();
}
