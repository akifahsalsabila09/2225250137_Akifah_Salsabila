import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/motion.dart';
import '../../core/domain/soal_tetap.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/vehicle.dart';
import '../problem/problem_session.dart';
import '../teacher/settings_screen.dart';

/// Layar utama: hanya berisi 7 soal.
class SoalListScreen extends StatelessWidget {
  const SoalListScreen({super.key});

  static int? bestScore(AppState s, String problemId) {
    final list = s.attempts.where((a) => a.problemId == problemId && a.maxScore == 6).toList();
    if (list.isEmpty) return null;
    return list.map((a) => a.score).reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final done = soalTetap.where((q) => bestScore(s, q.problem.id) != null).length;
    return Scaffold(
      body: CityBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('KotaLaju', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.ink)),
                  ),
                  IconButton(
                    tooltip: 'Pengaturan',
                    icon: const Icon(Icons.settings, color: AppColors.ink),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                ],
              ),
              Text('Halo, ${s.profile?.nickname ?? ''}! Ayo kerjakan 7 soal jarak, kecepatan, dan waktu.',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$done dari 7 soal sudah dikerjakan', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: done / 7,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.right,
                      backgroundColor: const Color(0xFFE8E8E8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final q in soalTetap) _SoalCard(q: q, best: bestScore(s, q.problem.id)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoalCard extends StatelessWidget {
  final SoalTetap q;
  final int? best;
  const _SoalCard({required this.q, required this.best});

  @override
  Widget build(BuildContext context) {
    final p = q.problem;
    final vehicle = p.scene.movers.isNotEmpty ? p.scene.movers.first.vehicle : VehicleType.car;
    final stars = best == null ? 0 : (best! >= 6 ? 3 : best! >= 4 ? 2 : best! >= 2 ? 1 : 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SoalScreen(no: q.no))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: best == null ? AppColors.taxi : AppColors.right,
                  child: Text('${q.no}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: best == null ? AppColors.ink : Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q.judul, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StarRow(stars: stars, size: 18),
                          Text(best == null ? 'Belum dikerjakan' : 'Skor terbaik $best/6',
                              style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                ),
                VehicleView(type: vehicle, width: 62),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Layar mengerjakan satu soal (Alur 5 Langkah, dengan petunjuk dan boleh mencoba lagi).
class SoalScreen extends StatelessWidget {
  final int no;
  const SoalScreen({super.key, required this.no});

  @override
  Widget build(BuildContext context) {
    final q = soalTetap[no - 1];
    return FocusScaffold(
      title: 'Soal $no: ${q.judul}',
      body: ProblemSessionView(
        key: ValueKey('soal-$no'),
        problem: q.problem,
        mode: SessionMode.practice,
        recordContext: 'soal',
        askEffort: AppScope.read(context).mentalEffortEnabled,
        finishLabel: no < 7 ? 'Lanjut ke Soal ${no + 1} →' : 'Kembali ke daftar soal',
        onFinished: (rec) {
          AppScope.read(context).recordAttempt(rec);
          final nav = Navigator.of(context);
          if (no < 7) {
            nav.pushReplacement(MaterialPageRoute(builder: (_) => SoalScreen(no: no + 1)));
          } else {
            nav.pop();
          }
        },
      ),
    );
  }
}
