# Status

## Selesai & diverifikasi end-to-end

### Backend (core-api)

Migrasi `000001`–`000009` (timezone Asia/Jakarta, inventaris alat/obat, dan pengayaan Fase terbaru: foto dokter/pasien, `staff_skills`, `billing.expenses`, promo diskon, odontogram photo). Endpoint per domain:

- **identity**: `/patients` (GET paginated — search + family linking via `primaryAccountUserId` — /POST/PUT/DELETE), `/patients/:id/stats`, `/patients/:id/odontogram-timeline`, `/users` (CRUD paginated, staf non-dokter), `/roles`, `PUT /auth/me`, `POST /auth/change-password`
- **scheduling**: `/branches` (read only), `/doctors` (read, aktif saja) + `/doctors/admin` (paginated, termasuk nonaktif + `bio`/`commissionRate`/`skills`) + `/doctors/:id` (detail) + `/doctors/:id/stats` + POST/PUT/DELETE (CRUD lengkap: cabang, jadwal mingguan, skill), `/reservations` (GET paginated dengan filter `branchId`/`status`/`from`/`to`/`patientId`; POST untuk buat baru), `/reservations/:id/status` (PATCH)
- **billing**: `/treatments` + `/treatment-categories` (CRUD penuh + `/treatments/stats`), `/payments` (GET paginated dengan filter `patientId`, POST mendukung `promoId`/`discountAmount`, otomatis akumulasi `loyalty_points`), `/payments/:id/invoice`, `/inventory` (CRUD paginated), `/expenses` (CRUD biaya operasional), `/admin/dashboard*` (KPI + 4 agregat chart), `/admin/reports/*` (summary, revenue-trend, by-payment-method, commission-by-doctor, profit-report)
- **clinical**: `/medical-records` (GET paginated list/detail, POST create — append-only, odontogram + foto progres + pemakaian alat/obat)
- **content (CMS)**: `/content/article-categories`, `/content/articles`, `/content/promos` (+ `discountType`/`discountValue`), `/content/testimonials`, `/content/videos`, `/content/notification-templates` + `/content/notification-logs` + kirim broadcast (simulasi) — semua CRUD penuh, sengaja tanpa pagination (katalog kecil, dipakai bersama publik/mobile)
- **auth**: `POST /auth/login` (rate-limited 10/menit), `GET /auth/me`

**Pagination server-side backward-compatible**: paket `internal/platform/pagination` — hanya aktif kalau query `page`/`pageSize` dikirim; tanpa parameter itu tetap mengembalikan array polos (mobile app tidak perlu berubah). Diterapkan di Pasien/Dokter/Reservasi/Pembayaran/Inventaris/User.

**Keamanan**: `apperr.Internal` (generic 500 + log server-side, tidak lagi membocorkan pesan error DB mentah), rate limiting login, `helmet.New()`, CORS allowlist (`ALLOWED_ORIGINS`). Diaudit: semua query pakai parameter binding pgx (tidak ada raw value diinterpolasi ke SQL), nol `v-html` di frontend.

Semua endpoint data di atas (di luar `/auth/*`) **belum ada RBAC** — publik sementara sampai proteksi per-role dibangun di Fase 1. Login sendiri sudah nyata dan admin panel sudah mengunci semua halaman di belakang login (`middleware/auth.global.ts`).

### Admin panel (Nuxt 3)

**14 halaman semuanya fungsional** (tidak ada lagi "coming soon"). Chart di seluruh panel pakai `vue-echarts`/`echarts` lewat wrapper `components/charts/EChart.vue` (menggantikan chart SVG/HTML manual dari round sebelumnya). Beberapa halaman kini memakai pola **master-detail** (tabel/list di kiri, panel ringkas persisten di kanan) mengikuti referensi visual yang diminta user, bukan lagi modal/slideover-on-click:

- **Dashboard** — 6 KPI tile + chart ECharts (tren revenue, status reservasi, revenue per cabang, top treatment), 2 tabel data terbaru
- **Reservasi & Antrian** — filter (cabang/status/tanggal), toggle List/Kalender, panel ringkas **di kanan** (KPI total/menunggu + chart distribusi status) — dipindah dari full-width di atas tabel
- **Pasien** — CRUD + foto, panel kanan **persisten** (bukan slideover): statistik belanja/kunjungan/loyalty + chart tren 6 bulan, foto progres odontogram sebelum/sesudah, rekam medis/reservasi/pembayaran/promo ringkas
- **Dokter & Jadwal** — CRUD + foto, bio, komisi, skill (radar chart); panel detail slideover berisi `DoctorStats` (revenue, komisi, tren, top treatment)
- **Billing & Transaksi** — kasir POS (dengan pilih promo & auto-hitung diskon), halaman detail transaksi terpisah (`/billing/:id`), panel kanan ringkas (2 KPI + 2 chart kecil: tren revenue, metode pembayaran)
- **Cabang** — list kiri (dikelompokkan Aktif/Nonaktif) + detail kanan 4 tab (Profil, Dokter, Jadwal, Statistik); backend masih read-only (CRUD belum diminta)
- **Perawatan & Harga** — CRUD penuh + panel statistik kanan (booking count/revenue per treatment, top treatment)
- **Rekam Medis** — buat entri (append-only): diagnosis, odontogram + foto, pemakaian alat/obat
- **Inventaris** — CRUD penuh, badge "Stok Menipis"
- **Laporan Keuangan** — 4 tab (Ringkasan, Pembiayaan, Komisi Dokter, Keuntungan), chart ECharts, **export Excel**
- **CMS** — 4 tab, CRUD penuh
- **User & Role** — CRUD penuh, bcrypt
- **Profil** — edit data diri + ganti password (halaman baru, sebelumnya belum berfungsi)
- **Notifikasi & Broadcast** — CRUD template + kirim broadcast (simulasi, log tersimpan) + log pengiriman (halaman baru, sebelumnya "coming soon" — integrasi WA gateway sungguhan masih Fase 2)

Semua halaman list (kecuali 4 tab CMS) pakai **pagination server-side** (`PaginationBar` + `PaginatedResponse<T>`).

**Layout & tema**: sidebar dikelompokkan per section, navbar dinamis + notifikasi real (stok menipis + reservasi hari ini) + color mode, logo gradient. **Login**: split-screen, show/hide password, captcha matematika self-hosted, `POST /auth/login` (JWT cookie 30 hari, akun demo `admin@ninadentalcare.com` / `NinaDental#2026`). **Skeleton loading** di semua panel/list async.

### Mobile (Flutter)

Bukan lagi skeleton "coming soon" — semua layar tersambung ke `core-api` sungguhan:

- **Identitas tanpa auth asli**: "Daftar"/"Lengkapi Profil" membuat baris `identity.patients` (relation `self`) lewat `POST /patients`, `patientId` disimpan di `flutter_secure_storage` sebagai sesi lokal (`SessionController`, Riverpod `AsyncNotifier`) — akan diganti JWT sungguhan begitu `auth` untuk pasien dibangun.
- **Home** — kartu sambutan, carousel promo, artikel & tips, testimoni (semua dari `/content/*`)
- **Cabang**, **Dokter** (+ detail jadwal mingguan), **Daftar Harga** (per kategori + pencarian), **Artikel** (list + detail)
- **Reservasi** — alur booking bertahap (cabang → dokter → jadwal & keluhan → rencana perawatan + estimasi total) lewat `Stepper`, submit ke `POST /reservations`
- **Riwayat Reservasi** & **Riwayat Pembayaran** — difilter ke `patientId` milik sendiri via parameter `patientId` baru di `GET /reservations` dan `GET /payments` (mencegah aplikasi pasien menarik data seluruh pasien lain)
- **Profil** — data diri, logout sesi lokal

Terlokalisasi penuh bahasa Indonesia (`flutter_localizations` + `initializeDateFormatting('id_ID')`, termasuk date/time picker). Diverifikasi: `flutter analyze` bersih, `flutter test` lulus, alur register→booking→riwayat dites lewat curl langsung ke core-api.

**APK release** dibuild dengan `--dart-define=API_BASE_URL=https://nfmtech.my.id/product/klinik/api/v1` (bicara ke backend produksi di VPS): `mobile/build/app/outputs/flutter-apk/app-release.apk` (57.3MB).

### Deployment (VPS produksi)

Stack penuh (`postgres`, `redis`, `core-api`, `payment-service`, `notification-service`, `admin-frontend`) berjalan di VPS bersama (shared dengan project lain milik user — total RAM cuma 3.6GB, ~20 container lain). Override compose baru `docker-compose.vps.yml` (host-port langsung, tanpa Traefik) dengan port yang dipastikan tidak bentrok dengan project lain: `4001` (admin), `8092` (core-api), `8093` (payment-service), `8094` (notification-service), `5435` (postgres), `6381` (redis). Reverse proxy lewat nginx yang sudah ada di VPS (domain `nfmtech.my.id`, pola path-per-produk): `/product/klinik/` → admin-frontend, `/product/klinik/mobile/` → core-api.

- **Live**: https://nfmtech.my.id/product/klinik/ (login admin panel, akun demo `admin@ninadentalcare.com` / `NinaDental#2026`) dan https://nfmtech.my.id/product/klinik/api/v1/ (API — dipakai admin panel & mobile). Path awalnya `/product/klinik/mobile/`, diganti ke `/product/klinik/api/` sesuai VPS.md yang diperbarui user. Flutter Web sengaja **tidak** dibangun/dideploy ke VPS (permintaan eksplisit user) — VPS cuma menjalankan backend + admin panel.
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
14. `EmptyState.vue` dipakai (halaman Pasien) tapi tidak pernah dibuat filenya — baru ketahuan saat verifikasi build/curl redesain layout. Fix: dibuat.
15. `formatDateShort` menambahkan `T00:00:00` ke semua input tanpa cek → `RangeError: Invalid time value` (500 SSR) saat dipanggil dengan timestamp ISO penuh (bukan tanggal saja). Fix: cek `includes('T')` dulu.
16. Panel detail Pasien/Cabang kosong saat SSR karena pola `ref` + `watch(list, {immediate:true})` gagal memilih baris pertama sebelum microtask fetch-nya selesai. Fix: ganti ke `computed` yang menurunkan pilihan langsung dari data list saat render (dengan override manual untuk klik user).

## Belum

- RBAC per-role di setiap endpoint data (saat ini semua endpoint di luar `/auth/*` masih publik meski login admin panel sudah nyata). Refresh-token rotation & expiry policy juga belum ada (token JWT tunggal, cookie 30 hari tetap).
- Auth pasien (register/login dengan password) untuk mobile — saat ini "sesi" mobile cuma `patientId` tersimpan lokal tanpa password, lihat bagian Mobile di atas.
- Notifikasi & Broadcast — kirim broadcast masih simulasi (log ditulis langsung, belum ada integrasi WA gateway pihak ketiga sungguhan).
- Cabang — masih read-only (CRUD belum diminta, hanya layout yang diredesain).
- Upload file asli (foto/gambar/video) — masih pakai URL manual, keputusan object storage ditunda ke saat benar-benar dibutuhkan.
- Flutter Web build untuk `https://nfmtech.my.id/product/klinik/ninadental` — disebut sebagai rencana publish tapi belum diminta eksplisit/belum dikerjakan.
- Build iOS (IPA) belum diverifikasi di mesin ini (butuh Xcode+CocoaPods lengkap).
- Mobile app belum disesuaikan dengan pengayaan backend terbaru (foto dokter/pasien, promo, dll) dan belum di-rebuild APK-nya sejak round ini — pending berikutnya.

## Langkah selanjutnya (urutan disarankan)

1. Update mobile app (Flutter) menyesuaikan endpoint/fitur baru dari round pengayaan ini, pastikan tidak ada yang error, rebuild APK
2. Implementasi auth pasien (`POST /api/v1/auth/register`, `/login` khusus pasien) + RBAC middleware penuh untuk seluruh endpoint data
3. CRUD untuk Cabang (saat ini read-only)
4. Integrasi WA gateway pihak ketiga sungguhan untuk modul Notifikasi & Broadcast
5. Pertimbangkan object storage (lihat docs/architecture.md §2) begitu upload file benar-benar dibutuhkan (mis. foto rontgen)
6. Flutter Web build + deploy ke `/product/klinik/ninadental` kalau memang dibutuhkan
