<script setup lang="ts">
definePageMeta({ title: 'Dokumentasi & Panduan' })

const activeSection = ref('getting-started')

const sections = [
  { id: 'getting-started', icon: 'i-lucide-rocket', label: 'Mulai Cepat' },
  { id: 'roles', icon: 'i-lucide-shield-check', label: 'Role & Hak Akses' },
  { id: 'reservasi', icon: 'i-lucide-calendar-check', label: 'Alur Reservasi' },
  { id: 'rekam-medis', icon: 'i-lucide-file-heart', label: 'Rekam Medis' },
  { id: 'billing', icon: 'i-lucide-credit-card', label: 'Billing & Pembayaran' },
  { id: 'cms', icon: 'i-lucide-newspaper', label: 'CMS & Konten' },
  { id: 'mobile', icon: 'i-lucide-smartphone', label: 'Aplikasi Mobile' },
  { id: 'api', icon: 'i-lucide-code-2', label: 'API & Integrasi' }
]

const ADMIN_URL = 'https://nfmtech.my.id/product/klinik'
const API_URL = 'https://nfmtech.my.id/product/klinik/api/v1'
const APK_URL = 'https://nfmtech.my.id/product/klinik/downloads/nina-dental-care.apk'
</script>

<template>
  <div class="p-4 w-full max-w-none">

    <!-- Page Header -->
    <div class="mb-6">
      <h1 class="text-2xl font-bold flex items-center gap-2 text-gray-900 dark:text-white">
        <UIcon name="i-lucide-book-open" class="w-6 h-6 text-primary" />
        Dokumentasi & Panduan Penggunaan
      </h1>
      <p class="text-sm text-muted mt-1">
        Panduan lengkap alur kerja, hak akses, dan cara penggunaan sistem <strong>Nina Dental Care Office Panel</strong>.
      </p>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 items-start">

      <!-- Sidebar nav -->
      <nav class="lg:sticky lg:top-4 space-y-1">
        <button
          v-for="s in sections"
          :key="s.id"
          class="w-full text-left flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-all"
          :class="activeSection === s.id
            ? 'bg-primary-100 dark:bg-primary-950/40 text-primary-700 dark:text-primary-300 font-semibold'
            : 'hover:bg-gray-100 dark:hover:bg-white/5 text-muted'"
          @click="activeSection = s.id"
        >
          <UIcon :name="s.icon" class="w-4 h-4 shrink-0" />
          {{ s.label }}
        </button>
      </nav>

      <!-- Main content -->
      <div class="lg:col-span-3 space-y-6">

        <!-- ══ MULAI CEPAT ══════════════════════════════════════════════════ -->
        <div v-if="activeSection === 'getting-started'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-rocket" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">Mulai Cepat — Panduan Onboarding</h2>
              </div>
            </template>
            <div class="space-y-5 text-sm">

              <UAlert color="info" variant="subtle" icon="i-lucide-info" title="Tentang Sistem">
                Nina Dental Care menggunakan sistem berbasis web (admin panel) dan aplikasi Android (mobile app). Keduanya terhubung ke satu backend API yang sama di VPS.
              </UAlert>

              <div>
                <h3 class="font-bold text-base mb-3">🔗 Akses Sistem</h3>
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div class="border border-default rounded-xl p-3 space-y-2">
                    <div class="flex items-center gap-2">
                      <UIcon name="i-lucide-monitor" class="w-4 h-4 text-primary" />
                      <span class="font-semibold">Admin Panel (Web)</span>
                    </div>
                    <a :href="ADMIN_URL" target="_blank" class="text-primary text-xs underline break-all">{{ ADMIN_URL }}</a>
                    <p class="text-xs text-muted">Untuk semua staf klinik</p>
                  </div>
                  <div class="border border-default rounded-xl p-3 space-y-2">
                    <div class="flex items-center gap-2">
                      <UIcon name="i-lucide-code-2" class="w-4 h-4 text-emerald-500" />
                      <span class="font-semibold">Backend API</span>
                    </div>
                    <a :href="API_URL" target="_blank" class="text-emerald-500 text-xs underline break-all">{{ API_URL }}</a>
                    <p class="text-xs text-muted">REST API untuk integrasi</p>
                  </div>
                  <div class="border border-default rounded-xl p-3 space-y-2">
                    <div class="flex items-center gap-2">
                      <UIcon name="i-lucide-smartphone" class="w-4 h-4 text-pink-500" />
                      <span class="font-semibold">Aplikasi Android</span>
                    </div>
                    <a :href="APK_URL" target="_blank" class="text-pink-500 text-xs underline break-all">Download APK (.apk)</a>
                    <p class="text-xs text-muted">Untuk pasien</p>
                  </div>
                </div>
              </div>

              <div>
                <h3 class="font-bold text-base mb-3">📋 Langkah Setup Awal</h3>
                <ol class="space-y-3 list-none">
                  <li v-for="(step, i) in [
                    { title: 'Login sebagai Superadmin', desc: 'Gunakan email admin@ninaclinic.id dan password yang telah ditetapkan. Superadmin dapat mengakses semua menu.', icon: 'i-lucide-log-in', color: 'primary' },
                    { title: 'Atur Cabang Klinik', desc: 'Buka menu Cabang, tambahkan data setiap cabang (nama, alamat, jam operasional). Cabang ini menjadi acuan untuk reservasi dan antrian.', icon: 'i-lucide-map-pin', color: 'warning' },
                    { title: 'Tambah Dokter & Jadwal', desc: 'Di menu Dokter & Jadwal, daftarkan setiap dokter beserta jadwal praktik per cabang dan durasi slot reservasi.', icon: 'i-lucide-stethoscope', color: 'success' },
                    { title: 'Tambah Staf & Assign Role', desc: 'Di menu User & Role, buat akun untuk setiap staf (admin cabang, perawat, finance) sesuai perannya.', icon: 'i-lucide-users', color: 'info' },
                    { title: 'Isi Daftar Perawatan & Harga', desc: 'Di menu Perawatan & Harga, tambahkan semua layanan klinik beserta harga dan kategorinya.', icon: 'i-lucide-list-checks', color: 'error' },
                    { title: 'Distribusikan Aplikasi ke Pasien', desc: 'Bagikan link download APK ke pasien. Pasien mendaftar mandiri di aplikasi, lalu admin dapat menghubungkan ke Rekam Medis.', icon: 'i-lucide-share-2', color: 'primary' }
                  ]" :key="i"
                    class="flex items-start gap-3 p-3 rounded-xl border border-default">
                    <div class="w-8 h-8 rounded-full flex items-center justify-center text-white text-sm font-bold shrink-0" :class="`bg-${step.color}-500`">
                      {{ i + 1 }}
                    </div>
                    <div>
                      <p class="font-semibold">{{ step.title }}</p>
                      <p class="text-muted text-xs mt-0.5">{{ step.desc }}</p>
                    </div>
                  </li>
                </ol>
              </div>

            </div>
          </UCard>
        </div>

        <!-- ══ ROLE & HAK AKSES ════════════════════════════════════════════ -->
        <div v-if="activeSection === 'roles'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-shield-check" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">Role & Hak Akses</h2>
              </div>
            </template>
            <div class="space-y-4 text-sm">
              <div
                v-for="role in [
                  { name: 'Superadmin', color: 'error', icon: 'i-lucide-shield', who: 'Pemilik klinik / IT Manager', access: 'FULL', desc: 'Dapat mengakses dan mengedit semua menu tanpa pengecualian, termasuk manajemen pengguna, laporan keuangan konsolidasi, dan konfigurasi sistem.', perms: ['Dashboard', 'Reservasi', 'Pasien', 'Dokter', 'Rekam Medis', 'Billing', 'Laporan', 'CMS', 'Inventaris', 'User & Role', 'Notifikasi', 'Cabang', 'Perawatan & Harga'] },
                  { name: 'Admin Cabang', color: 'warning', icon: 'i-lucide-building-2', who: 'Staf front office/resepsionis per cabang', access: 'OPERASIONAL', desc: 'Mengelola reservasi, antrian pasien, pendaftaran pasien baru, dan proses billing di cabangnya. Tidak bisa mengakses laporan keuangan atau pengaturan user.', perms: ['Dashboard', 'Reservasi & Antrian', 'Pasien', 'Billing', 'Notifikasi'] },
                  { name: 'Finance', color: 'info', icon: 'i-lucide-wallet', who: 'Staf keuangan', access: 'KEUANGAN', desc: 'Akses read-only ke data reservasi, dan akses penuh ke billing, laporan keuangan, dan rekonsiliasi pembayaran.', perms: ['Dashboard', 'Billing', 'Laporan Keuangan', 'Inventaris (baca saja)'] },
                  { name: 'Perawat', color: 'success', icon: 'i-lucide-heart-pulse', who: 'Perawat/asisten dokter', access: 'KLINIS', desc: 'Membantu dokter dalam pengisian rekam medis dan mengelola stok inventaris alat & obat klinik.', perms: ['Dashboard', 'Rekam Medis', 'Inventaris', 'Reservasi (baca saja)', 'Pasien (baca saja)'] },
                  { name: 'Dokter', color: 'primary', icon: 'i-lucide-stethoscope', who: 'Dokter gigi / spesialis', access: 'KLINIS', desc: 'Hanya melihat data pasien yang memiliki janji temu dengannya, dan mengisi/mengupdate rekam medis pasien tersebut.', perms: ['Rekam Medis (pasiennya)', 'Reservasi (pasiennya)', 'Dashboard (ringkasan)'] }
                ]"
                :key="role.name"
                class="border border-default rounded-xl p-4"
              >
                <div class="flex items-start gap-3 mb-3">
                  <div class="w-9 h-9 rounded-lg flex items-center justify-center" :class="`bg-${role.color}-100 dark:bg-${role.color}-950/40`">
                    <UIcon :name="role.icon" class="w-5 h-5" :class="`text-${role.color}-600`" />
                  </div>
                  <div class="flex-1">
                    <div class="flex items-center gap-2 flex-wrap">
                      <h3 class="font-bold">{{ role.name }}</h3>
                      <UBadge :color="role.color" variant="subtle" size="xs">{{ role.access }}</UBadge>
                    </div>
                    <p class="text-xs text-muted">Diperuntukkan: <strong>{{ role.who }}</strong></p>
                  </div>
                </div>
                <p class="text-muted text-xs mb-2">{{ role.desc }}</p>
                <div class="flex flex-wrap gap-1">
                  <UBadge v-for="p in role.perms" :key="p" color="neutral" variant="outline" size="xs">{{ p }}</UBadge>
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <!-- ══ ALUR RESERVASI ══════════════════════════════════════════════ -->
        <div v-if="activeSection === 'reservasi'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-calendar-check" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">Alur Reservasi — Pasien ke Klinik</h2>
              </div>
            </template>
            <div class="space-y-4 text-sm">
              <div
                v-for="(step, i) in [
                  { title: 'Pasien Buat Reservasi (Mobile)', actor: 'Pasien', icon: 'i-lucide-smartphone', color: 'primary', desc: 'Pasien membuka aplikasi → Menu Reservasi → Pilih cabang → Pilih dokter & tanggal → Pilih jam slot → Pilih perawatan → Konfirmasi → Bayar deposit.' },
                  { title: 'Notifikasi Masuk ke Admin', actor: 'Admin Cabang / Sistem', icon: 'i-lucide-bell', color: 'warning', desc: 'Sistem mengirim notifikasi ke Admin Cabang bahwa ada reservasi baru dengan status PENDING. Admin mengkonfirmasi atau menolak reservasi.' },
                  { title: 'Pasien Datang — Check-in', actor: 'Admin Cabang', icon: 'i-lucide-log-in', color: 'success', desc: 'Saat pasien tiba, Admin membuka menu Reservasi & Antrian → Scan QR atau cari nama → Klik "Check-in". Status berubah menjadi CHECKED_IN dan tiket antrian dicetak.' },
                  { title: 'Pasien Dipanggil', actor: 'Admin Cabang / Perawat', icon: 'i-lucide-megaphone', color: 'info', desc: 'Admin/Perawat memanggil nomor antrian pasien → Klik "Panggil". Status berubah menjadi IN_SERVICE.' },
                  { title: 'Dokter Tangani & Isi Rekam Medis', actor: 'Dokter / Perawat', icon: 'i-lucide-stethoscope', color: 'primary', desc: 'Dokter atau perawat membuka menu Rekam Medis, mengisi diagnosis, tindakan, resep, dan odontogram. Status reservasi diubah menjadi COMPLETED setelah selesai.' },
                  { title: 'Billing & Pembayaran', actor: 'Admin Cabang / Finance', icon: 'i-lucide-credit-card', color: 'error', desc: 'Admin Cabang / Finance membuka menu Billing → Cari transaksi → Verifikasi pembayaran pasien. Jika pembayaran via Xendit/QRIS sudah terkonfirmasi otomatis, status langsung PAID.' }
                ]"
                :key="i"
                class="flex items-start gap-3"
              >
                <div class="relative">
                  <div class="w-9 h-9 rounded-xl flex items-center justify-center z-10 relative" :class="`bg-${step.color}-100 dark:bg-${step.color}-950/40`">
                    <UIcon :name="step.icon" class="w-5 h-5" :class="`text-${step.color}-600`" />
                  </div>
                  <div v-if="i < 5" class="absolute left-4 top-9 w-0.5 h-6 bg-gray-200 dark:bg-gray-700" />
                </div>
                <div class="flex-1 pb-4">
                  <div class="flex items-center gap-2 flex-wrap">
                    <span class="font-semibold">{{ i + 1 }}. {{ step.title }}</span>
                    <UBadge :color="step.color" variant="subtle" size="xs">{{ step.actor }}</UBadge>
                  </div>
                  <p class="text-muted text-xs mt-1">{{ step.desc }}</p>
                </div>
              </div>

              <UAlert color="success" variant="subtle" icon="i-lucide-check-circle" title="Status Reservasi">
                <template #description>
                  <code>pending</code> → <code>confirmed</code> → <code>checked_in</code> → <code>in_progress</code> → <code>completed</code>.<br>
                  Status bisa menjadi <code>cancelled</code> atau <code>no_show</code> jika pasien tidak hadir.
                </template>
              </UAlert>
            </div>
          </UCard>
        </div>

        <!-- ══ REKAM MEDIS ═════════════════════════════════════════════════ -->
        <div v-if="activeSection === 'rekam-medis'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-file-heart" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">Rekam Medis — Cara Penggunaan</h2>
              </div>
            </template>
            <div class="space-y-4 text-sm">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div v-for="item in [
                  { title: 'Membuat Rekam Medis Baru', icon: 'i-lucide-file-plus', color: 'primary', steps: ['Buka menu Rekam Medis', 'Klik tombol + Tambah Rekam Medis', 'Pilih pasien dari daftar', 'Isi diagnosis, keluhan utama, dan tindakan yang dilakukan', 'Isi odontogram jika diperlukan', 'Tambah resep obat jika ada', 'Klik Simpan'] },
                  { title: 'Odontogram Digital', icon: 'i-lucide-scan-line', color: 'success', steps: ['Klik diagram gigi untuk memilih gigi yang ditangani', 'Pilih kondisi (caries, missing, filled, dll)', 'Warna otomatis muncul di tabel odontogram', 'Bisa ditambahkan foto gigi sebelum/sesudah tindakan', 'Riwayat odontogram tersimpan per kunjungan'] },
                  { title: 'Upload Foto Klinis', icon: 'i-lucide-camera', color: 'warning', steps: ['Scroll ke bagian Foto Klinis di rekam medis', 'Klik + Tambah Foto', 'Pilih jenis foto (sebelum / sesudah / x-ray)', 'Upload gambar dari device', 'Tambahkan keterangan foto', 'Foto otomatis terhubung ke profil pasien'] },
                  { title: 'Resep Obat & Dosis', icon: 'i-lucide-pill', color: 'info', steps: ['Buka tab Resep di form rekam medis', 'Klik + Tambah Obat', 'Pilih nama obat dari stok inventaris', 'Isi dosis, frekuensi, dan durasi', 'Stok inventaris otomatis berkurang', 'Cetak resep ke PDF dari halaman detail rekam medis'] }
                ]" :key="item.title"
                  class="border border-default rounded-xl p-4">
                  <div class="flex items-center gap-2 mb-3">
                    <UIcon :name="item.icon" class="w-4 h-4" :class="`text-${item.color}-500`" />
                    <h3 class="font-semibold">{{ item.title }}</h3>
                  </div>
                  <ol class="space-y-1 list-none">
                    <li v-for="(s, j) in item.steps" :key="j" class="flex items-start gap-2 text-xs text-muted">
                      <span class="w-4 h-4 rounded-full bg-gray-100 dark:bg-gray-800 text-[10px] flex items-center justify-center font-bold shrink-0 mt-0.5">{{ j + 1 }}</span>
                      {{ s }}
                    </li>
                  </ol>
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <!-- ══ BILLING & PEMBAYARAN ════════════════════════════════════════ -->
        <div v-if="activeSection === 'billing'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-credit-card" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">Billing & Pembayaran</h2>
              </div>
            </template>
            <div class="space-y-4 text-sm">
              <div>
                <h3 class="font-bold mb-2">Metode Pembayaran yang Didukung</h3>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  <div v-for="m in ['QRIS', 'Transfer BCA', 'Transfer Mandiri', 'Transfer BNI', 'OVO', 'GoPay', 'Dana', 'ShopeePay']" :key="m"
                    class="border border-default rounded-lg p-2 text-center text-xs font-medium">
                    {{ m }}
                  </div>
                </div>
              </div>

              <div>
                <h3 class="font-bold mb-2">Alur Pembayaran</h3>
                <div class="space-y-2">
                  <div v-for="(s, i) in [
                    'Pasien bayar deposit saat booking via mobile app (opsional, dikonfigurasi per cabang)',
                    'Setelah tindakan selesai, Admin/Finance membuka Billing untuk buat invoice final',
                    'Pasien dapat link pembayaran via WhatsApp/QR dari counter',
                    'Xendit (payment gateway) memproses dan mengirim notifikasi ke sistem',
                    'Status otomatis berubah menjadi PAID — tidak perlu konfirmasi manual'
                  ]" :key="i"
                    class="flex items-start gap-2 text-xs p-2 rounded-lg bg-gray-50 dark:bg-white/5">
                    <UBadge size="xs" color="primary" variant="subtle" class="shrink-0">{{ i + 1 }}</UBadge>
                    {{ s }}
                  </div>
                </div>
              </div>

              <UAlert color="warning" variant="subtle" icon="i-lucide-triangle-alert" title="Refund">
                Proses refund dilakukan manual melalui dashboard Xendit. Setelah refund diproses di Xendit, update status di menu Billing → Cari transaksi → Klik "Tandai Refund".
              </UAlert>
            </div>
          </UCard>
        </div>

        <!-- ══ CMS & KONTEN ════════════════════════════════════════════════ -->
        <div v-if="activeSection === 'cms'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-newspaper" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">CMS & Konten</h2>
              </div>
            </template>
            <div class="space-y-4 text-sm">
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div v-for="item in [
                  { title: 'Artikel & Edukasi', icon: 'i-lucide-file-text', color: 'primary', desc: 'Buat artikel edukasi gigi untuk ditampilkan di aplikasi mobile pasien. Dukung format rich text, gambar cover, dan kategori artikel.' },
                  { title: 'Promo & Diskon', icon: 'i-lucide-tag', color: 'error', desc: 'Buat banner promo dengan periode aktif, jenis diskon (nominal/persentase), dan gambar menarik. Promo aktif tampil di slider utama aplikasi mobile.' },
                  { title: 'Testimoni Pasien', icon: 'i-lucide-star', color: 'warning', desc: 'Kelola testimoni pasien yang tampil di aplikasi mobile. Bisa ditambahkan secara manual dari panel admin.' },
                  { title: 'Video Edukasi', icon: 'i-lucide-play-circle', color: 'success', desc: 'Tambahkan link video YouTube atau thumbnail video edukasi. Video tampil di halaman konten aplikasi mobile pasien.' }
                ]" :key="item.title"
                  class="border border-default rounded-xl p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <UIcon :name="item.icon" class="w-4 h-4" :class="`text-${item.color}-500`" />
                    <h3 class="font-semibold">{{ item.title }}</h3>
                  </div>
                  <p class="text-xs text-muted">{{ item.desc }}</p>
                </div>
              </div>
              <UAlert color="info" variant="subtle" icon="i-lucide-image" title="Tips Gambar">
                Gunakan gambar dengan rasio 16:9 dan resolusi minimal 800×400px untuk hasil terbaik di slider promo dan kartu artikel. Format yang disupport: JPG, PNG, WebP.
              </UAlert>
            </div>
          </UCard>
        </div>

        <!-- ══ APLIKASI MOBILE ═════════════════════════════════════════════ -->
        <div v-if="activeSection === 'mobile'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-smartphone" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">Aplikasi Mobile — Panduan Pasien</h2>
              </div>
            </template>
            <div class="space-y-4 text-sm">
              <div class="flex items-center gap-4 p-4 rounded-xl bg-gradient-to-r from-pink-50 to-purple-50 dark:from-pink-950/30 dark:to-purple-950/30 border border-pink-200 dark:border-pink-800">
                <UIcon name="i-lucide-download" class="w-10 h-10 text-pink-500 shrink-0" />
                <div class="flex-1">
                  <p class="font-bold text-base">Download Aplikasi Android</p>
                  <p class="text-xs text-muted">Nina Dental Care — v1.0.0 (57.9 MB)</p>
                </div>
                <a :href="APK_URL" target="_blank" download>
                  <UButton color="error" label="Download APK" icon="i-lucide-download" size="sm" />
                </a>
              </div>

              <div>
                <h3 class="font-bold mb-3">Fitur Aplikasi Mobile</h3>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div v-for="f in [
                    { icon: 'i-lucide-user-plus', color: 'primary', title: 'Registrasi & Login', desc: 'Daftar dengan nama & nomor WhatsApp. Login menggunakan email atau nomor WA.' },
                    { icon: 'i-lucide-calendar-plus', color: 'success', title: 'Buat Reservasi', desc: 'Pilih cabang → dokter → tanggal → jam → perawatan → konfirmasi & bayar.' },
                    { icon: 'i-lucide-file-heart', color: 'info', title: 'Rekam Medis', desc: 'Lihat riwayat kunjungan, diagnosis, dan resep dari setiap kunjungan ke klinik.' },
                    { icon: 'i-lucide-receipt', color: 'warning', title: 'Riwayat Pembayaran', desc: 'Pantau status pembayaran semua transaksi. Tombol bayar ulang untuk transaksi pending.' },
                    { icon: 'i-lucide-map-pin', color: 'error', title: 'Lokasi Klinik Terdekat', desc: 'Temukan cabang Nina Dental Care terdekat dengan info jam buka dan kontak.' },
                    { icon: 'i-lucide-newspaper', color: 'primary', title: 'Artikel & Promo', desc: 'Baca artikel edukasi gigi dan nikmati promo spesial yang aktif di klinik.' }
                  ]" :key="f.title"
                    class="flex items-start gap-3 p-3 border border-default rounded-xl">
                    <UIcon :name="f.icon" class="w-5 h-5 shrink-0 mt-0.5" :class="`text-${f.color}-500`" />
                    <div>
                      <p class="font-semibold text-xs">{{ f.title }}</p>
                      <p class="text-xs text-muted mt-0.5">{{ f.desc }}</p>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </UCard>
        </div>

        <!-- ══ API & INTEGRASI ════════════════════════════════════════════ -->
        <div v-if="activeSection === 'api'" class="space-y-5">
          <UCard>
            <template #header>
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-code-2" class="w-5 h-5 text-primary" />
                <h2 class="text-lg font-bold">API & Integrasi</h2>
              </div>
            </template>
            <div class="space-y-4 text-sm">
              <div class="p-3 rounded-xl bg-gray-900 text-green-400 font-mono text-xs space-y-1">
                <p class="text-gray-500"># Base URL</p>
                <p>{{ API_URL }}</p>
                <p class="text-gray-500 mt-2"># Authentication (Basic Auth)</p>
                <p>Authorization: Bearer &lt;JWT_TOKEN&gt;</p>
              </div>

              <div>
                <h3 class="font-bold mb-3">Endpoint Utama</h3>
                <div class="space-y-2">
                  <div v-for="ep in [
                    { method: 'GET', path: '/patients', desc: 'Daftar semua pasien (paginated)' },
                    { method: 'POST', path: '/patients', desc: 'Buat pasien baru' },
                    { method: 'GET', path: '/doctors', desc: 'Daftar semua dokter' },
                    { method: 'GET', path: '/reservations', desc: 'Daftar reservasi (filter: from, to, status)' },
                    { method: 'POST', path: '/reservations', desc: 'Buat reservasi baru' },
                    { method: 'GET', path: '/medical-records', desc: 'Daftar rekam medis (filter: patientId)' },
                    { method: 'GET', path: '/billing/payments', desc: 'Daftar transaksi pembayaran' },
                    { method: 'GET', path: '/content/articles', desc: 'Daftar artikel CMS (untuk mobile)' },
                    { method: 'GET', path: '/content/promos', desc: 'Daftar promo aktif' }
                  ]" :key="ep.path"
                    class="flex items-center gap-3 p-2 rounded-lg border border-default text-xs">
                    <UBadge
                      :color="ep.method === 'GET' ? 'info' : ep.method === 'POST' ? 'success' : 'warning'"
                      variant="subtle" size="xs" class="shrink-0 w-12 justify-center">
                      {{ ep.method }}
                    </UBadge>
                    <code class="text-primary font-mono">{{ ep.path }}</code>
                    <span class="text-muted ml-auto">{{ ep.desc }}</span>
                  </div>
                </div>
              </div>

              <UAlert color="info" variant="subtle" icon="i-lucide-book" title="Dokumentasi Lengkap API">
                <template #description>
                  Akses Swagger/OpenAPI docs di: <a :href="`${API_URL}/docs`" target="_blank" class="underline text-primary">{{ API_URL }}/docs</a>
                </template>
              </UAlert>
            </div>
          </UCard>
        </div>

      </div>
    </div>
  </div>
</template>
