import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../core/data/app_state.dart';
import 'teacher_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return FocusScaffold(
      title: 'Pengaturan',
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            value: s.reduceMotion,
            onChanged: (v) => s.setSettings(reduce: v),
            title: const Text('Kurangi gerakan'),
            subtitle: const Text('Matikan animasi hiasan di peta dan garasi.'),
          ),
          SwitchListTile(
            value: s.economyMode,
            onChanged: (v) => s.setSettings(economy: v),
            title: const Text('Mode Hemat'),
            subtitle: const Text('Untuk HP yang terasa lambat. Animasi pelajaran tetap ada.'),
          ),
          SwitchListTile(
            value: s.profile?.consent ?? false,
            onChanged: null,
            title: const Text('Persetujuan pencatatan data'),
            subtitle: const Text('Diatur saat pendaftaran. Minta bantuan guru untuk mengubahnya.'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Mode Guru'),
            subtitle: const Text('Rekap hasil belajar dan ekspor data (perlu PIN).'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TeacherGate())),
          ),
          const Divider(),
          const ListTile(
            title: Text('Tentang KotaLaju'),
            subtitle: Text('Aplikasi belajar Jarak, Kecepatan, dan Waktu untuk SMP kelas VII. '
                'Dikembangkan oleh Akifah Salsabila (Pendidikan Matematika) berdasarkan Cognitive Load Theory '
                'untuk meningkatkan Mathematical Literacy.'),
          ),
        ],
      ),
    );
  }
}
