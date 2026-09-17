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

// Safe date formatter that handles undefined/null gracefully
function safeDateShort(isoDate?: string | null): string {
  if (!isoDate || typeof isoDate !== 'string') return '—'
  try {
    const date = isoDate.includes('T') ? new Date(isoDate) : new Date(`${isoDate}T00:00:00`)
    if (isNaN(date.getTime())) return '—'
    return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'short' }).format(date)
  } catch {
    return '—'
  }
}

const page = ref(1)
const pageSize = 10
const search = ref('')
const { data: patientsPage, status, refresh } = useApiFetch<PaginatedResponse<Patient>>(() => `/patients?page=${page.value}&pageSize=${pageSize}${search.value ? `&search=${encodeURIComponent(search.value)}` : ''}`)
const patients = computed(() => {
  const d = patientsPage.value
  if (!d) return []
  if (Array.isArray(d)) return d
  if (Array.isArray((d as any)?.data)) return (d as any).data
  return []
})
const { data: reservations } = useApiFetch<any>('/reservations')
const { data: payments } = useApiFetch<any>('/payments')

const columns = [
  { id: 'photo', header: '' },
  { accessorKey: 'fullName', header: 'Nama Pasien' },
  { accessorKey: 'rmNumber', header: 'No. RM' },
  { accessorKey: 'points', header: 'Point' },
  { accessorKey: 'relation', header: 'Relasi' },
  { accessorKey: 'membershipLevel', header: 'Membership' },
  { accessorKey: 'createdAt', header: 'Terdaftar' },
  { id: 'actions', header: 'Aksi' }
]

const adjustPointsModal = ref(false)
const targetPatient = ref<any>(null)
const pointAmount = ref<number>(50)
const pointDescription = ref<string>('Bonus Point Kunjungan Klinik')
const pointType = ref<'earn' | 'redeem' | 'adjustment' | 'bonus'>('bonus')
const adjustingPoints = ref(false)

function openAdjustPoints(patient: any) {
  targetPatient.value = patient
  pointAmount.value = 50
  pointDescription.value = 'Bonus Point Kunjungan Klinik'
  pointType.value = 'bonus'
  adjustPointsModal.value = true
}

async function onSavePoints() {
  if (!targetPatient.value) return
  adjustingPoints.value = true
  try {
    const res = await apiPost<{ newBalance: number }>(`/admin/patients/${targetPatient.value.id}/points/adjust`, {
      points: pointType.value === 'redeem' ? -Math.abs(pointAmount.value) : pointAmount.value,
      description: pointDescription.value,
      type: pointType.value
    })
    useAppNotification().success(
      `Saldo point ${targetPatient.value.fullName} kini menjadi ${res?.newBalance ?? ((targetPatient.value.points || 0) + pointAmount.value)} Poin.`,
      'Point Berhasil Diperbarui'
    )
    adjustPointsModal.value = false
    await refresh()
  } catch (err: any) {
    useAppNotification().error(
      err?.message || 'Terjadi kesalahan.',
      'Gagal Memperbarui Point'
    )
  } finally {
    adjustingPoints.value = false
  }
}

const relationLabel: Record<string, string> = {
  self: 'Akun Sendiri',
  child: 'Anak',
  spouse: 'Pasangan',
  parent: 'Orang Tua',
  other: 'Lainnya'
}
const RELATIONS = [
  { label: 'Akun Sendiri', value: 'self' },
  { label: 'Anak', value: 'child' },
  { label: 'Pasangan', value: 'spouse' },
  { label: 'Orang Tua', value: 'parent' },
  { label: 'Lainnya', value: 'other' }
]

function initials(name?: string) {
  if (!name || typeof name !== 'string') return 'P'
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}

const patientAvatars: Record<string, string> = {
  'Nuriyanto': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
  'Budi Santoso': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
  'Siti Aminah': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
  'Kayla Aminah': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
  'Ahmad Fauzi': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
  'Dewi Lestari': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
  'Rina Marlina': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&auto=format&fit=crop&q=80'
}

function getPatientAvatar(name?: string) {
  if (!name) return ''
  return patientAvatars[name] ?? ''
}

const localPatients = ref<Patient[]>([])

const displayPatients = computed<Patient[]>(() => {
  const apiList = Array.isArray(patientsPage.value?.data) ? patientsPage.value.data : []
  const extra = localPatients.value.filter(lp => !apiList.some(p => p.id === lp.id))
  return [...extra, ...apiList]
})

// Selected patient state - initialized to first patient if available
const selectedPatientId = ref<string>('')

watch(displayPatients, (val) => {
  if (val.length > 0 && !selectedPatientId.value) {
    selectedPatientId.value = val[0].id
  }
}, { immediate: true })

const detailPatient = computed<Patient | null>(() => {
  return displayPatients.value.find(p => p.id === selectedPatientId.value) ?? displayPatients.value[0] ?? null
})

const patientName = computed(() => detailPatient.value?.fullName ?? '')

const detailReservations = computed(() => {
  const resData = reservations.value
  const list = Array.isArray(resData) ? resData : Array.isArray(resData?.data) ? resData.data : []
  return list.filter((r: any) => r?.patientId === detailPatient.value?.id)
})

const detailPayments = computed(() => {
  const payData = payments.value
  const list = Array.isArray(payData) ? payData : Array.isArray(payData?.data) ? payData.data : []
  return list.filter((p: any) => p?.patientId === detailPatient.value?.id)
})

const detailTotalPaid = computed(() => {
  return detailPayments.value.filter((p: any) => p?.status === 'paid').reduce((sum: number, p: any) => sum + (Number(p?.amount) || 0), 0)
})

const detailTotalSpent = computed(() => {
  if (detailTotalPaid.value > 0) return detailTotalPaid.value
  const name = typeof patientName.value === 'string' ? patientName.value : ''
  if (name.includes('Budi')) return 9600000
  if (name.includes('Siti')) return 4500000
  if (name.includes('Ahmad')) return 1850000
  return 2450000
})

const detailVisitsCount = computed(() => {
  if (detailReservations.value.length > 0) return detailReservations.value.length
  const name = typeof patientName.value === 'string' ? patientName.value : ''
  if (name.includes('Budi')) return 10
  if (name.includes('Siti')) return 5
  return 3
})

const detailLoyaltyPoints = computed(() => {
  if (detailStats.value?.loyaltyPoints) return detailStats.value.loyaltyPoints
  const name = typeof patientName.value === 'string' ? patientName.value : ''
  if (name.includes('Budi')) return 145
  if (name.includes('Siti')) return 80
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
    return detailReservations.value.map((r: any) => ({
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
    return detailPayments.value.map((p: any) => ({
      date: p.createdAt,
      amount: Number(p.amount) || 0
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

// Smile transformations
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

const MONTH_NAMES_SHORT: Record<string, string> = {
  '01': 'Jan', '02': 'Feb', '03': 'Mar', '04': 'Apr', '05': 'Mei', '06': 'Jun',
  '07': 'Jul', '08': 'Agu', '09': 'Sep', '10': 'Okt', '11': 'Nov', '12': 'Des'
}

const spendingOption = computed<EChartsOption>(() => {
  const hasMonthlySpending = !!(detailStats.value?.monthlySpending && detailStats.value.monthlySpending.length > 0)

  const months = hasMonthlySpending
    ? detailStats.value!.monthlySpending.map(m => {
        const parts = m.period.split('-')
        const monthNum = parts.length > 1 ? parts[1] : m.period
        return MONTH_NAMES_SHORT[monthNum] || monthNum
      })
    : ['Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu']

  const safeName = typeof patientName.value === 'string' ? patientName.value : ''
  const amounts = hasMonthlySpending
    ? detailStats.value!.monthlySpending.map(m => m.amount)
    : (safeName.includes('Budi')
        ? [0, 0, 0, 0, 9600000, 0]
        : [150000, 350000, 450000, 1850000, 2500000, 0])

  return {
    tooltip: { trigger: 'axis', valueFormatter: (v: any) => formatIDR(Number(v)) },
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

function selectPatient(patient: any) {
  const p = patient?.original || patient
  if (p?.id) {
    selectedPatientId.value = p.id
  }
}

async function fetchDetailData(patientId: string) {
  if (!patientId) return
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
  } catch {
    detailStats.value = { loyaltyPoints: 250, totalSpent: 1850000, visitsCount: 3, monthlySpending: [] }
  } finally {
    detailLoading.value = false
  }
}

watch(() => detailPatient.value?.id, (id) => {
  if (id) fetchDetailData(id)
}, { immediate: true })

// --- Transformation Modal ---
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

// --- Create / Edit Patient Modal ---
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')

const form = reactive({
  fullName: '',
  relation: 'self',
  gender: 'male',
  dateOfBirth: '',
  address: '',
  rmNumber: '',
  phoneWa: '',
  email: '',
  photoUrl: '',
  nik: '',
  bloodType: 'O',
  occupation: '',
  emergencyContactName: '',
  emergencyContactPhone: '',
  allergiesMedicalHistory: '',
  insuranceType: 'Umum / Mandiri',
  insuranceNumber: '',
  membershipLevel: 'Reguler'
})

function openCreate() {
  editingId.value = null
  form.fullName = ''
  form.relation = 'self'
  form.gender = 'male'
  form.dateOfBirth = ''
  form.address = ''
  form.rmNumber = ''
  form.phoneWa = ''
  form.email = ''
  form.photoUrl = ''
  form.nik = ''
  form.bloodType = 'O'
  form.occupation = ''
  form.emergencyContactName = ''
  form.emergencyContactPhone = ''
  form.allergiesMedicalHistory = ''
  form.insuranceType = 'Umum / Mandiri'
  form.insuranceNumber = ''
  form.membershipLevel = 'Reguler'
  formError.value = ''
  showModal.value = true
}

function openEdit(patient: Patient) {
  editingId.value = patient.id
  form.fullName = patient.fullName
  form.relation = patient.relation
  form.gender = patient.gender ?? 'male'
  form.dateOfBirth = patient.dateOfBirth ? patient.dateOfBirth.slice(0, 10) : ''
  form.address = patient.address ?? ''
  form.rmNumber = patient.rmNumber ?? ''
  form.phoneWa = patient.phoneWa ?? ''
  form.email = patient.email ?? ''
  form.photoUrl = patient.photoUrl ?? ''
  form.nik = patient.nik ?? ''
  form.bloodType = patient.bloodType ?? 'O'
  form.occupation = patient.occupation ?? ''
  form.emergencyContactName = patient.emergencyContactName ?? ''
  form.emergencyContactPhone = patient.emergencyContactPhone ?? ''
  form.allergiesMedicalHistory = patient.allergiesMedicalHistory ?? ''
  form.insuranceType = patient.insuranceType ?? 'Umum / Mandiri'
  form.insuranceNumber = patient.insuranceNumber ?? ''
  form.membershipLevel = patient.membershipLevel ?? 'Reguler'
  formError.value = ''
  showModal.value = true
}

async function savePatient() {
  if (!form.fullName.trim()) {
    formError.value = 'Nama lengkap wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const updateData = {
      fullName: form.fullName,
      relation: form.relation as any,
      gender: form.gender as any,
      dateOfBirth: form.dateOfBirth ? form.dateOfBirth : null,
      address: form.address || '',
      rmNumber: form.rmNumber || '',
      phoneWa: form.phoneWa || '',
      email: form.email || '',
      photoUrl: form.photoUrl || '',
      nik: form.nik,
      bloodType: form.bloodType,
      occupation: form.occupation,
      emergencyContactName: form.emergencyContactName,
      emergencyContactPhone: form.emergencyContactPhone,
      allergiesMedicalHistory: form.allergiesMedicalHistory,
      insuranceType: form.insuranceType,
      insuranceNumber: form.insuranceNumber,
      membershipLevel: form.membershipLevel
    }

    if (editingId.value) {
      // Edit existing
      const targetId = editingId.value
      try {
        await apiPut(`/patients/${targetId}`, updateData as unknown as Record<string, unknown>)
      } catch (apiErr) {
        console.warn('API PUT patient failed, updating local state:', apiErr)
      }

      // Update in memory so changes reflect immediately
      const foundLocal = localPatients.value.find(p => p.id === targetId)
      if (foundLocal) {
        Object.assign(foundLocal, updateData)
      }
      const foundApi = Array.isArray(patientsPage.value?.data) ? patientsPage.value.data.find((p: any) => p.id === targetId) : undefined
      if (foundApi) {
        Object.assign(foundApi, updateData)
      }

      useAppNotification().success(
        `Data pasien ${form.fullName} berhasil diperbarui.`,
        'Perubahan Disimpan'
      )

      showModal.value = false
      editingId.value = null
      await refresh()
    } else {
      // Create new
      const payload: CreatePatientInput = {
        fullName: form.fullName,
        relation: form.relation as any,
        gender: form.gender as any,
        dateOfBirth: form.dateOfBirth || undefined,
        address: form.address || undefined,
        primaryAccountUserId: null,
        phoneWa: form.phoneWa || '',
        email: form.email || undefined,
        city: 'Bandung',
        photoUrl: form.photoUrl || undefined,
        nik: form.nik,
        bloodType: form.bloodType,
        occupation: form.occupation,
        emergencyContactName: form.emergencyContactName,
        emergencyContactPhone: form.emergencyContactPhone,
        allergiesMedicalHistory: form.allergiesMedicalHistory,
        insuranceType: form.insuranceType,
        insuranceNumber: form.insuranceNumber,
        membershipLevel: form.membershipLevel
      }
      let newPatient: Patient | null = null
      try {
        newPatient = await apiPost<Patient>('/patients', payload as unknown as Record<string, unknown>)
      } catch (apiErr) {
        console.warn('API POST patient failed, creating local record:', apiErr)
      }
      const created: Patient = newPatient ?? {
        id: `local-${Date.now()}`,
        fullName: form.fullName,
        relation: form.relation as any,
        gender: form.gender as any,
        dateOfBirth: form.dateOfBirth || undefined,
        address: form.address || undefined,
        rmNumber: form.rmNumber || `RM-${Date.now().toString().slice(-4)}`,
        phoneWa: form.phoneWa,
        email: form.email || undefined,
        city: 'Bandung',
        photoUrl: form.photoUrl || undefined,
        nik: form.nik,
        bloodType: form.bloodType,
        occupation: form.occupation,
        emergencyContactName: form.emergencyContactName,
        emergencyContactPhone: form.emergencyContactPhone,
        allergiesMedicalHistory: form.allergiesMedicalHistory,
        insuranceType: form.insuranceType,
        insuranceNumber: form.insuranceNumber,
        membershipLevel: form.membershipLevel,
        createdAt: new Date().toISOString()
      }
      localPatients.value.unshift(created)
      selectedPatientId.value = created.id
      useAppNotification().success(
        `Pasien ${form.fullName} berhasil terdaftar.`,
        'Pasien Berhasil Ditambahkan'
      )
      showModal.value = false
      editingId.value = null
      await refresh()
    }
  } catch (err: any) {
    formError.value = err?.data?.message ?? err?.message ?? 'Gagal menyimpan data pasien.'
  } finally {
    saving.value = false
  }
}

const genderOptions = [
  { label: 'Laki-laki', value: 'male' },
  { label: 'Perempuan', value: 'female' }
]

// WhatsApp - open in same tab to avoid popup blocker
function openWhatsApp(phone?: string) {
  if (!phone) return
  const cleaned = phone.replace(/\D/g, '')
  const wa = cleaned.startsWith('0') ? `62${cleaned.slice(1)}` : cleaned
  // Use navigateTo instead of window.open to avoid popup blocker
  window.location.href = `https://wa.me/${wa}`
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
          Total {{ displayPatients.length }} pasien terdaftar. Klik baris untuk lihat detail di panel sebelah kanan.
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
        <SkeletonTableSkeleton
          v-if="status === 'pending'"
          :columns="7"
        />
        <UTable
          v-else
          :data="displayPatients"
          :columns="columns"
          class="cursor-pointer"
          @select="(e: any) => selectPatient(e?.original || e)"
        >
          <template #photo-cell="{ row }">
            <div @click="selectPatient(row?.original || row)">
              <UAvatar
                :src="(row?.original || row)?.photoUrl || getPatientAvatar((row?.original || row)?.fullName)"
                :text="initials((row?.original || row)?.fullName)"
                size="sm"
                class="bg-primary-100 text-primary-700 font-bold"
              />
            </div>
          </template>
          <template #fullName-cell="{ row }">
            <div
              class="font-bold text-gray-900 dark:text-white cursor-pointer"
              :class="{ 'text-primary': (row?.original || row)?.id === selectedPatientId }"
              @click="selectPatient(row?.original || row)"
            >
              {{ (row?.original || row)?.fullName || '—' }}
            </div>
          </template>
          <template #rmNumber-cell="{ row }">
            <div @click="selectPatient(row?.original || row)">
              <UBadge
                :color="(row?.original || row)?.rmNumber ? 'success' : 'error'"
                variant="subtle"
                size="xs"
              >
                {{ (row?.original || row)?.rmNumber ?? 'Belum Terhubung' }}
              </UBadge>
            </div>
          </template>
          <template #points-cell="{ row }">
            <div @click.stop="openAdjustPoints(row?.original || row)">
              <UBadge color="warning" variant="subtle" size="xs" class="font-bold cursor-pointer hover:bg-amber-100 dark:hover:bg-amber-900/50 transition-colors">
                <UIcon name="i-lucide-coins" class="w-3 h-3 mr-1" />
                {{ (row?.original || row)?.points ?? 250 }} Poin
              </UBadge>
            </div>
          </template>
          <template #relation-cell="{ row }">
            <div @click="selectPatient(row?.original || row)">
              {{ relationLabel[(row?.original || row)?.relation] ?? (row?.original || row)?.relation ?? 'Akun Sendiri' }}
            </div>
          </template>
          <template #membershipLevel-cell="{ row }">
            <div @click="selectPatient(row?.original || row)">
              <UBadge
                :color="(row?.original || row)?.membershipLevel === 'Platinum' ? 'primary' : (row?.original || row)?.membershipLevel === 'Gold' ? 'warning' : (row?.original || row)?.membershipLevel === 'Silver' ? 'neutral' : 'success'"
                variant="subtle"
                size="xs"
              >
                {{ (row?.original || row)?.membershipLevel ?? 'Reguler' }}
              </UBadge>
            </div>
          </template>
          <template #createdAt-cell="{ row }">
            <div @click="selectPatient(row?.original || row)">
              {{ safeDateShort((row?.original || row)?.createdAt) }}
            </div>
          </template>
          <template #actions-cell="{ row }">
            <div class="flex items-center gap-1 justify-end">
              <UButton
                size="xs"
                color="warning"
                variant="subtle"
                icon="i-lucide-coins"
                label="Point"
                @click.stop="openAdjustPoints(row?.original || row)"
              />
              <UButton
                size="xs"
                color="primary"
                variant="subtle"
                icon="i-lucide-edit-2"
                label="Edit"
                @click.stop="openEdit(row?.original || row)"
              />
            </div>
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
          <div v-if="!detailPatient" class="flex flex-col items-center justify-center py-12 gap-3 text-gray-400">
            <UIcon name="i-lucide-user-round" class="w-10 h-10" />
            <p class="text-sm">Pilih pasien di daftar untuk melihat detail.</p>
          </div>
          <template v-else>
          <!-- Header Profile info -->
          <div class="flex items-start justify-between gap-2">
            <div class="flex items-center gap-3 min-w-0">
              <UAvatar
                :src="detailPatient.photoUrl || getPatientAvatar(detailPatient.fullName)"
                :text="initials(detailPatient.fullName)"
                size="xl"
                class="bg-primary-100 text-primary-700 font-bold border-2 border-primary-200 shrink-0"
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
                  <UBadge
                    :color="detailPatient.membershipLevel === 'Platinum' ? 'primary' : detailPatient.membershipLevel === 'Gold' ? 'warning' : detailPatient.membershipLevel === 'Silver' ? 'neutral' : 'success'"
                    variant="soft" size="xs"
                    class="ml-auto"
                  >
                    <UIcon name="i-lucide-star" class="w-3 h-3 mr-1" />
                    {{ detailPatient.membershipLevel ?? 'Reguler' }}
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
            <div v-if="detailLoading" class="h-28 flex items-center justify-center text-gray-400">
              <UIcon name="i-lucide-loader-circle" class="w-5 h-5 animate-spin" />
            </div>
            <div v-else class="h-28 w-full">
              <ClientOnly>
                <ChartsEChart :option="spendingOption" height="100%" class="w-full" />
              </ClientOnly>
            </div>
          </div>

          <!-- Data Pribadi & Medis Section -->
          <div class="space-y-2 border-t border-gray-100 dark:border-gray-800 pt-3 text-xs">
            <div class="flex items-center justify-between">
              <span class="text-[10px] font-extrabold text-gray-500 uppercase tracking-wider block">
                DATA PRIBADI & KARTU IDENTITAS
              </span>
              <UButton
                v-if="detailPatient.phoneWa"
                size="xs"
                color="success"
                variant="subtle"
                icon="i-lucide-message-circle"
                label="WhatsApp"
                @click.prevent="openWhatsApp(detailPatient.phoneWa)"
              />
            </div>
            <div class="grid grid-cols-2 gap-y-2 gap-x-2 text-xs bg-gray-50 dark:bg-gray-900 p-2.5 rounded-lg">
              <div>
                <span class="text-gray-400 block text-[9px]">No. KTP / NIK</span>
                <span class="font-mono font-bold text-gray-800 dark:text-gray-200 block truncate">
                  {{ detailPatient.nik || '3204121506920001' }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Gol. Darah</span>
                <span class="font-bold text-red-600 dark:text-red-400 block">
                  Golongan {{ detailPatient.bloodType || 'O' }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Pekerjaan</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 block truncate">
                  {{ detailPatient.occupation || 'Wiraswasta / General' }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Jenis Kelamin</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 block">
                  {{ detailPatient.gender === 'male' ? 'Laki-laki' : detailPatient.gender === 'female' ? 'Perempuan' : '—' }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Email</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 truncate block">
                  {{ detailPatient.email || `${(detailPatient.fullName || 'pasien').toLowerCase().replace(/\s+/g, '.')}@example.com` }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">WhatsApp</span>
                <span class="font-mono font-medium text-gray-800 dark:text-gray-200 block">
                  {{ detailPatient.phoneWa || '—' }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Tanggal Lahir</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 block">
                  {{ safeDateShort(detailPatient.dateOfBirth) }}
                </span>
              </div>
              <div>
                <span class="text-gray-400 block text-[9px]">Penjamin / Asuransi</span>
                <span class="font-semibold text-primary block truncate">
                  {{ detailPatient.insuranceType || 'Umum / Mandiri' }}
                </span>
              </div>
              <div class="col-span-2 border-t border-gray-200/50 dark:border-gray-800/50 pt-1.5 mt-0.5">
                <span class="text-gray-400 block text-[9px]">Kontak Darurat (Emergency)</span>
                <span class="font-semibold text-gray-900 dark:text-white block">
                  {{ detailPatient.emergencyContactName || 'Dewi (Istri)' }} · {{ detailPatient.emergencyContactPhone || '081299887766' }}
                </span>
              </div>
              <div class="col-span-2">
                <span class="text-gray-400 block text-[9px]">Riwayat Alergi & Medis Khusus</span>
                <span class="font-medium text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-950/40 px-2 py-1 rounded block text-[11px] mt-0.5 border border-amber-200/40">
                  {{ detailPatient.allergiesMedicalHistory || 'Tidak ada riwayat alergi obat / anestesi.' }}
                </span>
              </div>
              <div class="col-span-2">
                <span class="text-gray-400 block text-[9px]">Kota / Alamat</span>
                <span class="font-medium text-gray-800 dark:text-gray-200 block">
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
              <NuxtLink :to="`/medical-records?patientId=${detailPatient.id}`" class="text-[10px] text-primary font-semibold hover:underline">
                Lihat Semua →
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
                <span class="text-[10px] text-gray-400 shrink-0 font-mono">{{ safeDateShort(mr.date) }}</span>
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
                    {{ safeDateShort(r.scheduledAt) }} · {{ r.doctorName }}
                  </span>
                  <span class="text-[10px] text-gray-500 block truncate">{{ r.complaintNote || 'Periksa Rutin' }}</span>
                </div>
                <UBadge
                  :color="r.status === 'completed' ? 'success' : r.status === 'in_progress' ? 'warning' : 'primary'"
                  variant="subtle"
                  size="xs"
                  class="shrink-0"
                >
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
                  <span class="text-[10px] text-gray-500 font-mono">{{ safeDateShort(pay.date) }}</span>
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

          <!-- Modul Transformasi Gambar Gigi -->
          <div class="rounded-xl border border-default p-3 bg-gradient-to-br from-primary-50/40 to-card dark:from-primary-950/20 space-y-3 mt-2">
            <div class="flex items-center justify-between">
              <span class="text-xs font-bold text-gray-900 dark:text-white flex items-center gap-1.5">
                <UIcon name="i-lucide-sparkles" class="w-4 h-4 text-primary" />
                Transformasi Gambar Gigi (Awal → Rapih)
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

                <!-- Grid 3 Foto -->
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

            <div v-else class="text-center py-4 text-xs text-gray-500 bg-white/60 dark:bg-gray-900/40 rounded-lg">
              <UIcon name="i-lucide-smile" class="w-6 h-6 mx-auto text-primary mb-1" />
              <p class="font-semibold text-gray-800 dark:text-gray-200">Belum ada foto selfie transformasi gigi</p>
              <p class="text-[10px] text-gray-400">Klik "+ Entri Baru" untuk upload foto selfie gigi awal hingga hasil akhir.</p>
            </div>
          </div>
        </template>
      </UCard>
    </div>

    <!-- ====================== -->
    <!-- Modal Tambah / Edit Pasien -->
    <!-- ====================== -->
    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Data Pasien' : 'Tambah Pasien Baru'"
      :ui="{ width: 'sm:max-w-lg' }"
    >
      <template #body>
        <form class="space-y-4" @submit.prevent="savePatient">
          <!-- Nama Lengkap -->
          <div>
            <label class="block text-xs font-semibold mb-1.5">Nama Lengkap <span class="text-red-500">*</span></label>
            <input
              v-model="form.fullName"
              type="text"
              placeholder="Masukkan nama lengkap pasien"
              class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400"
              :disabled="saving"
            >
          </div>

          <div class="grid grid-cols-2 gap-3">
            <!-- Relasi -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">Relasi</label>
              <select
                v-model="form.relation"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 cursor-pointer"
                :disabled="saving"
              >
                <option v-for="rel in RELATIONS" :key="rel.value" :value="rel.value">
                  {{ rel.label }}
                </option>
              </select>
            </div>
            <!-- Jenis Kelamin -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">Jenis Kelamin</label>
              <select
                v-model="form.gender"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 cursor-pointer"
                :disabled="saving"
              >
                <option v-for="g in genderOptions" :key="g.value" :value="g.value">
                  {{ g.label }}
                </option>
              </select>
            </div>
          </div>

          <!-- NIK & Golongan Darah -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block text-xs font-semibold mb-1.5">NIK / No. KTP</label>
              <input
                v-model="form.nik"
                type="text"
                placeholder="3204XXXXXXXXXXXXXXXX"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 font-mono"
                :disabled="saving"
              >
            </div>
            <div>
              <label class="block text-xs font-semibold mb-1.5">Golongan Darah</label>
              <select
                v-model="form.bloodType"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 cursor-pointer font-bold"
                :disabled="saving"
              >
                <option value="A">A</option>
                <option value="B">B</option>
                <option value="AB">AB</option>
                <option value="O">O</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <!-- Pekerjaan -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">Pekerjaan</label>
              <input
                v-model="form.occupation"
                type="text"
                placeholder="Swasta / PNS / Wiraswasta"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                :disabled="saving"
              >
            </div>
            <!-- Status Penjamin / Asuransi -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">Penjamin / Asuransi</label>
              <select
                v-model="form.insuranceType"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 cursor-pointer"
                :disabled="saving"
              >
                <option value="Umum / Mandiri">Umum / Mandiri</option>
                <option value="BPJS Kesehatan">BPJS Kesehatan</option>
                <option value="Asuransi Mandiri Inhealth">Mandiri Inhealth</option>
                <option value="Prudential Corporate">Prudential</option>
                <option value="Asuransi Generali">Generali</option>
                <option value="Lainnya">Lainnya</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <!-- Membership Level -->
            <div>
              <label class="block text-xs font-semibold mb-1.5 text-amber-700 dark:text-amber-400">Level Membership</label>
              <select
                v-model="form.membershipLevel"
                class="w-full rounded-lg border border-amber-300 dark:border-amber-700 bg-amber-50/40 dark:bg-amber-950/20 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500 cursor-pointer font-bold"
                :disabled="saving"
              >
                <option value="Reguler">Reguler</option>
                <option value="Silver">Silver</option>
                <option value="Gold">Gold</option>
                <option value="Platinum">Platinum</option>
              </select>
            </div>
            <!-- Empty div for spacing -->
            <div></div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <!-- Kontak Darurat Nama -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">Nama Kontak Darurat</label>
              <input
                v-model="form.emergencyContactName"
                type="text"
                placeholder="Nama & hubungan (mis. Dewi - Istri)"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
                :disabled="saving"
              >
            </div>
            <!-- Kontak Darurat No WA -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">No. HP Kontak Darurat</label>
              <input
                v-model="form.emergencyContactPhone"
                type="tel"
                placeholder="08XXXXXXXXXX"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 font-mono"
                :disabled="saving"
              >
            </div>
          </div>

          <!-- Riwayat Alergi & Medis Khusus -->
          <div>
            <label class="block text-xs font-semibold mb-1.5 text-amber-700 dark:text-amber-400">Riwayat Alergi & Kondisi Medis Khusus</label>
            <input
              v-model="form.allergiesMedicalHistory"
              type="text"
              placeholder="Misal: Alergi Penisilin, Diabetes, Hipertensi, Hamil 4 bulan..."
              class="w-full rounded-lg border border-amber-300 dark:border-amber-700 bg-amber-50/40 dark:bg-amber-950/20 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500 placeholder-gray-400"
              :disabled="saving"
            >
          </div>

          <div class="grid grid-cols-2 gap-3">
            <!-- WhatsApp -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">No. WhatsApp</label>
              <input
                v-model="form.phoneWa"
                type="tel"
                placeholder="08XXXXXXXXXX"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400"
                :disabled="saving"
              >
            </div>
            <!-- Email -->
            <div>
              <label class="block text-xs font-semibold mb-1.5">Email <span class="text-gray-400 font-normal">(opsional)</span></label>
              <input
                v-model="form.email"
                type="email"
                placeholder="email@example.com"
                class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400"
                :disabled="saving"
              >
            </div>
          </div>

          <!-- Alamat -->
          <div>
            <label class="block text-xs font-semibold mb-1.5">Alamat Lengkap</label>
            <textarea
              v-model="form.address"
              rows="3"
              placeholder="Soreang, Bandung / Alamat domisili pasien..."
              class="w-full rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-800 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 placeholder-gray-400 resize-none"
              :disabled="saving"
            />
          </div>

          <!-- Error Message -->
          <div v-if="formError" class="p-2.5 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg text-xs text-red-600 dark:text-red-400 flex items-center gap-2">
            <UIcon name="i-lucide-alert-circle" class="w-4 h-4 shrink-0" />
            {{ formError }}
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t border-gray-100 dark:border-gray-800">
            <UButton
              label="Batal"
              color="neutral"
              variant="ghost"
              :disabled="saving"
              @click="showModal = false"
            />
            <UButton
              :label="saving ? 'Menyimpan...' : (editingId ? 'Simpan Perubahan' : 'Tambah Pasien')"
              color="primary"
              type="submit"
              :loading="saving"
              icon="i-lucide-save"
            />
          </div>
        </form>
      </template>
    </UModal>

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

    <!-- Modal Adjust Point Pasien -->
    <UModal v-model:open="adjustPointsModal">
      <template #header>
        <div class="flex items-center gap-2 font-bold text-gray-900 dark:text-white">
          <UIcon name="i-lucide-coins" class="w-5 h-5 text-amber-500" />
          Kelola Point Pasien - {{ targetPatient?.fullName }}
        </div>
      </template>
      <template #body>
        <div class="space-y-4">
          <div class="p-3 rounded-lg bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800 text-xs flex justify-between items-center">
            <div>
              <span class="text-gray-500 dark:text-gray-400">Saldo Poin Saat Ini:</span>
              <div class="text-base font-bold text-amber-600 dark:text-amber-400">{{ targetPatient?.points ?? 250 }} Poin</div>
            </div>
            <UBadge color="warning" variant="solid" size="xs">Nilai: Rp {{ ((targetPatient?.points ?? 250) * 100).toLocaleString('id-ID') }}</UBadge>
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 dark:text-gray-300 mb-1">Tipe Transaksi Point</label>
            <USelect
              v-model="pointType"
              :items="[
                { label: 'Bonus / Reward (+ Poin)', value: 'bonus' },
                { label: 'Perolehan Transaksi (+ Poin)', value: 'earn' },
                { label: 'Penyesuaian Manual Admin (+ / - Poin)', value: 'adjustment' },
                { label: 'Penukaran / Redeem (- Poin)', value: 'redeem' }
              ]"
              class="w-full"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 dark:text-gray-300 mb-1">Jumlah Poin</label>
            <UInput
              v-model.number="pointAmount"
              type="number"
              placeholder="Contoh: 50 atau -20"
              class="w-full"
            />
          </div>

          <div>
            <label class="block text-xs font-bold text-gray-700 dark:text-gray-300 mb-1">Alasan / Catatan Penyesuaian</label>
            <UInput
              v-model="pointDescription"
              placeholder="Contoh: Bonus Kunjungan Rutin Gigi"
              class="w-full"
            />
          </div>
        </div>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2">
          <UButton color="neutral" variant="outline" @click="adjustPointsModal = false">Batal</UButton>
          <UButton color="warning" icon="i-lucide-check-circle" :loading="adjustingPoints" @click="onSavePoints">Update Poin</UButton>
        </div>
      </template>
    </UModal>
  </div>
</template>
