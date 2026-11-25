import 'dart:math';

/// Jenis rintangan dan tinggi minimal lompatan agar lolos (piksel).
enum ObstacleType {
  cone(30, 'kerucut'),
  pothole(14, 'lubang'),
  rock(26, 'batu'),
  puddle(14, 'genangan'),
  barrier(38, 'palang');

  const ObstacleType(this.clearance, this.label);
  final double clearance;
  final String label;
}

class Obstacle {
  final double x;
  final ObstacleType type;
  bool hit = false;
  bool passed = false;
  Obstacle(this.x, this.type);
}

/// Dunia permainan sepeda (tanpa Flutter, mudah dites).
/// Sepeda maju otomatis, berhenti di setiap koin soal, dan bisa melompati rintangan.
class RideWorld {
  static const speed = 220.0; // piksel per detik
  static const gap = 650.0; // jarak antarkoin
  static const firstCoin = 700.0;
  static const jumpVelocity = 540.0;
  static const gravity = 1500.0;
  static const hitZone = 24.0;

  final int coinCount;
  double distance = 0;
  double time = 0;
  double jumpH = 0;
  double _jumpV = 0;
  double wobble = 0; // > 0 saat oleng setelah menabrak
  double _slow = 0;
  bool riding = false;
  bool finished = false;
  int? activeCoin;
  int collected = 0;
  late final List<Obstacle> obstacles;

  RideWorld(this.coinCount) {
    obstacles = _buildObstacles();
  }

  double coinX(int i) => firstCoin + i * gap;
  double get finishX => coinX(coinCount - 1) + gap;

  int get hits => obstacles.where((o) => o.hit).length;
  int get cleared => obstacles.where((o) => o.passed && !o.hit).length;
  bool get airborne => jumpH > 0;

  List<Obstacle> _buildObstacles() {
    final list = <Obstacle>[];
    var k = 0;
    for (var g = 0; g <= coinCount; g++) {
      final start = g == 0 ? 0.0 : coinX(g - 1);
      for (final offset in [260.0, 470.0]) {
        list.add(Obstacle(start + offset, ObstacleType.values[k % ObstacleType.values.length]));
        k++;
      }
    }
    return list;
  }

  void start() {
    riding = true;
  }

  /// Lompat (hanya saat sepeda melaju dan menyentuh tanah).
  bool jump() {
    if (!riding || airborne) return false;
    _jumpV = jumpVelocity;
    jumpH = 0.01;
    return true;
  }

  void step(double dt) {
    time += dt;
    wobble = max(0, wobble - dt);
    if (airborne || _jumpV > 0) {
      jumpH += _jumpV * dt;
      _jumpV -= gravity * dt;
      if (jumpH <= 0) {
        jumpH = 0;
        _jumpV = 0;
      }
    }
    if (!riding) return;
    final v = speed * (_slow > 0 ? 0.45 : 1.0);
    _slow = max(0, _slow - dt);
    distance += v * dt;

    for (final o in obstacles) {
      if (o.hit || o.passed) continue;
      if ((o.x - distance).abs() < hitZone) {
        if (jumpH < o.type.clearance) {
          o.hit = true;
          wobble = 0.6;
          _slow = 0.8;
        }
      } else if (distance > o.x + hitZone) {
        o.passed = true;
      }
    }

    if (collected < coinCount && distance >= coinX(collected) - 40) {
      distance = coinX(collected) - 40;
      riding = false;
      activeCoin = collected;
      jumpH = 0;
      _jumpV = 0;
    } else if (collected >= coinCount && distance >= finishX) {
      distance = finishX;
      riding = false;
      finished = true;
    }
  }

  /// Soal pada koin aktif sudah dijawab; lanjut menggowes.
  void continueRiding() {
    if (activeCoin != null) collected++;
    activeCoin = null;
    riding = true;
  }

  void reset() {
    distance = 0;
    jumpH = 0;
    _jumpV = 0;
    wobble = 0;
    _slow = 0;
    riding = false;
    finished = false;
    activeCoin = null;
    collected = 0;
    for (final o in obstacles) {
      o.hit = false;
      o.passed = false;
    }
  }
}
