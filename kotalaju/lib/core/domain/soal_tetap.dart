import 'problem.dart';
import 'problem_bank.dart';
import 'units.dart';

/// Paket 7 soal tetap yang dipakai di SELURUH aplikasi
/// (latihan materi, checkpoint, kuis, Tes Awal, dan Ujian Kota).
///
/// Soal 1–4 diambil dari kisi-kisi Mathematical Literacy (angka dan konteks sama persis;
/// kalimat dipecah menjadi kalimat pendek ≤ 15 kata sesuai prinsip Cognitive Load).
/// Soal 5–7 adalah soal tambahan kelas VII tentang kecepatan, jarak, dan waktu.
class SoalTetap {
  final int no;
  final String judul;
  final bool dariKisiKisi;
  final Problem Function() _build;
  const SoalTetap(this.no, this.judul, this.dariKisiKisi, this._build);

  Problem get problem => _build();
}

final List<SoalTetap> soalTetap = [
  SoalTetap(1, 'Memilih Rute Bersepeda', true,
      () => buildRouteChoice(s: 6, vA: 12, vB: 15, deadline: 25, level: 2, seed: 101, ctx: 0)),
  SoalTetap(2, 'Perjalanan Menuju Museum', true,
      () => buildTravelTime(s: 150, v: 50, level: 2, seed: 102, ctx: 0)),
  SoalTetap(3, 'Perjalanan Bersepeda Andi', true,
      () => buildTwoLeg(s1: 4, v1: 8, s2: 6, v2: 12, level: 2, seed: 103, ctx: 0)),
  SoalTetap(4, 'Memeriksa Waktu Perjalanan Bus', true,
      () => buildCheckInverted(s: 120, v: 40, character: 'Budi', level: 2, seed: 104)),
  SoalTetap(5, 'Kecepatan Sepeda Rani', false,
      () => buildSpeed(s: 6, timeValue: 30, timeUnit: Unit.min, level: 2, seed: 105, ctx: 0)),
  SoalTetap(6, 'Jarak Perjalanan Ayah', false,
      () => buildDistance(v: 60, timeValue: 90, timeUnit: Unit.min, level: 2, seed: 106, ctx: 0)),
  SoalTetap(7, 'Waktu Tempuh Truk Sayur', false,
      () => buildTravelTime(s: 90, v: 60, level: 2, seed: 107, ctx: 2)),
];

/// Ambil soal berdasarkan nomor (1–7).
Problem soal(int no) => soalTetap[no - 1].problem;

List<Problem> soalNomor(List<int> nomor) => [for (final n in nomor) soal(n)];

List<Problem> semuaSoal() => [for (final s in soalTetap) s.problem];

/// Tes Awal dan Ujian Kota: 4 soal kisi-kisi (satu per indikator, skor maksimal 24).
List<Problem> soalKisiKisi() => soalNomor(const [1, 2, 3, 4]);

/// Nomor soal (1–7) dari sebuah problem tetap, atau null bila bukan soal tetap.
int? nomorSoal(Problem p) {
  for (final s in soalTetap) {
    if (s.problem.id == p.id) return s.no;
  }
  return null;
}

/// Label pendek untuk riwayat dan daftar.
String labelSoal(String problemId) {
  for (final s in soalTetap) {
    if (s.problem.id == problemId) return 'Soal ${s.no}: ${s.judul}';
  }
  return problemId;
}

Indicator indikatorSoal(int no) => soal(no).indicator;
