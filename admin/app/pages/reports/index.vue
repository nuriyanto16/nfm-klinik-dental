<script setup lang="ts">
import type { BranchRevenue, DailyRevenue, FinancialSummary, PaymentMethodRevenue } from '~/types/api'

definePageMeta({ title: 'Laporan Keuangan' })

function toDateInput(d: Date) {
  return d.toISOString().slice(0, 10)
}
const today = new Date()
const thirtyDaysAgo = new Date(today.getTime() - 29 * 24 * 60 * 60 * 1000)

const range = reactive({ from: toDateInput(thirtyDaysAgo), to: toDateInput(today) })

const summary = ref<FinancialSummary | null>(null)
const trend = ref<DailyRevenue[]>([])
const byMethod = ref<PaymentMethodRevenue[]>([])
const byBranch = ref<BranchRevenue[]>([])
const loading = ref(false)
const loadError = ref('')

async function loadReports() {
  loading.value = true
  loadError.value = ''
  try {
    const qs = `from=${range.from}&to=${range.to}`
    const [s, t, m, b] = await Promise.all([
      $fetch<FinancialSummary>(apiUrl(`/admin/reports/summary?${qs}`)),
      $fetch<DailyRevenue[]>(apiUrl(`/admin/reports/revenue-trend?${qs}`)),
      $fetch<PaymentMethodRevenue[]>(apiUrl(`/admin/reports/by-payment-method?${qs}`)),
      $fetch<BranchRevenue[]>(apiUrl('/admin/dashboard/revenue-by-branch'))
    ])
    summary.value = s
    trend.value = t
    byMethod.value = m
    byBranch.value = b
  } catch (err) {
    loadError.value = apiErrorMessage(err)
  } finally {
    loading.value = false
  }
}

onMounted(loadReports)

const methodLabel: Record<string, string> = {
  bank_transfer_bca: 'Transfer BCA',
  bank_transfer_bni: 'Transfer BNI',
  bank_transfer_mandiri: 'Transfer Mandiri',
  ewallet_ovo: 'OVO',
  ewallet_dana: 'DANA',
  ewallet_shopeepay: 'ShopeePay',
  qris: 'QRIS',
  cash: 'Tunai',
  manual_transfer: 'Transfer Manual',
  lainnya: 'Lainnya'
}
const methodItems = computed(() => byMethod.value.map(m => ({ label: methodLabel[m.method] ?? m.method, value: m.revenue })))
const branchItems = computed(() => byBranch.value.map(b => ({ label: b.branchName, value: b.revenue })))
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-xl font-semibold">
          Laporan Keuangan
        </h1>
        <p class="text-sm text-muted">
          Ringkasan transaksi (online Xendit + manual/tunai) per periode.
        </p>
      </div>
      <div class="flex items-end gap-2">
        <UFormField label="Dari">
          <UInput
            v-model="range.from"
            type="date"
          />
        </UFormField>
        <UFormField label="Sampai">
          <UInput
            v-model="range.to"
            type="date"
          />
        </UFormField>
        <UButton
          icon="i-lucide-refresh-cw"
          label="Terapkan"
          :loading="loading"
          @click="loadReports"
        />
      </div>
    </div>

    <UAlert
      v-if="loadError"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat laporan"
      :description="loadError"
    />

    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <template v-if="loading && !summary">
        <SkeletonStatCardSkeleton
          v-for="i in 4"
          :key="i"
        />
      </template>
      <template v-else>
        <UPageCard
          :title="summary ? formatIDR(summary.totalRevenue) : '—'"
          description="Total Revenue (Lunas)"
          icon="i-lucide-banknote"
        />
        <UPageCard
          :title="String(summary?.totalTransactions ?? '—')"
          description="Jumlah Transaksi Lunas"
          icon="i-lucide-receipt"
        />
        <UPageCard
          :title="summary ? formatIDR(summary.avgTransaction) : '—'"
          description="Rata-rata per Transaksi"
          icon="i-lucide-calculator"
        />
        <UPageCard
          :title="summary ? formatIDR(summary.totalRefunded) : '—'"
          description="Total Dikembalikan (Refund)"
          icon="i-lucide-undo-2"
        />
      </template>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Tren Revenue Harian
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="loading && !trend.length" />
        <ChartsTrendChart
          v-else
          :points="trend"
        />
      </UCard>
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Revenue per Metode Pembayaran
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="loading && !byMethod.length" />
        <ChartsBarChart
          v-else
          :items="methodItems"
          :format-value="formatIDR"
        />
      </UCard>
    </div>

    <UCard>
      <template #header>
        <h2 class="font-medium">
          Revenue per Cabang (Keseluruhan)
        </h2>
      </template>
      <SkeletonChartSkeleton v-if="loading && !byBranch.length" />
      <ChartsBarChart
        v-else
        :items="branchItems"
        :format-value="formatIDR"
      />
    </UCard>
  </UContainer>
</template>
