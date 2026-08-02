<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { BranchRevenue, DailyRevenue, DashboardSummary, Payment, Reservation, StatusCount, TreatmentCount } from '~/types/api'

definePageMeta({ title: 'Dashboard' })

const { data: summary, status: summaryStatus, error } = useApiFetch<DashboardSummary>('/admin/dashboard')
const { data: trend, status: trendStatus } = useApiFetch<DailyRevenue[]>('/admin/dashboard/revenue-trend?days=14')
const { data: statusCounts, status: statusCountsStatus } = useApiFetch<StatusCount[]>('/admin/dashboard/reservations-by-status')
const { data: branchRevenue, status: branchRevenueStatus } = useApiFetch<BranchRevenue[]>('/admin/dashboard/revenue-by-branch')
const { data: topTreatments, status: topTreatmentsStatus } = useApiFetch<TreatmentCount[]>('/admin/dashboard/top-treatments')
const { data: reservations, status: reservationsStatus } = useApiFetch<Reservation[]>('/reservations')
const { data: payments, status: paymentsStatus } = useApiFetch<Payment[]>('/payments')

const { followUpList, markAsReminded, getWhatsAppLink } = useFollowUpPatients()

const kpis = computed(() => [
  { label: 'Reservasi Hari Ini', value: summary.value?.reservationsToday ?? '—', icon: 'i-lucide-calendar-check', hint: 'Semua cabang' },
  { label: 'Revenue Hari Ini', value: summary.value ? formatIDR(summary.value.revenueToday) : '—', icon: 'i-lucide-banknote', hint: 'Status lunas' },
  { label: 'Revenue Bulan Ini', value: summary.value ? formatIDR(summary.value.revenueThisMonth) : '—', icon: 'i-lucide-wallet', hint: 'Bulan berjalan' },
  { label: 'Antrian Aktif', value: summary.value?.activeQueue ?? '—', icon: 'i-lucide-users-round', hint: 'Soreang & Baleendah' },
  { label: 'Tingkat Kehadiran', value: summary.value ? `${summary.value.attendanceRate7d.toFixed(0)}%` : '—', icon: 'i-lucide-percent', hint: '7 hari terakhir' },
  { label: 'Total Pasien', value: summary.value?.totalPatients ?? '—', icon: 'i-lucide-users', hint: 'Termasuk anggota keluarga' }
])

const trendOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (trend.value ?? []).map(d => formatDateShort(d.date)), axisTick: { show: false } },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{
    type: 'line',
    data: (trend.value ?? []).map(d => d.revenue),
    smooth: true,
    symbol: 'circle',
    symbolSize: 6,
    itemStyle: { color: CHART_PRIMARY },
    lineStyle: { width: 2, color: CHART_PRIMARY },
    areaStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: 'rgba(37,99,235,0.25)' }, { offset: 1, color: 'rgba(37,99,235,0)' }] } }
  }]
}))

const statusOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (statusCounts.value ?? []).map(s => reservationStatusLabel(s.status)), axisLabel: { rotate: 20 } },
  yAxis: { type: 'value', splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{ type: 'bar', data: (statusCounts.value ?? []).map(s => s.count), itemStyle: { color: CHART_PRIMARY, borderRadius: [4, 4, 0, 0] }, barMaxWidth: 36 }]
}))

const branchOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (branchRevenue.value ?? []).map(b => b.branchName) },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{ type: 'bar', data: (branchRevenue.value ?? []).map(b => b.revenue), itemStyle: { color: CHART_PRIMARY, borderRadius: [4, 4, 0, 0] }, barMaxWidth: 60 }]
}))

const treatmentOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
  grid: { left: 8, right: 24, top: 8, bottom: 8, containLabel: true },
  xAxis: { type: 'value', splitLine: { lineStyle: { type: 'dashed' } } },
  yAxis: { type: 'category', data: (topTreatments.value ?? []).map(t => t.treatmentName).reverse(), axisTick: { show: false } },
  series: [{ type: 'bar', data: (topTreatments.value ?? []).map(t => t.bookingCount).reverse(), itemStyle: { color: CHART_PRIMARY, borderRadius: [0, 4, 4, 0] }, barMaxWidth: 22 }]
}))

const recentReservations = computed(() => (reservations.value ?? []).slice(0, 5))
const recentPayments = computed(() => (payments.value ?? []).slice(0, 5))

const reservationColumns = [
  { accessorKey: 'scheduledAt', header: 'Jadwal' },
  { accessorKey: 'patientName', header: 'Pasien' },
  { accessorKey: 'status', header: 'Status' }
]
const paymentColumns = [
  { accessorKey: 'createdAt', header: 'Tanggal' },
  { accessorKey: 'patientName', header: 'Pasien' },
  { accessorKey: 'amount', header: 'Jumlah' },
  { accessorKey: 'status', header: 'Status' }
]
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <div>
      <h1 class="text-xl font-semibold">
        Dashboard
      </h1>
      <p class="text-sm text-muted">
        Ringkasan operasional Nina Dental Care — Soreang & Baleendah.
      </p>
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <!-- KPI Row -->
    <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
      <div
        v-for="kpi in kpis"
        :key="kpi.label"
        class="p-3 rounded-xl border border-default bg-card shadow-xs flex flex-col justify-between"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs text-muted font-medium">{{ kpi.label }}</span>
          <UIcon
            :name="kpi.icon"
            class="w-4 h-4 text-primary"
          />
        </div>
        <div class="mt-2">
          <SkeletonTextSkeleton
            v-if="summaryStatus === 'pending'"
            class="h-7 w-20"
          />
          <p
            v-else
            class="text-lg font-bold text-gray-900 dark:text-white"
          >
            {{ kpi.value }}
          </p>
          <span class="text-[10px] text-muted">{{ kpi.hint }}</span>
        </div>
      </div>
    </div>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-4">
      <UCard class="lg:col-span-8">
        <template #header>
          <div class="flex items-center justify-between">
            <div>
              <h2 class="font-medium text-sm">
                Revenue 14 Hari Terakhir
              </h2>
              <p class="text-xs text-muted">
                Trend pendapatan harian gabungan cabang
              </p>
            </div>
          </div>
        </template>
        <SkeletonChartSkeleton v-if="trendStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="trendOption"
          height="220px"
        />
      </UCard>

      <UCard class="lg:col-span-4">
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="font-medium text-sm">
              Status Reservasi
            </h2>
          </div>
        </template>
        <SkeletonChartSkeleton v-if="statusCountsStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="statusOption"
          height="220px"
        />
      </UCard>
    </div>

    <!-- Additional Charts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Revenue per Cabang
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="branchRevenueStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="branchOption"
        />
      </UCard>

      <UCard>
        <template #header>
          <h2 class="font-medium">
            Perawatan Terlaris
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="topTreatmentsStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="treatmentOption"
        />
      </UCard>
    </div>

    <!-- Recent Tables Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="font-medium">
              Reservasi Terbaru
            </h2>
            <UButton
              to="/reservations"
              variant="link"
              size="xs"
              label="Lihat semua"
              trailing-icon="i-lucide-arrow-right"
            />
          </div>
        </template>
        <SkeletonTableSkeleton
          v-if="reservationsStatus === 'pending'"
          :rows="5"
          :columns="3"
        />
        <UTable
          v-else
          :data="recentReservations"
          :columns="reservationColumns"
        >
          <template #scheduledAt-cell="{ row }">
            {{ formatDateTime(row.original.scheduledAt) }}
          </template>
          <template #status-cell="{ row }">
            <UBadge
              :color="reservationStatusColor(row.original.status)"
              variant="subtle"
            >
              {{ reservationStatusLabel(row.original.status) }}
            </UBadge>
          </template>
        </UTable>
      </UCard>

      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="font-medium">
              Transaksi Terbaru
            </h2>
            <UButton
              to="/billing"
              variant="link"
              size="xs"
              label="Lihat semua"
              trailing-icon="i-lucide-arrow-right"
            />
          </div>
        </template>
        <SkeletonTableSkeleton
          v-if="paymentsStatus === 'pending'"
          :rows="5"
          :columns="4"
        />
        <UTable
          v-else
          :data="recentPayments"
          :columns="paymentColumns"
        >
          <template #createdAt-cell="{ row }">
            {{ formatDateTime(row.original.createdAt) }}
          </template>
          <template #amount-cell="{ row }">
            {{ formatIDR(row.original.amount) }}
          </template>
          <template #status-cell="{ row }">
            <UBadge
              :color="paymentStatusColor(row.original.status)"
              variant="subtle"
            >
              {{ paymentStatusLabel(row.original.status) }}
            </UBadge>
          </template>
        </UTable>
      </UCard>
    </div>

    <!-- Panel Pasien Rekomendasi Kontrol & Tindak Lanjut (Paling Bawah) -->
    <UCard class="bg-white dark:bg-gray-800 border-l-4 border-l-amber-500 shadow-xs">
      <template #header>
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-2">
            <UIcon name="i-lucide-bell-ring" class="w-5 h-5 text-amber-500 animate-pulse" />
            <div>
              <h2 class="font-bold text-sm text-gray-900 dark:text-white">
                Rekomendasi Kontrol Pasien & Tindak Lanjut Terdekat
              </h2>
              <p class="text-xs text-gray-500">
                Daftar pasien yang terdeteksi dari riwayat medis perlu melakukan jadwal kontrol dalam beberapa hari ke depan.
              </p>
            </div>
          </div>
          <UBadge color="amber" variant="subtle" size="xs">
            {{ followUpList.length }} Pasien Siap Dikontak
          </UBadge>
        </div>
      </template>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <div
          v-for="fu in followUpList"
          :key="fu.id"
          class="p-3 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-900/40 space-y-2"
        >
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <span class="font-bold text-xs text-gray-900 dark:text-white">{{ fu.patientName }}</span>
              <UBadge color="neutral" variant="outline" size="xs">{{ fu.rmNumber }}</UBadge>
            </div>
            <UBadge :color="fu.daysRemaining <= 1 ? 'error' : 'warning'" variant="soft" size="xs">
              {{ fu.daysRemaining === 1 ? 'Besok Kontrol' : `${fu.daysRemaining} Hari Lagi` }}
            </UBadge>
          </div>

          <div class="text-xs text-gray-600 dark:text-gray-300 space-y-0.5">
            <div><span class="text-gray-400">Rekomendasi:</span> <b>{{ fu.controlReason }}</b></div>
            <div><span class="text-gray-400">Treatment Sebelumnya:</span> {{ fu.treatmentName }}</div>
            <div><span class="text-gray-400">Tgl Kontrol Terdekat:</span> <span class="font-semibold text-primary">{{ fu.recommendedControlDate }}</span> ({{ fu.doctorName }})</div>
          </div>

          <div class="flex items-center justify-between pt-2 border-t border-gray-200 dark:border-gray-700">
            <span class="text-[11px] font-mono text-gray-400">{{ fu.phoneWa }}</span>
            <a
              :href="getWhatsAppLink(fu)"
              target="_blank"
              class="inline-flex items-center gap-1 text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline"
              @click="markAsReminded(fu.id)"
            >
              <UIcon name="i-lucide-send" class="w-3.5 h-3.5" />
              <span>{{ fu.status === 'REMINDED' ? 'Kirim Ulang WA' : 'Kirim Reminder WA' }}</span>
            </a>
          </div>
        </div>
      </div>
    </UCard>

    <!-- Charts Row -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-4">
      <UCard class="lg:col-span-8">
        <template #header>
          <div class="flex items-center justify-between">
            <div>
              <h2 class="font-medium text-sm">
                Revenue 14 Hari Terakhir
              </h2>
              <p class="text-xs text-muted">
                Trend pendapatan harian gabungan cabang
              </p>
            </div>
          </div>
        </template>
        <SkeletonChartSkeleton v-if="trendStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="trendOption"
          height="220px"
        />
      </UCard>

      <UCard class="lg:col-span-4">
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="font-medium text-sm">
              Status Reservasi
            </h2>
          </div>
        </template>
        <SkeletonChartSkeleton v-if="statusCountsStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="statusOption"
          height="220px"
        />
      </UCard>
    </div>

    <!-- Additional Charts -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Revenue per Cabang
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="branchRevenueStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="branchOption"
        />
      </UCard>

      <UCard>
        <template #header>
          <h2 class="font-medium">
            Perawatan Terlaris
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="topTreatmentsStatus === 'pending'" />
        <ChartsEChart
          v-else
          :option="treatmentOption"
        />
      </UCard>
    </div>

    <!-- Recent Tables Row -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="font-medium">
              Reservasi Terbaru
            </h2>
            <UButton
              to="/reservations"
              variant="link"
              size="xs"
              label="Lihat semua"
              trailing-icon="i-lucide-arrow-right"
            />
          </div>
        </template>
        <SkeletonTableSkeleton
          v-if="reservationsStatus === 'pending'"
          :rows="5"
          :columns="3"
        />
        <UTable
          v-else
          :data="recentReservations"
          :columns="reservationColumns"
        >
          <template #scheduledAt-cell="{ row }">
            {{ formatDateTime(row.original.scheduledAt) }}
          </template>
          <template #status-cell="{ row }">
            <UBadge
              :color="reservationStatusColor(row.original.status)"
              variant="subtle"
            >
              {{ reservationStatusLabel(row.original.status) }}
            </UBadge>
          </template>
        </UTable>
      </UCard>

      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="font-medium">
              Transaksi Terbaru
            </h2>
            <UButton
              to="/billing"
              variant="link"
              size="xs"
              label="Lihat semua"
              trailing-icon="i-lucide-arrow-right"
            />
          </div>
        </template>
        <SkeletonTableSkeleton
          v-if="paymentsStatus === 'pending'"
          :rows="5"
          :columns="4"
        />
        <UTable
          v-else
          :data="recentPayments"
          :columns="paymentColumns"
        >
          <template #createdAt-cell="{ row }">
            {{ formatDateTime(row.original.createdAt) }}
          </template>
          <template #amount-cell="{ row }">
            {{ formatIDR(row.original.amount) }}
          </template>
          <template #status-cell="{ row }">
            <UBadge
              :color="paymentStatusColor(row.original.status)"
              variant="subtle"
            >
              {{ paymentStatusLabel(row.original.status) }}
            </UBadge>
          </template>
        </UTable>
      </UCard>
    </div>
  </div>
</template>
