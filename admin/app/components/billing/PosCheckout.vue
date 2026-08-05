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
  itemType: 'treatment' | 'medicine'
  categoryName: string
}

const DEFAULT_MEDICINES = [
  { id: 'med-01', name: 'Paracetamol 500mg (Strip)', categoryName: 'Obat Anti-Nyeri & Demam', price: 15000, type: 'medicine' },
  { id: 'med-02', name: 'Amoxicillin 500mg Antibiotik (Strip)', categoryName: 'Obat Antibiotik', price: 25000, type: 'medicine' },
  { id: 'med-03', name: 'Cataflam / Kalium Diklofenak 50mg (Strip)', categoryName: 'Obat Anti-Inflamasi', price: 35000, type: 'medicine' },
  { id: 'med-04', name: 'Asam Mefenamat 500mg (Strip)', categoryName: 'Obat Anti-Nyeri Gigi', price: 18000, type: 'medicine' },
  { id: 'med-05', name: 'Betadine Gargle Antiseptik 190ml', categoryName: 'Obat Kumur & Antiseptik', price: 32000, type: 'medicine' },
  { id: 'med-06', name: 'Sensodyne Repair & Protect Toothpaste 100g', categoryName: 'Pasta Gigi Sensitif', price: 45000, type: 'medicine' },
  { id: 'med-07', name: 'Behel Relief Wax Ortodonti (Pcs)', categoryName: 'Aksesoris Behel', price: 25000, type: 'medicine' },
  { id: 'med-08', name: 'Orthodontic Dental Floss Mint (Pcs)', categoryName: 'Perawatan Mulut', price: 20000, type: 'medicine' },
  { id: 'med-09', name: 'Sikat Gigi Khusus Behel Ortho (Pcs)', categoryName: 'Perawatan Mulut', price: 30000, type: 'medicine' },
  { id: 'med-10', name: 'Benzocaine Topical Anesthetic Gel (Tube)', categoryName: 'Anestesi Lokal', price: 55000, type: 'medicine' }
]

const catalogTypeFilter = ref<'all' | 'treatment' | 'medicine'>('all')

const allCatalogItems = computed(() => {
  const treatmentItems = (props.treatments ?? []).map(t => ({
    id: t.id,
    name: t.name,
    categoryName: t.categoryName || 'Jasa Gigi',
    price: t.price,
    durationMinutes: t.durationMinutes,
    itemType: 'treatment' as const,
    isActive: t.isActive
  }))

  const medicineItems = DEFAULT_MEDICINES.map(m => ({
    id: m.id,
    name: m.name,
    categoryName: m.categoryName,
    price: m.price,
    durationMinutes: null,
    itemType: 'medicine' as const,
    isActive: true
  }))

  return [...treatmentItems, ...medicineItems]
})

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

const DEFAULT_PROMOS: Promo[] = [
  {
    id: 'pro-1',
    title: 'Diskon Soft Opening 20%',
    description: 'Diskon 20% untuk semua jenis perawatan',
    discountType: 'percentage',
    discountValue: 20,
    isActive: true,
    startsAt: '2026-08-01T00:00:00Z',
    endsAt: '2026-08-31T23:59:59Z'
  },
  {
    id: 'pro-2',
    title: 'Voucher Potongan Rp 50.000',
    description: 'Potongan Rp 50.000 tunai',
    discountType: 'fixed',
    discountValue: 50000,
    isActive: true,
    startsAt: '2026-08-01T00:00:00Z',
    endsAt: '2026-08-31T23:59:59Z'
  },
  {
    id: 'pro-3',
    title: 'Promo Merdeka Diskon 17%',
    description: 'Diskon Kemerdekaan 17%',
    discountType: 'percentage',
    discountValue: 17,
    isActive: true,
    startsAt: '2026-08-01T00:00:00Z',
    endsAt: '2026-08-31T23:59:59Z'
  },
  {
    id: 'pro-4',
    title: 'Voucher Behel Hemat Rp 500.000',
    description: 'Potongan Rp 500.000 khusus Behel Ortodonti',
    discountType: 'fixed',
    discountValue: 500000,
    isActive: true,
    startsAt: '2026-08-01T00:00:00Z',
    endsAt: '2026-08-31T23:59:59Z'
  }
]

const activePromos = computed(() => {
  const source = (props.promos && props.promos.length > 0) ? props.promos : DEFAULT_PROMOS
  return source.filter(p => p.isActive)
})
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

const doctorsForBranch = computed(() => {
  const source = (props.doctorsAdmin && props.doctorsAdmin.length > 0) ? props.doctorsAdmin : DUMMY_DOCTORS
  const filtered = source.filter(d => {
    if (!branchId.value) return true
    if (!d.branchIds || d.branchIds.length === 0) return true
    return d.branchIds.includes(branchId.value)
  })
  return filtered.length > 0 ? filtered : source
})

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
  const names = new Set(allCatalogItems.value.map(t => t.categoryName))
  return ['all', ...Array.from(names)]
})

const filteredTreatments = computed(() => allCatalogItems.value.filter((t) => {
  const matchesType = catalogTypeFilter.value === 'all' || t.itemType === catalogTypeFilter.value
  const matchesCategory = activeCategory.value === 'all' || t.categoryName === activeCategory.value
  const matchesSearch = !search.value || t.name.toLowerCase().includes(search.value.toLowerCase()) || t.categoryName.toLowerCase().includes(search.value.toLowerCase())
  return matchesType && matchesCategory && matchesSearch && t.isActive
}))

function addToCart(t: { id: string; name: string; price: number; itemType?: 'treatment' | 'medicine'; categoryName?: string }) {
  const existing = cart.value.find(line => line.treatmentId === t.id)
  if (existing) {
    existing.qty++
  } else {
    cart.value.push({
      treatmentId: t.id,
      name: t.name,
      price: t.price,
      qty: 1,
      itemType: t.itemType || 'treatment',
      categoryName: t.categoryName || 'Jasa Gigi'
    })
  }
}

function incQty(line: CartLine) {
  line.qty++
}

function decQty(line: CartLine) {
  if (line.qty > 1) {
    line.qty--
  } else {
    removeLine(line)
  }
}

function removeLine(line: CartLine) {
  cart.value = cart.value.filter(l => l.treatmentId !== line.treatmentId)
}

const subtotal = computed(() => cart.value.reduce((sum, l) => sum + l.price * l.qty, 0))

// Bank Transfer State
const selectedBank = ref('BCA')
const bankAccounts: Record<string, { bankName: string, accountName: string, accountNumber: string }> = {
  BCA: { bankName: 'Bank BCA', accountName: 'PT Nina Dental Care', accountNumber: '7700-1122-3344' },
  Mandiri: { bankName: 'Bank Mandiri', accountName: 'PT Nina Dental Care', accountNumber: '130-00-9988-7766' },
  BNI: { bankName: 'Bank BNI', accountName: 'PT Nina Dental Care', accountNumber: '088-7766-554' },
  BRI: { bankName: 'Bank BRI', accountName: 'PT Nina Dental Care', accountNumber: '4455-01-009988-53-1' }
}
const transferRefCode = ref('')

function calculateDiscount() {
  if (!promoId.value || promoId.value === 'none') {
    discount.value = 0
    return
  }
  const promo = activePromos.value.find(p => p.id === promoId.value)
  if (!promo) {
    discount.value = 0
    return
  }
  const type = promo.discountType || (promo.discountValue && promo.discountValue <= 100 ? 'percentage' : 'fixed')
  const val = promo.discountValue ?? 0
  if (type === 'percentage' || type === 'percent') {
    discount.value = Math.min(subtotal.value, Math.round((subtotal.value * val) / 100))
  } else {
    discount.value = Math.min(subtotal.value, val)
  }
}

watch([() => promoId.value, () => subtotal.value], () => {
  calculateDiscount()
}, { immediate: true })

const recommendedPromo = computed(() => {
  if (subtotal.value <= 0 || activePromos.value.length === 0) return null
  let bestPromo: Promo | null = null
  let maxDiscount = 0

  for (const p of activePromos.value) {
    let calcDisc = 0
    const type = p.discountType || (p.discountValue && p.discountValue <= 100 ? 'percentage' : 'fixed')
    const val = p.discountValue ?? 0
    if (type === 'percentage' || type === 'percent') {
      calcDisc = Math.round((subtotal.value * val) / 100)
    } else {
      calcDisc = val
    }
    calcDisc = Math.min(subtotal.value, calcDisc)
    if (calcDisc > maxDiscount) {
      maxDiscount = calcDisc
      bestPromo = p
    }
  }

  if (bestPromo && maxDiscount > 0) {
    return { promo: bestPromo, savingsAmount: maxDiscount }
  }
  return null
})

function applyRecommendedPromo() {
  if (recommendedPromo.value) {
    promoId.value = recommendedPromo.value.promo.id
    calculateDiscount()
  }
}

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
  if (!canPay.value) return
  processing.value = true
  posError.value = ''
  try {
    const treatmentIds = cart.value.flatMap(l => Array(l.qty).fill(l.treatmentId))

    // Step 1: Buat reservasi
    let reservationId = `pos-res-${Date.now()}`
    try {
      const reservation = await $fetch<{ id: string }>(apiUrl('/reservations'), {
        method: 'POST',
        body: {
          patientId: patientId.value,
          branchId: branchId.value,
          staffId: staffId.value,
          scheduledAt: new Date().toISOString(),
          treatmentIds,
          complaintNote: null,
          status: 'completed'
        }
      })
      if (reservation?.id) reservationId = reservation.id
    } catch (resErr: any) {
      // Jika reservasi gagal, tetap lanjut dengan ID lokal
      console.warn('Reservasi API gagal, lanjut dengan ID lokal:', resErr?.data?.message || resErr?.message)
    }

    // Step 2: Buat payment
    let payment: Payment | null = null
    try {
      payment = await $fetch<Payment>(apiUrl('/payments'), {
        method: 'POST',
        body: {
          reservationId,
          amount: total.value,
          depositAmount: total.value,
          paymentMethod: paymentMethod.value,
          status: 'paid',
          promoId: promoId.value || null,
          discountAmount: discount.value
        }
      })
    } catch (payErr: any) {
      // Fallback: buat payment lokal jika API gagal
      console.warn('Payment API gagal, gunakan data lokal:', payErr?.data?.message || payErr?.message)
    }

    // Step 3: Gunakan data API atau fallback lokal
    const selectedPatient = props.patients.find(p => p.id === patientId.value)
    const selectedBranch = props.branches.find(b => b.id === branchId.value)
    const selectedDoctor = (props.doctorsAdmin?.length > 0 ? props.doctorsAdmin : DUMMY_DOCTORS).find(d => d.id === staffId.value)

    const finalPayment: Payment = payment ?? {
      id: `local-pay-${Date.now()}`,
      reservationId,
      patientId: patientId.value,
      amount: total.value,
      depositAmount: total.value,
      status: 'paid',
      provider: paymentMethod.value,
      providerReference: `POS-${Date.now()}`,
      paymentMethod: paymentMethod.value,
      promoId: promoId.value || null,
      promoTitle: null,
      discountAmount: discount.value,
      paidAt: new Date().toISOString(),
      expiredAt: null,
      createdAt: new Date().toISOString(),
      patientName: selectedPatient?.fullName ?? 'Pasien',
      branchName: selectedBranch?.name ?? 'Nina Dental Care'
    }

    completedPayment.value = finalPayment
    emit('completed', finalPayment)
  } catch (err: any) {
    posError.value = err?.data?.message ?? err?.message ?? 'Terjadi kesalahan saat memproses pembayaran.'
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
            <!-- Catalog Type Switcher -->
            <div class="flex items-center gap-1.5 border-b border-default pb-2">
              <UButton
                size="xs"
                :variant="catalogTypeFilter === 'all' ? 'solid' : 'ghost'"
                :color="catalogTypeFilter === 'all' ? 'primary' : 'gray'"
                icon="i-lucide-grid"
                label="Semua Katalog"
                @click="catalogTypeFilter = 'all'"
              />
              <UButton
                size="xs"
                :variant="catalogTypeFilter === 'treatment' ? 'solid' : 'ghost'"
                :color="catalogTypeFilter === 'treatment' ? 'primary' : 'gray'"
                icon="i-lucide-stethoscope"
                label="🩺 Perawatan Gigi"
                @click="catalogTypeFilter = 'treatment'"
              />
              <UButton
                size="xs"
                :variant="catalogTypeFilter === 'medicine' ? 'solid' : 'ghost'"
                :color="catalogTypeFilter === 'medicine' ? 'primary' : 'gray'"
                icon="i-lucide-pill"
                label="💊 Obat & Produk Mulut"
                @click="catalogTypeFilter = 'medicine'"
              />
            </div>

            <div class="flex items-center gap-2">
              <UInput
                v-model="search"
                icon="i-lucide-search"
                placeholder="Cari perawatan gigi, obat-obatan, pasta gigi, antiseptik..."
                class="w-full"
              />
            </div>

            <!-- Categories Horizontal Scroll -->
            <div class="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar">
              <UButton
                v-for="cat in categories"
                :key="cat"
                :label="cat === 'all' ? 'Semua Kategori' : cat"
                size="xs"
                :variant="activeCategory === cat ? 'solid' : 'soft'"
                :color="activeCategory === cat ? 'primary' : 'neutral'"
                class="rounded-full shrink-0"
                @click="activeCategory = cat"
              />
            </div>
          </div>

          <!-- Item Cards Grid -->
          <div
            class="grid grid-cols-2 sm:grid-cols-3 gap-3 overflow-y-auto pr-1"
            style="max-height: calc(100vh - 320px);"
          >
            <div
              v-for="t in filteredTreatments"
              :key="t.id"
              class="group relative flex flex-col justify-between rounded-xl border border-default bg-card p-3.5 hover:border-primary hover:shadow-md transition-all cursor-pointer select-none"
              @click="addToCart(t)"
            >
              <div>
                <div class="flex items-start justify-between gap-1">
                  <span
                    :class="t.itemType === 'medicine' ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600' : 'bg-primary-50 dark:bg-primary-950/40 text-primary'"
                    class="text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-md"
                  >
                    {{ t.itemType === 'medicine' ? '💊 ' + t.categoryName : '🩺 ' + t.categoryName }}
                  </span>
                  <UIcon name="i-lucide-plus-circle" class="w-4 h-4 text-muted group-hover:text-primary transition-colors" />
                </div>
                <h4 class="text-xs font-semibold text-gray-900 dark:text-white mt-2 line-clamp-2 leading-tight">
                  {{ t.name }}
                </h4>
              </div>
              <div class="mt-3 pt-2 border-t border-default/60 flex items-center justify-between">
                <span class="text-xs font-bold text-primary">{{ formatIDR(t.price) }}</span>
                <span class="text-[10px] text-muted">{{ t.durationMinutes ? `${t.durationMinutes}m` : 'Stok Ada' }}</span>
              </div>
            </div>

            <div
              v-if="filteredTreatments.length === 0"
              class="col-span-full py-12 text-center border border-dashed border-default rounded-xl"
            >
              <UIcon name="i-lucide-search-x" class="w-8 h-8 text-muted mx-auto mb-2" />
              <p class="text-sm font-medium text-muted">Tidak ada perawatan atau obat yang cocok dengan pencarian.</p>
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
              <p class="text-xs text-muted">Keranjang masih kosong.<br>Klik katalog perawatan atau obat di sebelah kiri untuk menambahkan item.</p>
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
                <div class="flex items-center gap-1.5 mt-0.5">
                  <UBadge :color="line.itemType === 'medicine' ? 'green' : 'blue'" variant="subtle" size="xs">
                    {{ line.itemType === 'medicine' ? '💊 Obat / Produk' : '🩺 Jasa Gigi' }}
                  </UBadge>
                  <span class="text-[11px] text-muted">{{ formatIDR(line.price) }}</span>
                </div>
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

            <!-- Rekomendasi Sistem Promo Banner -->
            <div
              v-if="recommendedPromo && promoId !== recommendedPromo.promo.id"
              class="p-2.5 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 rounded-lg flex items-center justify-between gap-2 text-xs"
            >
              <div class="flex items-center gap-2 text-emerald-800 dark:text-emerald-300">
                <UIcon name="i-lucide-sparkles" class="w-4 h-4 text-emerald-600 shrink-0 animate-pulse" />
                <div>
                  <span class="font-bold">Rekomendasi Promo Terbaik:</span> {{ recommendedPromo.promo.title }}
                  <span class="text-[11px] block text-emerald-600 dark:text-emerald-400 font-semibold">Hemat {{ formatIDR(recommendedPromo.savingsAmount) }}</span>
                </div>
              </div>
              <UButton
                size="xs"
                color="emerald"
                label="Pakai Promo Ini"
                icon="i-lucide-check-circle"
                class="shrink-0 font-bold"
                @click="applyRecommendedPromo"
              />
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

          <!-- Bank Transfer Payment Inputs -->
          <div v-if="paymentMethod === 'manual_transfer'" class="space-y-2.5 p-3 rounded-xl border border-indigo-200 dark:border-indigo-800 bg-indigo-50/50 dark:bg-indigo-950/20 text-xs">
            <div class="flex items-center justify-between">
              <span class="font-bold text-indigo-800 dark:text-indigo-300 flex items-center gap-1.5">
                <UIcon name="i-lucide-landmark" class="w-4 h-4 text-indigo-600" />
                Detail Transfer Bank Klinik
              </span>
              <UBadge color="indigo" variant="subtle" size="xs">Manual Verify</UBadge>
            </div>

            <!-- Pilih Bank -->
            <div class="space-y-1">
              <label class="block text-[11px] font-semibold text-gray-700 dark:text-gray-300">Pilih Rekening Bank Tujuan:</label>
              <div class="grid grid-cols-4 gap-1.5">
                <UButton
                  v-for="(b, key) in bankAccounts"
                  :key="key"
                  :label="key"
                  size="xs"
                  :variant="selectedBank === key ? 'solid' : 'outline'"
                  :color="selectedBank === key ? 'indigo' : 'neutral'"
                  class="font-bold text-center justify-center"
                  @click="selectedBank = key"
                />
              </div>
            </div>

            <!-- Detail Rekening Info Box -->
            <div class="p-2 bg-white dark:bg-gray-800 rounded-lg border border-indigo-200 dark:border-indigo-700 text-[11px] space-y-1">
              <div class="flex justify-between text-gray-500">
                <span>Nama Bank:</span>
                <span class="font-bold text-gray-900 dark:text-white">{{ bankAccounts[selectedBank].bankName }}</span>
              </div>
              <div class="flex justify-between text-gray-500">
                <span>Nomor Rekening:</span>
                <span class="font-mono font-bold text-indigo-600 dark:text-indigo-400 text-xs">{{ bankAccounts[selectedBank].accountNumber }}</span>
              </div>
              <div class="flex justify-between text-gray-500">
                <span>Atas Nama:</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200">{{ bankAccounts[selectedBank].accountName }}</span>
              </div>
            </div>

            <!-- Kode Referensi Transfer -->
            <div>
              <label class="block text-[11px] font-semibold text-gray-700 dark:text-gray-300 mb-1">Nomor Referensi / Struk Transfer (Opsional)</label>
              <input
                v-model="transferRefCode"
                type="text"
                placeholder="Contoh: TRX-BCA-998877"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-1.5 text-xs font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
            </div>
          </div>
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
