<script setup lang="ts">
import type { Treatment, TreatmentCategory, TreatmentInput } from '~/types/api'

definePageMeta({ title: 'Perawatan & Harga' })

const { data: apiTreatments, status, refresh } = useApiFetch<Treatment[]>('/treatments')
const { data: apiCategories } = useApiFetch<TreatmentCategory[]>('/treatment-categories')

// ── Dummy / fallback data ───────────────────────────────────────────────────
const initialTreatments: Treatment[] = [
  { id: '41-001', categoryId: 'cat-umum', name: 'Scaling Gigi (Pembersihan Karang Gigi)', categoryName: 'Umum', description: 'Pembersihan karang gigi secara komprehensif menggunakan ultrasonic scaler.', price: 350000, durationMinutes: 30, imageUrl: null, isActive: true },
  { id: '41-002', categoryId: 'cat-umum', name: 'Tambal Gigi (Komposit)', categoryName: 'Umum', description: 'Penambalan gigi berlubang menggunakan bahan komposit sewarna gigi.', price: 250000, durationMinutes: 30, imageUrl: null, isActive: true },
  { id: '41-003', categoryId: 'cat-umum', name: 'Cabut Gigi Dewasa', categoryName: 'Umum', description: 'Pencabutan gigi permanen dengan anestesi lokal.', price: 300000, durationMinutes: 30, imageUrl: null, isActive: true },
  { id: '41-004', categoryId: 'cat-umum', name: 'Bleaching (Pemutihan Gigi)', categoryName: 'Umum', description: 'Pemutihan gigi instan menggunakan gel bleaching profesional.', price: 1500000, durationMinutes: 60, imageUrl: null, isActive: true },
  { id: '41-005', categoryId: 'cat-ortho', name: 'Behel Metal Konvensional', categoryName: 'Behel & Ortodonti', description: 'Pemasangan bracket metal standar untuk koreksi susunan gigi.', price: 6500000, durationMinutes: 60, imageUrl: null, isActive: true },
  { id: '41-006', categoryId: 'cat-ortho', name: 'Behel Keramik (Sapphire)', categoryName: 'Behel & Ortodonti', description: 'Behel transparan estetis dengan bracket keramik sapphire.', price: 12500000, durationMinutes: 60, imageUrl: null, isActive: true },
  { id: '41-007', categoryId: 'cat-ortho', name: 'Behel Self-Ligating', categoryName: 'Behel & Ortodonti', description: 'Behel tanpa karet dengan friction rendah, lebih cepat dan nyaman.', price: 9500000, durationMinutes: 60, imageUrl: null, isActive: true },
  { id: '41-008', categoryId: 'cat-ortho', name: 'Kontrol Behel Bulanan', categoryName: 'Behel & Ortodonti', description: 'Kunjungan kontrol dan penggantian kawat berkala.', price: 150000, durationMinutes: 20, imageUrl: null, isActive: true },
  { id: '41-009', categoryId: 'cat-kidz', name: 'Pemeriksaan Gigi Anak (Nina Kidz)', categoryName: 'Nina Kidz (Gigi Anak)', description: 'Pemeriksaan rutin gigi anak dengan pendekatan fun & friendly.', price: 100000, durationMinutes: 20, imageUrl: null, isActive: true },
  { id: '41-010', categoryId: 'cat-kidz', name: 'Fluoride Treatment Anak', categoryName: 'Nina Kidz (Gigi Anak)', description: 'Aplikasi fluoride untuk perlindungan gigi anak dari karies.', price: 200000, durationMinutes: 20, imageUrl: null, isActive: true },
  { id: '41-011', categoryId: 'cat-kidz', name: 'Vitamin Gigi Anak', categoryName: 'Nina Kidz (Gigi Anak)', description: 'Suplemen mineral dan vitamin untuk pertumbuhan gigi anak optimal.', price: 75000, durationMinutes: 15, imageUrl: null, isActive: true },
  { id: '41-012', categoryId: 'cat-implant', name: 'Implan Gigi (Single Tooth)', categoryName: 'Implan & Prostodontia', description: 'Penanaman akar gigi titanium untuk gigi yang hilang.', price: 15000000, durationMinutes: 90, imageUrl: null, isActive: true },
  { id: '41-013', categoryId: 'cat-implant', name: 'Veneer Porcelain', categoryName: 'Implan & Prostodontia', description: 'Lapisan tipis porselen untuk memperbaiki estetika gigi.', price: 3500000, durationMinutes: 60, imageUrl: null, isActive: true },
  { id: '41-014', categoryId: 'cat-surg', name: 'Cabut Gigi Bungsu (Odontektomi)', categoryName: 'Bedah Mulut', description: 'Pembedahan pengangkatan gigi impaksi / gigi bungsu bermasalah.', price: 1200000, durationMinutes: 60, imageUrl: null, isActive: false }
]

const initialCategories: TreatmentCategory[] = [
  { id: 'cat-umum', name: 'Umum', sortOrder: 1 },
  { id: 'cat-ortho', name: 'Behel & Ortodonti', sortOrder: 2 },
  { id: 'cat-kidz', name: 'Nina Kidz (Gigi Anak)', sortOrder: 3 },
  { id: 'cat-implant', name: 'Implan & Prostodontia', sortOrder: 4 },
  { id: 'cat-surg', name: 'Bedah Mulut', sortOrder: 5 }
]

const localTreatments = ref<Treatment[]>([])
const localCategories = ref<TreatmentCategory[]>([])

watch(apiTreatments, (val) => {
  if (val && (Array.isArray(val) ? val.length > 0 : (val as any)?.data?.length > 0)) {
    localTreatments.value = Array.isArray(val) ? [...val] : [...(val as any).data]
  } else if (localTreatments.value.length === 0) {
    localTreatments.value = [...initialTreatments]
  }
}, { immediate: true })

watch(apiCategories, (val) => {
  if (val && Array.isArray(val) && val.length > 0) {
    localCategories.value = [...val]
  } else if (localCategories.value.length === 0) {
    localCategories.value = [...initialCategories]
  }
}, { immediate: true })

// ── Filters ────────────────────────────────────────────────────────────────
const statusFilter = ref<'all' | 'active' | 'inactive'>('active')
const searchQuery = ref('')
const categoryFilter = ref<string>('all')

const categories = computed(() => {
  const all = localCategories.value.length > 0 ? localCategories.value : initialCategories
  return [{ id: 'all', name: 'Semua Kategori' }, ...all]
})

const filteredTreatments = computed(() => {
  return localTreatments.value.filter((t) => {
    if (statusFilter.value === 'active' && !t.isActive) return false
    if (statusFilter.value === 'inactive' && t.isActive) return false
    if (categoryFilter.value !== 'all' && t.categoryId !== categoryFilter.value) return false
    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase().trim()
      return t.name.toLowerCase().includes(q) || (t.categoryName || '').toLowerCase().includes(q) || (t.description || '').toLowerCase().includes(q)
    }
    return true
  })
})

// ── Stats ──────────────────────────────────────────────────────────────────
const totalActive = computed(() => localTreatments.value.filter(t => t.isActive).length)
const totalArchived = computed(() => localTreatments.value.filter(t => !t.isActive).length)
const totalRevEst = computed(() => localTreatments.value.filter(t => t.isActive).reduce((s, t) => s + t.price * 10, 0))

const statsByCategory = computed(() => {
  const map: Record<string, { name: string; count: number; revenue: number }> = {}
  for (const t of localTreatments.value.filter(x => x.isActive)) {
    if (!map[t.categoryId]) map[t.categoryId] = { name: t.categoryName, count: 0, revenue: 0 }
    map[t.categoryId].count++
    map[t.categoryId].revenue += t.price
  }
  return Object.values(map).sort((a, b) => b.count - a.count)
})

// ── Detail Slideover ───────────────────────────────────────────────────────
const showDetail = ref(false)
const detailTreatment = ref<Treatment | null>(null)

function openDetail(t: Treatment) {
  detailTreatment.value = t
  showDetail.value = true
}

function closeDetail() {
  showDetail.value = false
  detailTreatment.value = null
}

// ── Create / Edit Modal ────────────────────────────────────────────────────
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')
const newCategoryName = ref('')
const newCategoryDesc = ref('')
const modalTab = ref<'perawatan' | 'kategori'>('perawatan')

const form = reactive({
  categoryId: '',
  name: '',
  description: '',
  price: 0,
  durationMinutes: 30,
  imageUrl: '',
  isActive: true
})

function openCreate() {
  editingId.value = null
  form.categoryId = localCategories.value[0]?.id ?? 'cat-umum'
  form.name = ''
  form.description = ''
  form.price = 0
  form.durationMinutes = 30
  form.imageUrl = ''
  form.isActive = true
  formError.value = ''
  modalTab.value = 'perawatan'
  showModal.value = true
}

function openEdit(treatment: Treatment, closeDetailFirst = false) {
  if (closeDetailFirst) closeDetail()
  editingId.value = treatment.id
  form.categoryId = treatment.categoryId
  form.name = treatment.name
  form.description = treatment.description ?? ''
  form.price = treatment.price
  form.durationMinutes = treatment.durationMinutes
  form.imageUrl = treatment.imageUrl ?? ''
  form.isActive = treatment.isActive
  formError.value = ''
  modalTab.value = 'perawatan'
  showModal.value = true
}

function addCategory() {
  if (!newCategoryName.value.trim()) return
  const catName = newCategoryName.value.trim()
  const newCat: TreatmentCategory = {
    id: `cat-${Date.now()}`,
    name: catName,
    sortOrder: localCategories.value.length + 1
  }
  localCategories.value.push(newCat)
  form.categoryId = newCat.id
  newCategoryName.value = ''
  newCategoryDesc.value = ''
  try { $fetch(apiUrl('/treatment-categories'), { method: 'POST', body: { name: catName } }) } catch {}
}

function deleteCategory(catId: string) {
  const inUse = localTreatments.value.some(t => t.categoryId === catId)
  if (inUse) {
    alert('Kategori ini masih digunakan oleh perawatan lain. Pindahkan perawatan tersebut terlebih dahulu.')
    return
  }
  if (!confirm('Hapus kategori ini?')) return
  localCategories.value = localCategories.value.filter(c => c.id !== catId)
  if (form.categoryId === catId) form.categoryId = localCategories.value[0]?.id ?? ''
  try { $fetch(apiUrl(`/treatment-categories/${catId}`), { method: 'DELETE' }) } catch {}
}

async function onSubmit() {
  if (!form.categoryId || !form.name.trim() || form.price <= 0) {
    formError.value = 'Kategori, nama, dan harga (lebih dari 0) wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const category = localCategories.value.find(c => c.id === form.categoryId)
    const categoryName = category?.name ?? 'Umum'
    const payload = {
      categoryId: form.categoryId,
      name: form.name,
      description: form.description || null,
      price: form.price,
      durationMinutes: form.durationMinutes,
      imageUrl: form.imageUrl || null,
      isActive: form.isActive
    }

    if (editingId.value) {
      const idx = localTreatments.value.findIndex(t => t.id === editingId.value)
      if (idx !== -1) {
        localTreatments.value[idx] = { ...localTreatments.value[idx], ...payload, categoryName }
        if (detailTreatment.value?.id === editingId.value) {
          detailTreatment.value = { ...localTreatments.value[idx] }
        }
      }
      try { await $fetch(apiUrl(`/treatments/${editingId.value}`), { method: 'PUT', body: payload }) } catch {}
    } else {
      const newT: Treatment = { id: `trt-${Date.now()}`, ...payload, categoryName }
      localTreatments.value.unshift(newT)
      try { await $fetch(apiUrl('/treatments'), { method: 'POST', body: payload }) } catch {}
    }
    showModal.value = false
  } catch (err: any) {
    formError.value = err?.data?.message ?? err?.message ?? 'Gagal menyimpan data.'
  } finally {
    saving.value = false
  }
}

// ── Soft Delete / Reactivate ───────────────────────────────────────────────
function onSoftDelete(t: Treatment) {
  if (!confirm(`Arsipkan perawatan "${t.name}"? Data tetap aman di sistem.`)) return
  const idx = localTreatments.value.findIndex(x => x.id === t.id)
  if (idx !== -1) localTreatments.value[idx] = { ...localTreatments.value[idx], isActive: false }
  if (detailTreatment.value?.id === t.id) detailTreatment.value = { ...localTreatments.value[idx] }
  try { $fetch(apiUrl(`/treatments/${t.id}`), { method: 'PUT', body: { ...t, isActive: false } }) } catch {}
}

function onReactivate(t: Treatment) {
  const idx = localTreatments.value.findIndex(x => x.id === t.id)
  if (idx !== -1) localTreatments.value[idx] = { ...localTreatments.value[idx], isActive: true }
  if (detailTreatment.value?.id === t.id) detailTreatment.value = { ...localTreatments.value[idx] }
  try { $fetch(apiUrl(`/treatments/${t.id}`), { method: 'PUT', body: { ...t, isActive: true } }) } catch {}
}

// ── Format helpers ─────────────────────────────────────────────────────────
const CATEGORY_COLORS: Record<string, string> = {
  'cat-umum': 'sky',
  'cat-ortho': 'violet',
  'cat-kidz': 'pink',
  'cat-implant': 'amber',
  'cat-surg': 'red'
}
function catColor(categoryId: string): string {
  return CATEGORY_COLORS[categoryId] ?? 'neutral'
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <!-- Header -->
    <div class="flex items-center justify-between flex-wrap gap-2">
      <div>
        <h1 class="text-xl font-bold text-gray-900 dark:text-white">Perawatan & Harga</h1>
        <p class="text-xs text-gray-500 mt-0.5">
          Katalog perawatan Nina Dental Care.
          <span class="text-amber-500 font-semibold">Soft Delete</span> — data terarsip tidak hilang permanen.
        </p>
      </div>
      <UButton icon="i-lucide-plus" label="+ Tambah Perawatan" color="primary" @click="openCreate" />
    </div>

    <!-- Filter Toolbar -->
    <div class="flex flex-col sm:flex-row items-start sm:items-center gap-3 bg-white dark:bg-gray-800 p-3 rounded-xl border border-gray-200 dark:border-gray-700">
      <!-- Status Tabs -->
      <div class="flex items-center gap-1 bg-gray-100 dark:bg-gray-900 p-0.5 rounded-lg">
        <button
          v-for="opt in [{ v: 'active', label: 'Aktif' }, { v: 'inactive', label: 'Terarsip' }, { v: 'all', label: 'Semua' }]"
          :key="opt.v"
          class="px-3 py-1 text-xs font-semibold rounded-md transition-all"
          :class="statusFilter === opt.v ? 'bg-white dark:bg-gray-700 text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'"
          @click="statusFilter = opt.v as any"
        >
          {{ opt.label }}
          <span v-if="opt.v === 'active'" class="ml-1 bg-primary text-white text-[9px] font-bold px-1.5 py-0.5 rounded-full">{{ totalActive }}</span>
          <span v-if="opt.v === 'inactive'" class="ml-1 bg-amber-400 text-white text-[9px] font-bold px-1.5 py-0.5 rounded-full">{{ totalArchived }}</span>
        </button>
      </div>

      <!-- Category Filter -->
      <select
        v-model="categoryFilter"
        class="px-2 py-1.5 text-xs rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-200 focus:outline-none focus:ring-2 focus:ring-primary-400"
      >
        <option v-for="c in categories" :key="c.id" :value="c.id">{{ c.name }}</option>
      </select>

      <!-- Search -->
      <UInput
        v-model="searchQuery"
        icon="i-lucide-search"
        placeholder="Cari nama / kategori..."
        size="sm"
        class="w-full sm:w-60 ml-auto"
      />
    </div>

    <!-- Main Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">

      <!-- ── Table ── -->
      <div class="lg:col-span-9 space-y-0">
        <UCard :ui="{ body: 'p-0 sm:p-0' }">
          <div v-if="status === 'pending'" class="flex items-center justify-center py-10 text-gray-400 text-sm gap-2">
            <UIcon name="i-lucide-loader-circle" class="w-5 h-5 animate-spin" />
            Memuat data...
          </div>
          <div v-else-if="filteredTreatments.length === 0" class="py-10 text-center text-gray-400 text-sm">
            <UIcon name="i-lucide-stethoscope" class="w-8 h-8 mx-auto mb-2" />
            <p>Tidak ada data perawatan</p>
          </div>
          <div v-else class="overflow-x-auto">
            <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
              <thead class="bg-gray-50 dark:bg-gray-800/60 text-[11px] font-bold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
                <tr>
                  <th class="px-4 py-3">Kategori</th>
                  <th class="px-4 py-3">Nama Perawatan</th>
                  <th class="px-4 py-3">Harga</th>
                  <th class="px-4 py-3">Durasi</th>
                  <th class="px-4 py-3">Status</th>
                  <th class="px-4 py-3 text-right">Aksi</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-800">
                <tr
                  v-for="t in filteredTreatments"
                  :key="t.id"
                  class="hover:bg-primary-50/40 dark:hover:bg-primary-900/10 transition-colors cursor-pointer group"
                  @click="openDetail(t)"
                >
                  <td class="px-4 py-3">
                    <UBadge :color="catColor(t.categoryId) as any" variant="subtle" size="xs">
                      {{ t.categoryName }}
                    </UBadge>
                  </td>
                  <td class="px-4 py-3 font-semibold text-gray-900 dark:text-white max-w-xs">
                    {{ t.name }}
                    <p v-if="t.description" class="text-[10px] text-gray-400 font-normal truncate max-w-[260px]">{{ t.description }}</p>
                  </td>
                  <td class="px-4 py-3 font-bold text-emerald-700 dark:text-emerald-400 whitespace-nowrap">
                    {{ formatIDR(t.price) }}
                  </td>
                  <td class="px-4 py-3 whitespace-nowrap text-gray-500">
                    <div class="flex items-center gap-1">
                      <UIcon name="i-lucide-clock" class="w-3 h-3" />
                      {{ t.durationMinutes }} menit
                    </div>
                  </td>
                  <td class="px-4 py-3">
                    <UBadge :color="t.isActive ? 'success' : 'neutral'" variant="soft" size="xs">
                      {{ t.isActive ? 'Aktif' : 'Terarsip' }}
                    </UBadge>
                  </td>
                  <td class="px-4 py-3 text-right" @click.stop>
                    <div class="flex items-center justify-end gap-1">
                      <UButton
                        size="xs"
                        variant="ghost"
                        color="neutral"
                        icon="i-lucide-eye"
                        title="Lihat Detail"
                        @click="openDetail(t)"
                      />
                      <UButton
                        size="xs"
                        variant="ghost"
                        color="primary"
                        icon="i-lucide-edit-2"
                        title="Edit"
                        @click="openEdit(t)"
                      />
                      <UButton
                        v-if="t.isActive"
                        size="xs"
                        variant="ghost"
                        color="warning"
                        icon="i-lucide-archive"
                        title="Arsipkan"
                        @click="onSoftDelete(t)"
                      />
                      <UButton
                        v-else
                        size="xs"
                        variant="ghost"
                        color="success"
                        icon="i-lucide-rotate-ccw"
                        title="Aktifkan Kembali"
                        @click="onReactivate(t)"
                      />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <!-- Table Footer -->
          <div class="px-4 py-2.5 border-t border-gray-100 dark:border-gray-800 flex items-center justify-between text-xs text-gray-400">
            <span>Menampilkan {{ filteredTreatments.length }} dari {{ localTreatments.length }} perawatan</span>
            <span>Total Aktif: <b class="text-primary">{{ totalActive }}</b> item</span>
          </div>
        </UCard>
      </div>

      <!-- ── Stats Sidebar ── -->
      <div class="lg:col-span-3 space-y-4">
        <!-- Summary Card -->
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-bar-chart-2" class="w-4 h-4 text-primary" />
              <h3 class="font-bold text-sm">Ringkasan Katalog</h3>
            </div>
          </template>
          <div class="space-y-3 text-xs">
            <div class="flex justify-between items-center p-2 bg-emerald-50 dark:bg-emerald-900/20 rounded-lg">
              <span class="text-gray-600 dark:text-gray-300 font-medium">Total Aktif</span>
              <span class="text-2xl font-extrabold text-emerald-600">{{ totalActive }}</span>
            </div>
            <div class="flex justify-between items-center p-2 bg-amber-50 dark:bg-amber-900/20 rounded-lg">
              <span class="text-gray-600 dark:text-gray-300 font-medium">Terarsip</span>
              <span class="text-2xl font-extrabold text-amber-500">{{ totalArchived }}</span>
            </div>
            <div class="p-2 bg-primary-50 dark:bg-primary-900/20 rounded-lg">
              <span class="text-gray-500 block mb-0.5">Est. Pendapatan</span>
              <span class="text-base font-extrabold text-primary">{{ formatIDR(totalRevEst) }}</span>
            </div>
          </div>
        </UCard>

        <!-- Per-Category Card -->
        <UCard>
          <template #header>
            <div class="flex items-center gap-2">
              <UIcon name="i-lucide-layers" class="w-4 h-4 text-violet-500" />
              <h3 class="font-bold text-sm">Per Kategori</h3>
            </div>
          </template>
          <div class="space-y-2 text-xs">
            <div
              v-for="cat in statsByCategory"
              :key="cat.name"
              class="flex items-center justify-between p-2 rounded-lg bg-gray-50 dark:bg-gray-800"
            >
              <span class="font-semibold text-gray-800 dark:text-gray-200 truncate">{{ cat.name }}</span>
              <div class="text-right shrink-0">
                <span class="font-bold text-primary block">{{ cat.count }} item</span>
              </div>
            </div>
          </div>
        </UCard>
      </div>
    </div>

    <!-- ════════════════════════════════ -->
    <!-- Detail Slideover / Panel Kanan -->
    <!-- ════════════════════════════════ -->
    <USlideover
      v-model:open="showDetail"
      side="right"
      title="Detail Perawatan"
    >
      <template #body>
        <div v-if="detailTreatment" class="space-y-5 p-1">
          <!-- Header -->
          <div class="space-y-2">
            <div class="flex items-start justify-between gap-2">
              <div class="flex items-center gap-3">
                <div class="w-12 h-12 rounded-xl bg-primary-100 dark:bg-primary-900/30 text-primary flex items-center justify-center shrink-0">
                  <UIcon name="i-lucide-stethoscope" class="w-6 h-6" />
                </div>
                <div>
                  <h2 class="font-bold text-base text-gray-900 dark:text-white leading-tight">{{ detailTreatment.name }}</h2>
                  <UBadge :color="catColor(detailTreatment.categoryId) as any" variant="subtle" size="xs" class="mt-1">
                    {{ detailTreatment.categoryName }}
                  </UBadge>
                </div>
              </div>
              <UBadge :color="detailTreatment.isActive ? 'success' : 'neutral'" variant="soft" size="sm">
                {{ detailTreatment.isActive ? 'Aktif' : 'Terarsip' }}
              </UBadge>
            </div>
          </div>

          <!-- Info Grid -->
          <div class="grid grid-cols-2 gap-3">
            <div class="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-900/20 text-center">
              <span class="text-[10px] font-bold text-gray-500 uppercase tracking-wide block">Harga</span>
              <span class="text-xl font-extrabold text-emerald-600 dark:text-emerald-400">{{ formatIDR(detailTreatment.price) }}</span>
            </div>
            <div class="p-3 rounded-xl bg-blue-50 dark:bg-blue-900/20 text-center">
              <span class="text-[10px] font-bold text-gray-500 uppercase tracking-wide block">Durasi</span>
              <span class="text-xl font-extrabold text-blue-600 dark:text-blue-400">{{ detailTreatment.durationMinutes }} <span class="text-sm font-normal">menit</span></span>
            </div>
          </div>

          <!-- Description -->
          <div v-if="detailTreatment.description" class="p-3 bg-gray-50 dark:bg-gray-800 rounded-xl">
            <span class="text-[10px] font-bold text-gray-400 uppercase tracking-wide block mb-1">Deskripsi Layanan</span>
            <p class="text-sm text-gray-700 dark:text-gray-200 leading-relaxed">{{ detailTreatment.description }}</p>
          </div>

          <!-- Additional Info -->
          <div class="border border-gray-200 dark:border-gray-700 rounded-xl overflow-hidden">
            <div class="bg-gray-50 dark:bg-gray-800 px-3 py-2 border-b border-gray-200 dark:border-gray-700">
              <span class="text-[10px] font-bold text-gray-500 uppercase tracking-wide">Informasi Tambahan</span>
            </div>
            <div class="divide-y divide-gray-100 dark:divide-gray-800">
              <div class="flex justify-between px-3 py-2.5 text-xs">
                <span class="text-gray-500">Kode Perawatan (SKU)</span>
                <span class="font-mono font-bold text-gray-800 dark:text-gray-200 text-xs">
                  {{ detailTreatment.id.startsWith('41') || detailTreatment.id.startsWith('cat') ? detailTreatment.id : `TRT-${detailTreatment.id.slice(0, 8).toUpperCase()}` }}
                </span>
              </div>
              <div class="flex justify-between px-3 py-2.5 text-xs">
                <span class="text-gray-500">Kategori Layanan</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200 text-xs">{{ detailTreatment.categoryName || 'Umum' }}</span>
              </div>
              <div class="flex justify-between px-3 py-2.5 text-xs">
                <span class="text-gray-500">Est. Kunjungan/Bulan</span>
                <span class="font-bold text-primary">~10</span>
              </div>
              <div class="flex justify-between px-3 py-2.5 text-xs">
                <span class="text-gray-500">Est. Pendapatan/Bulan</span>
                <span class="font-bold text-emerald-600">{{ formatIDR(detailTreatment.price * 10) }}</span>
              </div>
            </div>
          </div>

          <!-- Image if any -->
          <div v-if="detailTreatment.imageUrl" class="rounded-xl overflow-hidden border border-gray-200 dark:border-gray-700">
            <img :src="detailTreatment.imageUrl" :alt="detailTreatment.name" class="w-full h-40 object-cover">
          </div>

          <!-- Action Buttons -->
          <div class="flex gap-2 pt-2 border-t border-gray-100 dark:border-gray-800">
            <UButton
              icon="i-lucide-edit-2"
              label="Edit Perawatan"
              color="primary"
              class="flex-1"
              @click="openEdit(detailTreatment, true)"
            />
            <UButton
              v-if="detailTreatment.isActive"
              icon="i-lucide-archive"
              label="Arsipkan"
              color="warning"
              variant="outline"
              @click="onSoftDelete(detailTreatment)"
            />
            <UButton
              v-else
              icon="i-lucide-rotate-ccw"
              label="Aktifkan"
              color="success"
              variant="outline"
              @click="onReactivate(detailTreatment)"
            />
          </div>
        </div>
      </template>
    </USlideover>

    <!-- ════════════════════════════════ -->
    <!-- Create / Edit Modal (Tab-based) -->
    <!-- ════════════════════════════════ -->
    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Perawatan' : 'Tambah Perawatan Baru'"
    >
      <template #body>
        <!-- Tab Switcher -->
        <div class="flex items-center gap-1 bg-gray-100 dark:bg-gray-900 p-0.5 rounded-lg mb-4">
          <button
            type="button"
            class="flex-1 py-1.5 text-xs font-semibold rounded-md transition-all"
            :class="modalTab === 'perawatan' ? 'bg-white dark:bg-gray-700 text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'"
            @click="modalTab = 'perawatan'"
          >
            <span class="flex items-center justify-center gap-1.5">
              <UIcon name="i-lucide-stethoscope" class="w-3.5 h-3.5" />
              Data Perawatan
            </span>
          </button>
          <button
            type="button"
            class="flex-1 py-1.5 text-xs font-semibold rounded-md transition-all"
            :class="modalTab === 'kategori' ? 'bg-white dark:bg-gray-700 text-primary shadow-sm' : 'text-gray-500 hover:text-gray-700'"
            @click="modalTab = 'kategori'"
          >
            <span class="flex items-center justify-center gap-1.5">
              <UIcon name="i-lucide-tags" class="w-3.5 h-3.5" />
              Master Kategori
              <span class="bg-primary text-white text-[9px] font-bold px-1.5 py-0.5 rounded-full leading-none">{{ localCategories.length }}</span>
            </span>
          </button>
        </div>

        <!-- ── TAB: Data Perawatan ── -->
        <form v-if="modalTab === 'perawatan'" class="space-y-4" @submit.prevent="onSubmit">
          <div v-if="formError" class="p-2.5 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg text-xs text-red-600 flex items-center gap-2">
            <UIcon name="i-lucide-alert-circle" class="w-4 h-4 shrink-0" />
            {{ formError }}
          </div>

          <!-- Kategori -->
          <div>
            <label class="block text-xs font-semibold mb-1.5">
              Kategori <span class="text-red-500">*</span>
              <button type="button" class="ml-2 text-[10px] text-primary font-normal hover:underline" @click="modalTab = 'kategori'">
                + Kelola Kategori →
              </button>
            </label>
            <select
              v-model="form.categoryId"
              class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 appearance-none cursor-pointer"
            >
              <option value="" disabled>-- Pilih Kategori --</option>
              <option v-for="cat in localCategories" :key="cat.id" :value="cat.id">{{ cat.name }}</option>
            </select>
          </div>

          <!-- Nama Perawatan -->
          <div>
            <label class="block text-xs font-semibold mb-1.5">Nama Perawatan <span class="text-red-500">*</span></label>
            <input
              v-model="form.name"
              type="text"
              placeholder="mis. Scaling Gigi (Pembersihan Karang Gigi)"
              class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400"
              :disabled="saving"
            >
          </div>

          <!-- Deskripsi -->
          <div>
            <label class="block text-xs font-semibold mb-1.5">Deskripsi <span class="text-gray-400 font-normal">(Opsional)</span></label>
            <textarea
              v-model="form.description"
              rows="3"
              placeholder="Penjelasan singkat tentang prosedur dan manfaat perawatan ini..."
              class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400 resize-none"
              :disabled="saving"
            />
          </div>

          <!-- Harga & Durasi -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold mb-1.5">Harga (Rp) <span class="text-red-500">*</span></label>
              <input
                v-model.number="form.price"
                type="number"
                step="50000"
                min="0"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                :disabled="saving"
              >
              <span class="text-[10px] text-emerald-600 font-semibold mt-0.5 block h-4">
                {{ form.price > 0 ? formatIDR(form.price) : '' }}
              </span>
            </div>
            <div>
              <label class="block text-xs font-semibold mb-1.5">Durasi (Menit)</label>
              <input
                v-model.number="form.durationMinutes"
                type="number"
                step="5"
                min="5"
                max="480"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                :disabled="saving"
              >
              <span class="text-[10px] text-gray-400 mt-0.5 block h-4">
                {{ form.durationMinutes ? `~${form.durationMinutes} menit` : '' }}
              </span>
            </div>
          </div>

          <!-- Status Aktif -->
          <label class="flex items-center gap-3 p-3 bg-gray-50 dark:bg-gray-900 rounded-lg cursor-pointer group">
            <input
              id="isActive"
              v-model="form.isActive"
              type="checkbox"
              class="w-4 h-4 rounded text-primary focus:ring-primary cursor-pointer"
            >
            <div>
              <span class="text-sm font-semibold group-hover:text-primary transition-colors">Status Aktif</span>
              <span class="block text-[11px] text-gray-400">Perawatan ini tampil di aplikasi & daftar layanan klinik</span>
            </div>
            <UBadge
              :color="form.isActive ? 'success' : 'neutral'"
              variant="soft"
              size="xs"
              class="ml-auto"
            >
              {{ form.isActive ? 'Aktif' : 'Nonaktif' }}
            </UBadge>
          </label>

          <div class="flex justify-end gap-2 pt-3 border-t border-gray-100 dark:border-gray-800">
            <UButton label="Batal" color="neutral" variant="ghost" :disabled="saving" @click="showModal = false" />
            <UButton
              type="submit"
              :label="saving ? 'Menyimpan...' : (editingId ? 'Simpan Perubahan' : 'Tambah Perawatan')"
              color="primary"
              :loading="saving"
              icon="i-lucide-save"
            />
          </div>
        </form>

        <!-- ── TAB: Master Kategori ── -->
        <div v-else class="space-y-4">
          <!-- Add Category Form -->
          <div class="p-4 bg-primary-50 dark:bg-primary-900/20 rounded-xl border border-primary-200 dark:border-primary-800 space-y-3">
            <h4 class="text-xs font-bold text-primary flex items-center gap-1.5">
              <UIcon name="i-lucide-plus-circle" class="w-4 h-4" />
              Tambah Kategori Baru
            </h4>
            <div>
              <label class="block text-xs font-semibold mb-1.5">Nama Kategori <span class="text-red-500">*</span></label>
              <div class="flex gap-2">
                <input
                  v-model="newCategoryName"
                  type="text"
                  placeholder="mis. Gigi Palsu, Veneer, Implan..."
                  class="flex-1 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400"
                  @keydown.enter.prevent="addCategory"
                >
                <UButton
                  icon="i-lucide-plus"
                  label="Tambah"
                  color="primary"
                  size="sm"
                  :disabled="!newCategoryName.trim()"
                  @click="addCategory"
                />
              </div>
              <p class="text-[10px] text-gray-400 mt-1">Tekan Enter atau klik Tambah untuk menyimpan kategori.</p>
            </div>
          </div>

          <!-- Daftar Kategori -->
          <div>
            <div class="flex items-center justify-between mb-2">
              <h4 class="text-xs font-bold text-gray-700 dark:text-gray-300 uppercase tracking-wide">Daftar Kategori ({{ localCategories.length }})</h4>
            </div>
            <div v-if="localCategories.length === 0" class="py-6 text-center text-gray-400 text-xs">
              <UIcon name="i-lucide-tags" class="w-6 h-6 mx-auto mb-1" />
              Belum ada kategori
            </div>
            <div v-else class="space-y-2">
              <div
                v-for="cat in localCategories"
                :key="cat.id"
                class="flex items-center justify-between px-3 py-2.5 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 group"
              >
                <div class="flex items-center gap-2">
                  <div class="w-2 h-2 rounded-full bg-primary shrink-0" />
                  <span class="text-sm font-medium text-gray-800 dark:text-gray-200">{{ cat.name }}</span>
                  <span class="text-[10px] text-gray-400">
                    ({{ localTreatments.filter(t => t.categoryId === cat.id).length }} perawatan)
                  </span>
                </div>
                <div class="flex items-center gap-1">
                  <UBadge
                    v-if="form.categoryId === cat.id"
                    color="primary"
                    variant="subtle"
                    size="xs"
                  >
                    Dipilih
                  </UBadge>
                  <UButton
                    size="xs"
                    variant="ghost"
                    color="primary"
                    icon="i-lucide-check"
                    title="Gunakan kategori ini"
                    @click="form.categoryId = cat.id; modalTab = 'perawatan'"
                  />
                  <UButton
                    size="xs"
                    variant="ghost"
                    color="error"
                    icon="i-lucide-trash-2"
                    title="Hapus kategori"
                    @click="deleteCategory(cat.id)"
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="flex justify-end pt-2 border-t border-gray-100 dark:border-gray-800">
            <UButton
              label="← Kembali ke Form Perawatan"
              color="primary"
              variant="outline"
              size="sm"
              icon="i-lucide-arrow-left"
              @click="modalTab = 'perawatan'"
            />
          </div>
        </div>
      </template>
    </UModal>
  </div>
</template>
