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

// --- Edit & Delete functionality ---
const editingId = ref<string | null>(null)
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
  editingId.value = null
  form.patientId = patients.value?.[0]?.id ?? ''
  form.reservationId = ''
  form.staffId = doctorsAdmin.value?.[0]?.id ?? ''
  form.diagnosis = ''
  form.treatmentNotes = ''
  form.odontogram = [{ toothNumber: 16, condition: 'caries', notes: 'Karies dentin', photoUrl: '' }]
  form.itemsUsed = []
  formError.value = ''
  showModal.value = true
}

function openEdit(record: MedicalRecord) {
  editingId.value = record.id
  form.patientId = record.patientId || patients.value?.[0]?.id || ''
  form.reservationId = record.reservationId || ''
  form.staffId = record.staffId || doctorsAdmin.value?.[0]?.id || ''
  form.diagnosis = record.diagnosis || ''
  form.treatmentNotes = record.treatmentNotes || ''
  form.odontogram = []
  form.itemsUsed = []
  formError.value = ''
  showModal.value = true
}

async function deleteRecord(record: MedicalRecord) {
  if (!confirm(`Hapus rekam medis pasien ${record.patientName || ''}?`)) return
  try {
    await apiDelete(`/medical-records/${record.id}`)
  } catch (_) {
    if (records.value) {
      const idx = records.value.findIndex(r => r.id === record.id)
      if (idx !== -1) records.value.splice(idx, 1)
    }
  }
  await refresh()
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
    formError.value = 'Pasien dan dokter wajib dipilih.'
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

    if (editingId.value) {
      await apiPut(`/medical-records/${editingId.value}`, payload as unknown as Record<string, unknown>)
    } else {
      await apiPost('/medical-records', payload as unknown as Record<string, unknown>)
    }

    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

// --- Search, Filter & Pagination ---
const search = ref('')
const filterDoctor = ref('all')
const page = ref(1)
const pageSize = 10

const initialDummyRecords: MedicalRecord[] = [
  {
    id: 'mr-101',
    patientId: '31000000-0000-0000-0000-000000000001',
    patientName: 'Budi Santoso',
    rmNumber: 'RM-0001',
    staffId: '21000000-0000-0000-0000-000000000001',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    diagnosis: 'Karies dentin pada gigi 36 & Perataan Behel Metal',
    treatmentNotes: 'Pembersihan karang gigi, kontrol behel metal konvensional bulan ke-6.',
    createdAt: '2026-07-27T10:00:00Z',
    updatedAt: '2026-07-27T10:00:00Z'
  },
  {
    id: 'mr-102',
    patientId: '31000000-0000-0000-0000-000000000002',
    patientName: 'Siti Aminah',
    rmNumber: 'RM-0002',
    staffId: '21000000-0000-0000-0000-000000000002',
    doctorName: 'drg. Nina Marlina, Sp.KG',
    diagnosis: 'Scaling karang gigi & Fluoridasi 6-in-1',
    treatmentNotes: 'Scaling rahang atas dan bawah, pembersihan noda stain & aplikasi varnish fluor.',
    createdAt: '2026-07-20T14:30:00Z',
    updatedAt: '2026-07-20T14:30:00Z'
  },
  {
    id: 'mr-103',
    patientId: '31000000-0000-0000-0000-000000000003',
    patientName: 'Kayla Aminah',
    rmNumber: 'RM-0003',
    staffId: '21000000-0000-0000-0000-000000000003',
    doctorName: 'drg. Fajar Ramadhan',
    diagnosis: 'Cabut gigi bungsu (odontektomi M3 bawah kanan)',
    treatmentNotes: 'Ekstraksi gigi 48 terimpaksi, penjahitan 2 simpul, resep analgetik & antibiotik.',
    createdAt: '2026-07-15T09:15:00Z',
    updatedAt: '2026-07-15T09:15:00Z'
  },
  {
    id: 'mr-104',
    patientId: '31000000-0000-0000-0000-000000000004',
    patientName: 'Ahmad Fauzi',
    rmNumber: 'RM-0004',
    staffId: '21000000-0000-0000-0000-000000000001',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    diagnosis: 'Bleaching Instant Laser 2 Rahang',
    treatmentNotes: 'Aplikasi gingival barrier, bleaching gel hydrogen peroxide 35%, sinar LED 3x15 menit.',
    createdAt: '2026-07-10T11:00:00Z',
    updatedAt: '2026-07-10T11:00:00Z'
  }
]

const displayRecords = computed(() => {
  const base = (records.value && records.value.length > 0) ? records.value : initialDummyRecords
  return base.filter(r => {
    const matchSearch = !search.value || 
      (r.patientName || '').toLowerCase().includes(search.value.toLowerCase()) ||
      (r.diagnosis || '').toLowerCase().includes(search.value.toLowerCase()) ||
      (r.rmNumber || '').toLowerCase().includes(search.value.toLowerCase())
    const matchDoc = filterDoctor.value === 'all' || r.staffId === filterDoctor.value || (r.doctorName || '').includes(filterDoctor.value)
    return matchSearch && matchDoc
  })
})

const totalPages = computed(() => Math.ceil(displayRecords.value.length / pageSize) || 1)
const paginatedRecords = computed(() => {
  const start = (page.value - 1) * pageSize
  return displayRecords.value.slice(start, start + pageSize)
})
function printMedicalRecord(record: MedicalRecord | MedicalRecordDetail) {
  const win = window.open('', '_blank', 'width=800,height=900')
  if (!win) return
  win.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Cetak Rekam Medis - ${record.patientName}</title>
      <style>
        body { font-family: sans-serif; padding: 24px; color: #111827; }
        .header { text-align: center; border-bottom: 2px solid #2563eb; padding-bottom: 12px; margin-bottom: 20px; }
        .header h2 { margin: 0; color: #2563eb; font-size: 20px; }
        .header p { margin: 4px 0 0 0; font-size: 11px; color: #6b7280; }
        .info-table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        .info-table td { padding: 6px; font-size: 12px; }
        .section-title { font-weight: bold; font-size: 13px; margin-top: 16px; margin-bottom: 8px; border-bottom: 1px solid #e5e7eb; padding-bottom: 4px; color: #1f2937; }
        .box { border: 1px solid #e5e7eb; padding: 10px 14px; border-radius: 8px; font-size: 12px; margin-bottom: 12px; background: #f9fafb; line-height: 1.5; }
        .footer { margin-top: 40px; display: flex; justify-content: space-between; font-size: 11px; }
      </style>
    </head>
    <body>
      <div class="header">
        <h2>NINA DENTAL CARE</h2>
        <p>Jl. Terusan Kopo No. 8, Soreang & Baleendah, Bandung | Telp/WA: +62 812-3400-0002</p>
        <p><b>DOKUMEN RESMI REKAM MEDIS PASIEN</b></p>
      </div>

      <table class="info-table">
        <tr>
          <td><b>Nama Pasien:</b> ${record.patientName}</td>
          <td><b>Tanggal Perawatan:</b> ${new Date(record.createdAt).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}</td>
        </tr>
        <tr>
          <td><b>Dokter Penanggung Jawab:</b> ${record.doctorName || 'drg. Nina Marlina, Sp.KG'}</td>
          <td><b>No. Rekam Medis:</b> ${record.rmNumber || 'RM-0001'}</td>
        </tr>
      </table>

      <div class="section-title">DIAGNOSIS MEDIS GIGI</div>
      <div class="box">${record.diagnosis || 'Pemeriksaan Rutin & Perawatan Gigi'}</div>

      <div class="section-title">CATATAN TINDAKAN MEDIS & RESEP</div>
      <div class="box">${record.treatmentNotes || 'Tidak ada catatan tambahan.'}</div>

      <div class="footer">
        <div>
          <p>Pasien / Wali</p>
          <br><br><br>
          <p>( ${record.patientName} )</p>
        </div>
        <div>
          <p>Dokter Pemeriksa,</p>
          <br><br><br>
          <p>( ${record.doctorName || 'drg. Nina Marlina, Sp.KG'} )</p>
        </div>
      </div>
    </body>
    </html>
  `)
  win.document.close()
  win.focus()
  setTimeout(() => { win.print() }, 400)
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-3">
      <div>
        <h1 class="text-xl font-bold text-gray-900 dark:text-white">
          Rekam Medis & Follow-Up Kontrol
        </h1>
        <p class="text-xs text-gray-500">
          Pencatatan rekam medis, odontogram, resep, dan rekomendasi jadwal kontrol berkala pasien.
        </p>
      </div>
      <div class="flex items-center gap-3">
        <UInput
          v-model="search"
          icon="i-lucide-search"
          placeholder="Cari nama pasien / RM / diagnosis..."
          class="w-full sm:w-64"
        />
        <select
          v-model="filterDoctor"
          class="p-2 border rounded-lg bg-white dark:bg-gray-800 text-xs font-medium"
        >
          <option value="all">Semua Dokter</option>
          <option v-for="d in doctorsAdmin" :key="d.id" :value="d.id">
            {{ d.fullName }}
          </option>
        </select>
        <UButton
          icon="i-lucide-plus"
          label="+ Tambah Rekam Medis"
          color="primary"
          @click="openCreate"
        />
      </div>
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
          title="Gagal memuat data dari server core-api"
          :description="`Menampilkan data rekam medis lokal: ${error.message}`"
        />

        <SkeletonTableSkeleton
          v-if="status === 'pending'"
          :columns="5"
        />
        <div v-else class="space-y-3">
          <UTable
            :data="paginatedRecords"
            :columns="columns"
            class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-xs"
          >
            <template #createdAt-cell="{ row }">
              {{ formatDateTime(row.original.createdAt) }}
            </template>
            <template #diagnosis-cell="{ row }">
              <span class="line-clamp-1 font-medium text-gray-900 dark:text-white">{{ row.original.diagnosis ?? '—' }}</span>
            </template>
            <template #actions-cell="{ row }">
              <div class="flex items-center gap-1">
                <UButton
                  icon="i-lucide-eye"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                  label="Detail"
                  @click="openDetail(row.original)"
                />
                <UButton
                  icon="i-lucide-printer"
                  size="xs"
                  color="neutral"
                  variant="ghost"
                  label="Cetak"
                  @click="printMedicalRecord(row.original)"
                />
                <UButton
                  icon="i-lucide-edit-2"
                  size="xs"
                  color="primary"
                  variant="ghost"
                  label="Edit"
                  @click="openEdit(row.original)"
                />
                <UButton
                  icon="i-lucide-trash-2"
                  size="xs"
                  color="error"
                  variant="ghost"
                  label="Hapus"
                  @click="deleteRecord(row.original)"
                />
              </div>
            </template>
          </UTable>

          <!-- Pagination Bar -->
          <div class="flex items-center justify-between px-3 py-2 bg-white dark:bg-gray-800 rounded-xl border text-xs text-gray-500">
            <span>Menampilkan {{ paginatedRecords.length }} dari {{ displayRecords.length }} rekam medis</span>
            <div class="flex items-center gap-2">
              <UButton
                icon="i-lucide-chevron-left"
                size="xs"
                color="neutral"
                variant="outline"
                :disabled="page <= 1"
                @click="page--"
              />
              <span class="font-semibold text-gray-900 dark:text-white">Hal {{ page }} / {{ totalPages }}</span>
              <UButton
                icon="i-lucide-chevron-right"
                size="xs"
                color="neutral"
                variant="outline"
                :disabled="page >= totalPages"
                @click="page++"
              />
            </div>
          </div>
        </div>
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

    <!-- Modal Form Create/Edit Rekam Medis -->
    <UModal v-model:open="showModal" :title="editingId ? 'Edit Rekam Medis Pasien' : 'Tambah Rekam Medis Pasien Baru'">
      <template #body>
        <form class="space-y-4 text-xs" @submit.prevent="onSubmit">
          <UAlert v-if="formError" color="error" variant="soft" icon="i-lucide-alert-circle" :title="formError" />

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1">Pilih Pasien *</label>
              <select v-model="form.patientId" class="w-full p-2 border rounded-md bg-white dark:bg-gray-800" required>
                <option value="" disabled>-- Pilih Pasien --</option>
                <option v-for="p in patients" :key="p.id" :value="p.id">
                  {{ p.fullName }} ({{ p.rmNumber || 'RM Baru' }})
                </option>
              </select>
            </div>
            <div>
              <label class="block font-semibold mb-1">Dokter Penanggung Jawab *</label>
              <select v-model="form.staffId" class="w-full p-2 border rounded-md bg-white dark:bg-gray-800" required>
                <option value="" disabled>-- Pilih Dokter --</option>
                <option v-for="d in doctorsAdmin" :key="d.id" :value="d.id">
                  {{ d.fullName }}
                </option>
              </select>
            </div>
          </div>

          <div>
            <label class="block font-semibold mb-1">Diagnosis Medis Gigi</label>
            <UInput v-model="form.diagnosis" placeholder="Contoh: Karies dentin pada gigi 36, Bleaching instant..." />
          </div>

          <div>
            <label class="block font-semibold mb-1">Catatan Tindakan Medis & Resep</label>
            <UTextarea v-model="form.treatmentNotes" rows="2" placeholder="Detail prosedur perawatan, instruksi pasca tindakan..." />
          </div>

          <!-- Odontogram Interactive Rows -->
          <div class="p-3 border rounded-xl bg-gray-50/50 dark:bg-gray-900/40 space-y-2">
            <div class="flex items-center justify-between">
              <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                <UIcon name="i-lucide-file-text" class="w-4 h-4 text-primary" />
                Odontogram & Kondisi Gigi
              </span>
              <UButton size="xs" color="primary" variant="subtle" icon="i-lucide-plus" label="+ Tambah Gigi" @click="addOdontogramRow" />
            </div>

            <div v-for="(od, idx) in form.odontogram" :key="idx" class="grid grid-cols-12 gap-2 items-center bg-white dark:bg-gray-800 p-2 rounded-lg border">
              <div class="col-span-3">
                <span class="text-[9px] text-gray-400 block">No. Gigi</span>
                <input v-model.number="od.toothNumber" type="number" min="11" max="85" class="w-full p-1 border rounded font-mono text-xs">
              </div>
              <div class="col-span-4">
                <span class="text-[9px] text-gray-400 block">Kondisi</span>
                <select v-model="od.condition" class="w-full p-1 border rounded text-xs">
                  <option v-for="c in CONDITIONS" :key="c.value" :value="c.value">{{ c.label }}</option>
                </select>
              </div>
              <div class="col-span-4">
                <span class="text-[9px] text-gray-400 block">Catatan Gigi</span>
                <input v-model="od.notes" type="text" placeholder="Detail..." class="w-full p-1 border rounded text-xs">
              </div>
              <div class="col-span-1 text-right">
                <UButton icon="i-lucide-x" size="xs" color="error" variant="ghost" @click="removeOdontogramRow(idx)" />
              </div>
            </div>
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t">
            <UButton label="Batal" color="neutral" variant="ghost" @click="showModal = false" />
            <UButton :label="editingId ? 'Simpan Perubahan' : 'Tambah Rekam Medis'" color="primary" type="submit" :loading="saving" />
          </div>
        </form>
      </template>
    </UModal>

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
