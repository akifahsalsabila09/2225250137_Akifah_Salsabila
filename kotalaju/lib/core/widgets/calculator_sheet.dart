import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../domain/calc.dart';
import '../domain/format.dart';

/// Kalkulator sederhana untuk siswa (+ − × ÷, desimal dengan koma).
class CalculatorSheet extends StatefulWidget {
  const CalculatorSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.focusBg,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (_) => const CalculatorSheet(),
      );

  @override
  State<CalculatorSheet> createState() => _CalculatorSheetState();
}

class _CalculatorSheetState extends State<CalculatorSheet> {
  String _expr = '';
  String? _result;

  static String _plain(double v) => fmtNum(v, maxDecimals: 4).replaceAll('.', '');

  void _press(String k) {
    setState(() {
      switch (k) {
        case 'C':
          _expr = '';
          _result = null;
        case '⌫':
          if (_expr.isNotEmpty) _expr = _expr.substring(0, _expr.length - 1);
          _result = null;
        case '=':
          final v = CalcEngine.evaluate(_expr);
          if (v == null) {
            _result = _expr.contains('÷0') ? 'Tidak bisa dibagi 0' : 'Belum lengkap';
          } else {
            _result = '= ${fmtNum(v, maxDecimals: 4)}';
            _expr = _plain(v);
          }
        default:
          final isOp = CalcEngine.ops.contains(k);
          if (isOp && _expr.isNotEmpty && CalcEngine.ops.contains(_expr[_expr.length - 1])) {
            _expr = _expr.substring(0, _expr.length - 1) + k;
          } else if (isOp && _expr.isEmpty && k != '−') {
            // abaikan operator di awal
          } else {
            _expr += k;
          }
          _result = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final preview = CalcEngine.evaluate(_expr);
    const keys = [
      ['C', '⌫', '÷', '×'],
      ['7', '8', '9', '−'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', ',', '00', '='],
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Text('🧮 Kalkulator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: 'Tutup'),
            ]),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_expr.isEmpty ? '0' : _expr,
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  Text(
                    _result ?? (preview != null && CalcEngine.ops.any(_expr.contains) ? '= ${fmtNum(preview, maxDecimals: 4)}' : ' '),
                    style: const TextStyle(color: Color(0xFFB2FF59), fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text('Tips: 30 menit = 30 ÷ 60 jam. Pakai koma untuk desimal.', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            for (final row in keys)
              Row(
                children: [
                  for (final k in row)
                    if (!(k == '=' && row == keys.last))
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: SizedBox(
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.zero,
                                backgroundColor: k == '='
                                    ? AppColors.right
                                    : CalcEngine.ops.contains(k)
                                        ? AppColors.speed
                                        : (k == 'C' || k == '⌫')
                                            ? AppColors.wrong
                                            : Colors.white,
                                foregroundColor: (k == '=' || CalcEngine.ops.contains(k) || k == 'C' || k == '⌫')
                                    ? Colors.white
                                    : AppColors.ink,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () => _press(k),
                              child: Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
