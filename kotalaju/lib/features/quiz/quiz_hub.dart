import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/data/content.dart';
import '../../core/domain/problem.dart';
import '../../core/domain/problem_bank.dart';
import '../problem/problem_session.dart';
import '../problem/series.dart';
import 'test_screen.dart';

/// Stasiun Kuis: kuis distrik, latihan campur, tes awal, ujian kota, riwayat.
class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final doneDistricts = districts.where((d) => s.doneDistricts.contains(d.id) && d.quizTemplates.isNotEmpty).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('📝 Stasiun Kuis', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            icon: '🚏',
            title: 'Tes Awal',
            subtitle: s.pretestDone ? 'Skor ${s.pretestScore}/24' : 'Belum dikerjakan',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestScreen(kind: TestKind.pretest))),
          ),
          const SizedBox(height: 8),
          const Text('Kuis Distrik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          if (doneDistricts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Selesaikan distrik di peta kota untuk membuka kuisnya.'),
            ),
          for (final d in doneDistricts)
            _card(
              context,
              icon: d.icon,
              title: 'Kuis ${d.name}',
              subtitle: '5 soal literasi • umpan balik per langkah',
              onTap: () => _districtQuiz(context, d),
            ),
          const SizedBox(height: 8),
          const Text('Latihan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          _card(
            context,
            icon: '🔀',
            title: 'Latihan Campur',
            subtitle: '4 soal: satu dari tiap kemampuan literasi',
            enabled: s.doneDistricts.contains('bundaran_jkw'),
            onTap: () => _mixed(context, s),
          ),
          const SizedBox(height: 8),
          _card(
            context,
            icon: '🏛️',
            title: 'Ujian Kota',
            subtitle: s.posttestDone
                ? 'Skor ${s.posttestScore}/24'
                : (s.postTestOpen ? 'Siap dikerjakan!' : 'Terbuka setelah Simpang Berpapasan & Jalur Susul'),
            enabled: s.postTestOpen,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestScreen(kind: TestKind.posttest))),
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            title: const Text('Riwayat', style: TextStyle(fontWeight: FontWeight.w900)),
            children: [
              for (final a in s.attempts.reversed.take(30))
                ListTile(
                  dense: true,
                  leading: Icon(a.maxScore > 0 && a.score / a.maxScore >= 0.66 ? Icons.check_circle : Icons.timelapse,
                      color: a.maxScore > 0 && a.score / a.maxScore >= 0.66 ? AppColors.right : AppColors.speed),
                  title: Text('${ProblemBank.templates[a.templateId]?.title ?? a.templateId} • ${a.indicator.en}'),
                  subtitle: Text('${_ctxLabel(a.context)} • ${a.finishedAt.day}/${a.finishedAt.month}'),
                  trailing: Text('${a.score}/${a.maxScore}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _ctxLabel(String c) => switch (c) {
        'practice' => 'Latihan',
        'completion' => 'Contoh setengah jadi',
        'checkpoint' => 'Checkpoint',
        'district_quiz' => 'Kuis distrik',
        'mixed' => 'Latihan campur',
        'pretest' => 'Tes Awal',
        'posttest' => 'Ujian Kota',
        _ => c,
      };

  Widget _card(BuildContext context,
      {required String icon, required String title, required String subtitle, VoidCallback? onTap, bool enabled = true}) {
    return Card(
      child: ListTile(
        enabled: enabled,
        minVerticalPadding: 14,
        leading: Text(icon, style: TextStyle(fontSize: 34, color: enabled ? null : Colors.black26)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        subtitle: Text(subtitle),
        trailing: Icon(enabled ? Icons.chevron_right : Icons.lock),
        onTap: enabled ? onTap : null,
      ),
    );
  }

  void _districtQuiz(BuildContext context, District d) {
    final s = AppScope.read(context);
    final rnd = Random();
    final level = s.adaptive.levelFor(StepKind.compute) >= 3 ? 3 : 2;
    final ps = [
      for (var k = 0; k < 5; k++)
        ProblemBank.generate(d.quizTemplates[k % d.quizTemplates.length], level: level, seed: rnd.nextInt(1 << 30)),
    ];
    ProblemSeriesScreen.open(context,
        title: 'Kuis ${d.name}', problems: ps, mode: SessionMode.quiz, recordContext: 'district_quiz', askEffort: true);
  }

  void _mixed(BuildContext context, AppState s) {
    final rnd = Random();
    final available = <String>{
      for (final d in districts)
        if (s.doneDistricts.contains(d.id)) ...d.quizTemplates,
    };
    final ps = <Problem>[];
    for (final i in Indicator.values) {
      final ids = ProblemBank.byIndicator(i).where(available.contains).toList();
      final pool = ids.isEmpty ? ProblemBank.byIndicator(i).where((id) => id != 'berpapasan' && id != 'menyusul').toList() : ids;
      ps.add(ProblemBank.generate(pool[rnd.nextInt(pool.length)], level: 2, seed: rnd.nextInt(1 << 30)));
    }
    ProblemSeriesScreen.open(context, title: 'Latihan Campur', problems: ps, mode: SessionMode.practice, recordContext: 'mixed');
  }
}
