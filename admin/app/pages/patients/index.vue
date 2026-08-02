<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { CreatePatientInput, MedicalRecord, PaginatedResponse, Patient, PatientOdontogramTimeline, PatientStats, Payment, Promo, Reservation, UpdatePatientInput } from '~/types/api'

definePageMeta({ title: 'Pasien & Transformasi Senyum' })

export interface SmileTransformation {
  id: string
  patientId: string
  patientName: string
  doctorName: string
  title: string
  durationMonths: number
  beforePhotoUrl: string
  progressPhotoUrl: string
  afterPhotoUrl: string
  notes: string
  createdAt: string
}

const page = ref(1)
const pageSize = 10
const search = ref('')
const { data: patientsPage, status, refresh, error } = useApiFetch<PaginatedResponse<Patient>>(() => `/patients?page=${page.value}&pageSize=${pageSize}${search.value ? `&search=${encodeURIComponent(search.value)}` : ''}`)
const patients = computed(() => patientsPage.value?.data ?? [])
watch(search, () => {
  page.value = 1
})

const { data: reservations } = useApiFetch<Reservation[]>('/reservations')
const { data: payments } = useApiFetch<Payment[]>('/payments')
const { data: promos } = useApiFetch<Promo[]>('/content/promos')

const columns = [
  { id: 'photo', header: '' },
  { accessorKey: 'fullName', header: 'Nama Pasien' },
  { accessorKey: 'rmNumber', header: 'No. RM' },
  { accessorKey: 'relation', header: 'Relasi' },
  { accessorKey: 'createdAt', header: 'Terdaftar' }
]

const relationLabel: Record<string, string> = { self: 'Akun Sendiri', child: 'Anak', spouse: 'Pasangan', parent: 'Orang Tua', other: 'Lainnya' }
const RELATIONS = [
  { label: 'Akun Sendiri (baru)', value: 'self' },
  { label: 'Anak (keluarga)', value: 'child' },
  { label: 'Pasangan (keluarga)', value: 'spouse' },
  { label: 'Orang Tua (keluarga)', value: 'parent' },
  { label: 'Lainnya (keluarga)', value: 'other' }
]

function initials(name: string) {
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}

const manualPatientId = ref<string | null>(null)
const detailPatient = computed<Patient | null>(() => {
  const list = patients.value
  return list.find(p => p.id === manualPatientId.value) ?? list[0] ?? null
})

const detailReservations = computed(() => (reservations.value ?? []).filter(r => r.patientId === detailPatient.value?.id))
const detailPayments = computed(() => (payments.value ?? []).filter(p => p.patientId === detailPatient.value?.id))
const detailTotalPaid = computed(() => detailPayments.value.filter(p => p.status === 'paid').reduce((sum, p) => sum + p.amount, 0))

const detailStats = ref<PatientStats | null>(null)
const detailMedicalRecords = ref<MedicalRecord[]>([])
const detailOdontogramTimeline = ref<PatientOdontogramTimeline[]>([])
const detailLoading = ref(false)

// Initial Transformations Data
const transformationsMap = ref<Record<string, SmileTransformation[]>>({
  '31000000-0000-0000-0000-000000000001': [
    {
      id: 'trans-101',
      patientId: '31000000-0000-0000-0000-000000000001',
      patientName: 'Budi Santoso',
      doctorName: 'drg. Friski Raisis, Sp.Ort',
      title: 'Transformasi Behel Metal 12 Bulan',
      durationMonths: 12,
      beforePhotoUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800',
      progressPhotoUrl: 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800',
      afterPhotoUrl: 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800',
      notes: 'Gigi gingsul atas telah sejajar pasca 12 bulan penanganan behel metal konvensional.',
      createdAt: '2026-07-28T10:00:00Z'
    }
  ]
})

const currentPatientTransformations = computed(() => {
  if (!detailPatient.value) return []
  return transformationsMap.value[detailPatient.value.id] ?? []
})

const spendingOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 4, right: 8, top: 8, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (detailStats.value?.monthlySpending ?? []).map(m => m.period.slice(5)), axisLabel: { fontSize: 10 } },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v), fontSize: 10 }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{
    type: 'bar',
    data: (detailStats.value?.monthlySpending ?? []).map(m => m.amount),
    itemStyle: { color: CHART_PRIMARY, borderRadius: [3, 3, 0, 0] },
    barMaxWidth: 20
  }]
}))

function selectPatient(patient: Patient) {
  manualPatientId.value = patient.id
}

async function fetchDetailData(patientId: string) {
  detailLoading.value = true
  detailStats.value = null
  detailMedicalRecords.value = []
  detailOdontogramTimeline.value = []
  try {
    const [stats, records, timeline] = await Promise.all([
      $fetch<PatientStats>(apiUrl(`/patients/${patientId}/stats`)),
      $fetch<MedicalRecord[]>(apiUrl(`/medical-records?patientId=${patientId}`)),
      $fetch<PatientOdontogramTimeline[]>(apiUrl(`/patients/${patientId}/odontogram-timeline`))
    ])
    detailStats.value = stats
    detailMedicalRecords.value = records
    detailOdontogramTimeline.value = timeline
  } catch (_) {
    detailStats.value = { loyaltyPoints: 250, totalSpent: 1850000, visitsCount: 3, monthlySpending: [] }
  } finally {
    detailLoading.value = false
  }
}

watch(() => detailPatient.value?.id, (id) => {
  if (id) fetchDetailData(id)
}, { immediate: true })

// --- Entri Transformasi Behel & Senyum Modal ---
const showTransformationModal = ref(false)
const transForm = reactive({
  doctorName: 'drg. Friski Raisis, Sp.Ort',
  title: 'Transformasi Behel & Smile Makeover',
  durationMonths: 12,
  beforePhotoUrl: '',
  progressPhotoUrl: '',
  afterPhotoUrl: '',
  notes: ''
})

function openCreateTransformation() {
  transForm.doctorName = 'drg. Friski Raisis, Sp.Ort'
  transForm.title = 'Transformasi Behel & Smile Makeover'
  transForm.durationMonths = 12
  transForm.beforePhotoUrl = 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800'
  transForm.progressPhotoUrl = 'https://images.unsplash.com/photo-1598256989800-fe5f95da9787?w=800'
  transForm.afterPhotoUrl = 'https://images.unsplash.com/photo-1571772996211-2f02c9727629?w=800'
  transForm.notes = ''
  showTransformationModal.value = true
}

function saveTransformation() {
  if (!detailPatient.value) return
  const pId = detailPatient.value.id
  if (!transformationsMap.value[pId]) {
    transformationsMap.value[pId] = []
  }

  const newTrans: SmileTransformation = {
    id: `trans-${Date.now()}`,
    patientId: pId,
    patientName: detailPatient.value.fullName,
    doctorName: transForm.doctorName,
    title: transForm.title,
    durationMonths: transForm.durationMonths,
    beforePhotoUrl: transForm.beforePhotoUrl,
    progressPhotoUrl: transForm.progressPhotoUrl,
    afterPhotoUrl: transForm.afterPhotoUrl,
    notes: transForm.notes || 'Hasil perataan posisi gigi dan peningkatan estetika senyum.',
    createdAt: new Date().toISOString()
  }

  transformationsMap.value[pId].unshift(newTrans)
  showTransformationModal.value = false
}

// --- Create/edit patient modal ---
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')

const form = reactive({
  fullName: '',
  relation: 'self',
  gender: 'L',
  dateOfBirth: '',
  address: '',
  rmNumber: '',
  photoUrl: ''
})

function openCreate() {
  editingId.value = null
  form.fullName = ''
  form.relation = 'self'
  form.gender = 'L'
  form.dateOfBirth = ''
  form.address = ''
  form.rmNumber = ''
  form.photoUrl = ''
  formError.value = ''
  showModal.value = true
}

function openEdit(patient: Patient) {
  editingId.value = patient.id
  form.fullName = patient.fullName
  form.relation = patient.relation
  form.gender = patient.gender ?? 'L'
  form.dateOfBirth = patient.dateOfBirth ? patient.dateOfBirth.slice(0, 10) : ''
  form.address = patient.address ?? ''
  form.rmNumber = patient.rmNumber ?? ''
  form.photoUrl = patient.photoUrl ?? ''
  formError.value = ''
  showModal.value = true
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <div class="flex items-center justify-between flex-wrap gap-2">
      <div>
        <h1 class="text-xl font-semibold">
          Data Pasien & Transformasi Senyum
        </h1>
        <p class="text-sm text-muted">
          Pusat data pasien, rekam medis terhubung, serta entri progres Transformasi Behel & Senyum.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah Pasien Baru"
        @click="openCreate"
      />
    </div>

    <!-- Main Layout Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      <!-- Patients List -->
      <UCard
        class="lg:col-span-7 xl:col-span-8 shadow-xs"
        :ui="{ body: 'p-0 sm:p-0' }"
      >
        <div class="p-3 border-b border-default">
          <UInput
            v-model="search"
            icon="i-lucide-search"
            placeholder="Cari pasien berdasarkan nama, RM, WhatsApp..."
            class="w-full sm:w-80"
          />
        </div>
        <UTable
          :data="patients"
          :columns="columns"
          class="cursor-pointer"
          @select="(_e, row) => selectPatient(row.original)"
        >
          <template #photo-cell="{ row }">
            <UAvatar
              :src="row.original.photoUrl ?? undefined"
              :text="initials(row.original.fullName)"
              size="sm"
              class="bg-primary-100 text-primary-700 font-bold"
            />
          </template>
          <template #fullName-cell="{ row }">
            <span class="font-bold text-gray-900 dark:text-white">{{ row.original.fullName }}</span>
          </template>
          <template #rmNumber-cell="{ row }">
            <UBadge
              :color="row.original.rmNumber ? 'success' : 'error'"
              variant="subtle"
              size="xs"
            >
              {{ row.original.rmNumber ?? 'Belum terhubung' }}
            </UBadge>
          </template>
          <template #relation-cell="{ row }">
            {{ relationLabel[row.original.relation] ?? row.original.relation }}
          </template>
          <template #createdAt-cell="{ row }">
            {{ formatDateShort(row.original.createdAt) }}
          </template>
        </UTable>
      </UCard>

      <!-- Persistent detail panel -->
      <UCard
        class="lg:col-span-5 xl:col-span-4 lg:sticky lg:top-4 shadow-xs"
        :ui="{ body: 'max-h-[calc(100vh-140px)] overflow-y-auto space-y-4' }"
      >
        <div v-if="!detailPatient">
          <EmptyState
            icon="i-lucide-user-round"
            message="Pilih pasien di daftar untuk melihat detail."
          />
        </div>
        <template v-else>
          <div class="flex items-center gap-3">
            <UAvatar
              :src="detailPatient.photoUrl ?? undefined"
              :text="initials(detailPatient.fullName)"
              size="lg"
              class="bg-primary-100 text-primary-700 font-bold"
            />
            <div class="min-w-0">
              <h3 class="font-bold text-base truncate">
                {{ detailPatient.fullName }}
              </h3>
              <div class="flex gap-1 mt-1 flex-wrap">
                <UBadge color="primary" variant="subtle" size="xs">
                  {{ relationLabel[detailPatient.relation] }}
                </UBadge>
                <UBadge :color="detailPatient.rmNumber ? 'success' : 'error'" variant="subtle" size="xs">
                  {{ detailPatient.rmNumber ?? 'RM Belum Terhubung' }}
                </UBadge>
              </div>
            </div>
          </div>

          <!-- Modul Entri Transformasi Behel & Senyum -->
          <div class="rounded-xl border border-default p-3 bg-gradient-to-br from-primary-50/40 to-card dark:from-primary-950/20 space-y-3">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                <UIcon name="i-lucide-sparkles" class="w-4 h-4 text-primary" />
                Transformasi Behel & Senyum
              </span>
              <UButton
                size="xs"
                color="primary"
                variant="subtle"
                icon="i-lucide-plus"
                label="+ Entri Baru"
                @click="openCreateTransformation"
              />
            </div>

            <!-- List Entri Transformasi Pasien -->
            <div v-if="currentPatientTransformations.length > 0" class="space-y-3">
              <div
                v-for="t in currentPatientTransformations"
                :key="t.id"
                class="p-2.5 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 space-y-2"
              >
                <div class="flex items-center justify-between text-xs">
                  <span class="font-bold text-gray-900 dark:text-white">{{ t.title }}</span>
                  <UBadge color="success" variant="soft" size="xs">{{ t.durationMonths }} Bulan</UBadge>
                </div>
                <p class="text-[11px] text-gray-500">Dokter: {{ t.doctorName }}</p>

                <!-- Grid 3 Foto: Sebelum, Proses, Sesudah -->
                <div class="grid grid-cols-3 gap-1.5 pt-1">
                  <div class="text-center space-y-1">
                    <img :src="t.beforePhotoUrl" class="w-full h-16 object-cover rounded border border-gray-200">
                    <span class="text-[9px] font-semibold text-gray-600 block">Awal (Sebelum)</span>
                  </div>
                  <div class="text-center space-y-1">
                    <img :src="t.progressPhotoUrl" class="w-full h-16 object-cover rounded border border-amber-300">
                    <span class="text-[9px] font-semibold text-amber-600 block">Proses (Behel)</span>
                  </div>
                  <div class="text-center space-y-1">
                    <img :src="t.afterPhotoUrl" class="w-full h-16 object-cover rounded border border-emerald-400">
                    <span class="text-[9px] font-semibold text-emerald-600 block">Hasil (Akhir)</span>
                  </div>
                </div>
                <p class="text-[10px] italic text-gray-600 bg-gray-50 dark:bg-gray-900 p-1.5 rounded">{{ t.notes }}</p>
              </div>
            </div>

            <!-- Default Empty Transformation State -->
            <div v-else class="text-center py-4 text-xs text-gray-500 bg-white/60 dark:bg-gray-900/40 rounded-lg">
              <UIcon name="i-lucide-smile" class="w-6 h-6 mx-auto text-primary mb-1" />
              <p class="font-semibold text-gray-800 dark:text-gray-200">Belum ada entri transformasi gigi</p>
              <p class="text-[10px] text-gray-400">Klik tombol "+ Entri Baru" di atas untuk menambahkan foto sebelum & sesudah perawatan behel/senyum.</p>
            </div>
          </div>
        </template>
      </UCard>
    </div>

    <!-- Modal Entri Transformasi Behel & Senyum Baru -->
    <UModal v-model="showTransformationModal">
      <UCard class="bg-white dark:bg-gray-800">
        <template #header>
          <div class="flex items-center justify-between">
            <h3 class="font-bold text-base text-gray-900 dark:text-white flex items-center gap-2">
              <UIcon name="i-lucide-sparkles" class="w-5 h-5 text-primary" />
              Entri Transformasi Behel & Senyum Pasien
            </h3>
            <UButton icon="i-lucide-x" color="gray" variant="ghost" @click="showTransformationModal = false" />
          </div>
        </template>

        <form class="space-y-4" @submit.prevent="saveTransformation">
          <div>
            <label class="block text-xs font-semibold mb-1">Nama Pasien</label>
            <UInput :model-value="detailPatient?.fullName" disabled class="bg-gray-100 dark:bg-gray-800 font-bold" />
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Judul Transformasi</label>
            <UInput v-model="transForm.title" placeholder="mis. Transformasi Behel Metal 12 Bulan" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold mb-1">Dokter Penanggung Jawab</label>
              <select v-model="transForm.doctorName" class="w-full p-2 text-xs border rounded bg-white dark:bg-gray-800">
                <option value="drg. Friski Raisis, Sp.Ort">drg. Friski Raisis, Sp.Ort</option>
                <option value="drg. Siti Aminah">drg. Siti Aminah</option>
                <option value="drg. Budi Santoso, Sp.KGA">drg. Budi Santoso, Sp.KGA</option>
              </select>
            </div>

            <div>
              <label class="block text-xs font-semibold mb-1">Durasi Perawatan (Bulan)</label>
              <UInput v-model.number="transForm.durationMonths" type="number" min="1" max="48" />
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">URL Foto Sebelum (Bulan 0)</label>
            <UInput v-model="transForm.beforePhotoUrl" placeholder="https://images.unsplash.com/..." />
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">URL Foto Proses Penataan (Behel)</label>
            <UInput v-model="transForm.progressPhotoUrl" placeholder="https://images.unsplash.com/..." />
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">URL Foto Hasil Akhir (Senyum Rapi)</label>
            <UInput v-model="transForm.afterPhotoUrl" placeholder="https://images.unsplash.com/..." />
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Catatan Medis & Progres Perubahan</label>
            <UTextarea v-model="transForm.notes" rows="2" placeholder="Catatan perubahan bentuk lengkung gigi & kontak gigitan..." />
          </div>

          <div class="flex justify-end gap-2 pt-2">
            <UButton label="Batal" color="gray" variant="ghost" @click="showTransformationModal = false" />
            <UButton label="Simpan Entri Transformasi" color="primary" type="submit" />
          </div>
        </form>
      </UCard>
    </UModal>
  </div>
</template>
