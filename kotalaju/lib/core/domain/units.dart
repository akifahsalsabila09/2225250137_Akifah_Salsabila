import 'format.dart';

enum Dimension { distance, time, speed }

enum Unit {
  km('km', Dimension.distance, 1000),
  hm('hm', Dimension.distance, 100),
  dam('dam', Dimension.distance, 10),
  m('m', Dimension.distance, 1),
  h('jam', Dimension.time, 3600),
  min('menit', Dimension.time, 60),
  s('detik', Dimension.time, 1),
  kmPerH('km/jam', Dimension.speed, 1000 / 3600),
  mPerMin('m/menit', Dimension.speed, 1 / 60),
  mPerS('m/detik', Dimension.speed, 1);

  const Unit(this.label, this.dimension, this.toBase);

  final String label;
  final Dimension dimension;

  /// Faktor ke satuan dasar (m, detik, m/detik).
  final double toBase;

  static List<Unit> of(Dimension d) => values.where((u) => u.dimension == d).toList();

  Unit get distancePart => switch (this) {
        Unit.kmPerH => Unit.km,
        Unit.mPerMin || Unit.mPerS => Unit.m,
        _ => this,
      };

  Unit get timePart => switch (this) {
        Unit.kmPerH => Unit.h,
        Unit.mPerMin => Unit.min,
        Unit.mPerS => Unit.s,
        _ => this,
      };
}

/// Besaran = nilai + satuan. Logika domain tidak memakai angka tanpa satuan.
class Quantity {
  final double value;
  final Unit unit;
  const Quantity(this.value, this.unit);

  Dimension get dimension => unit.dimension;

  Quantity to(Unit target) => UnitEngine.convert(this, target);

  bool equals(Quantity other, {double rel = 0.01}) {
    if (other.dimension != dimension) return false;
    return nearlyEqual(to(other.unit).value, other.value, rel: rel);
  }

  String get label => '${fmtNum(value, maxDecimals: 3)} ${unit.label}';

  @override
  String toString() => label;
}

class UnitMismatch implements Exception {
  final String message;
  UnitMismatch(this.message);
  @override
  String toString() => message;
}

class ConversionStep {
  final String description;
  final String expression;
  final Quantity? result;
  const ConversionStep(this.description, this.expression, [this.result]);
}

class UnitEngine {
  static Quantity convert(Quantity q, Unit target) {
    if (q.unit.dimension != target.dimension) {
      throw UnitMismatch('Tidak bisa mengubah ${q.unit.label} ke ${target.label}');
    }
    return Quantity(q.value * q.unit.toBase / target.toBase, target);
  }

  /// Arah konversi yang SALAH (dikali padahal harus dibagi, atau sebaliknya).
  static double wrongDirection(Quantity q, Unit target) {
    final f = q.unit.toBase / target.toBase;
    return f >= 1 ? q.value / f : q.value * (1 / f);
  }

  /// Kesalahan memakai 100 sebagai ganti 60 (khusus waktu menit/jam).
  static double? base100(Quantity q, Unit target) {
    if (q.unit == Unit.min && target == Unit.h) return q.value / 100;
    if (q.unit == Unit.h && target == Unit.min) return q.value * 100;
    return null;
  }

  /// Penjelasan langkah demi langkah untuk Kalkulator Satuan dan animasi.
  static List<ConversionStep> explain(Quantity q, Unit target) {
    if (q.unit.dimension != target.dimension) {
      throw UnitMismatch('Dimensi berbeda');
    }
    if (q.unit == target) {
      return [ConversionStep('Satuannya sudah sama.', q.label, q)];
    }
    if (q.dimension != Dimension.speed) {
      return [_simple(q, target)];
    }
    final steps = <ConversionStep>[];
    final dFrom = q.unit.distancePart, dTo = target.distancePart;
    final tFrom = q.unit.timePart, tTo = target.timePart;
    var v = q.value;
    if (dFrom != dTo) {
      final f = dFrom.toBase / dTo.toBase;
      final nv = v * f;
      final big = f >= 1;
      final factor = big ? f : 1 / f;
      steps.add(ConversionStep(
        'Ubah ${dFrom.label} ke ${dTo.label}: 1 ${big ? dFrom.label : dTo.label} = ${fmtNum(factor)} ${big ? dTo.label : dFrom.label}.',
        '${fmtNum(v, maxDecimals: 3)} ${big ? '×' : '÷'} ${fmtNum(factor)} = ${fmtNum(nv, maxDecimals: 3)} ${dTo.label} tiap 1 ${tFrom.label}',
      ));
      v = nv;
    }
    if (tFrom != tTo) {
      final f = tFrom.toBase / tTo.toBase; // 1 tFrom = f tTo
      final nv = v / f;
      if (f >= 1) {
        steps.add(ConversionStep(
          '1 ${tFrom.label} = ${fmtNum(f)} ${tTo.label}. Jarak tadi dibagi ke ${fmtNum(f)} bagian.',
          '${fmtNum(v, maxDecimals: 3)} ÷ ${fmtNum(f)} = ${fmtNum(nv, maxDecimals: 3)} ${target.label}',
          Quantity(nv, target),
        ));
      } else {
        final inv = 1 / f;
        steps.add(ConversionStep(
          '1 ${tTo.label} = ${fmtNum(inv)} ${tFrom.label}. Dalam 1 ${tTo.label}, jaraknya ${fmtNum(inv)} kali lipat.',
          '${fmtNum(v, maxDecimals: 3)} × ${fmtNum(inv)} = ${fmtNum(nv, maxDecimals: 3)} ${target.label}',
          Quantity(nv, target),
        ));
      }
      v = nv;
    } else {
      steps.add(ConversionStep('Hasil akhir', '${fmtNum(v, maxDecimals: 3)} ${target.label}', Quantity(v, target)));
    }
    return steps;
  }

  static ConversionStep _simple(Quantity q, Unit target) {
    final from = q.unit;
    final res = convert(q, target);
    if (from.toBase > target.toBase) {
      final factor = from.toBase / target.toBase;
      return ConversionStep(
        '1 ${from.label} = ${fmtNum(factor)} ${target.label}. Satuan besar → kecil, jadi DIKALI ${fmtNum(factor)}.',
        '${fmtNum(q.value, maxDecimals: 3)} × ${fmtNum(factor)} = ${fmtNum(res.value, maxDecimals: 3)} ${target.label}',
        res,
      );
    }
    final factor = target.toBase / from.toBase;
    return ConversionStep(
      '1 ${target.label} = ${fmtNum(factor)} ${from.label}. Satuan kecil → besar, jadi DIBAGI ${fmtNum(factor)}.',
      '${fmtNum(q.value, maxDecimals: 3)} ÷ ${fmtNum(factor)} = ${fmtNum(res.value, maxDecimals: 3)} ${target.label}',
      res,
    );
  }

  /// Petunjuk aturan saja (tanpa hasil) untuk mode bantuan "cek".
  static String rule(Unit from, Unit target) {
    if (from.dimension == Dimension.speed) {
      return 'Ubah bagian jarak dulu (${from.distancePart.label} → ${target.distancePart.label}), '
          'lalu bagian waktu (${from.timePart.label} → ${target.timePart.label}).';
    }
    if (from.toBase > target.toBase) {
      return '1 ${from.label} = ${fmtNum(from.toBase / target.toBase)} ${target.label}. Besar → kecil: dikali.';
    }
    return '1 ${target.label} = ${fmtNum(target.toBase / from.toBase)} ${from.label}. Kecil → besar: dibagi.';
  }
}
