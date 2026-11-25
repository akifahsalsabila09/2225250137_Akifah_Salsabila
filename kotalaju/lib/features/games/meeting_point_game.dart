import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/domain/clock.dart';
import '../../core/domain/format.dart';
import '../../core/domain/motion.dart';
import '../../core/domain/problem.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/road_scene.dart';
import 'arena_screen.dart';

/// G2 Tebak Titik Temu: tancapkan bendera dan tebak jam berpapasan, lalu buktikan dengan simulasi.
class MeetingPointGame extends StatefulWidget {
  final int tier;
  const MeetingPointGame({super.key, required this.tier});
  @override
  State<MeetingPointGame> createState() => _MeetingPointGameState();
}

class _Round {
  final SceneData scene;
  final MeetingResult meet;
  _Round(this.scene, this.meet);
}

class _MeetingPointGameState extends State<MeetingPointGame> with SingleTickerProviderStateMixin {
  static const _rounds = 3;
  final _rnd = Random();
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..addListener(() => setState(() {}));
  final _clockCtrl = TextEditingController();
  int _round = 0;
  late _Round _r = _make();
  double _flag = 0.5;
  bool _ran = false;
  int _points = 0;
  String? _result;

  _Round _make() {
    const speeds = [30, 40, 45, 50, 60, 70, 80];
    while (true) {
      final va = speeds[_rnd.nextInt(speeds.length)].toDouble();
      final vb = speeds[_rnd.nextInt(speeds.length)].toDouble();
      if (va == vb) continue;
      final t = switch (widget.tier) { 1 => [1.0, 2.0, 3.0], 2 => [0.5, 1.5, 2.5], _ => [1.0, 1.5, 2.0] }[_rnd.nextInt(3)];
      final delay = widget.tier == 3 ? 30 : 0;
      final depart = ClockTime.hm(6 + _rnd.nextInt(3), _rnd.nextBool() ? 0 : 30);
      // Tier 3: B berangkat 30 menit kemudian; A sudah berjalan va × 0,5 km.
      final s = (va + vb) * t + va * delay / 60;
      if (((s * 2) - (s * 2).roundToDouble()).abs() > 1e-9) continue;
      final a = Mover(id: 'A', vehicle: VehicleType.car, startKm: 0, direction: 1, speedKmh: va, departAt: depart);
      final b = Mover(id: 'B', vehicle: VehicleType.bus, startKm: s, direction: -1, speedKmh: vb, departAt: depart.plusMinutes(delay));
      final m = MotionSimulator.meeting(a, b)!;
      return _Round(
        SceneData(type: SceneType.straight, lengthKm: s, leftName: 'Kota A', rightName: 'Kota B', movers: [a, b]),
        m,
      );
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _clockCtrl.dispose();
    super.dispose();
  }

  void _go() {
    final guess = ClockTime.parse(_clockCtrl.text);
    if (guess == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tulis jam tebakanmu, contoh 08.30')));
      return;
    }
    FocusScope.of(context).unfocus();
    final clockOk = (guess.minutes - _r.meet.clockMinutes).abs() <= 1;
    final flagKm = _flag * _r.scene.lengthKm;
    final flagOk = (flagKm - _r.meet.positionKm).abs() <= _r.scene.lengthKm * 0.1;
    final pts = (clockOk ? 2 : 0) + (flagOk ? 1 : 0);
    _points += pts;
    final a = _r.scene.movers[0], b = _r.scene.movers[1];
    setState(() {
      _ran = true;
      _result = [
        clockOk ? '✅ Jamnya tepat: ${_r.meet.clock.label}!' : '❌ Mereka bertemu pukul ${_r.meet.clock.label}, bukan ${guess.label}.',
        flagOk ? '✅ Benderamu dekat titik temu.' : '📍 Titik temu di km ${fmtNum(_r.meet.positionKm)} dari Kota A.',
        if (!clockOk && b.departAt != a.departAt)
          'B berangkat ${b.departAt.minutes - a.departAt.minutes} menit kemudian. Saat itu A sudah ${fmtNum(a.speedKmh * (b.departAt.minutes - a.departAt.minutes) / 60)} km.',
        if (!clockOk) 'Jarak berkurang ${fmtNum(a.speedKmh)} + ${fmtNum(b.speedKmh)} = ${fmtNum(a.speedKmh + b.speedKmh)} km tiap jam.',
      ].join('\n');
    });
    _anim.forward(from: 0);
  }

  void _next() {
    if (_round == _rounds - 1) {
      final stars = _points >= 8 ? 3 : _points >= 6 ? 2 : _points >= 3 ? 1 : 0;
      finishGame(context, gameId: 'meeting_point', tier: widget.tier, stars: stars, details: {'points': _points});
      return;
    }
    setState(() {
      _round++;
      _r = _make();
      _ran = false;
      _result = null;
      _flag = 0.5;
      _clockCtrl.clear();
      _anim.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = _r.scene.movers[0], b = _r.scene.movers[1];
    final t0 = a.departAt.minutes.toDouble();
    final tEnd = _r.meet.clockMinutes + 10;
    final clock = _ran ? t0 + _anim.value * (tEnd - t0) : null;
    return CityBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('🚩 Tebak Titik Temu ${_round + 1}/$_rounds', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Mobil A dari Kota A pukul ${a.departAt.label}, ${fmtNum(a.speedKmh)} km/jam.\n'
                  'Bus B dari Kota B pukul ${b.departAt.label}, ${fmtNum(b.speedKmh)} km/jam.\n'
                  'Jarak kedua kota ${fmtNum(_r.scene.lengthKm)} km. Kapan dan di mana mereka bertemu?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(builder: (context, cons) {
              final w = cons.maxWidth;
              const margin = 34.0;
              final x = margin + _flag * (w - 2 * margin);
              return SizedBox(
                height: 190,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(top: 30, child: RoadSceneView(scene: _r.scene, clockMinutes: clock, height: 160)),
                    Positioned(
                      left: x - 22,
                      top: 0,
                      child: GestureDetector(
                        onHorizontalDragUpdate: _ran
                            ? null
                            : (d) => setState(() => _flag = (_flag + d.delta.dx / (w - 2 * margin)).clamp(0.0, 1.0)),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              color: Colors.white,
                              child: Text('km ${fmtNum(_flag * _r.scene.lengthKm, maxDecimals: 0)}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.distance)),
                            ),
                            const Text('🚩', style: TextStyle(fontSize: 30)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            const Text('Geser bendera 🚩 ke tempat mereka bertemu.', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            NumberField(
              controller: _clockCtrl,
              unitLabel: '',
              hint: 'Pukul berapa? contoh 08.30',
              color: AppColors.clock,
              enabled: !_ran,
              keyboard: TextInputType.datetime,
            ),
            const SizedBox(height: 12),
            if (_result != null && _anim.isCompleted) FeedbackPanel(correct: !_result!.contains('❌'), message: _result!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: !_ran ? _go : (_anim.isCompleted ? _next : null),
              child: Text(!_ran ? 'Jalan! 🚗💨' : (_round == _rounds - 1 ? 'Lihat hasil' : 'Ronde berikutnya')),
            ),
          ],
        ),
      ),
    );
  }
}
