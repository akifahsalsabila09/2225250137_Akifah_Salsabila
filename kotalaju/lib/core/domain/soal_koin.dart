/// 7 soal koin (pilihan ganda) tentang jarak, waktu, dan kecepatan – kelas VII.
/// Soal 1–4 dari kisi-kisi Mathematical Literacy; soal 5–7 soal tambahan.
library;

class SoalKoin {
  final int no;
  final String judul;
  final String pertanyaan;
  final List<String> pilihan;
  final int benar;
  final List<String> pembahasan;
  final bool dariKisiKisi;

  const SoalKoin({
    required this.no,
    required this.judul,
    required this.pertanyaan,
    required this.pilihan,
    required this.benar,
    required this.pembahasan,
    this.dariKisiKisi = false,
  });

  String get jawaban => pilihan[benar];
}

const soalKoin = <SoalKoin>[
  SoalKoin(
    no: 1,
    judul: 'Memilih Rute Bersepeda',
    dariKisiKisi: true,
    pertanyaan: 'Dina akan pergi ke rumah temannya yang berjarak 6 km. '
        'Lewat Rute A, kecepatan rata-ratanya 12 km/jam. '
        'Lewat Rute B, kecepatan rata-ratanya 15 km/jam. '
        'Dina harus tiba paling lama 25 menit. Rute mana yang sebaiknya dipilih?',
    pilihan: ['Rute A', 'Rute B', 'Keduanya terlambat', 'Keduanya sama cepat'],
    benar: 1,
    pembahasan: [
      'Waktu = jarak ÷ kecepatan.',
      'Rute A: 6 ÷ 12 = 0,5 jam = 30 menit (terlambat).',
      'Rute B: 6 ÷ 15 = 0,4 jam = 24 menit (tepat waktu).',
      'Jadi, Dina memilih Rute B.',
    ],
  ),
  SoalKoin(
    no: 2,
    judul: 'Perjalanan Menuju Museum',
    dariKisiKisi: true,
    pertanyaan: 'Bus sekolah pergi ke museum yang berjarak 150 km. '
        'Bus melaju dengan kecepatan rata-rata 50 km/jam dan tidak berhenti. '
        'Berapa lama perjalanan bus?',
    pilihan: ['2 jam', '5 jam', '3 jam', '7.500 jam'],
    benar: 2,
    pembahasan: [
      'Diketahui: jarak 150 km, kecepatan 50 km/jam.',
      'Waktu = jarak ÷ kecepatan = 150 ÷ 50 = 3 jam.',
      'Jadi, bus butuh 3 jam untuk sampai ke museum.',
    ],
  ),
  SoalKoin(
    no: 3,
    judul: 'Perjalanan Bersepeda Andi',
    dariKisiKisi: true,
    pertanyaan: 'Andi bersepeda dari rumah ke taman. '
        'Mula-mula ia menempuh 4 km dengan kecepatan 8 km/jam. '
        'Setelah istirahat, ia menempuh 6 km lagi dengan kecepatan 12 km/jam. '
        'Berapa total waktu dan kecepatan rata-ratanya?',
    pilihan: ['1 jam; 10 km/jam', '1 jam; 20 km/jam', '2 jam; 5 km/jam', '0,5 jam; 10 km/jam'],
    benar: 0,
    pembahasan: [
      'Bagian 1: 4 ÷ 8 = 0,5 jam.',
      'Bagian 2: 6 ÷ 12 = 0,5 jam.',
      'Total waktu = 0,5 + 0,5 = 1 jam. Total jarak = 4 + 6 = 10 km.',
      'Kecepatan rata-rata = total jarak ÷ total waktu = 10 ÷ 1 = 10 km/jam.',
    ],
  ),
  SoalKoin(
    no: 4,
    judul: 'Memeriksa Waktu Perjalanan Bus',
    dariKisiKisi: true,
    pertanyaan: 'Sebuah bus menempuh 120 km dengan kecepatan rata-rata 40 km/jam. '
        'Budi menghitung: 40 ÷ 120 = 0,33 jam, jadi bus hanya butuh sekitar 20 menit. '
        'Apakah Budi benar?',
    pilihan: [
      'Benar, sekitar 20 menit',
      'Salah, seharusnya 80 menit',
      'Benar, karena bus itu cepat',
      'Salah, seharusnya 3 jam',
    ],
    benar: 3,
    pembahasan: [
      'Budi membalik pembagian (kecepatan ÷ jarak).',
      'Waktu = jarak ÷ kecepatan = 120 ÷ 40 = 3 jam.',
      'Jadi, waktu yang benar 3 jam, bukan 20 menit.',
    ],
  ),
  SoalKoin(
    no: 5,
    judul: 'Kecepatan Sepeda Rani',
    pertanyaan: 'Rani bersepeda ke perpustakaan sejauh 6 km. '
        'Ia sampai dalam waktu 30 menit. '
        'Berapa kecepatan rata-rata Rani dalam km/jam?',
    pilihan: ['0,2 km/jam', '12 km/jam', '5 km/jam', '180 km/jam'],
    benar: 1,
    pembahasan: [
      'Ubah menit ke jam dulu: 30 menit = 30 ÷ 60 = 0,5 jam.',
      'Kecepatan = jarak ÷ waktu = 6 ÷ 0,5 = 12 km/jam.',
      'Hati-hati: 6 ÷ 30 = 0,2 itu salah karena menit belum diubah ke jam.',
    ],
  ),
  SoalKoin(
    no: 6,
    judul: 'Jarak Perjalanan Ayah',
    pertanyaan: 'Ayah menyetir mobil di jalan tol dengan kecepatan 60 km/jam. '
        'Ayah menyetir selama 90 menit. '
        'Berapa km jarak yang ditempuh?',
    pilihan: ['60 km', '150 km', '5.400 km', '90 km'],
    benar: 3,
    pembahasan: [
      'Ubah menit ke jam dulu: 90 menit = 90 ÷ 60 = 1,5 jam.',
      'Jarak = kecepatan × waktu = 60 × 1,5 = 90 km.',
    ],
  ),
  SoalKoin(
    no: 7,
    judul: 'Waktu Tempuh Truk Sayur',
    pertanyaan: 'Truk sayur pergi dari kebun ke pasar induk yang berjarak 90 km. '
        'Truk melaju dengan kecepatan rata-rata 60 km/jam. '
        'Berapa lama perjalanannya?',
    pilihan: ['1 jam', '1,5 jam', '2 jam', '30 menit'],
    benar: 1,
    pembahasan: [
      'Waktu = jarak ÷ kecepatan = 90 ÷ 60 = 1,5 jam.',
      '1,5 jam sama dengan 1 jam 30 menit.',
    ],
  ),
];
