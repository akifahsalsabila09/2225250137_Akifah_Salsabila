import 'package:flutter/material.dart';

/// Menulis teks di kanvas. [anchor] menentukan titik acuan (0.5,0.5 = tengah).
Size drawLabel(
  Canvas c,
  String text,
  Offset at, {
  Color color = const Color(0xFF2D2D2D),
  double size = 13,
  bool bold = false,
  Color? background,
  Offset anchor = const Offset(0.5, 0.5),
  double maxWidth = 240,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w600),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);
  final topLeft = at - Offset(tp.width * anchor.dx, tp.height * anchor.dy);
  if (background != null) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(topLeft.dx - 6, topLeft.dy - 3, tp.width + 12, tp.height + 6),
      const Radius.circular(8),
    );
    c.drawRRect(r, Paint()..color = background);
    c.drawRRect(
        r,
        Paint()
          ..color = color.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }
  tp.paint(c, topLeft);
  return Size(tp.width, tp.height);
}

/// Panah dua arah dengan label (untuk jarak).
void drawSpanArrow(Canvas c, double x1, double x2, double y, String label, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(x1, y), Offset(x2, y), p);
  for (final (x, dir) in [(x1, 1.0), (x2, -1.0)]) {
    c.drawLine(Offset(x, y), Offset(x + 8 * dir, y - 5), p);
    c.drawLine(Offset(x, y), Offset(x + 8 * dir, y + 5), p);
    c.drawLine(Offset(x, y - 7), Offset(x, y + 7), p);
  }
  drawLabel(c, label, Offset((x1 + x2) / 2, y), color: color, bold: true, background: Colors.white);
}

void drawDashedLine(Canvas c, Offset a, Offset b, Paint p, {double dash = 14, double gap = 10, double phase = 0}) {
  final total = (b - a).distance;
  if (total == 0) return;
  final dir = (b - a) / total;
  var d = -(phase % (dash + gap));
  while (d < total) {
    final s = d.clamp(0.0, total);
    final e = (d + dash).clamp(0.0, total);
    if (e > s) c.drawLine(a + dir * s, a + dir * e, p);
    d += dash + gap;
  }
}

/// Jalan aspal horizontal.
void drawRoad(Canvas c, Rect r, {double phase = 0}) {
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = const Color(0xFF5B5B5B));
  final edge = Paint()
    ..color = Colors.white.withValues(alpha: 0.7)
    ..strokeWidth = 2;
  c.drawLine(Offset(r.left + 6, r.top + 4), Offset(r.right - 6, r.top + 4), edge);
  c.drawLine(Offset(r.left + 6, r.bottom - 4), Offset(r.right - 6, r.bottom - 4), edge);
  drawDashedLine(
    c,
    Offset(r.left + 8, r.center.dy),
    Offset(r.right - 8, r.center.dy),
    Paint()
      ..color = const Color(0xFFF2C94C)
      ..strokeWidth = 3,
    phase: phase,
  );
}

void drawPlace(Canvas c, Offset at, String name, {Color color = const Color(0xFF4F4F4F)}) {
  c.drawCircle(at, 9, Paint()..color = Colors.white);
  c.drawCircle(
      at,
      9,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
  c.drawCircle(at, 3.5, Paint()..color = color);
  if (name.isNotEmpty) drawLabel(c, name, at + const Offset(0, 22), size: 12, bold: true);
}
