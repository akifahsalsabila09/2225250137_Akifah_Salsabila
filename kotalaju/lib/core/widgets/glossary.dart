import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../domain/clock.dart';
import '../domain/motion.dart';
import '../domain/problem.dart';
import 'road_scene.dart';

/// Kamus Jalan (EL01): istilah kaku dijelaskan dengan kalimat sederhana dan gambar mini.
const glossary = <String, String>{
  'berpapasan': 'Bertemu saat bergerak dari arah yang berlawanan.',
  'menyusul': 'Mengejar dari belakang, arahnya sama, sampai sejajar.',
  'waktu tempuh': 'Lama perjalanan. Bukan jam berangkat atau jam tiba.',
  'kecepatan rata-rata': 'Jarak yang ditempuh dalam 1 jam (atau 1 menit, 1 detik), dihitung rata-rata.',
  'jarak': 'Panjang jalan yang dilalui dari tempat awal ke tempat tujuan.',
};

SceneData? _miniScene(String term) {
  final t0 = ClockTime.hm(7, 0);
  switch (term) {
    case 'berpapasan':
      return SceneData(type: SceneType.straight, lengthKm: 100, leftName: 'A', rightName: 'B', movers: [
        Mover(id: 'A', vehicle: VehicleType.car, startKm: 0, direction: 1, speedKmh: 50, departAt: t0),
        Mover(id: 'B', vehicle: VehicleType.bus, startKm: 100, direction: -1, speedKmh: 50, departAt: t0),
      ]);
    case 'menyusul':
      return SceneData(type: SceneType.straight, lengthKm: 100, leftName: 'Start', rightName: '', movers: [
        Mover(id: 'A', vehicle: VehicleType.bus, startKm: 40, direction: 1, speedKmh: 40, departAt: t0),
        Mover(id: 'B', vehicle: VehicleType.motorbike, startKm: 0, direction: 1, speedKmh: 60, departAt: t0),
      ]);
    default:
      return null;
  }
}

Future<void> showGlossary(BuildContext context, String term) {
  final scene = _miniScene(term);
  return showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(children: [
        const Icon(Icons.menu_book, color: AppColors.distance),
        const SizedBox(width: 8),
        Expanded(child: Text(term, style: const TextStyle(fontWeight: FontWeight.w900))),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(glossary[term] ?? '-', style: const TextStyle(fontSize: 17)),
          if (scene != null) ...[
            const SizedBox(height: 12),
            SizedBox(width: 300, child: RoadSceneView(scene: scene, showLabels: false, height: 110)),
          ],
        ],
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))],
    ),
  );
}
