import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/adaptive.dart';
import '../domain/motion.dart';
import '../domain/problem.dart';
import 'content.dart';
import 'models.dart';

/// Urutan kendaraan yang terbuka di Garasi.
const vehicleUnlockOrder = [
  VehicleType.bicycle,
  VehicleType.scooter,
  VehicleType.motorbike,
  VehicleType.car,
  VehicleType.bus,
  VehicleType.train,
];

const vehicleColors = <int>[0xFFF2C94C, 0xFFEB5757, 0xFF2F80ED, 0xFF27AE60, 0xFF9B51E0, 0xFFF2994A];

class AppBadge {
  final String id, name, icon, desc;
  const AppBadge(this.id, this.name, this.icon, this.desc);
}

const allBadges = [
  AppBadge('teliti_satuan', 'Teliti Satuan', '🔧', '10 konversi satuan benar'),
  AppBadge('pelukis_jalan', 'Pelukis Jalan', '✏️', 'Memakai Sketsa Jalan 5 kali'),
  AppBadge('detektif', 'Detektif', '🔍', 'Menemukan 5 kesalahan di Detektif Lalu Lintas'),
  AppBadge('cek_logika', 'Pemeriksa Logika', '🧠', '10 kali Cek Logika benar'),
  AppBadge('penjelajah', 'Penjelajah Kota', '🗺️', 'Menyelesaikan semua distrik'),
  AppBadge('juara_ujian', 'Juara Ujian Kota', '🏆', 'Skor Ujian Kota ≥ 18 dari 24'),
];

class AppState extends ChangeNotifier {
  SharedPreferences? _prefs;
  static const _key = 'kotalaju_state_v1';

  Profile? profile;
  Set<String> doneDistricts = {};
  Map<String, Set<int>> segmentsDone = {};
  int? prereqScore;
  List<AttemptRecord> attempts = [];
  AdaptivePath adaptive = AdaptivePath();
  int coins = 0;
  Set<VehicleType> unlocked = {};
  Map<String, int> vehicleColor = {};
  Set<String> badges = {};
  Map<String, int> counters = {};
  Map<String, int> gameStars = {};
  bool mentalEffortEnabled = true;
  bool reduceMotion = false;
  bool economyMode = false;
  String? teacherPinHash;
  List<Map<String, dynamic>> events = [];

  /// Karakter pesepeda yang dipilih (indeks ke riderSkins).
  int riderSkin = 0;

  void setRiderSkin(int i) {
    riderSkin = i;
    _changed();
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      _fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Gagal memuat data: $e');
    }
  }

  void _save() {
    _prefs?.setString(_key, jsonEncode(_toJson()));
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  // ───────────── profil ─────────────

  void createProfile({required String nickname, required int grade, required String classCode, required VehicleType vehicle, required bool consent}) {
    final rnd = Random.secure();
    final id = List.generate(16, (_) => rnd.nextInt(16).toRadixString(16)).join();
    profile = Profile(nickname: nickname, grade: grade, classCode: classCode, vehicle: vehicle, consent: consent, studentId: id);
    unlocked = {vehicle};
    log('consent', {'given': consent});
    _changed();
  }

  void selectVehicle(VehicleType v) {
    if (profile == null || !unlocked.contains(v)) return;
    profile = profile!.copyWith(vehicle: v);
    _changed();
  }

  int colorOf(VehicleType v) => vehicleColor[v.name] ?? vehicleColors.first;

  bool buyColor(VehicleType v, int color, {int cost = 30}) {
    if (coins < cost) return false;
    coins -= cost;
    vehicleColor[v.name] = color;
    _changed();
    return true;
  }

  // ───────────── distrik ─────────────

  bool isDistrictOpen(District d) => d.prerequisites.every(doneDistricts.contains);

  bool get recommendMenaraJam => prereqScore == null || prereqScore! < 4;

  bool get postTestOpen => doneDistricts.contains('halte_transit');

  void markSegment(String districtId, int index) {
    final s = segmentsDone.putIfAbsent(districtId, () => {});
    if (s.add(index)) _changed();
  }

  bool segmentDone(String districtId, int index) => segmentsDone[districtId]?.contains(index) ?? false;

  /// Mengembalikan kendaraan baru yang terbuka (jika ada).
  VehicleType? completeDistrict(String id) {
    if (!doneDistricts.add(id)) return null;
    coins += 20;
    VehicleType? newVehicle;
    for (final v in vehicleUnlockOrder) {
      if (!unlocked.contains(v)) {
        unlocked.add(v);
        newVehicle = v;
        break;
      }
    }
    if (districts.every((d) => doneDistricts.contains(d.id))) badges.add('penjelajah');
    log('district_completed', {'district': id});
    _changed();
    return newVehicle;
  }

  // ───────────── percobaan soal ─────────────

  void recordAttempt(AttemptRecord a) {
    attempts.add(a);
    if (a.context != 'pretest' && a.context != 'posttest') {
      for (final s in a.steps) {
        adaptive.record(s.step, correct: s.correct, hintLevelUsed: s.hintLevel);
      }
      coins += a.score;
    }
    for (final s in a.steps) {
      if (s.step == StepKind.unit && s.correct && s.elementId.startsWith('c')) bump('unit_correct');
      if (s.step == StepKind.check && s.correct) bump('check_correct', save: false);
    }
    if ((counters['check_correct'] ?? 0) >= 10) badges.add('cek_logika');
    if (a.context == 'posttest' && posttestScore != null && posttestScore! >= 18) badges.add('juara_ujian');
    log('attempt_completed', {
      'problem': a.problemId,
      'context': a.context,
      'score': a.score,
      'max': a.maxScore,
      'effort': a.mentalEffort,
    });
    _changed();
  }

  void setPrereqScore(int score) {
    prereqScore = score;
    log('pretest_prerequisite', {'score': score});
    _changed();
  }

  void bump(String counter, {int by = 1, bool save = true}) {
    counters[counter] = (counters[counter] ?? 0) + by;
    if ((counters['unit_correct'] ?? 0) >= 10) badges.add('teliti_satuan');
    if ((counters['sketch_used'] ?? 0) >= 5) badges.add('pelukis_jalan');
    if ((counters['detective_found'] ?? 0) >= 5) badges.add('detektif');
    if (save) _changed();
  }

  void addCoins(int n) {
    coins += n;
    _changed();
  }

  void recordGame(String gameId, int tier, int stars, Map<String, dynamic> details) {
    final key = '${gameId}_$tier';
    if (stars > (gameStars[key] ?? 0)) gameStars[key] = stars;
    coins += stars * 5;
    log('game_session_completed', {'game': gameId, 'tier': tier, 'stars': stars, ...details});
    _changed();
  }

  int bestStars(String gameId) =>
      [1, 2, 3].map((t) => gameStars['${gameId}_$t'] ?? 0).fold(0, (a, b) => a > b ? a : b);

  bool isGameUnlocked(GameInfo g) => doneDistricts.contains(g.unlockedBy);

  // ───────────── skor tes ─────────────

  List<AttemptRecord> attemptsIn(String context) => attempts.where((a) => a.context == context).toList();

  Map<Indicator, int>? _testScores(String context) {
    final list = attemptsIn(context);
    if (list.isEmpty) return null;
    final m = <Indicator, int>{};
    for (final i in Indicator.values) {
      final ofI = list.where((a) => a.indicator == i).toList();
      if (ofI.isNotEmpty) m[i] = ofI.last.score;
    }
    return m;
  }

  Map<Indicator, int>? get pretestByIndicator => _testScores('pretest');
  Map<Indicator, int>? get posttestByIndicator => _testScores('posttest');

  int? get pretestScore => pretestByIndicator?.values.fold<int>(0, (a, b) => a + b);
  int? get posttestScore => posttestByIndicator?.values.fold<int>(0, (a, b) => a + b);

  bool get pretestDone => (pretestByIndicator?.length ?? 0) == Indicator.values.length;
  bool get posttestDone => (posttestByIndicator?.length ?? 0) == Indicator.values.length;

  double? get nGain {
    final pre = pretestScore, post = posttestScore;
    if (pre == null || post == null || !pretestDone || !posttestDone || pre >= 24) return null;
    return (post - pre) / (24 - pre);
  }

  /// Rasio skor per indikator (0..1) dari semua kuis/tes untuk grafik radar.
  Map<Indicator, double> mlProfile() {
    final res = <Indicator, double>{};
    for (final i in Indicator.values) {
      final list = attempts.where((a) => a.indicator == i && a.context != 'completion').toList();
      final recent = list.length > 8 ? list.sublist(list.length - 8) : list;
      final max = recent.fold<int>(0, (a, b) => a + b.maxScore);
      res[i] = max == 0 ? 0 : recent.fold<int>(0, (a, b) => a + b.score) / max;
    }
    return res;
  }

  double? unitErrorRate(String context) {
    var graded = 0, unitErr = 0;
    for (final a in attemptsIn(context)) {
      for (final s in a.steps) {
        if (s.maxPoints == 0) continue;
        graded++;
        if (s.error?.category == ErrorCategory.unit) unitErr++;
      }
    }
    return graded == 0 ? null : unitErr / graded;
  }

  // ───────────── pengaturan & guru ─────────────

  void setSettings({bool? mentalEffort, bool? reduce, bool? economy}) {
    if (mentalEffort != null) mentalEffortEnabled = mentalEffort;
    if (reduce != null) reduceMotion = reduce;
    if (economy != null) economyMode = economy;
    _changed();
  }

  static String _hash(String pin) => sha256.convert(utf8.encode('kotalaju:$pin')).toString();

  void setTeacherPin(String pin) {
    teacherPinHash = _hash(pin);
    _changed();
  }

  bool checkTeacherPin(String pin) => teacherPinHash != null && _hash(pin) == teacherPinHash;

  Future<void> resetAll() async {
    await _prefs?.remove(_key);
    profile = null;
    doneDistricts = {};
    segmentsDone = {};
    prereqScore = null;
    attempts = [];
    adaptive = AdaptivePath();
    coins = 0;
    unlocked = {};
    vehicleColor = {};
    badges = {};
    counters = {};
    gameStars = {};
    teacherPinHash = null;
    events = [];
    notifyListeners();
  }

  /// Event analitik hanya dicatat bila siswa menyetujui pengumpulan data.
  void log(String type, Map<String, dynamic> payload) {
    if (profile?.consent != true && type != 'consent') return;
    events.add({'type': type, 'at': DateTime.now().toUtc().toIso8601String(), 'payload': payload});
    if (events.length > 5000) events.removeRange(0, events.length - 5000);
  }

  void logTool(String tool) {
    log('tool_used', {'tool': tool});
    _save();
  }

  // ───────────── serialisasi ─────────────

  Map<String, dynamic> _toJson() => {
        'profile': profile?.toJson(),
        'doneDistricts': doneDistricts.toList(),
        'segmentsDone': {for (final e in segmentsDone.entries) e.key: e.value.toList()},
        'prereqScore': prereqScore,
        'attempts': [for (final a in attempts) a.toJson()],
        'adaptive': adaptive.toJson(),
        'coins': coins,
        'unlocked': [for (final v in unlocked) v.name],
        'vehicleColor': vehicleColor,
        'badges': badges.toList(),
        'counters': counters,
        'gameStars': gameStars,
        'mentalEffortEnabled': mentalEffortEnabled,
        'reduceMotion': reduceMotion,
        'economyMode': economyMode,
        'teacherPinHash': teacherPinHash,
        'events': events,
        'riderSkin': riderSkin,
      };

  void _fromJson(Map<String, dynamic> j) {
    profile = j['profile'] == null ? null : Profile.fromJson((j['profile'] as Map).cast<String, dynamic>());
    doneDistricts = {...((j['doneDistricts'] as List?) ?? []).cast<String>()};
    segmentsDone = {
      for (final e in ((j['segmentsDone'] as Map?) ?? {}).entries)
        e.key as String: {...(e.value as List).map((x) => (x as num).toInt())},
    };
    prereqScore = (j['prereqScore'] as num?)?.toInt();
    attempts = [
      for (final a in ((j['attempts'] as List?) ?? [])) AttemptRecord.fromJson((a as Map).cast<String, dynamic>()),
    ];
    adaptive = AdaptivePath.fromJson((j['adaptive'] as Map?)?.cast<String, dynamic>());
    coins = (j['coins'] as num?)?.toInt() ?? 0;
    unlocked = {for (final v in ((j['unlocked'] as List?) ?? [])) VehicleType.values.byName(v as String)};
    vehicleColor = ((j['vehicleColor'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
    badges = {...((j['badges'] as List?) ?? []).cast<String>()};
    counters = ((j['counters'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
    gameStars = ((j['gameStars'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt()));
    mentalEffortEnabled = j['mentalEffortEnabled'] as bool? ?? true;
    reduceMotion = j['reduceMotion'] as bool? ?? false;
    economyMode = j['economyMode'] as bool? ?? false;
    teacherPinHash = j['teacherPinHash'] as String?;
    events = [for (final e in ((j['events'] as List?) ?? [])) (e as Map).cast<String, dynamic>()];
    riderSkin = (j['riderSkin'] as num?)?.toInt() ?? 0;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
