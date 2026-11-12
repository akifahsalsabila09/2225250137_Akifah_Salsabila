# Product Requirements Document (PRD)
# KotaLaju — Aplikasi Belajar Jarak, Kecepatan, dan Waktu

| Item | Isi |
|---|---|
| Penyusun | Akifah Salsabila (2225250137), Pendidikan Matematika, Kelas 3F |
| Versi dokumen | 1.0 (12 November 2026) |
| Platform | Android (prioritas), dapat dibangun juga untuk Web |
| Sasaran pengguna | Siswa SMP kelas VII (materi Perbandingan: Kecepatan, Jarak, Waktu) |
| Kemampuan yang ditingkatkan | Mathematical Literacy (literasi matematis) |
| Landasan desain | Cognitive Load Theory (CLT): intrinsic, extraneous, germane load |
| Tema visual | Kendaraan dan perkotaan, dengan animasi |

---

## 1. Latar Belakang

Materi kecepatan, jarak, dan waktu biasanya diajarkan dengan segitiga JKW di papan tulis, lalu siswa mengerjakan soal LKS. Wawancara kebutuhan dengan siswa S01 (kelas 8, sudah mempelajari materi ini di kelas 7, wawancara 35 menit pada 5 November 2026) menunjukkan bahwa siswa **sudah hafal rumus**, tetapi kesulitan muncul pada:

1. **Konversi satuan** (menit ↔ jam, km/jam ↔ m/detik). Inilah kesulitan terbesar (IL01, IL05, EL04).
2. **Soal cerita panjang** yang mencampur jam keberangkatan dan lama perjalanan (K03, EL05).
3. **Soal berpapasan dan menyusul**, karena kecepatan harus dijumlahkan atau dikurangkan (IL04).
4. **Bahasa soal yang kaku** dan **informasi tidak relevan** (EL01, EL03).
5. **Buku yang hanya berisi teks** tanpa gambar jalan atau arah gerak (EL02, DS03).

Hal yang terbukti membantu siswa: segitiga JKW (GL01), menggambar jalan sebelum menghitung (GL03), menulis *Diketahui–Ditanya* (GL04), mengecek kewajaran jawaban (GL02), dan memastikan satuan sudah sama sebelum menghitung (GL05).

Masalah-masalah di atas berkaitan langsung dengan empat komponen Mathematical Literacy: memodelkan situasi (*Formulating*), menerapkan prosedur (*Employing*), menafsirkan hasil (*Interpreting*), dan bernalar (*Reasoning*). KotaLaju dirancang untuk menurunkan beban kognitif yang tidak perlu dan mengarahkan usaha mental siswa ke pembentukan pemahaman.

> **Catatan keterbatasan.** Temuan berasal dari **satu informan** dengan pedoman wawancara yang belum tervalidasi empiris. Keputusan desain di bawah ini bersifat hipotesis awal dan perlu diuji pada tahap evaluasi (uji ahli, uji kelompok kecil, uji lapangan).

---

## 2. Tujuan Produk

| Kode | Tujuan | Ukuran keberhasilan |
|---|---|---|
| T1 | Meningkatkan Mathematical Literacy siswa pada materi JKW | Rata-rata skor *posttest* > *pretest*; N-gain ≥ 0,3 (kategori sedang) |
| T2 | Mengurangi kesalahan konversi satuan | Proporsi jawaban salah karena satuan turun ≥ 50% dari pretest ke posttest |
| T3 | Siswa mampu memodelkan soal berpapasan dan menyusul | ≥ 70% siswa menjawab benar soal berpapasan/menyusul di posttest |
| T4 | Beban kognitif terkelola | Rata-rata skor usaha mental (skala Paas 1–9) pada soal setara menurun seiring level |
| T5 | Aplikasi menarik dan mudah dipakai | Skor SUS ≥ 70; angket kemenarikan ≥ kategori "baik" |

---

## 3. Persona Pengguna

**P1. Raka, siswa kelas VII (pengguna utama).** Hafal segitiga JKW tetapi sering lupa apakah menit harus dibagi atau dikali 60. Cepat bosan membaca paragraf panjang. Suka kendaraan dan game di HP. Memakai HP Android kelas menengah ke bawah dengan kuota terbatas.

**P2. Bu Sari, guru matematika (pengguna sekunder).** Ingin tahu siswa mana yang masih salah konversi satuan, dan ingin memakai aplikasi sebagai tugas rumah atau pengayaan di kelas.

**P3. Peneliti (Akifah).** Membutuhkan data pretest/posttest, skor per indikator literasi, dan data beban kognitif untuk analisis.

---

## 4. Ruang Lingkup

### 4.1 Termasuk dalam versi 1.0 (MVP)

1. **Materi** dalam bentuk peta kota interaktif dengan 6 distrik pembelajaran.
2. **Kuis** literasi matematis dengan penskoran per tahapan (mengikuti kisi-kisi ML).
3. **Game**: 5 mini-game bertema kendaraan dan kota.
4. **Diagnostik awal** (pretest) dan **tes akhir** (posttest).
5. **Alat bantu**: Bengkel Satuan (konverter bertahap), Sketsa Jalan, Penanda Info (highlighter).
6. **Sistem petunjuk bertingkat** (*fading hints*).
7. **Garasi** (profil, koleksi kendaraan, lencana).
8. Mode luring penuh (*offline-first*).
9. Ekspor data hasil belajar (CSV) untuk guru/peneliti.

### 4.2 Tidak termasuk dalam versi 1.0

- Dasbor guru daring secara *real-time* (direncanakan di versi 1.1 melalui API sinkronisasi; lihat [api.md](api.md)).
- Fitur obrolan atau papan peringkat global (mendorong kompetisi berlebihan dan menambah distraksi).
- Materi di luar JKW (misalnya debit atau skala).

---

## 5. Pemetaan Temuan Wawancara → Keputusan Desain

Tabel ini menjadi acuan utama. Setiap fitur harus dapat ditelusuri ke minimal satu baris.

| Kode temuan | Temuan | Jenis beban | Keputusan desain (fitur) |
|---|---|---|---|
| K02, GL01 | Siswa terbiasa dan terbantu dengan segitiga JKW | Germane | **Segitiga JKW interaktif**: tutup satu besaran untuk melihat rumusnya, *disertai makna* ("jarak = kecepatan × waktu karena tiap jam menempuh v km"), agar tidak sekadar hafalan |
| K03, EL05 | Bingung membedakan jam keberangkatan dan lama perjalanan dalam paragraf | Extraneous | **Penanda Info**: siswa mewarnai angka sesuai jenisnya (🕐 jam keberangkatan, ⏱ durasi, 📏 jarak, 🚗 kecepatan) + **Garis Waktu** visual |
| IL01, IL05, EL04 | Konversi satuan paling sulit; guru menjelaskan terlalu cepat | Intrinsic + Extraneous | **Bengkel Satuan**: konversi langkah demi langkah dengan animasi, tempo diatur siswa, bisa diulang; disertai *worked example* lalu *fading* |
| IL02, GL05 | Banyak langkah yang harus diingat sekaligus; satuan beda → salah total | Intrinsic | **Alur 5 Langkah** tetap pada setiap soal: ① Baca & Tandai ② Diketahui–Ditanya ③ Samakan Satuan ④ Hitung ⑤ Cek Logika |
| IL03 | Prasyarat: pecahan dan jam (45 menit = ¾ jam) | Intrinsic | **Diagnostik awal** + distrik prasyarat "Menara Jam"; siswa yang lemah diarahkan ke sana terlebih dahulu |
| IL04 | Berpapasan/menyusul membingungkan (kecepatan dijumlah/dikurang) | Intrinsic | **Simulasi Simpang Berpapasan & Jalur Susul**: dua kendaraan bergerak, jarak antar-kendaraan ditampilkan menyusut, kecepatan gabungan divisualisasikan sebagai "jarak yang hilang per jam" |
| IL05 | Salah tangkap siapa yang berangkat duluan | Intrinsic | **Garis Waktu keberangkatan** dan animasi yang menunjukkan kendaraan A sudah bergerak sebelum B |
| EL01 | Istilah kaku: "waktu tempuh masing-masing", "berpapasan pada jarak" | Extraneous | **Kamus Jalan**: istilah bergaris bawah dapat diketuk untuk melihat arti dan gambar mini; kalimat soal disederhanakan |
| EL02, DS03 | Buku hanya berisi teks, tidak ada gambar jalan atau arah panah | Extraneous | **Integrasi teks–visual**: setiap soal cerita disertai diagram jalan; label angka diletakkan *pada* diagram, bukan terpisah (menghindari *split-attention*) |
| EL03 | Informasi tidak relevan ("motor berwarna merah") | Extraneous | Soal level awal **bebas detail tak relevan**. Di level lanjut, informasi tak relevan **sengaja** dimunculkan sebagai latihan *Formulating* ("coret info yang tidak perlu"), bukan sebagai gangguan tersembunyi |
| EL04, DS02 | Butuh tempo sendiri; konversi perlu dijelaskan pelan | Extraneous | Semua animasi materi punya kontrol **putar / jeda / langkah berikutnya / ulangi**; tidak ada auto-advance |
| GL02 | Siswa mengecek kewajaran ("ngebut → waktu lebih singkat") | Germane | **Langkah Cek Logika** wajib: pertanyaan "Apakah masuk akal?" dengan pilihan alasan |
| GL03 | Menggambar jalan membantu memahami soal | Germane | **Sketsa Jalan**: seret kendaraan, titik awal, dan arah ke jalan sebelum menghitung |
| GL04 | Menulis *Diketahui–Ditanya* membuat lebih teliti | Germane | Langkah ② berupa formulir *Diketahui–Ditanya* yang diisi siswa |
| DS01 | Ingin animasi mobil berpapasan dan kalkulator mini konversi | — | Animasi simulasi + **Kalkulator Satuan** di Bengkel Satuan (tersedia penuh di awal, kemudian dibatasi di level lanjut agar siswa tetap berlatih) |
| DS02 | Bagian rumus utama biarkan siswa menghitung sendiri | Germane | Langkah ④ Hitung **tidak** dibantu kalkulator otomatis; hanya diberi umpan balik |

---

## 6. Kebutuhan Fungsional

### 6.1 Onboarding dan Diagnostik

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-01 | Siswa membuat profil lokal: nama panggilan, kelas, kode kelas (opsional), dan memilih kendaraan awal (sepeda/motor/mobil/bus) | Wajib |
| F-02 | Siswa mengerjakan **Pretest** 4 soal ML (1 soal per indikator, maks 24 poin) dan 6 soal prasyarat singkat (pecahan dan jam) | Wajib |
| F-03 | Sistem menentukan jalur belajar: jika skor prasyarat < 4/6, distrik "Menara Jam" dibuka dan disarankan lebih dahulu | Wajib |
| F-04 | Persetujuan pengumpulan data (untuk penelitian) ditampilkan dengan bahasa sederhana; dapat ditolak tanpa mengurangi fungsi aplikasi | Wajib |

### 6.2 Materi (Peta Kota)

Navigasi utama berupa **peta kota** yang dapat digeser. Setiap distrik adalah satu modul. Distrik berikutnya terbuka setelah *checkpoint* distrik sebelumnya selesai (tidak harus nilai sempurna).

| Distrik | Isi | Temuan terkait |
|---|---|---|
| 🕐 **Menara Jam** (prasyarat) | Membaca jam, selisih waktu, menit ↔ jam sebagai pecahan (15' = ¼ jam, 45' = ¾ jam) | IL03 |
| 🔺 **Bundaran JKW** | Makna kecepatan, segitiga JKW interaktif, tiga bentuk rumus | K02, GL01 |
| 🔧 **Bengkel Satuan** | Konversi waktu, jarak, dan kecepatan (km/jam ↔ m/detik) langkah demi langkah | IL01, EL04 |
| 🛣️ **Jalan Raya Cerita** | Membaca soal cerita: Penanda Info, Kamus Jalan, Garis Waktu, Diketahui–Ditanya | K03, EL01, EL05 |
| 🚦 **Simpang Berpapasan** | Dua kendaraan berlawanan arah: kecepatan gabungan, waktu dan titik bertemu | IL04 |
| 🏁 **Jalur Susul** | Kendaraan menyusul: selisih waktu berangkat, jarak awal, selisih kecepatan | IL04, IL05 |

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-10 | Setiap distrik terdiri atas urutan: **Animasi Pembuka** (≤ 45 detik) → **Contoh Terselesaikan** (*worked example*) → **Contoh Setengah Jadi** (*completion problem*) → **Latihan Mandiri** → **Checkpoint** | Wajib |
| F-11 | Setiap animasi memiliki kontrol jeda, langkah, ulangi, dan kecepatan putar (0,5× / 1×) | Wajib |
| F-12 | Teks di setiap layar materi maksimal ±40 kata; selebihnya disajikan visual atau dipecah ke layar berikutnya | Wajib |
| F-13 | Narasi suara opsional (dapat dinyalakan/dimatikan), tidak menggandakan teks yang sama persis di layar (*redundancy*) | Sebaiknya |
| F-14 | Tombol **Ringkasan Distrik**: satu kartu rangkuman yang bisa dibuka kapan saja | Wajib |
| F-15 | Siswa dapat meninjau ulang distrik yang sudah selesai tanpa batas | Wajib |

### 6.3 Alat Bantu Belajar

| ID | Alat | Deskripsi | Prioritas |
|---|---|---|---|
| F-20 | **Penanda Info** | Siswa mengetuk angka/frasa dalam soal lalu memilih jenisnya. Sistem memeriksa, lalu angka terwarnai pindah otomatis ke formulir *Diketahui* | Wajib |
| F-21 | **Sketsa Jalan** | Kanvas jalan lurus; siswa menempatkan kendaraan, titik awal, arah panah, dan label jarak. Sistem memberi umpan balik jika arah atau posisi keliru | Wajib |
| F-22 | **Bengkel Satuan (Kalkulator Satuan)** | Konversi dengan menampilkan langkah ("45 menit ÷ 60 = ¾ jam = 0,75 jam"). Tingkat bantuan: penuh → hanya mengecek → terkunci (di level ujian) | Wajib |
| F-23 | **Kamus Jalan** | *Tooltip* istilah dengan definisi sederhana + ilustrasi mini | Wajib |
| F-24 | **Garis Waktu** | Visual jam keberangkatan dan durasi di sumbu waktu horizontal | Wajib |
| F-25 | **Segitiga JKW** | Widget yang bisa diketuk: tutup J/K/W untuk menampilkan rumusnya | Wajib |

### 6.4 Alur Penyelesaian Soal (5 Langkah)

Setiap soal cerita (di latihan, checkpoint, dan kuis) menggunakan alur tetap agar siswa membangun skema yang stabil:

```
① Baca & Tandai → ② Diketahui–Ditanya → ③ Samakan Satuan → ④ Hitung → ⑤ Cek Logika
```

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-30 | Pada level awal, kelima langkah ditampilkan terpisah (satu layar per langkah) | Wajib |
| F-31 | Pada level menengah, langkah ① dan ② digabung; pada level lanjut, siswa mengisi jawaban akhir dan hanya diminta menjelaskan alasan (*fading*) | Wajib |
| F-32 | Langkah ⑤ meminta siswa memilih atau menulis alasan kewajaran jawaban | Wajib |
| F-33 | Jawaban numerik diperiksa bersama satuannya (misal "0,75 jam" dan "45 menit" sama-sama diterima jika ditanya waktu tanpa satuan tertentu) | Wajib |

### 6.5 Sistem Petunjuk Bertingkat

| Tingkat | Bentuk | Contoh |
|---|---|---|
| 1 | Pertanyaan pemantik | "Siapa yang berangkat lebih dulu?" |
| 2 | Petunjuk visual | "Coba gambar jalan lurus, A dari kiri, B dari kanan" (membuka Sketsa Jalan) |
| 3 | Langkah berikutnya | "Ubah 45 menit ke jam dulu: 45 ÷ 60 = …" |
| 4 | Contoh sejenis terselesaikan | Menampilkan *worked example* dengan angka berbeda |

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-40 | Petunjuk dibuka satu per satu atas permintaan siswa | Wajib |
| F-41 | Setelah 2 kali salah pada langkah yang sama, tombol petunjuk berdenyut halus (tidak memaksa) | Sebaiknya |
| F-42 | Penggunaan petunjuk dicatat (untuk analisis), tetapi tidak menghukum skor latihan; di kuis, petunjuk mengurangi skor tahap terkait sesuai rubrik | Wajib |

### 6.6 Kuis (Stasiun Kuis)

Kuis menilai **Mathematical Literacy** dengan rubrik per tahapan seperti kisi-kisi.

| Indikator ML | Bentuk soal di aplikasi | Contoh konteks kota |
|---|---|---|
| **Reasoning** | Membandingkan dua/tiga alternatif dan memilih dengan alasan | Memilih rute ojek agar tiba ≤ 25 menit |
| **Formulating** | Memilih info relevan, menentukan besaran yang dicari, menyusun model | Bus wisata ke museum; ada info tak relevan |
| **Employing** | Perhitungan multi-langkah: waktu total, kecepatan rata-rata | Kurir motor mengantar paket ke 2 lokasi |
| **Interpreting** | Memeriksa jawaban tokoh, menilai kewajaran, memperbaiki | "Budi menghitung 40 ÷ 120…", setuju atau tidak? |

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-50 | Bank soal minimal 40 butir (10 per indikator) dengan 3 tingkat kesulitan | Wajib |
| F-51 | Soal parametrik: angka dibangkitkan ulang dari templat agar siswa tidak menghafal jawaban | Wajib |
| F-52 | Setiap soal dinilai per tahapan (maks 6 poin) sesuai kisi-kisi; skor parsial diberikan jika proses benar tetapi salah hitung | Wajib |
| F-53 | Umpan balik per tahapan setelah soal selesai, termasuk diagnosis jenis kesalahan (salah konversi, rumus terbalik, salah baca soal, salah hitung) | Wajib |
| F-54 | **Kuis Distrik** (5 soal, setelah tiap distrik) dan **Ujian Kota** (posttest, 4 soal ML setara pretest, maks 24 poin) | Wajib |
| F-55 | Setelah setiap soal kuis, muncul satu pertanyaan **usaha mental** (skala 1–9) — dapat dimatikan oleh guru/peneliti | Sebaiknya |
| F-56 | Tidak ada batas waktu ketat di kuis latihan; Ujian Kota boleh memakai batas waktu longgar (opsional) | Wajib |

### 6.7 Game (Arena Kota)

Game dipakai untuk **latihan terdistribusi dan penguatan**, bukan untuk memperkenalkan konsep baru. Game baru terbuka setelah distrik terkaitnya selesai.

| # | Nama game | Mekanik | Konsep / Indikator ML | Dibuka setelah |
|---|---|---|---|---|
| G1 | **Rally Satuan** | Mobil melaju di jalan bergerbang; siswa memilih gerbang berisi konversi yang benar ("90 menit = ? jam"). Benar → *boost*, salah → mobil melambat dan langkah konversi ditunjukkan | Konversi satuan (Employing) | Bengkel Satuan |
| G2 | **Tebak Titik Temu** | Dua kendaraan di jalan; siswa menancapkan bendera di titik yang diperkirakan sebagai tempat bertemu dan memasukkan jamnya. Lalu animasi diputar untuk membuktikan | Berpapasan (Formulating + Interpreting) | Simpang Berpapasan |
| G3 | **Kejar Bus Terakhir** | Siswa mengatur kecepatan motor agar menyusul bus sebelum halte terakhir; simulasi berjalan sesuai nilai yang dipilih | Menyusul (Employing + Reasoning) | Jalur Susul |
| G4 | **Pilih Rute Kurir** | Peta kota mini dengan 2–3 rute (jarak dan kecepatan berbeda) dan batas waktu pengantaran. Pilih rute dan beri alasan | Reasoning | Bundaran JKW |
| G5 | **Detektif Lalu Lintas** | Laporan perjalanan tokoh berisi kesalahan; siswa menemukan langkah yang salah dan memperbaikinya | Interpreting | Jalan Raya Cerita |

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-60 | Setiap game memiliki 3 tingkat (Pemula, Lancar, Jago) | Wajib |
| F-61 | Saat siswa salah di game, permainan berhenti sebentar dan menampilkan penjelasan singkat sebelum lanjut (umpan balik, bukan sekadar "Game Over") | Wajib |
| F-62 | Game tidak memakai batas waktu yang sangat ketat di tingkat Pemula agar beban kognitif tidak bertambah karena tekanan waktu | Wajib |
| F-63 | Hadiah: koin kota, suku cadang untuk mendandani kendaraan di Garasi, dan lencana | Wajib |

### 6.8 Garasi (Profil dan Motivasi)

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-70 | Koleksi kendaraan yang terbuka seiring kemajuan (sepeda → skuter → motor → mobil → bus → kereta) | Wajib |
| F-71 | Kustomisasi warna dan stiker kendaraan memakai koin | Sebaiknya |
| F-72 | Lencana berbasis proses, bukan hanya nilai: "Teliti Satuan" (10 soal tanpa salah satuan), "Pelukis Jalan" (memakai Sketsa Jalan 10 kali), "Detektif" (5 kesalahan ditemukan) | Wajib |
| F-73 | Grafik kemajuan pribadi per indikator ML (radar 4 sumbu) | Wajib |

### 6.9 Guru dan Peneliti

| ID | Kebutuhan | Prioritas |
|---|---|---|
| F-80 | Mode Guru (dilindungi PIN) untuk melihat rekap siswa di perangkat yang sama | Sebaiknya |
| F-81 | Ekspor CSV: skor pretest/posttest per indikator, skor per tahap, jenis kesalahan, penggunaan petunjuk, skor usaha mental, durasi | Wajib |
| F-82 | Sinkronisasi ke server (v1.1) melalui API pada [api.md](api.md) | Nanti |

---

## 7. Kebutuhan Non-Fungsional

| ID | Kategori | Kebutuhan |
|---|---|---|
| NF-01 | Perangkat | Berjalan lancar di Android 8.0+ dengan RAM 2 GB; target 60 fps pada animasi, minimal 30 fps di perangkat rendah |
| NF-02 | Ukuran | APK ≤ 60 MB; tidak perlu unduhan tambahan |
| NF-03 | Luring | Seluruh fitur siswa dapat dipakai tanpa internet |
| NF-04 | Bahasa | Bahasa Indonesia baku yang sederhana, kalimat ≤ 15 kata, sesuai jenjang SMP |
| NF-05 | Aksesibilitas | Kontras warna memenuhi WCAG AA; ukuran sentuh ≥ 48 dp; informasi tidak hanya dibedakan dengan warna (selalu disertai ikon) |
| NF-06 | Privasi | Tidak mengumpulkan data identitas asli tanpa persetujuan; nama cukup nama panggilan; data tersimpan lokal dan terenkripsi saat ekspor/sinkron |
| NF-07 | Keamanan anak | Tanpa iklan, tanpa pembelian dalam aplikasi, tanpa tautan keluar |
| NF-08 | Kinerja | Waktu buka aplikasi ≤ 3 detik; perpindahan layar ≤ 300 ms |
| NF-09 | Audio | Semua suara dapat dimatikan; efek suara pendek dan tidak berulang terus-menerus |

---

## 8. Prinsip Cognitive Load yang Wajib Dipatuhi

Prinsip ini juga berlaku sebagai aturan bagi pengembang (lihat [agents.md](agents.md)).

1. **Menarik di luar soal, tenang di dalam soal.** Animasi meriah, warna cerah, dan efek suara boleh ada di peta kota, Garasi, dan perayaan. Di layar pengerjaan soal, hanya animasi yang menjelaskan konsep yang boleh tampil (*coherence principle*).
2. **Satu ide per layar** (*segmenting*).
3. **Label diletakkan di dalam gambar** (*spatial contiguity*), bukan di keterangan terpisah.
4. **Penanda (*signaling*)**: warna konsisten untuk setiap besaran di seluruh aplikasi: jarak = biru, kecepatan = oranye, waktu = hijau, jam keberangkatan = ungu.
5. **Contoh terselesaikan → setengah jadi → mandiri** (*worked example* dan *fading*).
6. **Tempo diatur siswa** (*learner pacing*); tidak ada animasi materi yang berganti otomatis.
7. **Prasyarat sebelum konsep gabungan** (*pre-training*): konversi satuan dikuasai sebelum soal berpapasan/menyusul.
8. **Bantuan memudar seiring kemahiran** (*expertise reversal*): siswa yang sudah mahir tidak dipaksa melewati langkah rinci.

---

## 9. Metrik dan Evaluasi

| Instrumen | Waktu | Keterangan |
|---|---|---|
| Pretest ML (24 poin) | Awal | 4 soal setara kisi-kisi |
| Posttest ML (24 poin) | Akhir | Soal paralel dengan pretest |
| Skala usaha mental (Paas, 1–9) | Setelah tiap soal kuis | Indikator beban kognitif keseluruhan; perlu diinterpretasikan hati-hati |
| Log interaksi | Sepanjang penggunaan | Jenis kesalahan, petunjuk, durasi, penggunaan alat bantu |
| SUS (System Usability Scale) | Akhir | Kepraktisan |
| Angket kemenarikan | Akhir | Respons siswa |
| Validasi ahli materi dan media | Sebelum uji coba | Kevalidan |

---

## 10. Risiko dan Mitigasi

| Risiko | Mitigasi |
|---|---|
| Animasi terlalu meriah sehingga menambah beban ekstrinsik | Prinsip §8.1; mode "Fokus" yang mematikan dekorasi; uji keterbacaan dengan siswa |
| Siswa hanya menghafal segitiga JKW tanpa makna | Setiap pemakaian segitiga disertai pertanyaan makna dan langkah Cek Logika |
| Siswa mengandalkan Kalkulator Satuan terus-menerus | Bantuan kalkulator memudar per level; terkunci di Ujian Kota |
| Game lebih menarik daripada materi sehingga siswa melewati materi | Game terbuka setelah distrik terkait selesai |
| Temuan wawancara hanya dari 1 siswa | Uji kelompok kecil (5–8 siswa) sebelum uji lapangan; revisi berdasarkan data |
| HP siswa berspesifikasi rendah | Mode grafis "Hemat" (animasi lebih sederhana); uji di perangkat RAM 2 GB |

---

## 11. Rilis

| Versi | Isi |
|---|---|
| 0.1 (Prototipe) | Peta kota, Bundaran JKW, Bengkel Satuan, G1 Rally Satuan |
| 0.5 (Alfa) | Semua distrik, alur 5 langkah, petunjuk bertingkat, kuis distrik |
| 1.0 (Uji coba) | Pretest/posttest, 5 game, Garasi, ekspor CSV |
| 1.1 | Sinkronisasi server dan dasbor guru |

Dokumen terkait: [readme.md](readme.md) · [design.md](design.md) · [architecture.md](architecture.md) · [api.md](api.md) · [task.md](task.md) · [agents.md](agents.md)
