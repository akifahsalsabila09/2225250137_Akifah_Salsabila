/// Isi distrik (materi). Urutan segmen mengikuti design.md §2.1:
/// animasi → contoh terselesaikan → contoh setengah jadi → checkpoint.
///
/// Semua soal cerita diambil dari paket 7 soal tetap (lib/core/domain/soal_tetap.dart).
library;

sealed class Segment {
  final String title;
  const Segment(this.title);
}

class AnimSegment extends Segment {
  final String animId;
  final String intro;
  const AnimSegment(super.title, this.animId, this.intro);
}

class TriangleSegment extends Segment {
  const TriangleSegment(super.title);
}

/// Contoh terselesaikan memakai satu soal tetap.
class WorkedSegment extends Segment {
  final int soal;
  const WorkedSegment(super.title, this.soal);
}

/// Contoh setengah jadi: langkah ① dan ② sudah diisi.
class CompletionSegment extends Segment {
  final int soal;
  const CompletionSegment(super.title, this.soal);
}

/// Latihan dengan petunjuk dan boleh mencoba lagi.
class PracticeSegment extends Segment {
  final List<int> soal;
  const PracticeSegment(super.title, this.soal);
}

/// Checkpoint: satu kali jawab per langkah; lulus bila [passMin] soal mendapat ≥ 66%.
class CheckpointSegment extends Segment {
  final List<int> soal;
  final int passMin;
  const CheckpointSegment(super.title, this.soal, this.passMin);
}

class DrillSegment extends Segment {
  final int count;
  final int level;
  const DrillSegment(super.title, this.count, this.level);
}

class QuickSegment extends Segment {
  final int count;
  final bool isCheckpoint;
  const QuickSegment(super.title, this.count, {this.isCheckpoint = false});
}

class CalculatorSegment extends Segment {
  const CalculatorSegment(super.title);
}

class ReadingToolsSegment extends Segment {
  const ReadingToolsSegment(super.title);
}

class District {
  final String id;
  final String name;
  final String icon;
  final String tagline;
  final List<String> prerequisites;
  final List<String> interviewRefs;
  final List<Segment> segments;
  final List<String> summary;
  final List<String> unlocksGames;

  /// Nomor soal tetap yang dibahas di distrik ini.
  final List<int> soal;

  const District({
    required this.id,
    required this.name,
    required this.icon,
    required this.tagline,
    required this.prerequisites,
    required this.interviewRefs,
    required this.segments,
    required this.summary,
    required this.unlocksGames,
    required this.soal,
  });
}

const districts = <District>[
  District(
    id: 'menara_jam',
    name: 'Menara Jam',
    icon: '🕐',
    tagline: 'Jam, menit, dan pecahan',
    prerequisites: [],
    interviewRefs: ['IL03'],
    segments: [
      AnimSegment('Pizza Jam', 'pizza', 'Satu jam itu seperti satu pizza bundar. Geser untuk melihat berapa bagian jam dari sekian menit.'),
      AnimSegment('Selisih Waktu', 'clockgap', 'Berapa lama dari jam berangkat sampai jam tiba? Geser jamnya dan lihat garis waktunya.'),
      QuickSegment('Latihan Jam & Pecahan', 5),
      QuickSegment('Checkpoint Menara Jam', 5, isCheckpoint: true),
    ],
    summary: ['1 jam = 60 menit', '15 menit = ¼ jam = 0,25 jam', '30 menit = ½ jam = 0,5 jam', '45 menit = ¾ jam = 0,75 jam'],
    unlocksGames: [],
    soal: [],
  ),
  District(
    id: 'bundaran_jkw',
    name: 'Bundaran JKW',
    icon: '🔺',
    tagline: 'Jarak, Kecepatan, Waktu',
    prerequisites: [],
    interviewRefs: ['K02', 'GL01', 'GL02'],
    segments: [
      AnimSegment('Mobil dan Tiang Jam', 'markers',
          'Mobil melaju 60 km/jam. Artinya, setiap 1 jam mobil menempuh 60 km. Perhatikan tiang di jalan.'),
      TriangleSegment('Segitiga JKW'),
      WorkedSegment('Contoh: Waktu Tempuh Truk (Soal 7)', 7),
      CompletionSegment('Lengkapi: Perjalanan ke Museum (Soal 2)', 2),
      CheckpointSegment('Checkpoint JKW (Soal 2 & 7)', [2, 7], 2),
    ],
    summary: ['J = K × W', 'K = J ÷ W', 'W = J ÷ K', 'Kecepatan besar → waktu singkat'],
    unlocksGames: ['courier_route'],
    soal: [2, 7],
  ),
  District(
    id: 'bengkel_satuan',
    name: 'Bengkel Satuan',
    icon: '🔧',
    tagline: 'Menyamakan satuan',
    prerequisites: ['bundaran_jkw'],
    interviewRefs: ['IL01', 'IL05', 'EL04', 'DS01', 'DS02'],
    segments: [
      AnimSegment('Tangga Satuan', 'ladder', 'Turun tangga berarti satuan makin kecil, jadi angkanya makin besar (dikali). Naik tangga: dibagi.'),
      AnimSegment('Roda Waktu', 'timewheel', '1 jam = 60 menit. Jam → menit: dikali 60. Menit → jam: dibagi 60.'),
      AnimSegment('km/jam → m/detik', 'kmh2ms', 'Kita ubah 72 km/jam menjadi m/detik. Tiga langkah, satu per satu. Tidak perlu terburu-buru.'),
      CalculatorSegment('Kalkulator Satuan'),
      DrillSegment('Latihan Konversi', 6, 2),
      WorkedSegment('Contoh: Kecepatan Sepeda Rani (Soal 5)', 5),
      CompletionSegment('Lengkapi: Jarak Perjalanan Ayah (Soal 6)', 6),
      CheckpointSegment('Checkpoint Bengkel (Soal 5 & 6)', [5, 6], 2),
    ],
    summary: ['Besar → kecil: dikali', 'Kecil → besar: dibagi', '1 jam = 60 menit = 3.600 detik', '1 km = 1.000 m'],
    unlocksGames: ['unit_rally'],
    soal: [5, 6],
  ),
  District(
    id: 'jalan_cerita',
    name: 'Jalan Raya Cerita',
    icon: '🛣️',
    tagline: 'Membaca soal cerita',
    prerequisites: ['bengkel_satuan'],
    interviewRefs: ['K03', 'EL01', 'EL02', 'EL03', 'EL05', 'GL03', 'GL04'],
    segments: [
      ReadingToolsSegment('Penanda Info & Kamus Jalan'),
      WorkedSegment('Contoh: Memeriksa Hitungan Budi (Soal 4)', 4),
      CompletionSegment('Lengkapi: Memilih Rute Bersepeda (Soal 1)', 1),
      CheckpointSegment('Checkpoint Cerita (Soal 1 & 4)', [1, 4], 2),
    ],
    summary: ['Tandai angka: jarak, kecepatan, lama', 'Tulis Diketahui–Ditanya', 'Bandingkan dalam satuan yang sama', 'Periksa: apakah hasilnya masuk akal?'],
    unlocksGames: ['traffic_detective'],
    soal: [1, 4],
  ),
  District(
    id: 'halte_transit',
    name: 'Halte Transit',
    icon: '🚏',
    tagline: 'Perjalanan dua tahap',
    prerequisites: ['jalan_cerita'],
    interviewRefs: ['IL02', 'GL02', 'GL05'],
    segments: [
      AnimSegment('Mobil dan Tiang Jam', 'markers',
          'Ingat lagi: tiap jam, kendaraan menempuh sejauh kecepatannya. Kalau kecepatannya berubah, hitung tiap bagian sendiri-sendiri.'),
      CompletionSegment('Lengkapi: Perjalanan Bersepeda Andi (Soal 3)', 3),
      PracticeSegment('Latihan Ulang Semua Soal', [7, 5, 6, 2, 1, 4]),
      CheckpointSegment('Checkpoint Halte (Soal 3)', [3], 1),
    ],
    summary: [
      'Hitung waktu tiap bagian: jarak ÷ kecepatan',
      'Total waktu = jumlah semua waktu',
      'Kecepatan rata-rata = total jarak ÷ total waktu',
      'Bukan rata-rata dari dua kecepatan!',
    ],
    unlocksGames: ['meeting_point', 'catch_bus'],
    soal: [3],
  ),
];

District districtById(String id) => districts.firstWhere((d) => d.id == id);

class GameInfo {
  final String id;
  final String name;
  final String icon;
  final String desc;
  final String unlockedBy;
  const GameInfo(this.id, this.name, this.icon, this.desc, this.unlockedBy);
}

const games = <GameInfo>[
  GameInfo('unit_rally', 'Rally Satuan', '🏎️', 'Pilih gerbang konversi yang benar!', 'bengkel_satuan'),
  GameInfo('meeting_point', 'Tebak Titik Temu', '🚩', 'Tancapkan bendera di tempat mereka bertemu.', 'halte_transit'),
  GameInfo('catch_bus', 'Kejar Bus Terakhir', '🚌', 'Atur kecepatan motor untuk menyusul bus.', 'halte_transit'),
  GameInfo('courier_route', 'Pilih Rute Kurir', '📦', 'Antar paket tepat waktu!', 'bundaran_jkw'),
  GameInfo('traffic_detective', 'Detektif Lalu Lintas', '🔍', 'Temukan langkah yang salah.', 'jalan_cerita'),
];
