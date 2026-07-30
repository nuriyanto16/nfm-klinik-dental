<script setup lang="ts">
import type { Branch, CreatePaymentInput, DoctorDetail, Patient, Payment, Reservation, Treatment } from '~/types/api'

definePageMeta({ title: 'Billing & Rekonsiliasi' })

const { data: payments, status, error, refresh } = useApiFetch<Payment[]>('/payments')
const { data: reservations } = useApiFetch<Reservation[]>('/reservations')
const { data: patients } = useApiFetch<Patient[]>('/patients')
const { data: branches } = useApiFetch<Branch[]>('/branches')
const { data: doctorsAdmin } = useApiFetch<DoctorDetail[]>('/doctors/admin')
const { data: treatments } = useApiFetch<Treatment[]>('/treatments')

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

    <SkeletonTableSkeleton
      v-if="status === 'pending'"
      :columns="6"
    />
    <UTable
      v-else
      :data="payments ?? []"
      :columns="columns"
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
        <UButton
          icon="i-lucide-printer"
          size="xs"
          color="neutral"
          variant="ghost"
          label="Invoice"
          :to="`/billing/${row.original.id}/invoice`"
          target="_blank"
        />
      </template>
    </UTable>

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
