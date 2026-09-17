# Panduan Penggunaan Sistem Nina Dental Care

Dokumen ini adalah panduan lengkap untuk menggunakan seluruh platform digital Nina Dental Care, yang terdiri dari **Aplikasi Mobile (Pasien)** dan **Admin Panel (Staf/Klinik)**.

---

## 📱 1. Panduan Aplikasi Mobile (Untuk Pasien)

Aplikasi mobile dirancang khusus untuk mempermudah pasien dalam mengakses layanan klinik secara digital.

### A. Fitur Utama
1. **Pemesanan Jadwal (Reservasi):** Pasien dapat memilih jadwal kunjungan, memilih dokter (seperti drg. Nina Marlina, drg. Friski, dll.), serta melihat ketersediaan slot waktu secara *real-time*.
2. **Rekam Medis & Odontogram:** Riwayat perawatan gigi pasien serta kondisi Odontogram (peta gigi) dapat dipantau langsung.
3. **Transformasi Senyum (Smile Transformation):** Pasien pengguna behel (ortodonti) atau veneer dapat melihat progres perbandingan foto gigi mereka dari awal (Bulan ke-0), selama perawatan, hingga hasil akhir yang rapi.
4. **Artikel & Promo:** Informasi kesehatan gigi dan promo khusus dari klinik.
5. **Membership & Poin Loyalitas:** Pasien bisa mengumpulkan poin setiap transaksi dan melihat tingkat membership mereka (Reguler, Silver, Gold, Platinum).

### B. Pengaturan Akun & Tema (Baru!)
- **Ubah Tema & Font:** Pasien sekarang dapat memodifikasi tampilan aplikasinya. Buka menu **Profil -> Pengaturan Tema & Tampilan**. Di sini, pasien dapat memilih warna dominan aplikasi (Biru, Pink, Emerald, Ungu), mengubah font aplikasi (Inter, Outfit, Poppins, Roboto), serta mengaktifkan **Mode Gelap (Dark Mode)**.
- **Keluar / Logout:** Untuk keluar dari aplikasi, tombol **Logout** telah dipindahkan ke **bagian paling bawah** pada layar Profil Pasien (berwarna merah) agar tidak mudah tidak sengaja tertekan.

---

## 💻 2. Panduan Admin Panel (Untuk Staf & Manajemen)

Admin Panel berjalan di antarmuka Web (`/product/klinik/`) dan digunakan untuk operasional harian.

### A. Dashboard Utama
- **Ringkasan Operasional:** Menampilkan statistik real-time seperti total pasien aktif hari ini, total revenue, tingkat kehadiran, dan antrean.
- Dasbor ini dilengkapi dengan animasi dan tampilan yang lebih modern (*premium glassmorphism*) untuk menonjolkan fitur *real-time monitoring*.

### B. Manajemen Pasien & Membership (Baru!)
- Buka menu **Pasien** dari navigasi utama.
- Anda dapat menambahkan atau mengedit data pasien (termasuk NIK, Pekerjaan, dan Kontak Darurat).
- **Pengaturan Membership:** Staf kini dapat mengatur **Level Membership** pasien ke opsi (Reguler, Silver, Gold, Platinum). Badge membership akan langsung tampil di kolom tabel.
- **Poin Pasien:** Tombol *Point (koin kuning)* digunakan untuk menambahkan atau mengurangi saldo poin kunjungan pasien.

### C. Manajemen Reservasi & Jadwal
- Buka menu **Reservasi** untuk melihat seluruh daftar antrean pasien.
- Ubah status dari "Menunggu" menjadi "Sedang Ditangani" ketika pasien masuk ke ruang tindakan.
- Ubah menjadi "Selesai" jika tindakan selesai, ini akan memungkinkan staf untuk memproses pembayaran (Billing).

### D. Billing, Kasir & Rekonsiliasi (POS)
- Saat pembayaran dilakukan, klik **Proses Bayar** di kolom Billing.
- Masukkan rincian tagihan (tindakan yang diberikan) serta diskon/promo jika ada.
- Setelah sukses, staf dapat langsung mencetak struk dengan menekan tombol **Cetak Struk / Invoice**.
  > **Penting**: Cetak Struk sekarang dirancang untuk langsung membuka *Tab Baru* (Pop-up), sehingga kasir tidak akan kehilangan layar halaman tabel billing.

### E. Entri Transformasi Senyum (Before & After)
- Pada menu **Pasien**, klik nama pasien yang sedang dirawat.
- Pada panel samping kanan, gulir ke bawah ke bagian "Transformasi Gambar Gigi".
- Klik **+ Entri Baru** dan unggah foto pasien:
  1. **Sebelum:** Foto awal sebelum dirawat (Misal: Gigi Gingsul).
  2. **Proses:** Foto saat sedang proses perawatan (Misal: Memakai Behel).
  3. **Sesudah:** Foto ketika perawatan berhasil dan gigi rapi.
- Catat progres ini dan sistem akan secara otomatis merapikannya di aplikasi pasien (agar pasien juga bisa melihat progres mereka).

---

## ⚙️ 3. Panduan Teknis & Troubleshooting

### A. Cetak Billing Gagal (Link Rusak)
- **Sudah diperbaiki!** Aplikasi secara otomatis akan melampirkan prefix `/product/klinik/billing/.../invoice` jika di-deploy di VPS *production*. Jangan membuka link melalui Nuxt `navigateTo` jika ada *reverse proxy* Nginx; sistem ini telah dirancang menggunakan `window.open` untuk kompatibilitas proxy terbaik.

### B. Aplikasi Mobile Tidak Menampilkan Font / Blank Putih
- Pastikan koneksi internet ponsel menyala pada pemuatan pertama, karena font utama seperti *Outfit* atau *Inter* diambil menggunakan mekanisme `google_fonts` dari sistem operasi. Setelah di-cache, font akan bisa dijalankan *offline*.

### C. Cara Cek Pembaruan Mobile (Update)
- Pada halaman Profil Mobile, pengguna bisa mengklik **Cek Update**. Aplikasi akan mengecek versi terbaru dari server dan mengunduh APK/Bundle *patch* jika tersedia secara *seamless*.
