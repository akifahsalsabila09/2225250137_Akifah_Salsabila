# Task Plan — KotaLaju

Rencana kerja mengikuti model pengembangan **ADDIE** (Analysis → Design → Development → Implementation → Evaluation). Setiap tugas diberi ID agar dapat dirujuk di *commit*, laporan, atau oleh agen AI (lihat [agents.md](agents.md)).

**Legenda**: `[x]` selesai · `[ ]` belum · **P0** wajib MVP · **P1** penting · **P2** tambahan
**Estimasi**: dalam hari kerja (HK), untuk 1 orang pengembang.

---

## Fase 0 — Analysis ✅

| ID | Tugas | Status |
|---|---|---|
| A-01 | Menyusun pedoman wawancara berbasis CLT (K, IL, EL, GL, DS) | [x] |
| A-02 | Wawancara siswa S01 (kelas 8, 35 menit, 5 Nov 2026) | [x] |
| A-03 | Pengodean awal transkrip (IL/EL/GL) | [x] |
| A-04 | Menyusun kisi-kisi soal Mathematical Literacy (4 indikator, 24 poin) | [x] |
| A-05 | Menambah informan wawancara (target 3–5 siswa) untuk memperkuat temuan | [ ] P1 |
| A-06 | Analisis KD/CP Kurikulum Merdeka Fase D terkait perbandingan dan kecepatan | [ ] P0 |

---

## Fase 1 — Design (± 10 HK)

| ID | Tugas | Output | Est. | Prioritas |
|---|---|---|---|---|
| D-01 | Finalisasi PRD dan matriks temuan → fitur | [prd.md](prd.md) | 1 | P0 |
| D-02 | Desain pembelajaran per distrik (tujuan, urutan, contoh) | [design.md](design.md) §2 | 2 | P0 |
| D-03 | Menulis 12 templat soal awal (3 per indikator) beserta rubrik 6 poin | `assets/content/problems/` | 2 | P0 |
| D-04 | Menyusun pretest/posttest paralel dan 6 soal prasyarat | `tests/*.json` | 1 | P0 |
| D-05 | *Style guide* visual: palet besaran, tipografi, ikon | Figma | 1 | P0 |
| D-06 | Wireframe semua layar utama | Figma | 2 | P0 |
| D-07 | Prototipe klik (peta → Bengkel Satuan → alur 5 langkah → G1) | Figma | 1 | P0 |
| D-08 | Storyboard animasi A01–A11 | PDF/Figma | 1 | P1 |
| D-09 | Validasi ahli materi dan ahli media atas desain + instrumen | Lembar validasi | — | P0 |
| D-10 | Uji keterbacaan prototipe dengan 3–5 siswa (*think-aloud*) | Catatan revisi | 1 | P0 |

**Kriteria selesai fase**: validator menyatakan "layak dengan revisi" atau lebih baik; revisi sudah diterapkan.

---

## Fase 2 — Development

### Sprint 1 — Fondasi (± 5 HK)

| ID | Tugas | Est. | Prioritas |
|---|---|---|---|
| S1-01 | Inisialisasi proyek Flutter, struktur folder sesuai [architecture.md](architecture.md) §3 | 0,5 | P0 |
| S1-02 | Pasang dependensi: flame, rive, flutter_riverpod, go_router, drift, shared_preferences | 0,5 | P0 |
| S1-03 | `theme.dart`: token warna besaran, tipografi, mode gelap | 0,5 | P0 |
| S1-04 | Domain: `Unit`, `Quantity`, `Rational`, `UnitEngine.convert/explain` + unit test | 1,5 | P0 |
| S1-05 | Domain: `MotionSimulator` (posisi, berpapasan, menyusul) + unit test | 1 | P0 |
| S1-06 | Skema Drift dan repositori (students, attempts, attempt_steps, events) | 1 | P0 |
| S1-07 | CI: analyze + test + validasi konten | 0,5 | P1 |

### Sprint 2 — Mesin Soal (± 6 HK)

| ID | Tugas | Est. | Prioritas |
|---|---|---|---|
| S2-01 | Model `ProblemTemplate` dan parser JSON + `tool/validate_content.dart` | 1 | P0 |
| S2-02 | `ProblemGenerator` dengan seed, constraint, dan aturan level | 1,5 | P0 |
| S2-03 | `Scorer` per tahap dengan *error carried forward* + unit test dari contoh kisi-kisi (Dina, Bus Museum, Andi, Budi) | 1,5 | P0 |
| S2-04 | `ErrorDiagnoser` untuk 9 kode kesalahan + unit test | 1 | P0 |
| S2-05 | `AdaptivePath` dan `HintPolicy` + unit test | 1 | P0 |

### Sprint 3 — Alat Bantu dan Alur 5 Langkah (± 8 HK)

| ID | Tugas | Est. | Prioritas |
|---|---|---|---|
| S3-01 | Widget **Penanda Info** (ketuk token → pilih jenis → pindah ke Diketahui) | 1,5 | P0 |
| S3-02 | Widget **Diketahui–Ditanya** | 0,5 | P0 |
| S3-03 | Widget **Kalkulator Satuan** dengan 3 mode bantuan (penuh/cek/terkunci) | 1 | P0 |
| S3-04 | Widget **Segitiga JKW** interaktif (Rive A02) | 1 | P0 |
| S3-05 | Widget **Garis Waktu** | 0,5 | P0 |
| S3-06 | Widget **Kamus Jalan** (*tooltip*) | 0,5 | P0 |
| S3-07 | Widget **Sketsa Jalan** (seret kendaraan, arah, label) + pemeriksaan | 1,5 | P0 |
| S3-08 | Layar `ProblemSession`: langkah ①–⑤, fading per level, petunjuk bertingkat, umpan balik | 1,5 | P0 |

### Sprint 4 — Materi dan Peta Kota (± 8 HK)

| ID | Tugas | Est. | Prioritas |
|---|---|---|---|
| S4-01 | Peta kota (Flame): distrik, jalan, status kunci, kendaraan *ambient* (A11) | 2 | P0 |
| S4-02 | Pemutar segmen distrik: animasi → contoh → setengah jadi → latihan → checkpoint | 1,5 | P0 |
| S4-03 | `AnimationControls` (▶︎ ⏸ ⏭ ↺ 🐢) + *checkpoint* animasi | 0,5 | P0 |
| S4-04 | Animasi instruksional A01, A03, A04, A05, A08 | 2 | P0 |
| S4-05 | Simulasi A06 (Pita Jarak Berpapasan) dan A07 (Garis Waktu Susul) memakai `MotionSimulator` | 1,5 | P0 |
| S4-06 | Konten JSON keenam distrik + kartu ringkasan | 1 | P0 |
| S4-07 | Pembungkus Mode Fokus vs Mode Kota | 0,5 | P0 |

### Sprint 5 — Kuis dan Tes (± 4 HK)

| ID | Tugas | Est. | Prioritas |
|---|---|---|---|
| S5-01 | Onboarding: profil, pilih kendaraan, persetujuan data | 1 | P0 |
| S5-02 | Pretest + diagnostik prasyarat → jalur belajar | 1 | P0 |
| S5-03 | Kuis Distrik (5 soal) dan Ujian Kota (posttest) | 1 | P0 |
| S5-04 | Pertanyaan usaha mental (1–9) setelah soal kuis, dapat dimatikan | 0,5 | P1 |
| S5-05 | Layar hasil: skor per tahap, diagnosis kesalahan, radar ML | 0,5 | P0 |
| S5-06 | Tambah bank soal hingga ≥ 40 templat (10 per indikator) | 2 | P0 |

### Sprint 6 — Game (± 10 HK)

| ID | Tugas | Est. | Prioritas |
|---|---|---|---|
| S6-01 | Komponen Flame bersama: `VehicleComponent`, `RoadComponent`, `ParallaxCityBackground` | 1 | P0 |
| S6-02 | **G1 Rally Satuan** (3 tingkat) | 2 | P0 |
| S6-03 | **G2 Tebak Titik Temu** | 2 | P0 |
| S6-04 | **G3 Kejar Bus Terakhir** | 2 | P1 |
| S6-05 | **G4 Pilih Rute Kurir** | 1,5 | P0 |
| S6-06 | **G5 Detektif Lalu Lintas** | 1,5 | P1 |

### Sprint 7 — Garasi, Guru, dan Penyempurnaan (± 6 HK)

| ID | Tugas | Est. | Prioritas |
|---|---|---|---|
| S7-01 | Garasi: koleksi kendaraan, kustomisasi, animasi A09/A10 | 1,5 | P1 |
| S7-02 | Lencana berbasis proses | 0,5 | P1 |
| S7-03 | Mode Guru (PIN) dan ekspor CSV (attempts, steps, summary) | 1,5 | P0 |
| S7-04 | Efek suara, musik Mode Kota, narasi opsional | 1 | P2 |
| S7-05 | Mode grafis Hemat + pemantau fps + dukungan "Kurangi gerakan" | 0,5 | P0 |
| S7-06 | Aksesibilitas: label TalkBack, skala teks 130%, kontras | 0,5 | P0 |
| S7-07 | Profiling di HP RAM 2 GB; optimasi aset; APK ≤ 60 MB | 1 | P0 |

**Kriteria selesai fase**: semua P0 selesai; `flutter test` lulus; cakupan domain ≥ 90%; tidak ada *crash* pada skenario integrasi utama.

---

## Fase 3 — Implementation (Uji Coba)

| ID | Tugas | Keterangan | Prioritas |
|---|---|---|---|
| I-01 | Validasi ahli materi dan ahli media atas produk jadi | Lembar validasi (skala Likert) | P0 |
| I-02 | Revisi berdasarkan validasi | — | P0 |
| I-03 | Uji coba kelompok kecil (6–9 siswa kelas VII) | Kepraktisan, keterbacaan, bug | P0 |
| I-04 | Revisi tahap 2 | — | P0 |
| I-05 | Uji lapangan: pretest → ± 4 pertemuan memakai aplikasi → posttest | Satu kelas (atau kelas eksperimen dan kontrol) | P0 |
| I-06 | Pengisian SUS dan angket kemenarikan | Setelah posttest | P0 |
| I-07 | Wawancara singkat pasca-penggunaan (3 siswa) memakai pedoman yang sama | Bandingkan dengan temuan awal | P1 |

---

## Fase 4 — Evaluation

| ID | Tugas | Metode | Prioritas |
|---|---|---|---|
| E-01 | Kevalidan | Rata-rata skor validator → kategori | P0 |
| E-02 | Kepraktisan | Skor SUS dan angket | P0 |
| E-03 | Keefektifan: Mathematical Literacy | Uji-t berpasangan (atau Wilcoxon), N-gain total dan per indikator | P0 |
| E-04 | Penurunan kesalahan satuan | Proporsi `UNIT_*` pretest vs posttest | P1 |
| E-05 | Tren usaha mental per level | Deskriptif; interpretasi hati-hati karena skala satu butir | P1 |
| E-06 | Analisis penggunaan alat bantu vs skor | Korelasi/deskriptif dari log | P2 |
| E-07 | Menyusun laporan dan rekomendasi pengembangan lanjutan | — | P0 |

---

## Versi 1.1 (setelah penelitian)

| ID | Tugas | Prioritas |
|---|---|---|
| V-01 | Backend sinkronisasi sesuai [api.md](api.md) §4 | P2 |
| V-02 | Dasbor guru web | P2 |
| V-03 | Pembaruan konten tanpa memperbarui APK (`/content/bundle`) | P2 |

---

## Ringkasan Jadwal (perkiraan)

| Minggu | Kegiatan |
|---|---|
| 1–2 | Fase Design + validasi desain |
| 3 | Sprint 1–2 |
| 4–5 | Sprint 3–4 |
| 6 | Sprint 5 |
| 7–8 | Sprint 6 |
| 9 | Sprint 7 + validasi produk |
| 10 | Uji kelompok kecil + revisi |
| 11–12 | Uji lapangan |
| 13 | Analisis dan laporan |
