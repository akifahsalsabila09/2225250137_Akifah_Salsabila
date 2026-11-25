import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../domain/motion.dart';
import '../domain/problem.dart';
import 'paint_utils.dart';
import 'vehicle.dart';

/// Sketsa Jalan (GL03): siswa menempatkan kendaraan dan arah geraknya sebelum menghitung.
class RoadSketchDialog extends StatefulWidget {
  final SceneData scene;
  const RoadSketchDialog({super.key, required this.scene});

  static Future<bool?> show(BuildContext context, SceneData scene) =>
      showDialog<bool>(context: context, builder: (_) => RoadSketchDialog(scene: scene));

  @override
  State<RoadSketchDialog> createState() => _RoadSketchDialogState();
}

class _RoadSketchDialogState extends State<RoadSketchDialog> {
  final _pos = <String, double>{'A': 0.45, 'B': 0.55};
  final _dir = <String, int>{'A': 0, 'B': 0};
  String? _feedback;
  bool _ok = false;

  void _check() {
    final ms = widget.scene.movers;
    final a = ms[0], b = ms[1];
    final dirsOk = _dir['A'] == a.direction && _dir['B'] == b.direction;
    bool orderOk;
    if (a.direction != b.direction) {
      orderOk = (_pos['A']! < _pos['B']!) == (a.startKm < b.startKm);
    } else {
      // Menyusul: yang berangkat lebih dulu berada di depan saat yang kedua mulai.
      final aheadIsA = a.departAt.minutes <= b.departAt.minutes;
      orderOk = aheadIsA ? _pos['A']! > _pos['B']! : _pos['B']! > _pos['A']!;
    }
    setState(() {
      _ok = dirsOk && orderOk;
      _feedback = _ok
          ? 'Sketsamu tepat! Sekarang lebih mudah menghitungnya.'
          : !dirsOk
              ? 'Cek lagi arah panahnya. Ke mana masing-masing bergerak?'
              : (a.direction != b.direction
                  ? 'Cek posisi awalnya. Siapa yang dari kiri, siapa dari kanan?'
                  : 'Siapa yang berangkat lebih dulu? Dia sudah berada di depan.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final ms = widget.scene.movers;
    final headOn = ms[0].direction != ms[1].direction;
    return AlertDialog(
      title: const Text('✏️ Sketsa Jalan', style: TextStyle(fontWeight: FontWeight.w900)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              headOn
                  ? 'Geser A dan B ke posisi awalnya. Lalu pilih arah geraknya.'
                  : 'Geser A dan B ke posisinya saat ${ms[1].departAt.label}. Lalu pilih arahnya.',
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(builder: (context, cons) {
              final w = cons.maxWidth;
              return SizedBox(
                height: 120,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SketchRoadPainter(widget.scene.leftName, headOn ? widget.scene.rightName : ''),
                      ),
                    ),
                    for (final id in ['A', 'B'])
                      Positioned(
                        left: (_pos[id]! * (w - 60)).clamp(0, w - 60),
                        top: id == 'A' ? 4 : 50,
                        child: GestureDetector(
                          onHorizontalDragUpdate: (d) =>
                              setState(() => _pos[id] = (_pos[id]! + d.delta.dx / (w - 60)).clamp(0.0, 1.0)),
                          child: Column(
                            children: [
                              VehicleView(
                                type: ms[id == 'A' ? 0 : 1].vehicle,
                                width: 60,
                                facingRight: _dir[id] != -1,
                              ),
                              Text(id, style: const TextStyle(fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            for (final id in ['A', 'B'])
              Row(
                children: [
                  SizedBox(width: 90, child: Text('Arah $id:', style: const TextStyle(fontWeight: FontWeight.w700))),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: -1, icon: Icon(Icons.arrow_back)),
                      ButtonSegment(value: 1, icon: Icon(Icons.arrow_forward)),
                    ],
                    emptySelectionAllowed: true,
                    selected: _dir[id] == 0 ? <int>{} : {_dir[id]!},
                    onSelectionChanged: (s) => setState(() => _dir[id] = s.isEmpty ? 0 : s.first),
                  ),
                ],
              ),
            if (_feedback != null) ...[
              const SizedBox(height: 8),
              Text(_feedback!,
                  style: TextStyle(fontWeight: FontWeight.w700, color: _ok ? AppColors.right : AppColors.wrong)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, _ok), child: const Text('Tutup')),
        FilledButton(onPressed: _check, child: const Text('Periksa')),
      ],
    );
  }
}

class _SketchRoadPainter extends CustomPainter {
  final String left, right;
  _SketchRoadPainter(this.left, this.right);
  @override
  void paint(Canvas c, Size s) {
    drawRoad(c, Rect.fromLTWH(0, s.height * 0.42, s.width, 28));
    drawLabel(c, left, Offset(0, s.height - 4), anchor: const Offset(0, 1), size: 11, bold: true);
    if (right.isNotEmpty) drawLabel(c, right, Offset(s.width, s.height - 4), anchor: const Offset(1, 1), size: 11, bold: true);
  }

  @override
  bool shouldRepaint(covariant _SketchRoadPainter old) => false;
}

/// Ikon kendaraan ringan untuk daftar.
Widget vehicleIcon(VehicleType t, {double size = 40, Color? color}) => VehicleView(type: t, width: size, color: color);
