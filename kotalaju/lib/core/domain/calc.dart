/// Kalkulator sederhana: + − × ÷ dengan urutan operasi (× dan ÷ dulu).
/// Desimal memakai koma, misalnya "6 ÷ 0,5".
class CalcEngine {
  static const ops = ['+', '−', '×', '÷'];

  /// Mengembalikan null bila ekspresi tidak lengkap atau dibagi nol.
  static double? evaluate(String expr) {
    final tokens = _tokenize(expr);
    if (tokens == null || tokens.isEmpty) return null;
    // Bentuk: angka (op angka)*
    if (tokens.length.isEven) return null;
    final nums = <double>[];
    final opsList = <String>[];
    for (var i = 0; i < tokens.length; i++) {
      if (i.isEven) {
        final v = double.tryParse(tokens[i]);
        if (v == null) return null;
        nums.add(v);
      } else {
        if (!ops.contains(tokens[i])) return null;
        opsList.add(tokens[i]);
      }
    }
    // × dan ÷ dulu
    final n2 = <double>[nums.first];
    final o2 = <String>[];
    for (var i = 0; i < opsList.length; i++) {
      final op = opsList[i];
      final b = nums[i + 1];
      if (op == '×') {
        n2[n2.length - 1] = n2.last * b;
      } else if (op == '÷') {
        if (b == 0) return null;
        n2[n2.length - 1] = n2.last / b;
      } else {
        o2.add(op);
        n2.add(b);
      }
    }
    var result = n2.first;
    for (var i = 0; i < o2.length; i++) {
      result = o2[i] == '+' ? result + n2[i + 1] : result - n2[i + 1];
    }
    return result;
  }

  static List<String>? _tokenize(String expr) {
    final out = <String>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isNotEmpty) {
        out.add(buf.toString().replaceAll(',', '.'));
        buf.clear();
      }
    }

    final s = expr.replaceAll(' ', '').replaceAll('-', '−').replaceAll('*', '×').replaceAll('/', '÷').replaceAll(':', '÷');
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (RegExp(r'[0-9,.]').hasMatch(ch)) {
        buf.write(ch == '.' ? ',' : ch);
      } else if (ops.contains(ch)) {
        // minus di awal = bilangan negatif
        if (ch == '−' && buf.isEmpty && (out.isEmpty || ops.contains(out.last))) {
          buf.write('-');
          continue;
        }
        flush();
        out.add(ch);
      } else {
        return null;
      }
    }
    flush();
    return out;
  }
}
