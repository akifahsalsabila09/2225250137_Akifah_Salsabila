import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/domain/clock.dart';
import '../../core/domain/format.dart';
import '../../core/domain/motion.dart';
import '../../core/domain/problem.dart';
import '../../core/widgets/animation_player.dart';
import '../../core/widgets/paint_utils.dart';
import '../../core/widgets/road_scene.dart';
import '../../core/widgets/vehicle.dart';

/// Membuat animasi instruksional berdasarkan id (design.md §4.3).
Widget buildLessonAnimation(String id, {VoidCallback? onFinished}) => switch (id) {
      'markers' => MarkersAnimation(onFinished: onFinished),
      'headon' => HeadOnAnimation(onFinished: onFinished),
      'catchup' => CatchUpAnimation(onFinished: onFinished),
      'ladder' => LadderAnimation(onFinished: onFinished),
      'kmh2ms' => KmhToMsAnimation(onFinished: onFinished),
      'timewheel' => const TimeWheel(),
      'pizza' => const PizzaClock(),
      'clockgap' => const ClockGap(),
      _ => Text('Animasi "$id" belum tersedia'),
    };

// ───────────── A01 Mobil dan tiang jam ─────────────

class MarkersAnimation extends StatelessWidget {
  final VoidCallback? onFinished;
  const MarkersAnimation({super.key, this.onFinished});

  @override
  Widget build(BuildContext context) {
    return AnimationPlayer(
      duration: const Duration(seconds: 9),
      checkpoints: const [1 / 3, 2 / 3, 1],
      captions: const [
        '1 jam → 60 km',
        '2 jam → 120 km (60 + 60)',
        '3 jam → 180 km. Jarak = 60 × 3 = kecepatan × waktu!',
      ],
      onFinished: onFinished,
      builder: (_, t) => SizedBox(height: 170, child: CustomPaint(painter: _MarkersPainter(t), size: Size.infinite)),
    );
  }
}

class _MarkersPainter extends CustomPainter {
  final double t;
  _MarkersPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(18)), Paint()..color = const Color(0xFFEAF6E3));
    const l = 30.0;
    final r = s.width - 30;
    final roadY = s.height * 0.62;
    drawRoad(c, Rect.fromLTRB(l - 14, roadY - 16, r + 14, roadY + 16), phase: t * 300);
    final hours = t * 3;
    for (var h = 1; h <= 3; h++) {
      final x = l + h / 3 * (r - l);
      final reached = hours >= h - 1e-6;
      final post = Paint()..color = reached ? AppColors.distance : Colors.black26;
      c.drawRect(Rect.fromLTWH(x - 2, roadY - 60, 4, 44), post);
      if (reached) {
        drawLabel(c, '+60 km', Offset(x, roadY - 70), color: AppColors.distance, bold: true, background: Colors.white, size: 12);
        drawLabel(c, '$h jam', Offset(x, roadY + 30), color: AppColors.time, bold: true, size: 12);
      }
    }
    final x = l + t * (r - l);
    drawVehicleAt(c, Offset(x, roadY - 18), 62, VehicleType.car, turn: t * 20);
    drawLabel(c, '🚗 60 km/jam', const Offset(14, 14), anchor: Offset.zero, color: AppColors.speed, bold: true, background: Colors.white);
    drawLabel(c, 'Waktu: ${fmtNum(hours, maxDecimals: 1)} jam   Jarak: ${fmtNum(hours * 60, maxDecimals: 0)} km',
        Offset(s.width - 14, 14),
        anchor: const Offset(1, 0), size: 12, bold: true, background: Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MarkersPainter old) => old.t != t;
}

// ───────────── A06 Pita jarak berpapasan ─────────────

class HeadOnAnimation extends StatelessWidget {
  final VoidCallback? onFinished;
  const HeadOnAnimation({super.key, this.onFinished});

  static final _scene = SceneData(
    type: SceneType.straight,
    lengthKm: 180,
    leftName: 'Kota Barat',
    rightName: 'Kota Timur',
    movers: [
      Mover(id: 'A', vehicle: VehicleType.car, startKm: 0, direction: 1, speedKmh: 50, departAt: ClockTime.hm(7, 0)),
      Mover(id: 'B', vehicle: VehicleType.bus, startKm: 180, direction: -1, speedKmh: 40, departAt: ClockTime.hm(7, 0)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AnimationPlayer(
      duration: const Duration(seconds: 10),
      checkpoints: const [0.5, 1.0],
      captions: const [
        '1 jam: A maju 50 km, B maju 40 km. Jaraknya berkurang 50 + 40 = 90 km.',
        '2 jam: 180 km habis. Berpapasan pukul 09.00! Waktu = 180 ÷ 90 = 2 jam.',
      ],
      onFinished: onFinished,
      builder: (_, t) {
        final clock = 420 + t * 120;
        final gap = 180 - 90 * (t * 2);
        return Column(
          children: [
            RoadSceneView(scene: _scene, clockMinutes: clock, showBand: true, height: 170),
            const SizedBox(height: 6),
            Text('Setiap jam jarak berkurang 90 km  •  sisa ${fmtNum(max(0, gap))} km',
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.distance)),
          ],
        );
      },
    );
  }
}

// ───────────── A07 Garis waktu menyusul ─────────────

class CatchUpAnimation extends StatelessWidget {
  final VoidCallback? onFinished;
  const CatchUpAnimation({super.key, this.onFinished});

  static final _bus = Mover(id: 'A', vehicle: VehicleType.bus, startKm: 0, direction: 1, speedKmh: 40, departAt: ClockTime.hm(7, 0));
  static final _moto = Mover(id: 'B', vehicle: VehicleType.motorbike, startKm: 0, direction: 1, speedKmh: 60, departAt: ClockTime.hm(7, 30));
  static final _scene = SceneData(
    type: SceneType.straight,
    lengthKm: 75,
    leftName: 'Terminal',
    rightName: '',
    movers: [_bus, _moto],
    showTimeline: true,
  );

  @override
  Widget build(BuildContext context) {
    return AnimationPlayer(
      duration: const Duration(seconds: 10),
      checkpoints: const [1 / 3, 2 / 3, 1.0],
      captions: const [
        'Pukul 07.30 motor baru berangkat. Bus sudah 40 × ½ = 20 km di depan.',
        'Motor mendekat 60 − 40 = 20 km tiap jam. Setengah jam lagi: tinggal 10 km.',
        'Pukul 08.30 motor menyusul bus di km 60. Waktu = 20 ÷ 20 = 1 jam setelah 07.30.',
      ],
      onFinished: onFinished,
      builder: (_, t) {
        final clock = 420 + t * 90;
        return Column(
          children: [
            RoadSceneView(scene: _scene, clockMinutes: clock, showBand: true, height: 170),
            const SizedBox(height: 4),
            TimelineView(
              from: ClockTime.hm(6, 50),
              to: ClockTime.hm(8, 40),
              nowMinutes: clock,
              marks: [
                TimelineMark('Bus', ClockTime.hm(7, 0), end: ClockTime.hm(7, 30)),
                TimelineMark('Motor', ClockTime.hm(7, 30)),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ───────────── A03 Tangga satuan ─────────────

class LadderAnimation extends StatelessWidget {
  final VoidCallback? onFinished;
  const LadderAnimation({super.key, this.onFinished});

  @override
  Widget build(BuildContext context) {
    return AnimationPlayer(
      duration: const Duration(seconds: 8),
      checkpoints: const [1 / 3, 2 / 3, 1.0],
      captions: const [
        'Turun 1 anak tangga: km → hm, dikali 10. 3 km = 30 hm.',
        'Turun lagi: hm → dam, dikali 10. 30 hm = 300 dam.',
        'Sampai m: 3 km = 3.000 m. Turun 3 tangga = dikali 1.000. Naik tangga = dibagi.',
      ],
      onFinished: onFinished,
      builder: (_, t) => SizedBox(height: 210, child: CustomPaint(painter: _LadderPainter(t), size: Size.infinite)),
    );
  }
}

class _LadderPainter extends CustomPainter {
  final double t;
  _LadderPainter(this.t);
  static const _units = ['km', 'hm', 'dam', 'm'];

  @override
  void paint(Canvas c, Size s) {
    final stepW = s.width / 4.4;
    final stepH = s.height / 5;
    Offset top(int i) => Offset(16 + i * stepW, 20 + i * stepH);
    for (var i = 0; i < 4; i++) {
      final o = top(i);
      final rect = Rect.fromLTWH(o.dx, o.dy + 40, stepW, s.height - o.dy - 40);
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()..color = Color.lerp(const Color(0xFFBFE6FF), AppColors.distance, i / 4)!);
      drawLabel(c, _units[i], rect.topCenter + const Offset(0, 18), bold: true, size: 18, color: Colors.white);
      if (i < 3) {
        drawLabel(c, '× 10', Offset(o.dx + stepW, o.dy + 30), color: AppColors.wrong, bold: true, size: 12);
      }
    }
    final pos = t * 3;
    final i0 = pos.floor().clamp(0, 3);
    final frac = pos - i0;
    final a = top(i0), b = top(min(3, i0 + 1));
    final hop = sin(frac * pi) * 26;
    final center = Offset.lerp(a, b, frac)! + Offset(stepW / 2, 18 - hop);
    final value = 3 * pow(10, pos.round());
    c.drawCircle(center, 22, Paint()..color = AppColors.taxi);
    drawLabel(c, fmtNum(value), center, bold: true, size: 14);
  }

  @override
  bool shouldRepaint(covariant _LadderPainter old) => old.t != t;
}

// ───────────── A05 km/jam → m/detik ─────────────

class KmhToMsAnimation extends StatelessWidget {
  final VoidCallback? onFinished;
  const KmhToMsAnimation({super.key, this.onFinished});

  @override
  Widget build(BuildContext context) {
    return AnimationPlayer(
      duration: const Duration(seconds: 9),
      checkpoints: const [1 / 3, 2 / 3, 1.0],
      captions: const [
        'Langkah 1: ubah km ke m. 72 km = 72 × 1.000 = 72.000 m.',
        'Langkah 2: ubah jam ke detik. 1 jam = 60 × 60 = 3.600 detik.',
        'Langkah 3: bagi. 72.000 m ÷ 3.600 detik = 20 m/detik.',
      ],
      startCaption: '72 km/jam = … m/detik? Tekan ▶.',
      onFinished: onFinished,
      builder: (_, t) {
        Widget panel(int i, String a, String b, Color color) {
          final shown = t >= (i + 1) / 3 - 0.01;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: shown ? 1 : 0.15,
            child: Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: color, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                title: Text(a, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(b, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
              ),
            ),
          );
        }

        return Column(
          children: [
            const Text('72 km/jam', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.speed)),
            panel(0, 'Bagian jarak: km → m', '72 × 1.000 = 72.000 m', AppColors.distance),
            panel(1, 'Bagian waktu: jam → detik', '1 jam = 3.600 detik', AppColors.time),
            panel(2, 'Bagi jarak dengan waktu', '72.000 ÷ 3.600 = 20 m/detik', AppColors.speed),
          ],
        );
      },
    );
  }
}

// ───────────── A04 Roda waktu (interaktif) ─────────────

class TimeWheel extends StatefulWidget {
  const TimeWheel({super.key});
  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  double _min = 90;

  @override
  Widget build(BuildContext context) {
    final h = _min / 60;
    return Column(
      children: [
        SizedBox(height: 170, child: CustomPaint(painter: _GearPainter(_min), size: Size.infinite)),
        Slider(
          value: _min,
          min: 0,
          max: 180,
          divisions: 36,
          label: '${_min.round()} menit',
          onChanged: (v) => setState(() => _min = v),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text('${_min.round()} menit ÷ 60 = ${fmtNum(h, maxDecimals: 3)} jam',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.time)),
                Text('${fmtNum(h, maxDecimals: 3)} jam × 60 = ${_min.round()} menit',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Menit → jam: angka jadi lebih kecil (bagi). Jam → menit: lebih besar (kali).',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GearPainter extends CustomPainter {
  final double minutes;
  _GearPainter(this.minutes);

  void _gear(Canvas c, Offset o, double r, double angle, Color color, String label, String value) {
    const teeth = 12;
    final path = Path();
    for (var i = 0; i < teeth * 2; i++) {
      final a = angle + i * pi / teeth;
      final rr = i.isEven ? r : r * 0.82;
      final p = o + Offset(cos(a), sin(a)) * rr;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    c.drawPath(path, Paint()..color = color);
    c.drawCircle(o, r * 0.55, Paint()..color = Colors.white);
    drawLabel(c, value, o - const Offset(0, 6), bold: true, size: 16, color: color);
    drawLabel(c, label, o + const Offset(0, 12), size: 11);
  }

  @override
  void paint(Canvas c, Size s) {
    final h = minutes / 60;
    _gear(c, Offset(s.width * 0.3, s.height / 2), 70, h * 2 * pi / 12, AppColors.time, 'jam', fmtNum(h, maxDecimals: 2));
    _gear(c, Offset(s.width * 0.72, s.height / 2), 50, -minutes * 2 * pi / 60, AppColors.clock, 'menit', '${minutes.round()}');
    drawLabel(c, '1 putaran besar = 60 putaran kecil', Offset(s.width / 2, s.height - 6), anchor: const Offset(0.5, 1), size: 11);
  }

  @override
  bool shouldRepaint(covariant _GearPainter old) => old.minutes != minutes;
}

// ───────────── A08 Pizza jam (interaktif) ─────────────

class PizzaClock extends StatefulWidget {
  const PizzaClock({super.key});
  @override
  State<PizzaClock> createState() => _PizzaClockState();
}

class _PizzaClockState extends State<PizzaClock> {
  double _min = 45;

  @override
  Widget build(BuildContext context) {
    final h = _min / 60;
    final frac = fractionLabel(h);
    return Column(
      children: [
        SizedBox(height: 150, child: CustomPaint(painter: _PizzaPainter(_min), size: Size.infinite)),
        Slider(
          value: _min,
          min: 5,
          max: 120,
          divisions: 23,
          label: '${_min.round()} menit',
          onChanged: (v) => setState(() => _min = v),
        ),
        Text('${_min.round()} menit = ${_min.round()}/60 jam${frac != null ? ' = $frac jam' : ''} = ${fmtNum(h, maxDecimals: 3)} jam',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.time)),
        const SizedBox(height: 6),
        const Text('Coba geser ke 15, 30, dan 45 menit.', style: TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _PizzaPainter extends CustomPainter {
  final double minutes;
  _PizzaPainter(this.minutes);

  @override
  void paint(Canvas c, Size s) {
    final r = min(60.0, s.height / 2 - 6);
    final n = (minutes / 60).ceil().clamp(1, 2);
    for (var i = 0; i < 2; i++) {
      final o = Offset(s.width / 2 + (i - 0.5) * (r * 2 + 20), s.height / 2);
      c.drawCircle(o, r, Paint()..color = const Color(0xFFF5E6C8));
      final filled = (minutes - i * 60).clamp(0, 60) / 60;
      if (filled > 0) {
        c.drawArc(Rect.fromCircle(center: o, radius: r), -pi / 2, filled * 2 * pi, true, Paint()..color = AppColors.speed);
        for (var k = 0; k < 6; k++) {
          final a = -pi / 2 + (k + 0.5) / 6 * filled * 2 * pi;
          c.drawCircle(o + Offset(cos(a), sin(a)) * r * 0.6, 6, Paint()..color = AppColors.wrong);
        }
      }
      for (var q = 0; q < 4; q++) {
        final a = -pi / 2 + q * pi / 2;
        c.drawLine(o, o + Offset(cos(a), sin(a)) * r, Paint()
          ..color = Colors.brown.withValues(alpha: 0.4)
          ..strokeWidth = 2);
      }
      c.drawCircle(o, r, Paint()
        ..color = Colors.brown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      drawLabel(c, 'jam ke-${i + 1}', o + Offset(0, r + 2), size: 10, anchor: const Offset(0.5, 0));
      if (i + 1 >= n && minutes <= 60) break;
    }
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter old) => old.minutes != minutes;
}

// ───────────── Selisih waktu (interaktif) ─────────────

class ClockGap extends StatefulWidget {
  const ClockGap({super.key});
  @override
  State<ClockGap> createState() => _ClockGapState();
}

class _ClockGapState extends State<ClockGap> {
  ClockTime _a = ClockTime.hm(7, 15);
  ClockTime _b = ClockTime.hm(8, 0);

  Widget _picker(String label, ClockTime v, ValueChanged<ClockTime> on) => Column(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(onPressed: () => on(v.plusMinutes(-5)), icon: const Icon(Icons.remove_circle_outline)),
              Text(v.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.clock)),
              IconButton(onPressed: () => on(v.plusMinutes(5)), icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final d = _a.minutesUntil(_b);
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          spacing: 12,
          children: [
            _picker('Berangkat', _a, (v) => setState(() => _a = v)),
            _picker('Tiba', _b, (v) => setState(() => _b = v)),
          ],
        ),
        const SizedBox(height: 8),
        if (d > 0)
          TimelineView(
            from: _a.plusMinutes(-15),
            to: _b.plusMinutes(15),
            marks: [TimelineMark('Perjalanan', _a, end: _b)],
          ),
        const SizedBox(height: 8),
        Text(
          d > 0
              ? 'Pukul ${_a.label} sampai ${_b.label} = $d menit${d >= 60 ? ' = ${d ~/ 60} jam ${d % 60} menit' : ''}'
              : 'Jam tiba harus setelah jam berangkat.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.time),
        ),
        const SizedBox(height: 4),
        const Text('Ingat: pukul (jam) berbeda dengan lama perjalanan.', style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
