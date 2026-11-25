import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../domain/format.dart';
import '../domain/units.dart';

enum CalcMode { full, check, locked }

/// Kalkulator Satuan (DS01). Menampilkan LANGKAH konversi, bukan hanya hasil.
class UnitCalculator extends StatefulWidget {
  final Quantity? initial;
  final Unit? target;
  const UnitCalculator({super.key, this.initial, this.target});

  static Future<void> show(BuildContext context, {Quantity? initial, Unit? target}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.focusBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: UnitCalculator(initial: initial, target: target),
      ),
    );
  }

  @override
  State<UnitCalculator> createState() => _UnitCalculatorState();
}

class _UnitCalculatorState extends State<UnitCalculator> {
  late Dimension _dim = widget.initial?.dimension ?? Dimension.time;
  late Unit _from = widget.initial?.unit ?? Unit.min;
  late Unit _to = widget.target ?? Unit.h;
  late final _ctrl = TextEditingController(text: widget.initial == null ? '45' : fmtNum(widget.initial!.value, maxDecimals: 3));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setDim(Dimension d) {
    final us = Unit.of(d);
    setState(() {
      _dim = d;
      _from = us.first;
      _to = us.length > 1 ? us[1] : us.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = parseNum(_ctrl.text);
    final steps = v == null ? null : UnitEngine.explain(Quantity(v, _from), _to);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              const Icon(Icons.build_circle, color: AppColors.speed, size: 30),
              const SizedBox(width: 8),
              Text('Kalkulator Satuan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 12),
            SegmentedButton<Dimension>(
              segments: const [
                ButtonSegment(value: Dimension.time, label: Text('Waktu'), icon: Icon(Icons.timer_outlined)),
                ButtonSegment(value: Dimension.distance, label: Text('Jarak'), icon: Icon(Icons.straighten)),
                ButtonSegment(value: Dimension.speed, label: Text('Laju'), icon: Icon(Icons.speed)),
              ],
              selected: {_dim},
              onSelectionChanged: (s) => _setDim(s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Angka'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _unitRow('Dari', _from, (u) => setState(() => _from = u)),
            const SizedBox(height: 6),
            _unitRow('Ke', _to, (u) => setState(() => _to = u)),
            const SizedBox(height: 14),
            if (steps != null)
              for (var i = 0; i < steps.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(radius: 14, backgroundColor: _dim.color, child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(steps[i].description, style: const TextStyle(fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(steps[i].expression, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _dim.color)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _unitRow(String label, Unit selected, ValueChanged<Unit> onPick) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final u in Unit.of(_dim))
                ChoiceChip(
                  label: Text(u.label),
                  selected: u == selected,
                  onSelected: (_) => onPick(u),
                  selectedColor: _dim.color.withValues(alpha: 0.25),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
