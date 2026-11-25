import 'clock.dart';
import 'format.dart';
import 'problem.dart';
import 'units.dart';

class ElementResult {
  final String elementId;
  final StepKind step;
  final bool correct;
  final int points;
  final int maxPoints;
  final ErrorCode? error;
  final String feedback;

  /// Benar berdasarkan jawaban siswa sebelumnya (error carried forward).
  final bool carried;

  const ElementResult({
    required this.elementId,
    required this.step,
    required this.correct,
    required this.points,
    required this.maxPoints,
    this.error,
    required this.feedback,
    this.carried = false,
  });
}

/// Penilaian per tahap (rubrik 6 poin). Satu-satunya tempat skor dihitung.
class Scorer {
  static const _praise = ['Tepat!', 'Hebat!', 'Mantap!', 'Benar!', 'Keren!'];
  static String _ok(String id) => _praise[id.hashCode.abs() % _praise.length];

  static ElementResult scoreTags(Problem p, Map<String, TagKind> tags) {
    final wrong = <StoryToken>[];
    ErrorCode? code;
    for (final t in p.tokens) {
      final given = tags[t.id];
      if (given == t.kind) continue;
      wrong.add(t);
      if (t.kind == TagKind.irrelevant) {
        code ??= ErrorCode.irrelevantUsed;
      } else if ((t.kind == TagKind.clock && given == TagKind.duration) ||
          (t.kind == TagKind.duration && given == TagKind.clock)) {
        code = ErrorCode.clockVsDuration;
      } else {
        code ??= ErrorCode.misread;
      }
    }
    final ok = wrong.isEmpty;
    return ElementResult(
      elementId: 'read',
      step: StepKind.read,
      correct: ok,
      points: ok ? p.readPoints : 0,
      maxPoints: p.readPoints,
      error: ok ? null : code,
      feedback: ok
          ? '${_ok('read')} Semua info sudah ditandai dengan benar.'
          : 'Cek lagi: ${wrong.map((t) => '"${t.text}"').join(', ')}. ${code!.message}',
    );
  }

  static ElementResult scoreAsk(Problem p, int? choice) {
    final ok = choice == p.askCorrect;
    return ElementResult(
      elementId: 'ask',
      step: StepKind.known,
      correct: ok,
      points: ok ? p.askPoints : 0,
      maxPoints: p.askPoints,
      error: ok ? null : ErrorCode.misread,
      feedback: ok ? '${_ok('ask')} Itu yang ditanya.' : 'Baca kalimat tanyanya lagi. ${ErrorCode.misread.message}',
    );
  }

  static ElementResult scoreUnitsSame(Problem p, bool? sameAnswer) {
    final ok = sameAnswer == true;
    return ElementResult(
      elementId: 'units',
      step: StepKind.unit,
      correct: ok,
      points: ok ? p.unitPoints : 0,
      maxPoints: p.unitPoints,
      error: ok ? null : ErrorCode.misread,
      feedback: ok ? '${_ok('units')} ${p.unitNote}' : 'Lihat lagi satuannya. ${p.unitNote}',
    );
  }

  static ElementResult scoreConversion(Problem p, int i, double? value) {
    final c = p.conversions[i];
    final id = 'c$i';
    if (value == null) return _empty(id, StepKind.unit, c.points);
    final expected = c.expected;
    if (nearlyEqual(value, expected)) {
      return ElementResult(
        elementId: id,
        step: StepKind.unit,
        correct: true,
        points: c.points,
        maxPoints: c.points,
        feedback: '${_ok(id)} ${c.from.label} = ${fmtNum(expected, maxDecimals: 3)} ${c.target.label}.',
      );
    }
    ErrorCode code;
    final b100 = UnitEngine.base100(c.from, c.target);
    if (b100 != null && nearlyEqual(value, b100)) {
      code = ErrorCode.unitBase100;
    } else if (nearlyEqual(value, UnitEngine.wrongDirection(c.from, c.target))) {
      code = ErrorCode.unitWrongDirection;
    } else if (nearlyEqual(value, c.from.value)) {
      code = ErrorCode.unitNotConverted;
    } else if (nearlyEqual(value, expected, rel: 0.15)) {
      code = ErrorCode.arithmetic;
    } else {
      code = ErrorCode.unknown;
    }
    return ElementResult(
      elementId: id,
      step: StepKind.unit,
      correct: false,
      points: 0,
      maxPoints: c.points,
      error: code,
      feedback: code.message,
    );
  }

  /// [answer] berupa double (NumericSub), ClockTime (ClockSub), atau int (ChoiceSub).
  static ElementResult scoreSub(Problem p, int i, Object? answer, Given given) {
    final sub = p.subs[i];
    final id = 's$i';
    const step = StepKind.compute;
    if (answer == null) return _empty(id, step, sub.points);
    switch (sub) {
      case NumericSub():
        final v = answer as double;
        if (nearlyEqual(v, sub.expected)) {
          return _right(id, step, sub.points);
        }
        final ecfVal = sub.ecf?.call(given);
        if (ecfVal != null && nearlyEqual(v, ecfVal) && !nearlyEqual(ecfVal, sub.expected)) {
          return ElementResult(
            elementId: id,
            step: step,
            correct: true,
            carried: true,
            points: sub.points,
            maxPoints: sub.points,
            feedback: 'Caramu benar berdasarkan jawabanmu sebelumnya. '
                'Jawaban tepatnya ${fmtNum(sub.expected, maxDecimals: 3)} ${sub.unit.label}.',
          );
        }
        ErrorCode code = ErrorCode.unknown;
        for (final w in sub.wrongs) {
          if (nearlyEqual(v, w.value)) {
            code = w.code;
            break;
          }
        }
        if (code == ErrorCode.unknown && nearlyEqual(v, sub.expected, rel: 0.15)) {
          code = ErrorCode.arithmetic;
        }
        return _wrong(id, step, sub.points, code);
      case ClockSub():
        final c = answer as ClockTime;
        if ((c.minutes - sub.expected.minutes).abs() <= 1) return _right(id, step, sub.points);
        final ecfVal = sub.ecf?.call(given);
        if (ecfVal != null && (c.minutes - ecfVal).abs() <= 1 && ecfVal != sub.expected.minutes) {
          return ElementResult(
            elementId: id,
            step: step,
            correct: true,
            carried: true,
            points: sub.points,
            maxPoints: sub.points,
            feedback: 'Caramu benar berdasarkan jawabanmu sebelumnya. Jawaban tepatnya pukul ${sub.expected.label}.',
          );
        }
        var code = ErrorCode.unknown;
        for (final (mins, ec) in sub.wrongs) {
          if ((c.minutes - mins).abs() <= 1) {
            code = ec;
            break;
          }
        }
        if (code == ErrorCode.unknown && (c.minutes - sub.expected.minutes).abs() <= 10) {
          code = ErrorCode.arithmetic;
        }
        return _wrong(id, step, sub.points, code);
      case ChoiceSub():
        final idx = answer as int;
        if (idx == sub.correct) return _right(id, step, sub.points);
        return _wrong(id, step, sub.points, sub.wrongCodes[idx] ?? ErrorCode.unknown);
    }
  }

  static ElementResult scoreCheck(Problem p, int? choice) {
    final c = p.check;
    if (choice == null) return _empty('check', StepKind.check, c.points);
    if (choice == c.correct) {
      return ElementResult(
        elementId: 'check',
        step: StepKind.check,
        correct: true,
        points: c.points,
        maxPoints: c.points,
        feedback: '${_ok('check')} Kamu sudah memeriksa kewajaran jawabanmu.',
      );
    }
    final code = c.wrongCodes[choice] ?? ErrorCode.unknown;
    return ElementResult(
      elementId: 'check',
      step: StepKind.check,
      correct: false,
      points: 0,
      maxPoints: c.points,
      error: code,
      feedback: code == ErrorCode.unknown ? 'Alasan itu belum tepat. Coba bayangkan kejadiannya di jalan.' : code.message,
    );
  }

  static ElementResult _right(String id, StepKind step, int pts) => ElementResult(
      elementId: id, step: step, correct: true, points: pts, maxPoints: pts, feedback: _ok(id));

  static ElementResult _wrong(String id, StepKind step, int pts, ErrorCode code) => ElementResult(
      elementId: id, step: step, correct: false, points: 0, maxPoints: pts, error: code, feedback: code.message);

  static ElementResult _empty(String id, StepKind step, int pts) => ElementResult(
      elementId: id,
      step: step,
      correct: false,
      points: 0,
      maxPoints: pts,
      error: ErrorCode.unknown,
      feedback: 'Isi jawabannya dulu, ya.');
}
