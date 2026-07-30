# Nina Dental Care — Mobile App & Office/Admin Panel

Monorepo untuk sistem digital Nina Dental Care (klinik gigi, cabang Soreang &
Baleendah — Kab. Bandung): aplikasi mobile pasien (Flutter) dan office/admin
panel (Nuxt 3 + Go + PostgreSQL).

Baca dulu:
- [`docs/architecture.md`](docs/architecture.md) — plan arsitektur lengkap (disetujui)
- [`docs/status.md`](docs/status.md) — apa yang sudah & belum dikerjakan
- [`HISTORY.md`](HISTORY.md) — changelog tiap update/adjustment

## Struktur

```
mobile/                 Flutter app (Android + iOS)
admin/                  Office/admin panel (Nuxt 3 + Nuxt UI)
services/core-api/            Backend utama (Go)
services/payment-service/     Integrasi Xendit (Go)
services/notification-service/ WA/push/email (Go)
service-infra-klinik/  docker-compose + .env.example
docs/                   Dokumentasi arsitektur & status
```

## Jalankan secara lokal

Butuh Docker (dan Docker Compose v2).

```bash
cp service-infra-klinik/.env.example service-infra-klinik/.env   # isi secrets/API key sesuai kebutuhan
make up                            # docker compose up --build, expose semua port ke localhost
make migrate-up                    # jalankan migrasi database
make seed                          # isi data dummy (cabang, dokter, pasien, reservasi, transaksi)
```

Setelah jalan:
- Admin panel: http://localhost:3100 (3000 dipakai project lain di mesin ini) — Dashboard, Reservasi, Pasien, Dokter, Cabang, dan Perawatan & Harga sudah menampilkan data dummy
- core-api: http://localhost:8080/healthz (endpoint data: `/api/v1/branches`, `/doctors`, `/patients`, `/treatments`, `/reservations`, `/payments`, `/admin/dashboard`)
- payment-service: http://localhost:8081/healthz
- notification-service: http://localhost:8082/healthz

`make down` untuk mematikan, `make logs` untuk tail log semua service. Data
Postgres/Redis disimpan di `service-infra-klinik/data/` (bind mount, bukan
Docker volume) — survive `docker compose down` dan `docker volume prune`.

## Development tanpa Docker

- **admin**: `cd admin && pnpm install && pnpm dev`
- **core-api / payment-service / notification-service**: butuh Postgres &
  Redis lokal (atau `make up` lalu jalankan `go run ./cmd/api` dari masing-masing
  folder service dengan `DATABASE_URL`/`REDIS_URL` mengarah ke `localhost`).
- **mobile**: lihat [`mobile/README.md`](mobile/README.md).
