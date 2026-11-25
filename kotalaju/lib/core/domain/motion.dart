import 'clock.dart';

enum VehicleType {
  walk('pejalan kaki'),
  bicycle('sepeda'),
  scooter('skuter'),
  motorbike('motor'),
  car('mobil'),
  bus('bus'),
  truck('truk'),
  train('kereta'),
  courier('motor kurir');

  const VehicleType(this.label);
  final String label;
}

/// Kendaraan pada jalan lurus 1 dimensi.
class Mover {
  final String id;
  final VehicleType vehicle;
  final double startKm;
  final int direction; // +1 ke kanan, -1 ke kiri
  final double speedKmh;
  final ClockTime departAt;

  const Mover({
    required this.id,
    required this.vehicle,
    required this.startKm,
    required this.direction,
    required this.speedKmh,
    required this.departAt,
  });
}

enum MeetingType { headOn, catchUp }

class MeetingResult {
  final double clockMinutes;
  final double positionKm;
  final double relativeSpeedKmh;
  final MeetingType type;
  const MeetingResult(this.clockMinutes, this.positionKm, this.relativeSpeedKmh, this.type);

  ClockTime get clock => ClockTime(clockMinutes.round());
}

/// Satu-satunya sumber kebenaran gerak: dipakai animasi, game, dan kunci jawaban.
class MotionSimulator {
  static double positionAt(Mover m, double clockMinutes) {
    final dt = clockMinutes - m.departAt.minutes;
    if (dt <= 0) return m.startKm;
    return m.startKm + m.direction * m.speedKmh * dt / 60;
  }

  static MeetingResult? meeting(Mover a, Mover b) {
    final tL = (a.departAt.minutes > b.departAt.minutes ? a.departAt.minutes : b.departAt.minutes).toDouble();
    final pa = positionAt(a, tL);
    final pb = positionAt(b, tL);
    final gap = pb - pa; // posisi b relatif terhadap a
    final gapRate = b.direction * b.speedKmh - a.direction * a.speedKmh; // km per jam
    final type = a.direction == b.direction ? MeetingType.catchUp : MeetingType.headOn;
    if (gap.abs() < 1e-9) return MeetingResult(tL, pa, gapRate.abs(), type);
    if (gapRate.abs() < 1e-12) return null;
    final hours = -gap / gapRate;
    if (hours < 0) return null;
    final t = tL + hours * 60;
    return MeetingResult(t, positionAt(a, t), gapRate.abs(), type);
  }
}
