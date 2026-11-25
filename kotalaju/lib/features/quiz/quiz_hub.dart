import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/soal_tetap.dart';
import '../problem/problem_session.dart';
import '../problem/series.dart';
import 'test_screen.dart';

/// Stasiun Kuis: paket 7 soal tetap, Tes Awal, Ujian Kota, riwayat.
class QuizHubScreen extends StatelessWidget {
  const QuizHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final quizOpen = s.doneDistricts.contains('bundaran_jkw');
    return Scaffold(
      appBar: AppBar(title: const Text('📝 Stasiun Kuis', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _card(
            context,
            icon: '🚏',
            title: 'Tes Awal',
            subtitle: s.pretestDone ? 'Skor ${s.pretestScore}/24' : '4 soal kisi-kisi • belum dikerjakan',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestScreen(kind: TestKind.pretest))),
          ),
          const SizedBox(height: 8),
          const Text('Kuis 7 Soal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          _card(
            context,
            icon: '📝',
            title: 'Kuis (7 soal)',
            subtitle: quizOpen ? 'Satu kali jawab per langkah, dengan umpan balik' : 'Terbuka setelah SIM Bundaran JKW',
            enabled: quizOpen,
            onTap: () => ProblemSeriesScreen.open(context,
                title: 'Kuis', problems: semuaSoal(), mode: SessionMode.quiz, recordContext: 'district_quiz', askEffort: true),
          ),
          _card(
            context,
            icon: '💡',
            title: 'Latihan (7 soal)',
            subtitle: 'Boleh mencoba lagi dan membuka petunjuk',
            enabled: quizOpen,
            onTap: () => ProblemSeriesScreen.open(context,
                title: 'Latihan', problems: semuaSoal(), mode: SessionMode.practice, recordContext: 'mixed'),
          ),
          const SizedBox(height: 4),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Daftar soal', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  for (final q in soalTetap)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(radius: 14, child: Text('${q.no}')),
                      title: Text(q.judul),
                      subtitle: Text('${q.problem.indicator.en}${q.dariKisiKisi ? ' • kisi-kisi' : ''}'),
                      trailing: Text(_best(s, q.problem.id), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _card(
            context,
            icon: '🏛️',
            title: 'Ujian Kota',
            subtitle: s.posttestDone
                ? 'Skor ${s.posttestScore}/24'
                : (s.postTestOpen ? '4 soal kisi-kisi • siap dikerjakan!' : 'Terbuka setelah SIM Halte Transit'),
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
                  title: Text(labelSoal(a.problemId)),
                  subtitle: Text('${_ctxLabel(a.context)} • ${a.finishedAt.day}/${a.finishedAt.month}'),
                  trailing: Text('${a.score}/${a.maxScore}', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Skor terbaik siswa untuk satu soal (dari kuis, checkpoint, dan tes).
  static String _best(AppState s, String problemId) {
    final list = s.attempts.where((a) => a.problemId == problemId && a.maxScore == 6).toList();
    if (list.isEmpty) return '–';
    final best = list.map((a) => a.score).reduce((a, b) => a > b ? a : b);
    return '$best/6';
  }

  static String _ctxLabel(String c) => switch (c) {
        'practice' => 'Latihan',
        'completion' => 'Contoh setengah jadi',
        'checkpoint' => 'Checkpoint',
        'district_quiz' => 'Kuis',
        'mixed' => 'Latihan',
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
}
