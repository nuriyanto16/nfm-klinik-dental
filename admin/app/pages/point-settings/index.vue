<script setup lang="ts">
definePageMeta({ title: 'Pengaturan Point & Loyalty Reward' })

interface PointSettings {
  id: number
  pointsPerReservation: number
  pointsPerSpendIdr: number
  pointsEarnedPerSpend: number
  rupiahPerPoint: number
  minRedeemPoints: number
  updatedAt?: string
}

const { data: settings, pending, refresh } = await useApiFetch<PointSettings>('/admin/point-settings')

const form = ref<PointSettings>({
  id: 1,
  pointsPerReservation: 50,
  pointsPerSpendIdr: 10000,
  pointsEarnedPerSpend: 10,
  rupiahPerPoint: 100,
  minRedeemPoints: 50
})

watch(settings, (val) => {
  if (val) {
    form.value = { ...val }
  }
}, { immediate: true })

const saving = ref(false)

async function onSave() {
  saving.value = true
  try {
    await apiPut('/admin/point-settings', form.value as unknown as Record<string, unknown>)
    useAppNotification().success(
      'Aturan perolehan dan nilai tukar point berhasil diperbarui.',
      'Pengaturan Point Disimpan'
    )
    await refresh()
  } catch (err: any) {
    useAppNotification().error(
      err?.message || 'Terjadi kesalahan saat menyimpan pengaturan point.',
      'Gagal Menyimpan'
    )
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="p-6 max-w-4xl space-y-6">
    <!-- Header Card -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white flex items-center gap-2">
          <UIcon name="i-lucide-coins" class="w-7 h-7 text-amber-500" />
          Pengaturan Point & Loyalty Reward
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Konfigurasi perolehan poin pasien dari reservasi, kelipatan belanja, serta nilai konversi poin ke Rupiah.
        </p>
      </div>

      <UButton
        color="primary"
        icon="i-lucide-save"
        :loading="saving"
        @click="onSave"
      >
        Simpan Perubahan
      </UButton>
    </div>

    <!-- Form Section -->
    <UCard>
      <template #header>
        <div class="flex items-center gap-2 font-semibold text-gray-900 dark:text-white">
          <UIcon name="i-lucide-sliders" class="w-5 h-5 text-primary-500" />
          Aturan Perolehan & Penukaran Point
        </div>
      </template>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- 1. Point per Reservation -->
        <div class="p-4 rounded-xl bg-gray-50 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 space-y-2">
          <label class="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
            <UIcon name="i-lucide-calendar-check" class="w-4 h-4 text-emerald-500" />
            Poin per Reservasi Selesai
          </label>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            Jumlah poin otomatis yang didapat pasien setelah melakukan kunjungan / perawatan.
          </p>
          <div class="flex items-center gap-2 pt-2">
            <UInput
              v-model.number="form.pointsPerReservation"
              type="number"
              min="0"
              class="w-full"
            />
            <span class="text-sm font-semibold text-gray-600 dark:text-gray-300 shrink-0">Poin</span>
          </div>
        </div>

        <!-- 2. Points per Spend IDR -->
        <div class="p-4 rounded-xl bg-gray-50 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 space-y-2">
          <label class="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
            <UIcon name="i-lucide-receipt" class="w-4 h-4 text-blue-500" />
            Kelipatan Transaksi Belanja
          </label>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            Kelipatan nominal pembayaran (dalam Rupiah) untuk mendapatkan poin reward.
          </p>
          <div class="grid grid-cols-2 gap-2 pt-2">
            <div>
              <span class="text-xs text-gray-400">Kelipatan (Rp)</span>
              <CurrencyInput
                v-model="form.pointsPerSpendIdr"
              />
            </div>
            <div>
              <span class="text-xs text-gray-400">Dapat Poin</span>
              <UInput
                v-model.number="form.pointsEarnedPerSpend"
                type="number"
                min="0"
              />
            </div>
          </div>
        </div>

        <!-- 3. Rupiah Value per Point -->
        <div class="p-4 rounded-xl bg-gray-50 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 space-y-2">
          <label class="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
            <UIcon name="i-lucide-banknote" class="w-4 h-4 text-amber-500" />
            Nilai Konversi 1 Poin (IDR)
          </label>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            Nilai tukar Rupiah dari 1 poin pasien saat digunakan sebagai diskon atau voucher.
          </p>
          <div class="flex items-center gap-2 pt-2">
            <span class="text-sm font-semibold text-gray-600 dark:text-gray-300">Rp</span>
            <CurrencyInput
              v-model="form.rupiahPerPoint"
              class="w-full"
            />
          </div>
        </div>

        <!-- 4. Min Redeem Points -->
        <div class="p-4 rounded-xl bg-gray-50 dark:bg-gray-800/50 border border-gray-200 dark:border-gray-700 space-y-2">
          <label class="text-xs font-bold uppercase tracking-wider text-gray-500 dark:text-gray-400 flex items-center gap-1.5">
            <UIcon name="i-lucide-shield-alert" class="w-4 h-4 text-purple-500" />
            Minimal Poin Penukaran
          </label>
          <p class="text-xs text-gray-500 dark:text-gray-400">
            Batas minimal poin yang harus dimiliki pasien sebelum bisa ditukarkan.
          </p>
          <div class="flex items-center gap-2 pt-2">
            <UInput
              v-model.number="form.minRedeemPoints"
              type="number"
              min="0"
              class="w-full"
            />
            <span class="text-sm font-semibold text-gray-600 dark:text-gray-300 shrink-0">Poin</span>
          </div>
        </div>
      </div>
    </UCard>

    <!-- Preview Calculation Card -->
    <UCard class="bg-gradient-to-r from-amber-500/10 via-amber-500/5 to-transparent border-amber-500/30">
      <div class="flex items-start gap-4">
        <div class="p-3 rounded-full bg-amber-500/20 text-amber-600 dark:text-amber-400">
          <UIcon name="i-lucide-calculator" class="w-6 h-6" />
        </div>
        <div class="space-y-1">
          <h3 class="font-bold text-gray-900 dark:text-white text-base">Simulasi Perhitungan Poin</h3>
          <p class="text-xs text-gray-600 dark:text-gray-300">
            • Jika pasien melakukan reservasi & transaksi sebesar <strong class="text-amber-600">Rp 150.000</strong>:
          </p>
          <ul class="text-xs text-gray-600 dark:text-gray-300 list-disc list-inside pl-2 space-y-1">
            <li>Bonus Reservasi: <strong>+{{ form.pointsPerReservation }} Poin</strong></li>
            <li>Bonus Belanja: <strong>+{{ Math.floor(150000 / (form.pointsPerSpendIdr || 1)) * form.pointsEarnedPerSpend }} Poin</strong> ({{ 150000 / (form.pointsPerSpendIdr || 1) }}x kelipatan Rp {{ form.pointsPerSpendIdr?.toLocaleString() }})</li>
            <li>Total Diterima: <strong class="text-emerald-600 dark:text-emerald-400">{{ form.pointsPerReservation + (Math.floor(150000 / (form.pointsPerSpendIdr || 1)) * form.pointsEarnedPerSpend) }} Poin</strong></li>
            <li>Nilai Penukaran (Rupiah): <strong>Rp {{ ((form.pointsPerReservation + (Math.floor(150000 / (form.pointsPerSpendIdr || 1)) * form.pointsEarnedPerSpend)) * form.rupiahPerPoint).toLocaleString() }}</strong></li>
          </ul>
        </div>
      </div>
    </UCard>
  </div>
</template>
