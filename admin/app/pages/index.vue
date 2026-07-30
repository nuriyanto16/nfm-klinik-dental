<script setup lang="ts">
import type { BranchRevenue, DailyRevenue, DashboardSummary, Payment, Reservation, StatusCount, TreatmentCount } from '~/types/api'

definePageMeta({ title: 'Dashboard' })

const { data: summary, status: summaryStatus, error } = useApiFetch<DashboardSummary>('/admin/dashboard')
const { data: trend, status: trendStatus } = useApiFetch<DailyRevenue[]>('/admin/dashboard/revenue-trend?days=7')
const { data: statusCounts, status: statusCountsStatus } = useApiFetch<StatusCount[]>('/admin/dashboard/reservations-by-status')
const { data: branchRevenue, status: branchRevenueStatus } = useApiFetch<BranchRevenue[]>('/admin/dashboard/revenue-by-branch')
const { data: topTreatments, status: topTreatmentsStatus } = useApiFetch<TreatmentCount[]>('/admin/dashboard/top-treatments')
const { data: reservations, status: reservationsStatus } = useApiFetch<Reservation[]>('/reservations')
const { data: payments, status: paymentsStatus } = useApiFetch<Payment[]>('/payments')

const kpis = computed(() => [
  { label: 'Reservasi Hari Ini', value: summary.value?.reservationsToday ?? '—', icon: 'i-lucide-calendar-check', hint: 'Semua cabang' },
  { label: 'Revenue Hari Ini', value: summary.value ? formatIDR(summary.value.revenueToday) : '—', icon: 'i-lucide-banknote', hint: 'Status lunas' },
  { label: 'Revenue Bulan Ini', value: summary.value ? formatIDR(summary.value.revenueThisMonth) : '—', icon: 'i-lucide-wallet', hint: 'Bulan berjalan' },
  { label: 'Antrian Aktif', value: summary.value?.activeQueue ?? '—', icon: 'i-lucide-users-round', hint: 'Soreang & Baleendah' },
  { label: 'Tingkat Kehadiran', value: summary.value ? `${summary.value.attendanceRate7d.toFixed(0)}%` : '—', icon: 'i-lucide-percent', hint: '7 hari terakhir' },
  { label: 'Total Pasien', value: summary.value?.totalPatients ?? '—', icon: 'i-lucide-users', hint: 'Termasuk anggota keluarga' }
])

const statusItems = computed(() => (statusCounts.value ?? []).map(s => ({ label: reservationStatusLabel(s.status), value: s.count })))
const branchItems = computed(() => (branchRevenue.value ?? []).map(b => ({ label: b.branchName, value: b.revenue })))
const treatmentItems = computed(() => (topTreatments.value ?? []).map(t => ({ label: t.treatmentName, value: t.bookingCount })))

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
  <UContainer class="py-6 space-y-6">
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

    <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
      <template v-if="summaryStatus === 'pending'">
        <SkeletonStatCardSkeleton
          v-for="i in 6"
          :key="i"
        />
      </template>
      <UPageCard
        v-for="kpi in kpis"
        v-else
        :key="kpi.label"
        :title="String(kpi.value)"
        :description="kpi.label"
        :icon="kpi.icon"
      >
        <template #footer>
          <span class="text-xs text-muted">{{ kpi.hint }}</span>
        </template>
      </UPageCard>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Revenue 7 Hari Terakhir
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="trendStatus === 'pending'" />
        <ChartsTrendChart
          v-else
          :points="trend ?? []"
        />
      </UCard>

      <UCard>
        <template #header>
          <h2 class="font-medium">
            Reservasi per Status
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="statusCountsStatus === 'pending'" />
        <ChartsBarChart
          v-else
          :items="statusItems"
        />
      </UCard>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Revenue per Cabang
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="branchRevenueStatus === 'pending'" />
        <ChartsBarChart
          v-else
          :items="branchItems"
          :format-value="formatIDR"
        />
      </UCard>

      <UCard>
        <template #header>
          <h2 class="font-medium">
            Perawatan Terlaris
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="topTreatmentsStatus === 'pending'" />
        <ChartsBarChart
          v-else
          :items="treatmentItems"
        />
      </UCard>
    </div>

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
  </UContainer>
</template>
