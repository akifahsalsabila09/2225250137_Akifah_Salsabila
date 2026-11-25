import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../data/ai_client.dart';
import '../domain/tanya_jawab.dart';

/// Tanya Jawab: ketik pertanyaan, muncul jawaban yang paling cocok.
/// Bila belum puas, siswa bisa bertanya ke AI (Gemini lewat perantara Netlify).
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

class _AiTurn {
  final String tanya;
  String? jawab;
  String? error;
  _AiTurn(this.tanya);
}

class _TanyaSheetState extends State<TanyaSheet> {
  final _ctrl = TextEditingController();
  late final AiClient _ai = widget.ai ?? AiClient();
  String _query = '';
  final List<_AiTurn> _turns = [];
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _askAi() async {
    final q = _query.trim();
    if (q.isEmpty || _loading) return;
    FocusScope.of(context).unfocus();
    final turn = _AiTurn(q);
    setState(() {
      _turns.insert(0, turn);
      _loading = true;
    });
    try {
      final a = await _ai.tanya(q);
      turn.jawab = a;
    } on AiException catch (e) {
      turn.error = e.message;
    }
    if (mounted) setState(() => _loading = false);
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
            if (_query.trim().isNotEmpty)
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _askAi,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.distance, foregroundColor: Colors.white),
                  icon: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('🤖', style: TextStyle(fontSize: 18)),
                  label: Text(_loading ? 'AI sedang berpikir…' : 'Tanya AI'),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final t in _turns) _aiBubble(t),
                  if (_turns.isNotEmpty) const Divider(height: 24),
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'Belum ada jawaban siap untuk pertanyaan itu. Tekan "Tanya AI" atau coba kata lain, misalnya: rumus, menit, jam, km, rata-rata.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  for (var i = 0; i < results.length; i++)
                    Card(
                      child: ExpansionTile(
                        key: ValueKey('${results[i].tanya}-$_query'),
                        initiallyExpanded: _query.isNotEmpty && i == 0 && _turns.isEmpty,
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

  Widget _aiBubble(_AiTurn t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(left: 40, bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFDCEBFF), borderRadius: BorderRadius.circular(14)),
              child: Text(t.tanya, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.error != null ? AppColors.wrong : const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🤖 Pak Lampu (AI)', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.distance)),
                const SizedBox(height: 4),
                if (t.jawab == null && t.error == null)
                  const Text('Sedang berpikir…', style: TextStyle(fontStyle: FontStyle.italic))
                else if (t.error != null)
                  Text(t.error!, style: const TextStyle(color: AppColors.wrong, fontWeight: FontWeight.w700))
                else ...[
                  SelectableText(t.jawab!, style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 6),
                  const Text('Jawaban AI bisa keliru. Cek lagi dengan rumus dan pembahasan, ya.',
                      style: TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
