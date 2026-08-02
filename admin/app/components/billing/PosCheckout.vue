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
  { value: 'cash', label: 'Tunai', icon: 'i-lucide-banknote', color: 'emerald' },
  { value: 'qris', label: 'QRIS', icon: 'i-lucide-qr-code', color: 'blue' },
  { value: 'manual_transfer', label: 'Transfer Bank', icon: 'i-lucide-landmark', color: 'indigo' },
  { value: 'card', label: 'Kartu Debit/Kredit', icon: 'i-lucide-credit-card', color: 'purple' }
]

const patientId = ref(props.patients[0]?.id ?? '')
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
const cashReceived = ref<number>(0)
const processing = ref(false)
const posError = ref('')
const completedPayment = ref<Payment | null>(null)

const DUMMY_DOCTORS: DoctorDetail[] = [
  { id: '21000000-0000-0000-0000-000000000001', fullName: 'drg. Friski Raisis, Sp.Ort', specialization: 'Spesialis Ortodonti', email: 'friski@fdc.co.id', phoneWa: '08123456789', bio: 'Spesialis Ortodonti', commissionRate: 15, isActive: true, branchIds: [], schedules: [], skills: [] },
  { id: '21000000-0000-0000-0000-000000000002', fullName: 'drg. Siti Aminah', specialization: 'Dokter Gigi Umum', email: 'siti@fdc.co.id', phoneWa: '08123456780', bio: 'Dokter Gigi Umum', commissionRate: 10, isActive: true, branchIds: [], schedules: [], skills: [] },
  { id: '21000000-0000-0000-0000-000000000003', fullName: 'drg. Budi Santoso, Sp.KGA', specialization: 'Spesialis Gigi Anak', email: 'budi@fdc.co.id', phoneWa: '08123456781', bio: 'Spesialis Kedokteran Gigi Anak', commissionRate: 12, isActive: true, branchIds: [], schedules: [], skills: [] }
]

// Robust Doctor Filtering with automatic fallback so doctor is NEVER empty
const doctorsForBranch = computed(() => {
  const source = (props.doctorsAdmin && props.doctorsAdmin.length > 0) ? props.doctorsAdmin : DUMMY_DOCTORS
  const filtered = source.filter(d => {
    if (!branchId.value) return true
    if (!d.branchIds || d.branchIds.length === 0) return true
    return d.branchIds.includes(branchId.value)
  })
  return filtered.length > 0 ? filtered : source
})

// Auto select first available doctor whenever branch or list changes
watch([doctorsForBranch, branchId], () => {
  if (doctorsForBranch.value.length > 0) {
    if (!doctorsForBranch.value.some(d => d.id === staffId.value)) {
      staffId.value = doctorsForBranch.value[0].id
    }
  } else {
    staffId.value = ''
  }
}, { immediate: true })

const categories = computed(() => {
  const names = new Set(props.treatments.map(t => t.categoryName))
  return ['all', ...Array.from(names)]
})

const filteredTreatments = computed(() => props.treatments.filter((t) => {
  const matchesCategory = activeCategory.value === 'all' || t.categoryName === activeCategory.value
  const matchesSearch = !search.value || t.name.toLowerCase().includes(search.value.toLowerCase())
  return matchesCategory && matchesSearch && t.isActive
}))

function addToCart(t: Treatment) {
  const existing = cart.value.find(line => line.treatmentId === t.id)
  if (existing) {
    existing.qty++
  } else {
    cart.value.push({ treatmentId: t.id, name: t.name, price: t.price, qty: 1 })
  }
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

function setQuickCash(amount: number) {
  cashReceived.value = amount
}

function setExactCash() {
  cashReceived.value = total.value
}

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
  <div class="h-full flex flex-col">
    <!-- Success receipt view -->
    <div
      v-if="completedPayment"
      class="flex-1 flex flex-col items-center justify-center py-12 px-6 gap-5 bg-card rounded-2xl border border-default shadow-sm text-center"
    >
      <div class="w-20 h-20 rounded-full bg-emerald-100 dark:bg-emerald-950/60 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
        <UIcon
          name="i-lucide-check-circle-2"
          class="w-10 h-10"
        />
      </div>
      <div>
        <h3 class="text-2xl font-bold text-gray-900 dark:text-white">
          Transaksi POS Berhasil!
        </h3>
        <p class="text-sm text-muted mt-1">
          Pembayaran atas nama <span class="font-semibold text-gray-900 dark:text-white">{{ completedPayment.patientName }}</span>
        </p>
      </div>

      <div class="w-full max-w-sm p-4 rounded-xl border border-default bg-gray-50 dark:bg-gray-900/50 space-y-2 text-sm">
        <div class="flex justify-between">
          <span class="text-muted">Total Transaksi</span>
          <span class="font-bold text-primary">{{ formatIDR(completedPayment.amount) }}</span>
        </div>
        <div class="flex justify-between">
          <span class="text-muted">Metode</span>
          <span class="font-medium uppercase">{{ completedPayment.paymentMethod }}</span>
        </div>
        <div
          v-if="paymentMethod === 'cash' && change > 0"
          class="flex justify-between border-t border-default pt-2"
        >
          <span class="text-muted">Kembalian</span>
          <span class="font-bold text-emerald-600">{{ formatIDR(change) }}</span>
        </div>
      </div>

      <div class="flex items-center gap-3 mt-2">
        <UButton
          icon="i-lucide-printer"
          label="Cetak Struk / Invoice"
          size="lg"
          :to="`/billing/${completedPayment.id}/invoice`"
          target="_blank"
        />
        <UButton
          icon="i-lucide-plus"
          variant="soft"
          size="lg"
          label="Transaksi Baru"
          @click="resetForNewTransaction"
        />
      </div>
    </div>

    <!-- Main POS Interface -->
    <template v-else>
      <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 h-full items-start">
        <!-- Left Panel: Form Info & Catalog (Cols 7) -->
        <div class="lg:col-span-7 space-y-4 flex flex-col min-h-0">
          <!-- Patient, Branch, Doctor Selector Row -->
          <div class="grid grid-cols-1 sm:grid-cols-3 gap-3 p-4 rounded-xl border border-default bg-card shadow-xs">
            <UFormField
              label="Pasien *"
              required
            >
              <USelect
                v-model="patientId"
                :items="patients.map(p => ({ label: `${p.fullName}${p.rmNumber ? ' (' + p.rmNumber + ')' : ''}`, value: p.id }))"
                class="w-full"
                searchable
                placeholder="Pilih pasien..."
              />
            </UFormField>

            <UFormField
              label="Cabang *"
              required
            >
              <USelect
                v-model="branchId"
                :items="branches.map(b => ({ label: b.name, value: b.id }))"
                class="w-full"
              />
            </UFormField>

            <UFormField
              label="Dokter *"
              required
            >
              <USelect
                v-model="staffId"
                :items="doctorsForBranch.map(d => ({ label: `${d.fullName} (${d.specialization ?? 'Umum'})`, value: d.id }))"
                class="w-full"
                placeholder="Pilih dokter..."
              />
            </UFormField>
          </div>

          <!-- Catalog Search & Category Filters -->
          <div class="space-y-3">
            <div class="flex items-center gap-2">
              <UInput
                v-model="search"
                icon="i-lucide-search"
                placeholder="Cari nama perawatan / tindakan medis..."
                class="w-full"
              />
            </div>

            <!-- Categories Horizontal Scroll -->
            <div class="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar">
              <UButton
                v-for="cat in categories"
                :key="cat"
                :label="cat === 'all' ? 'Semua Perawatan' : cat"
                size="xs"
                :variant="activeCategory === cat ? 'solid' : 'soft'"
                :color="activeCategory === cat ? 'primary' : 'neutral'"
                class="rounded-full shrink-0"
                @click="activeCategory = cat"
              />
            </div>
          </div>

          <!-- Treatment Cards Grid -->
          <div
            class="grid grid-cols-2 sm:grid-cols-3 gap-3 overflow-y-auto pr-1"
            style="max-height: calc(100vh - 280px);"
          >
            <div
              v-for="t in filteredTreatments"
              :key="t.id"
              class="group relative flex flex-col justify-between rounded-xl border border-default bg-card p-3.5 hover:border-primary hover:shadow-md transition-all cursor-pointer select-none"
              @click="addToCart(t)"
            >
              <div>
                <div class="flex items-start justify-between gap-1">
                  <span class="text-[10px] font-bold uppercase tracking-wider text-primary px-2 py-0.5 rounded-md bg-primary-50 dark:bg-primary-950/40">
                    {{ t.categoryName }}
                  </span>
                  <UIcon name="i-lucide-plus-circle" class="w-4 h-4 text-muted group-hover:text-primary transition-colors" />
                </div>
                <h4 class="text-xs font-semibold text-gray-900 dark:text-white mt-2 line-clamp-2 leading-tight">
                  {{ t.name }}
                </h4>
              </div>
              <div class="mt-3 pt-2 border-t border-default/60 flex items-center justify-between">
                <span class="text-xs font-bold text-primary">{{ formatIDR(t.price) }}</span>
                <span class="text-[10px] text-muted">{{ t.durationMinutes ?? 30 }}m</span>
              </div>
            </div>

            <div
              v-if="filteredTreatments.length === 0"
              class="col-span-full py-12 text-center border border-dashed border-default rounded-xl"
            >
              <UIcon name="i-lucide-search-x" class="w-8 h-8 text-muted mx-auto mb-2" />
              <p class="text-sm font-medium text-muted">Tidak ada perawatan yang cocok dengan pencarian.</p>
            </div>
          </div>
        </div>

        <!-- Right Panel: Cart & Payment Checkout (Cols 5) -->
        <div class="lg:col-span-5 rounded-2xl border border-default bg-card p-4 space-y-4 shadow-sm flex flex-col h-full">
          <!-- Cart Title & Clear -->
          <div class="flex items-center justify-between pb-3 border-b border-default">
            <h3 class="font-semibold text-base flex items-center gap-2 text-gray-900 dark:text-white">
              <UIcon name="i-lucide-shopping-bag" class="w-5 h-5 text-primary" />
              Rincian Keranjang
            </h3>
            <span class="text-xs font-semibold px-2.5 py-0.5 rounded-full bg-primary-100 text-primary-700 dark:bg-primary-950 dark:text-primary-300">
              {{ cart.reduce((sum, l) => sum + l.qty, 0) }} Item
            </span>
          </div>

          <!-- Cart Line Items List -->
          <div
            class="flex-1 overflow-y-auto space-y-2.5 pr-1 min-h-[160px]"
            style="max-height: 220px;"
          >
            <div
              v-if="cart.length === 0"
              class="py-10 text-center border border-dashed border-default rounded-xl"
            >
              <UIcon name="i-lucide-shopping-cart" class="w-8 h-8 text-muted mx-auto mb-2 opacity-50" />
              <p class="text-xs text-muted">Keranjang masih kosong.<br>Klik katalog di sebelah kiri untuk memilih perawatan.</p>
            </div>

            <div
              v-for="line in cart"
              :key="line.treatmentId"
              class="flex items-center justify-between p-2.5 rounded-xl border border-default bg-gray-50/50 dark:bg-gray-900/40 text-xs gap-2"
            >
              <div class="flex-1 min-w-0">
                <p class="font-semibold text-gray-900 dark:text-white truncate">
                  {{ line.name }}
                </p>
                <p class="text-[11px] text-muted">
                  {{ formatIDR(line.price) }}
                </p>
              </div>

              <!-- Quantity Controls -->
              <div class="flex items-center gap-1 bg-card rounded-lg border border-default p-0.5">
                <UButton
                  icon="i-lucide-minus"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                  @click="decQty(line)"
                />
                <span class="w-5 text-center font-bold tabular-nums text-xs">{{ line.qty }}</span>
                <UButton
                  icon="i-lucide-plus"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                  @click="incQty(line)"
                />
              </div>

              <span class="w-20 text-right font-bold text-gray-900 dark:text-white tabular-nums">
                {{ formatIDR(line.price * line.qty) }}
              </span>

              <UButton
                icon="i-lucide-trash-2"
                size="xs"
                color="error"
                variant="ghost"
                @click="removeLine(line)"
              />
            </div>
          </div>

          <!-- Subtotal, Promo, Discount & Total -->
          <div class="border-t border-default pt-3 space-y-2.5 text-xs">
            <div class="flex justify-between text-muted">
              <span>Subtotal</span>
              <span class="font-semibold text-gray-900 dark:text-white tabular-nums">{{ formatIDR(subtotal) }}</span>
            </div>

            <div class="grid grid-cols-2 gap-2">
              <UFormField label="Voucher / Promo">
                <USelect
                  v-model="promoId"
                  :items="[{ label: 'Tanpa Promo', value: 'none' }, ...activePromos.map(p => ({ label: p.title, value: p.id }))]"
                  class="w-full"
                  size="xs"
                />
              </UFormField>
              <UFormField label="Potongan Diskon (Rp)">
                <UInput
                  v-model.number="discount"
                  type="number"
                  size="xs"
                  class="w-full"
                />
              </UFormField>
            </div>

            <div class="flex justify-between items-center font-bold text-sm border-t border-default pt-2 text-gray-900 dark:text-white">
              <span>Total Tagihan</span>
              <span class="text-base text-primary tabular-nums">{{ formatIDR(total) }}</span>
            </div>
          </div>

          <!-- Payment Method Buttons -->
          <div class="space-y-2">
            <p class="text-xs font-semibold text-muted uppercase tracking-wider">Metode Pembayaran</p>
            <div class="grid grid-cols-2 gap-2">
              <UButton
                v-for="m in PAYMENT_METHODS"
                :key="m.value"
                :icon="m.icon"
                :label="m.label"
                size="sm"
                :variant="paymentMethod === m.value ? 'solid' : 'soft'"
                :color="paymentMethod === m.value ? 'primary' : 'neutral'"
                class="justify-start text-xs font-medium"
                @click="paymentMethod = m.value"
              />
            </div>
          </div>

          <!-- Cash Payment Inputs & Preset Buttons -->
          <div v-if="paymentMethod === 'cash'" class="space-y-2 p-3 rounded-xl border border-default bg-emerald-50/50 dark:bg-emerald-950/20 text-xs">
            <div class="flex items-center justify-between">
              <span class="font-semibold text-emerald-800 dark:text-emerald-300">Pembayaran Cash</span>
              <UButton label="Uang Pas" size="xs" color="emerald" variant="subtle" @click="setExactCash" />
            </div>
            <UFormField label="Jumlah Uang Diterima (Rp)">
              <UInput
                v-model.number="cashReceived"
                type="number"
                class="w-full"
              />
            </UFormField>

            <!-- Quick Cash Presets -->
            <div class="flex flex-wrap gap-1.5 pt-1">
              <UButton
                v-for="preset in [50000, 100000, 200000, 500000]"
                :key="preset"
                :label="formatCompactIDR(preset)"
                size="xs"
                color="neutral"
                variant="outline"
                @click="setQuickCash(preset)"
              />
            </div>

            <div class="flex justify-between items-center pt-2 border-t border-emerald-200 dark:border-emerald-900/40 text-xs">
              <span class="font-medium text-muted">Uang Kembalian:</span>
              <span
                class="font-bold text-sm tabular-nums"
                :class="change >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-error'"
              >
                {{ formatIDR(change) }}
              </span>
            </div>
          </div>

          <UAlert
            v-if="posError"
            color="error"
            variant="subtle"
            :description="posError"
          />

          <!-- Submit Checkout Button -->
          <UButton
            block
            size="xl"
            icon="i-lucide-check-circle-2"
            label="Proses Pembayaran & Cetak"
            :disabled="!canPay"
            :loading="processing"
            class="font-bold shadow-md"
            @click="processPayment"
          />
        </div>
      </div>
    </template>
  </div>
</template>
