import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/data/models.dart';
import '../../core/domain/drills.dart';
import '../../core/domain/format.dart';
import '../../core/domain/problem.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/road_scene.dart';
import '../../core/widgets/story_view.dart';
import 'problem_session.dart';

/// Rangkaian soal (latihan, checkpoint, kuis, tes). Mengembalikan daftar AttemptRecord.
class ProblemSeriesScreen extends StatefulWidget {
  final String title;
  final List<Problem> problems;
  final SessionMode mode;
  final String recordContext;
  final bool askEffort;

  const ProblemSeriesScreen({
    super.key,
    required this.title,
    required this.problems,
    required this.mode,
    required this.recordContext,
    this.askEffort = false,
  });

  static Future<List<AttemptRecord>?> open(
    BuildContext context, {
    required String title,
    required List<Problem> problems,
    required SessionMode mode,
    required String recordContext,
    bool askEffort = false,
  }) {
    return Navigator.of(context).push<List<AttemptRecord>>(MaterialPageRoute(
      builder: (_) => ProblemSeriesScreen(
        title: title,
        problems: problems,
        mode: mode,
        recordContext: recordContext,
        askEffort: askEffort,
      ),
    ));
  }

  @override
  State<ProblemSeriesScreen> createState() => _ProblemSeriesScreenState();
}

class _ProblemSeriesScreenState extends State<ProblemSeriesScreen> {
  int _i = 0;
  final List<AttemptRecord> _done = [];

  Future<bool> _confirmLeave() async {
    if (_done.length == widget.problems.length) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dulu?'),
        content: const Text('Soal yang sudah selesai tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Lanjut mengerjakan')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.problems[_i];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        if (await _confirmLeave()) nav.pop(_done);
      },
      child: FocusScaffold(
        title: '${widget.title}  ${_i + 1}/${widget.problems.length}',
        body: ProblemSessionView(
          key: ValueKey('${p.id}-$_i'),
          problem: p,
          mode: widget.mode,
          recordContext: widget.recordContext,
          askEffort: widget.askEffort && AppScope.read(context).mentalEffortEnabled,
          finishLabel: _i == widget.problems.length - 1 ? 'Selesai' : 'Soal berikutnya →',
          onFinished: (rec) {
            AppScope.read(context).recordAttempt(rec);
            _done.add(rec);
            if (_i == widget.problems.length - 1) {
              Navigator.of(context).pop(_done);
            } else {
              setState(() => _i++);
            }
          },
        ),
      ),
    );
  }
}

/// Contoh terselesaikan (worked example): langkah dibuka satu per satu oleh siswa.
class WorkedExampleScreen extends StatefulWidget {
  final Problem problem;
  const WorkedExampleScreen({super.key, required this.problem});

  @override
  State<WorkedExampleScreen> createState() => _WorkedExampleScreenState();
}

class _WorkedExampleScreenState extends State<WorkedExampleScreen> {
  int _shown = 1;

  @override
  Widget build(BuildContext context) {
    final p = widget.problem;
    final done = _shown >= p.solution.length;
    return FocusScaffold(
      title: 'Contoh: ${p.title}',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RoadSceneView(scene: p.scene, height: 150),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8E1D0)),
            ),
            child: StoryView(story: p.story, revealTruth: true),
          ),
          const SizedBox(height: 14),
          const Text('Penyelesaian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          for (var i = 0; i < _shown && i < p.solution.length; i++)
            Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.distance, child: Text('${i + 1}', style: const TextStyle(color: Colors.white))),
                title: Text(p.solution[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton(
          onPressed: done ? () => Navigator.pop(context, true) : () => setState(() => _shown++),
          child: Text(done ? 'Saya mengerti ✓' : 'Langkah berikutnya'),
        ),
      ),
    );
  }
}

/// Rangkaian soal konversi pilihan ganda (Bengkel Satuan).
class DrillSeriesScreen extends StatefulWidget {
  final int count;
  final int level;
  const DrillSeriesScreen({super.key, required this.count, required this.level});

  @override
  State<DrillSeriesScreen> createState() => _DrillSeriesScreenState();
}

class _DrillSeriesScreenState extends State<DrillSeriesScreen> {
  final _seed = Random().nextInt(1 << 30);
  int _i = 0;
  int? _pick;
  int _correct = 0;

  @override
  Widget build(BuildContext context) {
    final lvl = widget.level == 2 && _i >= widget.count - 2 ? 3 : widget.level;
    final d = UnitDrill.generate(lvl, _seed + _i);
    final answered = _pick != null;
    final ok = _pick == d.correct;
    return FocusScaffold(
      title: 'Latihan Konversi ${_i + 1}/${widget.count}',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(d.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.time)),
          const SizedBox(height: 16),
          for (var k = 0; k < d.options.length; k++)
            OptionTile(
              text: '${fmtNum(d.options[k], maxDecimals: 3)} ${d.target.label}',
              selected: _pick == k,
              showCorrect: answered ? k == d.correct : null,
              onTap: answered
                  ? null
                  : () {
                      setState(() => _pick = k);
                      if (k == d.correct) {
                        _correct++;
                        AppScope.read(context).bump('unit_correct');
                      }
                    },
            ),
          if (answered) ...[
            const SizedBox(height: 10),
            FeedbackPanel(correct: ok, message: ok ? 'Tepat!' : d.wrongCodes[_pick]?.message ?? 'Belum tepat.', error: ok ? null : d.wrongCodes[_pick]),
            const SizedBox(height: 8),
            for (final s in d.explanation)
              Card(
                child: ListTile(
                  title: Text(s.description),
                  subtitle: Text(s.expression, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.time)),
                ),
              ),
          ],
        ],
      ),
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: FilledButton(
          onPressed: !answered
              ? null
              : () {
                  if (_i == widget.count - 1) {
                    Navigator.pop(context, _correct);
                  } else {
                    setState(() {
                      _i++;
                      _pick = null;
                    });
                  }
                },
          child: Text(_i == widget.count - 1 ? 'Selesai' : 'Berikutnya →'),
        ),
      ),
    );
  }
}

/// Soal prasyarat singkat (Menara Jam, diagnostik awal).
class QuickSeriesScreen extends StatefulWidget {
  final String title;
  final List<QuickQuestion> questions;
  final bool showFeedback;
  const QuickSeriesScreen({super.key, required this.title, required this.questions, this.showFeedback = true});

  @override
  State<QuickSeriesScreen> createState() => _QuickSeriesScreenState();
}

class _QuickSeriesScreenState extends State<QuickSeriesScreen> {
  int _i = 0;
  int? _pick;
  int _correct = 0;

  void _next() {
    if (_i == widget.questions.length - 1) {
      Navigator.pop(context, _correct);
    } else {
      setState(() {
        _i++;
        _pick = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_i];
    final answered = _pick != null;
    return FocusScaffold(
      title: '${widget.title} ${_i + 1}/${widget.questions.length}',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(q.prompt, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          for (var k = 0; k < q.options.length; k++)
            OptionTile(
              text: q.options[k],
              selected: _pick == k,
              showCorrect: answered && widget.showFeedback ? k == q.correct : null,
              onTap: answered
                  ? null
                  : () {
                      setState(() => _pick = k);
                      if (k == q.correct) _correct++;
                      if (!widget.showFeedback) Future.delayed(const Duration(milliseconds: 250), _next);
                    },
            ),
          if (answered && widget.showFeedback) ...[
            const SizedBox(height: 10),
            FeedbackPanel(correct: _pick == q.correct, message: q.explanation),
          ],
        ],
      ),
      bottom: widget.showFeedback
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FilledButton(
                onPressed: answered ? _next : null,
                child: Text(_i == widget.questions.length - 1 ? 'Selesai' : 'Berikutnya →'),
              ),
            )
          : null,
    );
  }
}
