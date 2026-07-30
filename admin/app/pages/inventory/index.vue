<script setup lang="ts">
import type { InventoryItem, InventoryItemInput } from '~/types/api'

definePageMeta({ title: 'Inventaris (Alat & Obat)' })

const { data: items, status, refresh, error } = useApiFetch<InventoryItem[]>('/inventory')

const categoryLabel: Record<string, string> = { obat: 'Obat', alat: 'Alat' }

const columns = [
  { accessorKey: 'category', header: 'Kategori' },
  { accessorKey: 'name', header: 'Nama' },
  { accessorKey: 'stockQuantity', header: 'Stok' },
  { accessorKey: 'unitPrice', header: 'Harga Satuan' },
  { accessorKey: 'isActive', header: 'Status' },
  { id: 'actions', header: '' }
]

function isLowStock(item: InventoryItem) {
  return item.stockQuantity <= item.reorderThreshold
}

const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')
const form = reactive<InventoryItemInput>({
  name: '',
  category: 'obat',
  unit: 'pcs',
  stockQuantity: 0,
  unitPrice: 0,
  reorderThreshold: 0,
  isActive: true
})

function openCreate() {
  editingId.value = null
  form.name = ''
  form.category = 'obat'
  form.unit = 'pcs'
  form.stockQuantity = 0
  form.unitPrice = 0
  form.reorderThreshold = 0
  form.isActive = true
  formError.value = ''
  showModal.value = true
}

function openEdit(item: InventoryItem) {
  editingId.value = item.id
  form.name = item.name
  form.category = item.category
  form.unit = item.unit
  form.stockQuantity = item.stockQuantity
  form.unitPrice = item.unitPrice
  form.reorderThreshold = item.reorderThreshold
  form.isActive = item.isActive
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  if (!form.name) {
    formError.value = 'Nama item wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    if (editingId.value) {
      await apiPut(`/inventory/${editingId.value}`, form as unknown as Record<string, unknown>)
    } else {
      await apiPost('/inventory', form as unknown as Record<string, unknown>)
    }
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

async function onDelete(item: InventoryItem) {
  if (!confirm(`Hapus item "${item.name}"?`)) return
  try {
    await apiDelete(`/inventory/${item.id}`)
    await refresh()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold">
          Inventaris (Alat & Obat)
        </h1>
        <p class="text-sm text-muted">
          Master data stok alat & obat. Berkurang otomatis saat dipakai di Rekam Medis.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah Item"
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

    <SkeletonTableSkeleton
      v-if="status === 'pending'"
      :columns="6"
    />
    <UTable
      v-else
      :data="items ?? []"
      :columns="columns"
    >
      <template #category-cell="{ row }">
        <UBadge
          :color="row.original.category === 'obat' ? 'info' : 'primary'"
          variant="subtle"
        >
          {{ categoryLabel[row.original.category] ?? row.original.category }}
        </UBadge>
      </template>
      <template #stockQuantity-cell="{ row }">
        <span :class="isLowStock(row.original) ? 'text-error font-medium' : ''">
          {{ row.original.stockQuantity }} {{ row.original.unit }}
        </span>
        <UBadge
          v-if="isLowStock(row.original)"
          color="error"
          variant="subtle"
          size="xs"
          class="ml-2"
        >
          Stok Menipis
        </UBadge>
      </template>
      <template #unitPrice-cell="{ row }">
        {{ formatIDR(row.original.unitPrice) }}
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

    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Item' : 'Tambah Item'"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <UFormField
            label="Nama Item"
            required
          >
            <UInput
              v-model="form.name"
              class="w-full"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Kategori"
              required
            >
              <USelect
                v-model="form.category"
                :items="[{ label: 'Obat', value: 'obat' }, { label: 'Alat', value: 'alat' }]"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Satuan"
              required
            >
              <UInput
                v-model="form.unit"
                class="w-full"
                placeholder="pcs, botol, ampul, dst"
              />
            </UFormField>
          </div>
          <div class="grid grid-cols-3 gap-4">
            <UFormField label="Stok">
              <UInput
                v-model.number="form.stockQuantity"
                type="number"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Harga Satuan">
              <UInput
                v-model.number="form.unitPrice"
                type="number"
                class="w-full"
              />
            </UFormField>
            <UFormField label="Batas Reorder">
              <UInput
                v-model.number="form.reorderThreshold"
                type="number"
                class="w-full"
              />
            </UFormField>
          </div>
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
  </UContainer>
</template>
