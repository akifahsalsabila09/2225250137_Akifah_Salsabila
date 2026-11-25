import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../domain/problem.dart';

/// Panel umpan balik: spesifik per langkah, nada suportif.
class FeedbackPanel extends StatelessWidget {
  final bool correct;
  final String message;
  final ErrorCode? error;
  final bool carried;
  const FeedbackPanel({super.key, required this.correct, required this.message, this.error, this.carried = false});

  @override
  Widget build(BuildContext context) {
    final color = correct ? AppColors.right : AppColors.wrong;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(correct ? Icons.check_circle : (error?.category.icon ?? Icons.info), color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!correct && error != null)
                    Text('Kesalahan ${error!.category.label.toLowerCase()}',
                        style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 13)),
                  Text(message, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu pilihan (pengganti radio) dengan ukuran sentuh besar.
class OptionTile extends StatelessWidget {
  final String text;
  final bool selected;
  final bool? showCorrect; // null = belum dinilai
  final VoidCallback? onTap;
  final Widget? leading;
  const OptionTile({super.key, required this.text, required this.selected, this.showCorrect, this.onTap, this.leading});

  @override
  Widget build(BuildContext context) {
    Color border = selected ? AppColors.distance : const Color(0xFFDDD6C6);
    Color bg = selected ? AppColors.distance.withValues(alpha: 0.08) : Colors.white;
    if (showCorrect == true) {
      border = AppColors.right;
      bg = AppColors.right.withValues(alpha: 0.1);
    } else if (showCorrect == false && selected) {
      border = AppColors.wrong;
      bg = AppColors.wrong.withValues(alpha: 0.08);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: border, width: 2)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 10)],
                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selected ? border : Colors.black38),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Isian angka dengan label satuan di kanan.
class NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String unitLabel;
  final Color color;
  final bool enabled;
  final String hint;
  final ValueChanged<String>? onSubmitted;
  final TextInputType keyboard;
  const NumberField({
    super.key,
    required this.controller,
    required this.unitLabel,
    this.color = AppColors.ink,
    this.enabled = true,
    this.hint = 'contoh: 0,75',
    this.onSubmitted,
    this.keyboard = const TextInputType.numberWithOptions(decimal: true),
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboard,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: unitLabel,
        suffixStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: color, width: 3)),
      ),
    );
  }
}

class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarRow({super.key, required this.stars, this.size = 22});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFF2B01E), size: size),
        ],
      );
}

/// Perayaan (Mode Kota): kartu berputar + confetti.
Future<void> showCelebration(BuildContext context, {required String title, required String subtitle, Widget? hero}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup',
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (ctx, a1, a2) => _Celebration(title: title, subtitle: subtitle, hero: hero),
    transitionBuilder: (ctx, anim, _, child) => ScaleTransition(
      scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
      child: child,
    ),
  );
}

class _Celebration extends StatefulWidget {
  final String title, subtitle;
  final Widget? hero;
  const _Celebration({required this.title, required this.subtitle, this.hero});
  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Stack(
      children: [
        if (!reduce)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(animation: _c, builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_c.value))),
            ),
          ),
        Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.taxi, width: 4),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.hero != null)
                    AnimatedBuilder(
                      animation: _c,
                      builder: (_, child) => Transform.rotate(
                        angle: reduce ? 0 : sin(_c.value * pi * 4) * 0.08 * (1 - _c.value),
                        child: child,
                      ),
                      child: widget.hero,
                    ),
                  const SizedBox(height: 10),
                  Text(widget.title,
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(widget.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Asyik, lanjut!')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);
  static const _colors = [AppColors.taxi, AppColors.distance, AppColors.speed, AppColors.time, AppColors.clock, AppColors.wrong];

  @override
  void paint(Canvas c, Size s) {
    final r = Random(7);
    for (var i = 0; i < 70; i++) {
      final x0 = r.nextDouble() * s.width;
      final speed = 0.6 + r.nextDouble() * 0.8;
      final y = -20 + (t * speed) * (s.height + 40);
      final x = x0 + sin(t * 8 + i) * 18;
      c.save();
      c.translate(x, y);
      c.rotate(t * 10 + i);
      c.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), Paint()..color = _colors[i % _colors.length].withValues(alpha: 1 - t * 0.5));
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

/// Kartu SIM (hadiah distrik).
class SimCard extends StatelessWidget {
  final String district;
  final String name;
  const SimCard({super.key, required this.district, required this.name});
  @override
  Widget build(BuildContext context) => Container(
        width: 240,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SIM KOTALAJU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Distrik: $district', style: const TextStyle(color: Colors.white)),
          ],
        ),
      );
}
