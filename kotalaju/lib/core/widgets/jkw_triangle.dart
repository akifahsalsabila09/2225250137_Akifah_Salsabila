import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Segitiga JKW interaktif (K02, GL01). Ketuk satu huruf untuk "menutupnya"
/// dan melihat rumusnya, beserta makna agar bukan sekadar hafalan.
class JkwTriangle extends StatefulWidget {
  final String? initial; // 'J' | 'K' | 'W'
  final double size;
  final ValueChanged<String>? onPick;
  const JkwTriangle({super.key, this.initial, this.size = 220, this.onPick});

  @override
  State<JkwTriangle> createState() => _JkwTriangleState();
}

class _JkwTriangleState extends State<JkwTriangle> {
  late String? _covered = widget.initial;

  static const _info = {
    'J': ('Jarak = Kecepatan × Waktu', 'Tiap jam menempuh K km, selama W jam.'),
    'K': ('Kecepatan = Jarak ÷ Waktu', 'Berapa km yang ditempuh dalam 1 jam?'),
    'W': ('Waktu = Jarak ÷ Kecepatan', 'Berapa kali K km "masuk" ke dalam J km?'),
  };

  void _tap(String l) {
    setState(() => _covered = _covered == l ? null : l);
    if (_covered != null) widget.onPick?.call(l);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return Column(
      children: [
        SizedBox(
          width: s,
          height: s * 0.86,
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _TrianglePainter())),
              _letter('J', 'Jarak', AppColors.distance, Offset(s / 2, s * 0.86 * 0.36)),
              _letter('K', 'Kecepatan', AppColors.speed, Offset(s * 0.32, s * 0.86 * 0.76)),
              _letter('W', 'Waktu', AppColors.time, Offset(s * 0.68, s * 0.86 * 0.76)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _covered == null
              ? const Text('Ketuk huruf yang dicari.', key: ValueKey('none'), style: TextStyle(fontSize: 15))
              : Column(
                  key: ValueKey(_covered),
                  children: [
                    _formula(_info[_covered]!.$1),
                    const SizedBox(height: 4),
                    Text(_info[_covered]!.$2,
                        textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _formula(String f) {
    final spans = <TextSpan>[];
    for (final part in f.split(' ')) {
      final color = switch (part) {
        'Jarak' => AppColors.distance,
        'Kecepatan' => AppColors.speed,
        'Waktu' => AppColors.time,
        _ => AppColors.ink,
      };
      spans.add(TextSpan(text: '$part ', style: TextStyle(color: color)));
    }
    return Text.rich(TextSpan(children: spans),
        textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900));
  }

  Widget _letter(String l, String name, Color color, Offset center) {
    final covered = _covered == l;
    return Positioned(
      left: center.dx - 34,
      top: center.dy - 30,
      width: 68,
      height: 60,
      child: Semantics(
        button: true,
        label: 'Tutup $name',
        child: GestureDetector(
          onTap: () => _tap(l),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: covered ? AppColors.ink : color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            alignment: Alignment.center,
            child: covered
                ? const Text('✋', style: TextStyle(fontSize: 26))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color, height: 1)),
                      Text(name, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final path = Path()
      ..moveTo(s.width / 2, 4)
      ..lineTo(s.width - 4, s.height - 4)
      ..lineTo(4, s.height - 4)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFFFFF6D6));
    final line = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(path, line);
    final midY = s.height * 0.55;
    final dx = (s.width / 2 - 4) * (midY - 4) / (s.height - 8);
    c.drawLine(Offset(s.width / 2 - dx, midY), Offset(s.width / 2 + dx, midY), line);
    c.drawLine(Offset(s.width / 2, midY), Offset(s.width / 2, s.height - 4), line);
    final tp = TextPainter(
      text: const TextSpan(text: '÷', style: TextStyle(fontSize: 18, color: Colors.black45, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(s.width / 2 + dx + 2, midY - 20));
    final tp2 = TextPainter(
      text: const TextSpan(text: '×', style: TextStyle(fontSize: 18, color: Colors.black45, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(c, Offset(s.width / 2 + 4, s.height - 26));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
