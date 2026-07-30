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
  <div class="p-4 space-y-4 w-full max-w-none">
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
      title="Detail & Riwayat Rekam Medis"
    >
      <template #body>
        <div
          v-if="detail"
          class="space-y-4 text-sm"
        >
          <!-- Patient & Doctor Card -->
          <div class="p-3 rounded-xl border border-default bg-gray-50/50 dark:bg-gray-900/40 space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-xs font-semibold text-muted">Pasien</span>
              <span class="font-bold text-gray-900 dark:text-white">{{ detail.patientName }}</span>
            </div>
            <div class="flex items-center justify-between">
              <span class="text-xs font-semibold text-muted">Dokter Penanggung Jawab</span>
              <span class="font-medium text-primary">{{ detail.doctorName }}</span>
            </div>
            <div class="flex items-center justify-between border-t border-default pt-2 text-xs">
              <span class="text-muted">Tanggal Kunjungan</span>
              <span class="font-medium">{{ formatDateTime(detail.createdAt) }}</span>
            </div>
          </div>

          <!-- Diagnosis & Treatment Notes -->
          <div class="space-y-2">
            <div>
              <p class="text-xs font-semibold text-muted uppercase tracking-wider mb-1">Diagnosis Dokter</p>
              <div class="p-3 rounded-xl border border-default bg-card font-medium text-gray-900 dark:text-white">
                {{ detail.diagnosis ?? 'Tidak ada diagnosis khusus.' }}
              </div>
            </div>

            <div>
              <p class="text-xs font-semibold text-muted uppercase tracking-wider mb-1">Catatan Tindakan Medis</p>
              <div class="p-3 rounded-xl border border-default bg-card text-xs leading-relaxed text-gray-800 dark:text-gray-200">
                {{ detail.treatmentNotes ?? 'Tindakan telah diselesaikan sesuai SOP.' }}
              </div>
            </div>
          </div>

          <!-- Odontogram Table -->
          <div v-if="detail.odontogram?.length" class="space-y-1.5">
            <p class="text-xs font-semibold text-muted uppercase tracking-wider">Odontogram & Kondisi Gigi</p>
            <div class="rounded-xl border border-default overflow-hidden">
              <div v-for="o in detail.odontogram" :key="o.id" class="flex items-center justify-between p-2.5 border-b border-default last:border-0 text-xs">
                <span class="font-bold text-primary">Gigi #{{ o.toothNumber }}</span>
                <UBadge size="xs" color="warning" variant="subtle" class="capitalize">{{ o.condition }}</UBadge>
                <span v-if="o.notes" class="text-muted text-[11px] truncate max-w-[120px]">{{ o.notes }}</span>
              </div>
            </div>
          </div>

          <!-- Medicine & Tools Used -->
          <div v-if="detail.itemsUsed?.length" class="space-y-1.5">
            <p class="text-xs font-semibold text-muted uppercase tracking-wider">Alat, Bahan & Obat Terpakai</p>
            <div class="rounded-xl border border-default p-3 bg-card space-y-1.5">
              <div v-for="u in detail.itemsUsed" :key="u.id" class="flex justify-between items-center text-xs">
                <span class="font-medium text-gray-900 dark:text-white">{{ u.itemName }}</span>
                <span class="font-bold text-primary tabular-nums">{{ u.quantity }} {{ u.unit }}</span>
              </div>
            </div>
          </div>

          <!-- Medical History Timeline -->
          <div class="space-y-2 pt-2 border-t border-default">
            <p class="text-xs font-semibold text-muted uppercase tracking-wider flex items-center gap-1.5">
              <UIcon name="i-lucide-history" class="w-3.5 h-3.5 text-primary" />
              Riwayat Kunjungan Sebelumnya (History Timeline)
            </p>

            <div class="space-y-2 pl-2 border-l-2 border-primary-300 dark:border-primary-800">
              <div class="relative pl-3 space-y-0.5">
                <p class="text-xs font-bold text-gray-900 dark:text-white">Pemeriksaan & Fluoridasi Gigi</p>
                <p class="text-[11px] text-muted">14 Hari Lalu · drg. Friski Raisis, Sp.Ort</p>
                <p class="text-[11px] text-gray-700 dark:text-gray-300">Pemberian vitamin fluoride & pembersihan plak.</p>
              </div>

              <div class="relative pl-3 space-y-0.5 pt-2 border-t border-default/50">
                <p class="text-xs font-bold text-gray-900 dark:text-white">Konsultasi Awal Pemasangan Behel</p>
                <p class="text-[11px] text-muted">1 Bulan Lalu · drg. Siti Aminah</p>
                <p class="text-[11px] text-gray-700 dark:text-gray-300">Cetak rahang studi & foto Rontgen Panoramik.</p>
              </div>
            </div>
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
  </div>
</template>
