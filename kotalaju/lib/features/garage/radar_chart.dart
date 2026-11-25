import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/domain/problem.dart';
import '../../core/widgets/paint_utils.dart';

/// Grafik radar 4 sumbu untuk kemampuan Mathematical Literacy (nilai 0..1).
class RadarChart extends StatelessWidget {
  final Map<Indicator, double> values;
  final Map<Indicator, double>? compare;
  final double size;
  const RadarChart({super.key, required this.values, this.compare, this.size = 220});

  @override
  Widget build(BuildContext context) {
    final desc = values.entries.map((e) => '${e.key.en} ${(e.value * 100).round()} persen').join(', ');
    return Semantics(
      label: 'Grafik kemampuan literasi: $desc',
      child: SizedBox(
        width: size + 80,
        height: size + 40,
        child: CustomPaint(painter: _RadarPainter(values, compare)),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final Map<Indicator, double> v;
  final Map<Indicator, double>? cmp;
  _RadarPainter(this.v, this.cmp);

  @override
  void paint(Canvas c, Size s) {
    final o = Offset(s.width / 2, s.height / 2);
    final r = min(s.width - 80, s.height - 40) / 2;
    const n = 4;
    Offset pt(int i, double f) {
      final a = -pi / 2 + i * 2 * pi / n;
      return o + Offset(cos(a), sin(a)) * r * f;
    }

    final grid = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final f in [0.25, 0.5, 0.75, 1.0]) {
      final path = Path()..moveTo(pt(0, f).dx, pt(0, f).dy);
      for (var i = 1; i <= n; i++) {
        path.lineTo(pt(i % n, f).dx, pt(i % n, f).dy);
      }
      c.drawPath(path, grid);
    }
    for (var i = 0; i < n; i++) {
      c.drawLine(o, pt(i, 1), grid);
      final ind = Indicator.values[i];
      drawLabel(c, ind.en, pt(i, 1.18), size: 11, bold: true);
    }

    Path poly(Map<Indicator, double> m) {
      final p = Path();
      for (var i = 0; i < n; i++) {
        final q = pt(i, (m[Indicator.values[i]] ?? 0).clamp(0.02, 1.0));
        if (i == 0) {
          p.moveTo(q.dx, q.dy);
        } else {
          p.lineTo(q.dx, q.dy);
        }
      }
      return p..close();
    }

    if (cmp != null) {
      final p = poly(cmp!);
      final dashed = Paint()
        ..color = Colors.black45
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final m in p.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 10) {
          c.drawPath(m.extractPath(d, d + 5), dashed);
        }
      }
    }
    final main = poly(v);
    c.drawPath(main, Paint()..color = AppColors.distance.withValues(alpha: 0.3));
    c.drawPath(
        main,
        Paint()
          ..color = AppColors.distance
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) => true;
}
