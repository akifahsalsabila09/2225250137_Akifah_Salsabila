import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/format.dart';
import '../../core/domain/problem.dart';
import '../../core/widgets/common.dart';
import 'arena_screen.dart';

/// G5 Detektif Lalu Lintas (Interpreting): temukan langkah yang salah, tentukan jenisnya, perbaiki.
class TrafficDetectiveGame extends StatefulWidget {
  final int tier;
  const TrafficDetectiveGame({super.key, required this.tier});
  @override
  State<TrafficDetectiveGame> createState() => _TrafficDetectiveGameState();
}

class _Case {
  final String story;
  final List<String> steps;
  final int wrongStep;
  final ErrorCategory category;
  final double fix;
  final String fixUnit;
  final String explain;
  _Case(this.story, this.steps, this.wrongStep, this.category, this.fix, this.fixUnit, this.explain);
}

class _TrafficDetectiveGameState extends State<TrafficDetectiveGame> {
  final _rnd = Random();
  late final List<_Case> _cases = _makeCases();
  int _i = 0;
  int _stage = 0; // 0 pilih kartu, 1 pilih jenis, 2 perbaiki, 3 hasil
  int? _card;
  ErrorCategory? _cat;
  final _fix = TextEditingController();
  int _points = 0;
  final List<bool> _got = [false, false, false];

  List<_Case> _makeCases() {
    final list = <_Case>[_unitCase(), _invertedCase(), _relativeCase(), _arithmeticCase()]..shuffle(_rnd);
    return list;
  }

  T _p<T>(List<T> xs) => xs[_rnd.nextInt(xs.length)];

  _Case _unitCase() {
    final tMin = _p([20, 30, 45, 15]);
    final v = _p([12, 16, 20, 24]);
    final s = v * tMin / 60;
    final wrongH = widget.tier == 1 ? tMin / 100 : tMin * 60;
    return _Case(
      'Laporan: sepeda menempuh ${fmtNum(s)} km dalam $tMin menit. Berapa kecepatannya dalam km/jam?',
      [
        'Diketahui: jarak ${fmtNum(s)} km, waktu $tMin menit.',
        'Ubah ke jam: $tMin menit = ${fmtNum(wrongH, maxDecimals: 3)} jam.',
        'Kecepatan = jarak ÷ waktu.',
        'Kecepatan = ${fmtNum(s)} ÷ ${fmtNum(wrongH, maxDecimals: 3)} = ${fmtNum(s / wrongH, maxDecimals: 3)} km/jam.',
      ],
      1,
      ErrorCategory.unit,
      tMin / 60,
      'jam',
      '$tMin menit ÷ 60 = ${fmtNum(tMin / 60, maxDecimals: 3)} jam.',
    );
  }

  _Case _invertedCase() {
    final v = _p([40, 50, 60, 80]);
    final t = _p([2, 3, 4]);
    final s = v * t;
    return _Case(
      'Laporan: truk menempuh $s km dengan kecepatan $v km/jam. Berapa jam perjalanannya?',
      [
        'Diketahui: jarak $s km, kecepatan $v km/jam.',
        'Waktu = $v ÷ $s = ${fmtNum(v / s, maxDecimals: 3)} jam.',
        'Jadi truk butuh sekitar ${(v / s * 60).round()} menit.',
      ],
      1,
      ErrorCategory.formula,
      t.toDouble(),
      'jam',
      'Waktu = jarak ÷ kecepatan = $s ÷ $v = $t jam.',
    );
  }

  _Case _relativeCase() {
    final va = _p([40, 50, 60]);
    final vb = _p([30, 45, 70]);
    final t = _p([1, 2, 3]);
    final s = (va + vb) * t;
    return _Case(
      'Laporan: mobil A ($va km/jam) dan bus B ($vb km/jam) berangkat bersamaan dari dua kota berjarak $s km, saling mendekat.',
      [
        'Diketahui: jarak $s km, A $va km/jam, B $vb km/jam, berlawanan arah.',
        'Jarak berkurang ${(va - vb).abs()} km tiap jam (${max(va, vb)} − ${min(va, vb)}).',
        'Waktu bertemu = $s ÷ ${(va - vb).abs()} = ${fmtNum(s / (va - vb).abs(), maxDecimals: 2)} jam.',
      ],
      1,
      ErrorCategory.formula,
      (va + vb).toDouble(),
      'km/jam',
      'Berlawanan arah: kecepatan dijumlah. $va + $vb = ${va + vb} km/jam.',
    );
  }

  _Case _arithmeticCase() {
    final v = _p([45, 54, 36, 72]);
    final t = _p([1.5, 2.5, 0.5]);
    final s = v * t;
    final wrong = s + _p([5, 10, -5]);
    return _Case(
      'Laporan: kereta melaju $v km/jam selama ${fmtNum(t)} jam. Berapa jauh perjalanannya?',
      [
        'Diketahui: kecepatan $v km/jam, waktu ${fmtNum(t)} jam.',
        'Jarak = kecepatan × waktu.',
        'Jarak = $v × ${fmtNum(t)} = ${fmtNum(wrong)} km.',
      ],
      2,
      ErrorCategory.arithmetic,
      s,
      'km',
      '$v × ${fmtNum(t)} = ${fmtNum(s)} km.',
    );
  }

  @override
  void dispose() {
    _fix.dispose();
    super.dispose();
  }

  void _pickCard(int i) {
    final c = _cases[_i];
    _got[0] = i == c.wrongStep;
    if (_got[0]) AppScope.read(context).bump('detective_found');
    setState(() {
      _card = i;
      _stage = 1;
    });
  }

  void _pickCat(ErrorCategory cat) => setState(() {
        _cat = cat;
        _got[1] = cat == _cases[_i].category;
        _stage = 2;
      });

  void _submitFix() {
    final v = parseNum(_fix.text);
    if (v == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _got[2] = nearlyEqual(v, _cases[_i].fix);
      _points += _got.where((g) => g).length;
      _stage = 3;
    });
  }

  void _next() {
    if (_i == _cases.length - 1) {
      final stars = _points >= 11 ? 3 : _points >= 8 ? 2 : _points >= 5 ? 1 : 0;
      finishGame(context, gameId: 'traffic_detective', tier: widget.tier, stars: stars, details: {'points': _points});
      return;
    }
    setState(() {
      _i++;
      _stage = 0;
      _card = null;
      _cat = null;
      _fix.clear();
      _got.setAll(0, [false, false, false]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = _cases[_i];
    return CityBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('🔍 Detektif ${_i + 1}/${_cases.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFC69C6D), width: 3),
              ),
              child: Text('📁 ${c.story}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Text(_stage == 0 ? 'Ketuk kartu langkah yang SALAH:' : 'Kartu langkah:',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            for (var k = 0; k < c.steps.length; k++)
              Card(
                color: _card == k
                    ? (k == c.wrongStep ? const Color(0xFFDFF5E5) : const Color(0xFFFFE3E3))
                    : (_stage > 0 && k == c.wrongStep ? const Color(0xFFDFF5E5) : Colors.white),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${k + 1}')),
                  title: Text(c.steps[k], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  onTap: _stage == 0 ? () => _pickCard(k) : null,
                ),
              ),
            if (_stage >= 1) ...[
              const SizedBox(height: 8),
              Text(_got[0] ? '✅ Betul, langkah ${c.wrongStep + 1} salah!' : '🔎 Langkah yang salah adalah nomor ${c.wrongStep + 1}.',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Jenis kesalahannya apa?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in [ErrorCategory.unit, ErrorCategory.formula, ErrorCategory.reading, ErrorCategory.arithmetic])
                    ChoiceChip(
                      avatar: Icon(cat.icon, size: 18),
                      label: Text(cat.label),
                      selected: _cat == cat,
                      onSelected: _stage == 1 ? (_) => _pickCat(cat) : null,
                    ),
                ],
              ),
            ],
            if (_stage >= 2) ...[
              const SizedBox(height: 8),
              Text(_got[1] ? '✅ Jenisnya tepat.' : 'Jenis yang tepat: ${c.category.label}.',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Perbaiki angkanya:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              NumberField(controller: _fix, unitLabel: c.fixUnit, enabled: _stage == 2, color: AppColors.distance),
            ],
            if (_stage == 3) ...[
              const SizedBox(height: 10),
              FeedbackPanel(correct: _got[2], message: _got[2] ? 'Kasus terpecahkan! ${c.explain}' : 'Perbaikan yang benar: ${c.explain}'),
            ],
            const SizedBox(height: 14),
            if (_stage == 2) FilledButton(onPressed: _submitFix, child: const Text('Periksa perbaikan')),
            if (_stage == 3)
              FilledButton(onPressed: _next, child: Text(_i == _cases.length - 1 ? 'Lihat hasil' : 'Kasus berikutnya')),
          ],
        ),
      ),
    );
  }
}
