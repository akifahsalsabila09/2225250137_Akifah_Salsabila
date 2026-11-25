import 'dart:math';

import 'format.dart';
import 'problem.dart';
import 'units.dart';

/// Soal konversi satuan pilihan ganda (Bengkel Satuan, Rally Satuan).
class UnitDrill {
  final Quantity from;
  final Unit target;
  final List<double> options;
  final int correct;
  final Map<int, ErrorCode> wrongCodes;
  const UnitDrill(this.from, this.target, this.options, this.correct, this.wrongCodes);

  double get answer => options[correct];
  String get prompt => '${from.label} = … ${target.label}';
  List<ConversionStep> get explanation => UnitEngine.explain(from, target);

  static UnitDrill generate(int level, int seed) {
    final r = Random(seed);
    final (Quantity q, Unit t) = switch (level) {
      1 => _pick(r, [
          () => (Quantity((1 + r.nextInt(4)).toDouble(), Unit.h), Unit.min),
          () => (Quantity(60.0 * (1 + r.nextInt(3)), Unit.min), Unit.h),
          () => (Quantity((1 + r.nextInt(5)).toDouble(), Unit.km), Unit.m),
          () => (Quantity(1000.0 * (1 + r.nextInt(5)), Unit.m), Unit.km),
        ])(),
      2 => _pick(r, [
          () => (Quantity(_pick(r, [15.0, 30.0, 45.0, 90.0, 20.0]), Unit.min), Unit.h),
          () => (Quantity(_pick(r, [0.5, 1.5, 0.25, 0.75, 2.5]), Unit.h), Unit.min),
          () => (Quantity(_pick(r, [1.5, 2.5, 0.5, 0.25]), Unit.km), Unit.m),
          () => (Quantity(_pick(r, [500.0, 250.0, 1500.0, 750.0]), Unit.m), Unit.km),
        ])(),
      _ => _pick(r, [
          () => (Quantity(_pick(r, [18.0, 36.0, 54.0, 72.0, 90.0, 108.0]), Unit.kmPerH), Unit.mPerS),
          () => (Quantity(_pick(r, [5.0, 10.0, 15.0, 20.0, 25.0]), Unit.mPerS), Unit.kmPerH),
          () => (Quantity(_pick(r, [1.0, 2.0, 0.5]), Unit.h), Unit.s),
          () => (Quantity(_pick(r, [3, 4, 5]).toDouble() * 3, Unit.km), Unit.dam),
        ])(),
    };
    final ans = q.to(t).value;
    final cands = <(double, ErrorCode)>[
      (UnitEngine.wrongDirection(q, t), ErrorCode.unitWrongDirection),
      if (UnitEngine.base100(q, t) != null) (UnitEngine.base100(q, t)!, ErrorCode.unitBase100),
      (q.value, ErrorCode.unitNotConverted),
      (ans * 10, ErrorCode.arithmetic),
      (ans / 10, ErrorCode.arithmetic),
    ];
    final opts = <(double, ErrorCode?)>[(ans, null)];
    for (final c in cands) {
      if (opts.length >= 3) break;
      if (opts.any((o) => nearlyEqual(o.$1, c.$1))) continue;
      opts.add(c);
    }
    opts.shuffle(r);
    final codes = <int, ErrorCode>{};
    var ci = 0;
    for (var i = 0; i < opts.length; i++) {
      if (opts[i].$2 == null) {
        ci = i;
      } else {
        codes[i] = opts[i].$2!;
      }
    }
    return UnitDrill(q, t, [for (final o in opts) o.$1], ci, codes);
  }
}

T _pick<T>(Random r, List<T> xs) => xs[r.nextInt(xs.length)];

/// Soal prasyarat singkat (Menara Jam & diagnostik awal).
class QuickQuestion {
  final String prompt;
  final List<String> options;
  final int correct;
  final String explanation;
  const QuickQuestion(this.prompt, this.options, this.correct, this.explanation);
}

class Prerequisites {
  static List<QuickQuestion> pool() => const [
        QuickQuestion('45 menit = … jam', ['¾ jam', '0,45 jam', '4,5 jam'], 0, '45 ÷ 60 = ¾. Ingat 1 jam = 60 menit.'),
        QuickQuestion('Dari pukul 07.15 sampai 08.00 lamanya …', ['45 menit', '85 menit', '15 menit'], 0,
            '07.15 → 08.00: 45 menit.'),
        QuickQuestion('½ dalam desimal adalah …', ['0,2', '0,5', '1,2'], 1, '1 ÷ 2 = 0,5.'),
        QuickQuestion('30 menit = … jam', ['0,3 jam', '3 jam', '0,5 jam'], 2, '30 ÷ 60 = 0,5 jam.'),
        QuickQuestion('3 ÷ ¾ = …', ['4', '2¼', '¼'], 0, 'Membagi dengan ¾ sama dengan mengali 4/3. 3 × 4/3 = 4.'),
        QuickQuestion('1 jam 20 menit = … menit', ['120 menit', '80 menit', '20 menit'], 1, '60 + 20 = 80 menit.'),
        QuickQuestion('15 menit = … jam', ['¼ jam', '0,15 jam', '1,5 jam'], 0, '15 ÷ 60 = ¼ jam.'),
        QuickQuestion('Pukul 06.40 ditambah 35 menit menjadi pukul …', ['07.15', '06.75', '07.05'], 0,
            '06.40 + 20 menit = 07.00, sisa 15 menit → 07.15.'),
        QuickQuestion('¾ dalam desimal adalah …', ['0,34', '0,75', '7,5'], 1, '3 ÷ 4 = 0,75.'),
        QuickQuestion('1,5 jam = … menit', ['150 menit', '90 menit', '105 menit'], 1, '1,5 × 60 = 90 menit.'),
        QuickQuestion('Dari pukul 09.50 sampai 10.20 lamanya …', ['30 menit', '70 menit', '50 menit'], 0,
            '09.50 → 10.00 = 10 menit, lalu 20 menit lagi. Total 30 menit.'),
        QuickQuestion('6 ÷ 0,5 = …', ['3', '12', '0,3'], 1, 'Membagi dengan 0,5 sama dengan mengali 2.'),
      ];

  /// 6 soal diagnostik tetap (sama untuk semua siswa).
  static List<QuickQuestion> diagnostic() => pool().sublist(0, 6);

  static List<QuickQuestion> practice(int seed, int count) {
    final p = pool()..shuffle(Random(seed));
    return p.take(count).toList();
  }
}
