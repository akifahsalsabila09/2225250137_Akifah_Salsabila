import 'package:flutter_test/flutter_test.dart';
import 'package:kotalaju/core/domain/adaptive.dart';
import 'package:kotalaju/core/domain/clock.dart';
import 'package:kotalaju/core/domain/drills.dart';
import 'package:kotalaju/core/domain/format.dart';
import 'package:kotalaju/core/domain/motion.dart';
import 'package:kotalaju/core/domain/problem.dart';
import 'package:kotalaju/core/domain/problem_bank.dart';
import 'package:kotalaju/core/domain/scorer.dart';
import 'package:kotalaju/core/domain/units.dart';

int subIndex(Problem p, bool Function(SubQuestion) where) => p.subs.indexWhere(where);

void main() {
  group('format', () {
    test('angka gaya Indonesia', () {
      expect(fmtNum(0.75), '0,75');
      expect(fmtNum(72000), '72.000');
      expect(fmtNum(3), '3');
      expect(fmtNum(1.5), '1,5');
    });
    test('parsing', () {
      expect(parseNum('0,75'), 0.75);
      expect(parseNum('0.75'), 0.75);
      expect(parseNum('3/4'), 0.75);
      expect(parseNum('1 1/2'), 1.5);
      expect(parseNum('72.000'), 72000);
      expect(parseNum('0.750'), 0.75);
      expect(parseNum('abc'), isNull);
    });
    test('jam', () {
      expect(ClockTime.parse('07.30')!.minutes, 450);
      expect(ClockTime.parse('7:05')!.label, '07.05');
      expect(ClockTime.hm(7, 0).plusHours(1.5).label, '08.30');
    });
  });

  group('UnitEngine', () {
    test('konversi dasar', () {
      expect(Quantity(45, Unit.min).to(Unit.h).value, closeTo(0.75, 1e-9));
      expect(Quantity(2, Unit.h).to(Unit.min).value, closeTo(120, 1e-9));
      expect(Quantity(72, Unit.kmPerH).to(Unit.mPerS).value, closeTo(20, 1e-9));
      expect(Quantity(20, Unit.mPerS).to(Unit.kmPerH).value, closeTo(72, 1e-9));
      expect(Quantity(3, Unit.km).to(Unit.m).value, closeTo(3000, 1e-9));
    });
    test('langkah km/jam → m/detik ditampilkan terpisah (EL04)', () {
      final steps = UnitEngine.explain(Quantity(72, Unit.kmPerH), Unit.mPerS);
      expect(steps.length, 2);
      expect(steps.last.result!.value, closeTo(20, 1e-9));
    });
    test('pola kesalahan', () {
      expect(UnitEngine.wrongDirection(Quantity(45, Unit.min), Unit.h), closeTo(2700, 1e-9));
      expect(UnitEngine.base100(Quantity(45, Unit.min), Unit.h), closeTo(0.45, 1e-9));
    });
  });

  group('MotionSimulator', () {
    test('berpapasan 180 km, 50 & 40 km/jam → 2 jam', () {
      final a = Mover(id: 'A', vehicle: VehicleType.car, startKm: 0, direction: 1, speedKmh: 50, departAt: ClockTime.hm(7, 0));
      final b = Mover(id: 'B', vehicle: VehicleType.bus, startKm: 180, direction: -1, speedKmh: 40, departAt: ClockTime.hm(7, 0));
      final m = MotionSimulator.meeting(a, b)!;
      expect(m.clock.label, '09.00');
      expect(m.positionKm, closeTo(100, 1e-9));
      expect(m.relativeSpeedKmh, 90);
      expect(m.type, MeetingType.headOn);
    });
    test('menyusul: bus 40 (07.00), motor 60 (07.30) → 08.30 di km 60', () {
      final a = Mover(id: 'A', vehicle: VehicleType.bus, startKm: 0, direction: 1, speedKmh: 40, departAt: ClockTime.hm(7, 0));
      final b = Mover(id: 'B', vehicle: VehicleType.motorbike, startKm: 0, direction: 1, speedKmh: 60, departAt: ClockTime.hm(7, 30));
      final m = MotionSimulator.meeting(a, b)!;
      expect(m.clock.label, '08.30');
      expect(m.positionKm, closeTo(60, 1e-9));
      expect(m.type, MeetingType.catchUp);
    });
    test('tidak pernah menyusul bila lebih lambat', () {
      final a = Mover(id: 'A', vehicle: VehicleType.bus, startKm: 0, direction: 1, speedKmh: 60, departAt: ClockTime.hm(7, 0));
      final b = Mover(id: 'B', vehicle: VehicleType.bicycle, startKm: 0, direction: 1, speedKmh: 20, departAt: ClockTime.hm(7, 30));
      expect(MotionSimulator.meeting(a, b), isNull);
    });
  });

  group('Contoh kisi-kisi Mathematical Literacy', () {
    test('No.1 Dina (Reasoning): Rute B, 24 menit', () {
      final p = buildRouteChoice(s: 6, vA: 12, vB: 15, deadline: 25);
      expect(p.maxScore, 6);
      expect(Scorer.scoreSub(p, 0, 30.0, {}).correct, isTrue);
      expect(Scorer.scoreSub(p, 1, 24.0, {}).correct, isTrue);
      final choice = p.subs[2] as ChoiceSub;
      expect(choice.options[choice.correct], 'Rute B');
      // menulis 0,5 (jam) di isian menit → satuan belum diubah
      expect(Scorer.scoreSub(p, 0, 0.5, {}).error, ErrorCode.unitNotConverted);
    });

    test('No.2 Bus museum (Formulating): 3 jam', () {
      final p = buildTravelTime(s: 150, v: 50);
      expect(p.maxScore, 6);
      final i = subIndex(p, (s) => s is NumericSub);
      expect(Scorer.scoreSub(p, i, 3.0, {}).correct, isTrue);
      final f = p.subs[0] as ChoiceSub;
      expect(f.options[f.correct], 'Waktu = Jarak ÷ Kecepatan');
    });

    test('No.3 Andi (Employing): 1 jam, 10 km/jam', () {
      final p = buildTwoLeg(s1: 4, v1: 8, s2: 6, v2: 12);
      expect(p.maxScore, 6);
      expect(Scorer.scoreSub(p, 0, 0.5, {}).correct, isTrue);
      expect(Scorer.scoreSub(p, 1, 0.5, {}).correct, isTrue);
      expect(Scorer.scoreSub(p, 2, 1.0, {'s0': 0.5, 's1': 0.5}).correct, isTrue);
      expect(Scorer.scoreSub(p, 3, 10.0, {'s2': 1.0}).correct, isTrue);
    });

    test('No.4 Budi (Interpreting): 40 ÷ 120 terdiagnosis pembagian terbalik', () {
      final p = buildCheckInverted(s: 120, v: 40);
      expect(p.maxScore, 6);
      final r = Scorer.scoreSub(p, 1, 40 / 120, {});
      expect(r.correct, isFalse);
      expect(r.error, ErrorCode.formulaInverted);
      expect(Scorer.scoreSub(p, 1, 3.0, {}).correct, isTrue);
      expect(Scorer.scoreSub(p, 2, 180.0, {'s1': 3}).correct, isTrue);
    });
  });

  group('Kesalahan khas dari wawancara', () {
    test('IL01: 45 menit = 0,45 jam → basis 100', () {
      final p = buildSpeed(s: 9, timeValue: 45, timeUnit: Unit.min);
      expect(Scorer.scoreConversion(p, 0, 0.45).error, ErrorCode.unitBase100);
      expect(Scorer.scoreConversion(p, 0, 2700).error, ErrorCode.unitWrongDirection);
      expect(Scorer.scoreConversion(p, 0, 0.75).correct, isTrue);
    });

    test('Error carried forward: kecepatan benar berdasarkan konversi siswa yang salah', () {
      final p = buildSpeed(s: 9, timeValue: 45, timeUnit: Unit.min);
      final i = subIndex(p, (s) => s is NumericSub);
      final r = Scorer.scoreSub(p, i, 20.0, {'c0': 0.45});
      expect(r.correct, isTrue);
      expect(r.carried, isTrue);
    });

    test('IL04: berpapasan memakai selisih kecepatan', () {
      final p = buildHeadOn(s: 180, va: 50, vb: 40, depart: ClockTime.hm(7, 0));
      expect(Scorer.scoreSub(p, 0, 10.0, {}).error, ErrorCode.relativeSpeedWrongOp);
      expect(Scorer.scoreSub(p, 0, 90.0, {}).correct, isTrue);
      expect(Scorer.scoreSub(p, 2, ClockTime.hm(9, 0), {'s1': 2}).correct, isTrue);
      expect(Scorer.scoreSub(p, 2, ClockTime.hm(2, 0), {'s1': 2}).error, ErrorCode.clockVsDuration);
    });

    test('IL05: menyusul dihitung dari jam bus berangkat', () {
      final p = buildCatchUp(vA: 40, vB: 60, c0: ClockTime.hm(7, 0), dMin: 30);
      expect(Scorer.scoreConversion(p, 0, 0.5).correct, isTrue);
      expect(Scorer.scoreSub(p, 0, 20.0, {'c0': 0.5}).correct, isTrue);
      expect(Scorer.scoreSub(p, 0, 1200.0, {'c0': 0.5}).error, ErrorCode.unitNotConverted);
      expect(Scorer.scoreSub(p, 1, 100.0, {}).error, ErrorCode.relativeSpeedWrongOp);
      expect(Scorer.scoreSub(p, 3, ClockTime.hm(8, 30), {'s2': 1}).correct, isTrue);
      expect(Scorer.scoreSub(p, 3, ClockTime.hm(8, 0), {'s2': 1}).error, ErrorCode.headStartIgnored);
    });

    test('K03/EL05: jam berangkat ditandai sebagai lama → CLOCK_VS_DURATION', () {
      final p = buildHeadOn(s: 180, va: 50, vb: 40, depart: ClockTime.hm(7, 0));
      final tags = {for (final t in p.tokens) t.id: t.kind};
      expect(Scorer.scoreTags(p, tags).correct, isTrue);
      tags['c'] = TagKind.duration;
      expect(Scorer.scoreTags(p, tags).error, ErrorCode.clockVsDuration);
    });
  });

  group('Bank soal', () {
    for (final t in ProblemBank.templates.values) {
      test('${t.id}: 100 instansi valid per level', () {
        for (var level = 1; level <= 3; level++) {
          for (var seed = 0; seed < 100; seed++) {
            final p = t.generate(level, seed);
            expect(p.maxScore, 6, reason: '${p.id} rubrik harus 6');
            expect(p.tokens, isNotEmpty);
            expect(p.askCorrect, inInclusiveRange(0, p.askOptions.length - 1));
            for (final sub in p.subs) {
              if (sub is NumericSub) {
                expect(sub.expected.isFinite && sub.expected > 0, isTrue, reason: '${p.id} ${sub.prompt}');
              }
            }
            // Kalimat soal ≤ 15 kata (agents.md §4).
            for (final sentence in p.story) {
              final text = sentence.map((s) => s.text).join();
              final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
              expect(words, lessThanOrEqualTo(15), reason: '${p.id}: "$text"');
            }
            // Info tak relevan hanya di level 3 dan indikator Formulating.
            if (p.tokens.any((tk) => tk.kind == TagKind.irrelevant)) {
              expect(level, 3);
              expect(p.indicator, Indicator.formulating);
            }
            // Pilihan Cek Logika yang benar selalu dinilai benar.
            expect(Scorer.scoreCheck(p, p.check.correct).correct, isTrue);
          }
        }
      });
    }

    test('drill konversi selalu punya jawaban benar di pilihan', () {
      for (var level = 1; level <= 3; level++) {
        for (var seed = 0; seed < 200; seed++) {
          final d = UnitDrill.generate(level, seed);
          expect(d.options.length, greaterThanOrEqualTo(2));
          expect(d.answer, closeTo(d.from.to(d.target).value, 1e-6));
        }
      }
    });
  });

  group('AdaptivePath', () {
    test('naik setelah 3 benar, turun setelah 2 salah', () {
      final a = AdaptivePath();
      for (var i = 0; i < 3; i++) {
        a.record(StepKind.unit, correct: true, hintLevelUsed: 0);
      }
      expect(a.levelFor(StepKind.unit), 2);
      a.record(StepKind.unit, correct: false, hintLevelUsed: 0);
      a.record(StepKind.unit, correct: false, hintLevelUsed: 0);
      expect(a.levelFor(StepKind.unit), 1);
      expect(a.levelFor(StepKind.compute), 1);
    });
    test('petunjuk tingkat 3 tidak menaikkan level', () {
      final a = AdaptivePath();
      for (var i = 0; i < 5; i++) {
        a.record(StepKind.read, correct: true, hintLevelUsed: 3);
      }
      expect(a.levelFor(StepKind.read), 1);
    });
  });
}
