# Status

## Selesai & diverifikasi end-to-end

### Backend (core-api)

Migrasi `000001`–`000008` (termasuk timezone Asia/Jakarta dan tabel inventaris alat/obat). Endpoint per domain:

- **identity**: `/patients` (GET/POST/PUT/DELETE — termasuk family linking via `primaryAccountUserId`), `/users` (GET/POST/PUT/DELETE untuk staf non-dokter), `/roles`
- **scheduling**: `/branches` (read), `/doctors` (read, aktif saja) + `/doctors/admin` (read, termasuk nonaktif) + `/doctors/:id` (detail) + POST/PUT/DELETE (CRUD lengkap termasuk cabang & jadwal mingguan), `/reservations` (GET dengan filter `branchId`/`status`/`from`/`to`, respons kini menyertakan `patientId`/`branchId`/`staffId`; POST untuk buat baru — `status` opsional di body, default `pending`, dipakai jalur POS untuk langsung `completed`), `/reservations/:id/status` (PATCH), `/reservation-statuses`
- **billing**: `/treatments` (read), `/payments` (GET — respons kini menyertakan `reservationId`/`patientId`, POST untuk transaksi manual/tunai dari office), `/payments/:id/invoice` (data invoice siap cetak), `/inventory` (CRUD alat & obat), `/admin/dashboard*` (KPI + 4 chart), `/admin/reports/*` (summary, revenue-trend, by-payment-method untuk periode custom)
- **clinical**: `/medical-records` (GET list/detail, POST create — append-only, termasuk odontogram & pemakaian alat/obat yang otomatis mengurangi stok dalam satu transaksi)
- **content (CMS)**: `/content/article-categories`, `/content/articles`, `/content/promos`, `/content/testimonials`, `/content/videos` — CRUD penuh

- **auth**: `POST /auth/login` (email+password staf, bcrypt, JWT HS256), `GET /auth/me` (validasi Bearer token)

Semua endpoint data di atas (di luar `/auth/*`) **belum ada RBAC** — publik sementara sampai proteksi per-role dibangun di Fase 1. Login sendiri sudah nyata (bukan lagi stub) dan admin panel sudah mengunci semua halaman di belakang login (`middleware/auth.global.ts`).

### Admin panel (Nuxt 3)

**Semua 12 modul kini punya halaman nyata** (bukan lagi "coming soon" kecuali Notifikasi & Broadcast, yang menunggu integrasi WA gateway):

- **Dashboard** — 6 KPI tile, 3 chart, 2 tabel data terbaru. Diaudit ulang: 100% dinamis dari data, tidak ada nilai hardcode.
- **Reservasi & Antrian** — filter (cabang/status/tanggal), buat reservasi baru (pilih pasien/cabang/dokter/jadwal/perawatan), ubah status inline, **toggle tampilan List/Kalender** (kalender bulan custom, klik tanggal untuk filter list ke tanggal tsb)
- **Pasien** — CRUD penuh, termasuk tambah anggota keluarga (relasi anak/pasangan/dll ke akun utama), **panel detail slideover** saat baris diklik (data pribadi + riwayat reservasi + riwayat pembayaran pasien tsb)
- **Dokter & Jadwal** — CRUD penuh: akun, spesialisasi, cabang praktik (multi-select), jadwal mingguan (hari/cabang/jam, repeatable), nonaktifkan akun, **panel detail slideover** saat baris diklik (statistik, data praktik, jadwal mingguan, reservasi terbaru dokter tsb)
- **Cabang**, **Perawatan & Harga** — read-only (belum diminta CRUD di fase ini)
- **Rekam Medis** — buat entri baru (append-only): diagnosis, catatan tindakan, odontogram (opsional), **pemakaian alat/obat** (mengurangi stok otomatis), lihat detail
- **Inventaris (Alat & Obat)** — modul baru: master data stok, kategori obat/alat, harga satuan, badge "Stok Menipis" saat di bawah batas reorder, CRUD penuh
- **Billing & Rekonsiliasi** — **kasir POS penuh** ("Transaksi Baru (POS)", modal fullscreen): katalog perawatan searchable + filter kategori, keranjang dengan qty stepper, diskon, 4 tombol metode pembayaran cepat (Tunai/QRIS/Transfer/Kartu), kalkulator kembalian otomatis untuk tunai, layar sukses dengan tombol cetak invoice langsung. Plus "Bayar Reservasi" (jalur lama, untuk reservasi yang sudah dibuat lewat app/admin) dan **cetak invoice** (halaman print-friendly terpisah, `/billing/:id/invoice`)
- **Laporan Keuangan** — modul baru: filter periode custom, 4 KPI, tren revenue harian, breakdown per metode pembayaran & per cabang
- **CMS** — modul baru: 4 tab (Artikel + kategori, Promo, Testimoni, Video), CRUD penuh (gambar/video pakai URL, belum ada upload)
- **User & Role** — CRUD penuh untuk staf non-dokter (perawat/admin cabang/finance/superadmin), password di-hash dengan bcrypt

**Layout & tema**: sidebar dikelompokkan per section (Operasional/Klinis/Keuangan/Konten & Marketing/Sistem), navbar dengan judul halaman dinamis + notifikasi + color mode, logo gradient. **Login sudah nyata**: split-screen dengan panel branding (blob gradient + 3 bullet fitur), show/hide password, captcha matematika self-hosted, dan tersambung ke `POST /auth/login` sungguhan (JWT disimpan di cookie 30 hari, akun demo `admin@ninadentalcare.com` / `NinaDental#2026`). Semua halaman admin dikunci di belakang login lewat `middleware/auth.global.ts`; sidebar menampilkan nama & role user yang benar-benar login, tombol "Keluar" menghapus sesi. **Skeleton loading** (`components/skeleton/*`) terpasang di semua menu yang memuat data async (tabel, KPI, chart, kalender) menggantikan tampilan kosong/spinner.

### Mobile (Flutter)

Bukan lagi skeleton "coming soon" — semua layar tersambung ke `core-api` sungguhan:

- **Identitas tanpa auth asli**: "Daftar"/"Lengkapi Profil" membuat baris `identity.patients` (relation `self`) lewat `POST /patients`, `patientId` disimpan di `flutter_secure_storage` sebagai sesi lokal (`SessionController`, Riverpod `AsyncNotifier`) — akan diganti JWT sungguhan begitu `auth` untuk pasien dibangun.
- **Home** — kartu sambutan, carousel promo, artikel & tips, testimoni (semua dari `/content/*`)
- **Cabang**, **Dokter** (+ detail jadwal mingguan), **Daftar Harga** (per kategori + pencarian), **Artikel** (list + detail)
- **Reservasi** — alur booking bertahap (cabang → dokter → jadwal & keluhan → rencana perawatan + estimasi total) lewat `Stepper`, submit ke `POST /reservations`
- **Riwayat Reservasi** & **Riwayat Pembayaran** — difilter ke `patientId` milik sendiri via parameter `patientId` baru di `GET /reservations` dan `GET /payments` (mencegah aplikasi pasien menarik data seluruh pasien lain)
- **Profil** — data diri, logout sesi lokal

Terlokalisasi penuh bahasa Indonesia (`flutter_localizations` + `initializeDateFormatting('id_ID')`, termasuk date/time picker). Diverifikasi: `flutter analyze` bersih, `flutter test` lulus, alur register→booking→riwayat dites lewat curl langsung ke core-api.

**APK release** dibuild dengan `--dart-define=API_BASE_URL=https://nfmtech.my.id/product/klinik/mobile/api/v1` (bicara ke backend produksi di VPS): `mobile/build/app/outputs/flutter-apk/app-release.apk` (57.3MB).

### Deployment (VPS produksi)

Stack penuh (`postgres`, `redis`, `core-api`, `payment-service`, `notification-service`, `admin-frontend`) berjalan di VPS bersama (shared dengan project lain milik user — total RAM cuma 3.6GB, ~20 container lain). Override compose baru `docker-compose.vps.yml` (host-port langsung, tanpa Traefik) dengan port yang dipastikan tidak bentrok dengan project lain: `4001` (admin), `8092` (core-api), `8093` (payment-service), `8094` (notification-service), `5435` (postgres), `6381` (redis). Reverse proxy lewat nginx yang sudah ada di VPS (domain `nfmtech.my.id`, pola path-per-produk): `/product/klinik/` → admin-frontend, `/product/klinik/mobile/` → core-api.

- **Live**: https://nfmtech.my.id/product/klinik/ (login admin panel, akun demo `admin@ninadentalcare.com` / `NinaDental#2026`) dan https://nfmtech.my.id/product/klinik/mobile/api/v1/ (API untuk mobile)
- Repo: https://github.com/nuriyanto16/nfm-klinik-dental.git

### Data dummy

`services/core-api/seed/seed.sql` (idempotent, `make seed`): 2 cabang, 4 dokter, 6 pasien (1 anak/family member), 4 kategori + 13 treatment, 10 reservasi dasar (semua status) + ~40 reservasi & pembayaran historis tambahan tersebar di 30 hari terakhir (untuk chart tren dashboard yang realistis), 8 item inventaris (obat & alat), 3 rekam medis (dengan odontogram & pemakaian item), 3 kategori artikel + 3 artikel, 2 promo, 3 testimoni, 2 video.

### Infra

`service-infra-klinik/` — 6 container sehat (`postgres`, `redis`, `core-api`, `payment-service`, `notification-service`, `admin-frontend`), tanpa MinIO, tanpa Traefik di local, bind mount data Postgres/Redis. `Makefile`: `make up/down/logs/migrate-up/migrate-down/migrate-new/seed`.

Perubahan lengkap & alasannya: lihat [`HISTORY.md`](../HISTORY.md).

## Bug yang ditemukan & diperbaiki selama verifikasi (kumulatif)

1. Admin Dockerfile tanpa `.dockerignore` → `COPY . .` menimpa `node_modules` container. Fix: tambah `.dockerignore`.
2. Postgres default timezone UTC vs klinik WIB → query "hari ini" salah jam 00:00–06:59 WIB. Fix: migrasi `000007_set_timezone`.
3. `seed.sql` tidak menghapus `scheduling.branches` sebelum insert ulang → re-run gagal. Fix: tambah statement DELETE.
4. `CreatePayment`: parameter `$4` dipakai di dua konteks tipe berbeda (kolom enum + perbandingan `CASE WHEN`) → Postgres gagal infer tipe (SQLSTATE 42P08). Fix: cast eksplisit `::billing.payment_status`.
5. `CreatePatient`: query `RETURNING` 10 kolom tapi `Scan` cuma 9 destinasi (kolom `address` terlewat) → error saat menambah anggota keluarga. Fix: sekaligus ketahuan `address` tidak pernah diekspos ke API/frontend sama sekali (form isi tapi tidak pernah tampil balik) — ditambahkan ke `Patient` struct, semua query, dan pre-fill form edit.
6. Seed: indexing array 2D PL/pgSQL (`pairs[i]` pada `uuid[][]`) mengembalikan `NULL`, bukan "baris ke-i" → error not-null constraint saat generate data historis. Fix: ganti jadi dua array 1D paralel.
7. Seed: variabel PL/pgSQL bertipe `text` dimasukkan ke kolom enum tanpa cast → error tipe. Fix: cast eksplisit `::billing.payment_status`.
8. `MonthCalendar.vue`: nama class Tailwind dibentuk lewat template literal → tidak ter-generate oleh JIT scanner (chip status transparan). Fix: peta statis nama class per status.
9. `useApiFetch('/reservations')` dipanggil 2x dengan argumen identik (list & kalender) → cache key `useFetch` bentrok, kedua ref saling menimpa. Fix: parameter `key` opsional di `useApiFetch`.
10. `flutter_local_notifications` butuh core library desugaring di Android Gradle → build APK gagal. Fix: `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs` di `android/app/build.gradle.kts`.
11. Nitro server build admin-frontend crash "JavaScript heap out of memory" di VPS ber-RAM kecil (3.6GB, V8 default heap ceiling ketauan dari total RAM host) → fix `NODE_OPTIONS=--max-old-space-size=3072` di `admin/Dockerfile` + swap tambahan di VPS.
12. Build 4 image docker sekaligus (`--build` paralel) di VPS shared ber-RAM 3.6GB sempat membuat **seluruh VPS OOM & reboot**. Fix: script deploy build satu-per-satu, dijalankan via `setsid nohup ... &disown` supaya tidak mati kalau SSH terputus.
13. Redirect login admin panel kehilangan prefix path setelah di-reverse-proxy ke subpath (`/product/klinik/` → redirect ke `/login` bukan `/product/klinik/login`) → fix `app.baseURL` baru di `nuxt.config.ts`, overridable lewat `NUXT_APP_BASE_URL`. Sempat tidak berefek karena env var itu di-set di `.env` tapi tidak didaftarkan di `environment:` service `admin-frontend` pada `docker-compose.yml` (Compose tidak otomatis meneruskan seluruh isi `.env` ke container).

## Belum

- RBAC per-role di setiap endpoint data (saat ini semua endpoint di luar `/auth/*` masih publik meski login admin panel sudah nyata). Refresh-token rotation & expiry policy juga belum ada (token JWT tunggal, cookie 30 hari tetap).
- Auth pasien (register/login dengan password) untuk mobile — saat ini "sesi" mobile cuma `patientId` tersimpan lokal tanpa password, lihat bagian Mobile di atas.
- Notifikasi & Broadcast — masih "coming soon" (butuh integrasi WA gateway pihak ketiga).
- Cabang & Perawatan/Harga — masih read-only (CRUD belum diminta).
- Upload file asli (foto/gambar/video) — masih pakai URL manual, keputusan object storage ditunda ke saat benar-benar dibutuhkan.
- Flutter Web build untuk `https://nfmtech.my.id/product/klinik/ninadental` — disebut sebagai rencana publish tapi belum diminta eksplisit/belum dikerjakan.
- Build iOS (IPA) belum diverifikasi di mesin ini (butuh Xcode+CocoaPods lengkap).

## Langkah selanjutnya (urutan disarankan)

1. Implementasi auth pasien (`POST /api/v1/auth/register`, `/login` khusus pasien) + RBAC middleware penuh untuk seluruh endpoint data
2. CRUD untuk Cabang & Perawatan/Harga (saat ini read-only)
3. Integrasi WA gateway pihak ketiga untuk modul Notifikasi & Broadcast
4. Pertimbangkan object storage (lihat docs/architecture.md §2) begitu upload file benar-benar dibutuhkan (mis. foto rontgen)
5. Flutter Web build + deploy ke `/product/klinik/ninadental` kalau memang dibutuhkan
