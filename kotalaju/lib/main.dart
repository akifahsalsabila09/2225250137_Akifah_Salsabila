import 'package:flutter/material.dart';

import 'app/theme.dart';
import 'core/data/app_state.dart';
import 'features/home/home_shell.dart';
import 'features/onboarding/onboarding_screen.dart';

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
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return s.profile == null ? const OnboardingScreen() : const HomeShell();
  }
}
