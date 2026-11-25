import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/data/content.dart';
import '../../core/widgets/common.dart';
import 'catch_bus_game.dart';
import 'courier_route_game.dart';
import 'meeting_point_game.dart';
import 'traffic_detective_game.dart';
import 'unit_rally_game.dart';

const tierNames = ['Pemula', 'Lancar', 'Jago'];

/// Arena Kota: game untuk latihan dan penguatan, terbuka setelah distrik terkait.
class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return CityBackdrop(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('🎮 Arena Kota', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const Text('Game terbuka setelah kamu mendapat SIM distriknya.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [for (final g in games) _gameCard(context, s, g)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gameCard(BuildContext context, AppState s, GameInfo g) {
    final open = s.isGameUnlocked(g);
    return Material(
      color: open ? Colors.white : Colors.white60,
      borderRadius: BorderRadius.circular(22),
      elevation: open ? 3 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: open
            ? () => _chooseTier(context, g)
            : () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Dapatkan SIM ${districtById(g.unlockedBy).name} untuk membuka game ini.')),
                ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(g.icon, style: TextStyle(fontSize: 52, color: open ? null : Colors.black26)),
                ),
              ),
              Text(g.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 2),
              Text(open ? g.desc : '🔒 ${districtById(g.unlockedBy).name}',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              if (open) StarRow(stars: s.bestStars(g.id), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _chooseTier(BuildContext context, GameInfo g) {
    final s = AppScope.read(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.focusBg,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${g.icon} ${g.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text(g.desc),
              const SizedBox(height: 12),
              for (var t = 1; t <= 3; t++)
                Card(
                  child: ListTile(
                    title: Text(tierNames[t - 1], style: const TextStyle(fontWeight: FontWeight.w900)),
                    trailing: StarRow(stars: s.gameStars['${g.id}_$t'] ?? 0),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => _gameFor(g.id, t)));
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gameFor(String id, int tier) => switch (id) {
        'unit_rally' => UnitRallyGame(tier: tier),
        'meeting_point' => MeetingPointGame(tier: tier),
        'catch_bus' => CatchBusGame(tier: tier),
        'courier_route' => CourierRouteGame(tier: tier),
        _ => TrafficDetectiveGame(tier: tier),
      };
}

/// Layar hasil game (dipakai semua game).
Future<void> finishGame(BuildContext context, {required String gameId, required int tier, required int stars, required Map<String, dynamic> details}) async {
  AppScope.read(context).recordGame(gameId, tier, stars, details);
  await showCelebration(
    context,
    title: stars >= 2 ? 'Keren!' : (stars == 1 ? 'Lumayan!' : 'Ayo coba lagi!'),
    subtitle: '+${stars * 5} koin',
    hero: StarRow(stars: stars, size: 48),
  );
  if (context.mounted) Navigator.of(context).pop();
}
