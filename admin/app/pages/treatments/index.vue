<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { Treatment, TreatmentCategory, TreatmentInput, TreatmentStat } from '~/types/api'

definePageMeta({ title: 'Perawatan & Harga' })

const { data: treatments, status, refresh, error } = useApiFetch<Treatment[]>('/treatments')
const { data: categories, refresh: refreshCategories } = useApiFetch<TreatmentCategory[]>('/treatment-categories')
const { data: stats, status: statsStatus } = useApiFetch<TreatmentStat[]>('/treatments/stats')

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
const totalBookings = computed(() => (stats.value ?? []).reduce((sum, s) => sum + s.bookingCount, 0))
const totalRevenue = computed(() => (stats.value ?? []).reduce((sum, s) => sum + s.revenue, 0))
const mostPopular = computed(() => stats.value?.[0])

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
  form.categoryId = categories.value?.[0]?.id ?? ''
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

async function addCategory() {
  if (!newCategoryName.value) return
  await apiPost('/treatment-categories', { name: newCategoryName.value })
  newCategoryName.value = ''
  await refreshCategories()
}

async function onSubmit() {
  if (!form.categoryId || !form.name || form.price <= 0) {
    formError.value = 'Kategori, nama, dan harga (lebih dari 0) wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const payload: TreatmentInput = {
      categoryId: form.categoryId,
      name: form.name,
      description: form.description || null,
      price: form.price,
      durationMinutes: form.durationMinutes,
      imageUrl: form.imageUrl || null,
      isActive: form.isActive
    }
    if (editingId.value) {
      await apiPut(`/treatments/${editingId.value}`, payload as unknown as Record<string, unknown>)
    } else {
      await apiPost('/treatments', payload as unknown as Record<string, unknown>)
    }
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

async function onDelete(treatment: Treatment) {
  if (!confirm(`Hapus perawatan "${treatment.name}"?`)) return
  try {
    await apiDelete(`/treatments/${treatment.id}`)
    await refresh()
  } catch (err) {
    alert(apiErrorMessage(err))
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
          Katalog treatment Nina Dental Care.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah Perawatan"
        @click="openCreate"
      />
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6">
      <div class="lg:col-span-8 xl:col-span-9 space-y-4">
        <UCard :ui="{ body: 'p-0 sm:p-0' }">
          <SkeletonTableSkeleton
            v-if="status === 'pending'"
            :columns="6"
          />
          <UTable
            v-else
            :data="treatments ?? []"
            :columns="columns"
          >
            <template #price-cell="{ row }">
              {{ formatIDR(row.original.price) }}
            </template>
            <template #durationMinutes-cell="{ row }">
              {{ row.original.durationMinutes }} menit
            </template>
            <template #isActive-cell="{ row }">
              <UBadge
                :color="row.original.isActive ? 'success' : 'neutral'"
                variant="subtle"
              >
                {{ row.original.isActive ? 'Aktif' : 'Nonaktif' }}
              </UBadge>
            </template>
            <template #actions-cell="{ row }">
              <div class="flex justify-end gap-1">
                <UButton
                  icon="i-lucide-pencil"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                  @click="openEdit(row.original)"
                />
                <UButton
                  icon="i-lucide-trash-2"
                  size="xs"
                  color="error"
                  variant="ghost"
                  @click="onDelete(row.original)"
                />
              </div>
            </template>
          </UTable>
        </UCard>
      </div>

      <!-- Right-side stats panel -->
      <div class="lg:col-span-4 xl:col-span-3 space-y-4">
        <template v-if="statsStatus === 'pending'">
          <SkeletonStatCardSkeleton
            v-for="i in 2"
            :key="i"
          />
          <SkeletonChartSkeleton />
        </template>
        <template v-else>
          <div class="grid grid-cols-2 gap-2">
            <UPageCard
              :title="String(totalBookings)"
              description="Total Booking"
            />
            <UPageCard
              :title="formatCompactIDR(totalRevenue)"
              description="Total Revenue"
            />
          </div>
          <UCard v-if="mostPopular">
            <template #header>
              <h3 class="text-sm font-medium">
                Paling Diminati
              </h3>
            </template>
            <p class="font-semibold">
              {{ mostPopular.treatmentName }}
            </p>
            <p class="text-sm text-muted">
              {{ mostPopular.bookingCount }} booking · {{ formatIDR(mostPopular.revenue) }}
            </p>
          </UCard>
          <UCard>
            <template #header>
              <h3 class="text-sm font-medium">
                Perawatan Paling Banyak Dipesan
              </h3>
            </template>
            <ChartsEChart
              :option="statsOption"
              height="260px"
            />
          </UCard>
        </template>
      </div>
    </div>

    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Perawatan' : 'Tambah Perawatan'"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <UFormField label="Kategori">
            <div class="flex gap-2">
              <USelect
                v-model="form.categoryId"
                :items="(categories ?? []).map(c => ({ label: c.name, value: c.id }))"
                class="flex-1"
              />
              <UInput
                v-model="newCategoryName"
                placeholder="Kategori baru..."
                class="w-40"
              />
              <UButton
                icon="i-lucide-plus"
                color="neutral"
                variant="soft"
                @click="addCategory"
              />
            </div>
          </UFormField>
          <UFormField
            label="Nama Perawatan"
            required
          >
            <UInput
              v-model="form.name"
              class="w-full"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Harga"
              required
            >
              <UInput
                v-model.number="form.price"
                type="number"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Durasi (menit)">
              <UInput
                v-model.number="form.durationMinutes"
                type="number"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Gambar (URL)">
            <UInput
              v-model="form.imageUrl"
              class="w-full"
              placeholder="https://..."
            />
          </UFormField>
          <UFormField label="Deskripsi">
            <UTextarea
              v-model="form.description"
              class="w-full"
              :rows="2"
            />
          </UFormField>
          <UFormField label="Status">
            <USwitch
              v-model="form.isActive"
              :label="form.isActive ? 'Aktif' : 'Nonaktif'"
            />
          </UFormField>

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
  </div>
</template>
