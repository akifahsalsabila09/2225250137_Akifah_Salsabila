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

## Bank Soal

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
