import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/motion.dart';
import '../../core/widgets/vehicle.dart';
import 'radar_chart.dart';

/// Garasi: koleksi kendaraan, kustomisasi warna, lencana, grafik kemajuan literasi.
class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});
  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    if (s.reduceMotion || MediaQuery.of(context).disableAnimations) {
      _bounce.stop();
    } else if (!_bounce.isAnimating) {
      _bounce.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile!;
    return CityBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('🚘 Garasi', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF6D6D6D),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF4F4F4F), width: 6),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(children: [
                      for (var i = 0; i < 3; i++) Container(height: 6, margin: const EdgeInsets.only(top: 6), color: Colors.white12),
                    ]),
                  ),
                  AnimatedBuilder(
                    animation: _bounce,
                    builder: (_, child) => Transform.translate(offset: Offset(0, -sin(_bounce.value * pi) * 6), child: child),
                    child: VehicleView(type: p.vehicle, width: 190, color: Color(s.colorOf(p.vehicle)), wheelTurn: 0),
                  ),
                  Positioned(
                    bottom: 8,
                    child: Text('${p.nickname} • ${p.vehicle.label}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section('Koleksi Kendaraan'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final v in vehicleUnlockOrder) _vehicleTile(s, v),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Kendaraan baru terbuka setiap kamu mendapat SIM distrik.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 14),
            _section('Cat Kendaraan (30 🪙)  •  Koinmu: ${s.coins}'),
            Wrap(
              spacing: 10,
              children: [
                for (final c in vehicleColors)
                  GestureDetector(
                    onTap: () {
                      if (s.colorOf(p.vehicle) == c) return;
                      final ok = s.buyColor(p.vehicle, c);
                      if (!ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Koin belum cukup. Kerjakan latihan atau main game dulu!')),
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: s.colorOf(p.vehicle) == c ? AppColors.ink : Colors.white, width: 4),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _section('Lencana'),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
              children: [
                for (final b in allBadges)
                  Tooltip(
                    message: b.desc,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: s.badges.contains(b.id) ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: s.badges.contains(b.id) ? AppColors.taxi : Colors.black12, width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(opacity: s.badges.contains(b.id) ? 1 : 0.25, child: Text(b.icon, style: const TextStyle(fontSize: 34))),
                          Text(b.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          Text(b.desc, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _section('Kemampuan Literasi Matematis'),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Center(child: RadarChart(values: s.mlProfile())),
                  const Text('Dari 8 soal terakhir tiap kemampuan.', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
      );

  Widget _vehicleTile(AppState s, VehicleType v) {
    final have = s.unlocked.contains(v);
    final selected = s.profile!.vehicle == v;
    return GestureDetector(
      onTap: have ? () => s.selectVehicle(v) : null,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: have ? 1 : 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.taxi : Colors.black12, width: selected ? 4 : 1.5),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: have ? 1 : 0.2,
              child: VehicleView(type: v, width: 76, color: have ? Color(s.colorOf(v)) : Colors.black),
            ),
            Text(have ? v.label : '???', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
