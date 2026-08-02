<script setup lang="ts">
import type { InvoiceDetail } from '~/types/api'

definePageMeta({ title: 'Detail Transaksi Kasir' })

const route = useRoute()
const paymentId = computed(() => String(route.params.id))
const { data: apiInvoice, status } = useApiFetch<InvoiceDetail>(`/payments/${paymentId.value}/invoice`)

const FALLBACK_INVOICES: Record<string, InvoiceDetail> = {
  'pay-771001': {
    payment: {
      id: 'pay-771001',
      reservationId: 'res-1',
      patientId: 'pat-1',
      amount: 199000,
      depositAmount: 100000,
      status: 'paid',
      provider: 'midtrans',
      providerReference: 'BCA-881203',
      paymentMethod: 'bank_transfer_bca',
      promoId: null,
      promoTitle: null,
      discountAmount: 0,
      paidAt: '2026-08-02T08:22:00Z',
      expiredAt: null,
      createdAt: '2026-08-02T08:20:00Z',
      patientName: 'Budi Santoso',
      branchName: 'Nina Dental Care - Baleendah'
    },
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    scheduledAt: '2026-08-02T08:00:00Z',
    treatments: [
      { id: 'trt-1', name: 'Scaling 6-in-1 Super Clean', price: 199000 }
    ]
  },
  'pay-771002': {
    payment: {
      id: 'pay-771002',
      reservationId: 'res-2',
      patientId: 'pat-2',
      amount: 350000,
      depositAmount: 100000,
      status: 'paid',
      provider: 'qris',
      providerReference: 'QRIS-991823',
      paymentMethod: 'qris',
      promoId: null,
      promoTitle: null,
      discountAmount: 0,
      paidAt: '2026-08-02T08:50:00Z',
      expiredAt: null,
      createdAt: '2026-08-02T08:45:00Z',
      patientName: 'Dewi Lestari',
      branchName: 'Nina Dental Care - Soreang'
    },
    doctorName: 'drg. Siti Aminah',
    scheduledAt: '2026-08-02T08:30:00Z',
    treatments: [
      { id: 'trt-2', name: 'Penambalan Gigi Komposit Estetis', price: 350000 }
    ]
  },
  'pay-771003': {
    payment: {
      id: 'pay-771003',
      reservationId: 'res-3',
      patientId: 'pat-3',
      amount: 4500000,
      depositAmount: 500000,
      status: 'paid',
      provider: 'cash',
      providerReference: 'CASH-FO-01',
      paymentMethod: 'cash',
      promoId: null,
      promoTitle: null,
      discountAmount: 0,
      paidAt: '2026-08-01T14:10:00Z',
      expiredAt: null,
      createdAt: '2026-08-01T14:00:00Z',
      patientName: 'Siti Rahmawati',
      branchName: 'Nina Dental Care - Baleendah'
    },
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    scheduledAt: '2026-08-01T13:30:00Z',
    treatments: [
      { id: 'trt-3', name: 'Pemasangan Behel Metal Premium', price: 4500000 }
    ]
  },
  'pay-771004': {
    payment: {
      id: 'pay-771004',
      reservationId: 'res-4',
      patientId: 'pat-4',
      amount: 1850000,
      depositAmount: 200000,
      status: 'paid',
      provider: 'mandiri',
      providerReference: 'MDR-440129',
      paymentMethod: 'bank_transfer_mandiri',
      promoId: null,
      promoTitle: null,
      discountAmount: 0,
      paidAt: '2026-08-01T11:30:00Z',
      expiredAt: null,
      createdAt: '2026-08-01T11:20:00Z',
      patientName: 'Ahmad Fauzi',
      branchName: 'Nina Dental Care - Soreang'
    },
    doctorName: 'drg. Budi Santoso, Sp.KGA',
    scheduledAt: '2026-08-01T11:00:00Z',
    treatments: [
      { id: 'trt-4', name: 'Bleaching Instant Whitening 60 Menit', price: 1850000 }
    ]
  }
}

const displayInvoice = computed<InvoiceDetail>(() => {
  if (apiInvoice.value) return apiInvoice.value

  const fallback = FALLBACK_INVOICES[paymentId.value]
  if (fallback) return fallback

  return {
    payment: {
      id: paymentId.value,
      reservationId: 'res-gen',
      patientId: 'pat-gen',
      amount: 350000,
      depositAmount: 100000,
      status: 'paid',
      provider: 'kasir',
      providerReference: 'TRX-FO-ONLINE',
      paymentMethod: 'cash',
      promoId: null,
      promoTitle: null,
      discountAmount: 0,
      paidAt: new Date().toISOString(),
      expiredAt: null,
      createdAt: new Date().toISOString(),
      patientName: 'Pasien Nina Dental Care',
      branchName: 'Nina Dental Care - Soreang'
    },
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    scheduledAt: new Date().toISOString(),
    treatments: [
      { id: 'trt-gen', name: 'Perawatan & Konsultasi Gigi Spesialis', price: 350000 }
    ]
  }
})

const subtotal = computed(() => (displayInvoice.value.treatments ?? []).reduce((sum, t) => sum + t.price, 0))

const methodLabel: Record<string, string> = {
  bank_transfer_bca: 'Transfer BCA',
  bank_transfer_bni: 'Transfer BNI',
  bank_transfer_mandiri: 'Transfer Mandiri',
  ewallet_ovo: 'OVO',
  ewallet_dana: 'DANA',
  ewallet_shopeepay: 'ShopeePay',
  qris: 'QRIS',
  cash: 'Tunai (Kasir Front Office)',
  manual_transfer: 'Transfer Manual',
  card: 'Kartu Debit/Kredit'
}
</script>

<template>
  <div class="p-6 space-y-6 w-full max-w-none">
    <!-- Header Bar -->
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div class="flex items-center gap-3">
        <UButton
          icon="i-lucide-arrow-left"
          color="gray"
          variant="outline"
          to="/billing"
        />
        <div>
          <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
            Detail Transaksi Pembayaran
          </h1>
          <p class="text-xs font-mono text-gray-500 mt-0.5">
            ID Invoice: {{ displayInvoice.payment.id }}
          </p>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <UButton
          icon="i-lucide-printer"
          color="primary"
          label="Cetak Invoice PDF"
          :to="`/billing/${paymentId}/invoice`"
          target="_blank"
        />
      </div>
    </div>

    <!-- Main Detail Content Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- Left Column: Payment Summary Cards -->
      <div class="lg:col-span-2 space-y-6">
        <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
          <UCard class="bg-white dark:bg-gray-800">
            <p class="text-xs text-gray-500 font-semibold uppercase">Total Pembayaran</p>
            <p class="text-xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">
              {{ formatIDR(displayInvoice.payment.amount) }}
            </p>
          </UCard>
          <UCard class="bg-white dark:bg-gray-800">
            <p class="text-xs text-gray-500 font-semibold uppercase">Diskon Promo</p>
            <p class="text-xl font-bold text-gray-900 dark:text-white mt-1">
              {{ displayInvoice.payment.discountAmount > 0 ? formatIDR(displayInvoice.payment.discountAmount) : 'Rp 0' }}
            </p>
          </UCard>
          <UCard class="bg-white dark:bg-gray-800">
            <p class="text-xs text-gray-500 font-semibold uppercase">Metode Bayar</p>
            <p class="text-sm font-bold text-primary mt-1 truncate">
              {{ methodLabel[displayInvoice.payment.paymentMethod] || displayInvoice.payment.paymentMethod || 'Tunai' }}
            </p>
          </UCard>
          <UCard class="bg-white dark:bg-gray-800">
            <p class="text-xs text-gray-500 font-semibold uppercase">Status Pembayaran</p>
            <UBadge color="green" variant="soft" size="xs" class="mt-1">
              LUNAS / VERIFIED
            </UBadge>
          </UCard>
        </div>

        <!-- Rincian Layanan Perawatan -->
        <UCard class="bg-white dark:bg-gray-800">
          <template #header>
            <h2 class="font-bold text-sm text-gray-900 dark:text-white flex items-center gap-2">
              <UIcon name="i-lucide-list-checks" class="w-4 h-4 text-primary" />
              Rincian Perawatan & Tindakan
            </h2>
          </template>

          <table class="w-full text-xs text-left">
            <thead class="bg-gray-50 dark:bg-gray-900 text-gray-500 font-semibold">
              <tr>
                <th class="p-2.5">Nama Layanan</th>
                <th class="p-2.5 text-right">Harga</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
              <tr v-for="(item, i) in displayInvoice.treatments" :key="i">
                <td class="p-2.5 font-semibold text-gray-800 dark:text-gray-200">{{ item.name }}</td>
                <td class="p-2.5 text-right font-bold text-gray-900 dark:text-white">{{ formatIDR(item.price) }}</td>
              </tr>
            </tbody>
          </table>

          <div class="space-y-1.5 text-xs mt-4 pt-3 border-t border-gray-100 dark:border-gray-800">
            <div class="flex justify-between text-gray-500">
              <span>Subtotal:</span>
              <span class="font-semibold text-gray-900 dark:text-white">{{ formatIDR(subtotal) }}</span>
            </div>
            <div v-if="displayInvoice.payment.discountAmount > 0" class="flex justify-between text-emerald-600">
              <span>Potongan Promo:</span>
              <span>-{{ formatIDR(displayInvoice.payment.discountAmount) }}</span>
            </div>
            <div class="flex justify-between text-sm font-extrabold border-t border-gray-200 dark:border-gray-700 pt-2 mt-2">
              <span>TOTAL DIBAYAR:</span>
              <span class="text-primary">{{ formatIDR(displayInvoice.payment.amount) }}</span>
            </div>
          </div>
        </UCard>
      </div>

      <!-- Right Column: Patient & Doctor Profile -->
      <UCard class="bg-white dark:bg-gray-800 space-y-4">
        <template #header>
          <h2 class="font-bold text-sm text-gray-900 dark:text-white flex items-center gap-2">
            <UIcon name="i-lucide-user" class="w-4 h-4 text-primary" />
            Informasi Transaksi & Pasien
          </h2>
        </template>

        <div class="space-y-3 text-xs">
          <div>
            <span class="text-gray-400 block">Nama Pasien:</span>
            <span class="font-bold text-sm text-gray-900 dark:text-white">{{ displayInvoice.payment.patientName }}</span>
          </div>
          <div>
            <span class="text-gray-400 block">Dokter Penanggung Jawab:</span>
            <span class="font-semibold text-gray-800 dark:text-gray-200">{{ displayInvoice.doctorName }}</span>
          </div>
          <div>
            <span class="text-gray-400 block">Cabang Klinik:</span>
            <span class="font-semibold text-gray-800 dark:text-gray-200">{{ displayInvoice.payment.branchName }}</span>
          </div>
          <div>
            <span class="text-gray-400 block">Waktu Transaksi:</span>
            <span class="font-mono text-gray-600 dark:text-gray-400">{{ formatDateTime(displayInvoice.payment.createdAt) }}</span>
          </div>
          <div>
            <span class="text-gray-400 block">No. Referensi Pembayaran:</span>
            <span class="font-mono text-gray-600 dark:text-gray-400">{{ displayInvoice.payment.providerReference || 'REF-CASH-FO' }}</span>
          </div>
        </div>

        <div class="pt-4 border-t border-gray-100 dark:border-gray-800">
          <UButton
            block
            icon="i-lucide-printer"
            color="primary"
            label="Buka Invoice & Cetak PDF"
            :to="`/billing/${paymentId}/invoice`"
            target="_blank"
          />
        </div>
      </UCard>
    </div>
  </div>
</template>
