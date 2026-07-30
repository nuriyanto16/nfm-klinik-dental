<script setup lang="ts">
import type { InvoiceDetail } from '~/types/api'

definePageMeta({ title: 'Detail Transaksi' })

const route = useRoute()
const { data: invoice, status, error } = useApiFetch<InvoiceDetail>(`/payments/${route.params.id}/invoice`)

const subtotal = computed(() => (invoice.value?.treatments ?? []).reduce((sum, t) => sum + t.price, 0))

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
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between">
      <div class="flex items-center gap-2">
        <UButton
          icon="i-lucide-arrow-left"
          color="neutral"
          variant="ghost"
          @click="$router.back()"
        />
        <div>
          <h1 class="text-xl font-semibold">
            Detail Transaksi
          </h1>
          <p
            v-if="invoice"
            class="text-sm text-muted font-mono"
          >
            {{ invoice.payment.id }}
          </p>
        </div>
      </div>
      <UButton
        v-if="invoice"
        icon="i-lucide-printer"
        label="Cetak Invoice"
        :to="`/billing/${route.params.id}/invoice`"
        target="_blank"
      />
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat transaksi"
      :description="error.message"
    />

    <template v-if="status === 'pending'">
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <SkeletonStatCardSkeleton
          v-for="i in 4"
          :key="i"
        />
      </div>
      <SkeletonTableSkeleton :columns="2" />
    </template>

    <template v-else-if="invoice">
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <UPageCard
          :title="formatIDR(invoice.payment.amount)"
          description="Total Dibayar"
          icon="i-lucide-banknote"
        />
        <UPageCard
          :title="invoice.payment.discountAmount > 0 ? formatIDR(invoice.payment.discountAmount) : '—'"
          description="Diskon/Promo"
          icon="i-lucide-tag"
        />
        <UPageCard
          :title="invoice.payment.paymentMethod ? (methodLabel[invoice.payment.paymentMethod] ?? invoice.payment.paymentMethod) : '—'"
          description="Metode Pembayaran"
          icon="i-lucide-wallet"
        />
        <UPageCard
          description="Status"
          icon="i-lucide-circle-check"
        >
          <template #title>
            <UBadge
              :color="paymentStatusColor(invoice.payment.status)"
              variant="subtle"
            >
              {{ paymentStatusLabel(invoice.payment.status) }}
            </UBadge>
          </template>
        </UPageCard>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <UCard>
          <template #header>
            <h2 class="font-medium">
              Informasi Pasien & Jadwal
            </h2>
          </template>
          <dl class="grid grid-cols-2 gap-y-2 text-sm">
            <dt class="text-muted">
              Pasien
            </dt>
            <dd class="text-right">
              {{ invoice.payment.patientName }}
            </dd>
            <dt class="text-muted">
              Cabang
            </dt>
            <dd class="text-right">
              {{ invoice.payment.branchName }}
            </dd>
            <dt class="text-muted">
              Dokter
            </dt>
            <dd class="text-right">
              {{ invoice.doctorName }}
            </dd>
            <dt class="text-muted">
              Jadwal Reservasi
            </dt>
            <dd class="text-right">
              {{ formatDateTime(invoice.scheduledAt) }}
            </dd>
            <dt class="text-muted">
              Tanggal Transaksi
            </dt>
            <dd class="text-right">
              {{ formatDateTime(invoice.payment.createdAt) }}
            </dd>
            <dt
              v-if="invoice.payment.promoTitle"
              class="text-muted"
            >
              Promo Dipakai
            </dt>
            <dd
              v-if="invoice.payment.promoTitle"
              class="text-right"
            >
              {{ invoice.payment.promoTitle }}
            </dd>
            <dt
              v-if="invoice.payment.providerReference"
              class="text-muted"
            >
              Referensi
            </dt>
            <dd
              v-if="invoice.payment.providerReference"
              class="text-right font-mono text-xs"
            >
              {{ invoice.payment.providerReference }}
            </dd>
          </dl>
        </UCard>

        <UCard>
          <template #header>
            <h2 class="font-medium">
              Rincian Perawatan
            </h2>
          </template>
          <table class="w-full text-sm">
            <tbody>
              <tr
                v-for="(item, i) in invoice.treatments"
                :key="i"
                class="border-b border-default last:border-b-0"
              >
                <td class="py-2">
                  {{ item.name }}
                </td>
                <td class="py-2 text-right">
                  {{ formatIDR(item.price) }}
                </td>
              </tr>
            </tbody>
          </table>
          <div class="space-y-1 text-sm mt-3 pt-3 border-t border-default">
            <div class="flex justify-between">
              <span class="text-muted">Subtotal Perawatan</span>
              <span>{{ formatIDR(subtotal) }}</span>
            </div>
            <div
              v-if="invoice.payment.discountAmount > 0"
              class="flex justify-between text-error"
            >
              <span>Diskon</span>
              <span>-{{ formatIDR(invoice.payment.discountAmount) }}</span>
            </div>
            <div class="flex justify-between font-semibold text-base border-t border-default pt-1 mt-1">
              <span>Total</span>
              <span>{{ formatIDR(invoice.payment.amount) }}</span>
            </div>
          </div>
        </UCard>
      </div>
    </template>
  </UContainer>
</template>
