import 'dart:math';

import 'clock.dart';
import 'format.dart';
import 'motion.dart';
import 'problem.dart';
import 'units.dart';

// ─────────────────────────── helper ───────────────────────────

T _pick<T>(Random r, List<T> xs) => xs[r.nextInt(xs.length)];
String _km(num v) => '${fmtNum(v)} km';
String _kmh(num v) => '${fmtNum(v)} km/jam';
String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
bool _isInt(double v) => (v - v.roundToDouble()).abs() < 1e-9;
WrongPattern _wp(double v, ErrorCode c) => WrongPattern(v, c);

/// Pilihan ganda yang diacak; [correct] selalu ada, salah beserta kode kesalahannya.
ChoiceSub choice(String prompt, int points, String correct, List<(String, ErrorCode?)> wrongs, Random r) {
  final items = <(String, ErrorCode?, bool)>[
    (correct, null, true),
    for (final w in wrongs) (w.$1, w.$2, false),
  ]..shuffle(r);
  var ci = 0;
  final codes = <int, ErrorCode>{};
  for (var i = 0; i < items.length; i++) {
    if (items[i].$3) {
      ci = i;
    } else if (items[i].$2 != null) {
      codes[i] = items[i].$2!;
    }
  }
  return ChoiceSub(prompt, points, options: [for (final it in items) it.$1], correct: ci, wrongCodes: codes);
}

ChoiceSub formulaChoice(String focus, Random r) {
  switch (focus) {
    case 'waktu':
      return choice('Rumus mana yang dipakai?', 1, 'Waktu = Jarak ÷ Kecepatan', [
        ('Waktu = Kecepatan ÷ Jarak', ErrorCode.formulaInverted),
        ('Waktu = Jarak × Kecepatan', ErrorCode.formulaWrong),
      ], r);
    case 'kecepatan':
      return choice('Rumus mana yang dipakai?', 1, 'Kecepatan = Jarak ÷ Waktu', [
        ('Kecepatan = Waktu ÷ Jarak', ErrorCode.formulaInverted),
        ('Kecepatan = Jarak × Waktu', ErrorCode.formulaWrong),
      ], r);
    default:
      return choice('Rumus mana yang dipakai?', 1, 'Jarak = Kecepatan × Waktu', [
        ('Jarak = Kecepatan ÷ Waktu', ErrorCode.formulaWrong),
        ('Jarak = Waktu ÷ Kecepatan', ErrorCode.formulaInverted),
      ], r);
  }
}

class ProblemTemplate {
  final String id;
  final String title;
  final Indicator indicator;
  final Problem Function(int level, int seed) generate;
  const ProblemTemplate(this.id, this.title, this.indicator, this.generate);
}

class ProblemBank {
  static final Map<String, ProblemTemplate> templates = {
    'waktu_tempuh': ProblemTemplate('waktu_tempuh', 'Perjalanan ke Tujuan', Indicator.formulating, genTravelTime),
    'kecepatan': ProblemTemplate('kecepatan', 'Berapa Kecepatannya?', Indicator.employing, genSpeed),
    'jarak': ProblemTemplate('jarak', 'Berapa Jauh?', Indicator.employing, genDistance),
    'pilih_rute': ProblemTemplate('pilih_rute', 'Memilih Rute', Indicator.reasoning, genRoute),
    'dua_tahap': ProblemTemplate('dua_tahap', 'Perjalanan Dua Tahap', Indicator.employing, genTwoLeg),
    'periksa_hitungan': ProblemTemplate('periksa_hitungan', 'Periksa Hitungan', Indicator.interpreting, genCheckWork),
    'berpapasan': ProblemTemplate('berpapasan', 'Berpapasan', Indicator.formulating, genHeadOn),
    'menyusul': ProblemTemplate('menyusul', 'Menyusul', Indicator.employing, genCatchUp),
    'tepat_waktu': ProblemTemplate('tepat_waktu', 'Tepat Waktu?', Indicator.reasoning, genOnTime),
  };

  static Problem generate(String id, {required int level, required int seed}) {
    final t = templates[id];
    if (t == null) throw ArgumentError('Templat tidak dikenal: $id');
    return t.generate(level.clamp(1, 3), seed);
  }

  static List<String> byIndicator(Indicator i) =>
      templates.values.where((t) => t.indicator == i).map((t) => t.id).toList();
}

// ─────────────────────── T1 Waktu tempuh (Formulating) ───────────────────────

class _TravelCtx {
  final VehicleType vehicle;
  final String name, short, from, to, d1, d2;
  final List<int> speeds;
  const _TravelCtx(this.vehicle, this.name, this.short, this.from, this.to, this.d1, this.d2, this.speeds);
}

const _travelCtx = [
  _TravelCtx(VehicleType.bus, 'Bus sekolah', 'Bus', 'sekolah', 'museum', '40 siswa', '3 guru', [40, 60, 80]),
  _TravelCtx(VehicleType.train, 'Kereta', 'Kereta', 'Stasiun Kota', 'Stasiun Bukit', '120 penumpang', '4 gerbong',
      [60, 80, 120]),
  _TravelCtx(VehicleType.truck, 'Truk sayur', 'Truk', 'kebun', 'pasar induk', '2 ton sayur', '2 sopir', [40, 48, 60]),
  _TravelCtx(VehicleType.car, 'Mobil Paman', 'Mobil', 'rumah', 'rumah Nenek', '4 penumpang', '2 koper', [40, 60, 80]),
];

Problem genTravelTime(int level, int seed) {
  final r = Random(seed);
  final ctx = r.nextInt(_travelCtx.length);
  final c = _travelCtx[ctx];
  final v = _pick(r, c.speeds).toDouble();
  final t = level == 1
      ? (2 + r.nextInt(3)).toDouble()
      : _pick(r, level == 2 ? [0.5, 1.5, 2.5] : [0.75, 1.25, 1.5, 2.25]);
  return buildTravelTime(s: v * t, v: v, level: level, seed: seed, ctx: ctx, distractor: level == 3);
}

Problem buildTravelTime({
  required double s,
  required double v,
  int level = 2,
  int seed = 0,
  int ctx = 0,
  bool distractor = false,
}) {
  final r = Random(seed ^ 0x51);
  final c = _travelCtx[ctx % _travelCtx.length];
  final t = s / v;
  return Problem(
    templateId: 'waktu_tempuh',
    seed: seed,
    level: level,
    indicator: Indicator.formulating,
    title: 'Perjalanan ke ${_cap(c.to)}',
    story: [
      [tx('${c.name} pergi dari ${c.from} ke ${c.to}.')],
      if (distractor)
        [
          tx('${c.short} membawa '),
          tk('x1', c.d1, TagKind.irrelevant),
          tx(' dan '),
          tk('x2', c.d2, TagKind.irrelevant),
          tx('.'),
        ],
      [tx('Jaraknya '), tk('s', _km(s), TagKind.distance), tx('.')],
      [tx('${c.short} melaju dengan kecepatan rata-rata '), tk('v', _kmh(v), TagKind.speed), tx('.')],
      [tx('${c.short} tidak berhenti selama perjalanan.')],
      [tx('Berapa jam '), gl('waktu tempuh'), tx(' perjalanannya?')],
    ],
    scene: SceneData(
      type: SceneType.single,
      lengthKm: s,
      leftName: _cap(c.from),
      rightName: _cap(c.to),
      movers: [
        Mover(id: 'A', vehicle: c.vehicle, startKm: 0, direction: 1, speedKmh: v, departAt: ClockTime.hm(7, 0)),
      ],
    ),
    readPoints: 1,
    askOptions: const ['Jarak (km)', 'Kecepatan (km/jam)', 'Lama perjalanan (jam)', 'Pukul berapa tiba'],
    askCorrect: 2,
    askPoints: 1,
    conversions: const [],
    unitNote: 'Jarak dalam km dan kecepatan dalam km/jam. Hasilnya langsung dalam jam.',
    unitPoints: 1,
    formulaFocus: 'waktu',
    subs: [
      formulaChoice('waktu', r),
      NumericSub('Waktu = ${fmtNum(s)} ÷ ${fmtNum(v)} = … jam', 1, expected: t, unit: Unit.h, wrongs: [
        _wp(v / s, ErrorCode.formulaInverted),
        _wp(s * v, ErrorCode.formulaWrong),
      ]),
    ],
    check: choice('Apakah hasilnya masuk akal?', 1,
        'Masuk akal. ${fmtNum(v)} × ${fmtNum(t)} = ${fmtNum(s)} km, sama dengan jaraknya.', [
      ('Tidak perlu dicek. Kalau rumusnya benar, pasti benar.', null),
      ('Makin cepat kendaraan, makin lama waktunya.', ErrorCode.formulaInverted),
    ], r),
    hints: {
      StepKind.compute: [
        'Yang dicari waktu. Tutup W di segitiga JKW. Apa yang tersisa?',
        'Waktu = jarak ÷ kecepatan = ${fmtNum(s)} ÷ ${fmtNum(v)}.',
      ],
    },
    solution: [
      'Diketahui: jarak = ${_km(s)}, kecepatan = ${_kmh(v)}.',
      if (distractor) 'Info "${c.d1}" dan "${c.d2}" tidak dipakai.',
      'Ditanya: waktu tempuh (jam).',
      'Satuan sudah sejalan: km dan km/jam.',
      'Waktu = jarak ÷ kecepatan = ${fmtNum(s)} ÷ ${fmtNum(v)} = ${fmtNum(t)} jam.',
      'Cek: ${fmtNum(v)} × ${fmtNum(t)} = ${fmtNum(s)} km. Masuk akal.',
    ],
  );
}

// ─────────────────────── T2 Kecepatan (Employing) ───────────────────────

class _MoveCtx {
  final VehicleType vehicle;
  final String short, opening;
  final List<int> speeds;
  const _MoveCtx(this.vehicle, this.short, this.opening, this.speeds);
}

const _speedCtx = [
  _MoveCtx(VehicleType.bicycle, 'Rani', 'Rani bersepeda ke perpustakaan kota.', [10, 12, 15, 16, 18, 20]),
  _MoveCtx(VehicleType.walk, 'Dimas', 'Dimas berjalan kaki ke sekolah.', [4, 5, 6]),
  _MoveCtx(VehicleType.motorbike, 'Pak Ojek', 'Pak Ojek mengantar penumpang ke pasar.', [30, 36, 40, 45, 48, 60]),
  _MoveCtx(VehicleType.car, 'Kak Lina', 'Kak Lina menyetir mobil ke kantor.', [40, 45, 48, 60, 72, 80]),
];

const _distCtx = [
  _MoveCtx(VehicleType.car, 'Ayah', 'Ayah menyetir mobil di jalan tol.', [60, 72, 80, 90]),
  _MoveCtx(VehicleType.bicycle, 'Sinta', 'Sinta bersepeda keliling taman kota.', [10, 12, 15, 18]),
  _MoveCtx(VehicleType.train, 'Kereta', 'Kereta komuter melaju antarstasiun.', [48, 60, 72, 80]),
  _MoveCtx(VehicleType.scooter, 'Kak Bimo', 'Kak Bimo naik skuter listrik ke kampus.', [12, 15, 18, 20]),
];

/// Memilih (waktu, kecepatan) agar jarak bilangan bulat.
(double tv, Unit tu, double v) _pickTimeSpeed(Random r, int level, List<int> speeds) {
  if (level == 1) {
    return ((1 + r.nextInt(3)).toDouble(), Unit.h, _pick(r, speeds).toDouble());
  }
  final opts = level == 2 ? [30, 45, 20, 15, 90] : [40, 75, 50, 36, 80];
  for (var i = 0; i < 200; i++) {
    final tMin = _pick(r, opts);
    final v = _pick(r, speeds);
    if ((v * tMin) % 60 == 0) return (tMin.toDouble(), Unit.min, v.toDouble());
  }
  return (30, Unit.min, speeds.firstWhere((v) => v.isEven, orElse: () => 12).toDouble());
}

Problem genSpeed(int level, int seed) {
  final r = Random(seed);
  final ctx = r.nextInt(_speedCtx.length);
  final (tv, tu, v) = _pickTimeSpeed(r, level, _speedCtx[ctx].speeds);
  final tH = tu == Unit.min ? tv / 60 : tv;
  return buildSpeed(s: v * tH, timeValue: tv, timeUnit: tu, level: level, seed: seed, ctx: ctx);
}

Problem buildSpeed({
  required double s,
  required double timeValue,
  required Unit timeUnit,
  int level = 2,
  int seed = 0,
  int ctx = 0,
}) {
  final r = Random(seed ^ 0x52);
  final c = _speedCtx[ctx % _speedCtx.length];
  final isMin = timeUnit == Unit.min;
  final tH = isMin ? timeValue / 60 : timeValue;
  final v = s / tH;
  return Problem(
    templateId: 'kecepatan',
    seed: seed,
    level: level,
    indicator: Indicator.employing,
    title: 'Kecepatan ${c.short}',
    story: [
      [tx(c.opening)],
      [tx('Jaraknya '), tk('s', _km(s), TagKind.distance), tx('.')],
      [tx('Waktu yang dibutuhkan '), tk('t', '${fmtNum(timeValue)} ${timeUnit.label}', TagKind.duration), tx('.')],
      [tx('Berapa '), gl('kecepatan rata-rata'), tx(' ${c.short} dalam km/jam?')],
    ],
    scene: SceneData(
      type: SceneType.single,
      lengthKm: s,
      leftName: 'Mulai',
      rightName: 'Tujuan',
      movers: [Mover(id: 'A', vehicle: c.vehicle, startKm: 0, direction: 1, speedKmh: v, departAt: ClockTime.hm(7, 0))],
    ),
    readPoints: 1,
    askOptions: const ['Jarak (km)', 'Kecepatan (km/jam)', 'Lama perjalanan', 'Pukul berapa tiba'],
    askCorrect: 1,
    askPoints: 1,
    conversions: [if (isMin) ConversionTask(Quantity(timeValue, Unit.min), Unit.h)],
    unitNote: isMin
        ? 'Waktu dalam menit, tetapi kecepatan diminta dalam km/jam. Ubah menit ke jam dulu.'
        : 'Jarak dalam km dan waktu dalam jam. Hasilnya langsung km/jam.',
    unitPoints: 1,
    formulaFocus: 'kecepatan',
    subs: [
      formulaChoice('kecepatan', r),
      NumericSub(
        isMin
            ? 'Kecepatan = jarak ÷ waktu (dalam jam) = … km/jam'
            : 'Kecepatan = ${fmtNum(s)} ÷ ${fmtNum(timeValue)} = … km/jam',
        1,
        expected: v,
        unit: Unit.kmPerH,
        wrongs: [
          if (isMin) _wp(s / timeValue, ErrorCode.unitNotConverted),
          if (isMin) _wp(s / (timeValue / 100), ErrorCode.unitBase100),
          _wp(tH / s, ErrorCode.formulaInverted),
          _wp(s * tH, ErrorCode.formulaWrong),
        ],
        ecf: isMin ? (g) => (g['c0'] ?? 0) > 0 ? s / g['c0']! : null : null,
      ),
    ],
    check: choice('Apakah hasilnya masuk akal?', 1,
        'Masuk akal. ${fmtNum(v)} km/jam × ${fmtNum(tH)} jam = ${fmtNum(s)} km.', [
      ('Kecepatan harus sama dengan jaraknya.', ErrorCode.formulaWrong),
      isMin
          ? ('Masuk akal. Kecepatannya ${fmtNum(s / timeValue)} km/jam.', ErrorCode.unitNotConverted)
          : ('Makin lama waktunya, makin besar kecepatannya.', ErrorCode.formulaInverted),
    ], r),
    hints: {
      if (isMin)
        StepKind.unit: [
          'Waktunya dalam menit. Kecepatan diminta dalam km/jam. Sudah sama?',
          '${fmtNum(timeValue)} menit ÷ 60 = … jam.',
        ],
      StepKind.compute: [
        'Yang dicari kecepatan. Tutup K di segitiga JKW.',
        'Kecepatan = jarak ÷ waktu. Pakai waktu dalam jam: ${fmtNum(s)} ÷ ${fmtNum(tH)}.',
      ],
    },
    solution: [
      'Diketahui: jarak = ${_km(s)}, waktu = ${fmtNum(timeValue)} ${timeUnit.label}.',
      'Ditanya: kecepatan rata-rata (km/jam).',
      if (isMin) 'Samakan satuan: ${fmtNum(timeValue)} menit ÷ 60 = ${fmtNum(tH, maxDecimals: 3)} jam.',
      if (!isMin) 'Satuan sudah sejalan: km dan jam.',
      'Kecepatan = jarak ÷ waktu = ${fmtNum(s)} ÷ ${fmtNum(tH, maxDecimals: 3)} = ${fmtNum(v)} km/jam.',
      'Cek: ${fmtNum(v)} × ${fmtNum(tH, maxDecimals: 3)} = ${fmtNum(s)} km. Masuk akal.',
    ],
  );
}

// ─────────────────────── T3 Jarak (Employing) ───────────────────────

Problem genDistance(int level, int seed) {
  final r = Random(seed);
  final ctx = r.nextInt(_distCtx.length);
  final (tv, tu, v) = _pickTimeSpeed(r, level, _distCtx[ctx].speeds);
  return buildDistance(v: v, timeValue: tv, timeUnit: tu, level: level, seed: seed, ctx: ctx);
}

Problem buildDistance({
  required double v,
  required double timeValue,
  required Unit timeUnit,
  int level = 2,
  int seed = 0,
  int ctx = 0,
}) {
  final r = Random(seed ^ 0x53);
  final c = _distCtx[ctx % _distCtx.length];
  final isMin = timeUnit == Unit.min;
  final tH = isMin ? timeValue / 60 : timeValue;
  final s = v * tH;
  return Problem(
    templateId: 'jarak',
    seed: seed,
    level: level,
    indicator: Indicator.employing,
    title: 'Seberapa Jauh?',
    story: [
      [tx(c.opening)],
      [tx('Kecepatan rata-ratanya '), tk('v', _kmh(v), TagKind.speed), tx('.')],
      [tx('Lama perjalanannya '), tk('t', '${fmtNum(timeValue)} ${timeUnit.label}', TagKind.duration), tx('.')],
      [tx('Berapa km '), gl('jarak'), tx(' yang ditempuh?')],
    ],
    scene: SceneData(
      type: SceneType.single,
      lengthKm: s,
      leftName: 'Mulai',
      rightName: '?',
      movers: [Mover(id: 'A', vehicle: c.vehicle, startKm: 0, direction: 1, speedKmh: v, departAt: ClockTime.hm(7, 0))],
    ),
    readPoints: 1,
    askOptions: const ['Jarak (km)', 'Kecepatan (km/jam)', 'Lama perjalanan', 'Pukul berapa tiba'],
    askCorrect: 0,
    askPoints: 1,
    conversions: [if (isMin) ConversionTask(Quantity(timeValue, Unit.min), Unit.h)],
    unitNote: isMin
        ? 'Kecepatan dalam km/jam, tetapi waktu dalam menit. Ubah menit ke jam dulu.'
        : 'Kecepatan dalam km/jam dan waktu dalam jam. Sudah sejalan.',
    unitPoints: 1,
    formulaFocus: 'jarak',
    subs: [
      formulaChoice('jarak', r),
      NumericSub(
        isMin ? 'Jarak = kecepatan × waktu (dalam jam) = … km' : 'Jarak = ${fmtNum(v)} × ${fmtNum(timeValue)} = … km',
        1,
        expected: s,
        unit: Unit.km,
        wrongs: [
          if (isMin) _wp(v * timeValue, ErrorCode.unitNotConverted),
          if (isMin) _wp(v * timeValue / 100, ErrorCode.unitBase100),
          _wp(v / tH, ErrorCode.formulaWrong),
          _wp(tH / v, ErrorCode.formulaInverted),
        ],
        ecf: isMin ? (g) => g['c0'] != null ? v * g['c0']! : null : null,
      ),
    ],
    check: choice('Apakah hasilnya masuk akal?', 1,
        'Masuk akal. Tiap 1 jam ${fmtNum(v)} km, jadi ${fmtNum(tH, maxDecimals: 3)} jam = ${fmtNum(s)} km.', [
      isMin
          ? ('Masuk akal. Jaraknya ${fmtNum(v * timeValue)} km.', ErrorCode.unitNotConverted)
          : ('Jarak harus lebih kecil dari kecepatannya.', ErrorCode.formulaWrong),
      ('Tidak perlu dicek. Kalau rumusnya benar, pasti benar.', null),
    ], r),
    hints: {
      if (isMin)
        StepKind.unit: [
          'Kecepatan per jam, waktu dalam menit. Sudah sama?',
          '${fmtNum(timeValue)} menit ÷ 60 = … jam.',
        ],
      StepKind.compute: [
        'Yang dicari jarak. Tutup J di segitiga JKW.',
        'Jarak = kecepatan × waktu = ${fmtNum(v)} × ${fmtNum(tH, maxDecimals: 3)}.',
      ],
    },
    solution: [
      'Diketahui: kecepatan = ${_kmh(v)}, waktu = ${fmtNum(timeValue)} ${timeUnit.label}.',
      'Ditanya: jarak (km).',
      if (isMin) 'Samakan satuan: ${fmtNum(timeValue)} menit ÷ 60 = ${fmtNum(tH, maxDecimals: 3)} jam.',
      if (!isMin) 'Satuan sudah sejalan: km/jam dan jam.',
      'Jarak = kecepatan × waktu = ${fmtNum(v)} × ${fmtNum(tH, maxDecimals: 3)} = ${fmtNum(s)} km.',
      'Cek: ${fmtNum(s)} ÷ ${fmtNum(v)} = ${fmtNum(tH, maxDecimals: 3)} jam. Cocok.',
    ],
  );
}

// ─────────────────────── T4 Pilih rute (Reasoning) ───────────────────────

class _RouteCtx {
  final VehicleType vehicle;
  final String name, dest;
  final List<int> speeds;
  final List<double> dists, distsL3;
  const _RouteCtx(this.vehicle, this.name, this.dest, this.speeds, this.dists, this.distsL3);
}

const _routeCtx = [
  _RouteCtx(VehicleType.bicycle, 'Dina', 'rumah temannya', [8, 10, 12, 15, 18, 20, 24], [3, 4, 5, 6, 8], [4.5, 7.5, 9]),
  _RouteCtx(VehicleType.motorbike, 'Raka', 'tempat les', [20, 24, 30, 36, 40, 45], [6, 8, 9, 10, 12], [7.5, 10.5, 13.5]),
  _RouteCtx(VehicleType.car, 'Bu Rina', 'kantor', [30, 36, 40, 45, 48, 60], [9, 10, 12, 15, 18], [13.5, 16.5, 22.5]),
];

Problem genRoute(int level, int seed) {
  final r = Random(seed);
  final ctx = r.nextInt(_routeCtx.length);
  final c = _routeCtx[ctx];
  for (var i = 0; i < 400; i++) {
    final s = _pick(r, level == 3 ? c.distsL3 : c.dists);
    final vA = _pick(r, c.speeds).toDouble();
    final vB = _pick(r, c.speeds).toDouble();
    if (vA == vB) continue;
    final tA = 60 * s / vA, tB = 60 * s / vB;
    if (!_isInt(tA) || !_isInt(tB) || (tA - tB).abs() < 4) continue;
    final lo = min(tA, tB).round(), hi = max(tA, tB).round();
    final deadline = lo + r.nextInt(hi - lo);
    return buildRouteChoice(s: s, vA: vA, vB: vB, deadline: deadline, level: level, seed: seed, ctx: ctx);
  }
  return buildRouteChoice(s: 6, vA: 12, vB: 15, deadline: 25, level: level, seed: seed, ctx: 0);
}

Problem buildRouteChoice({
  required double s,
  required double vA,
  required double vB,
  required int deadline,
  int level = 2,
  int seed = 0,
  int ctx = 0,
}) {
  final r = Random(seed ^ 0x54);
  final c = _routeCtx[ctx % _routeCtx.length];
  final tA = 60 * s / vA, tB = 60 * s / vB;
  final aWins = tA <= deadline;
  final win = aWins ? 'A' : 'B', lose = aWins ? 'B' : 'A';
  final tWin = aWins ? tA : tB;
  final ask = choice('Apa yang perlu kamu cari?', 1, 'Waktu tempuh tiap rute, lalu dibandingkan', [
    ('Jarak tiap rute', ErrorCode.misread),
    ('Kecepatan yang baru', ErrorCode.misread),
    ('Jam berangkat', ErrorCode.clockVsDuration),
  ], r);
  List<WrongPattern> wrongsFor(double v) => [
        _wp(s / v, ErrorCode.unitNotConverted),
        _wp(v / s * 60, ErrorCode.formulaInverted),
        _wp(s / v * 100, ErrorCode.unitBase100),
      ];
  return Problem(
    templateId: 'pilih_rute',
    seed: seed,
    level: level,
    indicator: Indicator.reasoning,
    title: 'Rute untuk ${c.name}',
    story: [
      [tx('${c.name} akan pergi ke ${c.dest}.')],
      [tx('Jaraknya '), tk('s', _km(s), TagKind.distance), tx('.')],
      [tx('Lewat Rute A, kecepatan rata-ratanya '), tk('va', _kmh(vA), TagKind.speed), tx('.')],
      [tx('Lewat Rute B, kecepatan rata-ratanya '), tk('vb', _kmh(vB), TagKind.speed), tx('.')],
      [tx('${c.name} harus tiba paling lama dalam '), tk('d', '$deadline menit', TagKind.duration), tx('.')],
      [tx('Rute mana yang sebaiknya dipilih?')],
    ],
    scene: SceneData(
      type: SceneType.routes,
      lengthKm: s,
      leftName: 'Berangkat',
      rightName: _cap(c.dest),
      routes: [RouteInfo('Rute A', s, vA), RouteInfo('Rute B', s, vB)],
      movers: [Mover(id: 'A', vehicle: c.vehicle, startKm: 0, direction: 1, speedKmh: vA, departAt: ClockTime.hm(7, 0))],
    ),
    readPoints: 1,
    askOptions: ask.options,
    askCorrect: ask.correct,
    askPoints: 1,
    conversions: const [],
    unitNote: 'Jarak ÷ kecepatan menghasilkan jam. Batas waktunya dalam menit, jadi ubah hasilnya ke menit (× 60).',
    unitPoints: 0,
    formulaFocus: 'waktu',
    subs: [
      NumericSub('Waktu Rute A = ${fmtNum(s)} ÷ ${fmtNum(vA)} jam = … menit', 1,
          expected: tA, unit: Unit.min, wrongs: wrongsFor(vA)),
      NumericSub('Waktu Rute B = ${fmtNum(s)} ÷ ${fmtNum(vB)} jam = … menit', 1,
          expected: tB, unit: Unit.min, wrongs: wrongsFor(vB)),
      choice('Rute mana yang dipilih?', 1, 'Rute $win', [('Rute $lose', ErrorCode.misread)], r),
    ],
    check: choice('Mengapa memilih rute itu?', 1,
        'Rute $win butuh ${fmtNum(tWin)} menit, tidak lebih dari $deadline menit.', [
      ('Rute $lose, karena lebih lambat jadi lebih aman.', null),
      ('Sama saja, karena jaraknya sama.', ErrorCode.misread),
    ], r),
    hints: {
      StepKind.compute: [
        'Hitung waktu tiap rute: waktu = jarak ÷ kecepatan.',
        'Hasilnya dalam jam. Kalikan 60 supaya menjadi menit, lalu bandingkan dengan $deadline menit.',
      ],
    },
    solution: [
      'Diketahui: jarak ${_km(s)}, Rute A ${_kmh(vA)}, Rute B ${_kmh(vB)}, batas $deadline menit.',
      'Ditanya: rute yang membuat ${c.name} tiba tepat waktu.',
      'Rute A: ${fmtNum(s)} ÷ ${fmtNum(vA)} = ${fmtNum(s / vA, maxDecimals: 3)} jam = ${fmtNum(tA)} menit.',
      'Rute B: ${fmtNum(s)} ÷ ${fmtNum(vB)} = ${fmtNum(s / vB, maxDecimals: 3)} jam = ${fmtNum(tB)} menit.',
      'Pilih Rute $win karena ${fmtNum(tWin)} menit tidak melebihi $deadline menit.',
    ],
  );
}

// ─────────────────────── T5 Dua tahap (Employing) ───────────────────────

class _LegCtx {
  final VehicleType vehicle;
  final String opening, from, to;
  final List<int> speeds;
  const _LegCtx(this.vehicle, this.opening, this.from, this.to, this.speeds);
}

const _legCtx = [
  _LegCtx(VehicleType.bicycle, 'Andi bersepeda dari rumah ke taman.', 'Rumah', 'Taman', [6, 8, 10, 12, 15, 16, 20]),
  _LegCtx(VehicleType.courier, 'Pak Kurir naik motor dari gudang ke toko.', 'Gudang', 'Toko', [20, 24, 30, 36, 40, 48, 60]),
];

Problem genTwoLeg(int level, int seed) {
  final r = Random(seed);
  final ctx = r.nextInt(_legCtx.length);
  final c = _legCtx[ctx];
  final times = level == 1 ? [0.5, 1.0] : [0.25, 0.5, 0.75, 1.0, 1.5];
  for (var i = 0; i < 400; i++) {
    final v1 = _pick(r, c.speeds).toDouble(), v2 = _pick(r, c.speeds).toDouble();
    if (v1 == v2) continue;
    final t1 = _pick(r, times), t2 = _pick(r, times);
    if (level > 1 && t1 == t2) continue;
    final s1 = v1 * t1, s2 = v2 * t2;
    if (!_isInt(s1 * 2) || !_isInt(s2 * 2)) continue;
    final avg = (s1 + s2) / (t1 + t2);
    if (!_isInt(avg * 100)) continue;
    return buildTwoLeg(s1: s1, v1: v1, s2: s2, v2: v2, level: level, seed: seed, ctx: ctx);
  }
  return buildTwoLeg(s1: 4, v1: 8, s2: 6, v2: 12, level: level, seed: seed, ctx: 0);
}

Problem buildTwoLeg({
  required double s1,
  required double v1,
  required double s2,
  required double v2,
  int level = 2,
  int seed = 0,
  int ctx = 0,
}) {
  final r = Random(seed ^ 0x55);
  final c = _legCtx[ctx % _legCtx.length];
  final t1 = s1 / v1, t2 = s2 / v2, total = t1 + t2;
  final avg = (s1 + s2) / total;
  final naive = (v1 + v2) / 2;
  final naiveDiffers = !nearlyEqual(naive, avg);
  final ask = choice('Apa yang ditanya?', 0, 'Total waktu, lalu kecepatan rata-rata', [
    ('Jarak sampai tempat istirahat', ErrorCode.misread),
    ('Kecepatan yang paling besar', ErrorCode.misread),
    ('Jam berangkat', ErrorCode.clockVsDuration),
  ], r);
  return Problem(
    templateId: 'dua_tahap',
    seed: seed,
    level: level,
    indicator: Indicator.employing,
    title: 'Perjalanan Dua Tahap',
    story: [
      [tx(c.opening)],
      [tx('Mula-mula ia menempuh '), tk('s1', _km(s1), TagKind.distance), tx(' dengan kecepatan '),
        tk('v1', _kmh(v1), TagKind.speed), tx('.')],
      [tx('Setelah istirahat, ia menempuh '), tk('s2', _km(s2), TagKind.distance), tx(' lagi.')],
      [tx('Kecepatannya kali ini '), tk('v2', _kmh(v2), TagKind.speed), tx('.')],
      [tx('Berapa total waktu perjalanannya?')],
      [tx('Berapa '), gl('kecepatan rata-rata'), tx(' seluruh perjalanannya?')],
    ],
    scene: SceneData(
      type: SceneType.legs,
      lengthKm: s1 + s2,
      leftName: c.from,
      rightName: c.to,
      legs: [LegInfo(s1, v1), LegInfo(s2, v2)],
      movers: [Mover(id: 'A', vehicle: c.vehicle, startKm: 0, direction: 1, speedKmh: v1, departAt: ClockTime.hm(7, 0))],
    ),
    readPoints: 1,
    askOptions: ask.options,
    askCorrect: ask.correct,
    askPoints: 0,
    conversions: const [],
    unitNote: 'Semua jarak dalam km dan kecepatan dalam km/jam. Waktu yang didapat dalam jam.',
    unitPoints: 0,
    formulaFocus: 'waktu',
    subs: [
      NumericSub('Waktu bagian 1 = ${fmtNum(s1)} ÷ ${fmtNum(v1)} = … jam', 1, expected: t1, unit: Unit.h, wrongs: [
        _wp(v1 / s1, ErrorCode.formulaInverted),
        _wp(s1 * v1, ErrorCode.formulaWrong),
      ]),
      NumericSub('Waktu bagian 2 = ${fmtNum(s2)} ÷ ${fmtNum(v2)} = … jam', 1, expected: t2, unit: Unit.h, wrongs: [
        _wp(v2 / s2, ErrorCode.formulaInverted),
        _wp(s2 * v2, ErrorCode.formulaWrong),
      ]),
      NumericSub('Total waktu = … jam', 1,
          expected: total,
          unit: Unit.h,
          ecf: (g) => g['s0'] != null && g['s1'] != null ? g['s0']! + g['s1']! : null),
      NumericSub('Kecepatan rata-rata = ${fmtNum(s1 + s2)} km ÷ total waktu = … km/jam', 1,
          expected: avg,
          unit: Unit.kmPerH,
          wrongs: [if (naiveDiffers) _wp(naive, ErrorCode.avgOfSpeeds)],
          ecf: (g) => (g['s2'] ?? 0) > 0 ? (s1 + s2) / g['s2']! : null),
    ],
    check: choice('Apakah hasilnya masuk akal?', 1,
        'Masuk akal. Rata-ratanya berada di antara ${fmtNum(v1)} dan ${fmtNum(v2)} km/jam.', [
      ('Rata-rata harus lebih besar dari kedua kecepatan.', ErrorCode.formulaWrong),
      naiveDiffers
          ? ('Rata-rata cukup (${fmtNum(v1)} + ${fmtNum(v2)}) ÷ 2.', ErrorCode.avgOfSpeeds)
          : ('Tidak perlu dicek. Kalau rumusnya benar, pasti benar.', null),
    ], r),
    hints: {
      StepKind.compute: [
        'Hitung waktu tiap bagian dulu, lalu jumlahkan.',
        'Kecepatan rata-rata = total jarak ÷ total waktu = ${fmtNum(s1 + s2)} ÷ ${fmtNum(total, maxDecimals: 3)}.',
      ],
    },
    solution: [
      'Bagian 1: ${fmtNum(s1)} ÷ ${fmtNum(v1)} = ${fmtNum(t1, maxDecimals: 3)} jam.',
      'Bagian 2: ${fmtNum(s2)} ÷ ${fmtNum(v2)} = ${fmtNum(t2, maxDecimals: 3)} jam.',
      'Total waktu = ${fmtNum(t1, maxDecimals: 3)} + ${fmtNum(t2, maxDecimals: 3)} = ${fmtNum(total, maxDecimals: 3)} jam.',
      'Total jarak = ${fmtNum(s1)} + ${fmtNum(s2)} = ${fmtNum(s1 + s2)} km.',
      'Kecepatan rata-rata = ${fmtNum(s1 + s2)} ÷ ${fmtNum(total, maxDecimals: 3)} = ${fmtNum(avg)} km/jam.',
    ],
  );
}

// ─────────────────────── T6 Periksa hitungan (Interpreting) ───────────────────────

const _chars = ['Budi', 'Rina', 'Dodi', 'Sari'];

Problem genCheckWork(int level, int seed) {
  final r = Random(seed);
  final ch = _pick(r, _chars);
  final useUnitVariant = level == 3 || (level == 2 && seed.isOdd);
  if (!useUnitVariant) {
    final v = _pick(r, [40, 50, 60]).toDouble();
    final t = level == 1 ? _pick(r, [2.0, 3.0, 4.0]) : _pick(r, [1.5, 2.5, 3.0]);
    return buildCheckInverted(s: v * t, v: v, character: ch, level: level, seed: seed);
  }
  for (var i = 0; i < 200; i++) {
    final tMin = _pick(r, [20, 30, 40, 45]);
    final v = _pick(r, [12, 15, 18]);
    if ((v * tMin) % 60 == 0) {
      return buildCheckUnits(s: v * tMin / 60, tMin: tMin.toDouble(), character: ch, level: level, seed: seed);
    }
  }
  return buildCheckUnits(s: 6, tMin: 30, character: ch, level: level, seed: seed);
}

Problem buildCheckInverted({
  required double s,
  required double v,
  String character = 'Budi',
  int level = 2,
  int seed = 0,
}) {
  final r = Random(seed ^ 0x56);
  final t = s / v;
  final wrongT = v / s;
  final m = (wrongT * 60).round();
  final ask = choice('Apa yang perlu kamu cari?', 1, 'Lama perjalanan bus yang benar', [
    ('Jarak Kota A ke Kota B', ErrorCode.misread),
    ('Kecepatan bus', ErrorCode.misread),
    ('Jam bus berangkat', ErrorCode.clockVsDuration),
  ], r);
  return Problem(
    templateId: 'periksa_hitungan',
    seed: seed,
    level: level,
    indicator: Indicator.interpreting,
    title: 'Periksa Hitungan $character',
    story: [
      [tx('Sebuah bus melaju dari Kota A ke Kota B.')],
      [tx('Jaraknya '), tk('s', _km(s), TagKind.distance), tx('.')],
      [tx('Kecepatan rata-ratanya '), tk('v', _kmh(v), TagKind.speed), tx('.')],
      [tx('$character menghitung waktunya: ${fmtNum(v)} ÷ ${fmtNum(s)} = ${fmtNum(wrongT)} jam.')],
      [tx('Kata $character, bus hanya butuh sekitar $m menit.')],
      [tx('Setujukah kamu dengan $character?')],
    ],
    scene: SceneData(
      type: SceneType.single,
      lengthKm: s,
      leftName: 'Kota A',
      rightName: 'Kota B',
      movers: [Mover(id: 'A', vehicle: VehicleType.bus, startKm: 0, direction: 1, speedKmh: v, departAt: ClockTime.hm(7, 0))],
    ),
    readPoints: 1,
    askOptions: ask.options,
    askCorrect: ask.correct,
    askPoints: 1,
    conversions: const [],
    unitNote: 'Jarak km dan kecepatan km/jam. Waktunya dalam jam.',
    unitPoints: 0,
    formulaFocus: 'waktu',
    subs: [
      formulaChoice('waktu', r),
      NumericSub('Waktu yang benar = … jam', 1, expected: t, unit: Unit.h, wrongs: [
        _wp(wrongT, ErrorCode.formulaInverted),
        _wp(s * v, ErrorCode.formulaWrong),
      ]),
      NumericSub('Dalam menit, waktunya = … menit (bandingkan dengan $m menit)', 1,
          expected: t * 60,
          unit: Unit.min,
          wrongs: [
            _wp(t * 100, ErrorCode.unitBase100),
            _wp(t / 60, ErrorCode.unitWrongDirection),
            _wp(m.toDouble(), ErrorCode.formulaInverted),
          ],
          ecf: (g) => g['s1'] != null ? g['s1']! * 60 : null),
    ],
    check: choice('Jadi, setujukah kamu dengan $character?', 1,
        'Tidak setuju. $character membalik pembagian. Waktu = jarak ÷ kecepatan.', [
      ('Setuju. $m menit wajar untuk bus.', ErrorCode.formulaInverted),
      ('Tidak setuju. Seharusnya jarak × kecepatan.', ErrorCode.formulaWrong),
    ], r),
    hints: {
      StepKind.compute: [
        'Bayangkan bus melaju ${fmtNum(v)} km tiap jam. Bisakah ${fmtNum(s)} km ditempuh dalam $m menit?',
        'Waktu = jarak ÷ kecepatan = ${fmtNum(s)} ÷ ${fmtNum(v)}.',
      ],
    },
    solution: [
      'Diketahui: jarak ${_km(s)}, kecepatan ${_kmh(v)}.',
      '$character menghitung ${fmtNum(v)} ÷ ${fmtNum(s)}. Pembagiannya terbalik.',
      'Waktu = ${fmtNum(s)} ÷ ${fmtNum(v)} = ${fmtNum(t)} jam = ${fmtNum(t * 60)} menit.',
      'Jadi tidak setuju: waktunya ${fmtNum(t)} jam, bukan $m menit.',
    ],
  );
}

Problem buildCheckUnits({
  required double s,
  required double tMin,
  String character = 'Sari',
  int level = 3,
  int seed = 0,
}) {
  final r = Random(seed ^ 0x57);
  final tH = tMin / 60;
  final v = s / tH;
  final wrongV = s / tMin;
  final ask = choice('Apa yang perlu kamu cari?', 1, 'Kecepatan sepeda yang benar (km/jam)', [
    ('Jarak yang ditempuh', ErrorCode.misread),
    ('Jam berangkat', ErrorCode.clockVsDuration),
    ('Lama perjalanan', ErrorCode.misread),
  ], r);
  return Problem(
    templateId: 'periksa_hitungan',
    seed: seed,
    level: level,
    indicator: Indicator.interpreting,
    title: 'Periksa Hitungan $character',
    story: [
      [tx('$character bersepeda sejauh '), tk('s', _km(s), TagKind.distance), tx('.')],
      [tx('Ia sampai dalam '), tk('t', '${fmtNum(tMin)} menit', TagKind.duration), tx('.')],
      [tx('$character menghitung: ${fmtNum(s)} ÷ ${fmtNum(tMin)} = ${fmtNum(wrongV)} km/jam.')],
      [tx('Katanya, sepedanya sangat lambat.')],
      [tx('Setujukah kamu dengan $character?')],
    ],
    scene: SceneData(
      type: SceneType.single,
      lengthKm: s,
      leftName: 'Mulai',
      rightName: 'Tujuan',
      movers: [Mover(id: 'A', vehicle: VehicleType.bicycle, startKm: 0, direction: 1, speedKmh: v, departAt: ClockTime.hm(7, 0))],
    ),
    readPoints: 1,
    askOptions: ask.options,
    askCorrect: ask.correct,
    askPoints: 1,
    conversions: [ConversionTask(Quantity(tMin, Unit.min), Unit.h)],
    unitNote: 'Waktu dalam menit, kecepatan diminta dalam km/jam. Ubah menit ke jam.',
    unitPoints: 1,
    formulaFocus: 'kecepatan',
    subs: [
      formulaChoice('kecepatan', r),
      NumericSub('Kecepatan yang benar = … km/jam', 1,
          expected: v,
          unit: Unit.kmPerH,
          wrongs: [
            _wp(wrongV, ErrorCode.unitNotConverted),
            _wp(s / (tMin / 100), ErrorCode.unitBase100),
            _wp(tH / s, ErrorCode.formulaInverted),
          ],
          ecf: (g) => (g['c0'] ?? 0) > 0 ? s / g['c0']! : null),
    ],
    check: choice('Jadi, setujukah kamu dengan $character?', 1, 'Tidak setuju. Menit harus diubah ke jam dulu.', [
      ('Setuju. Rumusnya sudah jarak ÷ waktu.', ErrorCode.unitNotConverted),
      ('Tidak setuju. Seharusnya jarak × waktu.', ErrorCode.formulaWrong),
    ], r),
    hints: {
      StepKind.unit: [
        '$character membagi dengan menit, padahal kecepatan diminta per jam.',
        '${fmtNum(tMin)} menit ÷ 60 = … jam.',
      ],
      StepKind.compute: [
        'Sepeda biasanya 10–20 km/jam. Apakah ${fmtNum(wrongV)} km/jam masuk akal?',
        'Kecepatan = ${fmtNum(s)} ÷ ${fmtNum(tH, maxDecimals: 3)} jam.',
      ],
    },
    solution: [
      '$character membagi jarak dengan menit, bukan dengan jam.',
      '${fmtNum(tMin)} menit = ${fmtNum(tH, maxDecimals: 3)} jam.',
      'Kecepatan = ${fmtNum(s)} ÷ ${fmtNum(tH, maxDecimals: 3)} = ${fmtNum(v)} km/jam.',
      '${fmtNum(v)} km/jam wajar untuk sepeda. Jadi $character keliru.',
    ],
  );
}

// ─────────────────────── T7 Berpapasan (Formulating) ───────────────────────

Problem genHeadOn(int level, int seed) {
  final r = Random(seed);
  const speeds = [30, 40, 45, 50, 60, 70, 80];
  final times = switch (level) { 1 => [1.0, 2.0, 3.0], 2 => [0.5, 1.5, 2.5], _ => [0.75, 1.25, 1.5, 2.25] };
  final depart = _pick(r, [ClockTime.hm(6, 0), ClockTime.hm(6, 30), ClockTime.hm(7, 0), ClockTime.hm(7, 15), ClockTime.hm(8, 0)]);
  final vehA = _pick(r, [VehicleType.car, VehicleType.motorbike, VehicleType.bus]);
  final vehB = _pick(r, [VehicleType.truck, VehicleType.bus, VehicleType.car]);
  for (var i = 0; i < 200; i++) {
    final va = _pick(r, speeds).toDouble(), vb = _pick(r, speeds).toDouble();
    if (va == vb) continue;
    final t = _pick(r, times);
    final s = (va + vb) * t;
    if (!_isInt(s * 2)) continue;
    return buildHeadOn(
        s: s, va: va, vb: vb, depart: depart, vehA: vehA, vehB: vehB, level: level, seed: seed, distractor: level == 3);
  }
  return buildHeadOn(s: 180, va: 50, vb: 40, depart: ClockTime.hm(7, 0), level: level, seed: seed);
}

Problem buildHeadOn({
  required double s,
  required double va,
  required double vb,
  required ClockTime depart,
  VehicleType vehA = VehicleType.car,
  VehicleType vehB = VehicleType.bus,
  int level = 2,
  int seed = 0,
  bool distractor = false,
}) {
  final r = Random(seed ^ 0x58);
  final a = Mover(id: 'A', vehicle: vehA, startKm: 0, direction: 1, speedKmh: va, departAt: depart);
  final b = Mover(id: 'B', vehicle: vehB, startKm: s, direction: -1, speedKmh: vb, departAt: depart);
  final meet = MotionSimulator.meeting(a, b)!;
  final t = s / (va + vb);
  final diff = (va - vb).abs();
  final nA = _cap(vehA.label), nB = _cap(vehB.label);
  final ask = choice('Apa yang ditanya?', 1, 'Jam (pukul) saat berpapasan', [
    ('Jarak kedua kota', ErrorCode.misread),
    ('Kecepatan $nB B', ErrorCode.misread),
    ('Lama perjalanan sampai Kota Timur', ErrorCode.clockVsDuration),
  ], r);
  return Problem(
    templateId: 'berpapasan',
    seed: seed,
    level: level,
    indicator: Indicator.formulating,
    title: 'Berpapasan di Jalan',
    story: [
      [tx('$nA A berangkat dari Kota Barat pukul '), tk('c', depart.label, TagKind.clock), tx('.')],
      [tx('Kecepatannya '), tk('va', _kmh(va), TagKind.speed), tx('.')],
      [tx('$nB B berangkat dari Kota Timur pada jam yang sama.')],
      [tx('Kecepatannya '), tk('vb', _kmh(vb), TagKind.speed), tx('.')],
      if (distractor) [tx('$nA A membawa '), tk('x', '4 penumpang', TagKind.irrelevant), tx('.')],
      [tx('Jarak Kota Barat dan Kota Timur '), tk('s', _km(s), TagKind.distance), tx('.')],
      [tx('Mereka melewati jalan yang sama.')],
      [tx('Pukul berapa mereka '), gl('berpapasan'), tx('?')],
    ],
    scene: SceneData(
      type: SceneType.straight,
      lengthKm: s,
      leftName: 'Kota Barat',
      rightName: 'Kota Timur',
      movers: [a, b],
    ),
    readPoints: 1,
    askOptions: ask.options,
    askCorrect: ask.correct,
    askPoints: 1,
    conversions: const [],
    unitNote: 'Jarak dalam km dan kecepatan dalam km/jam. Lama perjalanan akan dalam jam.',
    unitPoints: 0,
    formulaFocus: 'waktu',
    subs: [
      NumericSub('Setiap 1 jam, jarak di antara mereka berkurang … km', 1,
          expected: va + vb, unit: Unit.kmPerH, wrongs: [_wp(diff, ErrorCode.relativeSpeedWrongOp)]),
      NumericSub('Lama sampai berpapasan = … jam', 1,
          expected: t,
          unit: Unit.h,
          wrongs: [
            _wp(s / diff, ErrorCode.relativeSpeedWrongOp),
            _wp((va + vb) / s, ErrorCode.formulaInverted),
            _wp(s / va, ErrorCode.misread),
          ],
          ecf: (g) => (g['s0'] ?? 0) > 0 ? s / g['s0']! : null),
      ClockSub('Pukul berapa mereka berpapasan?', 1,
          expected: meet.clock,
          wrongs: [
            (ClockTime(0).plusHours(t).minutes, ErrorCode.clockVsDuration),
            (depart.plusHours(s / diff).minutes, ErrorCode.relativeSpeedWrongOp),
          ],
          ecf: (g) => g['s1'] != null ? depart.minutes + (g['s1']! * 60).round() : null),
    ],
    check: choice('Apakah hasilnya masuk akal?', 1,
        'Masuk akal. A menempuh ${fmtNum(va * t)} km dan B ${fmtNum(vb * t)} km. Jumlahnya ${fmtNum(s)} km.', [
      ('Mereka pasti bertemu tepat di tengah jalan.', ErrorCode.misread),
      ('Waktunya lebih lama daripada jika A berjalan sendiri.', ErrorCode.relativeSpeedWrongOp),
    ], r),
    hints: {
      StepKind.compute: [
        'Mereka saling mendekat. Berapa km jarak mereka berkurang tiap jam?',
        'Kecepatan gabungan = ${fmtNum(va)} + ${fmtNum(vb)}. Waktu = jarak ÷ kecepatan gabungan.',
      ],
    },
    solution: [
      'Diketahui: jarak ${_km(s)}, A ${_kmh(va)}, B ${_kmh(vb)}, berangkat pukul ${depart.label}.',
      'Berlawanan arah, jadi jaraknya berkurang ${fmtNum(va)} + ${fmtNum(vb)} = ${fmtNum(va + vb)} km tiap jam.',
      'Lama = ${fmtNum(s)} ÷ ${fmtNum(va + vb)} = ${fmtNum(t, maxDecimals: 3)} jam.',
      'Berpapasan pukul ${depart.label} + ${fmtNum(t, maxDecimals: 3)} jam = pukul ${meet.clock.label}.',
      'Cek: ${fmtNum(va * t)} km + ${fmtNum(vb * t)} km = ${fmtNum(s)} km.',
    ],
  );
}

// ─────────────────────── T8 Menyusul (Employing) ───────────────────────

Problem genCatchUp(int level, int seed) {
  final r = Random(seed);
  final c0 = _pick(r, [ClockTime.hm(6, 0), ClockTime.hm(6, 30), ClockTime.hm(7, 0), ClockTime.hm(7, 30)]);
  for (var i = 0; i < 400; i++) {
    final vA = _pick(r, [30, 40, 45, 50, 60]).toDouble();
    final vB = _pick(r, [40, 45, 50, 60, 70, 75, 80, 90]).toDouble();
    if (vB <= vA) continue;
    final dMin = switch (level) { 1 => 60, 2 => 30, _ => _pick(r, [20, 45, 15]) };
    final head = vA * dMin / 60;
    if (!_isInt(head * 2)) continue;
    final dur = head / (vB - vA);
    if (!_isInt(dur * 60) || dur > 4) continue;
    return buildCatchUp(vA: vA, vB: vB, c0: c0, dMin: dMin, level: level, seed: seed);
  }
  return buildCatchUp(vA: 40, vB: 60, c0: ClockTime.hm(7, 0), dMin: 30, level: level, seed: seed);
}

Problem buildCatchUp({
  required double vA,
  required double vB,
  required ClockTime c0,
  required int dMin,
  int level = 2,
  int seed = 0,
}) {
  final r = Random(seed ^ 0x59);
  final c1 = c0.plusMinutes(dMin);
  final bus = Mover(id: 'A', vehicle: VehicleType.bus, startKm: 0, direction: 1, speedKmh: vA, departAt: c0);
  final moto = Mover(id: 'B', vehicle: VehicleType.motorbike, startKm: 0, direction: 1, speedKmh: vB, departAt: c1);
  final meet = MotionSimulator.meeting(bus, moto)!;
  final head = vA * dMin / 60;
  final rel = vB - vA;
  final dur = head / rel;
  final p = meet.positionKm;
  final ask = choice('Apa yang ditanya?', 0, 'Jam (pukul) saat motor menyusul bus', [
    ('Jarak terminal ke kota', ErrorCode.misread),
    ('Kecepatan bus', ErrorCode.misread),
    ('Lama bus berhenti', ErrorCode.misread),
  ], r);
  return Problem(
    templateId: 'menyusul',
    seed: seed,
    level: level,
    indicator: Indicator.employing,
    title: 'Motor Menyusul Bus',
    story: [
      [tx('Sebuah bus berangkat dari terminal pukul '), tk('c0', c0.label, TagKind.clock), tx('.')],
      [tx('Kecepatan bus '), tk('va', _kmh(vA), TagKind.speed), tx('.')],
      [tx('Kak Rudi naik motor dari terminal pukul '), tk('c1', c1.label, TagKind.clock), tx('.')],
      [tx('Kecepatan motornya '), tk('vb', _kmh(vB), TagKind.speed), tx('.')],
      [tx('Mereka lewat jalan yang sama dan searah.')],
      [tx('Pukul berapa motor '), gl('menyusul'), tx(' bus?')],
    ],
    scene: SceneData(
      type: SceneType.straight,
      lengthKm: p * 1.25,
      leftName: 'Terminal',
      rightName: 'Kota',
      movers: [bus, moto],
      showTimeline: true,
    ),
    readPoints: 1,
    askOptions: ask.options,
    askCorrect: ask.correct,
    askPoints: 0,
    conversions: [
      ConversionTask(Quantity(dMin.toDouble(), Unit.min), Unit.h,
          label: 'Bus berangkat lebih dulu: ${c0.label} → ${c1.label} = $dMin menit.'),
    ],
    unitNote: 'Selisih berangkat dalam menit, kecepatan dalam km/jam. Ubah menit ke jam.',
    unitPoints: 1,
    formulaFocus: 'jarak',
    subs: [
      NumericSub('Saat motor berangkat, bus sudah menempuh … km', 1,
          expected: head,
          unit: Unit.km,
          wrongs: [
            _wp(vA * dMin, ErrorCode.unitNotConverted),
            _wp(vA * dMin / 100, ErrorCode.unitBase100),
          ],
          ecf: (g) => g['c0'] != null ? vA * g['c0']! : null),
      NumericSub('Setiap 1 jam, jarak motor ke bus berkurang … km', 1,
          expected: rel, unit: Unit.kmPerH, wrongs: [_wp(vA + vB, ErrorCode.relativeSpeedWrongOp)]),
      NumericSub('Motor menyusul setelah berjalan … jam', 0,
          expected: dur,
          unit: Unit.h,
          wrongs: [
            _wp(head / (vA + vB), ErrorCode.relativeSpeedWrongOp),
            _wp(rel / head, ErrorCode.formulaInverted),
          ],
          ecf: (g) => (g['s1'] ?? 0) > 0 && g['s0'] != null ? g['s0']! / g['s1']! : null),
      ClockSub('Pukul berapa motor menyusul bus?', 1,
          expected: meet.clock,
          wrongs: [
            (c0.plusHours(dur).minutes, ErrorCode.headStartIgnored),
            (ClockTime(0).plusHours(dur).minutes, ErrorCode.clockVsDuration),
          ],
          ecf: (g) => g['s2'] != null ? c1.minutes + (g['s2']! * 60).round() : null),
    ],
    check: choice('Apakah hasilnya masuk akal?', 1,
        'Masuk akal. Pada jam itu keduanya sudah ${fmtNum(p)} km dari terminal.', [
      ('Motor tidak mungkin menyusul karena bus berangkat duluan.', ErrorCode.headStartIgnored),
      ('Motor menyusul tepat saat ia berangkat.', ErrorCode.headStartIgnored),
    ], r),
    hints: {
      StepKind.unit: [
        'Siapa berangkat lebih dulu? Berapa menit selisihnya?',
        '$dMin menit ÷ 60 = … jam.',
      ],
      StepKind.compute: [
        'Saat motor mulai, bus sudah di depan. Searah, jadi selisih kecepatannya yang mengejar.',
        'Jarak awal = ${fmtNum(vA)} × ${fmtNum(dMin / 60, maxDecimals: 3)}. Waktu = jarak awal ÷ (${fmtNum(vB)} − ${fmtNum(vA)}).',
      ],
    },
    solution: [
      'Bus berangkat $dMin menit (${fmtNum(dMin / 60, maxDecimals: 3)} jam) lebih dulu.',
      'Jarak awal = ${fmtNum(vA)} × ${fmtNum(dMin / 60, maxDecimals: 3)} = ${fmtNum(head)} km.',
      'Searah, jadi jaraknya berkurang ${fmtNum(vB)} − ${fmtNum(vA)} = ${fmtNum(rel)} km tiap jam.',
      'Waktu menyusul = ${fmtNum(head)} ÷ ${fmtNum(rel)} = ${fmtNum(dur, maxDecimals: 3)} jam setelah ${c1.label}.',
      'Motor menyusul pukul ${meet.clock.label}, di km ${fmtNum(p)}.',
    ],
  );
}

// ─────────────────────── T9 Tepat waktu (Reasoning) ───────────────────────

class _OnTimeCtx {
  final String name, ride;
  final VehicleType vehicle;
  final List<int> speeds;
  final List<double> dists;
  const _OnTimeCtx(this.name, this.ride, this.vehicle, this.speeds, this.dists);
}

const _onTimeCtx = [
  _OnTimeCtx('Raka', 'ojek', VehicleType.motorbike, [20, 24, 30, 36, 40], [4, 5, 6, 8, 9, 10]),
  _OnTimeCtx('Nisa', 'angkot', VehicleType.bus, [20, 24, 30], [3, 4, 5, 6]),
  _OnTimeCtx('Fajar', 'sepeda', VehicleType.bicycle, [10, 12, 15], [2, 3, 4]),
];

Problem genOnTime(int level, int seed) {
  final r = Random(seed);
  final ctx = r.nextInt(_onTimeCtx.length);
  final c = _onTimeCtx[ctx];
  final bell = ClockTime.hm(7, 0);
  for (var i = 0; i < 300; i++) {
    final s = _pick(r, c.dists);
    final v = _pick(r, c.speeds).toDouble();
    final tMin = 60 * s / v;
    if (!_isInt(tMin) || tMin < 8 || tMin > 40) continue;
    final delta = _pick(r, level == 1 ? [-10, 10] : [-10, -5, 5, 10]);
    final depart = ClockTime(bell.minutes - tMin.round() + delta);
    return buildOnTime(s: s, v: v, depart: depart, bell: bell, level: level, seed: seed, ctx: ctx);
  }
  return buildOnTime(s: 9, v: 36, depart: ClockTime.hm(6, 40), bell: bell, level: level, seed: seed);
}

Problem buildOnTime({
  required double s,
  required double v,
  required ClockTime depart,
  required ClockTime bell,
  int level = 2,
  int seed = 0,
  int ctx = 0,
}) {
  final r = Random(seed ^ 0x60);
  final c = _onTimeCtx[ctx % _onTimeCtx.length];
  final tMin = 60 * s / v;
  final arrive = depart.plusMinutes(tMin);
  final onTime = arrive.minutes <= bell.minutes;
  final ask = choice('Apa yang perlu kamu cari dulu?', 1, 'Jam tiba, lalu bandingkan dengan jam masuk', [
    ('Jarak rumah ke sekolah', ErrorCode.misread),
    ('Kecepatan ${c.ride}', ErrorCode.misread),
    ('Jam berangkat', ErrorCode.clockVsDuration),
  ], r);
  return Problem(
    templateId: 'tepat_waktu',
    seed: seed,
    level: level,
    indicator: Indicator.reasoning,
    title: 'Tepat Waktu ke Sekolah?',
    story: [
      [tx('${c.name} naik ${c.ride} ke sekolah.')],
      [tx('Jarak rumah ke sekolah '), tk('s', _km(s), TagKind.distance), tx('.')],
      [tx('Kecepatan rata-rata ${c.ride} '), tk('v', _kmh(v), TagKind.speed), tx('.')],
      [tx('${c.name} berangkat pukul '), tk('c', depart.label, TagKind.clock), tx('.')],
      [tx('Sekolah masuk pukul '), tk('b', bell.label, TagKind.clock), tx('.')],
      [tx('Apakah ${c.name} tiba tepat waktu?')],
    ],
    scene: SceneData(
      type: SceneType.single,
      lengthKm: s,
      leftName: 'Rumah',
      rightName: 'Sekolah',
      movers: [Mover(id: 'A', vehicle: c.vehicle, startKm: 0, direction: 1, speedKmh: v, departAt: depart)],
      showTimeline: true,
    ),
    readPoints: 1,
    askOptions: ask.options,
    askCorrect: ask.correct,
    askPoints: 1,
    conversions: const [],
    unitNote: 'Jarak ÷ kecepatan menghasilkan jam. Ubah ke menit (× 60) agar mudah ditambah ke jam berangkat.',
    unitPoints: 0,
    formulaFocus: 'waktu',
    subs: [
      NumericSub('Lama perjalanan = … menit', 1, expected: tMin, unit: Unit.min, wrongs: [
        _wp(s / v, ErrorCode.unitNotConverted),
        _wp(v / s * 60, ErrorCode.formulaInverted),
        _wp(s / v * 100, ErrorCode.unitBase100),
      ]),
      ClockSub('${c.name} tiba pukul …', 1,
          expected: arrive,
          wrongs: [(ClockTime(0).plusMinutes(tMin).minutes, ErrorCode.clockVsDuration)],
          ecf: (g) => g['s0'] != null ? depart.minutes + g['s0']!.round() : null),
      choice('Apakah ${c.name} tepat waktu?', 1, onTime ? 'Ya, tepat waktu' : 'Tidak, terlambat',
          [(onTime ? 'Tidak, terlambat' : 'Ya, tepat waktu', ErrorCode.misread)], r),
    ],
    check: choice('Mengapa?', 1,
        onTime
            ? '${c.name} tiba pukul ${arrive.label}, sebelum pukul ${bell.label}.'
            : '${c.name} tiba pukul ${arrive.label}, sesudah pukul ${bell.label}.',
        [
          (onTime ? 'Terlambat, karena jaraknya ${fmtNum(s)} km.' : 'Tepat waktu, karena ${c.ride} cepat.',
              ErrorCode.misread),
          ('Tidak bisa ditentukan dari soal ini.', null),
        ],
        r),
    hints: {
      StepKind.compute: [
        'Berapa menit perjalanannya? Lalu tambahkan ke jam berangkat.',
        'Waktu = ${fmtNum(s)} ÷ ${fmtNum(v)} jam. Kalikan 60 untuk menit.',
      ],
    },
    solution: [
      'Lama perjalanan = ${fmtNum(s)} ÷ ${fmtNum(v)} = ${fmtNum(s / v, maxDecimals: 3)} jam = ${fmtNum(tMin)} menit.',
      'Tiba = ${depart.label} + ${fmtNum(tMin)} menit = pukul ${arrive.label}.',
      'Sekolah masuk ${bell.label}. ${onTime ? 'Tepat waktu.' : 'Terlambat.'}',
    ],
  );
}
