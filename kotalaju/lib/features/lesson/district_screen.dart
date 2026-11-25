import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/data/content.dart';
import '../../core/domain/drills.dart';
import '../../core/domain/problem.dart';
import '../../core/domain/problem_bank.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/jkw_triangle.dart';
import '../../core/widgets/story_view.dart';
import '../../core/widgets/unit_calculator.dart';
import '../../core/widgets/vehicle.dart';
import '../problem/problem_session.dart';
import '../problem/series.dart';
import 'animations.dart';

class DistrictScreen extends StatelessWidget {
  final String districtId;
  const DistrictScreen({super.key, required this.districtId});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final d = districtById(districtId);
    final done = state.doneDistricts.contains(d.id);
    return FocusScaffold(
      title: '${d.icon} ${d.name}',
      actions: [
        IconButton(
          tooltip: 'Ringkasan distrik',
          icon: const Icon(Icons.summarize),
          onPressed: () => _showSummary(context, d),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(d.tagline, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          if (done)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Chip(avatar: Icon(Icons.verified, color: AppColors.right), label: Text('SIM distrik sudah didapat')),
            ),
          const SizedBox(height: 10),
          for (var i = 0; i < d.segments.length; i++) _segmentTile(context, state, d, i),
        ],
      ),
    );
  }

  Widget _segmentTile(BuildContext context, AppState state, District d, int i) {
    final seg = d.segments[i];
    final segDone = state.segmentDone(d.id, i);
    final open = i == 0 || state.segmentDone(d.id, i - 1) || segDone;
    final icon = switch (seg) {
      AnimSegment() => Icons.play_circle_fill,
      TriangleSegment() => Icons.change_history,
      WorkedSegment() => Icons.menu_book,
      CompletionSegment() => Icons.edit_note,
      PracticeSegment() => Icons.fitness_center,
      CheckpointSegment() => Icons.flag,
      DrillSegment() => Icons.build,
      QuickSegment(isCheckpoint: final c) => c ? Icons.flag : Icons.quiz,
      CalculatorSegment() => Icons.calculate,
      ReadingToolsSegment() => Icons.highlight,
    };
    final kind = switch (seg) {
      AnimSegment() => 'Animasi',
      TriangleSegment() => 'Alat interaktif',
      WorkedSegment() => 'Contoh terselesaikan',
      CompletionSegment() => 'Contoh setengah jadi',
      PracticeSegment() => 'Latihan mandiri',
      CheckpointSegment() => 'Checkpoint',
      DrillSegment() => 'Latihan konversi',
      QuickSegment(isCheckpoint: final c) => c ? 'Checkpoint' : 'Latihan singkat',
      CalculatorSegment() => 'Alat bantu',
      ReadingToolsSegment() => 'Alat membaca soal',
    };
    return Card(
      child: ListTile(
        enabled: open,
        minVerticalPadding: 14,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: segDone ? AppColors.right : (open ? AppColors.taxi : const Color(0xFFE0E0E0)),
          child: Icon(segDone ? Icons.check : (open ? icon : Icons.lock), color: segDone ? Colors.white : AppColors.ink),
        ),
        title: Text(seg.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        subtitle: Text(kind),
        trailing: open ? const Icon(Icons.chevron_right) : null,
        onTap: open ? () => _openSegment(context, d, i) : null,
      ),
    );
  }

  static void _showSummary(BuildContext context, District d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.focusBg,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ringkasan ${d.name}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              for (final s in d.summary)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: AppColors.right),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSegment(BuildContext context, District d, int i) async {
    final state = AppScope.read(context);
    final seg = d.segments[i];
    final nav = Navigator.of(context);
    final rnd = Random();
    bool completed = false;
    bool isCheckpoint = false;

    switch (seg) {
      case AnimSegment():
        completed = await nav.push<bool>(MaterialPageRoute(builder: (_) => AnimSegmentScreen(segment: seg))) ?? false;
      case TriangleSegment():
        completed = await nav.push<bool>(MaterialPageRoute(builder: (_) => const TriangleScreen())) ?? false;
      case WorkedSegment():
        final p = ProblemBank.generate(seg.templateId, level: seg.level, seed: seg.seed);
        completed = await nav.push<bool>(MaterialPageRoute(builder: (_) => WorkedExampleScreen(problem: p))) ?? false;
      case CompletionSegment():
        final p = ProblemBank.generate(seg.templateId, level: seg.level, seed: seg.seed);
        final res = await ProblemSeriesScreen.open(context,
            title: seg.title, problems: [p], mode: SessionMode.completion, recordContext: 'completion');
        completed = (res?.length ?? 0) == 1;
      case PracticeSegment():
        final ps = [
          for (var k = 0; k < seg.count; k++)
            ProblemBank.generate(seg.templateIds[k % seg.templateIds.length], level: seg.level, seed: rnd.nextInt(1 << 30)),
        ];
        final res = await ProblemSeriesScreen.open(context,
            title: seg.title, problems: ps, mode: SessionMode.practice, recordContext: 'practice');
        completed = (res?.length ?? 0) == seg.count;
      case CheckpointSegment():
        isCheckpoint = true;
        final ps = [
          for (var k = 0; k < seg.count; k++)
            ProblemBank.generate(seg.templateIds[k % seg.templateIds.length], level: seg.level, seed: rnd.nextInt(1 << 30)),
        ];
        final res = await ProblemSeriesScreen.open(context,
            title: seg.title, problems: ps, mode: SessionMode.quiz, recordContext: 'checkpoint', askEffort: true);
        if (res != null && res.length == seg.count) {
          final passed = res.where((a) => a.maxScore > 0 && a.score / a.maxScore >= 0.66).length;
          completed = passed >= seg.passMin;
          if (!completed && context.mounted) {
            await _notPassed(context, passed, seg.passMin);
          }
        }
      case DrillSegment():
        final correct = await nav.push<int>(MaterialPageRoute(builder: (_) => DrillSeriesScreen(count: seg.count, level: seg.level)));
        completed = correct != null;
      case QuickSegment():
        isCheckpoint = seg.isCheckpoint;
        final qs = Prerequisites.practice(rnd.nextInt(1 << 30), seg.count);
        final correct = await nav.push<int>(MaterialPageRoute(builder: (_) => QuickSeriesScreen(title: seg.title, questions: qs)));
        if (correct != null) {
          completed = !seg.isCheckpoint || correct >= (seg.count * 0.8).ceil();
          if (!completed && context.mounted) await _notPassed(context, correct, (seg.count * 0.8).ceil());
        }
      case CalculatorSegment():
        completed = await nav.push<bool>(MaterialPageRoute(builder: (_) => const CalculatorScreen())) ?? false;
      case ReadingToolsSegment():
        completed = await nav.push<bool>(MaterialPageRoute(builder: (_) => const ReadingToolsScreen())) ?? false;
    }

    if (!completed) return;
    state.markSegment(d.id, i);
    if (isCheckpoint && i == d.segments.length - 1 && !state.doneDistricts.contains(d.id)) {
      final newVehicle = state.completeDistrict(d.id);
      if (!context.mounted) return;
      await showCelebration(
        context,
        title: 'SIM ${d.name} didapat!',
        subtitle: [
          '+20 koin',
          if (newVehicle != null) 'Kendaraan baru: ${newVehicle.label}!',
          for (final g in games.where((g) => g.unlockedBy == d.id)) 'Game baru: ${g.name}',
        ].join('\n'),
        hero: Column(children: [
          SimCard(district: d.name, name: state.profile?.nickname ?? ''),
          if (newVehicle != null) Padding(padding: const EdgeInsets.only(top: 10), child: VehicleView(type: newVehicle, width: 110)),
        ]),
      );
    }
  }

  static Future<void> _notPassed(BuildContext context, int got, int need) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hampir!'),
          content: Text('Kamu lolos $got soal. Butuh $need untuk dapat SIM. '
              'Ulangi contoh dan latihan dulu, lalu coba lagi checkpoint-nya.'),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Oke'))],
        ),
      );
}

class AnimSegmentScreen extends StatefulWidget {
  final AnimSegment segment;
  const AnimSegmentScreen({super.key, required this.segment});
  @override
  State<AnimSegmentScreen> createState() => _AnimSegmentScreenState();
}

class _AnimSegmentScreenState extends State<AnimSegmentScreen> {
  @override
  Widget build(BuildContext context) {
    return FocusScaffold(
      title: widget.segment.title,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.segment.intro, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 14),
          buildLessonAnimation(widget.segment.animId),
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Selesai ✓')),
      ),
    );
  }
}

class TriangleScreen extends StatelessWidget {
  const TriangleScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return FocusScaffold(
      title: 'Segitiga JKW',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('J di atas, K dan W di bawah. Tutup huruf yang dicari, lalu lihat sisanya.',
              style: TextStyle(fontSize: 17)),
          const SizedBox(height: 6),
          const Text('Atas-bawah: dibagi. Kiri-kanan: dikali.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Center(child: JkwTriangle(size: 260, onPick: (_) => AppScope.read(context).logTool('jkw_triangle'))),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Cek Logika: kalau kecepatan makin besar, waktunya makin singkat. '
                'Kalau hasil hitunganmu berlawanan, pasti ada yang salah.',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Selesai ✓')),
      ),
    );
  }
}

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return FocusScaffold(
      title: 'Kalkulator Satuan',
      body: const UnitCalculator(),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Selesai ✓')),
      ),
    );
  }
}

/// Pengenalan Penanda Info + Kamus Jalan (K03, EL01, EL05).
class ReadingToolsScreen extends StatefulWidget {
  const ReadingToolsScreen({super.key});
  @override
  State<ReadingToolsScreen> createState() => _ReadingToolsScreenState();
}

class _ReadingToolsScreenState extends State<ReadingToolsScreen> {
  late final Problem _p = ProblemBank.generate('menyusul', level: 2, seed: 5);
  final Map<String, TagKind> _revealed = {};

  @override
  Widget build(BuildContext context) {
    return FocusScaffold(
      title: 'Penanda Info & Kamus Jalan',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Setiap jenis angka punya warna dan ikon sendiri:', style: TextStyle(fontSize: 17)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in TagKind.values)
              Chip(
                avatar: Icon(k.icon, color: k.color),
                label: Text(k.label),
                side: BorderSide(color: k.color, width: 2),
              ),
          ]),
          const SizedBox(height: 14),
          const Text('Ketuk angka di soal ini untuk melihat jenisnya. Ketuk kata bergaris bawah untuk membuka Kamus Jalan.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: StoryView(
              story: _p.story,
              tags: _revealed,
              onTokenTap: (id) => setState(() => _revealed[id] = _p.tokens.firstWhere((t) => t.id == id).kind),
            ),
          ),
          const SizedBox(height: 14),
          const FeedbackPanel(
            correct: true,
            message: 'Perhatikan: "pukul 07.00" adalah JAM (ungu), bukan lama perjalanan. '
                'Lama perjalanan (hijau) biasanya ditulis "30 menit" atau "2 jam".',
          ),
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Selesai ✓')),
      ),
    );
  }
}
