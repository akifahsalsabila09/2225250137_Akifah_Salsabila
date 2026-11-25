import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../domain/problem.dart';
import 'glossary.dart';

/// Menampilkan soal cerita: satu kalimat per baris (segmenting).
/// Token angka dapat diketuk untuk Penanda Info; istilah bergaris bawah membuka Kamus Jalan.
class StoryView extends StatelessWidget {
  final List<List<StoryPart>> story;
  final Map<String, TagKind> tags;
  final String? selected;
  final ValueChanged<String>? onTokenTap;
  final bool revealTruth;
  final bool showExampleFirst;

  const StoryView({
    super.key,
    required this.story,
    this.tags = const {},
    this.selected,
    this.onTokenTap,
    this.revealTruth = false,
    this.showExampleFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final sentence in story)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text.rich(
              TextSpan(children: [for (final p in sentence) _span(context, p)]),
              style: const TextStyle(fontSize: 17, height: 1.7, color: AppColors.ink),
            ),
          ),
      ],
    );
  }

  InlineSpan _span(BuildContext context, StoryPart p) {
    if (p.glossary != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: GestureDetector(
          onTap: () => showGlossary(context, p.glossary!),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: p.text),
              const WidgetSpan(child: Icon(Icons.menu_book, size: 15, color: AppColors.distance)),
            ]),
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.distance,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
        ),
      );
    }
    final tok = p.token;
    if (tok == null) return TextSpan(text: p.text);
    final kind = revealTruth ? tok.kind : tags[tok.id];
    final isSel = selected == tok.id;
    final color = kind?.color ?? AppColors.ink;
    final strike = kind == TagKind.irrelevant;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Semantics(
        button: onTokenTap != null,
        label: '${tok.text}${kind != null ? ', ditandai ${kind.label}' : ''}',
        child: GestureDetector(
          onTap: onTokenTap == null ? null : () => onTokenTap!(tok.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: kind == null ? const Color(0xFFF1F1F1) : color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSel ? AppColors.ink : (kind == null ? const Color(0xFFBDBDBD) : color), width: isSel ? 2.5 : 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (kind != null) Icon(kind.icon, size: 15, color: color),
                if (kind != null) const SizedBox(width: 3),
                Text(
                  tok.text,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kind == null ? AppColors.ink : color,
                    decoration: strike ? TextDecoration.lineThrough : null,
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

/// Ringkasan "Diketahui" berdasarkan tanda siswa (GL04).
class KnownSummary extends StatelessWidget {
  final Problem problem;
  final Map<String, TagKind> tags;
  const KnownSummary({super.key, required this.problem, required this.tags});

  @override
  Widget build(BuildContext context) {
    final items = problem.tokens.where((t) => tags[t.id] != null && tags[t.id] != TagKind.irrelevant).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E1D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diketahui', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in items)
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(tags[t.id]!.icon, size: 16, color: tags[t.id]!.color),
                  label: Text('${tags[t.id]!.label}: ${t.text}'),
                  side: BorderSide(color: tags[t.id]!.color),
                  backgroundColor: tags[t.id]!.color.withValues(alpha: 0.08),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
