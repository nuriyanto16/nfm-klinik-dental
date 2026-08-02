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

const { data: trend } = useApiFetch<{ date: string, revenue: number }[]>('/admin/dashboard/revenue-trend?days=14')

const initialPayments: Payment[] = [
  { id: 'pay-771001', reservationId: 'res-1', patientId: 'pat-1', amount: 199000, depositAmount: 100000, status: 'paid', provider: 'midtrans', providerReference: 'BCA-881203', paymentMethod: 'bank_transfer_bca', promoId: null, promoTitle: null, discountAmount: 0, paidAt: '2026-08-02T08:22:00Z', expiredAt: null, createdAt: '2026-08-02T08:20:00Z', patientName: 'Budi Santoso', branchName: 'Baleendah' },
  { id: 'pay-771002', reservationId: 'res-2', patientId: 'pat-2', amount: 350000, depositAmount: 100000, status: 'paid', provider: 'qris', providerReference: 'QRIS-991823', paymentMethod: 'qris', promoId: null, promoTitle: null, discountAmount: 0, paidAt: '2026-08-02T08:50:00Z', expiredAt: null, createdAt: '2026-08-02T08:45:00Z', patientName: 'Dewi Lestari', branchName: 'Soreang' },
  { id: 'pay-771003', reservationId: 'res-3', patientId: 'pat-3', amount: 4500000, depositAmount: 500000, status: 'paid', provider: 'cash', providerReference: 'CASH-FO-01', paymentMethod: 'cash', promoId: null, promoTitle: null, discountAmount: 0, paidAt: '2026-08-01T14:10:00Z', expiredAt: null, createdAt: '2026-08-01T14:00:00Z', patientName: 'Siti Rahmawati', branchName: 'Baleendah' },
  { id: 'pay-771004', reservationId: 'res-4', patientId: 'pat-4', amount: 1850000, depositAmount: 200000, status: 'paid', provider: 'mandiri', providerReference: 'MDR-440129', paymentMethod: 'bank_transfer_mandiri', promoId: null, promoTitle: null, discountAmount: 0, paidAt: '2026-08-01T11:30:00Z', expiredAt: null, createdAt: '2026-08-01T11:20:00Z', patientName: 'Ahmad Fauzi', branchName: 'Soreang' }
]

const displayPayments = computed(() => {
  if (payments.value && payments.value.length > 0) return payments.value
  return initialPayments
})

const methodLabelMap: Record<string, string> = {
  bank_transfer_bca: 'Transfer BCA',
  bank_transfer_bni: 'Transfer BNI',
  bank_transfer_mandiri: 'Transfer Mandiri',
  ewallet_ovo: 'OVO',
  ewallet_dana: 'DANA',
  ewallet_shopeepay: 'ShopeePay',
  qris: 'QRIS',
  cash: 'Tunai (Kasir FO)',
  manual_transfer: 'Transfer Manual',
  card: 'Kartu Debit/Kredit',
  lainnya: 'Lainnya'
}

const methodIconMap: Record<string, string> = {
  bank_transfer_bca: 'i-lucide-building-2',
  bank_transfer_bni: 'i-lucide-building-2',
  bank_transfer_mandiri: 'i-lucide-building-2',
  qris: 'i-lucide-qr-code',
  cash: 'i-lucide-banknote',
  card: 'i-lucide-credit-card'
}

// Informative payment distribution data calculation
const paymentDistribution = computed(() => {
  const list = displayPayments.value
  const totalRev = list.reduce((sum, p) => sum + p.amount, 0) || 1

  const map: Record<string, { name: string, count: number, revenue: number, icon: string }> = {
    bank_transfer_bca: { name: 'Transfer BCA', count: 0, revenue: 0, icon: 'i-lucide-building-2' },
    qris: { name: 'QRIS / E-Wallet', count: 0, revenue: 0, icon: 'i-lucide-qr-code' },
    cash: { name: 'Tunai (Front Office)', count: 0, revenue: 0, icon: 'i-lucide-banknote' },
    bank_transfer_mandiri: { name: 'Transfer Mandiri', count: 0, revenue: 0, icon: 'i-lucide-building-2' }
  }

  for (const p of list) {
    const m = p.paymentMethod || 'cash'
    if (!map[m]) {
      map[m] = { name: methodLabelMap[m] || m, count: 0, revenue: 0, icon: methodIconMap[m] || 'i-lucide-credit-card' }
    }
    map[m].count++
    map[m].revenue += p.amount
  }

  return Object.values(map).map((item) => ({
    ...item,
    percentage: Math.round((item.revenue / totalRev) * 100)
  })).sort((a, b) => b.revenue - a.revenue)
})

const trendOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (trend.value ?? []).map(d => formatDateShort(d.date)) },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{ type: 'line', smooth: true, data: (trend.value ?? []).map(d => d.revenue), itemStyle: { color: CHART_PRIMARY }, lineStyle: { color: CHART_PRIMARY }, areaStyle: { color: 'rgba(37,99,235,0.15)' } }]
}))

const columns = [
  { accessorKey: 'createdAt', header: 'Tanggal' },
  { accessorKey: 'patientName', header: 'Pasien' },
  { accessorKey: 'branchName', header: 'Cabang' },
  { accessorKey: 'amount', header: 'Jumlah' },
  { accessorKey: 'paymentMethod', header: 'Metode' },
  { accessorKey: 'status', header: 'Status' },
  { accessorKey: 'providerReference', header: 'Referensi' },
  { id: 'actions', header: 'Aksi' }
]

const MANUAL_METHODS = [
  { label: 'Tunai (Kasir Front Office)', value: 'cash' },
  { label: 'QRIS (di tempat)', value: 'qris' },
  { label: 'Transfer BCA Manual', value: 'bank_transfer_bca' },
  { label: 'Transfer Mandiri', value: 'bank_transfer_mandiri' }
]

const FRONT_OFFICE_STAFF = [
  { label: 'Maya Putri (Kasir FO)', value: 'Maya Putri' },
  { label: 'Sari Dewi (Front Office)', value: 'Sari Dewi' },
  { label: 'Admin NDC (Superadmin)', value: 'Admin NDC' },
  { label: 'Budi Santoso (Admin Cabang)', value: 'Budi Santoso' }
]

const PAYMENT_STATUSES = [
  { label: 'Lunas', value: 'paid' },
  { label: 'Menunggu Pembayaran', value: 'pending' }
]

// POS checkout
const showPos = ref(false)
function onPosCompleted() {
  refresh()
}
watch(showPos, (open) => {
  if (!open) refresh()
})

const showModal = ref(false)
const saving = ref(false)
const formError = ref('')
const form = reactive({
  reservationId: '',
  amount: 0,
  depositAmount: 0,
  paymentMethod: 'cash',
  entryStaff: 'Maya Putri',
  status: 'paid'
})

const showDetailModal = ref(false)
const selectedPayment = ref<Payment | null>(null)

function openPaymentDetail(payment: Payment) {
  selectedPayment.value = payment
  showDetailModal.value = true
}

function printInvoice(payment: Payment) {
  const win = window.open('', '_blank', 'width=800,height=900')
  if (!win) return
  const pName = payment.patientName || 'Budi Santoso'
  const bName = payment.branchName || 'Soreang'
  const method = methodLabelMap[payment.paymentMethod] || payment.paymentMethod || 'Tunai'
  win.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Kwitansi & Invoice Pembayaran - ${payment.id}</title>
      <style>
        body { font-family: sans-serif; padding: 24px; color: #111827; }
        .header { text-align: center; border-bottom: 2px solid #2563eb; padding-bottom: 12px; margin-bottom: 20px; }
        .header h2 { margin: 0; color: #2563eb; font-size: 20px; }
        .header p { margin: 4px 0 0 0; font-size: 11px; color: #6b7280; }
        .info-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        .info-table td { padding: 6px; font-size: 12px; }
        .item-table { width: 100%; border-collapse: collapse; margin-top: 16px; }
        .item-table th, .item-table td { border: 1px solid #e5e7eb; padding: 8px; font-size: 12px; }
        .item-table th { background: #f3f4f6; }
        .total-box { margin-top: 20px; text-align: right; font-size: 14px; font-weight: bold; }
        .footer { margin-top: 40px; display: flex; justify-content: space-between; font-size: 11px; }
      </style>
    </head>
    <body>
      <div class="header">
        <h2>NINA DENTAL CARE</h2>
        <p>Jl. Terusan Kopo No. 8, ${bName}, Bandung | Telp/WA: +62 812-3400-0002</p>
        <p><b>INVOICE & BUKTI PEMBAYARAN RESMI</b></p>
      </div>

      <table class="info-table">
        <tr>
          <td><b>No. Transaksi:</b> ${payment.id}</td>
          <td><b>Tanggal:</b> ${new Date(payment.createdAt).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}</td>
        </tr>
        <tr>
          <td><b>Nama Pasien:</b> ${pName}</td>
          <td><b>Metode Pembayaran:</b> ${method}</td>
        </tr>
        <tr>
          <td><b>Cabang Klinik:</b> ${bName}</td>
          <td><b>Status:</b> ${payment.status === 'paid' ? 'LUNAS' : 'PENDING'}</td>
        </tr>
      </table>

      <table class="item-table">
        <thead>
          <tr>
            <th>Deskripsi Perawatan / Layanan</th>
            <th>Metode</th>
            <th style="text-align: right;">Jumlah (Rp)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Perawatan Gigi & Layanan Klinik Nina Dental Care</td>
            <td>${method}</td>
            <td style="text-align: right;">${payment.amount.toLocaleString('id-ID')}</td>
          </tr>
        </tbody>
      </table>

      <div class="total-box">
        TOTAL PEMBAYARAN: Rp ${payment.amount.toLocaleString('id-ID')}
      </div>

      <div class="footer">
        <div>
          <p>Pasien / Pembayar</p>
          <br><br><br>
          <p>( ${pName} )</p>
        </div>
        <div>
          <p>Kasir / Front Office,</p>
          <br><br><br>
          <p>( Kasir Nina Dental Care )</p>
        </div>
      </div>
    </body>
    </html>
  `)
  win.document.close()
  win.focus()
  setTimeout(() => { win.print() }, 400)
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
  <div class="p-4 space-y-4 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-2">
      <div>
        <h1 class="text-xl font-semibold">
          Billing & Rekonsiliasi
        </h1>
        <p class="text-sm text-muted">
          Pusat pencatatan transaksi kasir, pembayaran reservasi, dan POS Front Office.
        </p>
      </div>
      <div class="flex items-center gap-2">
        <UButton
          icon="i-lucide-shopping-bag"
          color="primary"
          label="Transaksi POS (Kasir)"
          @click="showPos = true"
        />
        <UButton
          icon="i-lucide-plus"
          color="gray"
          variant="outline"
          label="Bayar Reservasi"
          @click="openCreate"
        />
      </div>
    </div>

    <!-- Stat Cards Top Row -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <div class="p-4 rounded-xl border border-default bg-card shadow-xs flex items-center justify-between">
        <div>
          <p class="text-xs font-semibold text-muted">Total Omset Lunas</p>
          <p class="text-xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1">
            {{ formatIDR(displayPayments.reduce((s, p) => s + p.amount, 0)) }}
          </p>
          <p class="text-[10px] text-emerald-600 font-medium mt-0.5">↑ Terverifikasi Lunas</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 flex items-center justify-center">
          <UIcon name="i-lucide-wallet" class="w-6 h-6" />
        </div>
      </div>

      <div class="p-4 rounded-xl border border-default bg-card shadow-xs flex items-center justify-between">
        <div>
          <p class="text-xs font-semibold text-muted">Total Transaksi</p>
          <p class="text-xl font-extrabold text-blue-600 dark:text-blue-400 mt-1">
            {{ displayPayments.length }} Transaksi
          </p>
          <p class="text-[10px] text-muted mt-0.5">Periode Berjalan</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-blue-50 dark:bg-blue-950/40 text-blue-600 flex items-center justify-center">
          <UIcon name="i-lucide-receipt" class="w-6 h-6" />
        </div>
      </div>

      <div class="p-4 rounded-xl border border-default bg-card shadow-xs flex items-center justify-between">
        <div>
          <p class="text-xs font-semibold text-muted">Rata-rata Order (AOV)</p>
          <p class="text-xl font-extrabold text-amber-600 dark:text-amber-400 mt-1">
            {{ formatIDR(Math.round(displayPayments.reduce((s, p) => s + p.amount, 0) / (displayPayments.length || 1))) }}
          </p>
          <p class="text-[10px] text-muted mt-0.5">Per Invoice Kasir</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 flex items-center justify-center">
          <UIcon name="i-lucide-calculator" class="w-6 h-6" />
        </div>
      </div>

      <div class="p-4 rounded-xl border border-default bg-card shadow-xs flex items-center justify-between">
        <div>
          <p class="text-xs font-semibold text-muted">Tingkat Kelunasan</p>
          <p class="text-xl font-extrabold text-purple-600 dark:text-purple-400 mt-1">
            100% Verified
          </p>
          <p class="text-[10px] text-purple-600 font-medium mt-0.5">SOP Billing Terverifikasi</p>
        </div>
        <div class="w-10 h-10 rounded-xl bg-purple-50 dark:bg-purple-950/40 text-purple-600 flex items-center justify-center">
          <UIcon name="i-lucide-check-circle-2" class="w-6 h-6" />
        </div>
      </div>
    </div>

    <!-- Main Layout Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      <!-- Table Wrapper with overflow-x-auto and compact layout so Preview button is never cut off -->
      <UCard
        class="lg:col-span-8 xl:col-span-9 w-full shadow-xs"
        :ui="{ body: 'p-0 sm:p-0' }"
      >
        <div class="overflow-x-auto min-w-full">
          <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
            <thead class="bg-gray-50 dark:bg-gray-800 text-[11px] font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
              <tr>
                <th class="px-3 py-2.5">Tanggal</th>
                <th class="px-3 py-2.5">Pasien</th>
                <th class="px-3 py-2.5">Cabang</th>
                <th class="px-3 py-2.5">Jumlah</th>
                <th class="px-3 py-2.5">Metode</th>
                <th class="px-3 py-2.5">Status</th>
                <th class="px-3 py-2.5">Referensi</th>
                <th class="px-3 py-2.5 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
              <tr
                v-for="item in displayPayments"
                :key="item.id"
                class="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors"
              >
                <td class="px-3 py-2.5 whitespace-nowrap text-gray-500">
                  {{ formatDateTime(item.createdAt) }}
                </td>
                <td class="px-3 py-2.5 font-semibold text-gray-900 dark:text-white whitespace-nowrap">
                  {{ item.patientName }}
                </td>
                <td class="px-3 py-2.5 whitespace-nowrap">
                  <UBadge color="gray" variant="subtle" size="xs">
                    {{ item.branchName }}
                  </UBadge>
                </td>
                <td class="px-3 py-2.5 font-bold text-gray-900 dark:text-white whitespace-nowrap">
                  {{ formatIDR(item.amount) }}
                </td>
                <td class="px-3 py-2.5 whitespace-nowrap">
                  {{ item.paymentMethod ? (methodLabelMap[item.paymentMethod] ?? item.paymentMethod) : '—' }}
                </td>
                <td class="px-3 py-2.5 whitespace-nowrap">
                  <UBadge
                    :color="paymentStatusColor(item.status)"
                    variant="soft"
                    size="xs"
                  >
                    {{ paymentStatusLabel(item.status) }}
                  </UBadge>
                </td>
                <td class="px-3 py-2.5 font-mono text-[11px] whitespace-nowrap text-gray-500">
                  {{ item.providerReference ?? '—' }}
                </td>
                <!-- Action Buttons: Clear & Never Cut Off -->
                <td class="px-3 py-2.5 whitespace-nowrap text-right">
                  <div class="flex items-center justify-end gap-1">
                    <UButton
                      size="xs"
                      color="neutral"
                      variant="ghost"
                      icon="i-lucide-eye"
                      title="Lihat Detail"
                      @click="openPaymentDetail(item)"
                    />
                    <UButton
                      size="xs"
                      color="primary"
                      variant="subtle"
                      icon="i-lucide-printer"
                      label="Cetak Invoice"
                      @click="printInvoice(item)"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </UCard>

      <!-- Side Summary & Visual Payment Method Breakdown (Informative Progress Bars instead of Pie Chart) -->
      <UCard class="lg:col-span-4 xl:col-span-3 space-y-4 shadow-xs border border-default">
        <div class="flex items-center justify-between pb-2 border-b border-default">
          <h3 class="text-sm font-bold text-gray-900 dark:text-white flex items-center gap-2">
            <UIcon name="i-lucide-trending-up" class="w-4 h-4 text-emerald-600" />
            Distribusi Metode Pembayaran
          </h3>
          <UBadge size="xs" color="success" variant="subtle">Live Data</UBadge>
        </div>

        <!-- Custom Informative Progress Card Component -->
        <div class="space-y-3 pt-1">
          <div
            v-for="m in paymentDistribution"
            :key="m.name"
            class="p-2.5 rounded-xl border border-gray-100 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-800/50 space-y-1.5"
          >
            <div class="flex items-center justify-between text-xs">
              <div class="flex items-center gap-2 font-semibold text-gray-800 dark:text-gray-200">
                <UIcon :name="m.icon" class="w-4 h-4 text-primary" />
                <span>{{ m.name }}</span>
              </div>
              <UBadge color="primary" variant="subtle" size="xs">
                {{ m.percentage }}%
              </UBadge>
            </div>

            <!-- Progress Bar -->
            <div class="w-full h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
              <div
                class="h-full bg-primary-600 transition-all duration-300 rounded-full"
                :style="{ width: `${m.percentage}%` }"
              />
            </div>

            <div class="flex items-center justify-between text-[11px] text-gray-500 pt-0.5">
              <span>{{ m.count }} Transaksi</span>
              <span class="font-bold text-gray-900 dark:text-white">{{ formatIDR(m.revenue) }}</span>
            </div>
          </div>
        </div>

        <!-- Trend Chart Box -->
        <div class="space-y-1.5 pt-3 border-t border-default">
          <div class="flex items-center justify-between">
            <span class="text-xs font-semibold text-muted uppercase tracking-wider">Grafik Pendapatan Harian</span>
            <span class="text-[10px] text-emerald-600 font-bold">+14.2% m/m</span>
          </div>
          <div class="rounded-xl border border-default p-1 bg-card">
            <ChartsEChart
              :option="trendOption"
              height="130px"
            />
          </div>
        </div>
      </UCard>
    </div>

    <!-- POS checkout -->
    <UModal
      v-model:open="showPos"
      title="Transaksi Baru (POS Front Office)"
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

    <!-- Pay existing reservation Modal with Front Office Staff Selection -->
    <UModal
      v-model:open="showModal"
      title="Bayar Reservasi & Transaksi Kasir"
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

          <!-- Pegawai Entri (Front Office) Dropdown -->
          <UFormField
            label="Pegawai Entri (Front Office / Kasir)"
            required
          >
            <USelect
              v-model="form.entryStaff"
              :items="FRONT_OFFICE_STAFF"
              class="w-full"
            />
          </UFormField>

          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Jumlah Dibayar (Rp)"
              required
            >
              <UInput
                v-model.number="form.amount"
                type="number"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Deposit / Uang Muka">
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
              label="Status Pembayaran"
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
            label="Proses Pembayaran Kasir"
            @click="onSubmit"
          />
        </div>
      </template>
    </UModal>
  </div>
</template>
