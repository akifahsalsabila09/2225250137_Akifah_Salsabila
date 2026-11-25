import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../domain/clock.dart';
import '../domain/format.dart';
import '../domain/motion.dart';
import '../domain/problem.dart';
import 'paint_utils.dart';
import 'vehicle.dart';

/// Diagram jalan untuk setiap soal cerita (DS03, EL02).
/// Label angka diletakkan langsung di gambar (spatial contiguity) dengan warna besaran.
class RoadSceneView extends StatelessWidget {
  final SceneData scene;
  final double? clockMinutes;
  final bool showBand;
  final bool showLabels;
  final double height;
  const RoadSceneView({
    super.key,
    required this.scene,
    this.clockMinutes,
    this.showBand = false,
    this.showLabels = true,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Diagram jalan dari ${scene.leftName} ke ${scene.rightName}',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF6E3),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD5E8C9)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CustomPaint(
            painter: RoadScenePainter(scene, clockMinutes: clockMinutes, showBand: showBand, showLabels: showLabels),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class RoadScenePainter extends CustomPainter {
  final SceneData scene;
  final double? clockMinutes;
  final bool showBand;
  final bool showLabels;
  RoadScenePainter(this.scene, {this.clockMinutes, this.showBand = false, this.showLabels = true});

  double get _t0 => scene.movers.isEmpty
      ? 0
      : scene.movers.map((m) => m.departAt.minutes).reduce(min).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    switch (scene.type) {
      case SceneType.single:
      case SceneType.straight:
        _paintStraight(canvas, size);
      case SceneType.routes:
        _paintRoutes(canvas, size);
      case SceneType.legs:
        _paintLegs(canvas, size);
    }
  }

  void _paintStraight(Canvas c, Size size) {
    const margin = 34.0;
    final roadY = size.height * 0.62;
    final left = margin, right = size.width - margin;
    final roadRect = Rect.fromLTRB(left - 14, roadY - 16, right + 14, roadY + 16);
    final now = clockMinutes ?? _t0;
    final dashPhase = clockMinutes == null ? 0.0 : (now - _t0) * 4;
    drawRoad(c, roadRect, phase: dashPhase);
    final catchUp = scene.movers.length == 2 && scene.movers[0].direction == scene.movers[1].direction;
    drawPlace(c, Offset(left, roadY + 22), scene.leftName);
    if (!catchUp || scene.type == SceneType.single) {
      drawPlace(c, Offset(right, roadY + 22), scene.rightName);
    }
    double xOf(double km) => left + (km / scene.lengthKm).clamp(-0.05, 1.05) * (right - left);

    // Panah jarak total (bukan untuk soal menyusul yang jaraknya tidak diketahui).
    if (showLabels && !catchUp && scene.rightName != '?') {
      drawSpanArrow(c, left, right, 18, '${fmtNum(scene.lengthKm)} km', AppColors.distance);
    } else if (showLabels && scene.rightName == '?') {
      drawSpanArrow(c, left, right, 18, '? km', AppColors.distance);
    }

    // Pita jarak (A06): selisih posisi dua kendaraan.
    if (showBand && scene.movers.length == 2) {
      final pa = MotionSimulator.positionAt(scene.movers[0], now);
      final pb = MotionSimulator.positionAt(scene.movers[1], now);
      final gap = (pb - pa).abs();
      if (gap > 0.01) {
        final x1 = xOf(min(pa, pb)), x2 = xOf(max(pa, pb));
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(x1, roadY - 6, x2, roadY + 6), const Radius.circular(6)),
          Paint()..color = AppColors.distance.withValues(alpha: 0.55),
        );
        drawLabel(c, 'jarak antara: ${fmtNum(gap)} km', Offset((x1 + x2) / 2, roadY + 46),
            color: AppColors.distance, bold: true, background: Colors.white, size: 12);
      }
    }

    for (var i = 0; i < scene.movers.length; i++) {
      final m = scene.movers[i];
      final pos = MotionSimulator.positionAt(m, now);
      final x = xOf(pos);
      final vw = min(64.0, size.width * 0.15);
      final laneOffset = scene.movers.length == 2 ? (i == 0 ? -4.0 : 4.0) : 0.0;
      final y = roadY - vw * 0.30 + laneOffset;
      final started = now >= m.departAt.minutes;
      final turn = started ? (now - m.departAt.minutes) * m.speedKmh / 300 : 0.0;
      drawVehicleAt(c, Offset(x, y), vw, m.vehicle, facingRight: m.direction > 0, turn: turn);
      if (showLabels) {
        final ly = size.height * 0.30 + (catchUp ? i * 22.0 : 0);
        final lx = catchUp ? size.width * 0.5 : (i == 0 ? left + 40 : right - 40);
        final tag = scene.movers.length > 1 ? '${m.id}: ' : '';
        drawLabel(c, '$tag${fmtNum(m.speedKmh)} km/jam', Offset(lx, ly),
            color: AppColors.speed, bold: true, size: 12, background: Colors.white);
        if (scene.showTimeline || scene.movers.length > 1) {
          drawLabel(c, '${scene.movers.length > 1 ? m.id : ''} 🕐 ${m.departAt.label}',
              Offset(catchUp ? lx + 110 : lx, catchUp ? ly : ly + 22),
              color: AppColors.clock, size: 11, bold: true);
        }
        if (!started && clockMinutes != null) {
          drawLabel(c, 'menunggu', Offset(x, y - 26), size: 10, color: Colors.black54);
        }
      }
    }
    if (clockMinutes != null) {
      drawLabel(c, '🕐 ${ClockTime(now.round()).label}', Offset(size.width - 12, size.height - 12),
          anchor: const Offset(1, 1), color: AppColors.clock, bold: true, size: 13, background: Colors.white);
    }
  }

  void _paintRoutes(Canvas c, Size size) {
    final a = Offset(36, size.height * 0.55);
    final b = Offset(size.width - 36, size.height * 0.55);
    final n = scene.routes.length;
    for (var i = 0; i < n; i++) {
      final route = scene.routes[i];
      final bend = (i - (n - 1) / 2) * size.height * 0.85;
      final ctrl = Offset(size.width / 2, size.height * 0.55 + bend);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      c.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF5B5B5B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 18
            ..strokeCap = StrokeCap.round);
      c.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFF2C94C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      final mid = Offset(size.width / 2, (a.dy + 2 * ctrl.dy + b.dy) / 4);
      if (showLabels) {
        final allSameKm = scene.routes.every((r) => r.km == scene.routes.first.km);
        final txt = allSameKm
            ? '${route.name} • ${fmtNum(route.kmh)} km/jam'
            : '${route.name} • ${fmtNum(route.km)} km • ${fmtNum(route.kmh)} km/jam';
        drawLabel(c, txt, mid, color: AppColors.speed, bold: true, size: 12, background: Colors.white);
      }
    }
    drawPlace(c, a, scene.leftName);
    drawPlace(c, b, scene.rightName);
    if (showLabels && scene.routes.every((r) => r.km == scene.routes.first.km)) {
      drawLabel(c, 'Jarak sama: ${fmtNum(scene.lengthKm)} km', Offset(size.width / 2, size.height - 12),
          color: AppColors.distance, bold: true, size: 12, anchor: const Offset(0.5, 1));
    }
    if (scene.movers.isNotEmpty) {
      drawVehicleAt(c, a + const Offset(0, -26), 46, scene.movers.first.vehicle);
    }
  }

  void _paintLegs(Canvas c, Size size) {
    const margin = 34.0;
    final roadY = size.height * 0.62;
    final left = margin, right = size.width - margin;
    drawRoad(c, Rect.fromLTRB(left - 14, roadY - 16, right + 14, roadY + 16));
    final total = scene.legs.fold<double>(0, (a, l) => a + l.km);
    var acc = 0.0;
    var prevX = left;
    drawPlace(c, Offset(left, roadY + 22), scene.leftName);
    for (var i = 0; i < scene.legs.length; i++) {
      final leg = scene.legs[i];
      acc += leg.km;
      final x = left + acc / total * (right - left);
      if (i < scene.legs.length - 1) {
        drawPlace(c, Offset(x, roadY + 22), 'Istirahat', color: AppColors.time);
      } else {
        drawPlace(c, Offset(x, roadY + 22), scene.rightName);
      }
      if (showLabels) {
        drawSpanArrow(c, prevX + 4, x - 4, 18, '${fmtNum(leg.km)} km', AppColors.distance);
        drawLabel(c, '${fmtNum(leg.kmh)} km/jam', Offset((prevX + x) / 2, size.height * 0.36),
            color: AppColors.speed, bold: true, size: 12, background: Colors.white);
      }
      prevX = x;
    }
    if (scene.movers.isNotEmpty) {
      drawVehicleAt(c, Offset(left + 10, roadY - 18), min(56.0, size.width * 0.14), scene.movers.first.vehicle);
    }
  }

  @override
  bool shouldRepaint(covariant RoadScenePainter old) =>
      old.scene != scene || old.clockMinutes != clockMinutes || old.showBand != showBand || old.showLabels != showLabels;
}

/// Garis waktu: jam berangkat (ungu) dan durasi (hijau).
class TimelineMark {
  final String label;
  final ClockTime start;
  final ClockTime? end;
  final Color color;
  const TimelineMark(this.label, this.start, {this.end, this.color = AppColors.clock});
}

class TimelineView extends StatelessWidget {
  final List<TimelineMark> marks;
  final ClockTime from;
  final ClockTime to;
  final double? nowMinutes;
  const TimelineView({super.key, required this.marks, required this.from, required this.to, this.nowMinutes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0 + marks.length * 26,
      child: CustomPaint(painter: _TimelinePainter(marks, from, to, nowMinutes), size: Size.infinite),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  final List<TimelineMark> marks;
  final ClockTime from, to;
  final double? now;
  _TimelinePainter(this.marks, this.from, this.to, this.now);

  @override
  void paint(Canvas c, Size size) {
    const l = 56.0, r = 16.0;
    final span = max(1, to.minutes - from.minutes);
    double xOf(num m) => l + (m - from.minutes) / span * (size.width - l - r);
    final axisY = size.height - 22;
    final axis = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5;
    c.drawLine(Offset(l, axisY), Offset(size.width - r, axisY), axis);
    final step = span <= 90 ? 15 : (span <= 240 ? 30 : 60);
    for (var m = (from.minutes / step).ceil() * step; m <= to.minutes; m += step) {
      final x = xOf(m);
      c.drawLine(Offset(x, axisY - 4), Offset(x, axisY + 4), axis);
      drawLabel(c, ClockTime(m).label, Offset(x, axisY + 12), size: 10, color: Colors.black54);
    }
    for (var i = 0; i < marks.length; i++) {
      final mk = marks[i];
      final y = 12.0 + i * 26;
      drawLabel(c, mk.label, Offset(4, y), anchor: const Offset(0, 0.5), size: 11, bold: true);
      final xs = xOf(mk.start.minutes);
      if (mk.end != null) {
        final xe = xOf(mk.end!.minutes);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(xs, y - 6, xe, y + 6), const Radius.circular(6)),
            Paint()..color = AppColors.time.withValues(alpha: 0.75));
        drawLabel(c, '${mk.end!.minutes - mk.start.minutes} mnt', Offset((xs + xe) / 2, y), size: 10, color: Colors.white, bold: true);
      }
      c.drawCircle(Offset(xs, y), 6, Paint()..color = mk.color);
    }
    if (now != null) {
      final x = xOf(now!);
      c.drawLine(Offset(x, 0), Offset(x, axisY), Paint()
        ..color = AppColors.wrong
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) => old.now != now || old.marks != marks;
}
