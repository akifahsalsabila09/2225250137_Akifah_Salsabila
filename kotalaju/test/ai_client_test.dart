import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kotalaju/app/theme.dart';
import 'package:kotalaju/core/data/ai_client.dart';
import 'package:kotalaju/features/ai/ai_chat_screen.dart';

AiClient _client(http.Response Function(http.Request) handler) =>
    AiClient(client: MockClient((r) async => handler(r)), endpoint: Uri.parse('https://contoh.test/api/tanya'));

http.Response _json(int status, Map<String, dynamic> body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

Future<void> _frames(WidgetTester t, {int n = 60}) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  group('AiClient', () {
    test('mengirim riwayat percakapan, konteks, dan menerima jawaban', () async {
      late Map<String, dynamic> sent;
      final ai = _client((r) {
        sent = jsonDecode(r.body) as Map<String, dynamic>;
        expect(r.method, 'POST');
        return _json(200, {'jawaban': '30 menit = 0,5 jam.'});
      });
      final reply = await ai.chat(
        const [AiMessage(true, 'Halo'), AiMessage(false, 'Halo juga!'), AiMessage(true, ' 30 menit berapa jam? ')],
        konteks: 'Soal Rani',
        sudahDijawab: true,
      );
      expect(reply, '30 menit = 0,5 jam.');
      expect(sent['messages'], [
        {'role': 'user', 'text': 'Halo'},
        {'role': 'model', 'text': 'Halo juga!'},
        {'role': 'user', 'text': '30 menit berapa jam?'},
      ]);
      expect(sent['konteks'], 'Soal Rani');
      expect(sent['sudahDijawab'], true);
    });

    test('pesan galat dari server diteruskan dengan ramah', () async {
      final ai = _client((_) => _json(429, {'error': 'Kuota AI sedang habis. Coba lagi beberapa saat lagi, ya.'}));
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

  testWidgets('chat AI: percakapan berlanjut, jawaban diketik, format tebal & daftar', (t) async {
    final requests = <Map<String, dynamic>>[];
    final ai = _client((r) {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      requests.add(body);
      return requests.length == 1
          ? _json(200, {'jawaban': '**Kecepatan = jarak ÷ waktu.**\n1. Samakan satuan\n2. Bagi jarak dengan waktu'})
          : _json(200, {'jawaban': 'Contoh: 12 km ÷ 1 jam = 12 km/jam.'});
    });
    await t.pumpWidget(MaterialApp(theme: buildTheme(), home: AiChatScreen(ai: ai)));
    expect(find.text('Coba tanya:'), findsOneWidget);

    await t.tap(find.text('Apa rumus kecepatan?'));
    await _frames(t);
    expect(find.text('Kecepatan = jarak ÷ waktu.', findRichText: true), findsOneWidget);
    expect(find.text('Samakan satuan', findRichText: true), findsOneWidget);
    expect(find.text('1.'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'contoh lain dong');
    await t.tap(find.byTooltip('Kirim'));
    await _frames(t);
    expect(find.text('Contoh: 12 km ÷ 1 jam = 12 km/jam.', findRichText: true), findsOneWidget);
    // Permintaan kedua membawa riwayat: pertanyaan 1, jawaban 1, pertanyaan 2.
    final msgs = requests[1]['messages'] as List;
    expect(msgs.length, 3);
    expect(msgs[0], {'role': 'user', 'text': 'Apa rumus kecepatan?'});
    expect((msgs[1] as Map)['role'], 'model');
    expect(msgs[2], {'role': 'user', 'text': 'contoh lain dong'});
  });

  testWidgets('chat AI: galat menampilkan tombol Coba lagi', (t) async {
    var calls = 0;
    final ai = _client((_) {
      calls++;
      return calls == 1 ? _json(502, {'error': 'AI sedang tidak bisa dihubungi.'}) : _json(200, {'jawaban': 'Sudah bisa!'});
    });
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(),
      home: AiChatScreen(ai: ai, konteks: 'Soal Dina', judulKonteks: 'Koin 1 – Memilih Rute'),
    ));
    expect(find.text('📌 Membahas: Koin 1 – Memilih Rute'), findsOneWidget);
    await t.tap(find.text('Aku harus mulai dari mana?'));
    await _frames(t, n: 10);
    expect(find.text('AI sedang tidak bisa dihubungi.'), findsOneWidget);
    await t.tap(find.text('Coba lagi'));
    await _frames(t);
    expect(find.text('Sudah bisa!', findRichText: true), findsOneWidget);
    expect(calls, 2);
  });
}
