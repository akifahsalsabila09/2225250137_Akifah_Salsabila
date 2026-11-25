/// Format dan parsing angka gaya Indonesia: desimal koma (0,75), ribuan titik (72.000).
library;

String fmtNum(num value, {int maxDecimals = 2}) {
  final d = value.toDouble();
  if (d.isNaN || d.isInfinite) return '-';
  var s = d.toStringAsFixed(maxDecimals);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  var negative = s.startsWith('-');
  if (negative) s = s.substring(1);
  final parts = s.split('.');
  final intPart = _groupThousands(parts[0]);
  final out = parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
  if (out == '0') negative = false;
  return negative ? '-$out' : out;
}

String _groupThousands(String digits) {
  final b = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) b.write('.');
    b.write(digits[i]);
  }
  return b.toString();
}

/// Menerima "0,75", "0.75", "3/4", "1 1/2", "72.000", "72000".
double? parseNum(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;
  final mixed = RegExp(r'^(-?\d+)\s+(\d+)\s*/\s*(\d+)$').firstMatch(s);
  if (mixed != null) {
    final whole = double.parse(mixed.group(1)!);
    final a = double.parse(mixed.group(2)!);
    final b = double.parse(mixed.group(3)!);
    if (b == 0) return null;
    return whole < 0 ? whole - a / b : whole + a / b;
  }
  final frac = RegExp(r'^(-?[\d.,]+)\s*/\s*([\d.,]+)$').firstMatch(s);
  if (frac != null) {
    final a = _plain(frac.group(1)!);
    final b = _plain(frac.group(2)!);
    if (a == null || b == null || b == 0) return null;
    return a / b;
  }
  return _plain(s);
}

double? _plain(String raw) {
  var s = raw.replaceAll(' ', '');
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^-?[1-9]\d{0,2}(\.\d{3})+$').hasMatch(s)) {
    s = s.replaceAll('.', '');
  }
  return double.tryParse(s);
}

/// Label pecahan ramah untuk nilai jam yang umum.
String? fractionLabel(double v) {
  const known = <(double, String)>[
    (0.25, '¼'),
    (0.5, '½'),
    (0.75, '¾'),
    (1.25, '1¼'),
    (1.5, '1½'),
    (1.75, '1¾'),
    (2.5, '2½'),
  ];
  for (final (value, label) in known) {
    if ((value - v).abs() < 1e-9) return label;
  }
  return null;
}

bool nearlyEqual(double a, double b, {double rel = 0.01, double abs = 0.005}) {
  final tol = (b.abs() * rel) > abs ? b.abs() * rel : abs;
  return (a - b).abs() <= tol;
}
