<script setup lang="ts">
import type { CreateMedicalRecordInput, DoctorDetail, InventoryItem, MedicalRecord, MedicalRecordDetail, Patient, Reservation } from '~/types/api'

interface OdontogramFormRow { toothNumber: number, condition: string, notes: string, photoUrl: string }
interface ItemUsageFormRow { inventoryItemId: string, quantity: number, notes: string }

definePageMeta({ title: 'Rekam Medis & Follow-up Kontrol' })

const { data: records, status, refresh, error } = useApiFetch<MedicalRecord[]>('/medical-records')
const { data: patients } = useApiFetch<Patient[]>('/patients')
const { data: doctorsAdmin } = useApiFetch<DoctorDetail[]>('/doctors/admin')
const { data: reservations } = useApiFetch<Reservation[]>('/reservations')
const { data: inventoryItems } = useApiFetch<InventoryItem[]>('/inventory')

const { followUpList, markAsReminded, getWhatsAppLink } = useFollowUpPatients()

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
  try {
    detail.value = await $fetch<MedicalRecordDetail>(apiUrl(`/medical-records/${record.id}`))
  } catch (_) {
    detail.value = {
      ...record,
      odontogram: [],
      itemsUsed: []
    }
  }
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
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-2">
      <div>
        <h1 class="text-xl font-semibold">
          Rekam Medis & Follow-Up Kontrol
        </h1>
        <p class="text-sm text-muted">
          Pencatatan rekam medis, odontogram, dan rekomendasi kontrol berkala pasien.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah Rekam Medis"
        @click="openCreate"
      />
    </div>

    <!-- 2-Column Layout Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      <!-- Left Column: Medical Records Table -->
      <div class="lg:col-span-7 xl:col-span-8 space-y-4">
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
          class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-xs"
        >
          <template #createdAt-cell="{ row }">
            {{ formatDateTime(row.original.createdAt) }}
          </template>
          <template #diagnosis-cell="{ row }">
            <span class="line-clamp-1 font-medium">{{ row.original.diagnosis ?? '—' }}</span>
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
      </div>

      <!-- Right Column: Panel Pasien Rekomendasi Kontrol Terdekat -->
      <div class="lg:col-span-5 xl:col-span-4 lg:sticky lg:top-4">
        <UCard class="bg-white dark:bg-gray-800 border-l-4 border-l-amber-500 shadow-xs">
          <template #header>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-stethoscope" class="w-5 h-5 text-amber-500" />
                <div>
                  <h2 class="font-bold text-sm text-gray-900 dark:text-white">
                    Rekomendasi Kontrol Pasien Dari Rekam Medis (Terdekat)
                  </h2>
                  <p class="text-[11px] text-gray-500">
                    Pasien yang memerlukan jadwal kontrol lanjutan (Kontrol Behel, Pasca Operasi/Cabut Gigi, atau Scaling 6 Bulan).
                  </p>
                </div>
              </div>
              <UBadge color="amber" variant="subtle" size="xs">
                {{ followUpList.length }} Pasien
              </UBadge>
            </div>
          </template>

          <div class="space-y-3 max-h-[calc(100vh-220px)] overflow-y-auto pr-1">
            <div
              v-for="fu in followUpList"
              :key="fu.id"
              class="p-3 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/50 dark:bg-gray-900/40 space-y-2"
            >
              <div class="flex items-center justify-between">
                <div class="flex items-center gap-2">
                  <span class="font-bold text-xs text-gray-900 dark:text-white">{{ fu.patientName }}</span>
                  <UBadge color="neutral" variant="outline" size="xs">{{ fu.rmNumber }}</UBadge>
                </div>
                <UBadge :color="fu.daysRemaining <= 1 ? 'error' : 'warning'" variant="soft" size="xs">
                  {{ fu.daysRemaining === 1 ? 'Besok Kontrol' : `${fu.daysRemaining} Hari Lagi` }}
                </UBadge>
              </div>

              <div class="text-xs text-gray-600 dark:text-gray-300 space-y-0.5">
                <div><span class="text-gray-400">Rekomendasi:</span> <b>{{ fu.controlReason }}</b></div>
                <div><span class="text-gray-400">Tindakan Medis Sebelumnya:</span> {{ fu.treatmentName }}</div>
                <div><span class="text-gray-400">Target Kontrol:</span> <span class="font-semibold text-primary">{{ fu.recommendedControlDate }}</span> ({{ fu.doctorName }})</div>
              </div>

              <div class="flex items-center justify-between pt-2 border-t border-gray-200 dark:border-gray-700">
                <span class="text-[11px] font-mono text-gray-400">{{ fu.phoneWa }}</span>
                <a
                  :href="getWhatsAppLink(fu)"
                  target="_blank"
                  class="inline-flex items-center gap-1 text-xs font-bold text-emerald-600 dark:text-emerald-400 hover:underline"
                  @click="markAsReminded(fu.id)"
                >
                  <UIcon name="i-lucide-send" class="w-3.5 h-3.5" />
                  <span>{{ fu.status === 'REMINDED' ? 'Kirim Ulang WA' : 'Kirim Reminder WA' }}</span>
                </a>
              </div>
            </div>
          </div>
        </UCard>
      </div>
    </div>

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
              <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                <UIcon name="i-lucide-user" class="w-4 h-4 text-primary" />
                {{ detail.patientName }}
              </span>
            </div>
            <div class="flex items-center justify-between pt-1 border-t border-default">
              <span class="text-xs font-semibold text-muted">Dokter Penanggung Jawab</span>
              <span class="font-semibold text-gray-800 dark:text-gray-200">
                {{ detail.doctorName }}
              </span>
            </div>
          </div>
        </div>
      </template>
    </USlideover>
  </div>
</template>
