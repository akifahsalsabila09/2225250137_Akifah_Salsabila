/// Tanya Jawab seputar jarak, kecepatan, dan waktu (berjalan tanpa internet).
class TanyaJawab {
  final String tanya;
  final String jawab;
  final List<String> kataKunci;
  const TanyaJawab(this.tanya, this.jawab, this.kataKunci);
}

const daftarTanyaJawab = <TanyaJawab>[
  TanyaJawab(
    'Apa itu kecepatan?',
    'Kecepatan adalah jarak yang ditempuh dalam satu satuan waktu. '
        'Contoh: 60 km/jam artinya setiap 1 jam menempuh 60 km.',
    ['kecepatan', 'laju', 'km/jam', 'arti'],
  ),
  TanyaJawab(
    'Apa rumus jarak, kecepatan, dan waktu?',
    'Jarak = kecepatan × waktu.\nKecepatan = jarak ÷ waktu.\nWaktu = jarak ÷ kecepatan.\n'
        'Ingat segitiga JKW: J di atas, K dan W di bawah. Tutup yang dicari, lihat sisanya.',
    ['rumus', 'jkw', 'segitiga', 'jarak', 'waktu', 'kecepatan', 'cara', 'hitung'],
  ),
  TanyaJawab(
    'Bagaimana mengubah menit ke jam?',
    'Bagi dengan 60. Contoh: 30 menit = 30 ÷ 60 = 0,5 jam. 45 menit = 45 ÷ 60 = 0,75 jam.',
    ['menit', 'jam', 'ubah', 'konversi', 'satuan', 'bagi', '60'],
  ),
  TanyaJawab(
    'Bagaimana mengubah jam ke menit?',
    'Kalikan dengan 60. Contoh: 1,5 jam = 1,5 × 60 = 90 menit.',
    ['jam', 'menit', 'ubah', 'konversi', 'kali', '60'],
  ),
  TanyaJawab(
    'Kenapa satuannya harus disamakan dulu?',
    'Kalau kecepatan dalam km/jam tetapi waktu dalam menit, hasilnya pasti salah. '
        'Contoh: 6 km dalam 30 menit. 6 ÷ 30 = 0,2 itu salah. Ubah dulu 30 menit = 0,5 jam, lalu 6 ÷ 0,5 = 12 km/jam.',
    ['satuan', 'sama', 'samakan', 'menit', 'salah', 'kenapa'],
  ),
  TanyaJawab(
    'Bagaimana mengubah km ke m?',
    'Kalikan dengan 1.000. Contoh: 3 km = 3 × 1.000 = 3.000 m. Sebaliknya, m ke km dibagi 1.000.',
    ['km', 'meter', 'm', 'ubah', 'konversi', '1000'],
  ),
  TanyaJawab(
    'Bagaimana mengubah km/jam ke m/detik?',
    'Kalikan 1.000 (km ke m), lalu bagi 3.600 (jam ke detik). '
        'Contoh: 72 km/jam = 72 × 1.000 ÷ 3.600 = 20 m/detik.',
    ['km/jam', 'm/detik', 'detik', 'ubah', 'konversi', '3600'],
  ),
  TanyaJawab(
    'Apa itu kecepatan rata-rata?',
    'Kecepatan rata-rata = total jarak ÷ total waktu. '
        'Bukan rata-rata dari dua kecepatan! Contoh soal Andi: 10 km ÷ 1 jam = 10 km/jam.',
    ['rata-rata', 'rata', 'total', 'andi'],
  ),
  TanyaJawab(
    'Apa bedanya jam berangkat dengan lama perjalanan?',
    '"Pukul 07.00" adalah jam (waktu pada jam dinding). '
        '"2 jam" atau "30 menit" adalah lama perjalanan. Yang dipakai di rumus adalah lama perjalanan.',
    ['pukul', 'jam', 'lama', 'berangkat', 'beda', 'waktu tempuh'],
  ),
  TanyaJawab(
    'Apa itu waktu tempuh?',
    'Waktu tempuh adalah lama perjalanan dari tempat awal sampai tujuan.',
    ['waktu tempuh', 'tempuh', 'lama'],
  ),
  TanyaJawab(
    'Bagaimana cara memilih rute yang tepat waktu?',
    'Hitung waktu tiap rute (jarak ÷ kecepatan), ubah ke menit, lalu bandingkan dengan batas waktunya. '
        'Pilih rute yang waktunya tidak melebihi batas.',
    ['rute', 'pilih', 'tepat waktu', 'batas', 'dina', 'bandingkan'],
  ),
  TanyaJawab(
    'Bagaimana tahu jawabanku masuk akal?',
    'Cek dengan logika. Kendaraan lebih cepat → waktunya lebih singkat. '
        'Kalikan kembali: kecepatan × waktu harus sama dengan jarak. '
        'Sepeda biasanya 10–20 km/jam. Kalau hasilmu 0,2 km/jam atau 180 km/jam, pasti ada yang salah.',
    ['cek', 'masuk akal', 'periksa', 'logika', 'benar', 'salah', 'budi'],
  ),
  TanyaJawab(
    'Berapa jam 15, 30, dan 45 menit?',
    '15 menit = ¼ jam = 0,25 jam.\n30 menit = ½ jam = 0,5 jam.\n45 menit = ¾ jam = 0,75 jam.',
    ['15', '30', '45', 'menit', 'pecahan', 'seperempat', 'setengah'],
  ),
  TanyaJawab(
    'Bagaimana cara memakai kalkulator di aplikasi ini?',
    'Ketuk tombol 🧮. Tulis hitunganmu, misalnya 150 ÷ 50, lalu tekan =. '
        'Pakai koma untuk desimal, misalnya 6 ÷ 0,5.',
    ['kalkulator', 'hitung', 'pakai', 'cara'],
  ),
];

/// Mencari pertanyaan yang paling cocok dengan kata-kata pada [query].
List<TanyaJawab> cariTanyaJawab(String query) {
  final q = query.toLowerCase().trim();
  if (q.isEmpty) return daftarTanyaJawab;
  final words = q.split(RegExp(r'[\s?,.!]+')).where((w) => w.length >= 2).toList();
  final scored = <(TanyaJawab, int)>[];
  for (final item in daftarTanyaJawab) {
    final hay = '${item.tanya} ${item.kataKunci.join(' ')}'.toLowerCase();
    var score = 0;
    for (final w in words) {
      if (hay.contains(w)) score += item.kataKunci.any((k) => k == w) ? 2 : 1;
    }
    if (score > 0) scored.add((item, score));
  }
  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final s in scored) s.$1];
}
