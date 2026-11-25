import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../features/ai/ai_chat_screen.dart';
import '../data/ai_client.dart';
import '../domain/tanya_jawab.dart';

/// Tanya Jawab: ketik pertanyaan, muncul jawaban siap pakai yang paling cocok.
/// Bila belum puas, siswa bisa mengobrol dengan Pak Lampu (AI).
class TanyaSheet extends StatefulWidget {
  final AiClient? ai;
  const TanyaSheet({super.key, this.ai});

  static Future<void> show(BuildContext context, {AiClient? ai}) => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.focusBg,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(height: MediaQuery.of(ctx).size.height * 0.85, child: TanyaSheet(ai: ai)),
        ),
      );

  @override
  State<TanyaSheet> createState() => _TanyaSheetState();
}

class _TanyaSheetState extends State<TanyaSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _askAi() {
    FocusScope.of(context).unfocus();
    AiChatScreen.open(context, ai: widget.ai, pertanyaanAwal: _query.trim().isEmpty ? null : _query.trim());
  }

  @override
  Widget build(BuildContext context) {
    final results = cariTanyaJawab(_query);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Text('❓ Tanya Jawab', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: 'Tutup'),
            ]),
            TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              maxLength: 500,
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Tulis pertanyaanmu, misal: menit ke jam',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Hapus',
                        onPressed: () => setState(() {
                          _ctrl.clear();
                          _query = '';
                        }),
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
              onSubmitted: (_) {
                if (cariTanyaJawab(_query).isEmpty) _askAi();
              },
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _askAi,
                style: FilledButton.styleFrom(backgroundColor: AppColors.distance, foregroundColor: Colors.white),
                icon: const Text('🤖', style: TextStyle(fontSize: 18)),
                label: Text(_query.trim().isEmpty ? 'Ngobrol dengan Pak Lampu (AI)' : 'Tanya AI'),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Belum ada jawaban siap untuk pertanyaan itu. Tekan "Tanya AI" untuk bertanya ke Pak Lampu.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  for (var i = 0; i < results.length; i++)
                    Card(
                      child: ExpansionTile(
                        key: ValueKey('${results[i].tanya}-$_query'),
                        initiallyExpanded: _query.isNotEmpty && i == 0,
                        leading: const Icon(Icons.help, color: AppColors.distance),
                        title: Text(results[i].tanya, style: const TextStyle(fontWeight: FontWeight.w800)),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text(results[i].jawab, style: const TextStyle(fontSize: 15, height: 1.5))],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
