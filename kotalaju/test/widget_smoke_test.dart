import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotalaju/app/theme.dart';
import 'package:kotalaju/core/data/app_state.dart';
import 'package:kotalaju/core/data/content.dart';
import 'package:kotalaju/core/domain/motion.dart';
import 'package:kotalaju/core/domain/problem_bank.dart';
import 'package:kotalaju/features/games/catch_bus_game.dart';
import 'package:kotalaju/features/games/courier_route_game.dart';
import 'package:kotalaju/features/games/meeting_point_game.dart';
import 'package:kotalaju/features/games/traffic_detective_game.dart';
import 'package:kotalaju/features/games/unit_rally_game.dart';
import 'package:kotalaju/features/lesson/animations.dart';
import 'package:kotalaju/features/lesson/district_screen.dart';
import 'package:kotalaju/features/home/home_shell.dart';
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

Widget _wrap(AppState s, Widget child) =>
    AppScope(state: s, child: MaterialApp(theme: buildTheme(), home: child));

void main() {
  setUp(() {
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
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Kenalan dulu, yuk'), findsOneWidget);
  });

  testWidgets('beranda: peta, arena, kuis, garasi', (t) async {
    final s = await _state();
    await t.pumpWidget(_wrap(s, const HomeShell()));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('KotaLaju'), findsOneWidget);
    for (final tab in ['Arena', 'Kuis', 'Garasi', 'Peta']) {
      await t.tap(find.text(tab));
      await t.pump(const Duration(milliseconds: 500));
    }
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

  testWidgets('alur 5 langkah untuk setiap templat (mode latihan dan tes)', (t) async {
    final s = await _state();
    for (final id in ProblemBank.templates.keys) {
      for (final mode in [SessionMode.practice, SessionMode.test]) {
        final p = ProblemBank.generate(id, level: 2, seed: 3);
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
    await t.pumpWidget(_wrap(s, WorkedExampleScreen(problem: ProblemBank.generate('berpapasan', level: 1, seed: 7))));
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
