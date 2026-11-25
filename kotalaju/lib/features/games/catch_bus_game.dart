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

/// G3 Kejar Bus Terakhir: atur kecepatan motor agar menyusul bus TEPAT di halte target.
class CatchBusGame extends StatefulWidget {
  final int tier;
  const CatchBusGame({super.key, required this.tier});
  @override
  State<CatchBusGame> createState() => _CatchBusGameState();
}

class _CatchRound {
  final double vBus, vNeeded, target;
  final int delayMin;
  final ClockTime c0;
  final List<double> stops;
  _CatchRound(this.vBus, this.vNeeded, this.target, this.delayMin, this.c0, this.stops);
}

class _CatchBusGameState extends State<CatchBusGame> with SingleTickerProviderStateMixin {
  static const _rounds = 3;
  final _rnd = Random();
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..addListener(() => setState(() {}));
  int _round = 0;
  int _tries = 0;
  int _points = 0;
  late _CatchRound _r = _make();
  late double _v = _r.vBus + 10;
  bool _ran = false;
  bool? _success;

  _CatchRound _make() {
    while (true) {
      final vBus = [30.0, 40.0, 50.0, 60.0][_rnd.nextInt(4)];
      final d = switch (widget.tier) { 1 => 60, 2 => 30, _ => [20, 40][_rnd.nextInt(2)] };
      final vM = vBus + 10.0 * (1 + _rnd.nextInt(4));
      final p = vBus * vM * d / 60 / (vM - vBus);
      if ((p - p.roundToDouble()).abs() > 1e-9 || p > 150 || p < 10) continue;
      return _CatchRound(vBus, vM, p, d, ClockTime.hm(7, 0), [p / 2, p, p * 1.5].map((x) => x.roundToDouble()).toList());
    }
  }

  Mover get _bus => Mover(id: 'Bus', vehicle: VehicleType.bus, startKm: 0, direction: 1, speedKmh: _r.vBus, departAt: _r.c0);
  Mover get _moto => Mover(
      id: 'Motor', vehicle: VehicleType.motorbike, startKm: 0, direction: 1, speedKmh: _v, departAt: _r.c0.plusMinutes(_r.delayMin));

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _go() {
    final m = MotionSimulator.meeting(_bus, _moto);
    final ok = m != null && (m.positionKm - _r.target).abs() < 0.5;
    _tries++;
    setState(() {
      _ran = true;
      _success = ok;
    });
    _anim.forward(from: 0);
  }

  void _retry() => setState(() {
        _ran = false;
        _success = null;
        _anim.reset();
      });

  void _next() {
    _points += _success == true ? max(1, 4 - _tries) : 0;
    if (_round == _rounds - 1) {
      final stars = _points >= 8 ? 3 : _points >= 5 ? 2 : _points >= 2 ? 1 : 0;
      finishGame(context, gameId: 'catch_bus', tier: widget.tier, stars: stars, details: {'points': _points});
      return;
    }
    setState(() {
      _round++;
      _r = _make();
      _v = _r.vBus + 10;
      _tries = 0;
      _ran = false;
      _success = null;
      _anim.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final length = _r.target * 1.8;
    final m = MotionSimulator.meeting(_bus, _moto);
    final endClock = (m?.clockMinutes ?? _r.c0.minutes + 180.0) + 10;
    final clock = _ran ? _r.c0.minutes + _anim.value * (endClock - _r.c0.minutes) : null;
    final scene = SceneData(
      type: SceneType.straight,
      lengthKm: length,
      leftName: 'Terminal',
      rightName: '',
      movers: [_bus, _moto],
      showTimeline: true,
    );
    final busAtTarget = _r.c0.plusHours(_r.target / _r.vBus);
    final failMsg = m == null
        ? 'Motor tidak pernah menyusul. Kecepatannya harus lebih besar dari bus.'
        : 'Motor menyusul di km ${fmtNum(m.positionKm)}, bukan di km ${fmtNum(_r.target)}. '
            '${m.positionKm < _r.target ? 'Terlalu cepat, kurangi kecepatan.' : 'Terlalu lambat, tambah kecepatan.'}';
    return CityBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('🚌 Kejar Bus ${_round + 1}/$_rounds', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Bus berangkat pukul ${_r.c0.label}, ${fmtNum(_r.vBus)} km/jam.\n'
                  'Motor berangkat ${_r.delayMin} menit kemudian dari terminal yang sama.\n'
                  'Atur kecepatan motor supaya menyusul bus TEPAT di 🚏 km ${fmtNum(_r.target)}.',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            LayoutBuilder(builder: (context, cons) {
              final w = cons.maxWidth;
              const margin = 34.0;
              return SizedBox(
                height: 190,
                child: Stack(
                  children: [
                    Positioned.fill(top: 26, child: RoadSceneView(scene: scene, clockMinutes: clock, height: 164)),
                    for (final st in _r.stops)
                      Positioned(
                        left: margin + st / length * (w - 2 * margin) - 22,
                        top: 0,
                        width: 44,
                        child: Column(children: [
                          Text('🚏', style: TextStyle(fontSize: st == _r.target ? 26 : 18)),
                          Text('${fmtNum(st)} km',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: st == _r.target ? AppColors.wrong : Colors.black54)),
                        ]),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text('Kecepatan motor: ${fmtNum(_v)} km/jam',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.speed)),
            Slider(
              value: _v,
              min: _r.vBus + 5,
              max: _r.vBus + 60,
              divisions: 11,
              label: '${fmtNum(_v)} km/jam',
              onChanged: _ran ? null : (v) => setState(() => _v = v),
            ),
            if (_tries >= 1 && _success != true)
              Card(
                color: const Color(0xFFFFF6D6),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    '💡 Bus tiba di km ${fmtNum(_r.target)} pukul ${busAtTarget.label}. '
                    'Motor berangkat pukul ${_r.c0.plusMinutes(_r.delayMin).label}. Berapa jam waktu motor? '
                    'Kecepatan = ${fmtNum(_r.target)} km ÷ waktu itu.',
                  ),
                ),
              ),
            if (_ran && _anim.isCompleted)
              FeedbackPanel(
                correct: _success == true,
                message: _success == true ? 'Tepat di halte! Motor ${fmtNum(_v)} km/jam menyusul di km ${fmtNum(_r.target)}.' : failMsg,
              ),
            const SizedBox(height: 10),
            if (!_ran)
              FilledButton(onPressed: _go, child: const Text('Jalan! 🏍️'))
            else if (_anim.isCompleted && _success != true && _tries < 3)
              FilledButton(onPressed: _retry, child: const Text('Coba kecepatan lain'))
            else if (_anim.isCompleted)
              FilledButton(onPressed: _next, child: Text(_round == _rounds - 1 ? 'Lihat hasil' : 'Ronde berikutnya')),
          ],
        ),
      ),
    );
  }
}
