import 'dart:math';

import 'package:flutter/material.dart';

/// Pilihan karakter (skin) pesepeda.
class RiderSkin {
  final String name;
  final Color skin;
  final Color shirt;
  final Color pants;
  final Color headwear; // helm atau hijab
  final bool hijab;
  final Color bike;
  final Color hair;
  const RiderSkin({
    required this.name,
    required this.skin,
    required this.shirt,
    required this.pants,
    required this.headwear,
    required this.bike,
    this.hijab = false,
    this.hair = const Color(0xFF2B1B10),
  });
}

const riderSkins = <RiderSkin>[
  RiderSkin(
    name: 'Raka',
    skin: Color(0xFFC68642),
    shirt: Color(0xFF2F80ED),
    pants: Color(0xFF263238),
    headwear: Color(0xFFEB5757),
    bike: Color(0xFFF2C94C),
  ),
  RiderSkin(
    name: 'Nisa',
    skin: Color(0xFFE0AC69),
    shirt: Color(0xFFF06292),
    pants: Color(0xFF283593),
    headwear: Color(0xFF8E24AA),
    hijab: true,
    bike: Color(0xFF26A69A),
  ),
  RiderSkin(
    name: 'Dimas',
    skin: Color(0xFF8D5524),
    shirt: Color(0xFF43A047),
    pants: Color(0xFF37474F),
    headwear: Color(0xFFFFB300),
    bike: Color(0xFFE53935),
  ),
  RiderSkin(
    name: 'Sari',
    skin: Color(0xFFF1C27D),
    shirt: Color(0xFFFF8F00),
    pants: Color(0xFF4E342E),
    headwear: Color(0xFF2E7D32),
    hijab: true,
    bike: Color(0xFF1E88E5),
  ),
  RiderSkin(
    name: 'Budi',
    skin: Color(0xFFC68642),
    shirt: Color(0xFFD32F2F),
    pants: Color(0xFF1A237E),
    headwear: Color(0xFF1E88E5),
    bike: Color(0xFF43A047),
  ),
  RiderSkin(
    name: 'Lala',
    skin: Color(0xFFFFDBAC),
    shirt: Color(0xFF7E57C2),
    pants: Color(0xFF455A64),
    headwear: Color(0xFFFF80AB),
    bike: Color(0xFFFF7043),
    hair: Color(0xFF5D4037),
  ),
];

/// Menggambar pesepeda menghadap kanan. [origin] = titik tengah antara kedua roda (di poros roda).
/// [crank] = sudut pedal (radian). [scale] 1 = lebar ±100 px.
void paintRider(Canvas c, Offset origin, RiderSkin s, {double crank = 0, double scale = 1, double tilt = 0}) {
  c.save();
  c.translate(origin.dx, origin.dy);
  c.rotate(tilt);
  c.scale(scale);

  final outline = Paint()
    ..color = const Color(0xFF2D2D2D)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2
    ..strokeCap = StrokeCap.round;
  final frame = Paint()
    ..color = s.bike
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  const rear = Offset(-32, 0), front = Offset(32, 0), bb = Offset(-2, 0);
  const seat = Offset(-12, -26), head = Offset(22, -28), bar = Offset(24, -36);
  const wheelR = 17.0;

  void wheel(Offset o) {
    c.drawCircle(o, wheelR, Paint()..color = const Color(0xFF2D2D2D)..style = PaintingStyle.stroke..strokeWidth = 4);
    for (var k = 0; k < 4; k++) {
      final a = crank * 1.6 + k * pi / 4;
      c.drawLine(o + Offset(cos(a), sin(a)) * (wheelR - 2), o - Offset(cos(a), sin(a)) * (wheelR - 2),
          Paint()
            ..color = Colors.black38
            ..strokeWidth = 1);
    }
    c.drawCircle(o, 3, Paint()..color = const Color(0xFF9E9E9E));
  }

  // Kaki belakang (lebih gelap) di belakang rangka.
  Offset pedal(double a) => bb + Offset(cos(a), sin(a)) * 9;
  const hip = Offset(-10, -32);
  void leg(Offset foot, Color color) {
    const thigh = 19.0, shin = 20.0;
    final d = (foot - hip).distance.clamp(1.0, thigh + shin - 0.5);
    final dir = (foot - hip) / (foot - hip).distance;
    final a = (thigh * thigh - shin * shin + d * d) / (2 * d);
    final h = sqrt(max(0, thigh * thigh - a * a));
    final mid = hip + dir * a;
    final knee = mid + Offset(dir.dy, -dir.dx) * h; // lutut menekuk ke depan
    final p = Paint()
      ..color = color
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;
    c.drawLine(hip, knee, p);
    c.drawLine(knee, foot, p);
    c.drawCircle(foot + const Offset(2, 0), 3.5, Paint()..color = const Color(0xFF212121));
  }

  final backColor = Color.lerp(s.pants, Colors.black, 0.35)!;
  leg(pedal(crank + pi), backColor);

  wheel(rear);
  wheel(front);
  // Rangka
  c.drawLine(rear, bb, frame);
  c.drawLine(rear, seat, frame);
  c.drawLine(bb, seat, frame);
  c.drawLine(seat + const Offset(2, 0), head, frame);
  c.drawLine(bb, head, frame);
  c.drawLine(head, front, frame);
  c.drawLine(head, bar, frame..strokeWidth = 3.5);
  c.drawLine(bar, bar + const Offset(6, 2), outline);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: seat + const Offset(0, -2), width: 14, height: 5), const Radius.circular(3)),
      Paint()..color = const Color(0xFF212121));
  // Engkol
  c.drawLine(pedal(crank), pedal(crank + pi), Paint()
    ..color = const Color(0xFF616161)
    ..strokeWidth = 2.5);

  // Badan
  const shoulder = Offset(6, -56);
  c.drawLine(hip, shoulder, Paint()
    ..color = s.shirt
    ..strokeWidth = 13
    ..strokeCap = StrokeCap.round);
  // Lengan
  final arm = Paint()
    ..color = s.shirt
    ..strokeWidth = 5.5
    ..strokeCap = StrokeCap.round;
  const elbow = Offset(18, -46);
  c.drawLine(shoulder, elbow, arm);
  c.drawLine(elbow, bar + const Offset(2, 0), arm..color = s.skin);
  c.drawCircle(bar + const Offset(3, 0), 3, Paint()..color = s.skin);

  // Kaki depan
  leg(pedal(crank), s.pants);

  // Kepala
  const headC = Offset(12, -70);
  if (s.hijab) {
    final hij = Paint()..color = s.headwear;
    c.drawCircle(headC + const Offset(-1, -1), 12.5, hij);
    final drape = Path()
      ..moveTo(headC.dx - 12, headC.dy)
      ..quadraticBezierTo(headC.dx - 14, headC.dy + 18, headC.dx + 2, headC.dy + 16)
      ..lineTo(headC.dx + 10, headC.dy + 8)
      ..close();
    c.drawPath(drape, hij);
    c.drawOval(Rect.fromCenter(center: headC + const Offset(3, 1), width: 15, height: 17), Paint()..color = s.skin);
  } else {
    c.drawCircle(headC, 10, Paint()..color = s.skin);
    c.drawArc(Rect.fromCircle(center: headC + const Offset(-1, 1), radius: 10.5), pi * 0.85, pi * 0.55, false,
        Paint()
          ..color = s.hair
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Helm
    final helmet = Path()..addArc(Rect.fromCircle(center: headC + const Offset(-1, -2), radius: 12), pi, pi);
    c.drawPath(helmet, Paint()..color = s.headwear);
    c.drawLine(headC + const Offset(-13, -2), headC + const Offset(13, -2), Paint()
      ..color = s.headwear
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
  }
  // Mata & senyum
  c.drawCircle(headC + const Offset(6, 0), 1.6, Paint()..color = const Color(0xFF212121));
  c.drawArc(Rect.fromCircle(center: headC + const Offset(5, 3), radius: 3.5), 0.2, 1.4, false,
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
  c.restore();
}

/// Widget kecil untuk memilih karakter.
class RiderView extends StatelessWidget {
  final RiderSkin skin;
  final double width;
  final double crank;
  const RiderView({super.key, required this.skin, this.width = 100, this.crank = 0.6});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 1.05,
      child: CustomPaint(painter: _RiderPainter(skin, crank)),
    );
  }
}

class _RiderPainter extends CustomPainter {
  final RiderSkin skin;
  final double crank;
  _RiderPainter(this.skin, this.crank);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    paintRider(canvas, Offset(size.width / 2, size.height - 20 * scale), skin, crank: crank, scale: scale);
  }

  @override
  bool shouldRepaint(covariant _RiderPainter old) => old.skin != skin || old.crank != crank;
}
