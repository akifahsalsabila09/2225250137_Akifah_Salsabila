import 'package:flutter/material.dart';

import '../city_map/city_map_screen.dart';
import '../games/arena_screen.dart';
import '../garage/garage_screen.dart';
import '../quiz/quiz_hub.dart';

/// Navigasi utama: Peta (materi), Arena (game), Kuis, Garasi.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [CityMapScreen(), ArenaScreen(), QuizHubScreen(), GarageScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Peta'),
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: 'Arena'),
          NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz), label: 'Kuis'),
          NavigationDestination(icon: Icon(Icons.garage_outlined), selectedIcon: Icon(Icons.garage), label: 'Garasi'),
        ],
      ),
    );
  }
}
