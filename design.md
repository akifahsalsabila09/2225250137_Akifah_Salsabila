# Design Document — KotaLaju

Dokumen ini menjelaskan desain pembelajaran, desain visual, animasi, dan alur layar. Kebutuhan fitur ada di [prd.md](prd.md); implementasi teknis ada di [architecture.md](architecture.md).

---

## 1. Konsep Besar: "Kota yang Bergerak"

Siswa berperan sebagai **pengemudi baru di KotaLaju**, sebuah kota kartun yang ramai. Setiap distrik kota adalah satu topik. Siswa "mendapatkan SIM" per distrik dengan menyelesaikan checkpoint, membuka jalan menuju distrik berikutnya, dan mengoleksi kendaraan di Garasi.

Metafora ini dipilih karena:
- Jarak, kecepatan, dan waktu **memang terjadi di jalan**, sehingga tema tidak sekadar hiasan, tetapi juga menjadi representasi konsepnya.
- Semua soal kontekstual (bus sekolah, ojek, kurir, kereta) cocok dengan kisi-kisi Mathematical Literacy yang menuntut situasi nyata.

### Dua "mode" visual

| Mode | Di mana | Karakter visual |
|---|---|---|
| **Mode Kota** (meriah) | Peta kota, Garasi, Arena Game, layar perayaan | Animasi kendaraan lalu-lalang, lampu lalu lintas berkedip, awan bergerak, efek suara, *confetti* |
| **Mode Fokus** (tenang) | Layar materi, langkah soal, kuis | Latar polos terang, hanya diagram jalan yang relevan, tanpa elemen dekoratif yang bergerak, tanpa musik latar |

Ini adalah cara mendamaikan "animasi semenarik mungkin" dengan prinsip CLT: kemenarikan memotivasi siswa untuk masuk, tetapi tidak boleh mengganggu saat siswa sedang berpikir.

---

## 2. Desain Pembelajaran

### 2.1 Struktur Distrik (urutan wajib per modul)

```
┌──────────────┐  ┌─────────────────┐  ┌──────────────────┐  ┌────────────┐  ┌────────────┐
│ 1. Animasi   │→ │ 2. Contoh       │→ │ 3. Contoh        │→ │ 4. Latihan │→ │ 5. Check-  │
│    Pembuka   │  │    Terselesaikan│  │    Setengah Jadi │  │    Mandiri │  │    point   │
│ (cerita +    │  │ (semua langkah  │  │ (siswa mengisi   │  │ (3–5 soal, │  │ (3 soal,   │
│  konsep)     │  │  ditunjukkan)   │  │  1–2 langkah)    │  │  petunjuk) │  │  dapat SIM)│
└──────────────┘  └─────────────────┘  └──────────────────┘  └────────────┘  └────────────┘
```

### 2.2 Urutan Distrik (jalur belajar)

```
         [Terminal Awal: Pretest + Diagnostik]
                        │
          skor prasyarat < 4/6 ? ──ya──► [🕐 Menara Jam]
                        │                       │
                        ▼                       │
                [🔺 Bundaran JKW] ◄─────────────┘
                        │
                        ▼
                [🔧 Bengkel Satuan] ──► membuka G1 Rally Satuan, G4 Pilih Rute Kurir*
                        │
                        ▼
              [🛣️ Jalan Raya Cerita] ──► membuka G5 Detektif Lalu Lintas
                        │
              ┌─────────┴─────────┐
              ▼                   ▼
   [🚦 Simpang Berpapasan]   [🏁 Jalur Susul]
     → G2 Tebak Titik Temu     → G3 Kejar Bus Terakhir
              └─────────┬─────────┘
                        ▼
             [🏛️ Balai Kota: Ujian Kota / Posttest]
```
\* G4 sudah terbuka sejak Bundaran JKW untuk soal satuan seragam, lalu memakai satuan campuran setelah Bengkel Satuan.

### 2.3 Rincian Isi Tiap Distrik

#### 🕐 Menara Jam (prasyarat, IL03)
- Jam analog besar yang jarumnya dapat diputar; durasi tampil sebagai busur berwarna hijau.
- Visual "pizza jam": 1 jam = lingkaran, 15 menit = ¼ potong, 45 menit = ¾.
- Selisih waktu: 07.00 → 07.30 = 30 menit (Garis Waktu).
- Pecahan ↔ desimal: ¼ = 0,25; ½ = 0,5; ¾ = 0,75.

#### 🔺 Bundaran JKW (K02, GL01)
- Animasi pembuka: mobil melaju 60 km/jam. Setiap 1 jam muncul penanda "60 km" di jalan, sehingga siswa *melihat* bahwa jarak = kecepatan × waktu.
- Segitiga JKW interaktif: J di atas, K dan W di bawah. Mengetuk satu huruf akan "menutup" huruf itu dan menampilkan rumusnya. Setiap rumus disertai satu kalimat makna:
  - J = K × W → "Tiap jam menempuh K km, selama W jam."
  - K = J ÷ W → "Berapa km yang ditempuh dalam 1 jam?"
  - W = J ÷ K → "Berapa kali K km masuk ke dalam J km?"
- Langkah Cek Logika diperkenalkan di sini: "Kecepatan naik → waktu turun."

#### 🔧 Bengkel Satuan (IL01, IL05, EL04, DS01, DS02)
- **Tangga Satuan**: visual tangga km → hm → dam → m dengan animasi "turun tangga = ×10".
- **Roda Waktu**: jam ↔ menit ↔ detik dengan roda gigi (1 putaran besar = 60 putaran kecil).
- **Konversi km/jam → m/detik** dipecah menjadi 3 langkah terpisah, satu layar per langkah:
  1. Ubah km → m (×1000)
  2. Ubah jam → detik (×3600)
  3. Bagi keduanya
  
  Langkah tidak boleh dicoret-coret/digabung sekaligus (menjawab EL04).
- **Aturan arah konversi** dengan visual: "Satuan besar → kecil: angka jadi BANYAK (kali). Satuan kecil → besar: angka jadi SEDIKIT (bagi)." Contoh: 2 jam → menit, angka membesar menjadi 120.
- Kalkulator Satuan muncul di sini.

#### 🛣️ Jalan Raya Cerita (K03, EL01, EL02, EL03, EL05, GL03, GL04)
- Latihan **Penanda Info** pada soal cerita.
- Latihan **Kamus Jalan**: "waktu tempuh" = lama perjalanan; "berpapasan" = bertemu dari arah berlawanan; "menyusul" = mengejar dari belakang ke arah yang sama.
- Latihan **Sketsa Jalan**.
- Latihan **Coret Info Tak Perlu** (level 2–3): "motor berwarna merah" dapat dicoret.

#### 🚦 Simpang Berpapasan (IL04)
- Simulasi: Kota A di kiri, Kota B di kanan, jarak 180 km. Mobil A 50 km/jam, bus B 40 km/jam.
- **Visual kunci**: pita jarak di antara keduanya menyusut. Setiap 1 jam berlalu, pita berkurang 50 + 40 = **90 km**. Teks: "Jarak di antara mereka berkurang 90 km setiap jam." Dengan begitu kecepatan gabungan dipahami sebagai *laju menyusutnya jarak*, bukan aturan hafalan.
- Siswa dapat menggeser *slider* waktu untuk menggerakkan simulasi maju-mundur.

#### 🏁 Jalur Susul (IL04, IL05)
- Garis Waktu dua jalur: A berangkat 07.00, B berangkat 07.30.
- Animasi: A sudah berada 30 km di depan saat B mulai bergerak (jarak awal = kecepatan A × selisih waktu).
- Pita jarak menyusut sebesar *selisih* kecepatan per jam.
- Kesalahan umum yang dibahas: lupa bahwa A sudah berjalan lebih dahulu.

### 2.4 Alur 5 Langkah dan Fading

| Langkah | Level 1 (Pemula) | Level 2 (Lancar) | Level 3 (Jago) |
|---|---|---|---|
| ① Baca & Tandai | Penanda Info wajib, contoh pewarnaan diberikan | Penanda Info wajib | Opsional |
| ② Diketahui–Ditanya | Formulir dengan kolom terisi sebagian | Formulir kosong | Digabung dengan ③ |
| ③ Samakan Satuan | Kalkulator Satuan penuh (langkah ditampilkan) | Kalkulator hanya mengecek jawaban siswa | Tanpa kalkulator |
| ④ Hitung | Segitiga JKW ditampilkan | Segitiga dapat dibuka jika perlu | Tidak ditampilkan |
| ⑤ Cek Logika | Pilihan ganda alasan | Pilihan ganda alasan | Isian singkat alasan |

Naik level secara adaptif: 3 soal benar berturut-turut tanpa petunjuk tingkat 3 atau 4 → naik level. Dua soal salah berturut-turut di langkah yang sama → turun satu level untuk langkah itu saja.

### 2.5 Umpan Balik

- **Segera, spesifik, dan per langkah.** Contoh: "Hampir! Kamu membagi 45 dengan 100. Satu jam itu 60 menit, bukan 100. Coba lagi."
- **Diagnosis kesalahan** (ditampilkan dengan ikon):
  - 🔧 Salah satuan
  - 🔁 Rumus terbalik (contoh Budi: 40 ÷ 120)
  - 📖 Salah baca soal (siapa berangkat duluan, apa yang ditanya)
  - ➗ Salah hitung
- Benar → animasi singkat kendaraan melaju (≤ 1,5 detik), lalu lanjut atas ketukan siswa.

### 2.6 Desain Soal (Bank Soal)

Aturan penulisan soal (berlaku untuk semua penulis konten):
1. Kalimat ≤ 15 kata. Satu informasi per kalimat.
2. Angka disajikan sebagai angka ("45 menit", bukan "empat puluh lima menit").
3. Setiap soal cerita **wajib** memiliki diagram jalan (DS03).
4. Level 1–2: tanpa informasi tak relevan. Level 3: maksimal 1 informasi tak relevan, dan hanya pada soal dengan indikator Formulating.
5. Konteks lokal dan beragam: angkot, ojek daring, kereta komuter, bus kota (tanpa nama merek), sepeda, jalan kaki ke sekolah, kurir paket.
6. Format jam Indonesia: 07.30 (titik).
7. Angka dibuat "ramah" untuk level 1 (hasil bilangan bulat), dan memakai pecahan/desimal di level 2–3.

Contoh soal per indikator (dikembangkan dari kisi-kisi):

| Indikator | Contoh soal aplikasi |
|---|---|
| Reasoning | "Sinta naik ojek ke les, jaraknya 9 km. Rute Tol Kota: 36 km/jam. Rute Pasar: 27 km/jam. Les mulai 20 menit lagi. Rute mana yang dipilih? Jelaskan." |
| Formulating | "Bus wisata berwarna biru membawa 40 siswa ke museum. Jarak 150 km. Kecepatan 50 km/jam. Berapa lama perjalanannya?" (Level 3: siswa mencoret "warna biru" dan "40 siswa") |
| Employing | "Kurir mengantar paket 4 km dengan 8 km/jam, lalu 6 km dengan 12 km/jam. Berapa total waktu dan kecepatan rata-ratanya?" |
| Interpreting | "Budi menghitung waktu bus: 40 ÷ 120 = 0,33 jam ≈ 20 menit, untuk jarak 120 km dan kecepatan 40 km/jam. Setujukah kamu?" |

---

## 3. Desain Visual

### 3.1 Gaya Ilustrasi
- **Flat-isometric kartun** dengan sudut membulat; garis tepi tebal 2–3 px berwarna gelap lembut.
- Kendaraan dibuat *chubby* (proporsi lucu) agar akrab untuk remaja awal, tetapi tidak terlalu kekanak-kanakan.
- Kota bergaya Indonesia: ruko, warung, halte, masjid, pohon trembesi, zebra cross, angkot.

### 3.2 Palet Warna

| Token | Warna | Hex | Penggunaan |
|---|---|---|---|
| `jarak` | Biru jalan | `#2F80ED` | Semua angka/label jarak |
| `kecepatan` | Oranye speedometer | `#F2994A` | Semua angka/label kecepatan |
| `waktu` | Hijau lampu | `#27AE60` | Durasi |
| `jam` | Ungu senja | `#9B51E0` | Jam keberangkatan/kedatangan |
| `primary` | Kuning taksi | `#F2C94C` | Tombol utama, sorotan |
| `aspal` | Abu aspal | `#4F4F4F` | Jalan, teks utama |
| `latar-fokus` | Krem lembut | `#FFFBF2` | Latar Mode Fokus |
| `salah` | Merah rem | `#EB5757` | Umpan balik salah (selalu disertai ikon) |
| `benar` | Hijau lampu | `#27AE60` + ikon ✓ | Umpan balik benar |

Warna besaran (`jarak`, `kecepatan`, `waktu`, `jam`) **dipakai konsisten di seluruh aplikasi**: di soal, diagram, segitiga JKW, Penanda Info, dan rumus. Dengan begitu warna menjadi isyarat (*signaling*) yang menghubungkan teks dan gambar. Karena tidak semua siswa dapat membedakan warna, setiap besaran juga punya ikon: 📏 jarak, 🚗 kecepatan, ⏱ waktu, 🕐 jam.

Mode gelap disediakan dengan versi warna yang lebih terang (kontras ≥ 4,5:1).

### 3.3 Tipografi
- Judul: **Baloo 2** (bulat, ramah), 22–28 sp.
- Isi dan soal: **Nunito**, 16–18 sp, jarak baris 1,5.
- Angka dalam soal: Nunito Bold berwarna sesuai besarannya.
- Rumus: tampil besar (≥ 20 sp), operasi ditulis dengan × dan ÷ (bukan * atau /).

### 3.4 Ikon dan Karakter
- **Pak Lampu**: maskot lampu lalu lintas yang menjadi pemandu. Muncul hanya di animasi pembuka dan perayaan, **tidak muncul** di layar soal (menghindari *seductive detail*).
- Ikon besaran konsisten (lihat §3.2).

---

## 4. Desain Animasi

### 4.1 Kategori Animasi

| Kategori | Tujuan | Boleh di Mode Fokus? | Contoh |
|---|---|---|---|
| **Instruksional** | Menjelaskan konsep | ✅ Ya, dan dikontrol siswa | Pita jarak menyusut, penanda km per jam, roda waktu |
| **Umpan balik** | Mengonfirmasi benar/salah | ✅ Ya, singkat ≤ 1,5 detik | Mobil melaju (benar), mobil mengerem lembut (salah) |
| **Transisi** | Orientasi perpindahan layar | ✅ Halus ≤ 300 ms | Geser jalan ke kanan |
| **Dekoratif / suasana** | Motivasi dan suasana kota | ❌ Tidak | Awan, burung, mobil lalu-lalang, lampu kota |
| **Perayaan** | Hadiah | ❌ Hanya setelah soal selesai | *Confetti*, SIM baru, kendaraan baru keluar garasi |

### 4.2 Aturan Animasi Instruksional
1. Selalu ada kontrol: ▶︎ putar, ⏸ jeda, ⏭ langkah berikutnya, ↺ ulangi, 🐢 0,5×.
2. Animasi berhenti di setiap "momen kunci" dan menunggu ketukan siswa (misalnya saat 1 jam berlalu).
3. Teks label muncul **di dekat** objek yang dijelaskan, dengan warna besaran.
4. Durasi satu segmen ≤ 20 detik; satu animasi pembuka ≤ 45 detik.
5. Kendaraan di simulasi bergerak **sesuai skala** angka di soal (kendaraan 2× lebih cepat benar-benar tampak 2× lebih cepat). Hal ini penting agar animasi tidak menanamkan intuisi yang keliru.

### 4.3 Animasi Kunci yang Harus Dibuat

| ID | Nama | Deskripsi |
|---|---|---|
| A01 | Mobil dan Penanda Jam | Mobil melaju; setiap 1 jam muncul tiang penanda "+60 km" |
| A02 | Segitiga JKW | Segitiga memantul; huruf yang diketuk tertutup oleh "telapak tangan" dan rumus muncul |
| A03 | Tangga Satuan | Angka turun tangga dan bertambah nol |
| A04 | Roda Waktu | Roda gigi jam dan menit berputar sinkron |
| A05 | Konversi km/jam → m/detik | Tiga panel bertahap |
| A06 | Pita Jarak Berpapasan | Dua kendaraan saling mendekat; pita jarak menyusut; penghitung "−90 km/jam" |
| A07 | Garis Waktu Susul | Dua jalur waktu; kendaraan A start lebih dulu |
| A08 | Pizza Jam | Lingkaran jam dipotong ¼, ½, ¾ |
| A09 | SIM Baru | Kartu SIM keluar dan berputar (perayaan) |
| A10 | Garasi Buka | Pintu garasi terangkat, kendaraan baru keluar (perayaan) |
| A11 | Peta Kota Hidup | Kendaraan *ambient* di peta, lampu lalu lintas berganti |

Animasi karakter dan UI (A02, A09, A10, Pak Lampu) dibuat dengan **Rive** (ukuran kecil, interaktif, mendukung *state machine*). Simulasi berbasis angka (A01, A06, A07) di-*render* secara prosedural dengan **Flame/CustomPainter** agar posisi kendaraan tepat sesuai perhitungan.

### 4.4 Mode Grafis
- **Penuh**: semua animasi dekoratif aktif.
- **Hemat** (otomatis jika fps < 30 atau RAM ≤ 2 GB): animasi dekoratif peta dikurangi, partikel dimatikan. Animasi instruksional **tidak** dikurangi.
- Mengikuti pengaturan sistem "Kurangi gerakan" (*reduce motion*).

### 4.5 Suara
- Efek suara: klakson pendek (benar), bel sepeda (petunjuk), mesin *vroom* (naik level).
- Musik latar ringan hanya di Mode Kota; otomatis mati di Mode Fokus.
- Narasi opsional pada animasi pembuka. Jika narasi aktif, teks di layar diringkas menjadi kata kunci (menghindari *redundancy*).

---

## 5. Wireframe Layar Utama

### 5.1 Peta Kota (Beranda)
```
┌─────────────────────────────────────┐
│ 🪙 120   🏅 4      KotaLaju     ⚙️  │
├─────────────────────────────────────┤
│   ☁️          ☁️                    │
│      [🕐 Menara Jam ✓]              │
│            ║                        │
│   🚗→  [🔺 Bundaran JKW ✓]          │
│            ║                        │
│      [🔧 Bengkel Satuan ▶]  ← kini  │
│            ║  (jalan berkabut)      │
│      [🛣️ Jalan Raya Cerita 🔒]      │
│        ╱        ╲                   │
│  [🚦 Simpang🔒] [🏁 Susul🔒]        │
│            ║                        │
│      [🏛️ Balai Kota 🔒]             │
├─────────────────────────────────────┤
│  🗺️ Peta   🎮 Arena   📝 Kuis  🚘 Garasi │
└─────────────────────────────────────┘
```

### 5.2 Layar Soal, Langkah ① Baca & Tandai (Mode Fokus)
```
┌─────────────────────────────────────┐
│ ←  Soal 2/5        ①●②○③○④○⑤○   💡 │
├─────────────────────────────────────┤
│  ════A🚗══════════════════🚌B════   │
│      ◄──────── 180 km ────────►     │
│                                     │
│  Mobil A berangkat pukul [07.00].   │
│  Kecepatannya [50 km/jam].          │
│  Bus B berangkat pukul [07.00].     │
│  Kecepatannya [40 km/jam].          │
│  Jarak kedua kota [180 km].         │
│  Pukul berapa mereka [berpapasan]?  │
│                         └─ ketuk 📘 │
│                                     │
│  Ketuk angka, lalu pilih jenisnya:  │
│  [📏 Jarak][🚗 Kecepatan][⏱ Lama][🕐 Jam] │
│                                     │
│               [ Lanjut → ]          │
└─────────────────────────────────────┘
```

### 5.3 Langkah ③ Samakan Satuan
```
┌─────────────────────────────────────┐
│  ③ Samakan Satuan                    │
│                                     │
│  🚗 60 km/jam   ⏱ 45 menit          │
│        ↑ jam        ↑ menit  ⚠️ beda │
│                                     │
│  Ubah 45 menit ke jam:              │
│  45 ÷ [ 60 ] = [ 0,75 ] jam         │
│                                     │
│  ◔◔◔○  (pizza jam: ¾)               │
│                                     │
│  🔧 Buka Bengkel Satuan              │
│               [ Periksa ]           │
└─────────────────────────────────────┘
```

### 5.4 Arena Game
```
┌─────────────────────────────────────┐
│  🎮 Arena Kota                       │
│  ┌─────────┐ ┌─────────┐            │
│  │🏎 Rally │ │🚩 Tebak │            │
│  │ Satuan  │ │ Titik   │            │
│  │ ★★☆     │ │ Temu 🔒 │            │
│  └─────────┘ └─────────┘            │
│  ┌─────────┐ ┌─────────┐ ┌────────┐ │
│  │🚌 Kejar │ │📦 Rute  │ │🔍 Detek│ │
│  │ Bus  🔒 │ │ Kurir   │ │ tif 🔒 │ │
│  └─────────┘ └─────────┘ └────────┘ │
└─────────────────────────────────────┘
```

---

## 6. Desain Game

### G1 Rally Satuan
- **Tampilan**: jalan tiga lajur dari sudut pandang belakang; mobil siswa di bawah.
- **Alur**: pertanyaan muncul di papan reklame ("90 menit = … jam"); tiga gerbang di depan berisi pilihan. Siswa berpindah lajur dengan menggeser.
- **Benar**: *boost* nitro + koin. **Salah**: mobil melambat, papan reklame menampilkan langkah konversi selama 3 detik (atau sampai diketuk).
- **Tingkat**: Pemula (menit ↔ jam bulat), Lancar (pecahan/desimal), Jago (km/jam ↔ m/detik).
- **Kecepatan jalan** di level Pemula pelan dan konstan; tidak ada *game over* mendadak.

### G2 Tebak Titik Temu
- **Tampilan**: jalan lurus horizontal dengan dua kota; dua kendaraan siap berangkat.
- **Alur**: siswa menyeret bendera ke titik perkiraan dan mengisi jam bertemu → tekan "Jalan!" → simulasi berjalan → kendaraan bertemu → bandingkan dengan bendera siswa.
- **Skor**: berdasarkan ketepatan perhitungan (bukan perkiraan visual semata); siswa diminta menunjukkan perhitungan untuk bintang ke-3.

### G3 Kejar Bus Terakhir
- **Tampilan**: jalan dengan beberapa halte; bus berangkat lebih dahulu.
- **Alur**: siswa memilih kecepatan motor (*slider*) dan memprediksi di halte mana motor menyusul → simulasi dijalankan.
- **Reasoning**: "Berapa kecepatan minimum agar tersusul sebelum halte terakhir?"

### G4 Pilih Rute Kurir
- **Tampilan**: peta kota mini dari atas, 2–3 rute berwarna dengan label jarak dan kecepatan rata-rata (macet/lancar).
- **Alur**: pilih rute → pilih alasan dari kartu ("waktunya 24 menit < 25 menit") → kurir berjalan di rute → tepat waktu atau terlambat.
- Langsung mencerminkan soal kisi-kisi no. 1 (Dina).

### G5 Detektif Lalu Lintas
- **Tampilan**: "laporan perjalanan" berbentuk papan kasus; setiap langkah perhitungan berupa kartu.
- **Alur**: ketuk kartu yang salah → pilih jenis kesalahan (🔧/🔁/📖/➗) → tulis perbaikan.
- Langsung mencerminkan soal kisi-kisi no. 4 (Budi).

---

## 7. Aksesibilitas dan Inklusi
- Ukuran teks dapat diperbesar hingga 130% tanpa merusak tata letak.
- Semua ikon interaktif diberi label untuk pembaca layar (TalkBack).
- Informasi tidak hanya dibedakan dengan warna.
- Opsi "Kurangi gerakan" mematikan animasi dekoratif dan transisi.
- Tidak ada kilatan > 3 kali per detik.

---

## 8. Validasi Desain
Sebelum pengembangan penuh, prototipe (Figma) diuji dengan:
1. **Ahli materi**: kebenaran konsep, kesesuaian soal dengan indikator ML.
2. **Ahli media**: tampilan, animasi, navigasi.
3. **Uji keterbacaan** dengan 3–5 siswa kelas VII–VIII (*think-aloud*): apakah instruksi dipahami, dan apakah ada elemen yang mengganggu.
