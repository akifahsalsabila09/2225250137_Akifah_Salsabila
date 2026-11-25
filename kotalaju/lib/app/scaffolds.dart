import 'dart:math';

import 'package:flutter/material.dart';

import '../core/data/app_state.dart';
import 'theme.dart';

/// Mode Fokus: dipakai di layar materi, soal, dan kuis.
/// Tanpa dekorasi bergerak, tanpa maskot, latar polos (coherence principle).
class FocusScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  const FocusScaffold({super.key, required this.title, required this.body, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.focusBg,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: actions,
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottom == null ? null : SafeArea(child: bottom!),
    );
  }
}

/// Latar Mode Kota: langit, awan bergerak, siluet gedung. Meriah tetapi hanya di luar soal.
class CityBackdrop extends StatefulWidget {
  final Widget child;
  const CityBackdrop({super.key, required this.child});

  @override
  State<CityBackdrop> createState() => _CityBackdropState();
}

class _CityBackdropState extends State<CityBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    final still = s.reduceMotion || s.economyMode || MediaQuery.of(context).disableAnimations;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(painter: _SkyPainter(_c.value)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double t;
  _SkyPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7CC8FB), Color(0xFFD7F0FF)],
        ).createShader(rect),
    );
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 4; i++) {
      final x = ((t + i * 0.27) % 1.0) * (size.width + 200) - 100;
      final y = 40.0 + i * 70 + sin(i * 2.0) * 20;
      _cloud(canvas, Offset(x, y), 26 + i * 4.0, cloud);
    }
    final bld = Paint()..color = const Color(0xFFB8DDF5);
    final w = size.width;
    final base = size.height * 0.35;
    final rnd = Random(3);
    var x = 0.0;
    while (x < w) {
      final bw = 30 + rnd.nextDouble() * 40;
      final bh = 40 + rnd.nextDouble() * 90;
      canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, base - bh, bw - 4, bh + 2000),
            topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
        bld,
      );
      x += bw;
    }
  }

  void _cloud(Canvas c, Offset o, double r, Paint p) {
    c.drawCircle(o, r, p);
    c.drawCircle(o + Offset(r * 0.9, 4), r * 0.8, p);
    c.drawCircle(o + Offset(-r * 0.9, 6), r * 0.7, p);
    c.drawCircle(o + Offset(r * 0.2, -r * 0.5), r * 0.75, p);
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.t != t;
}
