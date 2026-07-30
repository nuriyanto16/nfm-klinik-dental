<script setup lang="ts">
import type { InvoiceDetail } from '~/types/api'

definePageMeta({ layout: 'invoice', title: 'Invoice' })

const route = useRoute()
const { data: invoice, error } = useApiFetch<InvoiceDetail>(`/payments/${route.params.id}/invoice`)

const subtotal = computed(() => (invoice.value?.treatments ?? []).reduce((sum, t) => sum + t.price, 0))

function print() {
  window.print()
}
</script>

<template>
  <UContainer class="py-8 print:py-0">
    <div class="max-w-2xl mx-auto space-y-4">
      <div class="flex justify-end gap-2 print:hidden">
        <UButton
          icon="i-lucide-arrow-left"
          color="neutral"
          variant="ghost"
          label="Kembali"
          @click="$router.back()"
        />
        <UButton
          icon="i-lucide-printer"
          label="Cetak"
          @click="print"
        />
      </div>

      <UAlert
        v-if="error"
        color="error"
        variant="subtle"
        icon="i-lucide-alert-triangle"
        title="Gagal memuat invoice"
        :description="error.message"
      />

      <div
        v-if="invoice"
        class="bg-white text-black rounded-lg shadow-sm ring-1 ring-default p-8 print:shadow-none print:ring-0"
      >
        <div class="flex items-start justify-between border-b border-gray-200 pb-4">
          <div>
            <div class="flex items-center gap-2 font-semibold text-lg">
              <span class="flex items-center justify-center w-8 h-8 rounded-lg bg-gradient-to-br from-primary-500 to-primary-700 text-white text-xs">NDC</span>
              Nina Dental Care
            </div>
            <p class="text-sm text-gray-500 mt-1">
              {{ invoice.payment.branchName }}
            </p>
          </div>
          <div class="text-right">
            <p class="text-sm text-gray-500">
              Invoice
            </p>
            <p class="font-mono text-xs">
              {{ invoice.payment.id }}
            </p>
            <p class="text-sm text-gray-500 mt-2">
              {{ formatDateTime(invoice.payment.createdAt) }}
            </p>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4 py-4 border-b border-gray-200 text-sm">
          <div>
            <p class="text-gray-500">
              Pasien
            </p>
            <p class="font-medium">
              {{ invoice.payment.patientName }}
            </p>
          </div>
          <div>
            <p class="text-gray-500">
              Dokter
            </p>
            <p class="font-medium">
              {{ invoice.doctorName }}
            </p>
          </div>
          <div>
            <p class="text-gray-500">
              Jadwal Reservasi
            </p>
            <p class="font-medium">
              {{ formatDateTime(invoice.scheduledAt) }}
            </p>
          </div>
          <div>
            <p class="text-gray-500">
              Status Pembayaran
            </p>
            <UBadge
              :color="paymentStatusColor(invoice.payment.status)"
              variant="subtle"
            >
              {{ paymentStatusLabel(invoice.payment.status) }}
            </UBadge>
          </div>
        </div>

        <table class="w-full text-sm my-4">
          <thead>
            <tr class="text-left text-gray-500 border-b border-gray-200">
              <th class="py-2 font-normal">
                Perawatan
              </th>
              <th class="py-2 font-normal text-right">
                Harga
              </th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="(item, i) in invoice.treatments"
              :key="i"
              class="border-b border-gray-100"
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

        <div class="space-y-1 text-sm ml-auto w-56">
          <div class="flex justify-between">
            <span class="text-gray-500">Subtotal Perawatan</span>
            <span>{{ formatIDR(subtotal) }}</span>
          </div>
          <div class="flex justify-between font-semibold text-base border-t border-gray-200 pt-1 mt-1">
            <span>Total Dibayar</span>
            <span>{{ formatIDR(invoice.payment.amount) }}</span>
          </div>
        </div>

        <p class="text-xs text-gray-400 mt-8 text-center">
          Invoice ini dihasilkan otomatis oleh Office Panel Nina Dental Care.
        </p>
      </div>
    </div>
  </UContainer>
</template>
