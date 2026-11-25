import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/domain/format.dart';
import '../../core/domain/motion.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paint_utils.dart';
import '../../core/widgets/vehicle.dart';
import 'arena_screen.dart';

/// G4 Pilih Rute Kurir (Reasoning): pilih rute dan alasannya, lalu lihat kurir berjalan.
class CourierRouteGame extends StatefulWidget {
  final int tier;
  const CourierRouteGame({super.key, required this.tier});
  @override
  State<CourierRouteGame> createState() => _CourierRouteGameState();
}

class _Route {
  final String name;
  final double km, kmh;
  const _Route(this.name, this.km, this.kmh);
  double get minutes => km / kmh * 60;
}

class _CRound {
  final List<_Route> routes;
  final int deadline;
  final int answer;
  final List<String> reasons;
  final int correctReason;
  _CRound(this.routes, this.deadline, this.answer, this.reasons, this.correctReason);
}

class _CourierRouteGameState extends State<CourierRouteGame> with SingleTickerProviderStateMixin {
  static const _rounds = 3;
  final _rnd = Random();
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 4))
    ..addListener(() => setState(() {}));
  int _round = 0;
  int _points = 0;
  late _CRound _r = _make();
  int? _route;
  int? _reason;
  bool _ran = false;

  _CRound _make() {
    const names = ['A', 'B', 'C'];
    final speeds = widget.tier == 1 ? [20.0, 30.0, 40.0, 60.0] : [15.0, 20.0, 24.0, 30.0, 36.0, 40.0, 45.0, 60.0];
    final kms = widget.tier == 1 ? [5.0, 10.0, 15.0, 20.0] : [4.0, 5.0, 6.0, 8.0, 9.0, 10.0, 12.0, 15.0, 18.0];
    for (var tries = 0; tries < 2000; tries++) {
      final rs = [
        for (var i = 0; i < 3; i++) _Route('Rute ${names[i]}', kms[_rnd.nextInt(kms.length)], speeds[_rnd.nextInt(speeds.length)]),
      ];
      if (rs.any((r) => (r.minutes - r.minutes.roundToDouble()).abs() > 1e-9)) continue;
      final times = rs.map((r) => r.minutes).toList()..sort();
      if (times[0] == times[1]) continue;
      final deadline = times[0].round() + _rnd.nextInt(max(1, (times[1] - times[0]).round()));
      if (deadline >= times[1]) continue;
      final ans = rs.indexWhere((r) => r.minutes == times[0]);
      final shortest = rs.indexWhere((r) => r.km == rs.map((x) => x.km).reduce(min));
      final fastest = rs.indexWhere((r) => r.kmh == rs.map((x) => x.kmh).reduce(max));
      if (widget.tier > 1 && (shortest == ans || fastest == ans)) continue;
      final win = rs[ans];
      final options = <(String, bool)>[
        ('${win.name}: ${fmtNum(win.km)} ÷ ${fmtNum(win.kmh)} jam = ${fmtNum(win.minutes)} menit, tidak lebih dari $deadline menit.', true),
        if (shortest != ans) ('${rs[shortest].name}, karena jaraknya paling pendek.', false),
        if (fastest != ans) ('${rs[fastest].name}, karena kecepatannya paling besar.', false),
        ('Semua rute pasti tepat waktu.', false),
      ];
      final opts = options.take(3).toList()..shuffle(_rnd);
      return _CRound(rs, deadline, ans, opts.map((o) => o.$1).toList(), opts.indexWhere((o) => o.$2));
    }
    final rs = [const _Route('Rute A', 5, 15), const _Route('Rute B', 15, 45), const _Route('Rute C', 9, 36)];
    return _CRound(rs, 18, 2, [
      'Rute C: 9 ÷ 36 jam = 15 menit, tidak lebih dari 18 menit.',
      'Rute A, karena jaraknya paling pendek.',
      'Rute B, karena kecepatannya paling besar.',
    ], 0);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _go() {
    if (_route == null || _reason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih rute dan alasannya dulu.')));
      return;
    }
    _points += (_route == _r.answer ? 1 : 0) + (_reason == _r.correctReason ? 1 : 0);
    setState(() => _ran = true);
    _anim.forward(from: 0);
  }

  void _next() {
    if (_round == _rounds - 1) {
      final stars = _points >= 6 ? 3 : _points >= 4 ? 2 : _points >= 2 ? 1 : 0;
      finishGame(context, gameId: 'courier_route', tier: widget.tier, stars: stars, details: {'points': _points});
      return;
    }
    setState(() {
      _round++;
      _r = _make();
      _route = null;
      _reason = null;
      _ran = false;
      _anim.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _route == null ? null : _r.routes[_route!];
    final elapsed = chosen == null ? 0.0 : _anim.value * chosen.minutes;
    final late = chosen != null && chosen.minutes > _r.deadline;
    return CityBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('📦 Rute Kurir ${_round + 1}/$_rounds', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Paket harus tiba dalam ${_r.deadline} menit. Pilih rute yang membuat paket tepat waktu.',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            Container(
              height: 200,
              decoration: BoxDecoration(color: const Color(0xFFEAF6E3), borderRadius: BorderRadius.circular(18)),
              child: CustomPaint(
                painter: _MapPainter(_r.routes, _route, _ran ? _anim.value : 0),
                size: Size.infinite,
              ),
            ),
            if (_ran)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('⏱ ${elapsed.round()} menit',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.time)),
              ),
            const SizedBox(height: 8),
            const Text('1. Pilih rute', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            for (var i = 0; i < _r.routes.length; i++)
              OptionTile(
                text: '${_r.routes[i].name}: ${fmtNum(_r.routes[i].km)} km • ${fmtNum(_r.routes[i].kmh)} km/jam',
                selected: _route == i,
                showCorrect: _ran ? i == _r.answer : null,
                onTap: _ran ? null : () => setState(() => _route = i),
              ),
            const SizedBox(height: 8),
            const Text('2. Pilih alasanmu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            for (var i = 0; i < _r.reasons.length; i++)
              OptionTile(
                text: _r.reasons[i],
                selected: _reason == i,
                showCorrect: _ran ? i == _r.correctReason : null,
                onTap: _ran ? null : () => setState(() => _reason = i),
              ),
            if (_ran && _anim.isCompleted) ...[
              const SizedBox(height: 8),
              FeedbackPanel(
                correct: !late,
                message: late
                    ? 'Terlambat ${(chosen.minutes - _r.deadline).round()} menit. Hitung waktu tiap rute: jarak ÷ kecepatan × 60.'
                    : 'Tepat waktu! Paket sampai dalam ${chosen!.minutes.round()} menit.',
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: !_ran ? _go : (_anim.isCompleted ? _next : null),
              child: Text(!_ran ? 'Antar paket! 🛵' : (_round == _rounds - 1 ? 'Lihat hasil' : 'Ronde berikutnya')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<_Route> routes;
  final int? chosen;
  final double progress;
  _MapPainter(this.routes, this.chosen, this.progress);

  @override
  void paint(Canvas c, Size s) {
    final a = Offset(40, s.height / 2), b = Offset(s.width - 40, s.height / 2);
    for (var i = 0; i < routes.length; i++) {
      final ctrl = Offset(s.width / 2, s.height / 2 + (i - 1) * s.height * 0.9);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy);
      c.drawPath(
          path,
          Paint()
            ..color = chosen == i ? const Color(0xFF3D3D3D) : const Color(0xFF7A7A7A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = chosen == i ? 20 : 14
            ..strokeCap = StrokeCap.round);
      final mid = Offset(s.width / 2, (a.dy + 2 * ctrl.dy + b.dy) / 4);
      final slow = routes[i].kmh <= 20;
      drawLabel(c, '${routes[i].name} ${slow ? '🐢' : '⚡'} ${fmtNum(routes[i].km)} km • ${fmtNum(routes[i].kmh)} km/jam', mid,
          size: 11, bold: true, color: AppColors.speed, background: Colors.white);
      if (chosen == i && progress > 0) {
        final t = progress;
        final p = Offset(
          (1 - t) * (1 - t) * a.dx + 2 * (1 - t) * t * ctrl.dx + t * t * b.dx,
          (1 - t) * (1 - t) * a.dy + 2 * (1 - t) * t * ctrl.dy + t * t * b.dy,
        );
        drawVehicleAt(c, p + const Offset(0, -12), 44, VehicleType.courier, turn: t * 30);
      }
    }
    drawPlace(c, a, 'Gudang');
    drawPlace(c, b, 'Rumah');
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
