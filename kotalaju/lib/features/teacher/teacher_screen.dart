import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/scaffolds.dart';
import '../../app/theme.dart';
import '../../core/data/app_state.dart';
import '../../core/data/csv_export.dart';
import '../../core/domain/problem.dart';

/// Gerbang PIN Mode Guru (F-80).
class TeacherGate extends StatefulWidget {
  const TeacherGate({super.key});
  @override
  State<TeacherGate> createState() => _TeacherGateState();
}

class _TeacherGateState extends State<TeacherGate> {
  final _pin = TextEditingController();
  final _pin2 = TextEditingController();
  String? _error;
  bool _ok = false;

  @override
  void dispose() {
    _pin.dispose();
    _pin2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (_ok) return const TeacherScreen();
    final creating = s.teacherPinHash == null;
    return FocusScaffold(
      title: 'Mode Guru',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(creating ? 'Buat PIN guru (4–6 angka)' : 'Masukkan PIN guru',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'PIN'),
          ),
          if (creating)
            TextField(
              controller: _pin2,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'Ulangi PIN'),
            ),
          if (_error != null) Text(_error!, style: const TextStyle(color: AppColors.wrong, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              final pin = _pin.text.trim();
              if (creating) {
                if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                  setState(() => _error = 'PIN harus 4–6 angka.');
                } else if (pin != _pin2.text.trim()) {
                  setState(() => _error = 'PIN tidak sama.');
                } else {
                  s.setTeacherPin(pin);
                  setState(() => _ok = true);
                }
              } else if (s.checkTeacherPin(pin)) {
                setState(() => _ok = true);
              } else {
                setState(() => _error = 'PIN salah.');
              }
            },
            child: Text(creating ? 'Simpan PIN' : 'Masuk'),
          ),
        ],
      ),
    );
  }
}

class TeacherScreen extends StatelessWidget {
  const TeacherScreen({super.key});

  String _fmt(double? v, {int d = 2}) => v == null ? '–' : v.toStringAsFixed(d).replaceAll('.', ',');

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.profile;
    final pre = s.pretestByIndicator, post = s.posttestByIndicator;
    final efforts = s.attempts.where((a) => a.mentalEffort != null).map((a) => a.mentalEffort!).toList();
    final avgEffort = efforts.isEmpty ? null : efforts.reduce((a, b) => a + b) / efforts.length;
    final errorCounts = <ErrorCategory, int>{};
    for (final a in s.attempts) {
      for (final st in a.steps) {
        if (st.error != null && !st.correct) errorCounts[st.error!.category] = (errorCounts[st.error!.category] ?? 0) + 1;
      }
    }
    return FocusScaffold(
      title: 'Mode Guru',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, size: 34),
              title: Text('${p?.nickname ?? '-'} • Kelas ${p?.grade ?? '-'} ${p?.classCode ?? ''}'),
              subtitle: Text('ID: ${p?.studentId ?? '-'}\nPersetujuan data: ${p?.consent == true ? 'Ya' : 'Tidak'}'),
              isThreeLine: true,
            ),
          ),
          const SizedBox(height: 8),
          const Text('Mathematical Literacy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Indikator')),
                DataColumn(label: Text('Pretest'), numeric: true),
                DataColumn(label: Text('Posttest'), numeric: true),
              ],
              rows: [
                for (final i in Indicator.values)
                  DataRow(cells: [
                    DataCell(Text(i.en)),
                    DataCell(Text('${pre?[i] ?? '–'}')),
                    DataCell(Text('${post?[i] ?? '–'}')),
                  ]),
                DataRow(cells: [
                  const DataCell(Text('Total (maks 24)', style: TextStyle(fontWeight: FontWeight.w900))),
                  DataCell(Text('${s.pretestScore ?? '–'}', style: const TextStyle(fontWeight: FontWeight.w900))),
                  DataCell(Text('${s.posttestScore ?? '–'}', style: const TextStyle(fontWeight: FontWeight.w900))),
                ]),
              ],
            ),
          ),
          Card(
            child: Column(children: [
              ListTile(title: const Text('N-gain'), trailing: Text(_fmt(s.nGain))),
              ListTile(title: const Text('Prasyarat jam & pecahan'), trailing: Text('${s.prereqScore ?? '–'} / 6')),
              ListTile(
                  title: const Text('Proporsi kesalahan satuan (pre → post)'),
                  trailing: Text('${_fmt(s.unitErrorRate('pretest'))} → ${_fmt(s.unitErrorRate('posttest'))}')),
              ListTile(title: const Text('Rata-rata usaha mental (1–9)'), trailing: Text(_fmt(avgEffort, d: 1))),
              ListTile(title: const Text('Jumlah soal dikerjakan'), trailing: Text('${s.attempts.length}')),
              ListTile(title: const Text('Distrik selesai'), trailing: Text('${s.doneDistricts.length} / 6')),
            ]),
          ),
          const SizedBox(height: 8),
          const Text('Jenis kesalahan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          for (final e in errorCounts.entries)
            ListTile(dense: true, leading: Icon(e.key.icon), title: Text(e.key.label), trailing: Text('${e.value}')),
          if (errorCounts.isEmpty) const Text('Belum ada data.'),
          const SizedBox(height: 8),
          const Text('Level bantuan per langkah', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Wrap(spacing: 6, children: [
            for (final k in StepKind.values) Chip(label: Text('${k.title}: L${s.adaptive.levelFor(k)}')),
          ]),
          const Divider(height: 28),
          SwitchListTile(
            value: s.mentalEffortEnabled,
            onChanged: (v) => s.setSettings(mentalEffort: v),
            title: const Text('Tanyakan usaha mental setelah kuis'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _export(context, s),
            icon: const Icon(Icons.download),
            label: const Text('Ekspor data (CSV)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, s),
            icon: const Icon(Icons.delete_forever, color: AppColors.wrong),
            label: const Text('Hapus semua data siswa di HP ini', style: TextStyle(color: AppColors.wrong)),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, AppState s) async {
    if (s.profile?.consent != true) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidak bisa ekspor'),
          content: const Text('Siswa belum menyetujui pencatatan data untuk penelitian.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Oke'))],
        ),
      );
      return;
    }
    final files = CsvExport.build(s);
    String where = '';
    if (!kIsWeb) {
      try {
        final dir = (Platform.isAndroid ? await getExternalStorageDirectory() : null) ?? await getApplicationDocumentsDirectory();
        final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
        for (final e in files.entries) {
          await File('${dir.path}/kotalaju_${s.profile!.studentId}_${stamp}_${e.key}').writeAsString(e.value);
        }
        where = dir.path;
      } catch (e) {
        where = '';
      }
    }
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ekspor selesai'),
        content: Text(where.isEmpty
            ? 'Berkas tidak dapat disimpan di perangkat ini. Salin datanya lewat tombol di bawah.'
            : 'Tiga berkas CSV (attempts, steps, summary) disimpan di:\n$where'),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: files.entries.map((e) => '### ${e.key}\n${e.value}').join('\n')));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data CSV disalin.')));
            },
            child: const Text('Salin ke clipboard'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState s) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua data?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Semua kemajuan, skor, dan data penelitian di HP ini akan hilang. Ketik HAPUS untuk melanjutkan.'),
          TextField(controller: ctrl),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim().toUpperCase() == 'HAPUS'), child: const Text('Hapus')),
        ],
      ),
    );
    ctrl.dispose();
    if (ok == true) {
      await s.resetAll();
      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }
}
