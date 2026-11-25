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

/// Mengirim pertanyaan ke perantara Netlify (/api/tanya) yang memanggil Gemini.
/// API key tidak pernah ada di aplikasi.
class AiClient {
  final http.Client _http;
  final Uri endpoint;

  AiClient({http.Client? client, Uri? endpoint})
      : _http = client ?? http.Client(),
        endpoint = endpoint ?? (kIsWeb ? Uri.base.resolve('/api/tanya') : Uri.parse('$aiSiteUrl/api/tanya'));

  Future<String> tanya(String pertanyaan) async {
    final q = pertanyaan.trim();
    if (q.isEmpty) throw AiException('Tulis pertanyaanmu dulu, ya.');
    http.Response res;
    try {
      res = await _http
          .post(endpoint, headers: {'content-type': 'application/json'}, body: jsonEncode({'pertanyaan': q}))
          .timeout(const Duration(seconds: 30));
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
