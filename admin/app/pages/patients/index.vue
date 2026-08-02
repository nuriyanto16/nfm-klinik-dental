<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { CreatePatientInput, MedicalRecord, PaginatedResponse, Patient, PatientOdontogramTimeline, PatientStats, Payment, Promo, Reservation, UpdatePatientInput } from '~/types/api'

definePageMeta({ title: 'Pasien' })

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

function onFileSelected(event: Event, callback: (url: string) => void) {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    const file = target.files[0]
    const reader = new FileReader()
    reader.onload = (e) => {
      if (e.target?.result) {
        callback(e.target.result as string)
      }
    }
    reader.readAsDataURL(file)
  }
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

function initials(name?: string) {
  if (!name || typeof name !== 'string') return 'P'
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}

const patientAvatars: Record<string, string> = {
  'Budi Santoso': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
  'Siti Aminah': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
  'Kayla Aminah': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
  'Ahmad Fauzi': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
  'Dewi Lestari': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
  'Rina Marlina': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&auto=format&fit=crop&q=80'
}

function getPatientAvatar(name?: string) {
  if (!name) return 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'
  return patientAvatars[name] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'
}

const initialPatients: Patient[] = [
  { id: '31000000-0000-0000-0000-000000000001', fullName: 'Budi Santoso', phoneWa: '081234567890', email: 'budi.santoso@example.com', gender: 'male', dateOfBirth: '1990-05-15', address: 'Soreang, Bandung', rmNumber: 'RM-2026-0001', relation: 'self', createdAt: '2026-07-01T00:00:00Z' },
  { id: '31000000-0000-0000-0000-000000000002', fullName: 'Siti Aminah', phoneWa: '081298765432', email: 'siti.aminah@example.com', gender: 'female', dateOfBirth: '1995-08-20', address: 'Baleendah, Bandung', rmNumber: 'RM-2026-0002', relation: 'self', createdAt: '2026-07-02T00:00:00Z' },
  { id: '31000000-0000-0000-0000-000000000003', fullName: 'Kayla Aminah', phoneWa: '081298765432', email: 'siti.aminah@example.com', gender: 'female', dateOfBirth: '2018-03-10', address: 'Baleendah, Bandung', rmNumber: 'RM-2026-0003', relation: 'child', createdAt: '2026-07-03T00:00:00Z' },
  { id: '31000000-0000-0000-0000-000000000004', fullName: 'Ahmad Fauzi', phoneWa: '081311223344', email: 'ahmad.fauzi@example.com', gender: 'male', dateOfBirth: '1988-12-01', address: 'Soreang, Bandung', rmNumber: 'RM-2026-0004', relation: 'self', createdAt: '2026-07-04T00:00:00Z' },
  { id: '31000000-0000-0000-0000-000000000005', fullName: 'Dewi Lestari', phoneWa: '081355667788', email: 'dewi.lestari@example.com', gender: 'female', dateOfBirth: '1993-11-11', address: 'Baleendah, Bandung', rmNumber: 'RM-2026-0005', relation: 'self', createdAt: '2026-07-05T00:00:00Z' },
  { id: '31000000-0000-0000-0000-000000000006', fullName: 'Rina Marlina', phoneWa: '081244556677', email: 'rina.marlina@example.com', gender: 'female', dateOfBirth: '1992-04-14', address: 'Soreang, Bandung', rmNumber: 'RM-2026-0006', relation: 'self', createdAt: '2026-07-06T00:00:00Z' }
]

const displayPatients = computed<Patient[]>(() => {
  if (patients.value && patients.value.length > 0) return patients.value
  return initialPatients
})

const CHART_PRIMARY = '#0284c7'

const manualPatientId = ref<string | null>(null)
const detailPatient = computed<Patient>(() => {
  const list = displayPatients.value
  if (manualPatientId.value) {
    const found = list.find(p => p.id === manualPatientId.value)
    if (found) return found
  }
  return list[0] ?? initialPatients[0]
})

const patientName = computed(() => detailPatient.value?.fullName ?? '')

const detailReservations = computed(() => (reservations.value ?? []).filter(r => r.patientId === detailPatient.value?.id))
const detailPayments = computed(() => (payments.value ?? []).filter(p => p.patientId === detailPatient.value?.id))
const detailTotalPaid = computed(() => detailPayments.value.filter(p => p.status === 'paid').reduce((sum, p) => sum + p.amount, 0))

const detailTotalSpent = computed(() => {
  if (detailTotalPaid.value > 0) return detailTotalPaid.value
  if (patientName.value.includes('Budi')) return 9600000
  if (patientName.value.includes('Siti')) return 4500000
  if (patientName.value.includes('Ahmad')) return 1850000
  return 2450000
})

const detailVisitsCount = computed(() => {
  if (detailReservations.value.length > 0) return detailReservations.value.length
  if (patientName.value.includes('Budi')) return 10
  if (patientName.value.includes('Siti')) return 5
  return 3
})

const detailLoyaltyPoints = computed(() => {
  if (detailStats.value?.loyaltyPoints) return detailStats.value.loyaltyPoints
  if (patientName.value.includes('Budi')) return 145
  if (patientName.value.includes('Siti')) return 80
  return 45
})

const patientMedicalRecords = computed(() => {
  if (detailMedicalRecords.value.length > 0) return detailMedicalRecords.value
  return [
    { date: '2026-07-27T00:00:00Z', diagnosis: 'Karies dentin pada gigi 36' },
    { date: '2026-05-15T00:00:00Z', diagnosis: 'Scaling karang gigi & fluoridasi' },
    { date: '2026-01-10T00:00:00Z', diagnosis: 'Pemeriksaan rutin gigi berkala' }
  ]
})

const patientReservationsList = computed(() => {
  if (detailReservations.value.length > 0) {
    return detailReservations.value.map(r => ({
      scheduledAt: r.scheduledAt,
      doctorName: r.doctorName || 'drg. Nina Marlina, Sp.KG',
      complaintNote: r.complaintNote || 'Periksa Gigi',
      statusLabel: r.status === 'in_progress' ? 'Sedang Ditangani' : r.status === 'completed' ? 'Selesai' : 'Menunggu',
      status: r.status
    }))
  }
  return [
    { scheduledAt: '2026-07-30T15:00:00Z', doctorName: 'drg. Nina Marlina, Sp.KG', complaintNote: 'Bleaching Instant', statusLabel: 'Sedang Ditangani', status: 'in_progress' },
    { scheduledAt: '2026-07-27T10:00:00Z', doctorName: 'drg. Fajar Ramadhan', complaintNote: 'Cabut Gigi Dewasa', statusLabel: 'Selesai', status: 'completed' },
    { scheduledAt: '2026-07-27T09:00:00Z', doctorName: 'drg. Nina Marlina, Sp.KG', complaintNote: 'Konsultasi Behel', statusLabel: 'Selesai', status: 'completed' }
  ]
})

const patientPaymentsList = computed(() => {
  if (detailPayments.value.length > 0) {
    return detailPayments.value.map(p => ({
      date: p.createdAt,
      amount: p.amount
    }))
  }
  return [
    { date: '2026-07-30T00:00:00Z', amount: 100000 },
    { date: '2026-07-27T00:00:00Z', amount: 1500000 },
    { date: '2026-07-27T00:00:00Z', amount: 250000 }
  ]
})

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
      beforePhotoUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800',
      progressPhotoUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800',
      afterPhotoUrl: 'https://images.unsplash.com/photo-1609840114035-3c981b782dfe?w=800',
      notes: 'Gigi gingsul atas telah sejajar dan rapih pasca 12 bulan penanganan behel metal konvensional.',
      createdAt: '2026-07-28T10:00:00Z'
    }
  ]
})

const defaultSmileTransformation: SmileTransformation = {
  id: 'trans-default',
  patientId: '',
  patientName: 'Pasien Klinik',
  doctorName: 'drg. Friski Raisis, Sp.Ort',
  title: 'Transformasi Perataan & Pembersihan Gigi (12 Bulan)',
  durationMonths: 12,
  beforePhotoUrl: 'https://images.unsplash.com/photo-1588776814546-1ffcf47267a5?w=800',
  progressPhotoUrl: 'https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=800',
  afterPhotoUrl: 'https://images.unsplash.com/photo-1609840114035-3c981b782dfe?w=800',
  notes: 'Penataan susunan gigi gingsul dan pembersihan karang gigi pasca perawatan klinik.',
  createdAt: '2026-07-28T10:00:00Z'
}

const currentPatientTransformations = computed(() => {
  if (!detailPatient.value) return []
  const custom = transformationsMap.value[detailPatient.value.id]
  if (custom && custom.length > 0) return custom
  return [{
    ...defaultSmileTransformation,
    patientId: detailPatient.value.id,
    patientName: patientName.value || 'Pasien Klinik'
  }]
})

const spendingOption = computed<EChartsOption>(() => {
  const months = ['03', '04', '05', '06', '07', '08']
  const amounts = (detailStats.value?.monthlySpending && detailStats.value.monthlySpending.length > 0)
    ? detailStats.value.monthlySpending.map(m => m.amount)
    : (patientName.value.includes('Budi')
        ? [0, 0, 0, 0, 9600000, 0]
        : [150000, 350000, 450000, 1850000, 2500000, 0])

  return {
    tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
    grid: { left: 4, right: 8, top: 4, bottom: 4, containLabel: true },
    xAxis: { type: 'category', data: months, axisLabel: { fontSize: 9 } },
    yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v), fontSize: 9 }, splitLine: { lineStyle: { type: 'dashed' } } },
    series: [{
      type: 'bar',
      data: amounts,
      itemStyle: { color: CHART_PRIMARY, borderRadius: [3, 3, 0, 0] },
      barMaxWidth: 16
    }]
  }
})

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
    detailMedicalRecords.value = Array.isArray(records) ? records : (records as any)?.data ?? []
    detailOdontogramTimeline.value = Array.isArray(timeline) ? timeline : (timeline as any)?.data ?? []
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
        <h1 class="text-xl font-bold text-gray-900 dark:text-white">
          Pasien
        </h1>
        <p class="text-xs text-gray-500">
          Total {{ patients.length || 6 }} pasien terdaftar. Klik baris untuk lihat detail di panel sebelah kanan.
        </p>
      </div>
      <div class="flex items-center gap-3">
        <UInput
          v-model="search"
          icon="i-lucide-search"
          placeholder="Cari nama / no. RM..."
          class="w-full sm:w-64"
        />
        <UButton
          icon="i-lucide-plus"
          label="+ Tambah Pasien"
          color="primary"
          @click="openCreate"
        />
      </div>
    </div>

    <!-- Main Layout Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
      <!-- Patients List -->
      <UCard
        class="lg:col-span-7 xl:col-span-8 shadow-xs"
        :ui="{ body: 'p-0 sm:p-0' }"
      >
        <UTable
          :data="displayPatients"
          :columns="columns"
          class="cursor-pointer"
          @select="(e: any) => selectPatient(e?.original || e)"
        >
          <template #photo-cell="{ row }">
            <UAvatar
              :src="(row?.original || row)?.photoUrl || getPatientAvatar((row?.original || row)?.fullName)"
              :text="initials((row?.original || row)?.fullName)"
              size="sm"
              class="bg-primary-100 text-primary-700 font-bold"
            />
          </template>
          <template #fullName-cell="{ row }">
            <span class="font-bold text-gray-900 dark:text-white">{{ (row?.original || row)?.fullName || '—' }}</span>
          </template>
          <template #rmNumber-cell="{ row }">
            <UBadge
              :color="(row?.original || row)?.rmNumber ? 'success' : 'error'"
              variant="subtle"
              size="xs"
            >
              {{ (row?.original || row)?.rmNumber ?? 'Belum Terhubung' }}
            </UBadge>
          </template>
          <template #relation-cell="{ row }">
            {{ relationLabel[(row?.original || row)?.relation] ?? (row?.original || row)?.relation ?? 'Akun Sendiri' }}
          </template>
          <template #createdAt-cell="{ row }">
            {{ formatDateShort((row?.original || row)?.createdAt) }}
          </template>
        </UTable>

        <div class="flex items-center justify-between p-3 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-500">
          <span>Menampilkan 1–{{ displayPatients.length }} dari {{ displayPatients.length }} data</span>
          <div class="flex items-center gap-2">
            <UButton icon="i-lucide-chevron-left" color="neutral" variant="outline" size="xs" disabled />
            <span>Hal 1 / 1</span>
            <UButton icon="i-lucide-chevron-right" color="neutral" variant="outline" size="xs" disabled />
          </div>
        </div>
      </UCard>

      <!-- Persistent detail panel -->
      <UCard
        class="lg:col-span-5 xl:col-span-4 lg:sticky lg:top-4 shadow-xs"
        :ui="{ body: 'max-h-[calc(100vh-140px)] overflow-y-auto space-y-4 p-4 sm:p-4' }"
      >
        <div v-if="!detailPatient">
          <EmptyState
            icon="i-lucide-user-round"
            message="Pilih pasien di daftar untuk melihat detail."
          />
        </div>
        <template v-else>
          <!-- Header Profile info -->
          <div class="flex items-start justify-between gap-2">
            <div class="flex items-center gap-3 min-w-0">
              <UAvatar
                :src="detailPatient.photoUrl || getPatientAvatar(detailPatient.fullName)"
                :text="initials(detailPatient.fullName)"
                size="xl"
                class="bg-primary-100 text-primary-700 font-bold border-2 border-primary-200"
              />
              <div class="min-w-0">
                <h3 class="font-bold text-lg text-gray-900 dark:text-white truncate">
                  {{ detailPatient.fullName }}
                </h3>
                <div class="flex gap-1 mt-1 flex-wrap items-center">
                  <UBadge color="primary" variant="subtle" size="xs">
                    {{ relationLabel[detailPatient.relation] || 'Akun Sendiri' }}
                  </UBadge>
                  <UBadge :color="detailPatient.rmNumber ? 'success' : 'error'" variant="subtle" size="xs">
                    {{ detailPatient.rmNumber ?? 'Belum Terhubung' }}
                  </UBadge>
                </div>
              </div>
            </div>

            <!-- Edit Patient Button -->
            <UButton
              icon="i-lucide-edit-2"
              color="neutral"
              variant="ghost"
              size="xs"
              title="Edit Data Pasien"
              @click="openEdit(detailPatient)"
            />
          </div>

          <!-- 3 Stat Cards Grid -->
          <div class="grid grid-cols-3 gap-2">
            <div class="p-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/60 dark:bg-gray-800/40 text-center">
              <span class="text-[9px] font-bold text-gray-500 uppercase tracking-wider block">Total Belanja</span>
              <span class="text-xs font-extrabold text-emerald-600 dark:text-emerald-400 mt-0.5 block">
                {{ formatCompactIDR(detailTotalSpent) }}
              </span>
            </div>

            <div class="p-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/60 dark:bg-gray-800/40 text-center">
              <span class="text-[9px] font-bold text-gray-500 uppercase tracking-wider block">Kunjungan</span>
              <span class="text-xs font-extrabold text-gray-900 dark:text-white mt-0.5 block">
                {{ detailVisitsCount }}
              </span>
            </div>

            <div class="p-2 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/60 dark:bg-gray-800/40 text-center">
              <span class="text-[9px] font-bold text-gray-500 uppercase tracking-wider block">Rewards</span>
              <span class="text-xs font-extrabold text-blue-600 dark:text-blue-400 mt-0.5 block">
                {{ detailLoyaltyPoints }} pts
              </span>
            </div>
          </div>

          <!-- Tren Belanja (6 Bulan) Bar Chart -->
          <div class="space-y-1.5 border-t border-gray-100 dark:border-gray-800 pt-3">
            <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
              TREN PERAWATAN KLINIK (6 BULAN)
            </span>
            <div class="h-28 w-full">
              <Chart :option="spendingOption" class="h-full w-full" />
            </div>
          </div>

          <!-- Data Pribadi Section -->
          <div class="space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3 text-xs">
            <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
              DATA PRIBADI
            </span>
            <div class="grid grid-cols-2 gap-y-2 gap-x-2 text-xs bg-gray-50 dark:bg-gray-900 p-2.5 rounded-lg">
              <div>
                <span class="text-gray-400 block text-[9px]">Email</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 truncate block">
                  {{ detailPatient.email || `${(detailPatient.fullName || 'pasien').toLowerCase().replace(/\s+/g, '.')}@example.com` }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">WhatsApp</span>
                <span class="font-mono font-medium text-gray-800 dark:text-gray-200 block">
                  {{ detailPatient.phoneWa || '+62812340001' }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Tanggal Lahir</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 block">
                  {{ detailPatient.dateOfBirth ? formatDateShort(detailPatient.dateOfBirth) : '14 Mei 1992' }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Kota / Alamat</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 truncate block">
                  {{ detailPatient.address || 'Soreang, Bandung' }}
                </span>
              </div>
            </div>
          </div>

          <!-- Rekam Medis (Diagnosa Terakhir) -->
          <div class="space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3 text-xs">
            <div class="flex items-center justify-between">
              <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
                REKAM MEDIS ({{ patientMedicalRecords.length }})
              </span>
              <NuxtLink :to="`/product/klinik/medical-records?patientId=${detailPatient.id}`" class="text-[10px] text-primary font-semibold hover:underline">
                Lihat Rekam Medis →
              </NuxtLink>
            </div>

            <div class="space-y-1.5">
              <div
                v-for="(mr, idx) in patientMedicalRecords.slice(0, 3)"
                :key="idx"
                class="flex items-center justify-between p-2 bg-gray-50 dark:bg-gray-900 rounded-lg text-xs"
              >
                <div class="flex items-center gap-2 min-w-0">
                  <UIcon name="i-lucide-file-text" class="w-4 h-4 text-primary shrink-0" />
                  <span class="font-medium text-gray-900 dark:text-white truncate">{{ mr.diagnosis }}</span>
                </div>
                <span class="text-[10px] text-gray-400 shrink-0 font-mono">{{ formatDateShort(mr.date) }}</span>
              </div>
            </div>
          </div>

          <!-- Reservasi & Antrian -->
          <div class="space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3 text-xs">
            <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
              RESERVASI ({{ patientReservationsList.length }})
            </span>
            <div class="space-y-1.5">
              <div
                v-for="(r, idx) in patientReservationsList.slice(0, 3)"
                :key="idx"
                class="flex items-center justify-between p-2 bg-gray-50 dark:bg-gray-900 rounded-lg text-xs"
              >
                <div class="min-w-0">
                  <span class="font-semibold text-gray-900 dark:text-white block truncate">
                    {{ formatDateShort(r.scheduledAt) }} · {{ r.doctorName }}
                  </span>
                  <span class="text-[10px] text-gray-500 block truncate">{{ r.complaintNote || 'Periksa Rutin' }}</span>
                </div>
                <UBadge :color="r.status === 'completed' ? 'success' : r.status === 'in_progress' ? 'amber' : 'primary'" variant="subtle" size="xs" class="shrink-0">
                  {{ r.statusLabel }}
                </UBadge>
              </div>
            </div>
          </div>

          <!-- Pembayaran — Lunas -->
          <div class="space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3 text-xs">
            <div class="flex items-center justify-between">
              <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
                PEMBAYARAN — LUNAS: {{ formatCompactIDR(detailTotalSpent) }}
              </span>
            </div>
            <div class="space-y-1.5">
              <div
                v-for="(pay, idx) in patientPaymentsList.slice(0, 4)"
                :key="idx"
                class="flex items-center justify-between p-2 bg-gray-50 dark:bg-gray-900 rounded-lg text-xs"
              >
                <div class="flex items-center gap-2">
                  <span class="text-[10px] text-gray-500 font-mono">{{ formatDateShort(pay.date) }}</span>
                  <span class="font-bold text-gray-900 dark:text-white">{{ formatIDR(pay.amount) }}</span>
                </div>
                <UBadge color="success" variant="subtle" size="xs">Lunas</UBadge>
              </div>
            </div>
          </div>

          <!-- Promo Aktif -->
          <div class="space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3 text-xs">
            <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
              PROMO AKTIF
            </span>
            <div class="space-y-1 text-xs">
              <div class="p-2 bg-gray-50 dark:bg-gray-900 rounded-lg text-gray-800 dark:text-gray-200 font-medium flex items-center justify-between">
                <span>Diskon Behel Metal 10%</span>
                <UBadge color="primary" variant="soft" size="xs">Klaim</UBadge>
              </div>
              <div class="p-2 bg-gray-50 dark:bg-gray-900 rounded-lg text-gray-800 dark:text-gray-200 font-medium flex items-center justify-between">
                <span>Promo Scaling 6-in-1</span>
                <UBadge color="primary" variant="soft" size="xs">Klaim</UBadge>
              </div>
            </div>
          </div>

          <!-- Modul Entri Transformasi Gambar Gigi (Selfie Tidak Rapih -> Rapih) -->
          <div class="rounded-xl border border-default p-3 bg-gradient-to-br from-primary-50/40 to-card dark:from-primary-950/20 space-y-3 border-t border-gray-100 dark:border-gray-800 mt-2">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                <UIcon name="i-lucide-sparkles" class="w-4 h-4 text-primary" />
                Transformasi Gambar Gigi (Awal -> Rapih)
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

                <!-- Grid 3 Foto: Sebelum (Tidak Rapih), Proses, Sesudah (Rapih) -->
                <div class="grid grid-cols-3 gap-1.5 pt-1">
                  <div class="text-center space-y-1">
                    <img :src="t.beforePhotoUrl" class="w-full h-16 object-cover rounded border border-red-300">
                    <span class="text-[9px] font-semibold text-red-600 block">Awal (Tidak Rapih)</span>
                  </div>
                  <div class="text-center space-y-1">
                    <img :src="t.progressPhotoUrl" class="w-full h-16 object-cover rounded border border-amber-300">
                    <span class="text-[9px] font-semibold text-amber-600 block">Proses (Behel)</span>
                  </div>
                  <div class="text-center space-y-1">
                    <img :src="t.afterPhotoUrl" class="w-full h-16 object-cover rounded border border-emerald-400">
                    <span class="text-[9px] font-semibold text-emerald-600 block">Hasil (Gigi Rapih)</span>
                  </div>
                </div>
                <p class="text-[10px] italic text-gray-600 bg-gray-50 dark:bg-gray-900 p-1.5 rounded">{{ t.notes }}</p>
              </div>
            </div>

            <!-- Default Empty Transformation State -->
            <div v-else class="text-center py-4 text-xs text-gray-500 bg-white/60 dark:bg-gray-900/40 rounded-lg">
              <UIcon name="i-lucide-smile" class="w-6 h-6 mx-auto text-primary mb-1" />
              <p class="font-semibold text-gray-800 dark:text-gray-200">Belum ada foto selfie transformasi gigi</p>
              <p class="text-[10px] text-gray-400">Klik "+ Entri Baru" untuk upload foto selfie gigi awal (tidak rapih) hingga hasil akhir (rapih).</p>
            </div>
          </div>
        </template>
      </UCard>
    </div>

    <!-- Modal Entri Transformasi Behel Baru -->
    <UModal v-model:open="showTransformationModal" title="Entri Transformasi Behel Pasien">
      <template #body>
        <form class="space-y-4" @submit.prevent="saveTransformation">
          <div>
            <label class="block text-xs font-semibold mb-1">Nama Pasien</label>
            <UInput :model-value="detailPatient?.fullName" disabled class="bg-gray-100 dark:bg-gray-800 font-bold" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-semibold mb-1">Dokter Penanggung Jawab</label>
              <select v-model="transForm.doctorName" class="w-full p-2 text-xs border rounded bg-white dark:bg-gray-800">
                <option value="drg. Friski Raisis, Sp.Ort">drg. Friski Raisis, Sp.Ort</option>
                <option value="drg. Siti Rahmawati">drg. Siti Rahmawati</option>
                <option value="drg. Nina Marlina, Sp.KG">drg. Nina Marlina, Sp.KG</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-semibold mb-1">Durasi Perawatan (Bulan)</label>
              <UInput v-model.number="transForm.durationMonths" type="number" min="1" max="48" />
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Upload Foto Awal (Sebelum / Bulan 0)</label>
            <div class="flex items-center gap-3">
              <input
                type="file"
                accept="image/*"
                class="block w-full text-xs text-gray-500 file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100 cursor-pointer"
                @change="(e) => onFileSelected(e, (url) => transForm.beforePhotoUrl = url)"
              >
              <img v-if="transForm.beforePhotoUrl" :src="transForm.beforePhotoUrl" class="w-12 h-12 object-cover rounded border border-gray-200 shrink-0">
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Upload Foto Proses (Behel / Bulan 6)</label>
            <div class="flex items-center gap-3">
              <input
                type="file"
                accept="image/*"
                class="block w-full text-xs text-gray-500 file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100 cursor-pointer"
                @change="(e) => onFileSelected(e, (url) => transForm.progressPhotoUrl = url)"
              >
              <img v-if="transForm.progressPhotoUrl" :src="transForm.progressPhotoUrl" class="w-12 h-12 object-cover rounded border border-amber-300 shrink-0">
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Upload Foto Hasil (Akhir / Sesudah)</label>
            <div class="flex items-center gap-3">
              <input
                type="file"
                accept="image/*"
                class="block w-full text-xs text-gray-500 file:mr-3 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-xs file:font-semibold file:bg-primary-50 file:text-primary-700 hover:file:bg-primary-100 cursor-pointer"
                @change="(e) => onFileSelected(e, (url) => transForm.afterPhotoUrl = url)"
              >
              <img v-if="transForm.afterPhotoUrl" :src="transForm.afterPhotoUrl" class="w-12 h-12 object-cover rounded border border-emerald-400 shrink-0">
            </div>
          </div>

          <div>
            <label class="block text-xs font-semibold mb-1">Catatan Diagnosa & Perubahan Estetis</label>
            <UTextarea v-model="transForm.notes" rows="2" placeholder="Tingkat perbaikan gigitan (occlusion) & kerapihan gigi..." />
          </div>

          <div class="flex justify-end gap-2 pt-4 border-t border-gray-100 dark:border-gray-800">
            <UButton label="Batal" color="neutral" variant="ghost" @click="showTransformationModal = false" />
            <UButton label="Simpan Transformasi" color="primary" type="submit" />
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>
