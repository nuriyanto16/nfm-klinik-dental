<script setup lang="ts">
import type { DoctorDetail, Patient, Payment, Promo, Treatment } from '~/types/api'

const props = defineProps<{
  patients: Patient[]
  branches: { id: string, name: string }[]
  doctorsAdmin: DoctorDetail[]
  treatments: Treatment[]
  promos: Promo[]
}>()

const emit = defineEmits<{ completed: [payment: Payment] }>()

interface CartLine {
  treatmentId: string
  name: string
  price: number
  qty: number
}

const PAYMENT_METHODS = [
  { value: 'cash', label: 'Tunai', icon: 'i-lucide-banknote' },
  { value: 'qris', label: 'QRIS', icon: 'i-lucide-qr-code' },
  { value: 'manual_transfer', label: 'Transfer Bank', icon: 'i-lucide-landmark' },
  { value: 'card', label: 'Kartu Debit/Kredit', icon: 'i-lucide-credit-card' }
]

const patientId = ref('')
const branchId = ref(props.branches[0]?.id ?? '')
const staffId = ref('')
const search = ref('')
const activeCategory = ref('all')
const cart = ref<CartLine[]>([])
const discount = ref(0)
const promoId = ref('')
const activePromos = computed(() => props.promos.filter(p => p.isActive))
const selectedPromo = computed(() => activePromos.value.find(p => p.id === promoId.value) ?? null)
const paymentMethod = ref('cash')
const cashReceived = ref(0)
const processing = ref(false)
const posError = ref('')
const completedPayment = ref<Payment | null>(null)

const doctorsForBranch = computed(() => props.doctorsAdmin.filter(d => !branchId.value || d.branchIds?.includes(branchId.value)))
watch(doctorsForBranch, (list) => {
  if (!list.some(d => d.id === staffId.value)) staffId.value = list[0]?.id ?? ''
}, { immediate: true })

const categories = computed(() => {
  const names = new Set(props.treatments.map(t => t.categoryName))
  return ['all', ...names]
})

const filteredTreatments = computed(() => props.treatments.filter((t) => {
  const matchesCategory = activeCategory.value === 'all' || t.categoryName === activeCategory.value
  const matchesSearch = !search.value || t.name.toLowerCase().includes(search.value.toLowerCase())
  return matchesCategory && matchesSearch && t.isActive
}))

function addToCart(t: Treatment) {
  const existing = cart.value.find(line => line.treatmentId === t.id)
  if (existing) existing.qty++
  else cart.value.push({ treatmentId: t.id, name: t.name, price: t.price, qty: 1 })
}
function incQty(line: CartLine) {
  line.qty++
}
function decQty(line: CartLine) {
  line.qty--
  if (line.qty <= 0) cart.value = cart.value.filter(l => l !== line)
}
function removeLine(line: CartLine) {
  cart.value = cart.value.filter(l => l !== line)
}

const subtotal = computed(() => cart.value.reduce((sum, l) => sum + l.price * l.qty, 0))
watch([selectedPromo, subtotal], ([promo, sub]) => {
  if (!promo || !promo.discountType) return
  discount.value = promo.discountType === 'percentage'
    ? Math.round(sub * (promo.discountValue ?? 0) / 100)
    : (promo.discountValue ?? 0)
})
const total = computed(() => Math.max(0, subtotal.value - discount.value))
const change = computed(() => Math.max(0, cashReceived.value - total.value))
const canPay = computed(() =>
  cart.value.length > 0
  && patientId.value
  && branchId.value
  && staffId.value
  && (paymentMethod.value !== 'cash' || cashReceived.value >= total.value)
)

function resetForNewTransaction() {
  cart.value = []
  discount.value = 0
  promoId.value = ''
  paymentMethod.value = 'cash'
  cashReceived.value = 0
  posError.value = ''
  completedPayment.value = null
}

async function processPayment() {
  processing.value = true
  posError.value = ''
  try {
    const treatmentIds = cart.value.flatMap(l => Array(l.qty).fill(l.treatmentId))
    const reservation = await apiPost<{ id: string }>('/reservations', {
      patientId: patientId.value,
      branchId: branchId.value,
      staffId: staffId.value,
      scheduledAt: new Date().toISOString(),
      treatmentIds,
      status: 'completed'
    })
    const payment = await apiPost<Payment>('/payments', {
      reservationId: reservation.id,
      amount: total.value,
      depositAmount: total.value,
      paymentMethod: paymentMethod.value,
      status: 'paid',
      promoId: promoId.value || null,
      discountAmount: discount.value
    })
    completedPayment.value = payment
    emit('completed', payment)
  } catch (err) {
    posError.value = apiErrorMessage(err)
  } finally {
    processing.value = false
  }
}
</script>

<template>
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-4 h-full">
    <!-- Success receipt view -->
    <div
      v-if="completedPayment"
      class="lg:col-span-3 flex flex-col items-center justify-center py-16 gap-4"
    >
      <div class="w-16 h-16 rounded-full bg-success/10 flex items-center justify-center">
        <UIcon
          name="i-lucide-check"
          class="w-8 h-8 text-success"
        />
      </div>
      <h3 class="text-lg font-semibold">
        Pembayaran Berhasil
      </h3>
      <p class="text-sm text-muted">
        {{ formatIDR(completedPayment.amount) }} — {{ completedPayment.patientName }}
      </p>
      <p
        v-if="paymentMethod === 'cash' && change > 0"
        class="text-sm"
      >
        Kembalian: <span class="font-semibold text-success">{{ formatIDR(change) }}</span>
      </p>
      <div class="flex gap-2 mt-4">
        <UButton
          icon="i-lucide-printer"
          label="Cetak Invoice"
          :to="`/billing/${completedPayment.id}/invoice`"
          target="_blank"
        />
        <UButton
          icon="i-lucide-plus"
          variant="soft"
          label="Transaksi Baru"
          @click="resetForNewTransaction"
        />
      </div>
    </div>

    <template v-else>
      <!-- Catalog -->
      <div class="lg:col-span-2 space-y-3 flex flex-col min-h-0">
        <div class="grid grid-cols-3 gap-3">
          <UFormField
            label="Pasien"
            required
          >
            <USelect
              v-model="patientId"
              :items="patients.map(p => ({ label: p.fullName, value: p.id }))"
              class="w-full"
              searchable
              placeholder="Pilih pasien"
            />
          </UFormField>
          <UFormField
            label="Cabang"
            required
          >
            <USelect
              v-model="branchId"
              :items="branches.map(b => ({ label: b.name, value: b.id }))"
              class="w-full"
            />
          </UFormField>
          <UFormField
            label="Dokter"
            required
          >
            <USelect
              v-model="staffId"
              :items="doctorsForBranch.map(d => ({ label: d.fullName, value: d.id }))"
              class="w-full"
            />
          </UFormField>
        </div>

        <UInput
          v-model="search"
          icon="i-lucide-search"
          placeholder="Cari perawatan..."
          class="w-full"
        />

        <div class="flex flex-wrap gap-1">
          <UButton
            v-for="cat in categories"
            :key="cat"
            :label="cat === 'all' ? 'Semua' : cat"
            size="xs"
            :variant="activeCategory === cat ? 'solid' : 'soft'"
            :color="activeCategory === cat ? 'primary' : 'neutral'"
            @click="activeCategory = cat"
          />
        </div>

        <div
          class="grid grid-cols-2 sm:grid-cols-3 gap-2 overflow-y-auto pr-1"
          style="max-height: 420px"
        >
          <button
            v-for="t in filteredTreatments"
            :key="t.id"
            type="button"
            class="text-left rounded-lg border border-default p-3 hover:border-primary hover:bg-primary/5 transition-colors"
            @click="addToCart(t)"
          >
            <p class="text-sm font-medium line-clamp-2">
              {{ t.name }}
            </p>
            <p class="text-xs text-muted mt-1">
              {{ t.categoryName }}
            </p>
            <p class="text-sm font-semibold text-primary mt-2">
              {{ formatIDR(t.price) }}
            </p>
          </button>
          <p
            v-if="filteredTreatments.length === 0"
            class="col-span-full text-sm text-muted py-6 text-center"
          >
            Tidak ada perawatan yang cocok.
          </p>
        </div>
      </div>

      <!-- Cart / checkout -->
      <div class="border-l border-default lg:pl-4 flex flex-col gap-3">
        <h3 class="font-medium flex items-center gap-2">
          <UIcon name="i-lucide-shopping-cart" />
          Keranjang
        </h3>

        <div
          class="flex-1 overflow-y-auto space-y-2"
          style="max-height: 260px"
        >
          <p
            v-if="cart.length === 0"
            class="text-sm text-muted py-6 text-center"
          >
            Klik perawatan di sebelah kiri untuk menambah.
          </p>
          <div
            v-for="line in cart"
            :key="line.treatmentId"
            class="flex items-center gap-2 text-sm"
          >
            <div class="flex-1 min-w-0">
              <p class="truncate">
                {{ line.name }}
              </p>
              <p class="text-xs text-muted">
                {{ formatIDR(line.price) }}
              </p>
            </div>
            <div class="flex items-center gap-1">
              <UButton
                icon="i-lucide-minus"
                size="xs"
                color="neutral"
                variant="soft"
                @click="decQty(line)"
              />
              <span class="w-5 text-center tabular-nums">{{ line.qty }}</span>
              <UButton
                icon="i-lucide-plus"
                size="xs"
                color="neutral"
                variant="soft"
                @click="incQty(line)"
              />
            </div>
            <span class="w-24 text-right tabular-nums">{{ formatIDR(line.price * line.qty) }}</span>
            <UButton
              icon="i-lucide-x"
              size="xs"
              color="error"
              variant="ghost"
              @click="removeLine(line)"
            />
          </div>
        </div>

        <div class="border-t border-default pt-3 space-y-2 text-sm">
          <div class="flex justify-between">
            <span class="text-muted">Subtotal</span>
            <span class="tabular-nums">{{ formatIDR(subtotal) }}</span>
          </div>
          <UFormField label="Promo">
            <USelect
              v-model="promoId"
              :items="[{ label: 'Tanpa Promo', value: '' }, ...activePromos.map(p => ({ label: p.title, value: p.id }))]"
              class="w-full"
            />
          </UFormField>
          <div class="flex justify-between items-center">
            <span class="text-muted">Diskon</span>
            <UInput
              v-model.number="discount"
              type="number"
              size="xs"
              class="w-28"
            />
          </div>
          <div class="flex justify-between font-semibold text-base border-t border-default pt-2">
            <span>Total</span>
            <span class="tabular-nums">{{ formatIDR(total) }}</span>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-2">
          <UButton
            v-for="m in PAYMENT_METHODS"
            :key="m.value"
            :icon="m.icon"
            :label="m.label"
            size="sm"
            :variant="paymentMethod === m.value ? 'solid' : 'soft'"
            :color="paymentMethod === m.value ? 'primary' : 'neutral'"
            @click="paymentMethod = m.value"
          />
        </div>

        <template v-if="paymentMethod === 'cash'">
          <UFormField label="Uang Diterima">
            <UInput
              v-model.number="cashReceived"
              type="number"
              class="w-full"
            />
          </UFormField>
          <div class="flex justify-between text-sm">
            <span class="text-muted">Kembalian</span>
            <span
              class="font-semibold"
              :class="change > 0 ? 'text-success' : ''"
            >{{ formatIDR(change) }}</span>
          </div>
        </template>

        <UAlert
          v-if="posError"
          color="error"
          variant="subtle"
          :description="posError"
        />

        <UButton
          block
          size="lg"
          icon="i-lucide-check-circle"
          label="Proses Pembayaran"
          :disabled="!canPay"
          :loading="processing"
          @click="processPayment"
        />
      </div>
    </template>
  </div>
</template>
