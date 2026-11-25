import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Alamat situs Netlify yang menjalankan fungsi Tanya AI (dipakai bila aplikasi
/// berjalan di luar browser, misalnya APK Android).
const aiSiteUrl = 'https://peaceful-daifuku-559ae4.netlify.app';

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// Satu pesan dalam percakapan. [fromUser] true = siswa, false = AI.
class AiMessage {
  final bool fromUser;
  final String text;
  const AiMessage(this.fromUser, this.text);

  Map<String, String> toJson() => {'role': fromUser ? 'user' : 'model', 'text': text};
}

/// Mengirim percakapan ke perantara Netlify (/api/tanya) yang memanggil Gemini.
/// API key tidak pernah ada di aplikasi.
class AiClient {
  final http.Client _http;
  final Uri endpoint;

  AiClient({http.Client? client, Uri? endpoint})
      : _http = client ?? http.Client(),
        endpoint = endpoint ?? (kIsWeb ? Uri.base.resolve('/api/tanya') : Uri.parse('$aiSiteUrl/api/tanya'));

  /// Satu pertanyaan tanpa riwayat.
  Future<String> tanya(String pertanyaan) => chat([AiMessage(true, pertanyaan)]);

  /// Percakapan lengkap. Pesan terakhir harus dari siswa.
  Future<String> chat(List<AiMessage> messages, {String? konteks, bool sudahDijawab = false}) async {
    final clean = [
      for (final m in messages)
        if (m.text.trim().isNotEmpty) AiMessage(m.fromUser, m.text.trim()),
    ];
    if (clean.isEmpty || !clean.last.fromUser) throw AiException('Tulis pertanyaanmu dulu, ya.');
    http.Response res;
    try {
      res = await _http
          .post(
            endpoint,
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'messages': [for (final m in clean.length > 16 ? clean.sublist(clean.length - 16) : clean) m.toJson()],
              if (konteks != null && konteks.isNotEmpty) 'konteks': konteks,
              'sudahDijawab': sudahDijawab,
            }),
          )
          .timeout(const Duration(seconds: 45));
    } catch (_) {
      throw AiException('Tidak bisa terhubung ke AI. Periksa internetmu, lalu coba lagi.');
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw AiException(res.statusCode == 404
          ? 'Fitur Tanya AI belum aktif di situs ini.'
          : 'AI memberi jawaban yang tidak bisa dibaca. Coba lagi.');
    }
    if (res.statusCode != 200) {
      throw AiException((body['error'] as String?) ?? 'AI sedang tidak bisa dihubungi. Coba lagi nanti.');
    }
    final jawaban = (body['jawaban'] as String?)?.trim() ?? '';
    if (jawaban.isEmpty) throw AiException('AI tidak memberi jawaban. Coba kata lain.');
    return jawaban;
  }
}
