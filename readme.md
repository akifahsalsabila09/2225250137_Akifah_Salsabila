# 🚗 KotaLaju

**Aplikasi Android untuk belajar Jarak, Kecepatan, dan Waktu bagi siswa SMP kelas VII, bertema kendaraan dan perkotaan.**

KotaLaju mengajak siswa menjadi pengemudi baru di sebuah kota kartun. Siswa menjelajahi distrik demi distrik, mempelajari konsep lewat animasi, mengerjakan kuis literasi matematis, dan bermain mini-game, sambil mengoleksi kendaraan di Garasi.

> Dikembangkan oleh **Akifah Salsabila** (NIM 2225250137, Pendidikan Matematika, Kelas 3F) sebagai produk penelitian pengembangan.

---

## ✨ Fitur Utama

| | Fitur | Isi |
|---|---|---|
| 🗺️ | **Materi (Peta Kota)** | 6 distrik: Menara Jam, Bundaran JKW, Bengkel Satuan, Jalan Raya Cerita, Simpang Berpapasan, Jalur Susul |
| 📝 | **Kuis** | Soal Mathematical Literacy (Reasoning, Formulating, Employing, Interpreting), dinilai per tahap dengan skor maksimal 6 per soal |
| 🎮 | **Game (Arena Kota)** | Rally Satuan · Tebak Titik Temu · Kejar Bus Terakhir · Pilih Rute Kurir · Detektif Lalu Lintas |
| 🧰 | **Alat Bantu** | Penanda Info, Sketsa Jalan, Kalkulator Satuan, Kamus Jalan, Garis Waktu, Segitiga JKW |
| 💡 | **Petunjuk Bertingkat** | Pertanyaan pemantik → petunjuk gambar → langkah berikutnya → contoh sejenis |
| 🚘 | **Garasi** | Koleksi kendaraan, lencana, grafik kemampuan literasi |
| 👩‍🏫 | **Mode Guru** | Rekap siswa dan ekspor CSV untuk penelitian |
| 📴 | **Luring** | Semua fitur siswa berjalan tanpa internet |

---

## 🧠 Landasan Pedagogis

### Mengapa aplikasi ini dibuat?
Wawancara dengan siswa yang sudah mempelajari materi ini menunjukkan bahwa **rumus sudah hafal**, tetapi siswa kesulitan dalam:
- **mengubah satuan** (menit ↔ jam, km/jam ↔ m/detik),
- **membaca soal cerita panjang** (jam berangkat dan lama perjalanan tercampur),
- **soal berpapasan dan menyusul**,
- **bahasa soal yang kaku** dan **buku yang hanya berisi teks**.

### Bagaimana aplikasi menanganinya? (Cognitive Load Theory)

| Jenis beban | Strategi di KotaLaju |
|---|---|
| **Intrinsic** (kerumitan materi) | Prasyarat dulu (Menara Jam, Bengkel Satuan), alur 5 langkah tetap, contoh terselesaikan → setengah jadi → mandiri |
| **Extraneous** (beban dari cara penyajian) | Mode Fokus tanpa dekorasi saat mengerjakan soal, label angka langsung di diagram jalan, kalimat pendek, kamus istilah, tempo diatur siswa |
| **Germane** (usaha membangun pemahaman) | Sketsa jalan sebelum menghitung, Diketahui–Ditanya, Cek Logika ("masuk akal?"), mencari kesalahan, variasi konteks |

### Alur 5 Langkah di setiap soal
```
① Baca & Tandai → ② Diketahui–Ditanya → ③ Samakan Satuan → ④ Hitung → ⑤ Cek Logika
```

### Kemampuan yang ditingkatkan: Mathematical Literacy
1. **Reasoning**: membandingkan pilihan dan memberi alasan
2. **Formulating**: mengubah situasi nyata menjadi model matematika
3. **Employing**: menerapkan konsep dan prosedur
4. **Interpreting**: menafsirkan dan menilai kewajaran hasil

---

## 🛠️ Teknologi

Flutter 3 (Dart 3) · Flame (game 2D) · Rive (animasi interaktif) · Riverpod · go_router · Drift/SQLite

Detail lengkap di [architecture.md](architecture.md).

---

## 🚀 Memulai Pengembangan

### Prasyarat
- Flutter SDK 3.x (`flutter doctor` bersih)
- Android Studio atau VS Code + ekstensi Flutter
- Perangkat/emulator Android 8.0+

### Langkah
```bash
git clone <url-repo> kotalaju
cd kotalaju
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

### Perintah penting
```bash
flutter analyze                       # cek kualitas kode
flutter test                          # jalankan test
dart run tool/validate_content.dart   # cek berkas soal dan materi
flutter build apk --release --split-per-abi
```

---

## 📁 Struktur Proyek (ringkas)

```
lib/
  app/          # router, tema, Mode Fokus
  core/domain/  # mesin satuan, simulator gerak, pembangkit soal, penilaian
  core/data/    # SQLite, konten JSON, analitik
  core/widgets/ # alat bantu belajar
  features/     # onboarding, peta kota, materi, kuis, game, garasi, guru
assets/
  content/      # materi & soal (JSON), dapat diedit tanpa mengubah kode
  rive/ images/ audio/
```

---

## ✍️ Menambah Soal

Soal ditulis sebagai **templat JSON** di `assets/content/problems/`. Angka dibangkitkan otomatis sehingga satu templat menghasilkan banyak variasi soal. Format lengkap ada di [api.md §3.2](api.md#32-templat-soal-problemsidjson).

Aturan singkat:
- Kalimat ≤ 15 kata, memakai "kamu".
- Wajib ada diagram jalan (`scene`).
- Rubrik total 6 poin, satu indikator ML.
- Jalankan `dart run tool/validate_content.dart` setelah menambah soal.

---

## 📚 Dokumen Proyek

| Dokumen | Isi |
|---|---|
| [prd.md](prd.md) | Kebutuhan produk, pemetaan temuan wawancara → fitur, metrik |
| [design.md](design.md) | Desain pembelajaran, visual, animasi, game, wireframe |
| [architecture.md](architecture.md) | Arsitektur teknis, struktur folder, model data |
| [api.md](api.md) | Antarmuka domain, skema konten JSON, REST API sinkronisasi |
| [task.md](task.md) | Rencana kerja ADDIE dan sprint |
| [agents.md](agents.md) | Aturan bagi agen AI dan pengembang |

---

## 🔬 Penelitian

| Tahap | Instrumen |
|---|---|
| Kevalidan | Lembar validasi ahli materi dan ahli media |
| Kepraktisan | System Usability Scale (SUS), angket respons siswa |
| Keefektifan | Pretest–posttest Mathematical Literacy (24 poin), N-gain |
| Beban kognitif | Skala usaha mental 1–9 setelah soal kuis, log kesalahan dan petunjuk |

**Keterbatasan**: analisis kebutuhan awal berasal dari satu informan dengan pedoman wawancara yang belum divalidasi empiris. Temuan diperkuat melalui uji keterbacaan dan uji coba kelompok kecil.

---

## 🔒 Privasi

Tanpa iklan, tanpa pembelian dalam aplikasi, dan tanpa pelacak pihak ketiga. Data belajar tersimpan di perangkat. Pengumpulan data untuk penelitian hanya dilakukan dengan persetujuan, dan hanya memakai nama panggilan.

---

## 📄 Lisensi

Untuk keperluan pendidikan dan penelitian. © 2026 Akifah Salsabila.
