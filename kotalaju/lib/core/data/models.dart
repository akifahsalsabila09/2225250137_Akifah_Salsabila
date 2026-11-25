import '../domain/motion.dart';
import '../domain/problem.dart';

class Profile {
  final String nickname;
  final int grade;
  final String classCode;
  final VehicleType vehicle;
  final bool consent;
  final String studentId;

  const Profile({
    required this.nickname,
    required this.grade,
    required this.classCode,
    required this.vehicle,
    required this.consent,
    required this.studentId,
  });

  Profile copyWith({VehicleType? vehicle, bool? consent}) => Profile(
        nickname: nickname,
        grade: grade,
        classCode: classCode,
        vehicle: vehicle ?? this.vehicle,
        consent: consent ?? this.consent,
        studentId: studentId,
      );

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'grade': grade,
        'classCode': classCode,
        'vehicle': vehicle.name,
        'consent': consent,
        'studentId': studentId,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        nickname: j['nickname'] as String,
        grade: (j['grade'] as num).toInt(),
        classCode: j['classCode'] as String? ?? '',
        vehicle: VehicleType.values.byName(j['vehicle'] as String),
        consent: j['consent'] as bool? ?? false,
        studentId: j['studentId'] as String,
      );
}

class StepRecord {
  final String elementId;
  final StepKind step;
  final bool correct;
  final int points;
  final int maxPoints;
  final ErrorCode? error;
  final int hintLevel;
  final int durationMs;

  const StepRecord({
    required this.elementId,
    required this.step,
    required this.correct,
    required this.points,
    required this.maxPoints,
    this.error,
    required this.hintLevel,
    required this.durationMs,
  });

  Map<String, dynamic> toJson() => {
        'e': elementId,
        's': step.name,
        'c': correct,
        'p': points,
        'm': maxPoints,
        if (error != null) 'err': error!.name,
        'h': hintLevel,
        'd': durationMs,
      };

  factory StepRecord.fromJson(Map<String, dynamic> j) => StepRecord(
        elementId: j['e'] as String,
        step: StepKind.values.byName(j['s'] as String),
        correct: j['c'] as bool,
        points: (j['p'] as num).toInt(),
        maxPoints: (j['m'] as num).toInt(),
        error: j['err'] == null ? null : ErrorCode.values.byName(j['err'] as String),
        hintLevel: (j['h'] as num).toInt(),
        durationMs: (j['d'] as num).toInt(),
      );
}

/// Konteks percobaan: practice | completion | checkpoint | district_quiz | mixed | pretest | posttest
class AttemptRecord {
  final String id;
  final String problemId;
  final String templateId;
  final int seed;
  final int level;
  final String context;
  final Indicator indicator;
  final int score;
  final int maxScore;
  int? mentalEffort;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<StepRecord> steps;

  AttemptRecord({
    required this.id,
    required this.problemId,
    required this.templateId,
    required this.seed,
    required this.level,
    required this.context,
    required this.indicator,
    required this.score,
    required this.maxScore,
    this.mentalEffort,
    required this.startedAt,
    required this.finishedAt,
    required this.steps,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'problemId': problemId,
        'templateId': templateId,
        'seed': seed,
        'level': level,
        'context': context,
        'indicator': indicator.name,
        'score': score,
        'maxScore': maxScore,
        'mentalEffort': mentalEffort,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'steps': [for (final s in steps) s.toJson()],
      };

  factory AttemptRecord.fromJson(Map<String, dynamic> j) => AttemptRecord(
        id: j['id'] as String,
        problemId: j['problemId'] as String,
        templateId: j['templateId'] as String,
        seed: (j['seed'] as num).toInt(),
        level: (j['level'] as num).toInt(),
        context: j['context'] as String,
        indicator: Indicator.values.byName(j['indicator'] as String),
        score: (j['score'] as num).toInt(),
        maxScore: (j['maxScore'] as num).toInt(),
        mentalEffort: (j['mentalEffort'] as num?)?.toInt(),
        startedAt: DateTime.parse(j['startedAt'] as String),
        finishedAt: DateTime.parse(j['finishedAt'] as String),
        steps: [for (final s in (j['steps'] as List)) StepRecord.fromJson((s as Map).cast<String, dynamic>())],
      );
}
