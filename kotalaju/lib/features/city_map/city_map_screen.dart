import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/data/content.dart';
import '../../core/domain/motion.dart';
import '../../core/widgets/paint_utils.dart';
import '../../core/widgets/vehicle.dart';
import '../lesson/district_screen.dart';
import '../quiz/test_screen.dart';
import '../teacher/settings_screen.dart';

class _Node {
  final String id;
  final String icon;
  final String name;
  final Offset frac; // x: fraksi lebar, y: piksel
  const _Node(this.id, this.icon, this.name, this.frac);
}

const _terminal = _Node('terminal', '🚏', 'Terminal Awal', Offset(0.5, 70));
const _balai = _Node('balai', '🏛️', 'Balai Kota', Offset(0.5, 1010));
const _layout = <String, Offset>{
  'menara_jam': Offset(0.27, 210),
  'bundaran_jkw': Offset(0.73, 350),
  'bengkel_satuan': Offset(0.27, 490),
  'jalan_cerita': Offset(0.73, 630),
  'simpang_berpapasan': Offset(0.25, 820),
  'jalur_susul': Offset(0.75, 820),
};

/// Peta Kota (Mode Kota): navigasi utama, meriah dan hidup.
class CityMapScreen extends StatefulWidget {
  const CityMapScreen({super.key});
  @override
  State<CityMapScreen> createState() => _CityMapScreenState();
}

class _CityMapScreenState extends State<CityMapScreen> with TickerProviderStateMixin {
  late final AnimationController _traffic = AnimationController(vsync: this, duration: const Duration(seconds: 24));
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200), lowerBound: 0.92, upperBound: 1.08);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final s = AppScope.of(context);
    final still = s.reduceMotion || MediaQuery.of(context).disableAnimations;
    if (still || s.economyMode) {
      _traffic.stop();
    } else if (!_traffic.isAnimating) {
      _traffic.repeat();
    }
    if (still) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _traffic.dispose();
    _pulse.dispose();
    super.dispose();
  }

  String? _currentTarget(AppState s) {
    if (!s.pretestDone) return 'terminal';
    if (s.recommendMenaraJam && !s.doneDistricts.contains('menara_jam')) return 'menara_jam';
    for (final d in districts) {
      if (d.id == 'menara_jam') continue;
      if (!s.doneDistricts.contains(d.id) && s.isDistrictOpen(d)) return d.id;
    }
    if (s.postTestOpen && !s.posttestDone) return 'balai';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final target = _currentTarget(s);
    return CityBackdrop(
      child: SafeArea(
        child: Column(
          children: [
            _topBar(context, s),
            Expanded(
              child: LayoutBuilder(builder: (context, cons) {
                final w = cons.maxWidth;
                Offset pos(Offset f) => Offset(f.dx * w, f.dy);
                final nodes = <String, Offset>{
                  'terminal': pos(_terminal.frac),
                  for (final e in _layout.entries) e.key: pos(e.value),
                  'balai': pos(_balai.frac),
                };
                return SingleChildScrollView(
                  child: SizedBox(
                    height: 1110,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _traffic,
                            builder: (_, __) => CustomPaint(painter: _MapPainter(nodes, _traffic.value, s.economyMode)),
                          ),
                        ),
                        _nodeWidget(context, s, _terminal.id, _terminal.icon, _terminal.name, nodes['terminal']!,
                            done: s.pretestDone, open: true, current: target == 'terminal'),
                        for (final d in districts)
                          _nodeWidget(context, s, d.id, d.icon, d.name, nodes[d.id]!,
                              done: s.doneDistricts.contains(d.id),
                              open: s.isDistrictOpen(d),
                              current: target == d.id,
                              recommended: d.id == 'menara_jam' && s.recommendMenaraJam && !s.doneDistricts.contains(d.id)),
                        _nodeWidget(context, s, _balai.id, _balai.icon, _balai.name, nodes['balai']!,
                            done: s.posttestDone, open: s.postTestOpen, current: target == 'balai'),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, AppState s) {
    final p = s.profile!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
            child: VehicleView(type: p.vehicle, width: 48, color: Color(s.colorOf(p.vehicle))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('KotaLaju', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.ink)),
                Text('Halo, ${p.nickname}!', style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          _pill('🪙', '${s.coins}'),
          const SizedBox(width: 6),
          _pill('🏅', '${s.badges.length}'),
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings, color: AppColors.ink),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }

  Widget _pill(String icon, String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Text('$icon $v', style: const TextStyle(fontWeight: FontWeight.w900)),
      );

  Widget _nodeWidget(BuildContext context, AppState s, String id, String icon, String name, Offset at,
      {required bool done, required bool open, bool current = false, bool recommended = false}) {
    const size = 84.0;
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? const Color(0xFFDFF5E5) : (open ? Colors.white : const Color(0xFFE8E8E8)),
        border: Border.all(color: current ? AppColors.taxi : (done ? AppColors.right : Colors.white), width: current ? 5 : 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(icon, style: TextStyle(fontSize: 36, color: open ? null : Colors.black26)),
          if (!open) const Icon(Icons.lock, size: 30, color: Colors.black54),
          if (done) const Positioned(right: 4, bottom: 4, child: Icon(Icons.verified, color: AppColors.right, size: 24)),
        ],
      ),
    );
    return Positioned(
      left: at.dx - 70,
      top: at.dy - size / 2,
      width: 140,
      child: Semantics(
        button: true,
        label: '$name${done ? ', selesai' : ''}${open ? '' : ', terkunci'}',
        child: GestureDetector(
          onTap: () => _open(context, s, id, open),
          child: Column(
            children: [
              current ? ScaleTransition(scale: _pulse, child: circle) : circle,
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                child: Text(name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ),
              if (recommended)
                Container(
                  margin: const EdgeInsets.only(top: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.taxi, borderRadius: BorderRadius.circular(8)),
                  child: const Text('Disarankan dulu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, AppState s, String id, bool open) {
    if (!open) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selesaikan distrik sebelumnya dulu untuk membuka jalan ini.')));
      return;
    }
    final nav = Navigator.of(context);
    if (id == 'terminal') {
      nav.push(MaterialPageRoute(builder: (_) => const TestScreen(kind: TestKind.pretest)));
    } else if (id == 'balai') {
      nav.push(MaterialPageRoute(builder: (_) => const TestScreen(kind: TestKind.posttest)));
    } else {
      nav.push(MaterialPageRoute(builder: (_) => DistrictScreen(districtId: id)));
    }
  }
}

class _MapPainter extends CustomPainter {
  final Map<String, Offset> n;
  final double t;
  final bool economy;
  _MapPainter(this.n, this.t, this.economy);

  Path _curve(Offset a, Offset b) {
    final midY = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
  }

  @override
  void paint(Canvas c, Size s) {
    // rumput & blok kota
    c.drawRect(Rect.fromLTWH(0, 130, s.width, s.height), Paint()..color = AppColors.grass.withValues(alpha: 0.55));
    final rnd = Random(11);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = 150 + rnd.nextDouble() * (s.height - 180);
      if (n.values.any((o) => (o - Offset(x, y)).distance < 90)) continue;
      if (rnd.nextBool()) {
        final bw = 26 + rnd.nextDouble() * 24, bh = 30 + rnd.nextDouble() * 40;
        final col = [const Color(0xFFFFE0B2), const Color(0xFFB3E5FC), const Color(0xFFF8BBD0), const Color(0xFFDCEDC8)][i % 4];
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y - bh, bw, bh), const Radius.circular(4)), Paint()..color = col);
        for (var wy = y - bh + 6; wy < y - 8; wy += 10) {
          for (var wx = x + 4; wx < x + bw - 6; wx += 9) {
            c.drawRect(Rect.fromLTWH(wx, wy, 5, 5), Paint()..color = Colors.white.withValues(alpha: 0.85));
          }
        }
      } else {
        c.drawCircle(Offset(x, y - 14), 12, Paint()..color = const Color(0xFF66BB6A));
        c.drawRect(Rect.fromLTWH(x - 2, y - 4, 4, 8), Paint()..color = const Color(0xFF8D6E63));
      }
    }
    // jalan
    final segs = [
      _curve(n['terminal']!, n['menara_jam']!),
      _curve(n['menara_jam']!, n['bundaran_jkw']!),
      _curve(n['bundaran_jkw']!, n['bengkel_satuan']!),
      _curve(n['bengkel_satuan']!, n['jalan_cerita']!),
      _curve(n['jalan_cerita']!, n['simpang_berpapasan']!),
      _curve(n['jalan_cerita']!, n['jalur_susul']!),
      _curve(n['simpang_berpapasan']!, n['balai']!),
      _curve(n['jalur_susul']!, n['balai']!),
    ];
    final road = Paint()
      ..color = const Color(0xFF5B5B5B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = const Color(0xFFF2C94C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final p in segs) {
      c.drawPath(p, road);
    }
    for (final p in segs) {
      for (final m in p.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 22) {
          c.drawPath(m.extractPath(d, d + 11), line);
        }
      }
    }
    // kendaraan lalu-lalang (dekoratif, hanya di Mode Kota)
    final main = Path();
    for (final i in [0, 1, 2, 3, 4, 6]) {
      main.addPath(segs[i], Offset.zero);
    }
    final metrics = main.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    final types = [VehicleType.bus, VehicleType.car, VehicleType.motorbike, VehicleType.truck];
    final count = economy ? 1 : 4;
    for (var k = 0; k < count; k++) {
      var dist = ((t + k / count) % 1.0) * total;
      for (final m in metrics) {
        if (dist <= m.length) {
          final tan = m.getTangentForOffset(dist);
          if (tan != null) {
            c.save();
            c.translate(tan.position.dx, tan.position.dy);
            final ang = tan.angle;
            final faceRight = cos(-ang) >= 0;
            drawVehicleAt(c, const Offset(0, -6), 40, types[k % types.length], facingRight: faceRight, turn: t * 40);
            c.restore();
          }
          break;
        }
        dist -= m.length;
      }
    }
    // lampu lalu lintas di Simpang
    final tl = n['jalan_cerita']! + const Offset(-60, 70);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: tl, width: 16, height: 40), const Radius.circular(5)),
        Paint()..color = AppColors.ink);
    final phase = (t * 6).floor() % 3;
    for (var i = 0; i < 3; i++) {
      final colors = [AppColors.wrong, AppColors.taxi, AppColors.right];
      c.drawCircle(tl + Offset(0, -12.0 + i * 12), 5, Paint()..color = phase == i ? colors[i] : Colors.white24);
    }
    drawLabel(c, 'Pilih distrik untuk mulai belajar', Offset(s.width / 2, s.height - 16), size: 12, color: Colors.black54);
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => old.t != t || old.n != n || old.economy != economy;
}
