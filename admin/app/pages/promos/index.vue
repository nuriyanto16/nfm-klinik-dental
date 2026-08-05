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

const page = ref(1)
const pageSize = 6

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

const totalPages = computed(() => Math.ceil(filteredVouchers.value.length / pageSize) || 1)
const paginatedVouchers = computed(() => {
  const start = (page.value - 1) * pageSize
  return filteredVouchers.value.slice(start, start + pageSize)
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

async function saveVoucher() {
  if (!form.title.trim()) return
  if (editingId.value) {
    const idx = vouchers.value.findIndex(v => v.id === editingId.value)
    const updated: AdminVoucherPromo = {
      ...vouchers.value[idx],
      title: form.title,
      voucherCode: (form.voucherCode || `PROMO${Date.now().toString().slice(-4)}`).toUpperCase(),
      bannerImageUrl: form.bannerImageUrl || null,
      description: form.description,
      discountType: form.discountType,
      discountValue: form.discountValue,
      minTransaction: form.minTransaction,
      maxUsageCount: form.maxUsageCount,
      targetCategory: form.targetCategory,
      isActive: form.isActive
    }
    if (idx !== -1) {
      vouchers.value[idx] = updated
    }
    try {
      await $fetch(apiUrl(`/content/promos/${editingId.value}`), { method: 'PUT', body: updated })
    } catch (e) {
      console.warn('API PUT promo error:', e)
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
    try {
      await $fetch(apiUrl('/content/promos'), { method: 'POST', body: newVoucher })
    } catch (e) {
      console.warn('API POST promo error:', e)
    }
  }
  showModal.value = false
  alert('Kode Voucher & Promo Mobile berhasil diperbarui!')
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

function onBannerFileSelected(event: Event) {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    const file = target.files[0]
    const reader = new FileReader()
    reader.onload = (e) => {
      if (e.target?.result) {
        form.bannerImageUrl = e.target.result as string
      }
    }
    reader.readAsDataURL(file)
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
    <div class="space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <UCard
          v-for="v in paginatedVouchers"
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

      <!-- Pagination Footer -->
      <div class="flex items-center justify-between px-4 py-3 bg-white dark:bg-gray-800 rounded-xl border text-xs text-gray-500 shadow-xs">
        <span>Menampilkan {{ paginatedVouchers.length }} dari {{ filteredVouchers.length }} promo voucher</span>
        <div class="flex items-center gap-2">
          <UButton icon="i-lucide-chevron-left" size="xs" color="neutral" variant="outline" :disabled="page <= 1" @click="page--" />
          <span class="font-semibold text-gray-900 dark:text-white">Hal {{ page }} / {{ totalPages }}</span>
          <UButton icon="i-lucide-chevron-right" size="xs" color="neutral" variant="outline" :disabled="page >= totalPages" @click="page++" />
        </div>
      </div>
    </div>

    <!-- Modal Form Create/Edit Voucher -->
    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Kode Voucher & Promo' : 'Buat Kode Voucher Baru'"
      :description="editingId ? 'Perbarui detail promo, nominal diskon, syarat & ketentuan, dan banner promo.' : 'Tambah voucher diskon baru yang dapat digunakan pasien di aplikasi mobile.'"
      class="sm:max-w-3xl"
    >
      <template #body>
        <form class="space-y-5 py-1" @submit.prevent="saveVoucher">
          <!-- Judul Promo -->
          <div>
            <label class="block text-xs font-bold text-gray-700 dark:text-gray-200 mb-1.5 flex items-center justify-between">
              <span>Judul Promo / Voucher <span class="text-rose-500">*</span></span>
              <span class="text-[10px] text-gray-400 font-normal">Tampil sebagai judul banner di mobile</span>
            </label>
            <UInput
              v-model="form.title"
              icon="i-lucide-tag"
              size="md"
              placeholder="mis. Promo Scaling 6-in-1 Super Clean"
              class="w-full"
            />
          </div>

          <!-- Kode Voucher & Tipe Diskon -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-gray-700 dark:text-gray-200 mb-1.5">
                Kode Voucher (Kapital) <span class="text-rose-500">*</span>
              </label>
              <UInput
                v-model="form.voucherCode"
                icon="i-lucide-barcode"
                size="md"
                placeholder="mis. SCALING50K"
                class="w-full font-mono text-sm uppercase tracking-wider"
                @input="(e: Event) => form.voucherCode = (e.target as HTMLInputElement).value.toUpperCase()"
              />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 dark:text-gray-200 mb-1.5">
                Tipe Diskon <span class="text-rose-500">*</span>
              </label>
              <div class="relative">
                <select
                  v-model="form.discountType"
                  class="w-full h-[38px] px-3 text-sm bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-primary-500 transition-all cursor-pointer"
                >
                  <option value="fixed">Nominal Potongan (Rp)</option>
                  <option value="percentage">Persentase (%)</option>
                </select>
              </div>
            </div>
          </div>

          <!-- Nilai Diskon & Min. Belanja Transaksi -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-gray-700 dark:text-gray-200 mb-1.5">
                Nilai Diskon {{ form.discountType === 'percentage' ? '(%)' : '(Rp)' }} <span class="text-rose-500">*</span>
              </label>
              <UInput
                v-model.number="form.discountValue"
                type="number"
                :step="form.discountType === 'percentage' ? 1 : 5000"
                icon="i-lucide-coins"
                size="md"
                class="w-full"
              />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 dark:text-gray-200 mb-1.5">
                Min. Belanja Transaksi (Rp)
              </label>
              <UInput
                v-model.number="form.minTransaction"
                type="number"
                step="25000"
                icon="i-lucide-wallet"
                size="md"
                class="w-full"
              />
            </div>
          </div>

          <!-- Target Category & Max Usage -->
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-gray-700 dark:text-gray-200 mb-1.5">
                Target Treatment / Kategori
              </label>
              <select
                v-model="form.targetCategory"
                class="w-full h-[38px] px-3 text-sm bg-white dark:bg-gray-900 border border-gray-300 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white focus:outline-hidden focus:ring-2 focus:ring-primary-500 transition-all cursor-pointer"
              >
                <option value="Semua Perawatan">Semua Perawatan</option>
                <option value="Pencegahan">Pencegahan & Scaling</option>
                <option value="Ortodonti">Ortodonti & Behel</option>
                <option value="Estetika">Estetika & Whitening</option>
                <option value="Gigi Anak">Gigi Anak (Nina Kidz)</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 dark:text-gray-200 mb-1.5">
                Kuota Maksimal Klaim
              </label>
              <UInput
                v-model.number="form.maxUsageCount"
                type="number"
                step="10"
                icon="i-lucide-users"
                size="md"
                placeholder="100"
                class="w-full"
              />
            </div>
          </div>

          <!-- Banner Image Upload & URL Preview -->
          <div class="space-y-2">
            <label class="block text-xs font-bold text-gray-700 dark:text-gray-200">
              Banner Foto Promo / Banner Voucher
            </label>
            <div class="space-y-3 bg-gray-50 dark:bg-gray-900/60 p-3.5 rounded-xl border border-gray-200 dark:border-gray-800">
              <div class="flex items-center gap-3">
                <UInput
                  v-model="form.bannerImageUrl"
                  icon="i-lucide-image"
                  size="sm"
                  placeholder="Paste URL foto banner (https://images.unsplash.com/...)"
                  class="flex-1"
                />
                <label class="px-3 py-1.5 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-700 rounded-lg text-xs font-semibold text-gray-700 dark:text-gray-200 hover:bg-gray-100 dark:hover:bg-gray-700 cursor-pointer transition-colors shrink-0 flex items-center gap-1.5">
                  <UIcon name="i-lucide-upload-cloud" class="w-4 h-4 text-primary-600" />
                  <span>Upload File</span>
                  <input type="file" accept="image/*" class="hidden" @change="onBannerFileSelected">
                </label>
              </div>

              <!-- Banner Preview Box -->
              <div v-if="form.bannerImageUrl" class="relative rounded-lg overflow-hidden border border-gray-200 dark:border-gray-700 bg-gray-100 dark:bg-gray-800 h-28 flex items-center justify-center">
                <img :src="form.bannerImageUrl" class="w-full h-full object-cover" alt="Banner Preview">
                <div class="absolute top-2 right-2 flex gap-1">
                  <span class="px-2 py-0.5 bg-black/60 backdrop-blur-xs text-white text-[10px] font-semibold rounded-md">Preview Banner</span>
                  <button type="button" class="p-1 bg-red-600/80 hover:bg-red-600 text-white rounded-md transition-colors" @click="form.bannerImageUrl = ''">
                    <UIcon name="i-lucide-x" class="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            </div>
          </div>

          <!-- Keterangan / Syarat & Ketentuan -->
          <div>
            <div class="flex items-center justify-between mb-1.5">
              <label class="block text-xs font-bold text-gray-700 dark:text-gray-200">
                Keterangan / Syarat & Ketentuan <span class="text-rose-500">*</span>
              </label>
              <span class="text-[10px] text-gray-400">Tampil lengkap di detail voucher mobile</span>
            </div>
            <UTextarea
              v-model="form.description"
              :rows="4"
              size="md"
              placeholder="Tuliskan deskripsi lengkap promo, contoh: Paket scaling lengkap pembersihan karang gigi + polishing + fluoridasi hanya Rp149.000, berlaku untuk reservasi di cabang Soreang & Baleendah."
              class="w-full text-sm leading-relaxed"
            />
            <p class="text-[11px] text-gray-400 mt-1">
              Catatan: Berikan penjelasan yang jelas mengenai syarat berlaku, cabang klinik, dan instruksi penukaran voucher.
            </p>
          </div>

          <!-- Status Tayang Mobile Toggle Switch -->
          <div class="flex items-center justify-between bg-gray-50 dark:bg-gray-900/60 p-3.5 rounded-xl border border-gray-200 dark:border-gray-800">
            <div class="flex items-center gap-3">
              <div class="p-2 rounded-lg" :class="form.isActive ? 'bg-emerald-100 dark:bg-emerald-950 text-emerald-600' : 'bg-gray-200 dark:bg-gray-800 text-gray-400'">
                <UIcon name="i-lucide-smartphone" class="w-5 h-5" />
              </div>
              <div>
                <p class="text-xs font-bold text-gray-900 dark:text-white">Tayangkan di Aplikasi Mobile</p>
                <p class="text-[11px] text-gray-500 dark:text-gray-400">Pasien dapat melihat dan mengklaim kode voucher ini dari aplikasi.</p>
              </div>
            </div>
            <label class="relative inline-flex items-center cursor-pointer shrink-0">
              <input v-model="form.isActive" type="checkbox" class="sr-only peer">
              <div class="w-11 h-6 bg-gray-200 peer-focus:outline-hidden rounded-full peer dark:bg-gray-700 peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-600" />
            </label>
          </div>

          <!-- Action Footer -->
          <div class="flex items-center justify-end gap-3 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton
              label="Batal"
              color="neutral"
              variant="soft"
              size="md"
              @click="showModal = false"
            />
            <UButton
              type="submit"
              color="primary"
              variant="solid"
              size="md"
              icon="i-lucide-check"
              :label="editingId ? 'Simpan Perubahan Voucher' : 'Buat Voucher Baru'"
              class="font-bold shadow-sm"
            />
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>
