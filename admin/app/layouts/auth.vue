<script setup lang="ts">
const features = [
  { icon: 'i-lucide-calendar-check', title: 'Reservasi & Antrian', label: 'Sinkronisasi jadwal & nomor antrian real-time per cabang' },
  { icon: 'i-lucide-stethoscope', title: 'Rekam Medis Digital', label: 'E-Medical records lengkap dengan Odontogram interaktif' },
  { icon: 'i-lucide-receipt-text', title: 'Kasir POS & Invoice', label: 'Pembayaran instan, cetak struk, dan laporan keuangan otomatis' }
]

const stats = [
  { label: 'Pasien Terdaftar', value: '12.4k+' },
  { label: 'Uptime Sistem', value: '99.9%' },
  { label: 'Cabang Aktif', value: '2 Unit' }
]
</script>

<template>
  <div class="min-h-screen grid lg:grid-cols-12 bg-gray-950/5 dark:bg-gray-950 font-sans selection:bg-emerald-500 selection:text-white">
    <!-- Left Hero Brand Panel (Desktop) -->
    <div class="hidden lg:flex lg:col-span-6 xl:col-span-7 flex-col justify-between p-12 text-white bg-gradient-to-br from-emerald-900 via-teal-900 to-slate-950 relative overflow-hidden">
      <!-- Animated / Ambient Background Glows -->
      <div class="absolute inset-0 opacity-15 [background-image:radial-gradient(circle_at_25%_25%,white_1px,transparent_1px)] [background-size:32px_32px]" />
      <div class="absolute -top-32 -right-32 w-96 h-96 rounded-full bg-emerald-500/20 blur-[100px] animate-pulse" />
      <div class="absolute top-1/2 -left-32 w-80 h-80 rounded-full bg-teal-400/20 blur-[120px]" />
      <div class="absolute -bottom-32 right-1/4 w-96 h-96 rounded-full bg-cyan-600/15 blur-[100px]" />

      <!-- Brand Top Header -->
      <div class="relative z-10 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="flex items-center justify-center w-11 h-11 rounded-2xl bg-gradient-to-tr from-emerald-400 to-teal-300 text-slate-950 font-black text-sm shadow-lg shadow-emerald-500/20 ring-2 ring-white/20">
            NDC
          </div>
          <div>
            <h1 class="font-bold text-base tracking-wide text-white flex items-center gap-2">
              Nina Dental Care
              <span class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-semibold bg-emerald-400/15 text-emerald-300 border border-emerald-400/30">
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                Office Portal
              </span>
            </h1>
            <p class="text-xs text-emerald-200/70 font-medium">Sistem Manajemen Klinik Gigi Terpadu</p>
          </div>
        </div>

        <div class="flex items-center gap-2 px-3 py-1.5 rounded-xl bg-white/5 border border-white/10 backdrop-blur-md text-xs font-medium text-white/80">
          <UIcon name="i-lucide-building-2" class="w-4 h-4 text-emerald-400" />
          <span>Soreang & Baleendah</span>
        </div>
      </div>

      <!-- Main Feature Showcase -->
      <div class="relative z-10 my-auto py-8 space-y-8 max-w-xl">
        <div class="space-y-3">
          <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-400/20 text-emerald-300 text-xs font-medium">
            <UIcon name="i-lucide-shield-check" class="w-4 h-4" />
            Akses Otorisasi Khusus Staf & Dokter
          </div>
          <h2 class="text-3xl xl:text-4xl font-extrabold tracking-tight leading-tight text-white">
            Kelola operasional klinik gigi dalam <span class="bg-gradient-to-r from-emerald-300 via-teal-200 to-cyan-200 bg-clip-text text-transparent">satu pintu interaktif</span>.
          </h2>
          <p class="text-emerald-100/70 text-sm leading-relaxed">
            Platform komprehensif untuk staf pendaftaran, perawat, kasir, dan tim medis dalam memberikan pelayanan pasien terbaik secara digital.
          </p>
        </div>

        <!-- Features Cards -->
        <div class="grid gap-3.5">
          <div
            v-for="f in features"
            :key="f.title"
            class="flex items-start gap-4 p-4 rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 backdrop-blur-md transition-all duration-300 group"
          >
            <div class="flex items-center justify-center w-10 h-10 rounded-xl bg-gradient-to-br from-emerald-400/20 to-teal-400/10 border border-emerald-400/30 text-emerald-300 group-hover:scale-110 transition-transform shrink-0">
              <UIcon :name="f.icon" class="w-5 h-5" />
            </div>
            <div>
              <h3 class="text-sm font-bold text-white group-hover:text-emerald-200 transition-colors">
                {{ f.title }}
              </h3>
              <p class="text-xs text-emerald-100/60 leading-relaxed mt-0.5">
                {{ f.label }}
              </p>
            </div>
          </div>
        </div>

        <!-- Quick Stats Banner -->
        <div class="grid grid-cols-3 gap-3 p-4 rounded-2xl bg-slate-900/50 border border-white/10 backdrop-blur-md">
          <div v-for="s in stats" :key="s.label" class="text-center">
            <p class="text-lg xl:text-xl font-black text-emerald-400">{{ s.value }}</p>
            <p class="text-[11px] text-emerald-100/60 font-medium mt-0.5">{{ s.label }}</p>
          </div>
        </div>
      </div>

      <!-- APK Download & Footer Info -->
      <div class="relative z-10 space-y-4">
        <div class="p-4 rounded-2xl bg-gradient-to-r from-emerald-900/80 to-teal-900/80 border border-emerald-500/30 backdrop-blur-md flex items-center justify-between gap-4 shadow-xl">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-emerald-500/20 border border-emerald-400/30 flex items-center justify-center text-emerald-300 shrink-0">
              <UIcon name="i-lucide-smartphone" class="w-5 h-5" />
            </div>
            <div>
              <p class="text-xs font-bold text-white flex items-center gap-2">
                Aplikasi Mobile Pasien
                <span class="px-1.5 py-0.5 rounded text-[10px] font-bold bg-emerald-400 text-emerald-950">v1.0.0</span>
              </p>
              <p class="text-[11px] text-emerald-100/70">Unduh installer APK Android terbaru (57.9 MB)</p>
            </div>
          </div>
          <a
            href="/downloads/nina-dental-care.apk"
            download="nina-dental-care.apk"
            target="_blank"
            class="flex items-center gap-2 py-2 px-3.5 rounded-xl bg-gradient-to-r from-emerald-400 to-teal-300 text-emerald-950 font-bold text-xs shadow-lg hover:brightness-110 hover:scale-105 active:scale-95 transition-all shrink-0 cursor-pointer"
          >
            <UIcon name="i-lucide-download" class="w-4 h-4" />
            <span>Download APK</span>
          </a>
        </div>

        <div class="flex items-center justify-between text-xs text-emerald-200/50">
          <p>© {{ new Date().getFullYear() }} Nina Dental Care. Internal Portal System.</p>
          <p class="flex items-center gap-1">
            <UIcon name="i-lucide-lock" class="w-3.5 h-3.5 text-emerald-400" />
            SSL 256-bit Encrypted
          </p>
        </div>
      </div>
    </div>

    <!-- Right Login Form Area -->
    <div class="lg:col-span-6 xl:col-span-5 flex items-center justify-center p-6 sm:p-10 relative overflow-hidden bg-slate-50 dark:bg-slate-900">
      <!-- Background Ambient Accents for Form Area -->
      <div class="absolute -top-24 -right-24 w-72 h-72 rounded-full bg-emerald-500/10 blur-3xl" />
      <div class="absolute -bottom-24 -left-24 w-72 h-72 rounded-full bg-teal-500/10 blur-3xl" />

      <div class="w-full max-w-md space-y-6 relative z-10">
        <!-- Mobile Logo Header -->
        <div class="flex flex-col items-center gap-2 text-center lg:hidden pb-2">
          <div class="flex items-center justify-center w-12 h-12 rounded-2xl bg-gradient-to-tr from-emerald-500 to-teal-400 text-white font-black text-base shadow-lg shadow-emerald-500/20">
            NDC
          </div>
          <h2 class="font-extrabold text-xl text-gray-900 dark:text-white">Nina Dental Care</h2>
          <p class="text-xs text-gray-500 dark:text-gray-400">Office Panel — Cabang Soreang & Baleendah</p>
        </div>

        <NuxtPage />
      </div>
    </div>
  </div>
</template>

