<script setup lang="ts">
const features = [
  { icon: 'i-lucide-calendar-check', label: 'Reservasi & antrian real-time per cabang' },
  { icon: 'i-lucide-stethoscope', label: 'Rekam medis digital & odontogram' },
  { icon: 'i-lucide-receipt-text', label: 'Kasir POS, invoice, dan laporan keuangan' }
]
</script>

<template>
  <div class="min-h-screen grid lg:grid-cols-2">
    <div class="hidden lg:flex flex-col justify-between p-10 text-white bg-gradient-to-br from-primary-600 via-primary-700 to-primary-950 relative overflow-hidden">
      <div class="absolute inset-0 opacity-10 [background-image:radial-gradient(circle_at_20%_20%,white_1px,transparent_1px)] [background-size:24px_24px]" />
      <div class="absolute -top-24 -right-24 w-96 h-96 rounded-full bg-white/10 blur-3xl" />
      <div class="absolute -bottom-32 -left-16 w-80 h-80 rounded-full bg-primary-400/20 blur-3xl" />
      <UIcon
        name="i-lucide-sparkles"
        class="absolute right-10 bottom-24 w-56 h-56 opacity-[0.06] rotate-12"
      />

      <div class="relative flex items-center gap-2 font-semibold">
        <span class="flex items-center justify-center w-9 h-9 rounded-full bg-white/15 text-sm backdrop-blur">NDC</span>
        <span>Nina Dental Care</span>
      </div>

      <div class="relative space-y-6 max-w-md">
        <UIcon
          name="i-lucide-shield-check"
          class="w-10 h-10 opacity-80"
        />
        <h2 class="text-2xl font-semibold leading-snug">
          Office Panel untuk reservasi, rekam medis, dan billing — Soreang & Baleendah.
        </h2>
        <p class="text-white/70 text-sm">
          Satu tempat untuk staf klinik mengelola jadwal, pasien, dan transaksi harian.
        </p>
        <ul class="space-y-3 pt-2">
          <li
            v-for="f in features"
            :key="f.label"
            class="flex items-center gap-3 text-sm text-white/85"
          >
            <span class="flex items-center justify-center w-8 h-8 rounded-lg bg-white/10 shrink-0">
              <UIcon
                :name="f.icon"
                class="w-4 h-4"
              />
            </span>
            {{ f.label }}
          </li>
        </ul>
      </div>

      <p class="relative text-xs text-white/60">
        © {{ new Date().getFullYear() }} Nina Dental Care. Internal use only.
      </p>
    </div>

    <div class="flex items-center justify-center p-4 bg-elevated/50">
      <div class="w-full max-w-sm space-y-6">
        <div class="flex justify-center lg:hidden">
          <AppLogo />
        </div>
        <NuxtPage />
      </div>
    </div>
  </div>
</template>
