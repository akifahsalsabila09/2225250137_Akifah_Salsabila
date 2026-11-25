# KotaLaju: Kode Aplikasi (Flutter)

Implementasi aplikasi sesuai [../prd.md](../prd.md), [../design.md](../design.md), dan [../architecture.md](../architecture.md).

## Menjalankan

1. Pasang **Flutter SDK** (stable) dari https://docs.flutter.dev/get-started/install/windows, lalu jalankan `flutter doctor`.
2. Untuk Android: pasang **Android Studio** (beserta Android SDK), lalu buat emulator atau sambungkan HP dengan *USB debugging* aktif.
3. Dari folder ini:

```bash
flutter pub get
flutter test                 # 38 test: domain (30) + smoke test layar (8)
flutter run                  # jalankan di HP/emulator
flutter run -d chrome        # atau coba langsung di browser
flutter build apk --release --split-per-abi   # buat APK
```

APK hasil build ada di `build/app/outputs/flutter-apk/`.

## Isi Aplikasi

| Fitur | Lokasi kode |
|---|---|
| Onboarding, persetujuan data | `lib/features/onboarding/` |
| Peta Kota (Mode Kota, kendaraan lalu-lalang) | `lib/features/city_map/` |
| 6 distrik materi + animasi instruksional | `lib/features/lesson/`, `lib/core/data/content.dart` |
| Alur 5 Langkah, petunjuk bertingkat, fading adaptif | `lib/features/problem/problem_session.dart` |
| Tes Awal / Ujian Kota (pretest–posttest, 24 poin) | `lib/features/quiz/test_screen.dart` |
| Stasiun Kuis (kuis distrik, latihan campur, riwayat) | `lib/features/quiz/quiz_hub.dart` |
| 5 game | `lib/features/games/` |
| Garasi (kendaraan, cat, lencana, radar ML) | `lib/features/garage/` |
| Mode Guru (PIN), ekspor CSV | `lib/features/teacher/`, `lib/core/data/csv_export.dart` |
| Mesin satuan, simulator gerak, bank soal, penilai | `lib/core/domain/` (Dart murni, teruji) |

## Perbedaan dari Dokumen Rancangan (versi MVP)

| Rancangan | Implementasi sekarang | Alasan |
|---|---|---|
| Rive/Lottie untuk animasi | Animasi digambar dengan `CustomPainter` | Tidak perlu berkas aset .riv. Gerak kendaraan memakai `MotionSimulator` yang sama dengan kunci jawaban |
| Flame untuk game | Widget Flutter + `Ticker`/`AnimationController` | Mengurangi dependensi. Game tetap memakai domain yang sama |
| Riverpod + go_router | `ChangeNotifier` + `InheritedNotifier` + `Navigator` | Lebih sederhana untuk MVP |
| Drift (SQLite) | `shared_preferences` (JSON) | Tanpa *code generation*. Model data tetap sesuai architecture.md §5 |
| Templat soal JSON | Templat soal dalam Dart (`problem_bank.dart`) | Aman tipe, tanpa parser ekspresi. Rubrik 6 poin divalidasi oleh test |
| Font Baloo 2 / Nunito, suara, narasi | Font bawaan, tanpa audio | Belum ada berkas aset |
| Mode gelap | Belum | Tahap berikutnya |
| Sinkronisasi server (v1.1) | Belum (sesuai rencana) | Lihat api.md §4 |

## Paket 7 Soal (dipakai di seluruh aplikasi)

Didefinisikan di `lib/core/domain/soal_tetap.dart`. Latihan materi, checkpoint, kuis, Tes Awal, dan Ujian Kota hanya memakai soal-soal ini.

| No | Soal | Indikator | Sumber | Jawaban |
|---|---|---|---|---|
| 1 | Memilih Rute Bersepeda (Dina, 6 km, 12 vs 15 km/jam, batas 25 menit) | Reasoning | Kisi-kisi | Rute B (24 menit) |
| 2 | Perjalanan Menuju Museum (150 km, 50 km/jam) | Formulating | Kisi-kisi | 3 jam |
| 3 | Perjalanan Bersepeda Andi (4 km @ 8 + 6 km @ 12 km/jam) | Employing | Kisi-kisi | 1 jam; 10 km/jam |
| 4 | Memeriksa Waktu Perjalanan Bus (Budi, 120 km, 40 km/jam) | Interpreting | Kisi-kisi | 3 jam, bukan 20 menit |
| 5 | Kecepatan Sepeda Rani (6 km dalam 30 menit) | Employing | Tambahan | 12 km/jam |
| 6 | Jarak Perjalanan Ayah (60 km/jam selama 90 menit) | Employing | Tambahan | 90 km |
| 7 | Waktu Tempuh Truk Sayur (90 km, 60 km/jam) | Formulating | Tambahan | 1,5 jam |

**Tes Awal dan Ujian Kota** memakai soal 1–4 (skor maksimal 24). Angka dan konteks soal kisi-kisi sama persis. Kalimatnya dipecah menjadi kalimat pendek (≤ 15 kata) sesuai prinsip Cognitive Load.

| Distrik | Soal |
|---|---|
| Bundaran JKW | 7 (contoh), 2 (setengah jadi), checkpoint 2 & 7 |
| Bengkel Satuan | 5 (contoh), 6 (setengah jadi), checkpoint 5 & 6 |
| Jalan Raya Cerita | 4 (contoh), 1 (setengah jadi), checkpoint 1 & 4 |
| Halte Transit | 3 (setengah jadi), latihan ulang semua soal, checkpoint 3 |

Distrik Simpang Berpapasan dan Jalur Susul diganti Halte Transit karena tidak ada soal berpapasan/menyusul di paket ini. Animasinya masih ada di kode (`animations.dart`) bila nanti dibutuhkan.

## Pembangkit Soal (cadangan)

| Templat | Indikator ML | Kesalahan yang didiagnosis |
|---|---|---|
| `waktu_tempuh` | Formulating (level 3: ada info tak relevan) | rumus terbalik |
| `kecepatan`, `jarak` | Employing (level 2+: waktu dalam menit) | satuan belum diubah, basis 100, arah konversi |
| `pilih_rute` | Reasoning (soal Dina) | satuan, rumus terbalik |
| `tepat_waktu` | Reasoning | jam vs lama perjalanan |
| `dua_tahap` | Employing (soal Andi) | rata-rata dua kecepatan |
| `periksa_hitungan` | Interpreting (soal Budi / kesalahan satuan) | rumus terbalik, satuan |
| `berpapasan` | Formulating | kecepatan gabungan, jam vs durasi |
| `menyusul` | Employing | jarak awal diabaikan, selisih kecepatan |

Setiap templat diuji: 100 instansi per level, rubrik = 6 poin, kalimat ≤ 15 kata, dan info tak relevan hanya muncul di level 3 Formulating.
