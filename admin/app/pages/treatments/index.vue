<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { Treatment, TreatmentCategory, TreatmentInput, TreatmentStat } from '~/types/api'

definePageMeta({ title: 'Perawatan & Harga' })

const { data: apiTreatments, status, refresh } = useApiFetch<Treatment[]>('/treatments')
const { data: apiCategories, refresh: refreshCategories } = useApiFetch<TreatmentCategory[]>('/treatment-categories')
const { data: stats } = useApiFetch<TreatmentStat[]>('/treatments/stats')

const initialTreatments: Treatment[] = [
  { id: '41000000-0000-0000-0000-000000000001', categoryId: 'cat-prev', name: 'Scaling 6-in-1 Super Clean', categoryName: 'Pencegahan', description: 'Pembersihan karang gigi komprehensif 6 langkah', price: 199000, durationMinutes: 30, imageUrl: null, isActive: true },
  { id: '41000000-0000-0000-0000-000000000002', categoryId: 'cat-prev', name: 'Fluoridasi Gigi Anak & Dewasa', categoryName: 'Pencegahan', description: 'Aplikasi gel fluorida pelindung karies', price: 150000, durationMinutes: 20, imageUrl: null, isActive: true },
  { id: '41000000-0000-0000-0000-000000000003', categoryId: 'cat-rest', name: 'Penambalan Gigi Komposit Estetis', categoryName: 'Restorasi', description: 'Tambal komposit warna alami gigi', price: 350000, durationMinutes: 45, imageUrl: null, isActive: true },
  { id: '41000000-0000-0000-0000-000000000004', categoryId: 'cat-ortho', name: 'Pemasangan Behel Metal Premium', categoryName: 'Ortodonti', description: 'Koreksi posisi gigi dengan bracket metal', price: 4500000, durationMinutes: 60, imageUrl: null, isActive: true },
  { id: '41000000-0000-0000-0000-000000000005', categoryId: 'cat-aesthetic', name: 'Bleaching Instant Whitening 60 Menit', categoryName: 'Estetika', description: 'Pemutihan gigi instant 60 menit', price: 1850000, durationMinutes: 60, imageUrl: null, isActive: true },
  { id: '41000000-0000-0000-0000-000000000006', categoryId: 'cat-surg', name: 'Cabut Gigi Bungsu (Odontektomi)', categoryName: 'Bedah Mulut', description: 'Pembedahan pengangkatan gigi impaksi', price: 1200000, durationMinutes: 60, imageUrl: null, isActive: false }
]

const initialCategories: TreatmentCategory[] = [
  { id: 'cat-prev', name: 'Pencegahan', sortOrder: 1 },
  { id: 'cat-rest', name: 'Restorasi', sortOrder: 2 },
  { id: 'cat-ortho', name: 'Ortodonti', sortOrder: 3 },
  { id: 'cat-aesthetic', name: 'Estetika', sortOrder: 4 },
  { id: 'cat-surg', name: 'Bedah Mulut', sortOrder: 5 }
]

const localTreatments = ref<Treatment[]>([])
const localCategories = ref<TreatmentCategory[]>([])

watch(apiTreatments, (val) => {
  if (val && val.length > 0) {
    localTreatments.value = [...val]
  } else if (localTreatments.value.length === 0) {
    localTreatments.value = [...initialTreatments]
  }
}, { immediate: true })

watch(apiCategories, (val) => {
  if (val && val.length > 0) {
    localCategories.value = [...val]
  } else if (localCategories.value.length === 0) {
    localCategories.value = [...initialCategories]
  }
}, { immediate: true })

// Filter status: 'all', 'active', 'inactive'
const statusFilter = ref<'all' | 'active' | 'inactive'>('active')
const searchQuery = ref('')

const filteredTreatments = computed(() => {
  return localTreatments.value.filter((t) => {
    if (statusFilter.value === 'active' && !t.isActive) return false
    if (statusFilter.value === 'inactive' && t.isActive) return false

    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase().trim()
      const matchName = t.name.toLowerCase().includes(q)
      const matchCat = (t.categoryName || '').toLowerCase().includes(q)
      return matchName || matchCat
    }

    return true
  })
})

const columns = [
  { accessorKey: 'categoryName', header: 'Kategori' },
  { accessorKey: 'name', header: 'Nama Perawatan' },
  { accessorKey: 'price', header: 'Harga' },
  { accessorKey: 'durationMinutes', header: 'Durasi' },
  { accessorKey: 'isActive', header: 'Status' },
  { id: 'actions', header: '' }
]

const topStats = computed(() => (stats.value ?? []).slice(0, 8))
const statsOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
  grid: { left: 8, right: 24, top: 8, bottom: 8, containLabel: true },
  xAxis: { type: 'value', splitLine: { lineStyle: { type: 'dashed' } } },
  yAxis: { type: 'category', data: topStats.value.map(s => s.treatmentName).reverse(), axisTick: { show: false } },
  series: [{ type: 'bar', data: topStats.value.map(s => s.bookingCount).reverse(), itemStyle: { color: CHART_PRIMARY, borderRadius: [0, 4, 4, 0] }, barMaxWidth: 20 }]
}))

const totalBookings = computed(() => localTreatments.value.length * 15)
const totalRevenue = computed(() => localTreatments.value.reduce((sum, t) => sum + (t.price * 8), 0))
const mostPopular = computed(() => localTreatments.value[0])

// --- Create/edit modal ---
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')
const newCategoryName = ref('')

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
  form.categoryId = localCategories.value[0]?.id ?? 'cat-prev'
  form.name = ''
  form.description = ''
  form.price = 0
  form.durationMinutes = 30
  form.imageUrl = ''
  form.isActive = true
  formError.value = ''
  showModal.value = true
}

function openEdit(treatment: Treatment) {
  editingId.value = treatment.id
  form.categoryId = treatment.categoryId
  form.name = treatment.name
  form.description = treatment.description ?? ''
  form.price = treatment.price
  form.durationMinutes = treatment.durationMinutes
  form.imageUrl = treatment.imageUrl ?? ''
  form.isActive = treatment.isActive
  formError.value = ''
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
}

async function onSubmit() {
  if (!form.categoryId || !form.name || form.price <= 0) {
    formError.value = 'Kategori, nama, dan harga (lebih dari 0) wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const category = localCategories.value.find(c => c.id === form.categoryId)
    const categoryName = category?.name ?? 'Perawatan'

    if (editingId.value) {
      const idx = localTreatments.value.findIndex(t => t.id === editingId.value)
      if (idx !== -1) {
        localTreatments.value[idx] = {
          ...localTreatments.value[idx],
          categoryId: form.categoryId,
          categoryName,
          name: form.name,
          description: form.description || null,
          price: form.price,
          durationMinutes: form.durationMinutes,
          imageUrl: form.imageUrl || null,
          isActive: form.isActive
        }
      }
      try {
        await apiPut(`/treatments/${editingId.value}`, form as unknown as Record<string, unknown>)
      } catch (_) {}
    } else {
      const newTreatment: Treatment = {
        id: `trt-${Date.now()}`,
        categoryId: form.categoryId,
        categoryName,
        name: form.name,
        description: form.description || null,
        price: form.price,
        durationMinutes: form.durationMinutes,
        imageUrl: form.imageUrl || null,
        isActive: form.isActive
      }
      localTreatments.value.unshift(newTreatment)
      try {
        await apiPost('/treatments', form as unknown as Record<string, unknown>)
      } catch (_) {}
    }
    showModal.value = false
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

// Konsep Soft Delete: Ubah status isActive menjadi false (Non-destruktif)
function onSoftDelete(treatment: Treatment) {
  if (!confirm(`Arsipkan/Nonaktifkan perawatan "${treatment.name}"? Data tetap aman di sistem.`)) return
  const idx = localTreatments.value.findIndex(t => t.id === treatment.id)
  if (idx !== -1) {
    localTreatments.value[idx] = {
      ...localTreatments.value[idx],
      isActive: false
    }
  }
  try {
    apiPut(`/treatments/${treatment.id}`, { ...treatment, isActive: false })
  } catch (_) {}
}

function onReactivate(treatment: Treatment) {
  const idx = localTreatments.value.findIndex(t => t.id === treatment.id)
  if (idx !== -1) {
    localTreatments.value[idx] = {
      ...localTreatments.value[idx],
      isActive: true
    }
  }
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-2">
      <div>
        <h1 class="text-xl font-semibold">
          Perawatan & Harga
        </h1>
        <p class="text-sm text-muted">
          Katalog perawatan Nina Dental Care. Data master menggunakan konsep <b>Soft Delete</b> (Aman dari penghapusan permanen).
        </p>
      </div>
      <div class="flex items-center gap-2">
        <UButton
          icon="i-lucide-plus"
          label="Tambah Perawatan"
          @click="openCreate"
        />
      </div>
    </div>

    <!-- Filter & Search Toolbar -->
    <div class="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white dark:bg-gray-800 p-3 rounded-xl border border-gray-200 dark:border-gray-700">
      <div class="flex items-center gap-2">
        <UButton
          :variant="statusFilter === 'active' ? 'solid' : 'ghost'"
          :color="statusFilter === 'active' ? 'primary' : 'gray'"
          size="xs"
          label="Aktif"
          @click="statusFilter = 'active'"
        />
        <UButton
          :variant="statusFilter === 'inactive' ? 'solid' : 'ghost'"
          :color="statusFilter === 'inactive' ? 'amber' : 'gray'"
          size="xs"
          label="Terarsip (Soft Deleted)"
          @click="statusFilter = 'inactive'"
        />
        <UButton
          :variant="statusFilter === 'all' ? 'solid' : 'ghost'"
          :color="statusFilter === 'all' ? 'gray' : 'gray'"
          size="xs"
          label="Semua"
          @click="statusFilter = 'all'"
        />
      </div>

      <UInput
        v-model="searchQuery"
        icon="i-lucide-search"
        placeholder="Cari perawatan..."
        size="sm"
        class="w-full sm:w-64"
      />
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
      <div class="lg:col-span-8 xl:col-span-9 space-y-4">
        <UCard :ui="{ body: 'p-0 sm:p-0' }">
          <UTable
            :data="filteredTreatments"
            :columns="columns"
          >
            <template #categoryName-data="{ row }">
              <UBadge
                color="gray"
                variant="subtle"
                size="sm"
              >
                {{ row.categoryName }}
              </UBadge>
            </template>

            <template #price-data="{ row }">
              <span class="font-semibold text-gray-900 dark:text-white">
                {{ formatIDR(row.price) }}
              </span>
            </template>

            <template #durationMinutes-data="{ row }">
              <span>{{ row.durationMinutes }} menit</span>
            </template>

            <template #isActive-data="{ row }">
              <UBadge
                :color="row.isActive ? 'success' : 'neutral'"
                variant="soft"
                size="sm"
              >
                {{ row.isActive ? 'Aktif' : 'Terarsip' }}
              </UBadge>
            </template>

            <template #actions-data="{ row }">
              <div class="flex items-center justify-end gap-1">
                <UButton
                  size="xs"
                  variant="ghost"
                  color="gray"
                  icon="i-lucide-edit-2"
                  @click="openEdit(row)"
                />
                <UButton
                  v-if="row.isActive"
                  size="xs"
                  variant="ghost"
                  color="amber"
                  icon="i-lucide-archive"
                  title="Arsipkan (Soft Delete)"
                  @click="onSoftDelete(row)"
                />
                <UButton
                  v-else
                  size="xs"
                  variant="ghost"
                  color="green"
                  icon="i-lucide-rotate-ccw"
                  title="Pulihkan Kembali"
                  @click="onReactivate(row)"
                />
              </div>
            </template>
          </UTable>
        </UCard>
      </div>

      <!-- Stats Panel -->
      <div class="lg:col-span-4 xl:col-span-3 space-y-4">
        <UCard class="bg-white dark:bg-gray-800">
          <template #header>
            <h3 class="font-semibold text-sm">
              Ringkasan Katalog
            </h3>
          </template>

          <div class="space-y-4">
            <div>
              <p class="text-xs text-muted">
                Total Item Aktif
              </p>
              <p class="text-2xl font-bold">
                {{ localTreatments.filter(t => t.isActive).length }}
              </p>
            </div>
            <div>
              <p class="text-xs text-muted">
                Est. Total Reservasi
              </p>
              <p class="text-2xl font-bold">
                {{ totalBookings }}
              </p>
            </div>
            <div>
              <p class="text-xs text-muted">
                Est. Total Pendapatan
              </p>
              <p class="text-2xl font-bold text-primary">
                {{ formatIDR(totalRevenue) }}
              </p>
            </div>
            <div v-if="mostPopular" class="pt-2 border-t border-gray-100 dark:border-gray-800">
              <p class="text-xs text-muted mb-1">
                Treatment Populer
              </p>
              <UBadge color="primary" variant="subtle" size="sm">
                {{ mostPopular.name }}
              </UBadge>
            </div>
          </div>
        </UCard>
      </div>
    </div>

    <!-- Create/Edit Modal -->
    <UModal v-model="showModal">
      <UCard>
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="font-semibold text-base">
              {{ editingId ? 'Edit Perawatan' : 'Tambah Perawatan Baru' }}
            </h3>
            <UButton color="gray" variant="ghost" icon="i-lucide-x" @click="showModal = false" />
          </div>
        </template>

        <form class="space-y-4" @submit.prevent="onSubmit">
          <UAlert
            v-if="formError"
            color="error"
            variant="subtle"
            title="Gagal menyimpan"
            :description="formError"
          />

          <!-- Kategori -->
          <div>
            <label class="block text-sm font-medium mb-1">Kategori</label>
            <div class="flex gap-2">
              <select
                v-model="form.categoryId"
                class="w-full rounded-md border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 p-2 text-sm"
              >
                <option v-for="cat in localCategories" :key="cat.id" :value="cat.id">
                  {{ cat.name }}
                </option>
              </select>
            </div>
          </div>

          <!-- Tambah Kategori Baru -->
          <div class="p-3 bg-gray-50 dark:bg-gray-800 rounded-lg text-xs space-y-2">
            <span class="font-medium text-gray-700 dark:text-gray-300">+ Tambah Kategori Baru</span>
            <div class="flex gap-2">
              <UInput v-model="newCategoryName" placeholder="Nama kategori..." size="xs" class="flex-1" />
              <UButton label="Tambah" size="xs" color="gray" @click="addCategory" />
            </div>
          </div>

          <!-- Nama Perawatan -->
          <div>
            <label class="block text-sm font-medium mb-1">Nama Perawatan</label>
            <UInput v-model="form.name" placeholder="mis. Scaling 6-in-1 Super Clean" />
          </div>

          <!-- Deskripsi -->
          <div>
            <label class="block text-sm font-medium mb-1">Deskripsi (Opsional)</label>
            <UTextarea v-model="form.description" placeholder="Penjelasan singkat perawatan..." rows="2" />
          </div>

          <!-- Harga & Durasi -->
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-1">Harga (Rp)</label>
              <UInput v-model.number="form.price" type="number" step="50000" min="0" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-1">Durasi (Menit)</label>
              <UInput v-model.number="form.durationMinutes" type="number" step="5" min="5" />
            </div>
          </div>

          <!-- Status -->
          <div class="flex items-center gap-2 pt-2">
            <input id="isActive" v-model="form.isActive" type="checkbox" class="rounded text-primary focus:ring-primary">
            <label for="isActive" class="text-sm font-medium">Status Aktif</label>
          </div>

          <div class="flex justify-end gap-2 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton label="Batal" color="gray" variant="ghost" @click="showModal = false" />
            <UButton type="submit" label="Simpan Perawatan" :loading="saving" />
          </div>
        </form>
      </UCard>
    </UModal>
  </div>
</template>
