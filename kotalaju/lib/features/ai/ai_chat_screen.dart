import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/data/ai_client.dart';

/// Layar chat "Pak Lampu" (Tanya AI) – percakapan bebas dengan Gemini lewat perantara Netlify.
class AiChatScreen extends StatefulWidget {
  final AiClient? ai;

  /// Teks soal yang sedang dikerjakan (opsional).
  final String? konteks;
  final String? judulKonteks;
  final bool sudahDijawab;

  /// Pertanyaan yang langsung dikirim saat layar dibuka (opsional).
  final String? pertanyaanAwal;

  const AiChatScreen({
    super.key,
    this.ai,
    this.konteks,
    this.judulKonteks,
    this.sudahDijawab = false,
    this.pertanyaanAwal,
  });

  static Future<void> open(
    BuildContext context, {
    String? konteks,
    String? judulKonteks,
    bool sudahDijawab = false,
    String? pertanyaanAwal,
    AiClient? ai,
  }) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AiChatScreen(
        ai: ai,
        konteks: konteks,
        judulKonteks: judulKonteks,
        sudahDijawab: sudahDijawab,
        pertanyaanAwal: pertanyaanAwal,
      ),
    ));
  }

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _Msg {
  final bool fromUser;
  final String text;
  final bool error;
  final bool intro;
  int shown;
  _Msg(this.fromUser, this.text, {this.error = false, this.intro = false}) : shown = fromUser || error || intro ? text.length : 0;
  bool get typing => shown < text.length;
}

class _AiChatScreenState extends State<AiChatScreen> {
  late final AiClient _ai = widget.ai ?? AiClient();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _waiting = false;
  Timer? _typer;

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
      false,
      widget.konteks == null
          ? 'Halo! Aku **Pak Lampu** 🚦, teman belajarmu.\nTanya apa saja tentang **jarak, kecepatan, dan waktu**, ya. Aku bantu langkah demi langkah!'
          : 'Halo! Aku **Pak Lampu** 🚦. Kita bahas **${widget.judulKonteks ?? 'soal ini'}** bareng, yuk.\n'
              '${widget.sudahDijawab ? 'Kamu sudah menjawab, jadi kita bisa bahas caranya sampai tuntas.' : 'Aku tidak akan langsung memberi jawabannya, tapi aku bantu kamu menemukannya sendiri.'}',
      intro: true,
    ));
    if (widget.pertanyaanAwal != null && widget.pertanyaanAwal!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(widget.pertanyaanAwal!));
    }
  }

  @override
  void dispose() {
    _typer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  List<String> get _saran => widget.konteks == null
      ? const [
          'Bagaimana mengubah menit ke jam?',
          'Apa rumus kecepatan?',
          'Kenapa kecepatan rata-rata bukan rata-rata dua kecepatan?',
          'Kasih aku 1 soal latihan dong!',
        ]
      : [
          'Aku harus mulai dari mana?',
          'Apa saja yang diketahui di soal ini?',
          'Rumus apa yang dipakai?',
          if (widget.sudahDijawab) 'Jelaskan pembahasannya pelan-pelan',
        ];

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  void _finishTyping() {
    _typer?.cancel();
    for (final m in _msgs) {
      m.shown = m.text.length;
    }
  }

  Future<void> _send(String text) async {
    final q = text.trim();
    if (q.isEmpty || _waiting) return;
    _finishTyping();
    _input.clear();
    setState(() {
      _msgs.add(_Msg(true, q));
      _waiting = true;
    });
    _scrollToEnd();
    final history = [
      for (final m in _msgs)
        if (!m.intro && !m.error) AiMessage(m.fromUser, m.text),
    ];
    try {
      final reply = await _ai.chat(history, konteks: widget.konteks, sudahDijawab: widget.sudahDijawab);
      if (!mounted) return;
      final msg = _Msg(false, reply);
      setState(() {
        _waiting = false;
        _msgs.add(msg);
      });
      _typer = Timer.periodic(const Duration(milliseconds: 16), (t) {
        if (!mounted) return t.cancel();
        setState(() => msg.shown = min(msg.text.length, msg.shown + 3));
        if (!msg.typing) t.cancel();
        _scrollToEnd();
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _waiting = false;
        _msgs.add(_Msg(false, e.message, error: true));
      });
    }
    _scrollToEnd();
  }

  void _retry() {
    final lastUser = _msgs.lastWhere((m) => m.fromUser, orElse: () => _Msg(true, ''));
    if (lastUser.text.isEmpty) return;
    setState(() {
      _msgs.removeWhere((m) => m.error);
      _msgs.remove(lastUser);
    });
    _send(lastUser.text);
  }

  void _reset() {
    _finishTyping();
    setState(() => _msgs.removeRange(1, _msgs.length));
  }

  @override
  Widget build(BuildContext context) {
    final onlyIntro = _msgs.length == 1;
    return Scaffold(
      backgroundColor: AppColors.focusBg,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(children: [
          CircleAvatar(backgroundColor: AppColors.taxi, child: Text('🚦', style: TextStyle(fontSize: 20))),
          SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pak Lampu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Tutor AI • jarak, kecepatan, waktu', style: TextStyle(fontSize: 12, color: Colors.black54)),
          ]),
        ]),
        actions: [
          IconButton(tooltip: 'Mulai percakapan baru', onPressed: _waiting ? null : _reset, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (widget.judulKonteks != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFFFF3C4),
                child: Text('📌 Membahas: ${widget.judulKonteks}', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                children: [
                  for (final m in _msgs) _bubble(m),
                  if (_waiting) const _TypingBubble(),
                  if (onlyIntro && !_waiting) ...[
                    const SizedBox(height: 8),
                    const Text('Coba tanya:', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in _saran)
                          ActionChip(
                            label: Text(s),
                            avatar: const Icon(Icons.chat_bubble_outline, size: 16),
                            onPressed: () => _send(s),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(_Msg m) {
    final user = m.fromUser;
    final shownText = m.text.substring(0, m.shown);
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: m.typing ? () => setState(_finishTyping) : null,
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: m.text));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teks disalin.')));
        },
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: user ? AppColors.distance : (m.error ? const Color(0xFFFFEBEE) : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(user ? 18 : 4),
              bottomRight: Radius.circular(user ? 4 : 18),
            ),
            border: user ? null : Border.all(color: m.error ? AppColors.wrong : const Color(0xFFE6E0D2)),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: user
              ? Text(m.text, style: const TextStyle(color: Colors.white, fontSize: 15.5, height: 1.4))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.error) ...[
                      Text(m.text, style: const TextStyle(color: AppColors.wrong, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      OutlinedButton.icon(onPressed: _retry, icon: const Icon(Icons.refresh), label: const Text('Coba lagi')),
                    ] else
                      RichAnswer(shownText + (m.typing ? ' ▍' : '')),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E0D2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Tulis pertanyaanmu…',
                    filled: true,
                    fillColor: const Color(0xFFF5F2EA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: 'Kirim',
                onPressed: _waiting ? null : () => _send(_input.text),
                style: IconButton.styleFrom(backgroundColor: AppColors.distance, foregroundColor: Colors.white),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Pak Lampu memakai AI (Gemini) dan bisa keliru. Cek lagi dengan rumus, ya.',
              style: TextStyle(fontSize: 11, color: Colors.black45)),
        ],
      ),
    );
  }
}

/// Menampilkan teks AI dengan format sederhana: **tebal**, daftar "- " / "1. ", dan judul "#".
class RichAnswer extends StatelessWidget {
  final String text;
  const RichAnswer(this.text, {super.key});

  static List<InlineSpan> _inline(String s) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var i = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > i) spans.add(TextSpan(text: s.substring(i, m.start)));
      spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w900)));
      i = m.end;
    }
    if (i < s.length) spans.add(TextSpan(text: s.substring(i).replaceAll('**', '')));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 15.5, height: 1.45, color: AppColors.ink);
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in lines)
          Builder(builder: (_) {
            final line = raw.trimRight();
            if (line.trim().isEmpty) return const SizedBox(height: 6);
            final heading = RegExp(r'^#{1,6}\s+(.*)').firstMatch(line.trim());
            if (heading != null) {
              return Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 2),
                child: Text.rich(TextSpan(children: _inline(heading.group(1)!)),
                    style: base.copyWith(fontWeight: FontWeight.w900, fontSize: 16.5)),
              );
            }
            final bullet = RegExp(r'^\s*[-*•]\s+(.*)').firstMatch(line);
            final number = RegExp(r'^\s*(\d+)[.)]\s+(.*)').firstMatch(line);
            if (bullet != null || number != null) {
              final marker = bullet != null ? '•' : '${number!.group(1)}.';
              final content = bullet != null ? bullet.group(1)! : number!.group(2)!;
              return Padding(
                padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(
                    width: 24,
                    child: Text(marker, style: base.copyWith(fontWeight: FontWeight.w900, color: AppColors.distance)),
                  ),
                  Expanded(child: Text.rich(TextSpan(children: _inline(content)), style: base)),
                ]),
              );
            }
            return Text.rich(TextSpan(children: _inline(line)), style: base);
          }),
      ],
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6E0D2)),
        ),
        child: Semantics(
          label: 'Pak Lampu sedang mengetik',
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Transform.translate(
                      offset: Offset(0, -4 * max(0, sin((_c.value * 2 * pi) - i * 0.9))),
                      child: const CircleAvatar(radius: 4, backgroundColor: AppColors.distance),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
