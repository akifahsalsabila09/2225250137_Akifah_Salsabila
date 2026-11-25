import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/ride_world.dart';
import '../../core/domain/soal_koin.dart';
import '../../core/widgets/calculator_sheet.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/paint_utils.dart';
import '../../core/widgets/rider.dart';
import '../../core/widgets/tanya_sheet.dart';

/// Naik sepeda di jalan kota penuh rintangan. Setiap koin berisi satu soal (7 koin = 7 soal).
class RideScreen extends StatefulWidget {
  const RideScreen({super.key});
  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> with SingleTickerProviderStateMixin {
  final RideWorld _world = RideWorld(soalKoin.length);
  late final Ticker _ticker = createTicker(_tick);
  final _focus = FocusNode();
  Duration _last = Duration.zero;
  bool _started = false;
  bool _sheetOpen = false;
  final List<int?> _answers = List.filled(soalKoin.length, null);

  int get _score => [
        for (var i = 0; i < soalKoin.length; i++)
          if (_answers[i] == soalKoin[i].benar) i
      ].length;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    if (_sheetOpen) return;
    setState(() => _world.step(dt));
  }

  void _start() {
    setState(() {
      _started = true;
      _world.start();
    });
    _focus.requestFocus();
  }

  void _jump() {
    if (_world.jump()) setState(() {});
  }

  void _answer(int coin, int choice) {
    if (_answers[coin] != null) return;
    setState(() => _answers[coin] = choice);
  }

  void _continue() {
    setState(_world.continueRiding);
    _focus.requestFocus();
  }

  void _restart() => setState(() {
        _world.reset();
        _answers.fillRange(0, _answers.length, null);
        _started = false;
      });

  Future<void> _openSheet(Future<void> Function(BuildContext) show) async {
    setState(() => _sheetOpen = true);
    await show(context);
    if (!mounted) return;
    _last = Duration.zero;
    setState(() => _sheetOpen = false);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final skin = riderSkins[AppScope.of(context).riderSkin.clamp(0, riderSkins.length - 1)];
    final overlayOpen = !_started || _world.activeCoin != null || _world.finished;
    return Scaffold(
      backgroundColor: AppColors.sky,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is KeyDownEvent &&
              (e.logicalKey == LogicalKeyboardKey.space || e.logicalKey == LogicalKeyboardKey.arrowUp)) {
            _jump();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        // SizedBox.expand: Stack harus memenuhi layar, bukan hanya setinggi bar atas.
        child: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => _jump(),
                  child: CustomPaint(painter: _RoadPainter(world: _world, answers: _answers, skin: skin)),
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: _hud())),
              if (!overlayOpen) ...[
                Positioned(
                  right: 12,
                  top: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 64),
                      child: Column(children: [
                        _roundButton('🧮', 'Kalkulator', () => _openSheet(CalculatorSheet.show)),
                        const SizedBox(height: 10),
                        _roundButton('❓', 'Tanya Jawab', () => _openSheet(TanyaSheet.show)),
                      ]),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        width: 132,
                        height: 64,
                        child: FilledButton(
                          onPressed: _jump,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.taxi,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const FittedBox(
                            child: Text('LOMPAT ⬆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_world.distance < 500)
                  Positioned(
                    left: 16,
                    bottom: 0,
                    child: SafeArea(
                      child: IgnorePointer(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 170),
                          margin: const EdgeInsets.only(bottom: 30),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                          child: const Text('Ketuk layar untuk melompati rintangan!',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        ),
                      ),
                    ),
                  ),
              ],
              if (!_started) _startCard(),
              if (_world.activeCoin != null) _questionCard(_world.activeCoin!),
              if (_world.finished) _finishCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundButton(String icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child:
                SizedBox(width: 52, height: 52, child: Center(child: Text(icon, style: const TextStyle(fontSize: 24)))),
          ),
        ),
      );

  Widget _hud() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < soalKoin.length; i++)
                    Semantics(
                      label: 'Koin ${i + 1}${_answers[i] == null ? ', belum' : ', sudah diambil'}',
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _answers[i] == null ? Colors.white : const Color(0xFFF2B01E),
                          border: Border.all(color: const Color(0xFFC8890B), width: 2),
                        ),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _answers[i] == null ? const Color(0xFFC8890B) : Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('⭐ $_score', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _overlay({required Widget child, Alignment align = Alignment.center}) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        alignment: align,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(context).size.height * 0.88),
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.focusBg,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.taxi, width: 4),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _startCard() {
    final s = AppScope.of(context);
    return _overlay(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('KotaLaju', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text(
              'Gowes keliling kota! Lompati rintangan dan ambil 7 koin. Setiap koin berisi 1 soal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            const Text('Pilih karaktermu:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < riderSkins.length; i++)
                  Semantics(
                    button: true,
                    selected: s.riderSkin == i,
                    label: 'Karakter ${riderSkins[i].name}',
                    child: GestureDetector(
                      onTap: () => s.setRiderSkin(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 92,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: s.riderSkin == i ? const Color(0xFFFFF3C4) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: s.riderSkin == i ? AppColors.taxi : const Color(0xFFE0E0E0),
                            width: s.riderSkin == i ? 4 : 1.5,
                          ),
                        ),
                        child: Column(children: [
                          RiderView(skin: riderSkins[i], width: 72),
                          Text(riderSkins[i].name, style: const TextStyle(fontWeight: FontWeight.w900)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Ketuk layar atau tombol LOMPAT untuk melompat. Di komputer: tombol spasi.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            SizedBox(
                width: double.infinity, child: FilledButton(onPressed: _start, child: const Text('Mulai Gowes 🚲'))),
          ],
        ),
      ),
    );
  }

  Widget _questionCard(int i) {
    final q = soalKoin[i];
    final picked = _answers[i];
    final answered = picked != null;
    final correct = picked == q.benar;
    return _overlay(
      align: Alignment.bottomCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF2B01E)),
                child: Text('${q.no}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Koin ${q.no} dari ${soalKoin.length}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFFC8890B))),
              ),
              IconButton(
                tooltip: 'Kalkulator',
                onPressed: () => CalculatorSheet.show(context),
                icon: const Text('🧮', style: TextStyle(fontSize: 22)),
              ),
              IconButton(
                tooltip: 'Tanya Jawab',
                onPressed: () => TanyaSheet.show(context),
                icon: const Text('❓', style: TextStyle(fontSize: 22)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(q.pertanyaan, style: const TextStyle(fontSize: 17, height: 1.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            for (var k = 0; k < q.pilihan.length; k++)
              OptionTile(
                text: q.pilihan[k],
                selected: picked == k,
                showCorrect: answered ? k == q.benar : null,
                onTap: answered ? null : () => _answer(i, k),
              ),
            if (answered) ...[
              const SizedBox(height: 10),
              FeedbackPanel(
                correct: correct,
                message: correct ? 'Benar! Kamu dapat 1 bintang ⭐' : 'Belum tepat. Jawaban yang benar: ${q.jawaban}',
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pembahasan', style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    for (final line in q.pembahasan)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• $line', style: const TextStyle(fontSize: 15)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _continue,
                child: Text(i == soalKoin.length - 1 ? 'Gowes ke garis finish 🏁' : 'Lanjut gowes 🚲'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _finishCard() {
    final stars = _score >= 7
        ? 3
        : _score >= 5
            ? 2
            : _score >= 3
                ? 1
                : 0;
    return _overlay(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏁', style: TextStyle(fontSize: 54)),
            const Text('Sampai di garis finish!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Kamu menjawab benar $_score dari ${soalKoin.length} soal.', style: const TextStyle(fontSize: 17)),
            Text('Rintangan dilompati: ${_world.cleared} dari ${_world.obstacles.length}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            StarRow(stars: stars, size: 42),
            const SizedBox(height: 12),
            for (var i = 0; i < soalKoin.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [
                  Icon(_answers[i] == soalKoin[i].benar ? Icons.check_circle : Icons.cancel,
                      color: _answers[i] == soalKoin[i].benar ? AppColors.right : AppColors.wrong, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Koin ${i + 1}: ${soalKoin[i].judul}', style: const TextStyle(fontSize: 14))),
                ]),
              ),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity, child: FilledButton(onPressed: _restart, child: const Text('Main lagi 🔁'))),
          ],
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  final RideWorld world;
  final List<int?> answers;
  final RiderSkin skin;
  _RoadPainter({required this.world, required this.answers, required this.skin});

  static double _hash(int k) {
    final x = sin(k * 12.9898) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final distance = world.distance;
    final time = world.time;
    final roadTop = h * 0.64;
    final roadH = h * 0.22;
    final groundY = roadTop + roadH * 0.62;
    final bikeX = w * 0.25;

    // Langit & matahari
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6EC3F7), Color(0xFFD6F0FF)],
        ).createShader(Offset.zero & s),
    );
    c.drawCircle(Offset(w * 0.85, h * 0.2), 34, Paint()..color = const Color(0xFFFFE27A));

    // Awan
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 4; i++) {
      final x = ((i * 320 - distance * 0.08 - time * 6) % (w + 320)) - 160;
      final y = h * 0.16 + i * 30.0;
      c.drawCircle(Offset(x, y), 24, cloud);
      c.drawCircle(Offset(x + 24, y + 4), 18, cloud);
      c.drawCircle(Offset(x - 22, y + 6), 16, cloud);
    }

    // Gedung
    const bw = 70.0;
    final farShift = distance * 0.3;
    const colors = [Color(0xFFFFCC80), Color(0xFF90CAF9), Color(0xFFF48FB1), Color(0xFFA5D6A7)];
    for (var k = (farShift / bw).floor() - 1; k * bw - farShift < w + bw; k++) {
      final x = k * bw - farShift;
      final bh = 70 + _hash(k) * 120;
      final rect = Rect.fromLTWH(x + 4, roadTop - 30 - bh, bw - 8, bh);
      c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), Paint()..color = colors[k.abs() % 4]);
      final win = Paint()..color = Colors.white.withValues(alpha: 0.8);
      for (var wy = rect.top + 10; wy < rect.bottom - 14; wy += 18) {
        for (var wx = rect.left + 8; wx < rect.right - 12; wx += 16) {
          c.drawRect(Rect.fromLTWH(wx, wy, 8, 10), win);
        }
      }
    }

    // Rumput & trotoar
    c.drawRect(Rect.fromLTWH(0, roadTop - 30, w, 30), Paint()..color = const Color(0xFF8BC34A));
    c.drawRect(Rect.fromLTWH(0, roadTop - 8, w, 8), Paint()..color = const Color(0xFFBDBDBD));

    // Pohon & lampu jalan
    const tw = 230.0;
    final nearShift = distance * 0.9;
    for (var k = (nearShift / tw).floor() - 1; k * tw - nearShift < w + tw; k++) {
      final x = k * tw - nearShift + 40;
      if (k.isEven) {
        c.drawRect(Rect.fromLTWH(x - 4, roadTop - 60, 8, 40), Paint()..color = const Color(0xFF8D6E63));
        c.drawCircle(Offset(x, roadTop - 72), 26, Paint()..color = const Color(0xFF43A047));
        c.drawCircle(Offset(x - 14, roadTop - 60), 16, Paint()..color = const Color(0xFF66BB6A));
      } else {
        c.drawRect(Rect.fromLTWH(x - 2, roadTop - 90, 4, 82), Paint()..color = const Color(0xFF616161));
        c.drawCircle(Offset(x + 6, roadTop - 90), 7, Paint()..color = const Color(0xFFFFF59D));
      }
    }

    // Jalan
    c.drawRect(Rect.fromLTWH(0, roadTop, w, roadH), Paint()..color = const Color(0xFF555555));
    drawDashedLine(
      c,
      Offset(0, roadTop + roadH * 0.3),
      Offset(w, roadTop + roadH * 0.3),
      Paint()
        ..color = const Color(0xFFF2C94C)
        ..strokeWidth = 5,
      dash: 34,
      gap: 26,
      phase: distance,
    );
    c.drawRect(Rect.fromLTWH(0, roadTop + roadH, w, h - roadTop - roadH), Paint()..color = const Color(0xFF7CB342));

    // Rintangan
    for (final o in world.obstacles) {
      final x = bikeX + (o.x - distance);
      if (x < -60 || x > w + 60) continue;
      _drawObstacle(c, Offset(x, groundY), o);
    }

    // Koin
    for (var i = 0; i < answers.length; i++) {
      if (i < world.collected || answers[i] != null) continue;
      final x = bikeX + (world.coinX(i) - distance);
      if (x < -60 || x > w + 60) continue;
      final y = groundY - 110 + sin(time * 3 + i) * 6;
      final squash = max(0.25, cos(time * 2.4 + i).abs());
      c.save();
      c.translate(x, y);
      c.scale(squash, 1);
      c.drawCircle(Offset.zero, 24, Paint()..color = const Color(0xFFF2B01E));
      c.drawCircle(
          Offset.zero,
          24,
          Paint()
            ..color = const Color(0xFFC8890B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
      c.drawCircle(Offset.zero, 15, Paint()..color = const Color(0xFFFFD54F));
      if (squash > 0.5) drawLabel(c, '?', Offset.zero, color: const Color(0xFF8D5A00), bold: true, size: 20);
      c.restore();
      drawLabel(c, 'Soal ${i + 1}', Offset(x, y + 36),
          size: 11, bold: true, color: AppColors.ink, background: Colors.white);
    }

    // Garis finish
    final fx = bikeX + (world.finishX - distance) + 60;
    if (fx > -80 && fx < w + 80) {
      final check = Paint();
      for (var r = 0; r < 4; r++) {
        for (var col = 0; col < 2; col++) {
          check.color = (r + col).isEven ? Colors.white : Colors.black;
          c.drawRect(Rect.fromLTWH(fx - 10 + col * 10, roadTop + r * roadH / 4, 10, roadH / 4), check);
        }
      }
      c.drawRect(Rect.fromLTWH(fx - 3, roadTop - 110, 6, 110), Paint()..color = const Color(0xFF424242));
      drawLabel(c, 'FINISH', Offset(fx + 30, roadTop - 100),
          bold: true, size: 14, background: AppColors.wrong, color: Colors.white);
    }

    // Bayangan & pesepeda
    const scale = 1.15;
    final shadowW = 70 * scale * (1 - min(0.6, world.jumpH / 150));
    c.drawOval(Rect.fromCenter(center: Offset(bikeX, groundY + 2), width: shadowW, height: 8),
        Paint()..color = Colors.black.withValues(alpha: 0.25));
    final tilt = world.wobble > 0 ? sin(time * 40) * 0.18 * (world.wobble / 0.6) : (world.airborne ? -0.08 : 0.0);
    paintRider(
      c,
      Offset(bikeX, groundY - 17 * scale - world.jumpH),
      skin,
      crank: distance / 18,
      scale: scale,
      tilt: tilt,
    );
    if (world.wobble > 0) {
      drawLabel(c, 'Aduh! 💥', Offset(bikeX + 10, groundY - 130 - world.jumpH),
          bold: true, size: 16, color: AppColors.wrong, background: Colors.white);
    }
  }

  void _drawObstacle(Canvas c, Offset base, Obstacle o) {
    c.save();
    c.translate(base.dx, base.dy);
    if (o.hit && (o.type == ObstacleType.cone || o.type == ObstacleType.barrier)) {
      c.rotate(0.9); // terguling setelah ditabrak
    }
    switch (o.type) {
      case ObstacleType.cone:
        final path = Path()
          ..moveTo(-14, 0)
          ..lineTo(0, -34)
          ..lineTo(14, 0)
          ..close();
        c.drawPath(path, Paint()..color = const Color(0xFFFF7043));
        c.drawLine(
            const Offset(-8, -12),
            const Offset(8, -12),
            Paint()
              ..color = Colors.white
              ..strokeWidth = 4);
        c.drawRect(const Rect.fromLTWH(-18, -3, 36, 5), Paint()..color = const Color(0xFFE64A19));
      case ObstacleType.pothole:
        c.drawOval(Rect.fromCenter(center: const Offset(0, 2), width: 50, height: 14),
            Paint()..color = const Color(0xFF212121));
        c.drawOval(
            Rect.fromCenter(center: const Offset(0, 0), width: 50, height: 14),
            Paint()
              ..color = const Color(0xFF3E2723)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      case ObstacleType.rock:
        final path = Path()
          ..moveTo(-18, 0)
          ..quadraticBezierTo(-20, -18, -4, -26)
          ..quadraticBezierTo(14, -28, 18, -10)
          ..lineTo(18, 0)
          ..close();
        c.drawPath(path, Paint()..color = const Color(0xFF9E9E9E));
        c.drawCircle(const Offset(-3, -16), 4, Paint()..color = const Color(0xFFBDBDBD));
      case ObstacleType.puddle:
        c.drawOval(Rect.fromCenter(center: const Offset(0, 1), width: 56, height: 14),
            Paint()..color = const Color(0xFF4FC3F7));
        c.drawOval(Rect.fromCenter(center: const Offset(-8, -1), width: 16, height: 4),
            Paint()..color = Colors.white.withValues(alpha: 0.7));
      case ObstacleType.barrier:
        final leg = Paint()
          ..color = const Color(0xFF616161)
          ..strokeWidth = 4;
        c.drawLine(const Offset(-16, 0), const Offset(-16, -36), leg);
        c.drawLine(const Offset(16, 0), const Offset(16, -36), leg);
        c.drawRect(const Rect.fromLTWH(-24, -40, 48, 12), Paint()..color = Colors.white);
        for (var k = 0; k < 4; k++) {
          c.drawRect(Rect.fromLTWH(-24 + k * 12.0, -40, 6, 12), Paint()..color = const Color(0xFFE53935));
        }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _RoadPainter old) => true;
}
