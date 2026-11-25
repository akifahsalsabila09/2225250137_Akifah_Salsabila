/// Isi distrik (materi). Urutan segmen mengikuti design.md §2.1:
/// animasi → contoh terselesaikan → contoh setengah jadi → latihan → checkpoint.
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

class WorkedSegment extends Segment {
  final String templateId;
  final int level;
  final int seed;
  const WorkedSegment(super.title, this.templateId, this.level, {this.seed = 7});
}

class CompletionSegment extends Segment {
  final String templateId;
  final int level;
  final int seed;
  const CompletionSegment(super.title, this.templateId, this.level, {this.seed = 11});
}

class PracticeSegment extends Segment {
  final List<String> templateIds;
  final int count;
  final int level;
  const PracticeSegment(super.title, this.templateIds, this.count, this.level);
}

class CheckpointSegment extends Segment {
  final List<String> templateIds;
  final int count;
  final int passMin;
  final int level;
  const CheckpointSegment(super.title, this.templateIds, this.count, this.passMin, this.level);
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
  final List<String> quizTemplates;

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
    required this.quizTemplates,
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
    quizTemplates: [],
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
      WorkedSegment('Contoh: Mencari Waktu', 'waktu_tempuh', 1),
      CompletionSegment('Lengkapi: Mencari Kecepatan', 'kecepatan', 1),
      PracticeSegment('Latihan JKW', ['waktu_tempuh', 'jarak', 'kecepatan'], 3, 1),
      CheckpointSegment('Checkpoint JKW', ['waktu_tempuh', 'kecepatan', 'jarak'], 3, 2, 1),
    ],
    summary: ['J = K × W', 'K = J ÷ W', 'W = J ÷ K', 'Kecepatan besar → waktu singkat'],
    unlocksGames: ['courier_route'],
    quizTemplates: ['waktu_tempuh', 'kecepatan', 'jarak', 'pilih_rute'],
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
      WorkedSegment('Contoh: Waktu dalam Menit', 'kecepatan', 2),
      PracticeSegment('Latihan Satuan Campur', ['kecepatan', 'jarak'], 3, 2),
      CheckpointSegment('Checkpoint Bengkel', ['kecepatan', 'jarak', 'kecepatan'], 3, 2, 2),
    ],
    summary: ['Besar → kecil: dikali', 'Kecil → besar: dibagi', '1 jam = 60 menit = 3.600 detik', '1 km = 1.000 m'],
    unlocksGames: ['unit_rally'],
    quizTemplates: ['kecepatan', 'jarak', 'periksa_hitungan', 'tepat_waktu'],
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
      WorkedSegment('Contoh: Coret Info Tak Perlu', 'waktu_tempuh', 3),
      PracticeSegment('Latihan Membaca Soal', ['waktu_tempuh', 'tepat_waktu', 'periksa_hitungan'], 3, 2),
      CheckpointSegment('Checkpoint Cerita', ['tepat_waktu', 'periksa_hitungan', 'waktu_tempuh'], 3, 2, 2),
    ],
    summary: ['Tandai angka: jarak, kecepatan, lama, jam', '"Pukul" = jam, bukan lama', 'Coret info yang tidak dipakai', 'Tulis Diketahui–Ditanya'],
    unlocksGames: ['traffic_detective'],
    quizTemplates: ['tepat_waktu', 'periksa_hitungan', 'waktu_tempuh', 'pilih_rute'],
  ),
  District(
    id: 'simpang_berpapasan',
    name: 'Simpang Berpapasan',
    icon: '🚦',
    tagline: 'Dua kendaraan saling mendekat',
    prerequisites: ['jalan_cerita'],
    interviewRefs: ['IL04', 'DS01', 'GL03'],
    segments: [
      AnimSegment('Pita Jarak', 'headon',
          'Mobil A dan bus B saling mendekat. Lihat pita biru di antara mereka. Berapa km pita itu menyusut setiap jam?'),
      WorkedSegment('Contoh: Berpapasan', 'berpapasan', 1),
      CompletionSegment('Lengkapi: Berpapasan', 'berpapasan', 2),
      PracticeSegment('Latihan Berpapasan', ['berpapasan'], 3, 2),
      CheckpointSegment('Checkpoint Simpang', ['berpapasan', 'berpapasan', 'dua_tahap'], 3, 2, 2),
    ],
    summary: ['Berlawanan arah: kecepatan dijumlah', 'Waktu = jarak ÷ (vA + vB)', 'Jam bertemu = jam berangkat + waktu'],
    unlocksGames: ['meeting_point'],
    quizTemplates: ['berpapasan', 'dua_tahap'],
  ),
  District(
    id: 'jalur_susul',
    name: 'Jalur Susul',
    icon: '🏁',
    tagline: 'Mengejar dari belakang',
    prerequisites: ['jalan_cerita'],
    interviewRefs: ['IL04', 'IL05'],
    segments: [
      AnimSegment('Siapa Duluan?', 'catchup',
          'Bus berangkat lebih dulu. Motor menyusul 30 menit kemudian. Lihat seberapa jauh bus sudah di depan.'),
      WorkedSegment('Contoh: Menyusul', 'menyusul', 1),
      CompletionSegment('Lengkapi: Menyusul', 'menyusul', 2),
      PracticeSegment('Latihan Menyusul', ['menyusul'], 3, 2),
      CheckpointSegment('Checkpoint Susul', ['menyusul', 'menyusul', 'tepat_waktu'], 3, 2, 2),
    ],
    summary: ['Searah: kecepatan dikurang', 'Jarak awal = v yang duluan × selisih waktu', 'Waktu = jarak awal ÷ (vB − vA)'],
    unlocksGames: ['catch_bus'],
    quizTemplates: ['menyusul', 'tepat_waktu'],
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
  GameInfo('meeting_point', 'Tebak Titik Temu', '🚩', 'Tancapkan bendera di tempat mereka bertemu.', 'simpang_berpapasan'),
  GameInfo('catch_bus', 'Kejar Bus Terakhir', '🚌', 'Atur kecepatan motor untuk menyusul bus.', 'jalur_susul'),
  GameInfo('courier_route', 'Pilih Rute Kurir', '📦', 'Antar paket tepat waktu!', 'bundaran_jkw'),
  GameInfo('traffic_detective', 'Detektif Lalu Lintas', '🔍', 'Temukan langkah yang salah.', 'jalan_cerita'),
];
