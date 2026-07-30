<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { Branch, CreatePaymentInput, DoctorDetail, PaginatedResponse, Patient, Payment, Promo, Reservation, Treatment } from '~/types/api'

definePageMeta({ title: 'Billing & Rekonsiliasi' })

const page = ref(1)
const pageSize = 10
const { data: paymentsPage, status, error, refresh } = useApiFetch<PaginatedResponse<Payment>>(() => `/payments?page=${page.value}&pageSize=${pageSize}`)
const payments = computed(() => paymentsPage.value?.data ?? [])

const { data: reservations } = useApiFetch<Reservation[]>('/reservations')
const { data: patients } = useApiFetch<Patient[]>('/patients')
const { data: branches } = useApiFetch<Branch[]>('/branches')
const { data: doctorsAdmin } = useApiFetch<DoctorDetail[]>('/doctors/admin')
const { data: treatments } = useApiFetch<Treatment[]>('/treatments')
const { data: promos } = useApiFetch<Promo[]>('/content/promos')

// KPI + chart panel: paid-only breakdown of the loaded page's own data isn't
// representative of the whole dataset once paginated, so these two draw
// from the full (unpaginated) recent history instead — cheap since it's
// capped by the dashboard's own revenue-trend endpoint.
const { data: trend } = useApiFetch<{ date: string, revenue: number }[]>('/admin/dashboard/revenue-trend?days=14')
const { data: methodBreakdown } = useApiFetch<{ method: string, revenue: number, count: number }[]>(() => {
  const to = new Date().toISOString().slice(0, 10)
  const from = new Date(Date.now() - 29 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10)
  return `/admin/reports/by-payment-method?from=${from}&to=${to}`
})

const methodLabelMap: Record<string, string> = {
  bank_transfer_bca: 'Transfer BCA',
  bank_transfer_bni: 'Transfer BNI',
  bank_transfer_mandiri: 'Transfer Mandiri',
  ewallet_ovo: 'OVO',
  ewallet_dana: 'DANA',
  ewallet_shopeepay: 'ShopeePay',
  qris: 'QRIS',
  cash: 'Tunai',
  manual_transfer: 'Transfer Manual',
  card: 'Kartu Debit/Kredit',
  lainnya: 'Lainnya'
}

const trendOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (trend.value ?? []).map(d => formatDateShort(d.date)) },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{ type: 'line', smooth: true, data: (trend.value ?? []).map(d => d.revenue), itemStyle: { color: CHART_PRIMARY }, lineStyle: { color: CHART_PRIMARY }, areaStyle: { color: 'rgba(37,99,235,0.15)' } }]
}))

const methodOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'item', valueFormatter: v => formatIDR(Number(v)) },
  legend: { bottom: 0 },
  series: [{
    type: 'pie',
    radius: ['40%', '70%'],
    data: (methodBreakdown.value ?? []).map((m, i) => ({ name: methodLabelMap[m.method] ?? m.method, value: m.revenue, itemStyle: { color: colorForIndex(i) } })),
    label: { formatter: '{b}: {d}%' }
  }]
}))

const columns = [
  { accessorKey: 'createdAt', header: 'Tanggal' },
  { accessorKey: 'patientName', header: 'Pasien' },
  { accessorKey: 'branchName', header: 'Cabang' },
  { accessorKey: 'amount', header: 'Jumlah' },
  { accessorKey: 'paymentMethod', header: 'Metode' },
  { accessorKey: 'status', header: 'Status' },
  { accessorKey: 'providerReference', header: 'Referensi' },
  { id: 'actions', header: '' }
]

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
  card: 'Kartu Debit/Kredit'
}

// --- POS checkout (new walk-in transaction) ---
const showPos = ref(false)
function onPosCompleted() {
  refresh()
}
// Closing the modal (X button or Esc) should also refresh the table in case
// a sale went through before it was closed.
watch(showPos, (open) => {
  if (!open) refresh()
})

// --- Pay an existing reservation (simple manual entry) ---
const MANUAL_METHODS = [
  { label: 'Tunai', value: 'cash' },
  { label: 'Transfer Manual', value: 'manual_transfer' },
  { label: 'QRIS (di tempat)', value: 'qris' }
]
const PAYMENT_STATUSES = [
  { label: 'Lunas', value: 'paid' },
  { label: 'Menunggu Pembayaran', value: 'pending' }
]

const showModal = ref(false)
const saving = ref(false)
const formError = ref('')
const form = reactive({
  reservationId: '',
  amount: 0,
  depositAmount: 0,
  paymentMethod: 'cash',
  status: 'paid'
})

function openCreate() {
  form.reservationId = ''
  form.amount = 0
  form.depositAmount = 100000
  form.paymentMethod = 'cash'
  form.status = 'paid'
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  if (!form.reservationId || form.amount <= 0) {
    formError.value = 'Reservasi dan jumlah pembayaran wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const payload: CreatePaymentInput = {
      reservationId: form.reservationId,
      amount: form.amount,
      depositAmount: form.depositAmount,
      paymentMethod: form.paymentMethod,
      status: form.status
    }
    await apiPost('/payments', payload as unknown as Record<string, unknown>)
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between flex-wrap gap-2">
      <div>
        <h1 class="text-xl font-semibold">
          Billing & Rekonsiliasi
        </h1>
        <p class="text-sm text-muted">
          Transaksi online (Xendit), kasir walk-in (POS), & pembayaran reservasi yang sudah ada.
        </p>
      </div>
      <div class="flex gap-2">
        <UButton
          icon="i-lucide-calendar-check"
          color="neutral"
          variant="soft"
          label="Bayar Reservasi"
          @click="openCreate"
        />
        <UButton
          icon="i-lucide-shopping-cart"
          label="Transaksi Baru (POS)"
          @click="showPos = true"
        />
      </div>
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Tren Revenue 14 Hari
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="!trend" />
        <ChartsEChart
          v-else
          :option="trendOption"
        />
      </UCard>
      <UCard>
        <template #header>
          <h2 class="font-medium">
            Metode Pembayaran (30 Hari)
          </h2>
        </template>
        <SkeletonChartSkeleton v-if="!methodBreakdown" />
        <ChartsEChart
          v-else
          :option="methodOption"
        />
      </UCard>
    </div>

    <UCard :ui="{ body: 'p-0 sm:p-0' }">
      <SkeletonTableSkeleton
        v-if="status === 'pending'"
        :columns="8"
      />
      <UTable
        v-else
        :data="payments"
        :columns="columns"
        class="cursor-pointer"
        @select="(_e, row) => navigateTo(`/billing/${row.original.id}`)"
      >
        <template #createdAt-cell="{ row }">
          {{ formatDateTime(row.original.createdAt) }}
        </template>
        <template #amount-cell="{ row }">
          {{ formatIDR(row.original.amount) }}
        </template>
        <template #paymentMethod-cell="{ row }">
          {{ row.original.paymentMethod ? (methodLabel[row.original.paymentMethod] ?? row.original.paymentMethod) : '—' }}
        </template>
        <template #status-cell="{ row }">
          <UBadge
            :color="paymentStatusColor(row.original.status)"
            variant="subtle"
          >
            {{ paymentStatusLabel(row.original.status) }}
          </UBadge>
        </template>
        <template #providerReference-cell="{ row }">
          <span class="font-mono text-xs">{{ row.original.providerReference ?? '—' }}</span>
        </template>
        <template #actions-cell="{ row }">
          <div
            class="flex justify-end gap-1"
            @click.stop
          >
            <UButton
              icon="i-lucide-eye"
              size="xs"
              color="neutral"
              variant="ghost"
              :to="`/billing/${row.original.id}`"
            />
            <UButton
              icon="i-lucide-printer"
              size="xs"
              color="neutral"
              variant="ghost"
              :to="`/billing/${row.original.id}/invoice`"
              target="_blank"
            />
          </div>
        </template>
      </UTable>
      <PaginationBar
        v-if="paymentsPage"
        :page="paymentsPage.page"
        :total-pages="paymentsPage.totalPages"
        :total="paymentsPage.total"
        :page-size="paymentsPage.pageSize"
        @update:page="page = $event"
      />
    </UCard>

    <!-- POS checkout -->
    <UModal
      v-model:open="showPos"
      title="Transaksi Baru (POS)"
      fullscreen
    >
      <template #body>
        <BillingPosCheckout
          :patients="patients ?? []"
          :branches="branches ?? []"
          :doctors-admin="doctorsAdmin ?? []"
          :treatments="treatments ?? []"
          :promos="promos ?? []"
          @completed="onPosCompleted"
        />
      </template>
    </UModal>

    <!-- Pay existing reservation -->
    <UModal
      v-model:open="showModal"
      title="Bayar Reservasi"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <UFormField
            label="Reservasi"
            required
          >
            <USelect
              v-model="form.reservationId"
              :items="(reservations ?? []).map(r => ({ label: `${r.patientName} — ${formatDateTime(r.scheduledAt)} (${reservationStatusLabel(r.status)})`, value: r.id }))"
              class="w-full"
              searchable
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Jumlah Dibayar"
              required
            >
              <UInput
                v-model.number="form.amount"
                type="number"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Deposit">
              <UInput
                v-model.number="form.depositAmount"
                type="number"
                class="w-full"
              />
            </UFormField>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Metode Pembayaran"
              required
            >
              <USelect
                v-model="form.paymentMethod"
                :items="MANUAL_METHODS"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Status"
              required
            >
              <USelect
                v-model="form.status"
                :items="PAYMENT_STATUSES"
                class="w-full"
              />
            </UFormField>
          </div>

          <UAlert
            v-if="formError"
            color="error"
            variant="subtle"
            :description="formError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showModal = false"
          />
          <UButton
            :loading="saving"
            label="Simpan"
            @click="onSubmit"
          />
        </div>
      </template>
    </UModal>
  </UContainer>
</template>
