import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kotalaju/app/theme.dart';
import 'package:kotalaju/core/data/ai_client.dart';
import 'package:kotalaju/core/widgets/tanya_sheet.dart';

AiClient _client(http.Response Function(http.Request) handler) =>
    AiClient(client: MockClient((r) async => handler(r)), endpoint: Uri.parse('https://contoh.test/api/tanya'));

http.Response _json(int status, Map<String, dynamic> body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

void main() {
  group('AiClient', () {
    test('mengirim pertanyaan dan menerima jawaban', () async {
      late Map<String, dynamic> sent;
      final ai = _client((r) {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        expect(r.method, 'POST');
        return _json(200, {'jawaban': '30 menit = 0,5 jam.'});
      });
      expect(await ai.tanya(' 30 menit berapa jam? '), '30 menit = 0,5 jam.');
      expect(sent['pertanyaan'], '30 menit berapa jam?');
    });

    test('pesan galat dari server diteruskan dengan ramah', () async {
      final ai = _client((_) => _json(429, {'error': 'Kuota AI hari ini sedang habis. Coba lagi nanti, ya.'}));
      expect(() => ai.tanya('halo'), throwsA(isA<AiException>().having((e) => e.message, 'message', contains('Kuota'))));
    });

    test('fungsi belum aktif (404 HTML) → pesan jelas', () async {
      final ai = _client((_) => http.Response('<html>Not found</html>', 404));
      expect(() => ai.tanya('halo'),
          throwsA(isA<AiException>().having((e) => e.message, 'message', contains('belum aktif'))));
    });

    test('pertanyaan kosong tidak dikirim', () async {
      var called = false;
      final ai = _client((_) {
        called = true;
        return _json(200, {'jawaban': 'x'});
      });
      expect(() => ai.tanya('   '), throwsA(isA<AiException>()));
      expect(called, isFalse);
    });
  });

  testWidgets('tombol Tanya AI menampilkan jawaban AI', (t) async {
    final ai = _client((_) => _json(200, {'jawaban': 'Kecepatan = jarak ÷ waktu.'}));
    await t.pumpWidget(MaterialApp(theme: buildTheme(), home: Scaffold(body: TanyaSheet(ai: ai))));
    await t.enterText(find.byType(TextField), 'bagaimana cara menghitung kecepatan sepeda?');
    await t.pump();
    await t.tap(find.text('Tanya AI'));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Kecepatan = jarak ÷ waktu.'), findsOneWidget);
    expect(find.textContaining('Jawaban AI bisa keliru'), findsOneWidget);
  });
}
