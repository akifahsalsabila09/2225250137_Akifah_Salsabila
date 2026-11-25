import 'package:flutter/material.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/domain/motion.dart';
import '../../core/widgets/vehicle.dart';

/// Onboarding: nama panggilan, kelas, kendaraan awal, persetujuan data (F-01, F-04).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  final _classCode = TextEditingController();
  int _grade = 7;
  VehicleType _vehicle = VehicleType.bicycle;
  bool _consent = false;
  int _page = 0;

  @override
  void dispose() {
    _name.dispose();
    _classCode.dispose();
    super.dispose();
  }

  void _finish() {
    AppScope.read(context).createProfile(
      nickname: _name.text.trim(),
      grade: _grade,
      classCode: _classCode.text.trim(),
      vehicle: _vehicle,
      consent: _consent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CityBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.focusBg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: switch (_page) { 0 => _welcome(), 1 => _profile(), _ => _consentPage() },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _welcome() => Column(
        key: const ValueKey(0),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🚦', style: TextStyle(fontSize: 64)),
          const Text('Selamat datang di KotaLaju!', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
            'Ada 7 soal tentang jarak, kecepatan, dan waktu. '
            'Kerjakan langkah demi langkah. Kalau bingung, buka petunjuknya!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17),
          ),
          const SizedBox(height: 16),
          const Wrap(spacing: 8, children: [
            VehicleView(type: VehicleType.bus, width: 80),
            VehicleView(type: VehicleType.car, width: 70),
            VehicleView(type: VehicleType.bicycle, width: 60),
          ]),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () => setState(() => _page = 1), child: const Text('Ayo mulai!'))),
        ],
      );

  Widget _profile() {
    final ok = _name.text.trim().isNotEmpty;
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Kenalan dulu, yuk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama panggilan', helperText: 'Cukup nama panggilan saja.'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('Kelas:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            for (final g in [7, 8, 9])
              ChoiceChip(label: Text('$g'), selected: _grade == g, onSelected: (_) => setState(() => _grade = g)),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _classCode,
          decoration: const InputDecoration(labelText: 'Kode kelas (opsional)', helperText: 'Dari gurumu, misalnya 7A'),
        ),
        const SizedBox(height: 14),
        const Text('Pilih kendaraan pertamamu:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final v in [VehicleType.bicycle, VehicleType.motorbike, VehicleType.car, VehicleType.bus])
              GestureDetector(
                onTap: () => setState(() => _vehicle = v),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _vehicle == v ? AppColors.taxi : Colors.black12, width: _vehicle == v ? 4 : 1.5),
                  ),
                  child: Column(children: [
                    VehicleView(type: v, width: 70),
                    Text(v.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: ok ? () => setState(() => _page = 2) : null, child: const Text('Lanjut')),
      ],
    );
  }

  Widget _consentPage() => Column(
        key: const ValueKey(2),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Boleh kami mencatat cara belajarmu?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const Text(
            'Aplikasi ini dipakai untuk penelitian. Kami ingin mencatat jawabanmu, petunjuk yang kamu buka, '
            'dan lama mengerjakan soal. Kami TIDAK mencatat nama lengkap, foto, lokasi, atau nomor HP. '
            'Data tersimpan di HP ini dan hanya dibuka gurumu.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          const Text('Kalau tidak setuju, kamu tetap bisa memakai semua fitur.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _consent,
            onChanged: (v) => setState(() => _consent = v),
            title: const Text('Saya setuju', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _finish, child: const Text('Masuk ke KotaLaju 🚗')),
        ],
      );
}
