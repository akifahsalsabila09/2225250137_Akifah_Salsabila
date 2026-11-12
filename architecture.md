# Architecture — KotaLaju

Dokumen ini menjelaskan arsitektur teknis aplikasi. Kebutuhan ada di [prd.md](prd.md), desain di [design.md](design.md), dan kontrak data/antarmuka di [api.md](api.md).

---

## 1. Ringkasan Keputusan Teknologi

| Kebutuhan | Pilihan | Alasan |
|---|---|---|
| Framework aplikasi | **Flutter 3.x (Dart 3)** | Satu basis kode untuk Android dan Web; performa animasi tinggi (Skia/Impeller); cocok untuk HP spesifikasi rendah |
| Mesin game 2D | **Flame** | Game loop, sprite, kolisi, dan efek; terintegrasi dengan widget Flutter |
| Animasi karakter dan UI | **Rive** | File kecil, interaktif (*state machine*), dapat dikendalikan dari kode |
| Animasi ringan | **Lottie** (opsional) dan animasi implisit Flutter | Efek perayaan sederhana |
| Manajemen state | **Riverpod** | Dapat diuji, tanpa `BuildContext`, cocok untuk logika soal |
| Navigasi | **go_router** | Rute deklaratif, *deep link* ke distrik/soal |
| Basis data lokal | **Drift (SQLite)** | *Offline-first*, kueri relasional untuk rekap skor, migrasi skema |
| Preferensi ringan | **shared_preferences** | Pengaturan suara, mode grafis |
| Konten | **File JSON** di `assets/content/` | Materi dan soal dapat diedit tanpa mengubah kode |
| Audio | **flame_audio** / **just_audio** | Efek suara dan narasi |
| Backend (v1.1, opsional) | **Supabase** (PostgreSQL + Auth + REST) atau REST API sendiri | Sinkronisasi hasil belajar dan dasbor guru |
| Pengujian | `flutter_test`, `mocktail`, `integration_test`, *golden test* | Logika penilaian wajib teruji |

---

## 2. Gambaran Arsitektur

```
┌──────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                        │
│  ┌───────────┐ ┌──────────┐ ┌─────────┐ ┌────────┐ ┌──────────┐  │
│  │ Peta Kota │ │ Materi   │ │ Kuis    │ │ Arena  │ │ Garasi   │  │
│  │ (Flame)   │ │ (Widget+ │ │ (Alur 5 │ │ Game   │ │ /Profil  │  │
│  │           │ │  Rive)   │ │ Langkah)│ │(Flame) │ │          │  │
│  └─────┬─────┘ └────┬─────┘ └────┬────┘ └───┬────┘ └────┬─────┘  │
│        │  Alat bantu bersama: Penanda Info, Sketsa Jalan,│        │
│        │  Kalkulator Satuan, Kamus, Garis Waktu, Segitiga JKW     │
├────────┴────────────┴────────────┴──────────┴───────────┴────────┤
│                   APPLICATION LAYER (Riverpod)                   │
│  ProgressController · LessonController · ProblemSessionController│
│  HintController · GameController · RewardController              │
├──────────────────────────────────────────────────────────────────┤
│                         DOMAIN LAYER (Dart murni)                │
│  ┌──────────────┐ ┌──────────────┐ ┌───────────────┐             │
│  │ Unit Engine  │ │ Problem      │ │ Scoring &     │             │
│  │ (konversi,   │ │ Generator    │ │ Error         │             │
│  │  Quantity)   │ │ (templat)    │ │ Diagnosis     │             │
│  └──────────────┘ └──────────────┘ └───────────────┘             │
│  ┌──────────────┐ ┌──────────────┐ ┌───────────────┐             │
│  │ Motion       │ │ Adaptive     │ │ Hint Policy   │             │
│  │ Simulator    │ │ Path/Fading  │ │ (fading)      │             │
│  └──────────────┘ └──────────────┘ └───────────────┘             │
├──────────────────────────────────────────────────────────────────┤
│                          DATA LAYER                              │
│  ContentRepository (JSON aset) · ProgressRepository (Drift)      │
│  AnalyticsRepository (event log) · SyncService (v1.1, REST)      │
└──────────────────────────────────────────────────────────────────┘
```

**Aturan dependensi**: Presentation → Application → Domain ← Data. Lapisan Domain **tidak** bergantung pada Flutter, sehingga seluruh logika matematika dan penilaian dapat diuji dengan `dart test` biasa.

---

## 3. Struktur Folder

```
kotalaju/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── router.dart                # go_router: rute semua layar
│   │   ├── theme.dart                 # token warna besaran, tipografi
│   │   └── focus_mode.dart            # pembungkus Mode Fokus vs Mode Kota
│   ├── core/
│   │   ├── domain/
│   │   │   ├── quantity.dart          # Quantity(value, Unit), operasi bersatuan
│   │   │   ├── unit_engine.dart       # konversi + langkah konversi
│   │   │   ├── motion_simulator.dart  # posisi kendaraan terhadap waktu
│   │   │   ├── problem.dart           # model Problem, Step, Answer
│   │   │   ├── problem_generator.dart # templat → instansi soal
│   │   │   ├── scorer.dart            # rubrik per tahap (maks 6)
│   │   │   ├── error_diagnoser.dart   # klasifikasi jenis kesalahan
│   │   │   ├── hint_policy.dart
│   │   │   └── adaptive_path.dart     # naik/turun level per langkah
│   │   ├── data/
│   │   │   ├── db/                    # Drift: tabel & DAO
│   │   │   ├── content_repository.dart
│   │   │   ├── progress_repository.dart
│   │   │   ├── analytics_repository.dart
│   │   │   └── sync_service.dart      # v1.1
│   │   └── widgets/                   # alat bantu bersama
│   │       ├── info_highlighter/
│   │       ├── road_sketch/
│   │       ├── unit_calculator/
│   │       ├── glossary_tooltip/
│   │       ├── timeline/
│   │       ├── jkw_triangle/
│   │       └── animation_controls/    # ▶︎ ⏸ ⏭ ↺ 🐢
│   ├── features/
│   │   ├── onboarding/                # profil, persetujuan, pretest
│   │   ├── city_map/                  # Flame: peta kota
│   │   ├── lesson/                    # distrik: animasi→contoh→latihan
│   │   ├── problem_session/           # alur 5 langkah
│   │   ├── quiz/                      # kuis distrik, ujian kota
│   │   ├── games/
│   │   │   ├── unit_rally/            # G1
│   │   │   ├── meeting_point/         # G2
│   │   │   ├── catch_the_bus/         # G3
│   │   │   ├── courier_route/         # G4
│   │   │   └── traffic_detective/     # G5
│   │   ├── garage/                    # koleksi, lencana, radar ML
│   │   └── teacher/                   # mode guru, ekspor CSV
│   └── l10n/                          # teks UI (id)
├── assets/
│   ├── content/
│   │   ├── districts/*.json           # isi tiap distrik
│   │   ├── problems/*.json            # templat soal
│   │   ├── glossary.json
│   │   └── tests/pretest.json, posttest.json
│   ├── rive/*.riv
│   ├── lottie/*.json
│   ├── images/                        # sprite kendaraan, ubin kota
│   └── audio/
├── test/                              # unit test domain
├── integration_test/
└── tool/
    └── validate_content.dart          # validasi skema JSON konten
```

---

## 4. Komponen Domain Inti

### 4.1 Unit Engine
Semua besaran disimpan sebagai `Quantity` (nilai + satuan) dan **tidak pernah** sebagai angka telanjang. Hal ini mencegah bug konversi di aplikasi dan sekaligus menjadi dasar diagnosis kesalahan satuan siswa.

- Satuan yang didukung: `km, hm, dam, m` · `jam, menit, detik` · `km/jam, m/menit, m/detik`.
- `convert(q, to)` mengembalikan nilai hasil **dan daftar langkah** (`ConversionStep`) yang dipakai oleh Kalkulator Satuan dan animasi A03–A05.
- Perbandingan memakai toleransi relatif 1e-6 dan dukungan pecahan (`Fraction`) agar ¾ jam dan 0,75 jam dianggap sama.

### 4.2 Problem Generator
- Soal didefinisikan sebagai **templat** (lihat skema di [api.md](api.md#3-skema-konten)) dengan variabel acak berbatas (`range`, `step`, `constraint`).
- Generator memastikan hasil sesuai level (bilangan bulat untuk level 1; pecahan sederhana untuk level 2) dan menolak kombinasi yang menghasilkan nilai tidak wajar (misalnya sepeda 90 km/jam).
- Seed acak disimpan per percobaan agar soal dapat direproduksi untuk analisis.

### 4.3 Motion Simulator
- Model 1D: `position(t) = start + direction × v × (t − departTime)` untuk `t ≥ departTime`.
- Menghitung waktu dan titik bertemu (berpapasan) dan waktu menyusul secara analitik, lalu memverifikasi dengan simulasi diskret.
- Dipakai oleh: animasi A01/A06/A07, game G2/G3, dan **sebagai kunci jawaban**, sehingga animasi dan kunci jawaban selalu konsisten.

### 4.4 Scorer dan Error Diagnoser
- Setiap soal memiliki `rubric`: daftar tahap dengan bobot (total 6), sesuai kisi-kisi ML.
- Skor parsial: tahap yang benar tetap dinilai meskipun tahap sebelumnya salah hitung (*error carried forward*). Jika siswa salah di tahap 2 tetapi tahap 3 benar *berdasarkan nilai tahap 2 miliknya*, tahap 3 tetap diberi poin.
- `ErrorDiagnoser` mencocokkan jawaban salah dengan pola kesalahan umum:

| Kode | Pola | Contoh |
|---|---|---|
| `UNIT_NOT_CONVERTED` | Menit dipakai sebagai jam | 60 × 45 = 2700 km |
| `UNIT_WRONG_DIRECTION` | Dikali 60, padahal seharusnya dibagi | 45 menit = 2700 jam |
| `UNIT_BASE_100` | Memakai 100, bukan 60 | 45 menit = 0,45 jam |
| `FORMULA_INVERTED` | v/s, bukan s/v | 40 ÷ 120 |
| `RELATIVE_SPEED_WRONG_OP` | Menjumlah kecepatan pada soal menyusul (atau mengurangkan pada soal berpapasan) | — |
| `HEAD_START_IGNORED` | Mengabaikan jarak awal pada soal menyusul | — |
| `CLOCK_VS_DURATION` | Jam keberangkatan dipakai sebagai durasi | t = 7 |
| `ARITHMETIC` | Proses benar, salah hitung | — |
| `UNKNOWN` | Tidak cocok dengan pola mana pun | — |

### 4.5 Adaptive Path dan Hint Policy
- `AdaptivePath` menyimpan level **per langkah** (bukan per siswa secara global), sehingga siswa yang sudah mahir menghitung tetapi lemah dalam satuan hanya mendapat bantuan pada langkah satuan.
- `HintPolicy` membuka petunjuk tingkat 1 → 4 dan mencatat tingkat tertinggi yang dipakai per soal.

---

## 5. Model Data Lokal (Drift/SQLite)

```
students(id PK, nickname, grade, class_code, avatar_vehicle, consent_research BOOL, created_at)
district_progress(student_id FK, district_id, status[locked|open|done], best_score, completed_at)
step_levels(student_id FK, step[read|known|unit|compute|check], level 1..3, updated_at)
attempts(id PK, student_id FK, problem_id, template_id, seed, context[practice|district_quiz|pretest|posttest|game],
         indicator[reasoning|formulating|employing|interpreting], level, score, max_score,
         started_at, finished_at, mental_effort 1..9 NULL)
attempt_steps(attempt_id FK, step_no, answer_json, correct BOOL, points, error_code, hint_level_used, duration_ms)
game_sessions(id PK, student_id FK, game_id, tier, stars, correct, wrong, duration_ms, played_at)
rewards(student_id FK, coins, unlocked_vehicles_json, badges_json)
events(id PK, student_id FK, type, payload_json, created_at, synced BOOL)
```

Skema JSON lengkap untuk setiap entitas ada di [api.md](api.md).

---

## 6. Alur Data Utama

### 6.1 Mengerjakan Soal
```
ProblemSessionController
   │ 1. ContentRepository.loadTemplate(id)
   │ 2. ProblemGenerator.generate(template, level, seed) ─► Problem
   │ 3. UI menampilkan langkah ①..⑤ sesuai AdaptivePath
   │ 4. Siswa menjawab langkah n
   │ 5. Scorer.checkStep(problem, n, answer) ─► StepResult(correct, points, errorCode)
   │ 6. ErrorDiagnoser ─► umpan balik spesifik
   │ 7. AnalyticsRepository.log(StepAnswered)
   │ 8. Setelah ⑤: Scorer.total, AdaptivePath.update, RewardController.grant
   └ 9. ProgressRepository.saveAttempt
```

### 6.2 Sinkronisasi (v1.1)
```
events (synced=false) ──► SyncService (WorkManager, saat online & Wi-Fi/izin)
                          └─ POST /v1/sync/batch ─► server ─► 200 ─► tandai synced=true
```
Konflik tidak mungkin terjadi karena data siswa hanya bertambah (*append-only*); server mendeduplikasi berdasarkan `event.id` (UUID).

---

## 7. Arsitektur Game (Flame)

- Setiap game adalah `FlameGame` terpisah yang dibungkus `GameWidget`.
- Logika soal di game **memakai Domain yang sama** (Unit Engine, Problem Generator, Motion Simulator). Game tidak boleh memiliki rumus sendiri.
- *Overlay* Flutter dipakai untuk pertanyaan, umpan balik, dan jeda, agar teks tetap tajam dan dapat diakses.
- Komponen umum: `VehicleComponent` (sprite + kecepatan), `RoadComponent` (jalan bergulir), `ParallaxCityBackground`.
- Siklus: `loading → briefing → playing ⇄ paused/feedback → result`.

---

## 8. Kinerja

| Teknik | Tujuan |
|---|---|
| *Sprite atlas* tunggal per game | Mengurangi *draw call* |
| Rive daripada GIF/video | Ukuran kecil, tajam di semua resolusi |
| Dekorasi peta dimatikan saat masuk Mode Fokus | Hemat CPU dan baterai |
| Pemantau fps; beralih otomatis ke mode Hemat jika < 30 fps selama 5 detik | Perangkat rendah |
| Konten dimuat malas (*lazy*) per distrik | Waktu buka ≤ 3 detik |
| Gambar WebP; audio OGG | APK ≤ 60 MB |

---

## 9. Keamanan dan Privasi
- Data lokal di SQLite pada penyimpanan internal aplikasi (tidak dapat diakses aplikasi lain).
- Mode Guru dilindungi PIN 4–6 digit (disimpan sebagai *hash*).
- Ekspor CSV hanya berisi nama panggilan dan ID acak; tidak ada data lokasi atau kontak.
- Sinkronisasi (v1.1): HTTPS, token per perangkat, ID siswa berupa UUID, tanpa nama asli di server.
- Tanpa SDK iklan atau pelacak pihak ketiga.

---

## 10. Pengujian

| Lapisan | Jenis | Cakupan minimum |
|---|---|---|
| Domain | Unit test | 90%: semua konversi, generator, scorer, diagnoser, simulator |
| Konten | Validasi skema (`tool/validate_content.dart`) dijalankan di CI | Semua JSON lolos; setiap templat menghasilkan 100 instansi valid |
| Widget | Widget test + golden | Alat bantu, alur 5 langkah |
| Integrasi | `integration_test` | Pretest → distrik → kuis → posttest |
| Kinerja | Profiling di perangkat RAM 2 GB | ≥ 30 fps di game dan peta |
| Pengguna | Uji keterbacaan dan uji coba kelompok kecil | Lihat [task.md](task.md) |

---

## 11. Build dan Distribusi
- `flutter build apk --release --split-per-abi` (APK lebih kecil per arsitektur).
- Distribusi untuk uji coba: berkas APK langsung atau Google Play *internal testing*.
- Versi Web (`flutter build web`) sebagai cadangan untuk siswa tanpa Android.
- CI: GitHub Actions menjalankan `flutter analyze`, `flutter test`, `dart run tool/validate_content.dart`.
