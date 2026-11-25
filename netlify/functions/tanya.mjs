// Netlify Function: perantara antara aplikasi KotaLaju dan Gemini.
// API key TIDAK pernah dikirim ke browser; disimpan di Netlify sebagai GEMINI_API_KEY.
// Opsional: GEMINI_MODEL untuk mengganti model (bawaan: gemini-2.5-flash).
//
// Permintaan (POST JSON):
//   { "messages": [{ "role": "user" | "model", "text": "..." }, ...],
//     "konteks": "teks soal (opsional)", "sudahDijawab": false }
//   Kompatibel lama: { "pertanyaan": "..." }
// Jawaban: { "jawaban": "..." } atau { "error": "..." }

const SYSTEM_PROMPT = `Kamu adalah "Pak Lampu", tutor matematika yang ramah, sabar, dan seru di aplikasi KotaLaju (permainan sepeda keliling kota) untuk siswa SMP kelas VII di Indonesia.

Fokus utamamu: jarak, kecepatan, waktu, kecepatan rata-rata, dan konversi satuan (km, m, jam, menit, detik, km/jam, m/detik), termasuk soal cerita seperti memilih rute, berpapasan, dan menyusul.

Cara menjawab:
- Bahasa Indonesia yang santai tapi sopan, kalimat pendek, sapa siswa dengan "kamu". Boleh pakai 1–2 emoji kendaraan/kota bila cocok.
- Jawab langsung ke inti. Biasanya 2–6 kalimat atau langkah bernomor. Jangan bertele-tele.
- Untuk hitungan, tulis langkah bernomor: Diketahui → Ditanya → Samakan satuan → Hitung → Cek masuk akal.
- Tulis desimal dengan koma (0,5), ribuan dengan titik (1.000), operasi dengan × dan ÷. Boleh pakai **tebal** untuk rumus penting.
- Ingatkan menyamakan satuan dan mengecek kewajaran jawaban bila relevan.
- Kalau siswa bingung, beri contoh dari kehidupan sehari-hari (naik sepeda ke sekolah, ojek, bus, kereta).
- Akhiri dengan pertanyaan pendek atau tantangan kecil bila cocok, agar siswa ikut berpikir.
- Ingat percakapan sebelumnya dan lanjutkan dengan nyambung.

Batasan:
- Pertanyaan matematika umum lain boleh dijawab singkat, lalu kaitkan kembali ke jarak, kecepatan, dan waktu.
- Bila pertanyaan tidak berhubungan dengan belajar atau tidak pantas, tolak dengan sopan dan ajak kembali belajar.
- Jangan meminta, menyimpan, atau membahas data pribadi.`;

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

const clip = (s, n) => String(s ?? '').trim().slice(0, n);

export default async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'Gunakan POST.' });

  const key = process.env.GEMINI_API_KEY;
  if (!key) return json(500, { error: 'GEMINI_API_KEY belum diatur di Netlify.' });

  let body;
  try {
    body = await req.json();
  } catch {
    return json(400, { error: 'Format permintaan tidak valid.' });
  }

  // Riwayat percakapan (maks 16 pesan terakhir, tiap pesan maks 1.500 huruf).
  let messages = Array.isArray(body?.messages) ? body.messages : [];
  if (!messages.length && body?.pertanyaan) messages = [{ role: 'user', text: body.pertanyaan }];
  messages = messages
    .filter((m) => m && (m.role === 'user' || m.role === 'model') && clip(m.text, 1500))
    .slice(-16)
    .map((m) => ({ role: m.role, parts: [{ text: clip(m.text, 1500) }] }));
  while (messages.length && messages[0].role !== 'user') messages.shift();
  if (!messages.length || messages[messages.length - 1].role !== 'user') {
    return json(400, { error: 'Pertanyaan masih kosong.' });
  }

  let system = SYSTEM_PROMPT;
  const konteks = clip(body?.konteks, 1500);
  if (konteks) {
    system += `\n\nSiswa sedang mengerjakan soal berikut di aplikasi:\n"""${konteks}"""\n`;
    system += body?.sudahDijawab
      ? 'Siswa SUDAH menjawab soal ini, jadi boleh membahas jawaban dan cara lengkapnya.'
      : 'Siswa BELUM menjawab soal ini. Jangan sebutkan jawaban akhir atau pilihan yang benar. Bimbing dengan pertanyaan pancingan dan langkah awal saja.';
  }

  const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: messages,
        generationConfig: { temperature: 0.7, maxOutputTokens: 1024 },
      }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      console.error('Gemini error', res.status, JSON.stringify(data).slice(0, 800));
      if (res.status === 429) return json(429, { error: 'Kuota AI sedang habis. Coba lagi beberapa saat lagi, ya.' });
      if (res.status === 400 || res.status === 403)
        return json(502, { error: 'API key Gemini ditolak. Periksa GEMINI_API_KEY di Netlify.' });
      if (res.status === 404)
        return json(502, { error: `Model "${model}" tidak ditemukan. Atur GEMINI_MODEL di Netlify.` });
      return json(502, { error: 'AI sedang tidak bisa dihubungi. Coba lagi sebentar lagi.' });
    }
    const jawaban = (data?.candidates?.[0]?.content?.parts ?? [])
      .map((p) => p.text ?? '')
      .join('')
      .trim();
    if (!jawaban) {
      const alasan = data?.candidates?.[0]?.finishReason || data?.promptFeedback?.blockReason;
      console.error('Jawaban kosong', alasan);
      return json(502, { error: 'Pak Lampu tidak bisa menjawab itu. Coba tanya hal lain tentang jarak, kecepatan, atau waktu.' });
    }
    return json(200, { jawaban });
  } catch (e) {
    console.error('Fetch gagal', e);
    return json(502, { error: 'AI sedang tidak bisa dihubungi. Coba lagi sebentar lagi.' });
  }
};

export const config = { path: '/api/tanya' };
