import 'problem.dart';

/// Level bantuan per langkah (1 = bantuan penuh, 3 = mandiri).
/// Naik: 3 kali benar berturut-turut tanpa petunjuk tingkat ≥ 3.
/// Turun: 2 kali salah berturut-turut pada langkah yang sama.
class AdaptivePath {
  final Map<StepKind, int> levels;
  final Map<StepKind, int> upStreak;
  final Map<StepKind, int> downStreak;

  AdaptivePath({Map<StepKind, int>? levels, Map<StepKind, int>? up, Map<StepKind, int>? down})
      : levels = levels ?? {},
        upStreak = up ?? {},
        downStreak = down ?? {};

  int levelFor(StepKind k) => levels[k] ?? 1;

  void record(StepKind k, {required bool correct, required int hintLevelUsed}) {
    if (correct && hintLevelUsed < 3) {
      downStreak[k] = 0;
      final u = (upStreak[k] ?? 0) + 1;
      if (u >= 3) {
        levels[k] = (levelFor(k) + 1).clamp(1, 3);
        upStreak[k] = 0;
      } else {
        upStreak[k] = u;
      }
    } else if (!correct) {
      upStreak[k] = 0;
      final d = (downStreak[k] ?? 0) + 1;
      if (d >= 2) {
        levels[k] = (levelFor(k) - 1).clamp(1, 3);
        downStreak[k] = 0;
      } else {
        downStreak[k] = d;
      }
    } else {
      upStreak[k] = 0;
    }
  }

  Map<String, dynamic> toJson() => {
        'levels': {for (final e in levels.entries) e.key.name: e.value},
        'up': {for (final e in upStreak.entries) e.key.name: e.value},
        'down': {for (final e in downStreak.entries) e.key.name: e.value},
      };

  factory AdaptivePath.fromJson(Map<String, dynamic>? j) {
    Map<StepKind, int> m(dynamic x) => {
          for (final e in ((x as Map?) ?? {}).entries) StepKind.values.byName(e.key as String): (e.value as num).toInt(),
        };
    if (j == null) return AdaptivePath();
    return AdaptivePath(levels: m(j['levels']), up: m(j['up']), down: m(j['down']));
  }
}
