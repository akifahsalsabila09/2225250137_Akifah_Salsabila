# AGENTS.md — Panduan untuk Agen AI dan Pengembang

Berkas ini berisi aturan kerja untuk **agen AI pemrograman** (Claude Code, Copilot, Cursor, dan lain-lain) maupun pengembang manusia yang mengerjakan KotaLaju. Baca berkas ini sebelum mengubah kode atau konten.

KotaLaju adalah **aplikasi pembelajaran**, bukan sekadar game. Setiap keputusan teknis harus melayani tujuan pedagogis: meningkatkan **Mathematical Literacy** siswa SMP kelas VII pada materi jarak, kecepatan, dan waktu, dengan **mengelola beban kognitif** (Cognitive Load Theory).

---

## 1. Dokumen Rujukan (urutan prioritas)

1. [prd.md](prd.md): apa yang dibangun dan mengapa (termasuk matriks temuan wawancara → fitur, §5)
2. [design.md](design.md): desain pembelajaran, visual, animasi, game
3. [architecture.md](architecture.md): struktur kode dan lapisan
4. [api.md](api.md): antarmuka domain, skema konten JSON, REST
5. [task.md](task.md): daftar tugas berikutnya

Jika dokumen saling bertentangan, ikuti urutan di atas dan **laporkan** konfliknya. Jangan diam-diam memilih salah satu.

---

## 2. Perintah Proyek

```bash
flutter pub get                          # pasang dependensi
flutter run                              # jalankan di perangkat/emulator
flutter analyze                          # wajib bersih sebelum selesai
flutter test                             # unit + widget test
flutter test integration_test            # uji integrasi
dart run tool/validate_content.dart      # validasi semua JSON konten
dart run build_runner build --delete-conflicting-outputs   # kode Drift/Riverpod
flutter build apk --release --split-per-abi
```

Sebelum menyatakan tugas selesai: `flutter analyze` bersih, `flutter test` lulus, dan validasi konten lulus (jika konten disentuh).

---

## 3. Aturan Pedagogis (WAJIB, tidak boleh dilanggar)

Aturan ini diturunkan dari wawancara siswa dan prinsip CLT. Kode dalam tanda kurung merujuk ke temuan wawancara di [prd.md](prd.md) §5.

### 3.1 Mode Fokus
- Layar **materi, langkah soal, dan kuis** memakai `FocusScaffold`. Di dalamnya **dilarang**: animasi dekoratif, maskot, musik latar, partikel, dan elemen bergerak yang tidak menjelaskan konsep.
- Animasi meriah hanya boleh ada di peta kota, Garasi, Arena Game (di luar momen menjawab), dan layar perayaan.

### 3.2 Representasi
- Semua besaran **wajib** memakai `Quantity` (nilai + satuan). Jangan pernah menyimpan atau meneruskan angka tanpa satuan di logika domain.
- Warna besaran **wajib** memakai token tema: `AppColors.distance`, `.speed`, `.time`, `.clock`. Jangan menulis kode hex langsung.
- Warna selalu disertai ikon besaran (aksesibilitas).
- Setiap soal cerita **wajib** memiliki diagram jalan (`scene`) (EL02, DS03).
- Label angka diletakkan **pada** diagram, dekat objeknya (*spatial contiguity*).

### 3.3 Tempo dan Segmentasi
- Animasi instruksional **wajib** memakai `AnimationControls` (putar, jeda, langkah, ulangi, lambat). **Dilarang** berpindah otomatis ke segmen berikutnya (EL04).
- Satu layar materi berisi maksimal ±40 kata.
- Konversi km/jam ↔ m/detik selalu ditampilkan sebagai **3 langkah terpisah** (EL04).

### 3.4 Alur Soal
- Soal cerita memakai alur 5 langkah: ① Baca & Tandai → ② Diketahui–Ditanya → ③ Samakan Satuan → ④ Hitung → ⑤ Cek Logika (IL02, GL02, GL04, GL05).
- Fading mengikuti tabel di [design.md](design.md) §2.4. Level ditentukan **per langkah** oleh `AdaptivePath`.
- Langkah ④ Hitung **tidak boleh** dihitungkan otomatis oleh aplikasi; siswa menghitung sendiri (DS02).
- Kalkulator Satuan terkunci pada pretest/posttest.

### 3.5 Umpan Balik
- Umpan balik harus **spesifik pada langkah** dan memakai `ErrorDiagnoser`. Hindari pesan generik "Salah!" jika kesalahannya dapat didiagnosis.
- Nada umpan balik positif dan suportif; tidak mengejek, tidak memakai kata "bodoh", "gagal total", dan sejenisnya.
- Di game, jawaban salah menghentikan permainan sejenak untuk menjelaskan, **bukan** langsung *game over*.

### 3.6 Penilaian
- Rubrik setiap soal berjumlah **6 poin** dan dipetakan ke satu indikator ML: `reasoning`, `formulating`, `employing`, atau `interpreting`.
- Skor parsial memakai *error carried forward*: tahap berikutnya tetap dinilai berdasarkan nilai yang dihasilkan siswa sendiri.
- Penilaian hanya dilakukan di lapisan Domain (`Scorer`). UI dan game tidak boleh menghitung skor sendiri.

### 3.7 Konsistensi Matematika
- Animasi, game, dan kunci jawaban **wajib** memakai `MotionSimulator` dan `UnitEngine` yang sama. Tidak boleh ada rumus duplikat di widget atau game.
- Kendaraan di simulasi bergerak sesuai **skala sebenarnya** dari angka soal.

---

## 4. Aturan Konten (soal, materi, teks UI)

- Bahasa Indonesia baku sederhana; kalimat ≤ 15 kata; satu informasi per kalimat.
- Gunakan "kamu", bukan "Anda".
- Format: desimal dengan koma (0,75), ribuan dengan titik (72.000), jam dengan titik (07.30), operasi dengan × dan ÷.
- Satuan ditulis lengkap di teks siswa: "km/jam", "menit", "m/detik".
- Istilah sulit (berpapasan, menyusul, waktu tempuh, kecepatan rata-rata) diberi penanda `[[istilah]]` agar menjadi tautan Kamus Jalan.
- Informasi tak relevan (*distractor*) hanya boleh muncul di level 3 dan pada indikator `formulating`, dan siswa harus diminta mencoretnya (EL03).
- Konteks: kendaraan dan perkotaan Indonesia; **tanpa merek dagang**, tanpa tokoh nyata.
- Nilai realistis: sepeda 10–20 km/jam, jalan kaki 4–6 km/jam, motor/mobil kota 30–60 km/jam, bus antarkota 40–80 km/jam, kereta 60–120 km/jam.
- Setiap templat baru wajib lolos `validate_content.dart` dan menghasilkan ≥ 100 instansi valid per level.

---

## 5. Aturan Kode

### 5.1 Arsitektur
- Ikuti lapisan di [architecture.md](architecture.md) §2: `features/*` → controller Riverpod → `core/domain` ← `core/data`.
- `core/domain` adalah **Dart murni**: tidak boleh mengimpor `package:flutter`.
- Satu fitur = satu folder di `lib/features/`.
- Game Flame berada di `lib/features/games/<nama>/`; overlay teks memakai widget Flutter.

### 5.2 Gaya
- Ikuti `flutter_lints` / `very_good_analysis`; tanpa peringatan analyzer.
- Penamaan kode dalam Bahasa Inggris; string untuk siswa diletakkan di `l10n/` (Bahasa Indonesia), bukan ditulis langsung di widget.
- Gunakan `final` dan *immutable model* (`freezed` atau kelas `@immutable`).
- Hindari `dynamic`; parsing JSON harus bertipe dan tervalidasi.

### 5.3 Pengujian
- Setiap perubahan di `core/domain` **wajib** disertai unit test.
- Wajib ada test untuk keempat contoh kisi-kisi:
  - Dina (6 km; 12 vs 15 km/jam; batas 25 menit → Rute B, 24 menit)
  - Bus Museum (150 km; 50 km/jam → 3 jam)
  - Andi (4 km @ 8 + 6 km @ 12 → 1 jam, rata-rata 10 km/jam)
  - Budi (120 km; 40 km/jam; jawaban Budi 40 ÷ 120 terdiagnosis `FORMULA_INVERTED`; jawaban benar 3 jam)
- Kesalahan umum siswa dari wawancara wajib punya test diagnosis: 45 menit → 0,45 jam (`UNIT_BASE_100`), 45 menit × 60 (`UNIT_WRONG_DIRECTION`), mengabaikan keberangkatan lebih awal (`HEAD_START_IGNORED`).
- Widget baru di `core/widgets/` wajib punya widget test.

### 5.4 Kinerja
- Target 60 fps; minimal 30 fps di perangkat RAM 2 GB.
- Aset gambar WebP, audio OGG, animasi Rive. Hindari GIF dan video.
- Matikan dekorasi peta saat layar tidak terlihat.

### 5.5 Privasi dan Keamanan Anak
- Dilarang menambah SDK iklan, analitik pihak ketiga, pembelian dalam aplikasi, atau tautan keluar.
- Dilarang mengumpulkan nama lengkap, lokasi, kontak, foto, atau mikrofon.
- Event analitik hanya dikirim jika `consent_research == true`.

---

## 6. Cara Bekerja untuk Agen AI

1. **Ambil tugas dari [task.md](task.md)** dan sebutkan ID-nya (misal `S3-01`).
2. Baca bagian dokumen yang relevan sebelum menulis kode.
3. Buat perubahan sekecil mungkin yang menyelesaikan tugas; jangan merombak berkas yang tidak terkait.
4. Tulis atau perbarui test.
5. Jalankan `flutter analyze`, `flutter test`, dan validasi konten.
6. Tandai tugas `[x]` di [task.md](task.md) jika semua kriteria terpenuhi.
7. Laporkan: apa yang diubah, berkas apa saja, hasil test, dan keputusan yang perlu dikonfirmasi pemilik proyek.

### Kapan harus bertanya dulu (jangan menebak)
- Perubahan yang melanggar salah satu aturan di §3 atau §4.
- Mengubah rubrik penilaian atau bobot skor.
- Mengubah alur pretest/posttest (memengaruhi validitas penelitian).
- Menambah dependensi baru yang besar (> 1 MB) atau yang membutuhkan internet.
- Menghapus fitur yang tercantum di PRD.

### Pesan *commit*
```
<ID tugas>: <ringkasan singkat>

<penjelasan bila perlu>
```
Contoh: `S2-04: tambah diagnosis UNIT_BASE_100 dan HEAD_START_IGNORED`

---

## 7. Daftar Periksa Sebelum Selesai

- [ ] Fitur dapat ditelusuri ke kebutuhan di PRD (F-xx) atau temuan wawancara.
- [ ] Layar soal/materi memakai `FocusScaffold` tanpa dekorasi bergerak.
- [ ] Semua besaran memakai `Quantity` dan token warna besaran.
- [ ] Animasi instruksional dapat dijeda, diulang, dan diperlambat.
- [ ] Teks siswa ≤ 15 kata per kalimat, memakai "kamu", tanpa merek.
- [ ] Umpan balik spesifik per langkah.
- [ ] Test ditulis dan lulus; analyzer bersih.
- [ ] Berjalan luring.
