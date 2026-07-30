<script setup lang="ts">
import type { CreateMedicalRecordInput, DoctorDetail, InventoryItem, MedicalRecord, MedicalRecordDetail, Patient, Reservation } from '~/types/api'

interface OdontogramFormRow { toothNumber: number, condition: string, notes: string, photoUrl: string }
interface ItemUsageFormRow { inventoryItemId: string, quantity: number, notes: string }

definePageMeta({ title: 'Rekam Medis' })

const { data: records, status, refresh, error } = useApiFetch<MedicalRecord[]>('/medical-records')
const { data: patients } = useApiFetch<Patient[]>('/patients')
const { data: doctorsAdmin } = useApiFetch<DoctorDetail[]>('/doctors/admin')
const { data: reservations } = useApiFetch<Reservation[]>('/reservations')
const { data: inventoryItems } = useApiFetch<InventoryItem[]>('/inventory')

const columns = [
  { accessorKey: 'createdAt', header: 'Tanggal' },
  { accessorKey: 'patientName', header: 'Pasien' },
  { accessorKey: 'doctorName', header: 'Dokter' },
  { accessorKey: 'diagnosis', header: 'Diagnosis' },
  { id: 'actions', header: '' }
]

const CONDITIONS = [
  { label: 'Sehat', value: 'healthy' },
  { label: 'Karies', value: 'caries' },
  { label: 'Ditambal', value: 'filled' },
  { label: 'Dicabut', value: 'extracted' },
  { label: 'Mahkota', value: 'crown' },
  { label: 'Lainnya', value: 'other' }
]

// --- Detail view ---
const showDetail = ref(false)
const detail = ref<MedicalRecordDetail | null>(null)
async function openDetail(record: MedicalRecord) {
  detail.value = await $fetch<MedicalRecordDetail>(apiUrl(`/medical-records/${record.id}`))
  showDetail.value = true
}

// --- Create modal ---
const showModal = ref(false)
const saving = ref(false)
const formError = ref('')
const form = reactive({
  patientId: '',
  reservationId: '',
  staffId: '',
  diagnosis: '',
  treatmentNotes: '',
  odontogram: [] as OdontogramFormRow[],
  itemsUsed: [] as ItemUsageFormRow[]
})

function openCreate() {
  form.patientId = ''
  form.reservationId = ''
  form.staffId = ''
  form.diagnosis = ''
  form.treatmentNotes = ''
  form.odontogram = []
  form.itemsUsed = []
  formError.value = ''
  showModal.value = true
}

function addOdontogramRow() {
  form.odontogram.push({ toothNumber: 11, condition: 'caries', notes: '', photoUrl: '' })
}
function removeOdontogramRow(i: number) {
  form.odontogram.splice(i, 1)
}
function addItemRow() {
  form.itemsUsed.push({ inventoryItemId: inventoryItems.value?.[0]?.id ?? '', quantity: 1, notes: '' })
}
function removeItemRow(i: number) {
  form.itemsUsed.splice(i, 1)
}

async function onSubmit() {
  if (!form.patientId || !form.staffId) {
    formError.value = 'Pasien dan dokter wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const payload: CreateMedicalRecordInput = {
      patientId: form.patientId,
      reservationId: form.reservationId || null,
      staffId: form.staffId,
      diagnosis: form.diagnosis || null,
      treatmentNotes: form.treatmentNotes || null,
      odontogram: form.odontogram.map(o => ({ ...o, notes: o.notes || null, photoUrl: o.photoUrl || null })),
      itemsUsed: form.itemsUsed.map(u => ({ ...u, notes: u.notes || null }))
    }
    await apiPost('/medical-records', payload as unknown as Record<string, unknown>)
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

function itemName(id: string) {
  return inventoryItems.value?.find(i => i.id === id)?.name ?? id
}
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold">
          Rekam Medis
        </h1>
        <p class="text-sm text-muted">
          Append-only — setiap tindakan dicatat sebagai entri baru, termasuk pemakaian alat & obat.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah Rekam Medis"
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
      :columns="5"
    />
    <UTable
      v-else
      :data="records ?? []"
      :columns="columns"
    >
      <template #createdAt-cell="{ row }">
        {{ formatDateTime(row.original.createdAt) }}
      </template>
      <template #diagnosis-cell="{ row }">
        <span class="line-clamp-1">{{ row.original.diagnosis ?? '—' }}</span>
      </template>
      <template #actions-cell="{ row }">
        <UButton
          icon="i-lucide-eye"
          size="xs"
          color="neutral"
          variant="ghost"
          label="Detail"
          @click="openDetail(row.original)"
        />
      </template>
    </UTable>

    <!-- Detail slideover -->
    <USlideover
      v-model:open="showDetail"
      title="Detail Rekam Medis"
    >
      <template #body>
        <div
          v-if="detail"
          class="space-y-4 text-sm"
        >
          <div>
            <p class="text-muted">
              Pasien
            </p>
            <p class="font-medium">
              {{ detail.patientName }}
            </p>
          </div>
          <div>
            <p class="text-muted">
              Dokter
            </p>
            <p class="font-medium">
              {{ detail.doctorName }}
            </p>
          </div>
          <div>
            <p class="text-muted">
              Tanggal
            </p>
            <p class="font-medium">
              {{ formatDateTime(detail.createdAt) }}
            </p>
          </div>
          <div>
            <p class="text-muted">
              Diagnosis
            </p>
            <p>{{ detail.diagnosis ?? '—' }}</p>
          </div>
          <div>
            <p class="text-muted">
              Catatan Tindakan
            </p>
            <p>{{ detail.treatmentNotes ?? '—' }}</p>
          </div>
          <div v-if="detail.odontogram?.length">
            <p class="text-muted mb-1">
              Odontogram
            </p>
            <ul class="space-y-1">
              <li
                v-for="o in detail.odontogram"
                :key="o.id"
              >
                Gigi {{ o.toothNumber }} — {{ o.condition }}<span v-if="o.notes"> ({{ o.notes }})</span>
              </li>
            </ul>
          </div>
          <div v-if="detail.itemsUsed?.length">
            <p class="text-muted mb-1">
              Alat & Obat Digunakan
            </p>
            <ul class="space-y-1">
              <li
                v-for="u in detail.itemsUsed"
                :key="u.id"
              >
                {{ u.itemName }} — {{ u.quantity }} {{ u.unit }}
              </li>
            </ul>
          </div>
        </div>
      </template>
    </USlideover>

    <!-- Create modal -->
    <UModal
      v-model:open="showModal"
      title="Tambah Rekam Medis"
      :ui="{ content: 'max-w-2xl' }"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Pasien"
              required
            >
              <USelect
                v-model="form.patientId"
                :items="(patients ?? []).map(p => ({ label: p.fullName, value: p.id }))"
                class="w-full"
                searchable
              />
            </UFormField>
            <UFormField
              label="Dokter"
              required
            >
              <USelect
                v-model="form.staffId"
                :items="(doctorsAdmin ?? []).map(d => ({ label: d.fullName, value: d.id }))"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Reservasi Terkait (opsional)">
            <USelect
              v-model="form.reservationId"
              :items="[{ label: 'Tidak ada', value: '' }, ...(reservations ?? []).map(r => ({ label: `${r.patientName} — ${formatDateTime(r.scheduledAt)}`, value: r.id }))]"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Diagnosis">
            <UTextarea
              v-model="form.diagnosis"
              class="w-full"
              :rows="2"
            />
          </UFormField>
          <UFormField label="Catatan Tindakan">
            <UTextarea
              v-model="form.treatmentNotes"
              class="w-full"
              :rows="2"
            />
          </UFormField>

          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-sm font-medium">Odontogram (opsional)</span>
              <UButton
                icon="i-lucide-plus"
                size="xs"
                variant="soft"
                label="Tambah"
                @click="addOdontogramRow"
              />
            </div>
            <div
              v-for="(o, i) in form.odontogram"
              :key="i"
              class="flex items-end gap-2"
            >
              <UFormField
                label="No. Gigi"
                class="w-24"
              >
                <UInput
                  v-model.number="o.toothNumber"
                  type="number"
                />
              </UFormField>
              <UFormField
                label="Kondisi"
                class="flex-1"
              >
                <USelect
                  v-model="o.condition"
                  :items="CONDITIONS"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                label="Catatan"
                class="flex-1"
              >
                <UInput
                  v-model="o.notes"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                label="Foto (URL)"
                class="flex-1"
              >
                <UInput
                  v-model="o.photoUrl"
                  class="w-full"
                  placeholder="https://..."
                />
              </UFormField>
              <UButton
                icon="i-lucide-trash-2"
                color="error"
                variant="ghost"
                @click="removeOdontogramRow(i)"
              />
            </div>
          </div>

          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-sm font-medium">Alat & Obat Digunakan (opsional)</span>
              <UButton
                icon="i-lucide-plus"
                size="xs"
                variant="soft"
                label="Tambah"
                @click="addItemRow"
              />
            </div>
            <div
              v-for="(u, i) in form.itemsUsed"
              :key="i"
              class="flex items-end gap-2"
            >
              <UFormField
                label="Item"
                class="flex-1"
              >
                <USelect
                  v-model="u.inventoryItemId"
                  :items="(inventoryItems ?? []).map(item => ({ label: `${item.name} (stok: ${item.stockQuantity} ${item.unit})`, value: item.id }))"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                label="Jumlah"
                class="w-28"
              >
                <UInput
                  v-model.number="u.quantity"
                  type="number"
                />
              </UFormField>
              <UButton
                icon="i-lucide-trash-2"
                color="error"
                variant="ghost"
                @click="removeItemRow(i)"
              />
            </div>
            <p
              v-if="form.itemsUsed.length"
              class="text-xs text-muted"
            >
              Stok akan berkurang otomatis: {{ form.itemsUsed.map(u => `${itemName(u.inventoryItemId)} (-${u.quantity})`).join(', ') }}
            </p>
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
