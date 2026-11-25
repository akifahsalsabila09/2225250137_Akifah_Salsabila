import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/drills.dart';
import '../../core/domain/problem.dart';
import '../../core/domain/soal_tetap.dart';
import '../../core/widgets/common.dart';
import '../garage/radar_chart.dart';
import '../problem/problem_session.dart';
import '../problem/series.dart';

enum TestKind { pretest, posttest }

/// Tes Awal dan Ujian Kota memakai 4 soal kisi-kisi yang sama persis
/// (satu per indikator Mathematical Literacy, skor maksimal 24).
List<Problem> testProblems(TestKind kind) => soalKisiKisi();

class TestScreen extends StatelessWidget {
  final TestKind kind;
  const TestScreen({super.key, required this.kind});

  bool _done(AppState s) => kind == TestKind.pretest ? s.pretestDone : s.posttestDone;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final isPre = kind == TestKind.pretest;
    final title = isPre ? '🚏 Terminal Awal: Tes Awal' : '🏛️ Balai Kota: Ujian Kota';
    return FocusScaffold(
      title: title,
      body: _done(s) ? _results(context, s) : _intro(context, s),
    );
  }

  Widget _intro(BuildContext context, AppState s) {
    final isPre = kind == TestKind.pretest;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isPre ? 'Sebelum berkeliling kota, ayo kenali kemampuanmu dulu.' : 'Kamu sudah menjelajahi semua distrik. Saatnya Ujian Kota!',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPre) const _Bullet('6 soal singkat tentang jam dan pecahan'),
                const _Bullet('4 soal cerita dari kisi-kisi (skor maksimal 24)'),
                const _Bullet('Tanpa petunjuk dan tanpa kalkulator satuan'),
                const _Bullet('Tidak ada batas waktu. Kerjakan dengan tenang.'),
                const _Bullet('Nilainya tidak mengurangi koinmu.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _run(context, s),
          icon: const Icon(Icons.play_arrow),
          label: Text(isPre ? 'Mulai Tes Awal' : 'Mulai Ujian Kota'),
        ),
        if (isPre) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti saja'),
          ),
        ],
      ],
    );
  }

  Future<void> _run(BuildContext context, AppState s) async {
    final nav = Navigator.of(context);
    if (kind == TestKind.pretest && s.prereqScore == null) {
      final score = await nav.push<int>(MaterialPageRoute(
        builder: (_) => QuickSeriesScreen(title: 'Tes Awal: Jam & Pecahan', questions: Prerequisites.diagnostic(), showFeedback: false),
      ));
      if (score == null) return;
      s.setPrereqScore(score);
    }
    if (!context.mounted) return;
    final res = await ProblemSeriesScreen.open(
      context,
      title: kind == TestKind.pretest ? 'Tes Awal' : 'Ujian Kota',
      problems: testProblems(kind),
      mode: SessionMode.test,
      recordContext: kind.name,
      askEffort: true,
    );
    if (res == null || res.length < 4 || !context.mounted) return;
    final total = res.fold<int>(0, (a, r) => a + r.score);
    await showCelebration(
      context,
      title: kind == TestKind.pretest ? 'Tes Awal selesai!' : 'Ujian Kota selesai!',
      subtitle: 'Skormu $total dari 24.${kind == TestKind.pretest && s.recommendMenaraJam ? '\nMulai dari Menara Jam, ya.' : ''}',
      hero: const Text('🎉', style: TextStyle(fontSize: 64)),
    );
  }

  Widget _results(BuildContext context, AppState s) {
    final isPre = kind == TestKind.pretest;
    final by = isPre ? s.pretestByIndicator! : s.posttestByIndicator!;
    final total = by.values.fold<int>(0, (a, b) => a + b);
    final pre = s.pretestByIndicator;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(child: Text('$total / 24', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.distance))),
        Center(child: Text(isPre ? 'Skor Tes Awal' : 'Skor Ujian Kota')),
        if (isPre && s.prereqScore != null)
          Center(child: Text('Jam & pecahan: ${s.prereqScore} / 6', style: const TextStyle(fontWeight: FontWeight.w700))),
        const SizedBox(height: 16),
        Center(
          child: RadarChart(
            values: {for (final i in Indicator.values) i: (by[i] ?? 0) / 6},
            compare: !isPre && pre != null ? {for (final i in Indicator.values) i: (pre[i] ?? 0) / 6} : null,
            size: 240,
          ),
        ),
        if (!isPre && pre != null)
          const Center(child: Text('Garis putus-putus = Tes Awal', style: TextStyle(fontSize: 12))),
        const SizedBox(height: 12),
        for (final i in Indicator.values)
          ListTile(
            title: Text('${i.en} (${i.id})', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: LinearProgressIndicator(value: (by[i] ?? 0) / 6, minHeight: 8, borderRadius: BorderRadius.circular(8)),
            trailing: Text(!isPre && pre != null ? '${pre[i] ?? 0} → ${by[i] ?? 0}' : '${by[i] ?? 0}/6',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        if (!isPre && s.nGain != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.trending_up, color: AppColors.right, size: 32),
              title: Text('Peningkatan (N-gain): ${s.nGain!.toStringAsFixed(2).replaceAll('.', ',')}'),
              subtitle: Text(s.nGain! >= 0.7 ? 'Tinggi' : s.nGain! >= 0.3 ? 'Sedang' : 'Rendah'),
            ),
          ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.check_circle, color: AppColors.right, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ]),
      );
}
