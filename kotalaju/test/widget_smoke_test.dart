import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotalaju/core/data/game_audio.dart';
import 'package:kotalaju/app/theme.dart';
import 'package:kotalaju/core/data/app_state.dart';
import 'package:kotalaju/core/data/content.dart';
import 'package:kotalaju/core/domain/motion.dart';
import 'package:kotalaju/core/domain/soal_koin.dart';
import 'package:kotalaju/core/domain/soal_tetap.dart';
import 'package:kotalaju/features/ride/ride_screen.dart';
import 'package:kotalaju/features/games/catch_bus_game.dart';
import 'package:kotalaju/features/games/courier_route_game.dart';
import 'package:kotalaju/features/games/meeting_point_game.dart';
import 'package:kotalaju/features/games/traffic_detective_game.dart';
import 'package:kotalaju/features/games/unit_rally_game.dart';
import 'package:kotalaju/features/lesson/animations.dart';
import 'package:kotalaju/features/lesson/district_screen.dart';
import 'package:kotalaju/features/home/soal_list_screen.dart';
import 'package:kotalaju/features/onboarding/onboarding_screen.dart';
import 'package:kotalaju/features/problem/problem_session.dart';
import 'package:kotalaju/features/problem/series.dart';
import 'package:kotalaju/features/quiz/test_screen.dart';
import 'package:kotalaju/features/teacher/teacher_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state({bool withProfile = true}) async {
  SharedPreferences.setMockInitialValues({});
  final s = AppState();
  await s.load();
  if (withProfile) {
    s.createProfile(nickname: 'Raka', grade: 7, classCode: '7A', vehicle: VehicleType.car, consent: true);
    for (final d in districts) {
      s.completeDistrict(d.id);
    }
  }
  return s;
}

/// Menjalankan beberapa frame agar animasi (lembar bawah, transisi) selesai.
Future<void> _frames(WidgetTester t, {int n = 12}) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Widget _wrap(AppState s, Widget child) =>
    AppScope(state: s, child: MaterialApp(theme: buildTheme(), home: child));

void main() {
  setUp(() {
    GameAudio.disabled = true;
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2340);
    binding.platformDispatcher.views.first.devicePixelRatio = 3;
  });

  testWidgets('onboarding tampil', (t) async {
    final s = await _state(withProfile: false);
    await t.pumpWidget(_wrap(s, const OnboardingScreen()));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Ayo mulai!'), findsOneWidget);
    await t.tap(find.text('Ayo mulai!'));
    await _frames(t);
    expect(find.text('Kenalan dulu, yuk'), findsOneWidget);
  });

  testWidgets('naik sepeda: 7 koin, jawab soal, sampai finish', (t) async {
    final s = await _state();
    await t.pumpWidget(_wrap(s, const RideScreen()));
    await t.pump();
    // Pilih karakter Nisa (berhijab).
    await t.tap(find.text('Nisa'));
    await t.pump();
    expect(s.riderSkin, 1);
    await t.ensureVisible(find.text('Mulai Gowes 🚲'));
    await t.tap(find.text('Mulai Gowes 🚲'));
    await t.pump();
    // Kalkulator dan Tanya Jawab bisa dibuka saat menggowes.
    await t.tap(find.byTooltip('Kalkulator'));
    await _frames(t);
    for (final k in ['1', '5', '0', '÷', '5', '0', '=']) {
      await t.tap(find.widgetWithText(FilledButton, k).first);
      await t.pump();
    }
    expect(find.text('= 3'), findsOneWidget);
    await t.tap(find.byTooltip('Tutup'));
    await _frames(t);
    await t.tap(find.byTooltip('Tanya Jawab'));
    await _frames(t);
    await t.enterText(find.byType(TextField), 'menit ke jam');
    await t.pump();
    expect(find.textContaining('Bagi dengan 60'), findsOneWidget);
    await t.tap(find.byTooltip('Tutup'));
    await _frames(t);
    // Tombol suara: matikan lalu nyalakan lagi (pilihan tersimpan).
    await t.tap(find.byTooltip('Matikan suara'));
    await t.pump();
    expect(s.soundOn, isFalse);
    expect(find.text('🔇'), findsOneWidget);
    await t.tap(find.byTooltip('Nyalakan suara'));
    await t.pump();
    expect(s.soundOn, isTrue);
    // Tombol Lompat berfungsi.
    await t.tap(find.text('LOMPAT ⬆'));
    await t.pump(const Duration(milliseconds: 50));
    for (var no = 1; no <= soalKoin.length; no++) {
      // Gowes sampai bertemu koin (menabrak rintangan hanya memperlambat).
      for (var i = 0; i < 300 && find.text('Koin $no dari 7').evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Koin $no dari 7'), findsOneWidget);
      final q = soalKoin[no - 1];
      // Pilih jawaban yang salah untuk koin genap, benar untuk koin ganjil.
      final pick = no.isOdd ? q.benar : (q.benar + 1) % q.pilihan.length;
      await t.ensureVisible(find.text(q.pilihan[pick]));
      await t.pump();
      await t.tap(find.text(q.pilihan[pick]));
      await t.pump();
      expect(find.text('Pembahasan'), findsOneWidget);
      if (no.isEven) expect(find.textContaining('Jawaban yang benar: ${q.jawaban}'), findsOneWidget);
      final next = find.textContaining(RegExp('gowes', caseSensitive: false)).last;
      await t.ensureVisible(next);
      await t.tap(next);
      await t.pump();
    }
    for (var i = 0; i < 300 && find.text('Sampai di garis finish!').evaluate().isEmpty; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Sampai di garis finish!'), findsOneWidget);
    expect(find.text('Kamu menjawab benar 4 dari 7 soal.'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('beranda hanya berisi 7 soal dan soal bisa dibuka', (t) async {
    final s = await _state();
    await t.pumpWidget(_wrap(s, const SoalListScreen()));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('KotaLaju'), findsOneWidget);
    for (final q in soalTetap) {
      final card = find.text(q.judul);
      await t.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).first);
      expect(card, findsOneWidget);
    }
    expect(find.text('Kuis'), findsNothing);
    await t.tap(find.text(soalTetap.last.judul));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Soal 7: ${soalTetap.last.judul}'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('semua distrik dapat dibuka', (t) async {
    final s = await _state();
    for (final d in districts) {
      await t.pumpWidget(_wrap(s, DistrictScreen(districtId: d.id)));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text(d.segments.first.title), findsOneWidget);
    }
  });

  testWidgets('semua animasi dapat diputar', (t) async {
    final s = await _state();
    for (final id in ['markers', 'headon', 'catchup', 'ladder', 'kmh2ms', 'timewheel', 'pizza', 'clockgap']) {
      await t.pumpWidget(_wrap(s, Scaffold(body: SingleChildScrollView(child: buildLessonAnimation(id)))));
      final play = find.byTooltip('Putar');
      if (play.evaluate().isNotEmpty) {
        await t.tap(play);
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(seconds: 1));
        }
      }
      expect(t.takeException(), isNull, reason: id);
    }
  });

  testWidgets('alur 5 langkah untuk ke-7 soal (mode latihan dan tes)', (t) async {
    final s = await _state();
    for (final q in soalTetap) {
      final id = 'soal${q.no}';
      for (final mode in [SessionMode.practice, SessionMode.test]) {
        final p = q.problem;
        await t.pumpWidget(_wrap(
          s,
          Scaffold(body: ProblemSessionView(key: ValueKey('$id-$mode'), problem: p, mode: mode, recordContext: 'practice', onFinished: (_) {})),
        ));
        await t.pump();
        // Langkah 1: tandai semua token dengan jawaban benar.
        for (final tok in p.tokens) {
          final token = find.text(tok.text).first;
          await t.ensureVisible(token);
          await t.pump();
          await t.tap(token);
          await t.pump();
          final chip = find.widgetWithText(ActionChip, tok.kind.label);
          await t.ensureVisible(chip);
          await t.pump();
          await t.tap(chip);
          await t.pump();
        }
        // Semua token harus tertandai benar sebelum diperiksa.
        expect(find.byIcon(Icons.block), p.tokens.any((x) => x.kind.name == 'irrelevant') ? findsWidgets : findsNothing);
        await t.tap(find.text(mode == SessionMode.test ? 'Simpan & lanjut' : 'Periksa'));
        await t.pump();
        expect(t.takeException(), isNull, reason: '$id $mode');
      }
    }
  });

  testWidgets('contoh terselesaikan & tes awal', (t) async {
    final s = await _state();
    await t.pumpWidget(_wrap(s, WorkedExampleScreen(problem: soal(3))));
    await t.pump();
    for (var i = 0; i < 6; i++) {
      final btn = find.text('Langkah berikutnya');
      if (btn.evaluate().isEmpty) break;
      await t.tap(btn);
      await t.pump();
    }
    expect(find.text('Saya mengerti ✓'), findsOneWidget);
    await t.pumpWidget(_wrap(s, const TestScreen(kind: TestKind.pretest)));
    await t.pump();
    expect(find.text('Mulai Tes Awal'), findsOneWidget);
  });

  testWidgets('kelima game dapat dimulai', (t) async {
    final s = await _state();
    final gamesUnderTest = <Widget>[
      const UnitRallyGame(tier: 1),
      const MeetingPointGame(tier: 3),
      const CatchBusGame(tier: 2),
      const CourierRouteGame(tier: 2),
      const TrafficDetectiveGame(tier: 1),
    ];
    for (final g in gamesUnderTest) {
      await t.pumpWidget(_wrap(s, g));
      await t.pump(const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: g.runtimeType.toString());
    }
    await t.pumpWidget(_wrap(s, const UnitRallyGame(tier: 3)));
    await t.tap(find.text('Mulai!'));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('mode guru tampil', (t) async {
    final s = await _state();
    await t.pumpWidget(_wrap(s, const TeacherScreen()));
    await t.pump();
    await t.scrollUntilVisible(find.text('Ekspor data (CSV)'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Ekspor data (CSV)'), findsOneWidget);
  });
}
