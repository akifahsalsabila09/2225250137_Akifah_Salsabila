import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/data/models.dart';
import '../../core/domain/clock.dart';
import '../../core/domain/format.dart';
import '../../core/domain/problem.dart';
import '../../core/domain/problem_bank.dart';
import '../../core/domain/scorer.dart';
import '../../core/domain/units.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/jkw_triangle.dart';
import '../../core/widgets/road_scene.dart';
import '../../core/widgets/road_sketch.dart';
import '../../core/widgets/story_view.dart';
import '../../core/widgets/unit_calculator.dart';

/// practice: boleh coba lagi, petunjuk bebas, fading adaptif.
/// completion: langkah ① dan ② sudah diisi (contoh setengah jadi).
/// quiz: satu kali jawab, umpan balik ditampilkan, petunjuk ≥ 3 mengurangi poin.
/// test: satu kali jawab, tanpa umpan balik, tanpa petunjuk, kalkulator terkunci.
enum SessionMode { practice, completion, quiz, test }

class _El {
  final String id;
  final StepKind step;
  const _El(this.id, this.step);
}

enum _Stage { solving, effort, summary }

class ProblemSessionView extends StatefulWidget {
  final Problem problem;
  final SessionMode mode;
  final String recordContext;
  final bool askEffort;
  final ValueChanged<AttemptRecord> onFinished;
  final String finishLabel;

  const ProblemSessionView({
    super.key,
    required this.problem,
    required this.mode,
    required this.recordContext,
    required this.onFinished,
    this.askEffort = false,
    this.finishLabel = 'Lanjut',
  });

  @override
  State<ProblemSessionView> createState() => _ProblemSessionViewState();
}

class _ProblemSessionViewState extends State<ProblemSessionView> {
  Problem get p => widget.problem;
  bool get isTest => widget.mode == SessionMode.test;
  bool get isQuiz => widget.mode == SessionMode.quiz;
  bool get canRetry => widget.mode == SessionMode.practice || widget.mode == SessionMode.completion;

  late final List<_El> _els;
  int _idx = 0;
  _Stage _stage = _Stage.solving;

  final Map<String, ElementResult> _first = {};
  final Map<String, int> _durations = {};
  final Map<String, int> _elementHint = {};
  final Map<StepKind, int> _hintLevel = {};
  final Set<String> _prefilled = {};
  ElementResult? _current;
  int _tries = 0;
  bool _revealed = false;

  final Map<String, TagKind> _tags = {};
  String? _selToken;
  int? _choice;
  bool? _same;
  final _num = TextEditingController();
  final Given _given = {};
  final _sw = Stopwatch();
  late final DateTime _startedAt = DateTime.now();
  int? _effort;
  bool _triangleOpen = false;

  @override
  void initState() {
    super.initState();
    _els = [
      const _El('read', StepKind.read),
      const _El('ask', StepKind.known),
      if (p.conversions.isEmpty) const _El('units', StepKind.unit),
      for (var i = 0; i < p.conversions.length; i++) _El('c$i', StepKind.unit),
      for (var i = 0; i < p.subs.length; i++) _El('s$i', StepKind.compute),
      const _El('check', StepKind.check),
    ];
    if (widget.mode == SessionMode.completion) {
      for (final t in p.tokens) {
        _tags[t.id] = t.kind;
      }
      _prefilled.addAll(['read', 'ask']);
      _idx = 2;
    }
    _sw.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.mode == SessionMode.practice && _level(StepKind.read) == 1 && _tags.isEmpty && p.tokens.isNotEmpty) {
      final ex = p.tokens.firstWhere((t) => t.kind != TagKind.irrelevant, orElse: () => p.tokens.first);
      _tags[ex.id] = ex.kind; // contoh pewarnaan
    }
    if (widget.mode == SessionMode.practice && _level(StepKind.compute) == 1) _triangleOpen = true;
  }

  @override
  void dispose() {
    _num.dispose();
    super.dispose();
  }

  int _level(StepKind k) {
    if (isTest) return 3;
    if (isQuiz) return 2;
    return AppScope.read(context).adaptive.levelFor(k);
  }

  CalcMode get _calcMode {
    if (isTest) return CalcMode.locked;
    if (isQuiz) return CalcMode.check;
    return switch (_level(StepKind.unit)) { 1 => CalcMode.full, 2 => CalcMode.check, _ => CalcMode.locked };
  }

  _El get _el => _els[_idx];

  // ───────────── penilaian ─────────────

  void _submit() {
    final e = _el;
    ElementResult? r;
    if (e.id == 'read') {
      r = Scorer.scoreTags(p, _tags);
    } else if (e.id == 'ask') {
      if (_choice == null) return _needAnswer();
      r = Scorer.scoreAsk(p, _choice);
    } else if (e.id == 'units') {
      if (_same == null) return _needAnswer();
      r = Scorer.scoreUnitsSame(p, _same);
    } else if (e.id.startsWith('c')) {
      final i = int.parse(e.id.substring(1));
      final v = parseNum(_num.text);
      if (v == null) return _needAnswer();
      _given[e.id] = v;
      r = Scorer.scoreConversion(p, i, v);
    } else if (e.id.startsWith('s')) {
      final i = int.parse(e.id.substring(1));
      final sub = p.subs[i];
      Object? ans;
      switch (sub) {
        case NumericSub():
          final v = parseNum(_num.text);
          if (v == null) return _needAnswer();
          _given[e.id] = v;
          ans = v;
        case ClockSub():
          final c = ClockTime.parse(_num.text);
          if (c == null) return _needAnswer('Tulis jam seperti 07.30');
          _given[e.id] = c.minutes.toDouble();
          ans = c;
        case ChoiceSub():
          if (_choice == null) return _needAnswer();
          ans = _choice;
      }
      r = Scorer.scoreSub(p, i, ans, _given);
    } else if (e.id == 'check') {
      if (_choice == null) return _needAnswer();
      r = Scorer.scoreCheck(p, _choice);
    }
    if (r == null) return;
    if (isQuiz && (_elementHint[e.id] ?? 0) >= 3 && r.points > 0) {
      r = ElementResult(
        elementId: r.elementId,
        step: r.step,
        correct: r.correct,
        points: r.points - 1,
        maxPoints: r.maxPoints,
        error: r.error,
        feedback: '${r.feedback} (Poin dikurangi karena memakai petunjuk.)',
        carried: r.carried,
      );
    }
    _first.putIfAbsent(e.id, () => r!);
    _durations.putIfAbsent(e.id, () => _sw.elapsedMilliseconds);
    _tries++;
    if (isTest) {
      _advance();
      return;
    }
    setState(() => _current = r);
  }

  void _needAnswer([String msg = 'Isi jawabannya dulu, ya.']) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void _retry() => setState(() => _current = null);

  void _reveal() {
    final e = _el;
    setState(() {
      _revealed = true;
      if (e.id == 'read') {
        for (final t in p.tokens) {
          _tags[t.id] = t.kind;
        }
      } else if (e.id.startsWith('c')) {
        _given[e.id] = p.conversions[int.parse(e.id.substring(1))].expected;
      } else if (e.id.startsWith('s')) {
        final sub = p.subs[int.parse(e.id.substring(1))];
        if (sub is NumericSub) _given[e.id] = sub.expected;
        if (sub is ClockSub) _given[e.id] = sub.expected.minutes.toDouble();
      }
    });
  }

  String _answerText(_El e) {
    if (e.id == 'read') return 'Lihat warna pada soal di atas.';
    if (e.id == 'ask') return p.askOptions[p.askCorrect];
    if (e.id == 'units') return 'Ya, sudah sejalan. ${p.unitNote}';
    if (e.id.startsWith('c')) {
      final c = p.conversions[int.parse(e.id.substring(1))];
      return UnitEngine.explain(c.from, c.target).map((s) => s.expression).join('  →  ');
    }
    if (e.id.startsWith('s')) {
      final sub = p.subs[int.parse(e.id.substring(1))];
      return switch (sub) {
        NumericSub() => '${fmtNum(sub.expected, maxDecimals: 3)} ${sub.unit.label}',
        ClockSub() => 'Pukul ${sub.expected.label}',
        ChoiceSub() => sub.options[sub.correct],
      };
    }
    return p.check.options[p.check.correct];
  }

  void _advance() {
    final e = _el;
    if (e.id == 'read' && !isTest && (_current?.correct ?? false)) {
      // tanda siswa sudah benar
    }
    _sw
      ..reset()
      ..start();
    setState(() {
      _idx++;
      _current = null;
      _tries = 0;
      _revealed = false;
      _choice = null;
      _same = null;
      _num.clear();
      _selToken = null;
      if (_idx >= _els.length) {
        _stage = widget.askEffort ? _Stage.effort : _Stage.summary;
      } else if (_els[_idx].step == StepKind.compute && widget.mode == SessionMode.practice) {
        _triangleOpen = _level(StepKind.compute) == 1;
      }
    });
  }

  void _skipRead() {
    for (final t in p.tokens) {
      _tags[t.id] = t.kind;
    }
    _first['read'] = ElementResult(
      elementId: 'read',
      step: StepKind.read,
      correct: true,
      points: p.readPoints,
      maxPoints: p.readPoints,
      feedback: 'Dilewati (sudah mahir).',
    );
    _advance();
  }

  AttemptRecord _record() {
    final rnd = Random();
    final steps = [
      for (final e in _els)
        if (_first[e.id] != null && !_prefilled.contains(e.id))
          StepRecord(
            elementId: e.id,
            step: e.step,
            correct: _first[e.id]!.correct,
            points: _first[e.id]!.points,
            maxPoints: _first[e.id]!.maxPoints,
            error: _first[e.id]!.error,
            hintLevel: _elementHint[e.id] ?? 0,
            durationMs: _durations[e.id] ?? 0,
          ),
    ];
    return AttemptRecord(
      id: List.generate(12, (_) => rnd.nextInt(16).toRadixString(16)).join(),
      problemId: p.id,
      templateId: p.templateId,
      seed: p.seed,
      level: p.level,
      context: widget.recordContext,
      indicator: p.indicator,
      score: steps.fold(0, (a, s) => a + s.points),
      maxScore: steps.fold(0, (a, s) => a + s.maxPoints),
      mentalEffort: _effort,
      startedAt: _startedAt,
      finishedAt: DateTime.now(),
      steps: steps,
    );
  }

  // ───────────── petunjuk ─────────────

  Future<void> _hint() async {
    final state = AppScope.read(context);
    final step = _el.step;
    final lvl = min(4, (_hintLevel[step] ?? 0) + 1);
    _hintLevel[step] = lvl;
    _elementHint[_el.id] = max(_elementHint[_el.id] ?? 0, lvl);
    state.log('hint_opened', {'problem': p.id, 'step': step.name, 'level': lvl});
    final hints = p.hintsFor(step);
    if (lvl == 2 && p.scene.sketchable) {
      state.bump('sketch_used');
      await RoadSketchDialog.show(context, p.scene);
      return;
    }
    if (!mounted) return;
    final Widget body = switch (lvl) {
      1 => Text(hints[0], style: const TextStyle(fontSize: 17)),
      2 => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Bayangkan kejadiannya di jalan. Perhatikan warna angka pada gambar.', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          RoadSceneView(scene: p.scene, height: 170),
        ]),
      3 => Text(hints[1], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      _ => _workedSister(),
    };
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.focusBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.lightbulb, color: AppColors.taxi, size: 28),
                const SizedBox(width: 8),
                Text('Petunjuk $lvl dari 4', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 12),
              body,
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Oke')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _workedSister() {
    final sis = ProblemBank.generate(p.templateId, level: p.level, seed: p.seed + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contoh soal sejenis dengan angka berbeda:', style: TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        StoryView(story: sis.story, revealTruth: true),
        const Divider(),
        for (var i = 0; i < sis.solution.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text('${i + 1}. ${sis.solution[i]}', style: const TextStyle(fontSize: 15)),
          ),
      ],
    );
  }

  // ───────────── tampilan ─────────────

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _Stage.solving => _solving(context),
      _Stage.effort => _effortView(),
      _Stage.summary => _summaryView(),
    };
  }

  Widget _solving(BuildContext context) {
    final e = _el;
    final answered = _current != null;
    return Column(
      children: [
        _stepHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              RoadSceneView(scene: p.scene, height: 140),
              if (p.scene.showTimeline && p.scene.movers.isNotEmpty && e.step != StepKind.read) ...[
                const SizedBox(height: 6),
                _timeline(),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E1D0)),
                ),
                child: StoryView(
                  story: p.story,
                  tags: _tags,
                  selected: _selToken,
                  onTokenTap: e.id == 'read' && !answered ? (id) => setState(() => _selToken = id) : null,
                ),
              ),
              const SizedBox(height: 12),
              _elementBody(e),
              if (answered) ...[
                const SizedBox(height: 12),
                FeedbackPanel(
                  correct: _current!.correct,
                  message: _current!.feedback,
                  error: _current!.error,
                  carried: _current!.carried,
                ),
              ],
              if (_revealed) ...[
                const SizedBox(height: 8),
                FeedbackPanel(correct: true, message: 'Jawaban: ${_answerText(e)}'),
              ],
            ],
          ),
        ),
        _bottomBar(),
      ],
    );
  }

  Widget _timeline() {
    final ms = p.scene.movers;
    final from = ms.map((m) => m.departAt.minutes).reduce(min);
    return TimelineView(
      from: ClockTime(from - 15),
      to: ClockTime(from + 120),
      marks: [
        for (final m in ms) TimelineMark('${m.id} berangkat', m.departAt),
      ],
    );
  }

  Widget _stepHeader() {
    final cur = _idx < _els.length ? _el.step : StepKind.check;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          for (final k in StepKind.values) ...[
            _dot(k, cur),
            if (k != StepKind.check)
              Expanded(child: Container(height: 3, color: k.index < cur.index ? AppColors.right : const Color(0xFFE0E0E0))),
          ],
          if (!isTest)
            IconButton(
              tooltip: 'Petunjuk',
              onPressed: _hint,
              icon: Badge(
                isLabelVisible: (_hintLevel[cur] ?? 0) > 0,
                label: Text('${_hintLevel[cur] ?? 0}'),
                child: Icon(Icons.lightbulb, color: _tries >= 2 ? AppColors.speed : AppColors.taxi, size: 30),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(StepKind k, StepKind cur) {
    final done = k.index < cur.index;
    final active = k == cur;
    return Tooltip(
      message: k.title,
      child: CircleAvatar(
        radius: active ? 16 : 13,
        backgroundColor: done ? AppColors.right : (active ? AppColors.distance : const Color(0xFFE0E0E0)),
        child: done
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : Text('${k.index + 1}', style: TextStyle(color: active ? Colors.white : Colors.black54, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      );

  Widget _elementBody(_El e) {
    final locked = _current != null && (!canRetry || _current!.correct) || _revealed;
    final stepLabel = 'Langkah ${e.step.index + 1}: ${e.step.title}';
    if (e.id == 'read') {
      final kinds = [
        TagKind.distance,
        TagKind.speed,
        TagKind.duration,
        TagKind.clock,
        if (p.tokens.any((t) => t.kind == TagKind.irrelevant)) TagKind.irrelevant,
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(stepLabel),
          Text(
            _selToken == null ? 'Ketuk angka di soal, lalu pilih jenisnya.' : 'Pilih jenis untuk "${p.tokens.firstWhere((t) => t.id == _selToken).text}":',
            style: const TextStyle(fontSize: 15),
          ),
          if (widget.mode == SessionMode.practice && _level(StepKind.read) == 1)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Satu angka sudah diwarnai sebagai contoh.', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in kinds)
                ActionChip(
                  avatar: Icon(k.icon, color: k.color, size: 18),
                  label: Text(k.label),
                  side: BorderSide(color: k.color, width: 2),
                  backgroundColor: k.color.withValues(alpha: 0.08),
                  onPressed: _selToken == null || locked
                      ? null
                      : () => setState(() {
                            _tags[_selToken!] = k;
                            final rest = p.tokens.where((t) => _tags[t.id] == null).toList();
                            _selToken = rest.isEmpty ? null : rest.first.id;
                          }),
                ),
            ],
          ),
        ],
      );
    }
    if (e.id == 'ask') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(stepLabel),
          KnownSummary(problem: p, tags: _tags),
          const SizedBox(height: 10),
          const Text('Apa yang ditanya?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          ..._options(p.askOptions, locked, p.askCorrect),
        ],
      );
    }
    if (e.id == 'units') {
      final units = p.tokens.where((t) => t.kind != TagKind.irrelevant).map((t) => t.text).join(' • ');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(stepLabel),
          Text('Satuan yang ada: $units', style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 6),
          const Text('Apakah satuannya sudah sejalan untuk dihitung?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          OptionTile(
            text: 'Ya, sudah sejalan',
            selected: _same == true,
            showCorrect: _current == null ? null : true,
            onTap: locked ? null : () => setState(() => _same = true),
          ),
          OptionTile(
            text: 'Belum, ada yang perlu diubah',
            selected: _same == false,
            showCorrect: _current == null ? null : false,
            onTap: locked ? null : () => setState(() => _same = false),
          ),
        ],
      );
    }
    if (e.id.startsWith('c')) {
      final c = p.conversions[int.parse(e.id.substring(1))];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(stepLabel),
          if (c.label != null) Text(c.label!, style: const TextStyle(fontSize: 15, color: AppColors.clock, fontWeight: FontWeight.w700)),
          Text('Ubah ${c.from.label} ke ${c.target.label}:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${c.from.label} = ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.time)),
              Expanded(
                child: NumberField(
                  controller: _num,
                  unitLabel: c.target.label,
                  color: AppColors.time,
                  enabled: !locked,
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_calcMode == CalcMode.full)
            OutlinedButton.icon(
              onPressed: () {
                AppScope.read(context).logTool('unit_calculator');
                UnitCalculator.show(context, initial: c.from, target: c.target);
              },
              icon: const Icon(Icons.build),
              label: const Text('Bengkel Satuan: lihat langkahnya'),
            )
          else if (_calcMode == CalcMode.check)
            OutlinedButton.icon(
              onPressed: () {
                AppScope.read(context).logTool('unit_rule');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(UnitEngine.rule(c.from.unit, c.target)), duration: const Duration(seconds: 5)),
                );
              },
              icon: const Icon(Icons.rule),
              label: const Text('Lihat aturannya'),
            ),
        ],
      );
    }
    if (e.id.startsWith('s')) {
      final sub = p.subs[int.parse(e.id.substring(1))];
      final showTri = !isTest && (_level(StepKind.compute) < 3 || isQuiz);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(stepLabel),
          if (showTri) _triangleBox(),
          const SizedBox(height: 8),
          Text(sub.prompt, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          switch (sub) {
            NumericSub() => NumberField(
                controller: _num,
                unitLabel: sub.unit.label,
                color: _unitColor(sub.unit),
                enabled: !locked,
                onSubmitted: (_) => _submit(),
              ),
            ClockSub() => NumberField(
                controller: _num,
                unitLabel: '',
                hint: 'contoh: 07.30',
                color: AppColors.clock,
                enabled: !locked,
                keyboard: TextInputType.datetime,
                onSubmitted: (_) => _submit(),
              ),
            ChoiceSub() => Column(children: _options(sub.options, locked, sub.correct)),
          },
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(stepLabel),
        Text(p.check.prompt, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        ..._options(p.check.options, locked, p.check.correct),
      ],
    );
  }

  Color _unitColor(Unit u) => switch (u.dimension) {
        Dimension.distance => AppColors.distance,
        Dimension.speed => AppColors.speed,
        Dimension.time => AppColors.time,
      };

  Widget _triangleBox() {
    if (_triangleOpen) {
      return Center(
        child: Column(
          children: [
            JkwTriangle(
              size: 180,
              initial: switch (p.formulaFocus) { 'waktu' => 'W', 'kecepatan' => 'K', _ => 'J' },
              onPick: (_) => AppScope.read(context).logTool('jkw_triangle'),
            ),
            TextButton(onPressed: () => setState(() => _triangleOpen = false), child: const Text('Sembunyikan segitiga')),
          ],
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _triangleOpen = true),
        icon: const Icon(Icons.change_history),
        label: const Text('Buka segitiga JKW'),
      ),
    );
  }

  List<Widget> _options(List<String> opts, bool locked, int correct) => [
        for (var i = 0; i < opts.length; i++)
          OptionTile(
            text: opts[i],
            selected: _choice == i,
            showCorrect: _current == null || isTest ? null : (i == correct ? (_current!.correct || _revealed || !canRetry) : false),
            onTap: locked ? null : () => setState(() => _choice = i),
          ),
      ];

  Widget _bottomBar() {
    final e = _el;
    final answered = _current != null;
    final buttons = <Widget>[];
    if (!answered && !_revealed) {
      if (e.id == 'read' && widget.mode == SessionMode.practice && _level(StepKind.read) == 3) {
        buttons.add(Expanded(child: OutlinedButton(onPressed: _skipRead, child: const Text('Lewati'))));
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(Expanded(flex: 2, child: FilledButton(onPressed: _submit, child: Text(isTest ? 'Simpan & lanjut' : 'Periksa'))));
    } else if (answered && !_current!.correct && canRetry && !_revealed) {
      if (_tries >= 2) {
        buttons.add(Expanded(child: OutlinedButton(onPressed: _reveal, child: const Text('Lihat jawaban'))));
        buttons.add(const SizedBox(width: 8));
      }
      buttons.add(Expanded(flex: 2, child: FilledButton(onPressed: _retry, child: const Text('Coba lagi'))));
    } else {
      buttons.add(Expanded(child: FilledButton(onPressed: _advance, child: const Text('Lanjut →'))));
    }
    return SafeArea(
      top: false,
      child: Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: Row(children: buttons)),
    );
  }

  Widget _effortView() {
    const labels = {1: 'Sangat\nringan', 5: 'Sedang', 9: 'Sangat\nberat'};
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Seberapa berat usaha berpikirmu untuk soal tadi?',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Tidak ada jawaban benar atau salah.', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 1; i <= 9; i++)
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      ChoiceChip(
                        label: Text('$i', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        selected: _effort == i,
                        onSelected: (_) => setState(() => _effort = i),
                        selectedColor: Color.lerp(AppColors.time, AppColors.wrong, (i - 1) / 8)!.withValues(alpha: 0.4),
                      ),
                      SizedBox(
                        height: 32,
                        child: Text(labels[i] ?? '', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _effort == null ? null : () => setState(() => _stage = _Stage.summary),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
  }

  Widget _summaryView() {
    final rec = _record();
    final pct = rec.maxScore == 0 ? 1.0 : rec.score / rec.maxScore;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Text(isTest ? 'Jawaban tersimpan' : (pct >= 0.8 ? 'Luar biasa!' : pct >= 0.5 ? 'Bagus, terus berlatih!' : 'Ayo coba lagi!'),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              if (!isTest) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text('${rec.score} / ${rec.maxScore}',
                      style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.distance)),
                ),
                Center(child: Text('Indikator: ${p.indicator.en} (${p.indicator.id})')),
                const SizedBox(height: 12),
                for (final s in rec.steps)
                  ListTile(
                    dense: true,
                    leading: Icon(s.correct ? Icons.check_circle : (s.error?.category.icon ?? Icons.cancel),
                        color: s.correct ? AppColors.right : AppColors.wrong),
                    title: Text('${s.step.index + 1}. ${s.step.title}'),
                    subtitle: s.error != null && !s.correct ? Text(s.error!.message) : null,
                    trailing: Text(s.maxPoints == 0 ? '–' : '${s.points}/${s.maxPoints}'),
                  ),
                const SizedBox(height: 8),
                ExpansionTile(
                  title: const Text('Lihat pembahasan', style: TextStyle(fontWeight: FontWeight.w800)),
                  children: [
                    for (var i = 0; i < p.solution.length; i++)
                      ListTile(dense: true, leading: CircleAvatar(radius: 12, child: Text('${i + 1}')), title: Text(p.solution[i])),
                  ],
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => widget.onFinished(rec), child: Text(widget.finishLabel)),
            ),
          ),
        ),
      ],
    );
  }
}
