import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/drills.dart';
import '../../core/domain/format.dart';
import '../../core/domain/motion.dart';
import '../../core/widgets/paint_utils.dart';
import '../../core/widgets/vehicle.dart';
import 'arena_screen.dart';

/// G1 Rally Satuan: pindah lajur ke gerbang konversi yang benar.
/// Salah → mobil berhenti dan langkah konversi ditampilkan (bukan game over).
class UnitRallyGame extends StatefulWidget {
  final int tier;
  const UnitRallyGame({super.key, required this.tier});
  @override
  State<UnitRallyGame> createState() => _UnitRallyGameState();
}

class _UnitRallyGameState extends State<UnitRallyGame> with SingleTickerProviderStateMixin {
  static const _total = 10;
  late final Ticker _ticker = createTicker(_tick);
  final _seed = Random().nextInt(1 << 30);
  Duration _last = Duration.zero;
  int _q = 0;
  int _lane = 1;
  double _gateY = -0.15;
  double _phase = 0;
  double _boost = 0;
  int _correct = 0;
  bool _started = false;
  bool _paused = false;
  bool _ended = false;
  late UnitDrill _drill = UnitDrill.generate(widget.tier, _seed);

  double get _gateSeconds => switch (widget.tier) { 1 => 7.5, 2 => 6.0, _ => 5.0 };

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (!_started || _paused || _ended) return;
    setState(() {
      _gateY += dt / _gateSeconds * (_boost > 0 ? 1.6 : 1);
      _phase += dt * (_boost > 0 ? 520 : 300);
      _boost = max(0, _boost - dt);
      if (_gateY >= 0.80) _evaluate();
    });
  }

  void _evaluate() {
    if (_lane == _drill.correct) {
      _correct++;
      _boost = 0.8;
      AppScope.read(context).bump('unit_correct', save: false);
      _nextQuestion();
    } else {
      _paused = true;
    }
  }

  void _nextQuestion() {
    _q++;
    if (_q >= _total) {
      _ended = true;
      final stars = _correct >= 9 ? 3 : _correct >= 7 ? 2 : _correct >= 5 ? 1 : 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) finishGame(context, gameId: 'unit_rally', tier: widget.tier, stars: stars, details: {'correct': _correct});
      });
      return;
    }
    _drill = UnitDrill.generate(widget.tier, _seed + _q);
    _gateY = -0.15;
  }

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _moveTo(int lane) => setState(() => _lane = lane.clamp(0, 2));

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final vType = s.profile?.vehicle ?? VehicleType.car;
    return Scaffold(
      backgroundColor: const Color(0xFF8BC34A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8BC34A),
        title: Text('🏎️ Rally Satuan • ${tierNames[widget.tier - 1]}', style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          Center(child: Text('${min(_q + 1, _total)}/$_total  ✅ $_correct  ', style: const TextStyle(fontWeight: FontWeight.w900))),
        ],
      ),
      body: LayoutBuilder(builder: (context, cons) {
        final w = cons.maxWidth, h = cons.maxHeight;
        final roadL = w * 0.08, roadR = w * 0.92;
        final laneW = (roadR - roadL) / 3;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _moveTo(((d.localPosition.dx - roadL) / laneW).floor()),
          onHorizontalDragEnd: (d) => _moveTo(_lane + ((d.primaryVelocity ?? 0) > 0 ? 1 : -1)),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _RallyPainter(
                    phase: _phase,
                    gateY: _gateY,
                    options: [for (final o in _drill.options) '${fmtNum(o, maxDecimals: 3)} ${_drill.target.label}'],
                    boost: _boost,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                left: roadL + laneW * _lane + laneW / 2 - 45,
                top: h * 0.80,
                child: Transform.rotate(
                  angle: -pi / 2,
                  child: VehicleView(type: vType, width: 90, color: Color(s.colorOf(vType)), wheelTurn: _phase / 50),
                ),
              ),
              Positioned(
                top: 10,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.ink, width: 3),
                  ),
                  child: Text(_drill.prompt,
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.time)),
                ),
              ),
              if (!_started) _overlay(
                title: 'Siap balapan?',
                body: 'Ketuk lajur (kiri, tengah, kanan) untuk pindah.\nMasuk ke gerbang dengan jawaban yang benar!',
                button: 'Mulai!',
                onTap: () => setState(() => _started = true),
              ),
              if (_paused) _overlay(
                title: 'Mobil berhenti sebentar',
                body: [
                  'Jawaban yang benar: ${fmtNum(_drill.answer, maxDecimals: 3)} ${_drill.target.label}',
                  if (_drill.wrongCodes[_lane] != null) _drill.wrongCodes[_lane]!.message,
                  ..._drill.explanation.map((e) => e.expression),
                ].join('\n\n'),
                button: 'Lanjut',
                onTap: () => setState(() {
                  _paused = false;
                  _nextQuestion();
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _overlay({required String title, required String body, required String button, required VoidCallback onTap}) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.focusBg, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              FilledButton(onPressed: onTap, child: Text(button)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RallyPainter extends CustomPainter {
  final double phase, gateY, boost;
  final List<String> options;
  _RallyPainter({required this.phase, required this.gateY, required this.options, required this.boost});

  @override
  void paint(Canvas c, Size s) {
    final l = s.width * 0.08, r = s.width * 0.92;
    c.drawRect(Rect.fromLTRB(l, 0, r, s.height), Paint()..color = const Color(0xFF555555));
    final edge = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    c.drawLine(Offset(l, 0), Offset(l, s.height), edge);
    c.drawLine(Offset(r, 0), Offset(r, s.height), edge);
    final laneW = (r - l) / 3;
    final dash = Paint()
      ..color = const Color(0xFFF2C94C)
      ..strokeWidth = 4;
    for (var i = 1; i < 3; i++) {
      final x = l + laneW * i;
      drawDashedLine(c, Offset(x, s.height), Offset(x, 0), dash, dash: 30, gap: 24, phase: phase);
    }
    // pohon di tepi jalan
    for (var k = 0; k < 6; k++) {
      final y = ((k * 140 + phase) % (s.height + 140)) - 70;
      for (final x in [l / 2, r + (s.width - r) / 2]) {
        c.drawCircle(Offset(x, y), 14, Paint()..color = const Color(0xFF2E7D32));
      }
    }
    if (boost > 0) {
      for (var k = 0; k < 8; k++) {
        final x = l + (k * 37 % (r - l));
        final y = (k * 97 + phase * 2) % s.height;
        c.drawLine(Offset(x, y), Offset(x, y + 40), Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..strokeWidth = 2);
      }
    }
    final gy = gateY * s.height;
    for (var i = 0; i < options.length; i++) {
      final rect = Rect.fromLTWH(l + laneW * i + 6, gy - 30, laneW - 12, 60);
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), Paint()..color = Colors.white);
      c.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(12)),
          Paint()
            ..color = AppColors.time
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
      drawLabel(c, options[i], rect.center, bold: true, size: 15, maxWidth: laneW - 16);
    }
  }

  @override
  bool shouldRepaint(covariant _RallyPainter old) => true;
}
