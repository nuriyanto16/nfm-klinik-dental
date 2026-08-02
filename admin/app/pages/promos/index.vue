<script setup lang="ts">
import type { Promo } from '~/types/api'

definePageMeta({ title: 'Promo & Kode Voucher' })

export interface AdminVoucherPromo extends Promo {
  voucherCode?: string
  minTransaction?: number
  maxUsageCount?: number
  usedCount?: number
  targetCategory?: string
}

const { data: apiPromos, refresh } = useApiFetch<Promo[]>('/content/promos')

const initialVouchers: AdminVoucherPromo[] = [
  {
    id: 'pro-1',
    title: 'Diskon Scaling 6-in-1 Super Clean',
    voucherCode: 'SCALING50K',
    bannerImageUrl: 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800&auto=format&fit=crop&q=80',
    description: 'Paket scaling lengkap pembersihan karang gigi + polishing + fluoridasi hanya Rp149.000.',
    startsAt: '2026-07-01T00:00:00Z',
    endsAt: '2026-08-31T23:59:59Z',
    isActive: true,
    discountType: 'fixed',
    discountValue: 50000,
    minTransaction: 150000,
    maxUsageCount: 100,
    usedCount: 38,
    targetCategory: 'Pencegahan'
  },
  {
    id: 'pro-2',
    title: 'Promo Spesial Behel Metal 10%',
    voucherCode: 'BEHEL10',
    bannerImageUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800&auto=format&fit=crop&q=80',
    description: 'Diskon 10% untuk pemasangan behel metal konvensional via aplikasi mobile.',
    startsAt: '2026-07-05T00:00:00Z',
    endsAt: '2026-08-15T23:59:59Z',
    isActive: true,
    discountType: 'percentage',
    discountValue: 10,
    minTransaction: 3000000,
    maxUsageCount: 50,
    usedCount: 12,
    targetCategory: 'Ortodonti'
  },
  {
    id: 'pro-3',
    title: 'Voucher New Patient Senyum Sehat',
    voucherCode: 'SMILESEHAT',
    bannerImageUrl: 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800&auto=format&fit=crop&q=80',
    description: 'Potongan Rp 30.000 khusus pasien baru pertama kali berkunjung ke Nina Dental Care.',
    startsAt: '2026-08-01T00:00:00Z',
    endsAt: '2026-09-30T23:59:59Z',
    isActive: true,
    discountType: 'fixed',
    discountValue: 30000,
    minTransaction: 100000,
    maxUsageCount: 200,
    usedCount: 84,
    targetCategory: 'Semua Perawatan'
  }
]

const vouchers = ref<AdminVoucherPromo[]>([...initialVouchers])

watch(apiPromos, val => {
  if (val && val.length > 0) {
    vouchers.value = val.map(p => ({
      ...p,
      voucherCode: p.title.includes('Scaling') ? 'SCALING50K' : p.title.includes('Behel') ? 'BEHEL10' : 'SMILE2026',
      minTransaction: 100000,
      maxUsageCount: 100,
      usedCount: 15,
      targetCategory: 'Semua Perawatan'
    }))
  }
}, { immediate: true })

const filterStatus = ref<'all' | 'active' | 'inactive'>('active')
const searchQuery = ref('')

const filteredVouchers = computed(() => {
  return vouchers.value.filter(v => {
    if (filterStatus.value === 'active' && !v.isActive) return false
    if (filterStatus.value === 'inactive' && v.isActive) return false

    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase().trim()
      const matchTitle = v.title.toLowerCase().includes(q)
      const matchCode = (v.voucherCode || '').toLowerCase().includes(q)
      return matchTitle || matchCode
    }
    return true
  })
})

const stats = computed(() => {
  const activeCount = vouchers.value.filter(v => v.isActive).length
  const totalClaims = vouchers.value.reduce((s, v) => s + (v.usedCount || 0), 0)
  const totalSaved = vouchers.value.reduce((s, v) => s + ((v.usedCount || 0) * (v.discountValue || 0)), 0)

  return { activeCount, totalClaims, totalSaved }
})

// --- Form create & edit ---
const showModal = ref(false)
const editingId = ref<string | null>(null)
const form = reactive({
  title: '',
  voucherCode: '',
  bannerImageUrl: '',
  description: '',
  discountType: 'fixed' as 'fixed' | 'percentage',
  discountValue: 50000,
  minTransaction: 100000,
  maxUsageCount: 100,
  targetCategory: 'Semua Perawatan',
  isActive: true
})

function openCreate() {
  editingId.value = null
  form.title = ''
  form.voucherCode = ''
  form.bannerImageUrl = 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800'
  form.description = ''
  form.discountType = 'fixed'
  form.discountValue = 50000
  form.minTransaction = 100000
  form.maxUsageCount = 100
  form.targetCategory = 'Semua Perawatan'
  form.isActive = true
  showModal.value = true
}

function openEdit(v: AdminVoucherPromo) {
  editingId.value = v.id
  form.title = v.title
  form.voucherCode = v.voucherCode || ''
  form.bannerImageUrl = v.bannerImageUrl || ''
  form.description = v.description || ''
  form.discountType = v.discountType || 'fixed'
  form.discountValue = v.discountValue || 0
  form.minTransaction = v.minTransaction || 0
  form.maxUsageCount = v.maxUsageCount || 100
  form.targetCategory = v.targetCategory || 'Semua Perawatan'
  form.isActive = v.isActive
  showModal.value = true
}

function saveVoucher() {
  if (!form.title.trim()) return
  if (editingId.value) {
    const idx = vouchers.value.findIndex(v => v.id === editingId.value)
    if (idx !== -1) {
      vouchers.value[idx] = {
        ...vouchers.value[idx],
        title: form.title,
        voucherCode: form.voucherCode.toUpperCase(),
        bannerImageUrl: form.bannerImageUrl || null,
        description: form.description,
        discountType: form.discountType,
        discountValue: form.discountValue,
        minTransaction: form.minTransaction,
        maxUsageCount: form.maxUsageCount,
        targetCategory: form.targetCategory,
        isActive: form.isActive
      }
    }
  } else {
    const newVoucher: AdminVoucherPromo = {
      id: `pro-${Date.now()}`,
      title: form.title,
      voucherCode: (form.voucherCode || `PROMO${Date.now().toString().slice(-4)}`).toUpperCase(),
      bannerImageUrl: form.bannerImageUrl || 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800',
      description: form.description,
      startsAt: new Date().toISOString(),
      endsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: form.isActive,
      discountType: form.discountType,
      discountValue: form.discountValue,
      minTransaction: form.minTransaction,
      maxUsageCount: form.maxUsageCount,
      usedCount: 0,
      targetCategory: form.targetCategory
    }
    vouchers.value.unshift(newVoucher)
  }
  showModal.value = false
}

function toggleActive(v: AdminVoucherPromo) {
  v.isActive = !v.isActive
}

function copyCode(code?: string) {
  if (code) {
    navigator.clipboard.writeText(code)
    alert(`Kode Voucher "${code}" disalin!`)
  }
}
</script>

<template>
  <div class="p-6 space-y-6 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          Manajemen Promo & Kode Voucher Mobile
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Kelola voucher diskon, banner promo spesial, kuota penggunaan, dan penyebaran ke aplikasi mobile.
        </p>
      </div>

      <UButton
        icon="i-lucide-plus"
        label="+ Buat Kode Voucher Baru"
        color="primary"
        @click="openCreate"
      />
    </div>

    <!-- Summary Stats -->
    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Voucher & Promo Aktif
            </p>
            <p class="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1">
              {{ stats.activeCount }} Banner Active
            </p>
          </div>
          <div class="p-3 bg-emerald-50 dark:bg-emerald-950/30 text-emerald-600 rounded-xl">
            <UIcon name="i-lucide-ticket-percent" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Total Klaim Pasien
            </p>
            <p class="text-2xl font-extrabold text-blue-600 dark:text-blue-400 mt-1">
              {{ stats.totalClaims }} Kali Dihitung
            </p>
          </div>
          <div class="p-3 bg-blue-50 dark:bg-blue-950/30 text-blue-600 rounded-xl">
            <UIcon name="i-lucide-users" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Est. Total Potongan Hemat
            </p>
            <p class="text-2xl font-extrabold text-purple-600 dark:text-purple-400 mt-1">
              {{ formatIDR(stats.totalSaved) }}
            </p>
          </div>
          <div class="p-3 bg-purple-50 dark:bg-purple-950/30 text-purple-600 rounded-xl">
            <UIcon name="i-lucide-piggy-bank" class="w-6 h-6" />
          </div>
        </div>
      </UCard>
    </div>

    <!-- Filter & Search Bar -->
    <div class="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white dark:bg-gray-800 p-3 rounded-xl border border-gray-200 dark:border-gray-700">
      <div class="flex items-center gap-2">
        <UButton
          :variant="filterStatus === 'active' ? 'solid' : 'ghost'"
          :color="filterStatus === 'active' ? 'primary' : 'gray'"
          size="xs"
          label="Aktif Tayang"
          @click="filterStatus = 'active'"
        />
        <UButton
          :variant="filterStatus === 'inactive' ? 'solid' : 'ghost'"
          :color="filterStatus === 'inactive' ? 'amber' : 'gray'"
          size="xs"
          label="Non-Aktif / Arsip"
          @click="filterStatus = 'inactive'"
        />
        <UButton
          :variant="filterStatus === 'all' ? 'solid' : 'ghost'"
          color="gray"
          size="xs"
          label="Semua"
          @click="filterStatus = 'all'"
        />
      </div>

      <UInput
        v-model="searchQuery"
        icon="i-lucide-search"
        placeholder="Cari promo atau kode voucher..."
        size="sm"
        class="w-full sm:w-64"
      />
    </div>

    <!-- Promos & Vouchers Cards Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <UCard
        v-for="v in filteredVouchers"
        :key="v.id"
        class="bg-white dark:bg-gray-800 flex flex-col justify-between overflow-hidden shadow-xs hover:shadow-md transition-shadow"
      >
        <div class="space-y-3">
          <!-- Banner Image -->
          <div class="relative">
            <img
              :src="v.bannerImageUrl || 'https://images.unsplash.com/photo-1629909613654-28e377c37b09?w=800'"
              class="w-full h-40 object-cover rounded-lg"
            >
            <div class="absolute top-2 right-2 flex gap-1">
              <UBadge :color="v.isActive ? 'green' : 'gray'" size="xs" variant="solid">
                {{ v.isActive ? 'Aktif Tayang' : 'Non-aktif' }}
              </UBadge>
            </div>
          </div>

          <!-- Voucher Code Pill -->
          <div class="flex items-center justify-between bg-primary-50 dark:bg-primary-950/40 p-2.5 rounded-lg border border-primary-200 dark:border-primary-800">
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-ticket-percent" class="w-5 h-5 text-primary" />
              <div>
                <span class="text-[10px] uppercase font-bold text-gray-500 block">Kode Voucher</span>
                <span class="font-mono font-extrabold text-sm text-primary tracking-wider">{{ v.voucherCode || 'TIDAK-ADA' }}</span>
              </div>
            </div>
            <UButton
              size="xs"
              color="primary"
              variant="soft"
              icon="i-lucide-copy"
              label="Salin"
              @click="copyCode(v.voucherCode)"
            />
          </div>

          <!-- Title & Description -->
          <h3 class="font-bold text-base text-gray-900 dark:text-white line-clamp-1">{{ v.title }}</h3>
          <p class="text-xs text-gray-500 dark:text-gray-400 line-clamp-2">{{ v.description }}</p>

          <!-- Details Grid -->
          <div class="grid grid-cols-2 gap-2 text-xs bg-gray-50 dark:bg-gray-900 p-2.5 rounded-lg">
            <div>
              <span class="text-gray-400 block text-[10px]">Nilai Diskon</span>
              <span class="font-bold text-emerald-600">
                {{ v.discountType === 'percentage' ? `${v.discountValue}%` : formatIDR(v.discountValue || 0) }}
              </span>
            </div>
            <div>
              <span class="text-gray-400 block text-[10px]">Penggunaan Kuota</span>
              <span class="font-semibold text-gray-800 dark:text-gray-200">
                {{ v.usedCount || 0 }} / {{ v.maxUsageCount || '100' }} Klaim
              </span>
            </div>
            <div>
              <span class="text-gray-400 block text-[10px]">Min. Transaksi</span>
              <span class="font-semibold text-gray-800 dark:text-gray-200">{{ formatIDR(v.minTransaction || 0) }}</span>
            </div>
            <div>
              <span class="text-gray-400 block text-[10px]">Target Treatment</span>
              <span class="font-semibold text-gray-800 dark:text-gray-200">{{ v.targetCategory || 'Semua' }}</span>
            </div>
          </div>
        </div>

        <!-- Action Buttons -->
        <div class="flex items-center justify-between pt-4 border-t border-gray-100 dark:border-gray-700 mt-4">
          <UButton
            size="xs"
            :color="v.isActive ? 'amber' : 'green'"
            variant="ghost"
            :icon="v.isActive ? 'i-lucide-eye-off' : 'i-lucide-eye'"
            :label="v.isActive ? 'Sembunyikan' : 'Aktifkan'"
            @click="toggleActive(v)"
          />
          <UButton
            size="xs"
            color="primary"
            variant="soft"
            icon="i-lucide-edit-2"
            label="Edit Voucher"
            @click="openEdit(v)"
          />
        </div>
      </UCard>
    </div>

    <!-- Modal Form Create/Edit Voucher -->
    <UModal v-model="showModal">
      <UCard class="bg-white dark:bg-gray-800">
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-base text-gray-900 dark:text-white">
              {{ editingId ? 'Edit Kode Voucher' : 'Buat Kode Voucher Baru' }}
            </h3>
            <UButton icon="i-lucide-x" color="gray" variant="ghost" @click="showModal = false" />
          </div>
        </template>

        <form class="space-y-4" @submit.prevent="saveVoucher">
          <div>
            <label class="block text-xs font-semibold mb-1">Judul Promo / Voucher</label>
            <UInput v-model="form.title" placeholder="mis. Promo Scaling 6-in-1 Super Clean" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold mb-1">Kode Voucher (Kapital)</label>
              <UInput v-model="form.voucherCode" placeholder="mis. SCALING50K" />
            </div>
            <div>
              <label class="block text-xs font-semibold mb-1">Tipe Diskon</label>
              <select v-model="form.discountType" class="w-full p-2 text-xs border rounded bg-white dark:bg-gray-800">
                <option value="fixed">Nominal Potongan (Rp)</option>
                <option value="percentage">Persentase (%)</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold mb-1">Nilai Diskon</label>
              <UInput v-model.number="form.discountValue" type="number" step="5000" />
            </div>
            <div>
              <label class="block text-xs font-semibold mb-1">Min. Belanja Transaksi (Rp)</label>
              <UInput v-model.number="form.minTransaction" type="number" step="50000" />
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">URL Banner Foto Promo</label>
            <UInput v-model="form.bannerImageUrl" placeholder="https://images.unsplash.com/..." />
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Keterangan / Syarat & Ketentuan</label>
            <UTextarea v-model="form.description" rows="2" placeholder="Berlaku untuk reservasi jadwal via aplikasi..." />
          </div>

          <div class="flex items-center gap-2 pt-2">
            <input id="vActive" v-model="form.isActive" type="checkbox" class="rounded text-primary">
            <label for="vActive" class="text-xs font-semibold">Tayangkan di Aplikasi Mobile</label>
          </div>

          <div class="flex justify-end gap-2 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton label="Batal" color="gray" variant="ghost" @click="showModal = false" />
            <UButton label="Simpan Voucher" color="primary" type="submit" />
          </div>
        </form>
      </UCard>
    </UModal>
  </div>
</template>
