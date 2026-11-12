# API Specification — KotaLaju

KotaLaju bersifat *offline-first*. Karena itu "API" di dokumen ini mencakup tiga hal:

1. **API Domain internal** (antarmuka Dart) yang dipakai semua fitur: konversi satuan, pembangkit soal, penilaian, dan simulasi.
2. **Skema Konten** (JSON) untuk materi dan soal, agar penulis konten dapat menambah soal tanpa mengubah kode.
3. **REST API Sinkronisasi** (v1.1, opsional) untuk mengirim hasil belajar ke server dan dasbor guru.

Arsitektur lengkap ada di [architecture.md](architecture.md).

---

## 1. Konvensi Umum

| Hal | Konvensi |
|---|---|
| Penamaan kode | Bahasa Inggris (`Quantity`, `scoreStep`); teks yang dilihat siswa dalam Bahasa Indonesia |
| Penamaan JSON | `snake_case` |
| ID | UUID v4 untuk entitas runtime; ID konten berupa *slug* (`berpapasan_l2_01`) |
| Waktu | ISO 8601 UTC (`2026-11-12T08:30:00Z`); jam dalam soal memakai `"07.30"` |
| Angka desimal | Titik di JSON (`0.75`); ditampilkan ke siswa dengan koma (`0,75`) |
| Satuan | Kode tetap: `km`, `hm`, `dam`, `m`, `h` (jam), `min` (menit), `s` (detik), `km/h`, `m/min`, `m/s` |

---

## 2. API Domain Internal (Dart)

### 2.1 Satuan dan Besaran

```dart
enum Dimension { distance, time, speed }

enum Unit {
  km, hm, dam, m,          // jarak
  h, min, s,               // waktu
  kmPerH, mPerMin, mPerS;  // kecepatan
  Dimension get dimension;
  String get label;        // "km", "jam", "menit", "km/jam", ...
}

class Quantity {
  final Rational value;    // pecahan eksak, mis. 3/4
  final Unit unit;
  Quantity to(Unit target);                 // lempar UnitMismatch jika dimensi beda
  bool equals(Quantity other, {double relTol = 1e-6});
}

class ConversionStep {
  final String description;   // "1 jam = 60 menit, jadi bagi dengan 60"
  final String expression;    // "45 ÷ 60"
  final Quantity result;      // 0,75 jam
}

abstract interface class UnitEngine {
  Quantity convert(Quantity q, Unit target);
  List<ConversionStep> explain(Quantity q, Unit target);   // untuk Kalkulator Satuan & animasi
  bool sameUnitsFor(List<Quantity> qs);                    // cek langkah ③
}
```

**Contoh**
```dart
engine.explain(Quantity(Rational(72), Unit.kmPerH), Unit.mPerS);
// [ "Ubah km ke m: 72 × 1000 = 72.000 m",
//   "Ubah jam ke detik: 1 × 3600 = 3600 detik",
//   "Bagi: 72.000 ÷ 3600 = 20 m/detik" ]
```

### 2.2 Simulator Gerak

```dart
class Mover {
  final String id;            // "A", "B"
  final String vehicle;       // "car", "bus", "motorbike", "bicycle", ...
  final Quantity startPos;    // km dari titik 0
  final int direction;        // +1 ke kanan, -1 ke kiri
  final Quantity speed;
  final ClockTime departAt;   // 07.00
}

abstract interface class MotionSimulator {
  Quantity positionAt(Mover m, ClockTime t);
  MeetingResult? meeting(Mover a, Mover b);    // berpapasan atau menyusul
  List<Frame> frames(List<Mover> ms, ClockTime from, ClockTime to, Duration step); // untuk animasi
}

class MeetingResult {
  final ClockTime time;            // jam bertemu
  final Quantity elapsed;          // lama sejak keberangkatan terakhir
  final Quantity position;         // km dari titik 0
  final Quantity relativeSpeed;    // jumlah (berpapasan) atau selisih (menyusul)
  final MeetingType type;          // headOn | catchUp
}
```

### 2.3 Soal dan Penilaian

```dart
enum Indicator { reasoning, formulating, employing, interpreting }
enum StepKind { readAndTag, knownAsked, unifyUnits, compute, checkLogic, choose, explain, findError }

class Problem {
  final String id;              // instansi: "<template_id>#<seed>"
  final String templateId;
  final Indicator indicator;
  final int level;              // 1..3
  final String storyText;       // sudah diisi angka
  final List<Token> tokens;     // potongan teks yang dapat ditandai
  final RoadScene scene;        // untuk diagram & Sketsa Jalan
  final List<ProblemStep> steps;
  final Rubric rubric;          // total maks 6
  final List<Hint> hints;       // tingkat 1..4
}

class StepAnswer { final StepKind kind; final Map<String, Object?> data; }

class StepResult {
  final bool correct;
  final int points;
  final ErrorCode? error;        // lihat tabel kode kesalahan
  final String feedback;         // teks umpan balik untuk siswa
}

abstract interface class ProblemGenerator {
  Problem generate(ProblemTemplate t, {required int level, required int seed});
}

abstract interface class Scorer {
  StepResult scoreStep(Problem p, int stepIndex, StepAnswer a, {Map<int, StepAnswer> previous});
  AttemptScore total(Problem p, List<StepResult> results);
}

abstract interface class ErrorDiagnoser {
  ErrorCode diagnose(Problem p, int stepIndex, StepAnswer a);
}
```

**Kode kesalahan (`ErrorCode`)**

| Kode | Ikon | Pesan umpan balik (contoh) |
|---|---|---|
| `UNIT_NOT_CONVERTED` | 🔧 | "Satuannya belum sama. Kecepatan dalam km/jam, tetapi waktu dalam menit." |
| `UNIT_WRONG_DIRECTION` | 🔧 | "Menit ke jam: angkanya harus jadi lebih kecil. Bagi dengan 60." |
| `UNIT_BASE_100` | 🔧 | "Ingat, 1 jam = 60 menit, bukan 100 menit." |
| `FORMULA_INVERTED` | 🔁 | "Coba lihat segitiga JKW lagi. Waktu = jarak ÷ kecepatan." |
| `RELATIVE_SPEED_WRONG_OP` | 🔁 | "Mereka saling mendekat dari arah berlawanan. Jaraknya berkurang lebih cepat atau lebih lambat?" |
| `HEAD_START_IGNORED` | 📖 | "Siapa yang berangkat lebih dulu? Seberapa jauh dia sudah berjalan?" |
| `CLOCK_VS_DURATION` | 📖 | "07.00 itu jam berangkat, bukan lama perjalanan." |
| `ARITHMETIC` | ➗ | "Caramu sudah benar! Cek lagi hitungannya." |
| `UNKNOWN` | ❓ | "Belum tepat. Mau lihat petunjuk?" |

### 2.4 Kemajuan, Adaptasi, dan Petunjuk

```dart
abstract interface class AdaptivePath {
  int levelFor(String studentId, StepKind step);
  void record(String studentId, StepKind step, {required bool correct, required int hintLevelUsed});
  // aturan: 3 benar berturut tanpa hint ≥3 → naik; 2 salah berturut → turun
}

abstract interface class HintPolicy {
  Hint next(Problem p, int stepIndex, int currentHintLevel);
  bool shouldPulse(int wrongCountOnStep);   // true jika ≥ 2
}

abstract interface class ProgressRepository {
  Future<void> saveAttempt(Attempt a);
  Future<DistrictStatus> districtStatus(String studentId, String districtId);
  Future<MlProfile> mlProfile(String studentId);   // skor rata-rata per indikator (untuk radar)
}

abstract interface class AnalyticsRepository {
  Future<void> log(LearningEvent e);
  Future<File> exportCsv({DateTime? from, DateTime? to, String? classCode});
}
```

---

## 3. Skema Konten

Semua berkas berada di `assets/content/` dan divalidasi oleh `tool/validate_content.dart`.

### 3.1 Distrik (`districts/<id>.json`)

```json
{
  "id": "bengkel_satuan",
  "title": "Bengkel Satuan",
  "icon": "wrench",
  "order": 3,
  "prerequisites": ["bundaran_jkw"],
  "interview_refs": ["IL01", "IL05", "EL04", "DS01", "DS02"],
  "segments": [
    {
      "type": "animation",
      "rive": "assets/rive/roda_waktu.riv",
      "state_machine": "main",
      "checkpoints": [
        { "id": "cp1", "caption": "1 jam = 60 menit" },
        { "id": "cp2", "caption": "Jam → menit: kali 60" }
      ],
      "narration": "assets/audio/narasi/bengkel_01.ogg"
    },
    { "type": "worked_example", "template_id": "konversi_menit_jam", "level": 1 },
    { "type": "completion", "template_id": "konversi_menit_jam", "level": 1, "blank_steps": [3] },
    { "type": "practice", "template_ids": ["konversi_menit_jam", "konversi_kmh_ms"], "count": 4 },
    { "type": "checkpoint", "template_ids": ["konversi_menit_jam", "konversi_kmh_ms"], "count": 3, "pass_min": 2 }
  ],
  "summary_card": {
    "points": [
      "Satuan besar → kecil: kali",
      "Satuan kecil → besar: bagi",
      "1 jam = 60 menit = 3600 detik"
    ]
  },
  "unlocks_games": ["unit_rally"]
}
```

### 3.2 Templat Soal (`problems/<id>.json`)

```json
{
  "id": "berpapasan_dua_kota",
  "indicator": "formulating",
  "topic": "headon",
  "levels": [1, 2, 3],
  "variables": {
    "jarak":  { "unit": "km",   "range": [60, 300], "step": 10 },
    "va":     { "unit": "km/h", "range": [30, 80],  "step": 5 },
    "vb":     { "unit": "km/h", "range": [30, 80],  "step": 5 },
    "berangkat": { "type": "clock", "options": ["06.00", "07.00", "07.30", "08.00"] },
    "kendaraan_a": { "type": "vehicle", "options": ["mobil", "motor", "bus"] },
    "kendaraan_b": { "type": "vehicle", "options": ["truk", "bus", "mobil"] }
  },
  "constraints": [
    "level == 1 implies (jarak % (va + vb) == 0)",
    "level == 2 implies (jarak * 4) % (va + vb) == 0"
  ],
  "story": [
    "{kendaraan_a} A berangkat dari Kota Barat pukul {berangkat}.",
    "Kecepatannya {va} km/jam.",
    "{kendaraan_b} B berangkat dari Kota Timur pada jam yang sama.",
    "Kecepatannya {vb} km/jam.",
    "Jarak kedua kota {jarak} km.",
    "Pukul berapa mereka [[berpapasan]]?"
  ],
  "distractors_l3": ["{kendaraan_a} A berwarna merah dan membawa 4 penumpang."],
  "scene": {
    "road_length": "{jarak}",
    "movers": [
      { "id": "A", "vehicle": "{kendaraan_a}", "start": 0, "direction": 1, "speed": "{va}", "depart": "{berangkat}" },
      { "id": "B", "vehicle": "{kendaraan_b}", "start": "{jarak}", "direction": -1, "speed": "{vb}", "depart": "{berangkat}" }
    ]
  },
  "steps": [
    { "kind": "read_and_tag", "expected_tags": { "va": "speed", "vb": "speed", "jarak": "distance", "berangkat": "clock" } },
    { "kind": "known_asked", "asked": "clock_meeting" },
    { "kind": "unify_units", "target_units": { "distance": "km", "time": "h" } },
    { "kind": "compute", "sub": [
        { "prompt": "Kecepatan gabungan", "answer": "va + vb", "unit": "km/h" },
        { "prompt": "Lama sampai berpapasan", "answer": "jarak / (va + vb)", "unit": "h" },
        { "prompt": "Jam berpapasan", "answer": "berangkat + jarak / (va + vb)", "unit": "clock" }
    ]},
    { "kind": "check_logic", "options": [
        { "text": "Waktunya lebih singkat daripada jika A berjalan sendiri", "correct": true },
        { "text": "Waktunya lebih lama karena ada dua kendaraan", "correct": false }
    ]}
  ],
  "rubric": [
    { "stage": 1, "step": 0, "points": 1, "desc": "Mengidentifikasi informasi relevan" },
    { "stage": 2, "step": 1, "points": 1, "desc": "Menentukan besaran yang dicari" },
    { "stage": 3, "step": 3, "sub": 0, "points": 1, "desc": "Model kecepatan gabungan" },
    { "stage": 4, "step": 3, "sub": 1, "points": 1, "desc": "Menghitung lama perjalanan" },
    { "stage": 5, "step": 3, "sub": 2, "points": 1, "desc": "Menentukan jam berpapasan" },
    { "stage": 6, "step": 4, "points": 1, "desc": "Menafsirkan kewajaran hasil" }
  ],
  "hints": [
    { "level": 1, "text": "Mereka bergerak saling mendekat atau saling menjauh?" },
    { "level": 2, "action": "open_road_sketch", "text": "Coba gambar jalan lurus, A dari kiri, B dari kanan." },
    { "level": 3, "text": "Setiap 1 jam, jarak di antara mereka berkurang {va} + {vb} km." },
    { "level": 4, "action": "show_worked_example", "seed_offset": 1 }
  ]
}
```

**Aturan validasi templat**
- Total poin `rubric` = 6.
- Setiap `story` (setelah diisi) ≤ 15 kata per kalimat.
- Setiap templat wajib memiliki `scene` (agar diagram jalan selalu ada).
- `distractors_l3` hanya boleh diisi jika `indicator == "formulating"`.
- Generator harus mampu menghasilkan ≥ 100 instansi valid per level yang tercantum.

### 3.3 Kamus (`glossary.json`)

```json
[
  { "term": "berpapasan", "meaning": "Bertemu saat bergerak dari arah berlawanan.", "image": "glossary/berpapasan.webp" },
  { "term": "menyusul", "meaning": "Mengejar dari belakang, arahnya sama, sampai sejajar.", "image": "glossary/menyusul.webp" },
  { "term": "waktu tempuh", "meaning": "Lama perjalanan, bukan jam berangkat.", "image": "glossary/waktu_tempuh.webp" }
]
```

### 3.4 Tes (`tests/pretest.json`, `tests/posttest.json`)

```json
{
  "id": "pretest_v1",
  "ml_items": [
    { "indicator": "reasoning",    "template_id": "pilih_rute",          "level": 2, "seed": 1001 },
    { "indicator": "formulating",  "template_id": "bus_museum",          "level": 2, "seed": 1002 },
    { "indicator": "employing",    "template_id": "dua_tahap_rata_rata", "level": 2, "seed": 1003 },
    { "indicator": "interpreting", "template_id": "periksa_budi",        "level": 2, "seed": 1004 }
  ],
  "prerequisite_items": ["jam_ke_pecahan_01", "jam_ke_pecahan_02", "selisih_jam_01",
                         "selisih_jam_02", "pecahan_desimal_01", "pembagian_pecahan_01"],
  "hints_allowed": false,
  "unit_calculator": "locked",
  "max_score": 24
}
```
Posttest memakai templat yang sama dengan **seed berbeda** (soal paralel).

### 3.5 Event Pembelajaran

```json
{
  "id": "6f1c0c1e-0d7a-4a5e-9b0a-2f3d1b7e8c11",
  "student_id": "0b9c...",
  "type": "step_answered",
  "created_at": "2026-11-12T08:30:00Z",
  "payload": {
    "attempt_id": "a1b2...",
    "problem_id": "berpapasan_dua_kota#48213",
    "step_no": 3,
    "correct": false,
    "error_code": "UNIT_WRONG_DIRECTION",
    "hint_level_used": 2,
    "duration_ms": 41200
  }
}
```

Jenis event: `app_opened`, `consent_given`, `pretest_completed`, `segment_viewed`, `animation_control` (play/pause/replay/slow), `tool_used` (highlighter/sketch/calculator/glossary/timeline/triangle), `step_answered`, `hint_opened`, `attempt_completed`, `mental_effort_rated`, `game_session_completed`, `district_completed`, `posttest_completed`.

---

## 4. REST API Sinkronisasi (v1.1)

**Base URL**: `https://<server>/v1`  ·  **Format**: JSON  ·  **Autentikasi**: `Authorization: Bearer <device_token>`

### 4.1 Ringkasan Endpoint

| Metode | Path | Peran | Deskripsi |
|---|---|---|---|
| POST | `/devices/register` | Siswa | Mendaftarkan perangkat dengan kode kelas dan mendapat `device_token` |
| POST | `/sync/batch` | Siswa | Mengirim batch event, percobaan, dan kemajuan |
| GET | `/content/version` | Siswa | Mengecek versi konten terbaru |
| GET | `/content/bundle/{version}` | Siswa | Mengunduh paket konten (ZIP) |
| POST | `/teacher/login` | Guru | Login guru dan mendapat token guru |
| GET | `/classes/{class_code}/summary` | Guru | Rekap kelas per indikator ML |
| GET | `/classes/{class_code}/students` | Guru | Daftar siswa dan kemajuan |
| GET | `/students/{student_id}/report` | Guru | Laporan rinci satu siswa |
| GET | `/classes/{class_code}/errors` | Guru | Distribusi jenis kesalahan |
| GET | `/classes/{class_code}/export.csv` | Guru/Peneliti | Ekspor data lengkap |

### 4.2 `POST /devices/register`

Request
```json
{ "class_code": "7A-SMPN1", "student_id": "0b9c...", "nickname": "Raka", "app_version": "1.1.0" }
```
Response `201`
```json
{ "device_token": "eyJhbGciOi...", "class_name": "VII A", "server_time": "2026-11-12T08:00:00Z" }
```
Galat: `404 CLASS_NOT_FOUND`, `409 ALREADY_REGISTERED`.

### 4.3 `POST /sync/batch`

Request (maksimal 500 event per batch)
```json
{
  "student_id": "0b9c...",
  "events": [ { "id": "6f1c...", "type": "step_answered", "created_at": "...", "payload": { } } ],
  "attempts": [
    { "id": "a1b2...", "problem_id": "berpapasan_dua_kota#48213", "context": "district_quiz",
      "indicator": "formulating", "level": 2, "score": 5, "max_score": 6,
      "started_at": "...", "finished_at": "...", "mental_effort": 4 }
  ],
  "progress": { "districts": { "bengkel_satuan": "done" }, "step_levels": { "unify_units": 2 } }
}
```
Response `200`
```json
{ "accepted": 37, "duplicates": 2, "rejected": [], "next_sync_after_s": 900 }
```
Server bersifat **idempoten** berdasarkan `id`; event yang sudah ada dihitung sebagai `duplicates`.

### 4.4 `GET /classes/{class_code}/summary`

Response `200`
```json
{
  "class_code": "7A-SMPN1",
  "students": 32,
  "pretest_avg": { "reasoning": 2.1, "formulating": 2.8, "employing": 3.0, "interpreting": 1.9, "total": 9.8 },
  "posttest_avg": { "reasoning": 4.2, "formulating": 4.6, "employing": 4.9, "interpreting": 4.0, "total": 17.7 },
  "n_gain": 0.56,
  "top_errors": [
    { "code": "UNIT_WRONG_DIRECTION", "share": 0.31 },
    { "code": "HEAD_START_IGNORED", "share": 0.18 }
  ],
  "mental_effort_trend": [ { "level": 1, "avg": 5.8 }, { "level": 2, "avg": 5.1 }, { "level": 3, "avg": 4.6 } ]
}
```
*(Angka di atas hanya contoh format.)*

### 4.5 Format Galat

```json
{ "error": { "code": "VALIDATION_FAILED", "message": "events[3].created_at tidak valid", "details": { } } }
```

| HTTP | Kode | Arti |
|---|---|---|
| 400 | `VALIDATION_FAILED` | Isi permintaan tidak sesuai skema |
| 401 | `UNAUTHORIZED` | Token tidak ada atau kedaluwarsa |
| 403 | `FORBIDDEN` | Guru mengakses kelas yang bukan miliknya |
| 404 | `NOT_FOUND` / `CLASS_NOT_FOUND` | Sumber daya tidak ditemukan |
| 409 | `ALREADY_REGISTERED` | Perangkat sudah terdaftar |
| 413 | `BATCH_TOO_LARGE` | Lebih dari 500 event |
| 429 | `RATE_LIMITED` | Terlalu sering; ikuti `Retry-After` |

### 4.6 Privasi di Server
- Server **tidak** menyimpan nama asli, hanya `nickname` dan UUID.
- Data siswa hanya dapat dibaca oleh guru pemilik kelas dan peneliti yang ditunjuk.
- Data dapat dihapus per siswa melalui permintaan guru (`DELETE /students/{id}`, peran admin).

---

## 5. Format Ekspor CSV

`attempts.csv`
```
student_id,nickname,class_code,context,problem_id,indicator,level,score,max_score,mental_effort,started_at,finished_at
```
`steps.csv`
```
attempt_id,step_no,step_kind,correct,points,error_code,hint_level_used,duration_ms
```
`summary.csv` (satu baris per siswa)
```
student_id,nickname,pre_reasoning,pre_formulating,pre_employing,pre_interpreting,pre_total,post_reasoning,post_formulating,post_employing,post_interpreting,post_total,n_gain,unit_error_rate_pre,unit_error_rate_post,avg_mental_effort
```
