import '../domain/problem.dart';
import 'app_state.dart';

/// Ekspor CSV sesuai api.md §5: attempts.csv, steps.csv, summary.csv.
class CsvExport {
  static String _esc(Object? v) {
    final s = v?.toString() ?? '';
    if (s.contains(',') || s.contains('"') || s.contains('\n')) return '"${s.replaceAll('"', '""')}"';
    return s;
  }

  static String _row(List<Object?> cells) => cells.map(_esc).join(',');

  static Map<String, String> build(AppState s) {
    final p = s.profile!;
    final attempts = StringBuffer()
      ..writeln(_row(['attempt_id', 'student_id', 'nickname', 'class_code', 'context', 'problem_id', 'indicator', 'level', 'score',
        'max_score', 'mental_effort', 'started_at', 'finished_at']));
    final steps = StringBuffer()
      ..writeln(_row(['attempt_id', 'element_id', 'step_kind', 'correct', 'points', 'max_points', 'error_code', 'error_category',
        'hint_level_used', 'duration_ms']));
    for (final a in s.attempts) {
      attempts.writeln(_row([
        a.id, p.studentId, p.nickname, p.classCode, a.context, a.problemId, a.indicator.name, a.level, a.score, a.maxScore,
        a.mentalEffort, a.startedAt.toUtc().toIso8601String(), a.finishedAt.toUtc().toIso8601String(),
      ]));
      for (final st in a.steps) {
        steps.writeln(_row([
          a.id, st.elementId, st.step.name, st.correct ? 1 : 0, st.points, st.maxPoints, st.error?.name, st.error?.category.name,
          st.hintLevel, st.durationMs,
        ]));
      }
    }
    final pre = s.pretestByIndicator, post = s.posttestByIndicator;
    final efforts = s.attempts.where((a) => a.mentalEffort != null).map((a) => a.mentalEffort!).toList();
    final summary = StringBuffer()
      ..writeln(_row([
        'student_id', 'nickname', 'class_code', 'grade', 'prereq_score',
        for (final i in Indicator.values) 'pre_${i.name}',
        'pre_total',
        for (final i in Indicator.values) 'post_${i.name}',
        'post_total', 'n_gain', 'unit_error_rate_pre', 'unit_error_rate_post', 'avg_mental_effort', 'districts_done', 'attempts',
      ]))
      ..writeln(_row([
        p.studentId, p.nickname, p.classCode, p.grade, s.prereqScore,
        for (final i in Indicator.values) pre?[i],
        s.pretestScore,
        for (final i in Indicator.values) post?[i],
        s.posttestScore,
        s.nGain?.toStringAsFixed(3),
        s.unitErrorRate('pretest')?.toStringAsFixed(3),
        s.unitErrorRate('posttest')?.toStringAsFixed(3),
        efforts.isEmpty ? null : (efforts.reduce((a, b) => a + b) / efforts.length).toStringAsFixed(2),
        s.doneDistricts.length,
        s.attempts.length,
      ]));
    return {'attempts.csv': attempts.toString(), 'steps.csv': steps.toString(), 'summary.csv': summary.toString()};
  }
}
