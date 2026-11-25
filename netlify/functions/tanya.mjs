// Netlify Function: perantara antara aplikasi KotaLaju dan Gemini.
// API key TIDAK pernah dikirim ke browser; disimpan di Netlify sebagai GEMINI_API_KEY.
// Opsional: GEMINI_MODEL untuk mengganti model (bawaan: gemini-2.5-flash).

const SYSTEM_PROMPT = `Kamu adalah "Pak Lampu", tutor matematika ramah di aplikasi KotaLaju untuk siswa SMP kelas VII di Indonesia.
Topikmu HANYA: jarak, kecepatan, waktu, kecepatan rata-rata, dan konversi satuan (km, m, jam, menit, detik, km/jam, m/detik).
Aturan:
- Jawab dalam bahasa Indonesia yang sederhana, kalimat pendek, sapa siswa dengan "kamu".
- Maksimal sekitar 120 kata. Pakai langkah bernomor bila menghitung.
- Tulis desimal dengan koma (0,5), ribuan dengan titik (1.000), operasi dengan × dan ÷.
- Ingatkan untuk menyamakan satuan dan mengecek apakah jawaban masuk akal.
- Bila siswa meminta jawaban soal, bimbing langkah demi langkah agar ia bisa menghitung sendiri.
- Bila pertanyaan di luar topik atau tidak pantas, tolak dengan sopan dan ajak kembali ke materi jarak, kecepatan, dan waktu.
- Jangan meminta atau menyimpan data pribadi.`;

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

export default async (req) => {
  if (req.method !== 'POST') return json(405, { error: 'Gunakan POST.' });

  const key = process.env.GEMINI_API_KEY;
  if (!key) return json(500, { error: 'GEMINI_API_KEY belum diatur di Netlify.' });

  let pertanyaan = '';
  try {
    const body = await req.json();
    pertanyaan = String(body?.pertanyaan ?? '').trim();
  } catch {
    return json(400, { error: 'Format permintaan tidak valid.' });
  }
  if (!pertanyaan) return json(400, { error: 'Pertanyaan masih kosong.' });
  if (pertanyaan.length > 500) pertanyaan = pertanyaan.slice(0, 500);

  const model = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`;

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: SYSTEM_PROMPT }] },
        contents: [{ role: 'user', parts: [{ text: pertanyaan }] }],
        generationConfig: { temperature: 0.4, maxOutputTokens: 600 },
      }),
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) {
      const status = res.status === 429 ? 429 : 502;
      const pesan =
        res.status === 429
          ? 'Kuota AI hari ini sedang habis. Coba lagi nanti, ya.'
          : 'AI sedang tidak bisa dihubungi. Coba lagi sebentar lagi.';
      console.error('Gemini error', res.status, JSON.stringify(data).slice(0, 500));
      return json(status, { error: pesan });
    }
    const jawaban = (data?.candidates?.[0]?.content?.parts ?? [])
      .map((p) => p.text ?? '')
      .join('')
      .trim();
    if (!jawaban) return json(502, { error: 'AI tidak memberi jawaban. Coba tulis pertanyaan dengan kata lain.' });
    return json(200, { jawaban });
  } catch (e) {
    console.error('Fetch gagal', e);
    return json(502, { error: 'AI sedang tidak bisa dihubungi. Coba lagi sebentar lagi.' });
  }
};

export const config = { path: '/api/tanya' };
