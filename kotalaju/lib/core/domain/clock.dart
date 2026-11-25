/// Jam dinding (pukul) dalam menit sejak 00.00.
class ClockTime implements Comparable<ClockTime> {
  final int minutes;
  const ClockTime(this.minutes);

  factory ClockTime.hm(int h, int m) => ClockTime(h * 60 + m);

  /// Menerima "07.30", "7:30", "07,30", "0730".
  static ClockTime? parse(String input) {
    final s = input.trim();
    final sep = RegExp(r'^(\d{1,2})[.:,](\d{2})$').firstMatch(s);
    if (sep != null) {
      final h = int.parse(sep.group(1)!);
      final m = int.parse(sep.group(2)!);
      if (h > 23 || m > 59) return null;
      return ClockTime.hm(h, m);
    }
    final compact = RegExp(r'^(\d{1,2})(\d{2})$').firstMatch(s);
    if (compact != null) {
      final h = int.parse(compact.group(1)!);
      final m = int.parse(compact.group(2)!);
      if (h > 23 || m > 59) return null;
      return ClockTime.hm(h, m);
    }
    return null;
  }

  int get hour => (minutes ~/ 60) % 24;
  int get minute => minutes % 60;

  String get label =>
      '${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}';

  ClockTime plusMinutes(num m) => ClockTime(minutes + m.round());
  ClockTime plusHours(num h) => ClockTime(minutes + (h * 60).round());

  /// Selisih dalam menit (other - this).
  int minutesUntil(ClockTime other) => other.minutes - minutes;

  @override
  int compareTo(ClockTime other) => minutes.compareTo(other.minutes);

  @override
  bool operator ==(Object other) => other is ClockTime && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;

  @override
  String toString() => label;
}
