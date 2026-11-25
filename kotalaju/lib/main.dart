import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'core/data/app_state.dart';
import 'features/ride/ride_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(KotaLajuApp(state: state));
}

class KotaLajuApp extends StatelessWidget {
  final AppState state;
  const KotaLajuApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'KotaLaju',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Aplikasi hanya berisi permainan sepeda dengan 7 koin soal.
        home: const RideScreen(),
      ),
    );
  }
}
