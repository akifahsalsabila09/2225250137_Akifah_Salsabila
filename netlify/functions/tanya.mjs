// Netlify Function: perantara antara aplikasi KotaLaju dan Gemini.
// API key TIDAK pernah dikirim ke browser; disimpan di Netlify sebagai GEMINI_API_KEY.
// Opsional: GEMINI_MODEL untuk memaksa model tertentu.
//
// POST JSON:
//   { "messages": [{ "role": "user" | "model", "text": "..." }, ...],
//     "konteks": "teks soal (opsional)", "sudahDijawab": false }
//   Kompatibel lama: { "pertanyaan": "..." }
// Jawaban: { "jawaban": "...", "model": "..." } atau { "error": "...", "detail": "..." }
//
// GET /api/tanya?cek=1 → daftar model Gemini Flash yang tersedia (tanpa memakai kuota jawaban).

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

const API = 'https://generativelanguage.googleapis.com/v1beta';

const json = (status, body) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store' },
  });

const clip = (s, n) => String(s ?? '').trim().slice(0, n);

// Model yang terakhir berhasil (bertahan selama fungsi masih "hangat").
let cachedModel = null;

async function callGemini(key, model, payload, timeoutMs) {
  try {
    const res = await fetch(`${API}/models/${encodeURIComponent(model)}:generateContent`, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-goog-api-key': key },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(timeoutMs),
    });
    const data = await res.json().catch(() => ({}));
    return { status: res.status, ok: res.ok, data };
  } catch (e) {
    return { status: 0, ok: false, data: { error: { message: String(e?.name === 'TimeoutError' ? 'timeout' : e?.message ?? e) } } };
  }
}

/** Daftar model Gemini "Flash" yang bisa generateContent, terbaik lebih dulu. */
async function listFlashModels(key) {
  try {
    const res = await fetch(`${API}/models?pageSize=200`, {
      headers: { 'x-goog-api-key': key },
      signal: AbortSignal.timeout(4000),
    });
    if (!res.ok) return { models: [], error: `${res.status} ${(await res.text()).slice(0, 200)}` };
    const data = await res.json();
    const skip = /(image|tts|audio|live|embedding|vision|thinking|exp|learnlm|robotics|computer)/i;
    const version = (n) => parseFloat((n.match(/gemini-(\d+(?:\.\d+)?)/) || [])[1] || '0');
    const usable = (data.models || [])
      .filter((m) => (m.supportedGenerationMethods || []).includes('generateContent'))
      .map((m) => String(m.name || '').replace(/^models\//, ''))
      .filter((n) => n.startsWith('gemini') && n.includes('flash') && !skip.test(n));
    const score = (n) =>
      version(n) * 10 - (n.includes('preview') ? 3 : 0) - (n.includes('lite') ? 2 : 0) + (n.endsWith('latest') ? 1 : 0);
    usable.sort((a, b) => score(b) - score(a));
    return { models: usable };
  } catch (e) {
    return { models: [], error: String(e?.message ?? e) };
  }
}

const describe = (r) =>
  `${r.status || 'jaringan'} ${r.data?.error?.status ?? ''} ${String(r.data?.error?.message ?? '').slice(0, 220)}`.trim();

export default async (req) => {
  const key = process.env.GEMINI_API_KEY;
  const url = new URL(req.url);

  if (req.method === 'GET' && url.searchParams.get('cek')) {
    if (!key) return json(500, { error: 'GEMINI_API_KEY belum diatur di Netlify.' });
    const { models, error } = await listFlashModels(key);
    return json(200, { keyAda: true, modelPaksa: process.env.GEMINI_MODEL || null, cachedModel, tersedia: models.slice(0, 12), error });
  }
  if (req.method !== 'POST') return json(405, { error: 'Gunakan POST.' });
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

  const payload = {
    systemInstruction: { parts: [{ text: system }] },
    contents: messages,
    // Jatah token longgar karena model terbaru "berpikir" dulu; panjang jawaban dijaga oleh SYSTEM_PROMPT.
    generationConfig: { temperature: 0.7, maxOutputTokens: 4096 },
  };

  // Urutan percobaan: model paksa → model yang terakhir berhasil → daftar model Flash dari Google → cadangan.
  const tried = [];
  const queue = [process.env.GEMINI_MODEL, cachedModel].filter(Boolean);
  let listed = false;
  let last = null;
  // Fungsi Netlify dihentikan sekitar 10 detik; sisakan ruang untuk membalas.
  const deadline = Date.now() + 9200;

  for (let attempt = 0; attempt < 4; attempt++) {
    const remaining = deadline - Date.now();
    if (remaining < 1500) break;
    if (!queue.length && !listed) {
      listed = true;
      const { models } = await listFlashModels(key);
      queue.push(...models.slice(0, 4), 'gemini-flash-latest', 'gemini-2.5-flash');
    }
    const model = queue.shift();
    if (!model) break;
    if (tried.includes(model)) {
      attempt--;
      continue;
    }
    tried.push(model);
    const r = await callGemini(key, model, payload, Math.max(1000, deadline - Date.now()));
    last = { model, ...r };

    if (r.ok) {
      const jawaban = (r.data?.candidates?.[0]?.content?.parts ?? [])
        .filter((p) => !p.thought)
        .map((p) => p.text ?? '')
        .join('')
        .trim();
      if (jawaban) {
        cachedModel = model;
        return json(200, { jawaban, model });
      }
      const alasan = r.data?.candidates?.[0]?.finishReason || r.data?.promptFeedback?.blockReason || 'kosong';
      if (alasan === 'SAFETY' || r.data?.promptFeedback?.blockReason) {
        return json(200, {
          jawaban: 'Maaf, Pak Lampu tidak bisa membahas itu. Yuk, tanya tentang jarak, kecepatan, atau waktu! 🚲',
          model,
        });
      }
      last.data = { error: { message: `jawaban kosong (${alasan})` } };
      continue; // coba model lain
    }

    if (r.status === 429) {
      return json(429, { error: 'Kuota AI sedang habis. Coba lagi beberapa saat lagi, ya.', detail: describe(r), model });
    }
    const msg = String(r.data?.error?.message ?? '');
    if (r.status === 403 || /api key/i.test(msg)) {
      return json(502, { error: 'API key Gemini ditolak. Periksa GEMINI_API_KEY di Netlify.', detail: describe(r), model });
    }
    // 404 (model tidak ada), 5xx (sibuk/galat), timeout, atau 400 khusus model → coba model berikutnya.
    console.error('Gemini gagal', model, describe(r));
  }

  const timedOut = last && last.status === 0 && /timeout/.test(String(last.data?.error?.message));
  return json(502, {
    error: timedOut
      ? 'AI terlalu lama menjawab. Coba pertanyaan yang lebih singkat, atau coba lagi.'
      : 'AI sedang tidak bisa dihubungi. Coba lagi sebentar lagi.',
    detail: last ? `${last.model}: ${describe(last)}` : 'tidak ada model yang bisa dicoba',
    dicoba: tried,
  });
};

export const config = { path: '/api/tanya' };
