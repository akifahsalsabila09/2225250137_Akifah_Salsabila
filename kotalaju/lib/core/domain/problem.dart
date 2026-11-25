import 'clock.dart';
import 'motion.dart';
import 'units.dart';

enum Indicator {
  reasoning('Reasoning', 'Bernalar'),
  formulating('Formulating', 'Memodelkan'),
  employing('Employing', 'Menerapkan'),
  interpreting('Interpreting', 'Menafsirkan');

  const Indicator(this.en, this.id);
  final String en;
  final String id;
}

/// Lima langkah tetap setiap soal cerita.
enum StepKind {
  read('Baca & Tandai'),
  known('Diketahui–Ditanya'),
  unit('Samakan Satuan'),
  compute('Hitung'),
  check('Cek Logika');

  const StepKind(this.title);
  final String title;
}

/// Jenis informasi untuk Penanda Info.
enum TagKind {
  distance('Jarak'),
  speed('Kecepatan'),
  duration('Lama'),
  clock('Jam'),
  irrelevant('Tidak perlu');

  const TagKind(this.label);
  final String label;
}

enum ErrorCategory { unit, formula, reading, arithmetic, unknown }

enum ErrorCode {
  unitNotConverted(ErrorCategory.unit, 'Satuannya belum disamakan. Ubah menit ke jam dulu (atau sebaliknya).'),
  unitWrongDirection(ErrorCategory.unit, 'Arah konversinya terbalik. Menit → jam: angkanya jadi lebih kecil, jadi dibagi 60.'),
  unitBase100(ErrorCategory.unit, 'Ingat, 1 jam = 60 menit, bukan 100 menit.'),
  formulaInverted(ErrorCategory.formula, 'Pembagiannya terbalik. Lihat lagi segitiga JKW.'),
  formulaWrong(ErrorCategory.formula, 'Rumusnya belum tepat. Tutup besaran yang dicari di segitiga JKW.'),
  relativeSpeedWrongOp(ErrorCategory.formula,
      'Cek arahnya. Berlawanan arah: kecepatan dijumlah. Searah (menyusul): kecepatan dikurang.'),
  avgOfSpeeds(ErrorCategory.formula, 'Kecepatan rata-rata = total jarak ÷ total waktu, bukan rata-rata dua kecepatan.'),
  headStartIgnored(ErrorCategory.reading, 'Siapa yang berangkat lebih dulu? Hitung dari jam berangkat yang tepat.'),
  clockVsDuration(ErrorCategory.reading, 'Bedakan jam (pukul berapa) dengan lama perjalanan.'),
  misread(ErrorCategory.reading, 'Baca lagi soalnya pelan-pelan. Apa yang sebenarnya diketahui dan ditanya?'),
  irrelevantUsed(ErrorCategory.reading, 'Ada info yang tidak dibutuhkan. Coret info yang tidak dipakai untuk menghitung.'),
  arithmetic(ErrorCategory.arithmetic, 'Caramu sudah benar! Cek lagi hitungannya.'),
  unknown(ErrorCategory.unknown, 'Belum tepat. Coba lihat petunjuk.');

  const ErrorCode(this.category, this.message);
  final ErrorCategory category;
  final String message;
}

class StoryToken {
  final String id;
  final String text;
  final TagKind kind;
  const StoryToken(this.id, this.text, this.kind);
}

class StoryPart {
  final String text;
  final StoryToken? token;
  final String? glossary;
  const StoryPart(this.text, {this.token, this.glossary});
}

StoryPart tx(String s) => StoryPart(s);
StoryPart tk(String id, String s, TagKind k) => StoryPart(s, token: StoryToken(id, s, k));
StoryPart gl(String term, [String? shown]) => StoryPart(shown ?? term, glossary: term);

typedef Given = Map<String, double>;

class WrongPattern {
  final double value;
  final ErrorCode code;
  const WrongPattern(this.value, this.code);
}

sealed class SubQuestion {
  final String prompt;
  final int points;
  const SubQuestion(this.prompt, this.points);
}

class NumericSub extends SubQuestion {
  final double expected;
  final Unit unit;
  final List<WrongPattern> wrongs;

  /// Nilai yang benar bila memakai jawaban siswa sebelumnya (error carried forward).
  final double? Function(Given given)? ecf;
  const NumericSub(super.prompt, super.points,
      {required this.expected, required this.unit, this.wrongs = const [], this.ecf});
}

class ClockSub extends SubQuestion {
  final ClockTime expected;
  final List<(int, ErrorCode)> wrongs;
  final int? Function(Given given)? ecf;
  const ClockSub(super.prompt, super.points, {required this.expected, this.wrongs = const [], this.ecf});
}

class ChoiceSub extends SubQuestion {
  final List<String> options;
  final int correct;
  final Map<int, ErrorCode> wrongCodes;
  const ChoiceSub(super.prompt, super.points,
      {required this.options, required this.correct, this.wrongCodes = const {}});
}

class ConversionTask {
  final Quantity from;
  final Unit target;
  final int points;
  final String? label;
  const ConversionTask(this.from, this.target, {this.points = 1, this.label});

  double get expected => from.to(target).value;
}

enum SceneType { single, straight, routes, legs }

class RouteInfo {
  final String name;
  final double km;
  final double kmh;
  const RouteInfo(this.name, this.km, this.kmh);
}

class LegInfo {
  final double km;
  final double kmh;
  const LegInfo(this.km, this.kmh);
}

class SceneData {
  final SceneType type;
  final double lengthKm;
  final String leftName;
  final String rightName;
  final List<Mover> movers;
  final List<RouteInfo> routes;
  final List<LegInfo> legs;
  final bool showTimeline;
  const SceneData({
    required this.type,
    required this.lengthKm,
    this.leftName = '',
    this.rightName = '',
    this.movers = const [],
    this.routes = const [],
    this.legs = const [],
    this.showTimeline = false,
  });

  bool get sketchable => type == SceneType.straight && movers.length == 2;
}

class Problem {
  final String templateId;
  final int seed;
  final int level;
  final Indicator indicator;
  final String title;
  final List<List<StoryPart>> story;
  final SceneData scene;

  final int readPoints;
  final List<String> askOptions;
  final int askCorrect;
  final int askPoints;

  final List<ConversionTask> conversions;
  final String unitNote;
  final int unitPoints; // dipakai bila conversions kosong (pertanyaan "satuan sudah sejalan?")

  final String formulaFocus; // 'waktu' | 'kecepatan' | 'jarak' untuk segitiga JKW
  final List<SubQuestion> subs;
  final ChoiceSub check;

  /// Petunjuk per langkah: [pertanyaan pemantik, langkah berikutnya].
  final Map<StepKind, List<String>> hints;
  final List<String> solution;

  const Problem({
    required this.templateId,
    required this.seed,
    required this.level,
    required this.indicator,
    required this.title,
    required this.story,
    required this.scene,
    required this.readPoints,
    required this.askOptions,
    required this.askCorrect,
    required this.askPoints,
    required this.conversions,
    required this.unitNote,
    required this.unitPoints,
    required this.formulaFocus,
    required this.subs,
    required this.check,
    required this.hints,
    required this.solution,
  });

  String get id => '$templateId#$seed@$level';

  List<StoryToken> get tokens => [
        for (final s in story)
          for (final p in s)
            if (p.token != null) p.token!,
      ];

  int get maxScore =>
      readPoints +
      askPoints +
      (conversions.isEmpty ? unitPoints : conversions.fold<int>(0, (a, c) => a + c.points)) +
      subs.fold<int>(0, (a, s) => a + s.points) +
      check.points;

  List<String> hintsFor(StepKind k) =>
      hints[k] ?? _defaultHints[k] ?? const ['Baca lagi soalnya.', 'Coba langkah demi langkah.'];

  static const _defaultHints = {
    StepKind.read: [
      'Angka mana yang punya satuan km? km/jam? menit? pukul?',
      'Angka dengan "pukul" adalah jam. Angka dengan "jam" atau "menit" saja adalah lama perjalanan.',
    ],
    StepKind.known: [
      'Lihat kalimat terakhir. Kata tanya apa yang dipakai?',
      '"Berapa lama" berarti waktu. "Pukul berapa" berarti jam. "Berapa km" berarti jarak.',
    ],
    StepKind.unit: [
      'Apakah semua satuan waktunya sama: jam semua atau menit semua?',
      'Menit → jam: dibagi 60. Jam → menit: dikali 60.',
    ],
    StepKind.check: [
      'Kalau kecepatan besar, waktunya harus singkat. Apakah hasilmu begitu?',
      'Coba kalikan kembali: kecepatan × waktu harus sama dengan jarak.',
    ],
  };
}
