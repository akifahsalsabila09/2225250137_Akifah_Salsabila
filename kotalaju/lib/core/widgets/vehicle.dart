import 'dart:math';

import 'package:flutter/material.dart';

import '../domain/motion.dart';

const _outline = Color(0xFF2D2D2D);

Color defaultVehicleColor(VehicleType t) => switch (t) {
      VehicleType.bus => const Color(0xFFF2C94C),
      VehicleType.truck => const Color(0xFF27AE60),
      VehicleType.train => const Color(0xFFEB5757),
      VehicleType.car => const Color(0xFF2F80ED),
      VehicleType.motorbike || VehicleType.courier => const Color(0xFFF2994A),
      VehicleType.bicycle => const Color(0xFF9B51E0),
      VehicleType.scooter => const Color(0xFF56CCF2),
      VehicleType.walk => const Color(0xFF6FCF97),
    };

/// Menggambar kendaraan kartun menghadap ke kanan di dalam [r].
void paintVehicle(Canvas c, Rect r, VehicleType type, Color body, {double wheelTurn = 0}) {
  final w = r.width, h = r.height, x = r.left, y = r.top;
  Offset p(double fx, double fy) => Offset(x + fx * w, y + fy * h);
  final stroke = Paint()
    ..color = _outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1.4, w * 0.025)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final fill = Paint()..color = body;
  final glass = Paint()..color = const Color(0xFFBFE6FF);
  final dark = Paint()..color = _outline;
  final light = Paint()..color = const Color(0xFFFFF3B0);

  void wheel(double fx, double fy, double fr) {
    final o = p(fx, fy);
    final rad = fr * h;
    c.drawCircle(o, rad, dark);
    c.drawCircle(o, rad * 0.45, Paint()..color = const Color(0xFFDADADA));
    final a = wheelTurn * 2 * pi;
    c.drawLine(o + Offset(cos(a), sin(a)) * rad * 0.4, o - Offset(cos(a), sin(a)) * rad * 0.4,
        Paint()
          ..color = _outline
          ..strokeWidth = 1.2);
  }

  void rrect(double l, double t, double rr, double b, double rad, Paint paint, {bool outline = true}) {
    final rect = RRect.fromRectAndRadius(Rect.fromLTRB(x + l * w, y + t * h, x + rr * w, y + b * h), Radius.circular(rad * h));
    c.drawRRect(rect, paint);
    if (outline) c.drawRRect(rect, stroke);
  }

  void rider(double fx, double headY) {
    c.drawLine(p(fx, headY + 0.12), p(fx + 0.06, headY + 0.42), stroke..strokeWidth = max(2, w * 0.05));
    stroke.strokeWidth = max(1.4, w * 0.025);
    c.drawCircle(p(fx, headY), 0.11 * h, Paint()..color = const Color(0xFFFFD7A8));
    c.drawCircle(p(fx, headY), 0.11 * h, stroke);
    final helmet = Path()
      ..addArc(Rect.fromCircle(center: p(fx, headY), radius: 0.12 * h), pi, pi);
    c.drawPath(helmet, Paint()..color = body.withValues(alpha: 0.9));
  }

  switch (type) {
    case VehicleType.car:
      final cabin = Path()
        ..moveTo(x + 0.24 * w, y + 0.48 * h)
        ..lineTo(x + 0.36 * w, y + 0.14 * h)
        ..lineTo(x + 0.68 * w, y + 0.14 * h)
        ..lineTo(x + 0.82 * w, y + 0.48 * h)
        ..close();
      c.drawPath(cabin, fill);
      c.drawPath(cabin, stroke);
      final win = Path()
        ..moveTo(x + 0.32 * w, y + 0.46 * h)
        ..lineTo(x + 0.40 * w, y + 0.22 * h)
        ..lineTo(x + 0.66 * w, y + 0.22 * h)
        ..lineTo(x + 0.74 * w, y + 0.46 * h)
        ..close();
      c.drawPath(win, glass);
      c.drawLine(p(0.53, 0.22), p(0.53, 0.46), stroke);
      rrect(0.04, 0.44, 0.96, 0.80, 0.14, fill);
      c.drawCircle(p(0.92, 0.56), 0.05 * h, light);
      wheel(0.27, 0.80, 0.15);
      wheel(0.73, 0.80, 0.15);
    case VehicleType.bus:
      rrect(0.03, 0.10, 0.97, 0.80, 0.14, fill);
      for (var i = 0; i < 4; i++) {
        rrect(0.08 + i * 0.18, 0.20, 0.22 + i * 0.18, 0.44, 0.05, glass, outline: false);
      }
      rrect(0.82, 0.20, 0.93, 0.70, 0.04, glass, outline: false);
      c.drawLine(p(0.05, 0.56), p(0.80, 0.56), Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 0.05 * h);
      c.drawCircle(p(0.95, 0.66), 0.05 * h, light);
      wheel(0.22, 0.80, 0.14);
      wheel(0.78, 0.80, 0.14);
    case VehicleType.truck:
      rrect(0.03, 0.08, 0.62, 0.78, 0.06, fill);
      rrect(0.64, 0.30, 0.96, 0.78, 0.10, Paint()..color = Color.lerp(body, Colors.white, 0.35)!);
      rrect(0.74, 0.36, 0.92, 0.54, 0.04, glass, outline: false);
      c.drawCircle(p(0.94, 0.68), 0.05 * h, light);
      wheel(0.18, 0.80, 0.14);
      wheel(0.46, 0.80, 0.14);
      wheel(0.82, 0.80, 0.14);
    case VehicleType.train:
      final body2 = Path()
        ..moveTo(x + 0.02 * w, y + 0.14 * h)
        ..lineTo(x + 0.80 * w, y + 0.14 * h)
        ..quadraticBezierTo(x + 0.99 * w, y + 0.18 * h, x + 0.99 * w, y + 0.62 * h)
        ..lineTo(x + 0.99 * w, y + 0.80 * h)
        ..lineTo(x + 0.02 * w, y + 0.80 * h)
        ..close();
      c.drawPath(body2, fill);
      c.drawPath(body2, stroke);
      for (var i = 0; i < 5; i++) {
        rrect(0.06 + i * 0.15, 0.24, 0.17 + i * 0.15, 0.46, 0.04, glass, outline: false);
      }
      c.drawLine(p(0.03, 0.58), p(0.98, 0.58), Paint()
        ..color = Colors.white
        ..strokeWidth = 0.06 * h);
      for (final fx in [0.12, 0.30, 0.62, 0.84]) {
        wheel(fx, 0.84, 0.09);
      }
    case VehicleType.motorbike:
    case VehicleType.courier:
    case VehicleType.scooter:
      wheel(0.20, 0.78, 0.18);
      wheel(0.80, 0.78, 0.18);
      final frame = Path()
        ..moveTo(x + 0.22 * w, y + 0.66 * h)
        ..lineTo(x + 0.40 * w, y + 0.50 * h)
        ..lineTo(x + 0.66 * w, y + 0.50 * h)
        ..lineTo(x + 0.80 * w, y + 0.70 * h)
        ..lineTo(x + 0.54 * w, y + 0.74 * h)
        ..close();
      c.drawPath(frame, fill);
      c.drawPath(frame, stroke);
      c.drawLine(p(0.70, 0.52), p(0.76, 0.28), stroke);
      if (type == VehicleType.courier) {
        rrect(0.06, 0.20, 0.34, 0.50, 0.04, Paint()..color = const Color(0xFFC69C6D));
      }
      if (type != VehicleType.scooter) rider(0.52, 0.18);
      if (type == VehicleType.scooter) rider(0.62, 0.08);
    case VehicleType.bicycle:
      final ws = Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2, w * 0.035);
      c.drawCircle(p(0.22, 0.74), 0.20 * h, ws);
      c.drawCircle(p(0.78, 0.74), 0.20 * h, ws);
      final fr = Paint()
        ..color = body
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.5, w * 0.045)
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(x + 0.22 * w, y + 0.74 * h)
        ..lineTo(x + 0.45 * w, y + 0.74 * h)
        ..lineTo(x + 0.66 * w, y + 0.46 * h)
        ..lineTo(x + 0.38 * w, y + 0.46 * h)
        ..close();
      c.drawPath(path, fr);
      c.drawLine(p(0.66, 0.46), p(0.78, 0.74), fr);
      c.drawLine(p(0.66, 0.46), p(0.70, 0.30), fr);
      rider(0.44, 0.10);
    case VehicleType.walk:
      final skin = Paint()..color = const Color(0xFFFFD7A8);
      final limb = Paint()
        ..color = _outline
        ..strokeWidth = max(2.5, w * 0.06)
        ..strokeCap = StrokeCap.round;
      final ph = sin(wheelTurn * 2 * pi) * 0.12;
      c.drawLine(p(0.5, 0.62), p(0.40 + ph, 0.95), limb);
      c.drawLine(p(0.5, 0.62), p(0.60 - ph, 0.95), limb);
      rrect(0.38, 0.28, 0.62, 0.66, 0.12, fill);
      c.drawLine(p(0.42, 0.36), p(0.30 - ph, 0.60), limb);
      c.drawLine(p(0.58, 0.36), p(0.70 + ph, 0.60), limb);
      c.drawCircle(p(0.5, 0.15), 0.13 * h, skin);
      c.drawCircle(p(0.5, 0.15), 0.13 * h, stroke);
  }
}

/// Widget kendaraan tunggal.
class VehicleView extends StatelessWidget {
  final VehicleType type;
  final Color? color;
  final double width;
  final bool facingRight;
  final double wheelTurn;
  const VehicleView({
    super.key,
    required this.type,
    this.color,
    this.width = 80,
    this.facingRight = true,
    this.wheelTurn = 0,
  });

  @override
  Widget build(BuildContext context) {
    final h = width * 0.55;
    return SizedBox(
      width: width,
      height: h,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(facingRight ? 1.0 : -1.0, 1.0, 1.0),
        child: CustomPaint(painter: _VehiclePainter(type, color ?? defaultVehicleColor(type), wheelTurn)),
      ),
    );
  }
}

class _VehiclePainter extends CustomPainter {
  final VehicleType type;
  final Color color;
  final double turn;
  _VehiclePainter(this.type, this.color, this.turn);

  @override
  void paint(Canvas canvas, Size size) => paintVehicle(canvas, Offset.zero & size, type, color, wheelTurn: turn);

  @override
  bool shouldRepaint(covariant _VehiclePainter old) => old.type != type || old.color != color || old.turn != turn;
}

/// Menggambar kendaraan di kanvas lain (dipakai painter jalan), dengan arah hadap.
void drawVehicleAt(Canvas c, Offset center, double width, VehicleType type, {Color? color, bool facingRight = true, double turn = 0}) {
  final h = width * 0.55;
  c.save();
  c.translate(center.dx, center.dy);
  if (!facingRight) c.scale(-1, 1);
  paintVehicle(c, Rect.fromCenter(center: Offset.zero, width: width, height: h), type, color ?? defaultVehicleColor(type),
      wheelTurn: turn);
  c.restore();
}
