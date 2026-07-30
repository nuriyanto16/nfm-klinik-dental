# Implementation Plan — Nina Dental Care: Mobile App + Office/Admin Panel

> Status: Fase 0 (Foundation) scaffolding selesai — lihat [status.md](./status.md)
> untuk apa yang sudah jalan dan apa langkah berikutnya. Dokumen ini adalah
> plan arsitektur yang disetujui dan menjadi acuan sepanjang proyek; update
> bagian yang relevan setiap kali sebuah keputusan berubah.

## 1. Context

Nina Dental Care (IG: @ninadental.ndc, web: ninadentalcare.com) adalah klinik gigi dengan 2 cabang di Kab. Bandung (**Soreang** & **Baleendah**), buka setiap hari 08.00–21.00, dengan layanan utama: scaling/whitening, behel (braces), dental anak (program "Nina Kidz"), gigi palsu. Branding memakai warna biru & putih.

Saat ini klinik belum punya sistem digital untuk reservasi, rekam medis, dan pembayaran — semua kemungkinan masih manual (WA/telepon/kertas). Tujuannya adalah membangun:
1. **Aplikasi mobile pasien** (Flutter, Android+iOS) untuk reservasi, rekam medis pribadi, pembayaran, dan info klinik — dengan acuan UX dari aplikasi FDC Dental Clinic (screenshot di `BAHAN/MOBILE/`), tapi ditingkatkan agar lebih informatif.
2. **Office & Admin Panel** (Go + Nuxt/Vue + PostgreSQL) untuk staf klinik mengelola reservasi, rekam medis, dokter, jadwal, pembayaran, dan konten.

Riset acuan (screenshot FDC) menunjukkan alur inti: pilih cabang → pilih tanggal & dokter → pilih pasien (akun keluarga) → pilih rencana perawatan → bayar (Xendit: VA/e-wallet/QRIS) → riwayat pembayaran, ditambah profil dengan membership tier, QR check-in, dan notifikasi WA otomatis.

**Keputusan yang sudah dikonfirmasi user:**
- Payment gateway: **Xendit**
- Notifikasi WA: **3rd-party gateway** (Fonnte/Wablas/Qontak — dipilih salah satu saat implementasi, desain harus provider-agnostic)
- Skala sistem: **single-tenant, multi-branch** (khusus Nina Dental Care, 2+ cabang), bukan SaaS multi-tenant

Domain/database dirancang agar tetap bisa di-extend ke multi-tenant di masa depan (pakai `branch_id` konsisten, hindari asumsi hardcode "1 klinik"), tapi tidak perlu tenant-isolation penuh sekarang.

---

## 2. Keputusan Arsitektur Utama

| Layer | Pilihan | Alasan |
|---|---|---|
| Mobile | Flutter 3.x, Dart | Satu codebase Android+iOS, sesuai permintaan |
| Mobile state mgmt | Riverpod + go_router | Testable, type-safe, cocok Clean Architecture |
| Admin frontend | Nuxt 3 (Vue 3, TS, Composition API) | Sesuai permintaan, SSR opsional untuk performa |
| Admin UI kit | Tailwind CSS + Nuxt UI (component lib gratis, modern) | "Template bagus" tanpa vendor lock-in; brand color Nina (biru/putih) di-theme di atasnya |
| Backend | Go (1.22+), framework **Fiber** atau **Echo** | Performa tinggi, konkurensi native cocok untuk notifikasi async & webhook payment |
| Backend arch | Modular monolith (domain-per-package) untuk `core-api` + 2 service satelit | Sesuai instruksi "jangan terlalu banyak dipisah" — hanya pecah yang benar-benar butuh siklus deploy & scaling terpisah (payment, notifikasi) |
| DB | PostgreSQL 16, satu instance, skema per domain (`identity`, `clinical`, `scheduling`, `billing`, `content`) | Satu container database sesuai instruksi, isolasi logis lewat schema bukan lewat container terpisah |
| Cache/Queue ringan | Redis (cache, rate-limit OTP, session blacklist, **pub/sub** event antar service) | Infra pendukung, bukan "service" domain — jadi tidak melanggar batasan jumlah microservice |
| Object storage | Belum diputuskan (foto rontgen, KTP asuransi, foto dokter/klinik) | Fitur ini baru dibutuhkan di Fase 2 (rekam medis) — backend konkret (disk lokal, S3, GCS, atau self-hosted lain) dipilih saat itu, bukan sekarang. Sengaja tidak dipasang lebih awal (sempat pakai MinIO di draf awal, dilepas atas permintaan user) |
| Reverse proxy / TLS | Traefik atau Nginx | Routing 1 domain ke banyak container + otomasi SSL (Let's Encrypt) |
| Orkestrasi | Docker Compose (bukan Kubernetes) | Skala klinik kecil-menengah, sesuai instruksi "cukup container", k8s adalah over-engineering di tahap ini |
| CI/CD | GitHub Actions (build & push image), Fastlane/Codemagic khusus build Flutter APK/IPA | Pipeline standar, terpisah dari runtime compose |

**Jumlah container "domain service" tetap 5** sesuai instruksi: `admin-frontend`, `core-api` (backend), `postgres` (database), `payment-service`, `notification-service`. Container pendukung (`redis`, `traefik`, `migrate`) dihitung sebagai infrastruktur, bukan service bisnis tambahan.

---

## 3. Arsitektur Sistem

```
                                   ┌───────────────────────────┐
                                   │        Traefik/Nginx       │  (TLS, routing, rate-limit)
                                   └──────────────┬─────────────┘
                     ┌────────────────────────────┼───────────────────────────┐
                     │                             │                           │
             ┌───────▼────────┐           ┌────────▼────────┐         ┌────────▼────────┐
             │ admin-frontend  │           │    core-api      │◄───────┤  Flutter Mobile │
             │ (Nuxt 3 SSR)    │──REST────►│  (Go, modular    │  REST  │  App (Android/  │
             │ office & admin  │           │   monolith)      │        │  iOS)           │
             └─────────────────┘           └───┬───────┬──────┘        └─────────────────┘
                                                │       │
                          events (Redis pub/sub)│       │ REST (internal)
                                   ┌─────────────▼┐   ┌──▼──────────────┐
                                   │ payment-      │   │ notification-   │
                                   │ service (Go)  │   │ service (Go)    │
                                   │ - Xendit API  │   │ - WA gateway    │
                                   │ - webhooks    │   │ - Push (FCM)    │
                                   │ - reconciliation │ - Email (SMTP)  │
                                   └───────┬───────┘   └────────┬────────┘
                                           │                    │
                                    ┌──────▼────────────────────▼──────┐
                                    │         PostgreSQL 16              │
                                    │  schemas: identity/clinical/       │
                                    │  scheduling/billing/content        │
                                    └─────────────────────────────────────┘
                                    ┌─────────────┐
                                    │   Redis      │
                                    └─────────────┘
```

**Alur event penting:** `core-api` membuat reservasi → memanggil `payment-service` untuk generate invoice Xendit → webhook Xendit masuk ke `payment-service` → publish event `payment.paid` via Redis pub/sub → `core-api` update status reservasi & `notification-service` mengirim WA/push konfirmasi. Pola yang sama dipakai untuk reminder H-1 (dijadwalkan oleh cron di `core-api`, dieksekusi oleh `notification-service`).

---

## 4. Skema Database (inti)

Skema per-domain di satu instance Postgres:

- **identity**: `users`, `patients` (relasi ke `users`, mendukung akun keluarga via `primary_account_user_id` + `relation`), `staff`, `roles`, `permissions`
- **scheduling**: `branches`, `doctors`, `doctor_schedules`, `reservations`, `reservation_treatments`, `queue_tickets` (untuk antrian real-time)
- **clinical**: `medical_records` (append-only), `odontogram_entries`, `medical_record_items` (pemakaian alat/obat per tindakan — lihat `billing.inventory_items` di bawah), `attachments` (link ke object storage — backend dipilih saat fitur ini dibangun, Fase 2), `audit_logs` (wajib untuk rekam medis — siapa akses/ubah kapan)
- **billing**: `treatments`, `treatment_categories`, `payments` (mendukung provider `xendit` maupun `manual` untuk transaksi tunai/office), `payment_events` (webhook log/idempotency), `inventory_items` (alat & obat — kategori, stok, harga satuan; stok berkurang otomatis saat dipakai di rekam medis), `membership_tiers`, `loyalty_points`, `insurance_info` (opsional, fase 3)
- **content**: `articles`, `article_categories`, `promos`, `testimonials`, `videos`, `notification_templates`, `notification_logs`

Migrasi pakai `golang-migrate`, versi terkontrol per service (`core-api` memegang mayoritas skema; `payment-service`/`notification-service` hanya punya tabel log milik mereka sendiri agar tetap longgar-terikat / loosely coupled). SQL migrasi sudah ditulis di `services/core-api/migrations/000001`–`000008` (`000007` men-set timezone database ke `Asia/Jakarta` — klinik beroperasi WIB, jadi semua logika "hari ini"/tanggal harus pakai kalender lokal, bukan UTC; `000008` menambahkan tabel inventaris alat/obat).

Data dummy untuk demo/pengembangan ada di `services/core-api/seed/seed.sql` (jalankan via `make seed`) — 2 cabang, 4 dokter, 6 pasien, 4 kategori + 13 treatment, 10 reservasi, 10 transaksi pembayaran, 8 item inventaris, 3 rekam medis, dan konten CMS contoh (artikel/promo/testimoni/video).

---

## 5. Backend — `core-api` (Go)

Struktur modular monolith, tiap domain = 1 package dengan handler/service/repository sendiri (hexagonal/clean architecture ringan):

```
services/core-api/
  cmd/api/main.go
  internal/
    identity/        (auth, users, patients, staff, RBAC middleware)
    scheduling/       (branches, doctors, schedules, reservations, queue)
    clinical/         (medical records, odontogram, attachments, audit log)
    billing/          (treatments, pricelist, payment orchestration — calls payment-service)
    content/          (articles, promos, testimonials, CMS)
    platform/         (db, redis, config, middleware, logger, jwt)
  migrations/
```

**Endpoint groups utama (REST, `/api/v1/...`):**
- `auth`: register (+OTP WA verifikasi via notification-service), login, refresh token, forgot password — **belum diimplementasikan**, satu-satunya domain yang tersisa
- ✅ `branches` (read-only) — CRUD belum diminta
- ✅ `doctors` (read, aktif saja), `doctors/admin` (read, termasuk nonaktif), `doctors/:id` (detail + jadwal), + POST/PUT/DELETE — CRUD penuh termasuk cabang praktik (multi) & jadwal mingguan
- ✅ `patients` — CRUD penuh, termasuk tambah anggota keluarga via `primaryAccountUserId` (mirror alur "Tambah Pasien"/"Pilih Pasien" di reference app)
- ✅ `users`, `roles` — CRUD akun staf non-dokter (perawat/admin cabang/finance/superadmin), password di-hash bcrypt
- ✅ `treatments` (read-only) — CRUD belum diminta
- ✅ `reservations` (GET dengan filter `branchId`/`status`/`from`/`to`, POST create), `reservations/:id/status` (PATCH), `reservation-statuses`
- ✅ `payments` (GET, POST untuk transaksi manual/office selain jalur Xendit), `payments/:id/invoice` (data invoice siap cetak)
- ✅ `inventory` — CRUD alat & obat, stok berkurang otomatis lewat `medical-records`
- ✅ `medical-records` — GET list/detail, POST create (append-only by design, sengaja tanpa PUT/DELETE), termasuk odontogram & pemakaian alat/obat dalam satu transaksi
- ✅ `content/{articles,article-categories,promos,testimonials,videos}` — CRUD penuh (CMS)
- ✅ `admin/dashboard*` (KPI + 4 chart), `admin/reports/*` (summary/revenue-trend/by-payment-method untuk periode custom)

✅ = endpoint nyata sudah ada (lihat `internal/{identity,scheduling,billing,clinical,content}/handler.go`). Semua endpoint di atas **belum ada auth/RBAC** — akan ditambahkan bersamaan dengan domain `auth`; role-restriction untuk `medical-records` (dokter/perawat full write, pasien read-only riwayat sendiri) menyusul di titik yang sama.

**Autentikasi & otorisasi:** JWT access (short-lived) + refresh token (rotasi, disimpan hashed), middleware RBAC berbasis role (`patient`, `dokter`, `perawat`, `admin_cabang`, `superadmin`, `finance`). Semua akses ke `clinical.medical_records` dicatat ke `audit_logs`.

---

## 6. `payment-service` (Go)

Tanggung jawab: integrasi Xendit (Invoice API / VA / e-wallet / QRIS), webhook handler idempoten, rekonsiliasi, refund.

- `POST /internal/payments` — dipanggil `core-api` saat reservasi dibuat → create Xendit invoice, simpan `payments` row (status `pending`, `expired_at`)
- `POST /webhooks/xendit` — verifikasi signature/token Xendit, update status, publish event `payment.paid` / `payment.expired` ke Redis
- `GET /internal/payments/:id` — status check (dipakai halaman "Riwayat Pembayaran")
- Reconciliation job harian: cocokkan status lokal vs Xendit API untuk transaksi yang stuck `pending`

Desain interface `PaymentProvider` di kode agar Xendit bisa diganti/ditambah provider lain tanpa ubah kontrak ke `core-api` (future-proofing murah, tidak menambah kompleksitas berarti karena hanya 1 interface + 1 implementasi dipakai sekarang). Interface sudah ditulis di `internal/payment/provider.go`; implementasi konkret Xendit menyusul saat API key tersedia (Fase 1).

**Jalur transaksi manual/office** (di luar payment-service, langsung di `core-api`/`billing`): staf front-office bisa mencatat pembayaran tunai/transfer manual langsung lewat `POST /api/v1/payments` (`provider: "manual"`), dan mencetak invoice lewat `GET /api/v1/payments/:id/invoice` — halaman `/billing/:id/invoice` di admin panel me-render ini dalam format print-friendly (`window.print()`, bukan generate PDF di server, supaya tidak menambah dependency).

---

## 7. `notification-service` (Go)

Tanggung jawab: satu pintu keluar semua notifikasi (WA, push, email), dengan template & log terpusat.

- Channel WA: interface `WhatsAppGateway`, implementasi awal ke salah satu provider (Fonnte/Wablas/Qontak — pilih berdasarkan harga & reliabilitas saat purchase, kode tidak berubah)
- Channel Push: Firebase Cloud Messaging (device token dari mobile app)
- Channel Email: SMTP (untuk notifikasi ke admin/staff, mis. laporan harian)
- Konsumen event dari Redis pub/sub (`reservation.created`, `payment.paid`, `reservation.reminder_h1`) → render template dari `content.notification_templates` → kirim → catat ke `content.notification_logs`
- Endpoint admin: kelola template pesan, lihat log kirim (sukses/gagal), retry manual

Gateway interfaces (`WhatsAppGateway`, `PushGateway`, `EmailGateway`) sudah ditulis di `internal/notify/gateway.go`.

---

## 8. Admin / Office Panel (Nuxt 3)

**Modul (menu utama, dikelompokkan di sidebar per `app/composables/useAdminNav.ts`):**
1. **Dashboard** — KPI harian: reservasi, revenue, tingkat kehadiran, antrian aktif per cabang, chart tren/breakdown ✅
2. **Reservasi & Antrian** — filter cabang/status/tanggal, buat reservasi baru, ubah status inline ✅ — papan antrian TV & check-in QR menyusul Fase 2
3. **Pasien** — CRUD penuh, family linking (relasi anak/pasangan/dll ke akun utama) ✅ — merge duplikat menyusul
4. **Dokter & Jadwal** — CRUD penuh: profil, spesialisasi, cabang praktik (multi), jadwal mingguan ✅ — manajemen cuti menyusul
5. **Cabang** — read-only ✅ — CRUD belum diminta
6. **Perawatan & Harga** — read-only ✅ — CRUD & harga per-cabang belum diminta
7. **Rekam Medis** — buat entri append-only: diagnosis, catatan tindakan, odontogram, **pemakaian alat/obat** (kurangi stok otomatis), lihat detail ✅ — akses dibatasi role dokter/perawat menyusul bersama `auth`
8. **Inventaris (Alat & Obat)** — master data stok, kategori obat/alat, badge stok menipis, CRUD penuh ✅ *(modul baru, di luar 12 modul awal — permintaan "penggunaan alat, obat dari tindakan pemeriksaan")*
9. **Billing & Rekonsiliasi** — riwayat transaksi (Xendit + manual/tunai dari office), **catat pembayaran manual**, **cetak invoice** ✅
10. **Laporan Keuangan** — filter periode custom, summary, tren revenue, breakdown metode/cabang ✅
11. **CMS** — artikel + kategori, promo, testimoni, video — CRUD penuh ✅ (gambar/video via URL, belum ada upload)
12. **Notifikasi/Broadcast** — kelola template WA/push, broadcast, log kirim — **coming soon**, butuh integrasi WA gateway pihak ketiga dulu
13. **User & Role** — CRUD staf non-dokter (perawat/admin cabang/finance/superadmin) ✅ — akun dokter dikelola di modul Dokter, bukan di sini

✅ = sudah menampilkan/mengelola data nyata dari core-api (diisi data dummy lewat `make seed`), bukan lagi "coming soon". Struktur folder Nuxt standar: `pages/`, `components/`, `composables/` (data-fetching lewat `useApiFetch` untuk GET — hostname internal docker saat SSR, hostname host-mapped saat client; `useApiMutate` untuk POST/PUT/PATCH/DELETE, selalu client-side, lihat `nuxt.config.ts`), `middleware/` (auth+role guard, menyusul bersama domain `auth`), `layouts/` (`default.vue` = admin shell dgn sidebar terkelompok + navbar, `auth.vue` = split-screen login, `invoice.vue` = layout kosong untuk halaman cetak).

---

## 9. Mobile App (Flutter)

**Arsitektur:** Clean Architecture ringan — `presentation` (widgets + Riverpod providers) / `domain` (entities, use cases) / `data` (repository impl, Dio client, DTO+`freezed`). Navigasi: `go_router` dengan guard auth. Storage token: `flutter_secure_storage`.

```
mobile/
  lib/
    core/          (theme, router, network client, error handling, di)
    features/
      auth/        (register w/ OTP WA, login)
      home/
      branch/       (pilih cabang, detail cabang)
      reservation/   (pilih tanggal/dokter, pilih pasien, pilih perawatan, ringkasan)
      payment/       (pilih metode, status, riwayat)
      patient/       (profil, keluarga/family member, rekam medis, QR profile)
      pricelist/
      content/       (artikel, promo, testimoni)
      notification/
    l10n/           (id/en)
  test/
```

**Fitur, mengikuti alur acuan (screenshot FDC) tapi disesuaikan brand Nina Dental Care (biru/putih, bukan hijau/pink):**
- Home: banner promo, quick menu (Reservasi, Price List, Cabang Terdekat, Riwayat Pembayaran, Dokter), testimoni, artikel edukasi
- Reservasi: pilih cabang (Soreang/Baleendah) → pilih tanggal & dokter (lihat jadwal) → pilih pasien (akun sendiri/anak — cocok dgn program "Nina Kidz") → pilih rencana perawatan (multi-select + harga) → catatan keluhan opsional → ringkasan & bayar deposit
- Pembayaran: ringkasan, Xendit (VA bank/e-wallet/QRIS), countdown expired, riwayat pembayaran (tab status)
- Profil: data diri, QR check-in, riwayat kunjungan & rekam medis ringkas, family member management
- Price List: kategori treatment, harga, tombol book langsung

**Peningkatan dibanding acuan (poin "improve lebih bagus informatif"):**
- Guest browsing: price list, artikel, profil klinik bisa dilihat tanpa login (login hanya wajib saat reservasi/bayar)
- **Status antrian real-time** ("Nomor antrian Anda: 5, estimasi 20 menit") — nilai tambah besar karena klinik gigi rawan delay, terhubung ke `queue_tickets` yang di-update admin panel
- **Odontogram digital** yang bisa dilihat pasien di riwayat rekam medis (transparansi treatment history)
- Push notification H-1 & H-0 otomatis (bukan cuma WA)
- Dark mode + tema warna brand Nina (biru/putih) dengan aksen konsisten di seluruh app
- Toggle bahasa ID/EN
- Loyalty/poin dengan progress bar visual menuju tier berikutnya (mempertahankan konsep membership tapi lebih sederhana dari acuan)

> Sudah di-scaffold (Flutter 3.44.8, target Android+iOS). Lihat `mobile/README.md` untuk struktur folder yang sudah ada dan apa yang masih perlu dikerjakan.

---

## 10. Infra & DevOps

`service-infra-klinik/docker-compose.yml` (base, tanpa port ke host) + override sesuai environment:

```yaml
services:
  postgres:         # database — bind mount ./data/postgres (bukan named volume)
  redis:            # cache + pub/sub — bind mount ./data/redis
  core-api:         # backend
  payment-service:
  notification-service:
  admin-frontend:   # nuxt
  migrate:          # one-off migration runner (profile "tools")
```
- `service-infra-klinik/docker-compose.dev.yml` — override, publish semua port ke localhost untuk dev.
- `service-infra-klinik/docker-compose.prod.yml` — override, menambahkan `traefik` (TLS Let's Encrypt) + label routing (`admin.${DOMAIN}`, `api.${DOMAIN}`, `pay.${DOMAIN}`), tidak ada port host langsung selain 80/443.
- Data Postgres & Redis di-bind mount ke `service-infra-klinik/data/{postgres,redis}` (folder biasa di disk, bukan Docker named volume) — sengaja begini agar `docker compose down`, `docker rm`, atau `docker volume prune` tidak bisa menghapus data secara tidak sengaja. Folder ini di-`.gitignore`-kan.
- Secrets lewat `service-infra-klinik/.env` (dev) / secret manager (prod — mis. Doppler atau Vault jika budget ada, minimal `.env` terenkripsi + akses terbatas jika tidak).
- Jalankan lewat `Makefile` di root: `make up`, `make migrate-up`, dst.

**CI/CD (GitHub Actions, di `.github/workflows/`):**
- `core-api.yml`, `payment-service.yml`, `notification-service.yml`: build → vet → test (dengan Postgres+Redis service container untuk core-api) → docker build (di `main`)
- `admin.yml`: pnpm install → lint → typecheck → build → docker build (di `main`)
- Mobile (Flutter, menyusul): analyze → test (`flutter test` + `integration_test`) → build APK/IPA via Codemagic atau Fastlane+GitHub Actions → distribusi internal (Firebase App Distribution) sebelum submit ke Play Store/App Store

---

## 11. Keamanan & Kepatuhan

- Data rekam medis & KTP asuransi = data pribadi sensitif → tunduk **UU PDP (UU No. 27/2022)** dan **Permenkes 24/2022** soal rekam medis elektronik. Perlu: consent eksplisit saat registrasi, enkripsi kolom sensitif (NIK, no. asuransi) via `pgcrypto`/app-level AES, retensi & hak hapus data pasien.
- Audit log wajib untuk setiap akses/perubahan `medical_records` (siapa, kapan, apa yang berubah).
- Rate limiting OTP & login (Redis) untuk cegah brute force.
- TLS end-to-end (Traefik + Let's Encrypt), secrets tidak pernah masuk git.
- Backup otomatis harian (`pg_dump` + upload ke object storage offsite) + retensi 30 hari minimum.
- Idempotency key untuk semua webhook Xendit (`payment_events`) agar tidak dobel-proses saat retry.

---

## 12. Roadmap & Fase

| Fase | Durasi (estimasi) | Scope |
|---|---|---|
| **0 — Foundation** | 2–3 minggu | Repo & docker-compose skeleton, CI/CD dasar, auth + RBAC, brand/design system (biru/putih Nina), migrasi DB awal |
| **1 — MVP Core Journey** | 6–8 minggu | Register/login (OTP WA), cabang, dokter+jadwal, alur reservasi lengkap, price list, pembayaran deposit via Xendit, riwayat pembayaran, admin: reservasi/pasien/dokter/treatment CRUD + dashboard basic |
| **2 — Klinis & Operasional** | 4–6 minggu | EMR + odontogram, QR check-in + papan antrian, notifikasi WA (reminder & konfirmasi) via 3rd-party gateway, push notification, CMS (artikel/promo/testimoni), loyalty/membership |
| **3 — Growth & Hardening** | 4–6 minggu | Reporting/analytics lanjutan, broadcast marketing, modul asuransi (opsional), audit-log viewer, security review, load testing, submission ke Play Store & App Store |

Total ±4–5 bulan kalender untuk tim kecil (indikatif — tergantung jumlah developer aktual).

**Estimasi tim minimum:** 2 backend (Go), 1–2 Flutter, 1 frontend Nuxt (bisa rangkap backend jika full-stack), 1 QA paruh waktu, 1 designer paruh waktu (brand & UI kit di awal).

---

## 13. Verifikasi & Definition of Done

- **Backend/services:** `go test ./...` hijau, health-check endpoint tiap service, Postman/Bruno collection untuk smoke test tiap domain, staging deploy sebelum prod
- **Admin (Nuxt):** unit test komponen kritikal (Vitest), e2e alur reservasi & billing (Playwright)
- **Mobile:** widget test tiap feature, `integration_test` untuk alur reservasi→bayar end-to-end, manual QA di device Android & iOS real (bukan cuma emulator) sebelum tiap rilis
- **Tiap fase:** demo end-to-end ke stakeholder (staff klinik) sebelum lanjut fase berikutnya, khususnya alur reservasi & pembayaran (uang riil) harus diuji di sandbox Xendit dulu

---

## 14. Struktur Repository (monorepo, sudah di-scaffold)

```
KLINIK GIGI/
  mobile/                 (Flutter app)
  admin/                  (Nuxt 3 office/admin panel)
  services/
    core-api/             (Go)
    payment-service/       (Go)
    notification-service/  (Go)
  infra/
    docker-compose.yml
    docker-compose.dev.yml
    docker-compose.prod.yml
    .env.example
  docs/
    architecture.md        (dokumen ini)
    status.md
  .github/workflows/
  Makefile
```

Monorepo dipilih karena tim kecil & siklus rilis saling terkait erat (lebih mudah koordinasi versi API antara mobile/admin/backend), tanpa mengorbankan kemampuan deploy tiap service secara independen lewat Docker image masing-masing.

## 15. Langkah Selanjutnya

Lihat [status.md](./status.md) untuk daftar konkret apa yang sudah dan belum dikerjakan.
