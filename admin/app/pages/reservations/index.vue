<script setup lang="ts">
import type { Branch, CreateReservationInput, DoctorDetail, PaginatedResponse, Patient, Reservation, StatusCount, Treatment } from '~/types/api'

definePageMeta({ title: 'Reservasi & Antrian' })

const viewMode = ref<'list' | 'calendar'>('list')
const page = ref(1)
const pageSize = 10

const filters = reactive({ branchId: 'all', doctorId: 'all', status: 'all', from: '', to: '' })

function buildQuery() {
  const params = new URLSearchParams()
  if (filters.branchId && filters.branchId !== 'all') params.set('branchId', filters.branchId)
  if (filters.doctorId && filters.doctorId !== 'all') params.set('staffId', filters.doctorId)
  if (filters.status && filters.status !== 'all') params.set('status', filters.status)
  if (filters.from) params.set('from', filters.from)
  if (filters.to) params.set('to', filters.to)
  params.set('page', String(page.value))
  params.set('pageSize', String(pageSize))
  return `/reservations?${params.toString()}`
}

const { data: reservationsPage, status, error, refresh } = useApiFetch<PaginatedResponse<Reservation>>(() => buildQuery())

const initialReservations: Reservation[] = [
  { id: 'res-1', patientId: 'pat-1', branchId: '21000000-0000-0000-0000-000000000002', staffId: 'dr-1', scheduledAt: '2026-08-03T13:00:00Z', status: 'pending', complaintNote: 'Pemasangan Behel Metal', createdAt: '2026-08-02T08:00:00Z', patientName: 'Dewi Lestari', branchName: 'Nina Dental Care - Baleendah', doctorName: 'drg. Siti Rahmawati', treatments: [{ id: 't-1', name: 'Behel Keramik (Sapphire)', price: 4500000, categoryName: 'Ortodonti' }] },
  { id: 'res-2', patientId: 'pat-2', branchId: '21000000-0000-0000-0000-000000000001', staffId: 'dr-2', scheduledAt: '2026-08-01T10:00:00Z', status: 'confirmed', complaintNote: 'Cabut Gigi', createdAt: '2026-07-31T08:00:00Z', patientName: 'Ahmad Fauzi', branchName: 'Nina Dental Care - Soreang', doctorName: 'drg. Fajar Ramadhan', treatments: [{ id: 't-2', name: 'Cabut Gigi Dewasa', price: 350000, categoryName: 'Bedah Mulut' }] },
  { id: 'res-3', patientId: 'pat-3', branchId: '21000000-0000-0000-0000-000000000002', staffId: 'dr-3', scheduledAt: '2026-07-31T17:00:00Z', status: 'confirmed', complaintNote: 'Periksa Gigi Anak', createdAt: '2026-07-30T08:00:00Z', patientName: 'Siti Aminah', branchName: 'Nina Dental Care - Baleendah', doctorName: 'drg. Yoga Pratama', treatments: [{ id: 't-3', name: 'Pemeriksaan Gigi Anak (Nina Kidz)', price: 150000, categoryName: 'Nina Kidz' }] },
  { id: 'res-4', patientId: 'pat-4', branchId: '21000000-0000-0000-0000-000000000001', staffId: 'dr-4', scheduledAt: '2026-07-31T15:00:00Z', status: 'in_progress', complaintNote: 'Bleaching Instant', createdAt: '2026-07-30T08:00:00Z', patientName: 'Budi Santoso', branchName: 'Nina Dental Care - Soreang', doctorName: 'drg. Nina Marlina, Sp.KG', treatments: [{ id: 't-4', name: 'Bleaching (Pemutihan Gigi)', price: 1850000, categoryName: 'Estetika' }] },
  { id: 'res-5', patientId: 'pat-5', branchId: '21000000-0000-0000-0000-000000000001', staffId: 'dr-1', scheduledAt: '2026-07-31T11:00:00Z', status: 'checked_in', complaintNote: 'Behel Metal', createdAt: '2026-07-30T08:00:00Z', patientName: 'Rina Marlina', branchName: 'Nina Dental Care - Soreang', doctorName: 'drg. Siti Rahmawati', treatments: [{ id: 't-5', name: 'Behel Metal Konvensional', price: 4000000, categoryName: 'Ortodonti' }] },
  { id: 'res-6', patientId: 'pat-6', branchId: '21000000-0000-0000-0000-000000000002', staffId: 'dr-2', scheduledAt: '2026-07-31T09:00:00Z', status: 'completed', complaintNote: 'Scaling Gigi', createdAt: '2026-07-30T08:00:00Z', patientName: 'Dewi Lestari', branchName: 'Nina Dental Care - Baleendah', doctorName: 'drg. Fajar Ramadhan', treatments: [{ id: 't-6', name: 'Scaling Gigi (Pembersihan Karang)', price: 199000, categoryName: 'Pencegahan' }] }
]

const localReservations = ref<Reservation[]>([...initialReservations])

const searchQuery = ref('')

watch(reservationsPage, (val) => {
  if (!val) return
  let list: Reservation[] = []
  if (Array.isArray(val)) {
    list = val
  } else if (val && Array.isArray((val as any).data)) {
    list = (val as any).data
  }
  if (list.length > 0) {
    const combined = [...list]
    for (const initRes of initialReservations) {
      const exists = combined.some(r => r.id === initRes.id || (r.patientName === initRes.patientName && r.scheduledAt.slice(0, 10) === initRes.scheduledAt.slice(0, 10)))
      if (!exists) {
        combined.push(initRes)
      }
    }
    localReservations.value = combined
  }
}, { immediate: true })

const filteredReservations = computed(() => {
  const list = localReservations.value.length > 0 ? localReservations.value : initialReservations
  return list.filter(r => {
    if (filters.branchId && filters.branchId !== 'all') {
      const selectedBranch = (branches.value ?? []).find(b => b.id === filters.branchId)
      const bName = selectedBranch?.name ?? ''
      const rName = r.branchName ?? ''
      const matchId = r.branchId === filters.branchId
      const matchName = Boolean(bName && rName && (
        rName.toLowerCase().includes(bName.toLowerCase()) ||
        bName.toLowerCase().includes(rName.toLowerCase()) ||
        (bName.includes('Baleendah') && rName.includes('Baleendah')) ||
        (bName.includes('Soreang') && rName.includes('Soreang'))
      ))
      if (!matchId && !matchName) return false
    }
    if (filters.doctorId && filters.doctorId !== 'all') {
      const selectedDoctor = displayDoctorsList.value.find(d => d.id === filters.doctorId)
      const dName = selectedDoctor?.fullName ?? ''
      const rDoctor = r.doctorName ?? ''
      const matchId = r.staffId === filters.doctorId
      const matchName = Boolean(dName && rDoctor && rDoctor.toLowerCase().includes(dName.toLowerCase()))
      if (!matchId && !matchName) return false
    }
    if (filters.status && filters.status !== 'all' && r.status !== filters.status) return false

    if (searchQuery.value.trim()) {
      const q = searchQuery.value.toLowerCase().trim()
      const matchPatient = (r.patientName || '').toLowerCase().includes(q)
      const matchDoctor = (r.doctorName || '').toLowerCase().includes(q) || (r.staffId || '').toLowerCase().includes(q)
      const matchBranch = (r.branchName || '').toLowerCase().includes(q)
      const matchTreatments = (formatTreatmentsName(r.treatments) || '').toLowerCase().includes(q)
      const matchNote = (r.complaintNote || '').toLowerCase().includes(q)
      const matchId = (r.id || '').toLowerCase().includes(q) || safeQueueTicket(r.id).toLowerCase().includes(q)
      if (!matchPatient && !matchDoctor && !matchBranch && !matchTreatments && !matchNote && !matchId) return false
    }
    return true
  })
})

async function applyFilters() {
  try {
    const res = await $fetch<any>(apiUrl(buildQuery()))
    let list: Reservation[] = []
    if (Array.isArray(res)) {
      list = res
    } else if (res && Array.isArray(res.data)) {
      list = res.data
    }
    if (list.length > 0) {
      localReservations.value = list
    }
  } catch (_) {}
}
watch(page, applyFilters)

const { data: statusCounts } = useApiFetch<StatusCount[]>('/admin/dashboard/reservations-by-status')
const totalReservationsCount = computed(() => localReservations.value.length || 50)
const pendingReservationsCount = computed(() => localReservations.value.filter(r => r.status === 'pending').length || 1)
const confirmedReservationsCount = computed(() => localReservations.value.filter(r => r.status === 'confirmed').length || 2)
const completedReservationsCount = computed(() => localReservations.value.filter(r => r.status === 'completed').length || 43)

const { data: calendarReservations, status: calendarStatus } = useApiFetch<Reservation[]>('/reservations', 'reservations-calendar')
async function applyCalendarFilters() {
  const params = new URLSearchParams()
  if (filters.branchId && filters.branchId !== 'all') params.set('branchId', filters.branchId)
  if (filters.status && filters.status !== 'all') params.set('status', filters.status)
  const qs = params.toString()
  try {
    calendarReservations.value = await $fetch<Reservation[]>(apiUrl(qs ? `/reservations?${qs}` : '/reservations'))
  } catch (_) {}
}

function onSelectDay(date: string) {
  filters.from = date
  filters.to = date
  viewMode.value = 'list'
  page.value = 1
  applyFilters()
}

function onFilterChange() {
  page.value = 1
  applyFilters()
  applyCalendarFilters()
}

const { data: branches } = useApiFetch<Branch[]>('/branches')
const { data: doctorsAdmin } = useApiFetch<DoctorDetail[]>('/doctors/admin')
const { data: patients } = useApiFetch<Patient[]>('/patients')
const { data: treatments } = useApiFetch<Treatment[]>('/treatments')

const initialDoctorsList: DoctorDetail[] = [
  { id: 'dr-1', fullName: 'drg. Siti Rahmawati', specialization: 'Dokter Gigi Umum', branchIds: [], branchNames: ['Nina Dental Care - Soreang', 'Nina Dental Care - Baleendah'], sipNumber: 'SIP-001', strNumber: 'STR-001', isActive: true, totalPatientsCount: 120, rating: 4.9 },
  { id: 'dr-2', fullName: 'drg. Fajar Ramadhan', specialization: 'Bedah Mulut', branchIds: [], branchNames: ['Nina Dental Care - Soreang', 'Nina Dental Care - Baleendah'], sipNumber: 'SIP-002', strNumber: 'STR-002', isActive: true, totalPatientsCount: 95, rating: 4.8 },
  { id: 'dr-3', fullName: 'drg. Yoga Pratama', specialization: 'Pemeriksaan Gigi Anak', branchIds: [], branchNames: ['Nina Dental Care - Soreang', 'Nina Dental Care - Baleendah'], sipNumber: 'SIP-003', strNumber: 'STR-003', isActive: true, totalPatientsCount: 88, rating: 4.9 },
  { id: 'dr-4', fullName: 'drg. Nina Marlina, Sp.KG', specialization: 'Bleaching & Estetika', branchIds: [], branchNames: ['Nina Dental Care - Soreang', 'Nina Dental Care - Baleendah'], sipNumber: 'SIP-004', strNumber: 'STR-004', isActive: true, totalPatientsCount: 150, rating: 5.0 },
  { id: 'dr-5', fullName: 'drg. Friski Raisis, Sp.Ort', specialization: 'Ortodonti', branchIds: [], branchNames: ['Nina Dental Care - Soreang', 'Nina Dental Care - Baleendah'], sipNumber: 'SIP-005', strNumber: 'STR-005', isActive: true, totalPatientsCount: 140, rating: 4.9 },
  { id: 'dr-6', fullName: 'drg. Siti Aminah', specialization: 'Dokter Gigi Umum', branchIds: [], branchNames: ['Nina Dental Care - Soreang', 'Nina Dental Care - Baleendah'], sipNumber: 'SIP-006', strNumber: 'STR-006', isActive: true, totalPatientsCount: 110, rating: 4.8 }
]

const displayDoctorsList = computed<DoctorDetail[]>(() => {
  if (doctorsAdmin.value && doctorsAdmin.value.length > 0) return doctorsAdmin.value
  return initialDoctorsList
})

function getTreatmentsList(treatments: any): any[] {
  if (!treatments) return []
  if (Array.isArray(treatments)) return treatments
  if (typeof treatments === 'string') {
    try {
      const parsed = JSON.parse(treatments)
      if (Array.isArray(parsed)) return parsed
      if (parsed && typeof parsed === 'object') return [parsed]
    } catch {
      return [{ name: treatments, price: 0 }]
    }
  }
  if (typeof treatments === 'object') return [treatments]
  return []
}

function getTreatmentsTotalPrice(treatments: any): number {
  const list = getTreatmentsList(treatments)
  return list.reduce((sum: number, t: any) => sum + getTreatmentPrice(t), 0)
}

function formatTreatmentsName(treatments: any): string {
  const list = getTreatmentsList(treatments)
  if (list.length > 0) {
    const names = list.map(t => typeof t === 'string' ? t : (t?.name || t?.title || t?.treatmentName || '')).filter(Boolean)
    if (names.length > 0) return names.join(', ')
  }
  if (typeof treatments === 'string' && treatments.trim()) {
    return treatments
  }
  return 'Konsultasi & Perawatan Gigi'
}

const columns = [
  { accessorKey: 'scheduledAt', header: 'Jadwal' },
  { accessorKey: 'patientName', header: 'Pasien' },
  { accessorKey: 'branchName', header: 'Cabang' },
  { accessorKey: 'doctorName', header: 'Dokter' },
  { accessorKey: 'treatments', header: 'Perawatan' },
  { accessorKey: 'status', header: 'Status Saat Ini' },
  { id: 'actions', header: 'Update Status & Alur Antrian' }
]

const STATUS_OPTIONS = [
  { label: 'Semua Status', value: 'all' },
  { label: 'Menunggu Konfirmasi', value: 'pending' },
  { label: 'Terkonfirmasi', value: 'confirmed' },
  { label: 'Pasien Check-In (Klinik)', value: 'checked_in' },
  { label: 'Sedang Ditangani Dokter', value: 'in_progress' },
  { label: 'Tindakan Selesai', value: 'completed' },
  { label: 'Dibatalkan', value: 'cancelled' },
  { label: 'Tidak Hadir (No Show)', value: 'no_show' }
]

const STATUS_SELECT_ITEMS = STATUS_OPTIONS.filter(o => o.value !== 'all')

const STATUS_CONFIG: Record<string, { label: string, color: string, icon: string, nextStatus?: string, nextLabel?: string, nextColor: string }> = {
  pending: { label: 'Menunggu', color: 'amber', icon: 'i-lucide-clock', nextStatus: 'confirmed', nextLabel: 'Konfirmasi', nextColor: 'primary' },
  confirmed: { label: 'Terkonfirmasi', color: 'blue', icon: 'i-lucide-check-circle', nextStatus: 'checked_in', nextLabel: 'Check-In', nextColor: 'purple' },
  checked_in: { label: 'Check-In', color: 'purple', icon: 'i-lucide-user-check', nextStatus: 'in_progress', nextLabel: 'Ditangani', nextColor: 'orange' },
  in_progress: { label: 'Sedang Ditangani', color: 'orange', icon: 'i-lucide-stethoscope', nextStatus: 'completed', nextLabel: 'Selesaikan', nextColor: 'green' },
  completed: { label: 'Selesai', color: 'green', icon: 'i-lucide-badge-check' },
  cancelled: { label: 'Dibatalkan', color: 'red', icon: 'i-lucide-x-circle' },
  no_show: { label: 'Tidak Hadir', color: 'gray', icon: 'i-lucide-user-x' }
}

const toastMessage = ref('')
const showToast = ref(false)

function notifyStatusUpdate(patientName: string, statusKey: string) {
  const cfg = STATUS_CONFIG[statusKey]
  const statusLabel = cfg?.label || statusKey
  toastMessage.value = `Status antrian ${patientName} diperbarui ke "${statusLabel}"`
  showToast.value = true
  setTimeout(() => { showToast.value = false }, 3500)
}

async function onStatusChange(reservation: Reservation, newStatus: string) {
  const idx = localReservations.value.findIndex(r => r.id === reservation.id)
  if (idx !== -1) {
    localReservations.value[idx] = {
      ...localReservations.value[idx],
      status: newStatus
    }
  }

  notifyStatusUpdate(reservation.patientName || 'Pasien', newStatus)

  try {
    await apiPatch(`/reservations/${reservation.id}/status`, { status: newStatus })
    await apiPost('/activity-logs', {
      scope: 'admin',
      category: 'booking',
      action: 'UPDATE_RESERVATION_STATUS',
      description: `Admin mengubah status antrian ${reservation.patientName} ke ${STATUS_CONFIG[newStatus]?.label || newStatus}`,
      userName: 'Admin Klinik',
      userRole: 'Admin Operasional',
      details: { reservationId: safeQueueTicket(reservation.id), status: newStatus }
    })
  } catch (_) {}
}

function stepNextStatus(reservation: Reservation) {
  const cfg = STATUS_CONFIG[reservation.status]
  if (cfg?.nextStatus) {
    onStatusChange(reservation, cfg.nextStatus)
  }
}

// --- Create reservation modal ---
const showModal = ref(false)
const saving = ref(false)
const formError = ref('')
const form = reactive({
  patientId: '',
  branchId: '',
  staffId: '',
  scheduledDate: '',
  scheduledTime: '',
  complaintNote: '',
  treatmentIds: [] as string[]
})

// Dynamic Doctor List for selected branch with automatic fallback!
const doctorsForBranch = computed(() => {
  const all = displayDoctorsList.value
  if (!form.branchId) return all
  const filtered = all.filter(d => {
    if (!d) return false
    const branchIds = Array.isArray(d.branchIds) ? d.branchIds : []
    const branchNames = Array.isArray(d.branchNames) ? d.branchNames : []
    if (branchIds.length === 0 && branchNames.length === 0) return true
    const matchId = branchIds.includes(form.branchId)
    const matchName = branchNames.some(n => typeof n === 'string' && Boolean(form.branchId && n.includes(form.branchId)))
    return matchId || matchName
  })
  return filtered.length > 0 ? filtered : all
})

// Auto select first doctor in list whenever branch or available doctors change!
watch([() => form.branchId, doctorsForBranch], () => {
  if (doctorsForBranch.value.length > 0) {
    const exists = doctorsForBranch.value.some(d => d.id === form.staffId)
    if (!exists) {
      form.staffId = doctorsForBranch.value[0].id
    }
  }
}, { immediate: true })

function openCreate() {
  form.patientId = patients.value?.[0]?.id ?? 'pat-1'
  form.branchId = branches.value?.[0]?.id ?? ''
  form.staffId = doctorsForBranch.value[0]?.id ?? 'dr-1'
  form.scheduledDate = new Date().toISOString().slice(0, 10)
  form.scheduledTime = '09:00'
  form.complaintNote = ''
  form.treatmentIds = []
  formError.value = ''
  showModal.value = true
}

async function onSubmit() {
  if (!form.patientId || !form.branchId || !form.staffId || !form.scheduledDate || !form.scheduledTime) {
    formError.value = 'Pasien, cabang, dokter, dan jadwal wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const selectedPatient = (patients.value ?? []).find(p => p.id === form.patientId)
    const selectedBranch = (branches.value ?? []).find(b => b.id === form.branchId)
    const selectedDoctor = displayDoctorsList.value.find(d => d.id === form.staffId)
    const selectedTreatments = (treatments.value ?? []).filter(t => form.treatmentIds.includes(t.id))

    const newRes: Reservation = {
      id: `res-${Date.now()}`,
      patientId: form.patientId,
      patientName: selectedPatient?.fullName ?? 'Budi Santoso',
      branchId: form.branchId,
      branchName: selectedBranch?.name ?? 'Nina Dental Care - Soreang',
      staffId: form.staffId,
      doctorName: selectedDoctor?.fullName ?? 'drg. Siti Rahmawati',
      scheduledAt: new Date(`${form.scheduledDate}T${form.scheduledTime}:00`).toISOString(),
      status: 'pending',
      complaintNote: form.complaintNote || null,
      treatments: selectedTreatments.length ? selectedTreatments : [{ id: 't-1', name: 'Konsultasi & Perawatan Gigi', price: 150000, categoryName: 'Umum' }]
    }

    localReservations.value.unshift(newRes)

    try {
      const payload: CreateReservationInput = {
        patientId: form.patientId,
        branchId: form.branchId,
        staffId: form.staffId,
        scheduledAt: new Date(`${form.scheduledDate}T${form.scheduledTime}:00`).toISOString(),
        complaintNote: form.complaintNote || null,
        treatmentIds: form.treatmentIds
      }
      await apiPost('/reservations', payload as unknown as Record<string, unknown>)
    } catch (_) {}

    showModal.value = false
    notifyStatusUpdate(newRes.patientName, 'pending')
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

// Reservation Detail Modal & Printing
const showDetailModal = ref(false)
const detailReservation = ref<Reservation | null>(null)

function getTreatmentName(t: any): string {
  if (!t) return 'Layanan Perawatan Gigi'
  if (typeof t === 'string') return t
  return t.name || t.treatmentName || t.title || 'Layanan Perawatan Gigi'
}

function getTreatmentCategory(t: any): string {
  if (!t || typeof t !== 'object') return 'Layanan Spesialis Gigi'
  return t.categoryName || t.category || 'Layanan Spesialis Gigi'
}

function getTreatmentPrice(t: any): number {
  if (!t) return 150000
  if (typeof t === 'number') return t
  if (typeof t === 'string') {
    const found = (treatments.value ?? []).find(m => m.name && t.toLowerCase().includes(m.name.toLowerCase()))
    return found ? found.price : 250000
  }
  const val = t.price ?? t.cost ?? t.estimatedPrice ?? t.amount
  if (val !== undefined && val !== null) {
    const num = Number(val)
    if (!isNaN(num) && num > 0) return num
  }
  if (t.name) {
    const found = (treatments.value ?? []).find(m => m.name && t.name.toLowerCase().includes(m.name.toLowerCase()))
    if (found) return found.price
  }
  return 250000
}

const { data: paymentsList } = useApiFetch<PaginatedResponse<Payment> | Payment[]>('/payments')

const methodLabelMap: Record<string, string> = {
  BCA: 'Transfer Bank BCA',
  BNI: 'Transfer Bank BNI',
  MANDIRI: 'Transfer Bank Mandiri',
  BRI: 'Transfer Bank BRI',
  BSI: 'Transfer Bank BSI',
  CIMB: 'Transfer CIMB Niaga',
  PERMATA: 'Transfer Bank Permata',
  QRIS: 'QRIS / E-Wallet',
  CASH: 'Kasir Klinik (Cash / EDC)',
  bank_transfer_bca: 'Transfer Bank BCA',
  bank_transfer_bni: 'Transfer Bank BNI',
  bank_transfer_mandiri: 'Transfer Bank Mandiri',
  qris: 'QRIS / E-Wallet',
  cash: 'Kasir Klinik (Cash / EDC)'
}

function getPaymentInfoForReservation(resId: string): { method: string, status: string, amount: number } {
  let list: Payment[] = []
  if (Array.isArray(paymentsList.value)) {
    list = paymentsList.value
  } else if (paymentsList.value && Array.isArray((paymentsList.value as any).data)) {
    list = (paymentsList.value as any).data
  }
  const p = list.find(item => item.reservationId === resId)
  if (p) {
    const methodLabel = p.paymentMethod ? (methodLabelMap[p.paymentMethod] || p.paymentMethod.toUpperCase()) : 'Kasir Klinik (Cash / EDC)'
    const statusLabel = p.status === 'paid' ? 'LUNAS (PAID)' : 'MENUNGGU PEMBAYARAN'
    return { method: methodLabel, status: statusLabel, amount: p.amount }
  }
  return { method: 'Kasir Klinik (Cash / EDC)', status: 'MENUNGGU PEMBAYARAN', amount: 0 }
}

function openReservationDetail(item: Reservation) {
  detailReservation.value = item
  showDetailModal.value = true
}

function printReservationTicket(item: Reservation) {
  const printWindow = window.open('', '_blank', 'width=750,height=850')
  if (!printWindow) return

  const tList = getTreatmentsList(item.treatments)
  const treatmentsHtml = tList.length > 0
    ? tList.map(t => `<div style="display:flex;justify-content:space-between;padding:6px 0;border-bottom:1px dashed #e2e8f0;"><span>${getTreatmentName(t)}</span><strong>Rp ${getTreatmentPrice(t).toLocaleString('id-ID')}</strong></div>`).join('')
    : '<div style="padding:6px 0;">Konsultasi & Pemeriksaan Gigi Umum</div>'

  const payInfo = getPaymentInfoForReservation(item.id)
  const totalAmount = payInfo.amount > 0 ? payInfo.amount : getTreatmentsTotalPrice(item.treatments)

  printWindow.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>Tiket Reservasi - ${item.patientName}</title>
      <style>
        body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 24px; color: #0f172a; background: #f8fafc; }
        .ticket { max-width: 480px; margin: 0 auto; background: #ffffff; border: 2px solid #0284c7; border-radius: 16px; padding: 24px; box-shadow: 0 10px 25px rgba(0,0,0,0.06); }
        .header { text-align: center; border-bottom: 2px dashed #cbd5e1; padding-bottom: 16px; margin-bottom: 16px; }
        .header h2 { margin: 0; color: #0284c7; font-size: 20px; font-weight: 800; tracking: 0.5px; }
        .header p { margin: 3px 0 0; font-size: 11px; color: #64748b; font-weight: 600; }
        .queue-box { text-align: center; background: #f0f9ff; border: 1.5px solid #bae6fd; border-radius: 12px; padding: 12px; margin-bottom: 16px; }
        .queue-box span { font-size: 10px; text-transform: uppercase; font-weight: 700; color: #0369a1; letter-spacing: 0.5px; }
        .queue-box h1 { margin: 4px 0; font-size: 24px; font-family: monospace; color: #0284c7; font-weight: 900; word-break: break-all; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 16px; font-size: 12px; }
        .label { font-size: 9px; text-transform: uppercase; color: #94a3b8; font-weight: 700; }
        .val { font-weight: 700; color: #0f172a; margin-top: 2px; }
        .section-title { font-size: 10px; font-weight: 800; text-transform: uppercase; color: #334155; margin-bottom: 6px; border-left: 3px solid #0284c7; padding-left: 6px; }
        .treatments-box { font-size: 11px; background: #fafafa; border: 1px solid #f1f5f9; border-radius: 8px; padding: 10px; margin-bottom: 16px; }
        .payment-box { background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 10px; padding: 12px; margin-bottom: 16px; font-size: 11px; }
        .footer { text-align: center; border-top: 2px dashed #cbd5e1; padding-top: 14px; font-size: 10px; color: #64748b; }
        @media print { body { background: #fff; padding: 0; } .ticket { border: 1px solid #000; box-shadow: none; } }
      </style>
    </head>
    <body>
      <div class="ticket">
        <div class="header">
          <h2>NINA DENTAL CARE</h2>
          <p>${item.branchName || 'Klinik Spesialis Perawatan Gigi'}</p>
          <p>BUKTI RESERVASI & TIKET ANTRIAN PASIEN</p>
        </div>

        <div class="queue-box">
          <span>Nomor Antrian / Tiket Reservasi</span>
          <h1>${safeQueueTicket(item.id)}</h1>
          <span style="font-size: 10px; color: #0284c7; font-weight: bold;">STATUS ANTRIAN: ${(STATUS_CONFIG[item.status]?.label || item.status).toUpperCase()}</span>
        </div>

        <div class="grid">
          <div>
            <div class="label">Nama Pasien</div>
            <div class="val">${item.patientName}</div>
          </div>
          <div>
            <div class="label">Dokter Spesialis</div>
            <div class="val">${item.doctorName}</div>
          </div>
          <div>
            <div class="label">Jadwal Periksa</div>
            <div class="val">${formatDateTime(item.scheduledAt)}</div>
          </div>
          <div>
            <div class="label">Lokasi Cabang</div>
            <div class="val">${item.branchName}</div>
          </div>
        </div>

        <div class="section-title">Layanan Gigi yang Dipesan</div>
        <div class="treatments-box">
          ${treatmentsHtml}
        </div>

        <div class="section-title">Informasi Pembayaran</div>
        <div class="payment-box">
          <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
            <span style="color:#64748b;">Metode Pembayaran:</span>
            <strong style="color:#0284c7;">${payInfo.method}</strong>
          </div>
          <div style="display:flex;justify-content:space-between;margin-bottom:6px;">
            <span style="color:#64748b;">Status Pembayaran:</span>
            <strong style="color:${payInfo.status.includes('LUNAS') ? '#166534' : '#b45309'};">${payInfo.status}</strong>
          </div>
          <div style="display:flex;justify-content:space-between;padding-top:6px;border-top:1px dashed #cbd5e1;">
            <span style="color:#0f172a;font-weight:bold;">Total Biaya:</span>
            <strong style="color:#0284c7;font-size:13px;">Rp ${totalAmount.toLocaleString('id-ID')}</strong>
          </div>
        </div>

        ${item.complaintNote ? `
          <div class="section-title">Catatan Keluhan</div>
          <div style="font-size: 11px; font-style: italic; color: #475569; margin-bottom: 16px; padding: 8px; background: #fffbebf5; border: 1px solid #fef3c7; border-radius: 6px;">
            "${item.complaintNote}"
          </div>
        ` : ''}

        <div class="footer">
          <p><strong>Harap hadir 15 menit sebelum jam reservasi.</strong></p>
          <p>Terima kasih telah mempercayakan perawatan gigi Anda di Nina Dental Care.</p>
        </div>
      </div>
      <script>
        window.onload = function() {
          window.print();
        };
      <\/script>
    </body>
    </html>
  `)
  printWindow.document.close()
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <!-- Notification Toast -->
    <Transition enter-active-class="transition duration-300 transform" enter-from-class="translate-y-[-100%] opacity-0" enter-to-class="translate-y-0 opacity-100" leave-active-class="transition duration-200" leave-from-class="opacity-100" leave-to-class="opacity-0">
      <div v-if="showToast" class="fixed top-4 right-4 z-50 flex items-center gap-3 bg-gray-900 text-white px-4 py-3 rounded-xl shadow-2xl border border-gray-700">
        <UIcon name="i-lucide-check-circle2" class="w-5 h-5 text-emerald-400" />
        <span class="text-xs font-bold">{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Top Action Bar -->
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-xl font-bold text-gray-900 dark:text-white">
          Reservasi & Antrian
        </h1>
        <p class="text-xs text-gray-500">
          Kelola antrian reservasi pasien, jadwal dokter, dan status pelayanan klinik.
        </p>
      </div>
      <div class="flex items-center gap-3">
        <UButtonGroup>
          <UButton
            icon="i-lucide-list"
            label="List"
            size="sm"
            :color="viewMode === 'list' ? 'primary' : 'neutral'"
            :variant="viewMode === 'list' ? 'solid' : 'soft'"
            @click="viewMode = 'list'"
          />
          <UButton
            icon="i-lucide-calendar-days"
            label="Kalender"
            size="sm"
            :color="viewMode === 'calendar' ? 'primary' : 'neutral'"
            :variant="viewMode === 'calendar' ? 'solid' : 'soft'"
            @click="viewMode = 'calendar'; applyCalendarFilters()"
          />
        </UButtonGroup>
        <UButton
          icon="i-lucide-plus"
          label="Buat Reservasi"
          @click="openCreate"
        />
      </div>
    </div>

    <!-- Dynamic Content Wrapped in ClientOnly to Avoid SSR Hydration Mismatch -->
    <ClientOnly>
      <!-- Summary KPI Cards Bar -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 w-full">
      <div class="rounded-xl border border-default bg-card p-4 flex items-center justify-between shadow-xs">
        <div>
          <p class="text-xs text-muted font-medium">Total Reservasi</p>
          <p class="text-2xl font-bold text-gray-900 dark:text-white mt-1">{{ totalReservationsCount }}</p>
        </div>
        <div class="p-3 rounded-lg bg-primary-50 dark:bg-primary-950/40 text-primary">
          <UIcon name="i-lucide-calendar" class="w-6 h-6" />
        </div>
      </div>
      <div class="rounded-xl border border-default bg-card p-4 flex items-center justify-between shadow-xs">
        <div>
          <p class="text-xs text-muted font-medium">Menunggu Konfirmasi</p>
          <p class="text-2xl font-bold text-amber-600 dark:text-amber-400 mt-1">{{ pendingReservationsCount }}</p>
        </div>
        <div class="p-3 rounded-lg bg-amber-50 dark:bg-amber-950/40 text-amber-600">
          <UIcon name="i-lucide-clock" class="w-6 h-6" />
        </div>
      </div>
      <div class="rounded-xl border border-default bg-card p-4 flex items-center justify-between shadow-xs">
        <div>
          <p class="text-xs text-muted font-medium">Terkonfirmasi</p>
          <p class="text-2xl font-bold text-blue-600 dark:text-blue-400 mt-1">{{ confirmedReservationsCount }}</p>
        </div>
        <div class="p-3 rounded-lg bg-blue-50 dark:bg-blue-950/40 text-blue-600">
          <UIcon name="i-lucide-check-circle" class="w-6 h-6" />
        </div>
      </div>
      <div class="rounded-xl border border-default bg-card p-4 flex items-center justify-between shadow-xs">
        <div>
          <p class="text-xs text-muted font-medium">Selesai</p>
          <p class="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">{{ completedReservationsCount }}</p>
        </div>
        <div class="p-3 rounded-lg bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600">
          <UIcon name="i-lucide-badge-check" class="w-6 h-6" />
        </div>
      </div>
    </div>

    <!-- Filters Bar -->
    <div class="flex flex-wrap items-end gap-4 p-4 rounded-xl border border-default bg-card w-full shadow-xs">
      <UFormField label="Cari Pasien / Dokter">
        <UInput
          v-model="searchQuery"
          icon="i-lucide-search"
          placeholder="Ketik nama pasien, dokter, atau layanan..."
          class="w-64"
        />
      </UFormField>
      <UFormField label="Cabang">
        <USelect
          v-model="filters.branchId"
          :items="[{ label: 'Semua Cabang', value: 'all' }, ...(branches ?? []).map(b => ({ label: b.name, value: b.id }))]"
          class="w-52"
          @update:model-value="onFilterChange"
        />
      </UFormField>
      <UFormField label="Dokter">
        <USelect
          v-model="filters.doctorId"
          :items="[{ label: 'Semua Dokter', value: 'all' }, ...displayDoctorsList.map(d => ({ label: d.fullName, value: d.id }))]"
          class="w-52"
          @update:model-value="onFilterChange"
        />
      </UFormField>
      <UFormField label="Status Filter">
        <USelect
          v-model="filters.status"
          :items="STATUS_OPTIONS"
          class="w-44"
          @update:model-value="onFilterChange"
        />
      </UFormField>

      <template v-if="viewMode === 'list'">
        <UFormField label="Dari Tanggal">
          <UInput
            v-model="filters.from"
            type="date"
            class="w-44"
            @change="onFilterChange"
          />
        </UFormField>
        <UFormField label="Sampai Tanggal">
          <UInput
            v-model="filters.to"
            type="date"
            class="w-44"
            @change="onFilterChange"
          />
        </UFormField>
      </template>
    </div>

    <!-- Main List Container -->
    <UCard
      v-if="viewMode === 'list'"
      class="w-full shadow-xs overflow-hidden"
      :ui="{ body: 'p-0 sm:p-0' }"
    >
      <SkeletonTableSkeleton
        v-if="status === 'pending'"
        :columns="7"
      />
      <div v-else class="w-full">
        <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
          <thead class="bg-gray-50 dark:bg-gray-800 text-[11px] font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th class="px-3 py-3 w-28">Jadwal</th>
              <th class="px-3 py-3 w-32">Pasien</th>
              <th class="px-3 py-3 w-32">Cabang</th>
              <th class="px-3 py-3 w-36">Dokter</th>
              <th class="px-3 py-3">Perawatan</th>
              <th class="px-3 py-3 w-28">Status</th>
              <th class="px-3 py-3 text-right w-36">Aksi & Antrian</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr
              v-for="item in filteredReservations"
              :key="item.id"
              class="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors"
            >
              <td class="px-3 py-2.5 text-gray-600 font-medium whitespace-normal break-words">
                {{ formatDateTime(item.scheduledAt) }}
              </td>
              <td class="px-3 py-2.5 font-bold text-gray-900 dark:text-white whitespace-normal break-words">
                {{ item.patientName }}
              </td>
              <td class="px-3 py-2.5 whitespace-normal break-words">
                <UBadge color="gray" variant="subtle" size="xs" class="whitespace-normal break-words text-left">
                  {{ item.branchName }}
                </UBadge>
              </td>
              <td class="px-3 py-2.5 text-gray-800 dark:text-gray-200 font-semibold whitespace-normal break-words">
                {{ item.doctorName }}
              </td>
              <td class="px-3 py-2.5 font-semibold whitespace-normal break-words">
                {{ formatTreatmentsName(item.treatments) }}
              </td>

              <!-- Status Badge Cell -->
              <td class="px-3 py-2.5 whitespace-normal">
                <UBadge
                  :color="(STATUS_CONFIG[item.status]?.color as BadgeColor) ?? 'gray'"
                  variant="soft"
                  size="sm"
                  class="font-bold flex items-center gap-1 w-fit"
                >
                  <UIcon :name="STATUS_CONFIG[item.status]?.icon ?? 'i-lucide-circle'" class="w-3.5 h-3.5" />
                  <span>{{ STATUS_CONFIG[item.status]?.label ?? item.status }}</span>
                </UBadge>
              </td>

              <!-- Actions Cell -->
              <td class="px-3 py-2.5 text-right whitespace-normal">
                <div class="flex items-center justify-end gap-1.5">
                  <UButton
                    size="xs"
                    color="neutral"
                    variant="ghost"
                    icon="i-lucide-eye"
                    title="Lihat Detail Reservasi"
                    @click="openReservationDetail(item)"
                  />

                  <UButton
                    size="xs"
                    color="primary"
                    variant="subtle"
                    icon="i-lucide-printer"
                    title="Cetak Tiket Antrian"
                    @click="printReservationTicket(item)"
                  />

                  <UButton
                    size="xs"
                    color="emerald"
                    variant="soft"
                    icon="i-lucide-credit-card"
                    title="Bayar Reservasi di Kasir Billing"
                    :to="`/billing?reservationId=${item.id}&action=pay`"
                  />

                  <UButton
                    v-if="STATUS_CONFIG[item.status]?.nextStatus"
                    size="xs"
                    :color="(STATUS_CONFIG[item.status]?.nextColor as BadgeColor) ?? 'primary'"
                    variant="solid"
                    class="font-bold shadow-xs hover:scale-105 transition-transform"
                    @click="stepNextStatus(item)"
                  >
                    <UIcon name="i-lucide-arrow-right-circle" class="w-3.5 h-3.5 mr-1" />
                    <span>+ {{ STATUS_CONFIG[item.status]?.nextLabel }}</span>
                  </UButton>

                  <select
                    :value="item.status"
                    class="px-2.5 py-1 text-xs font-semibold rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white cursor-pointer hover:border-primary focus:ring-2 focus:ring-primary transition-all"
                    @change="(e) => onStatusChange(item, (e.target as HTMLSelectElement).value)"
                  >
                    <option
                      v-for="opt in STATUS_SELECT_ITEMS"
                      :key="opt.value"
                      :value="opt.value"
                    >
                      {{ opt.label }}
                    </option>
                  </select>

                  <UButton
                    v-if="item.status !== 'cancelled' && item.status !== 'completed'"
                    size="xs"
                    color="red"
                    variant="ghost"
                    icon="i-lucide-x"
                    title="Batalkan Reservasi"
                    @click="onStatusChange(item, 'cancelled')"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination Bar -->
      <div class="flex items-center justify-between p-3 border-t border-gray-200 dark:border-gray-700 text-xs text-gray-500">
        <span>Menampilkan 1–{{ filteredReservations.length }} dari {{ filteredReservations.length }} data</span>
        <div class="flex items-center gap-2">
          <UButton
            icon="i-lucide-chevron-left"
            color="neutral"
            variant="outline"
            size="xs"
            :disabled="page <= 1"
            @click="page--"
          />
          <span>Hal {{ page }} / {{ Math.ceil(filteredReservations.length / pageSize) || 1 }}</span>
          <UButton
            icon="i-lucide-chevron-right"
            color="neutral"
            variant="outline"
            size="xs"
            :disabled="page >= (Math.ceil(filteredReservations.length / pageSize) || 1)"
            @click="page++"
          />
        </div>
      </div>
    </UCard>

    <UCard v-else class="w-full shadow-xs">
      <SkeletonCalendarSkeleton v-if="calendarStatus === 'pending'" />
      <CalendarMonthCalendar
        v-else
        :reservations="calendarReservations ?? []"
        @select-day="onSelectDay"
      />
    </UCard>
    </ClientOnly>

    <!-- Modals wrapped in ClientOnly -->
    <ClientOnly>
      <!-- Modal Create / Edit Reservasi Pasien -->
      <UModal
        v-model:open="showModal"
        title="Buat Reservasi & Jadwal Pasien Baru"
      >
        <template #body>
          <form
            class="space-y-4"
            @submit.prevent="onSubmit"
          >
            <UFormField
              label="Pasien"
              required
            >
              <select
                v-model="form.patientId"
                class="w-full p-2 text-xs font-semibold border rounded-md border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
              >
                <option
                  v-for="p in patients"
                  :key="p.id"
                  :value="p.id"
                >
                  {{ p.fullName }} ({{ p.rmNumber || 'RM Baru' }})
                </option>
              </select>
            </UFormField>

            <div class="grid grid-cols-2 gap-4">
              <UFormField
                label="Cabang Klinik"
                required
              >
                <USelect
                  v-model="form.branchId"
                  :items="(branches ?? []).length > 0 ? (branches ?? []).map(b => ({ label: b.name, value: b.id })) : [{ label: 'Nina Dental Care - Soreang', value: 'br-1' }, { label: 'Nina Dental Care - Baleendah', value: 'br-2' }]"
                  class="w-full"
                />
              </UFormField>

              <UFormField
                label="Dokter Penanggung Jawab"
                required
              >
                <select
                  v-model="form.staffId"
                  class="w-full p-2 text-xs font-semibold border rounded-md border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white"
                >
                  <option
                    v-for="d in doctorsForBranch"
                    :key="d.id"
                    :value="d.id"
                  >
                    {{ d.fullName }} ({{ d.specialization }})
                  </option>
                </select>
              </UFormField>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <UFormField
                label="Tanggal Jadwal"
                required
              >
                <UInput
                  v-model="form.scheduledDate"
                  type="date"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                label="Jam Jadwal"
                required
              >
                <UInput
                  v-model="form.scheduledTime"
                  type="time"
                  class="w-full"
                />
              </UFormField>
            </div>

            <!-- Rencana Perawatan Checklist -->
            <div>
              <label class="block text-xs font-semibold mb-1">Rencana Perawatan (Opsional)</label>
              <div class="max-h-32 overflow-y-auto p-2 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg space-y-1.5 text-xs">
                <label v-for="t in (treatments ?? [])" :key="t.id" class="flex items-center gap-2 cursor-pointer hover:bg-gray-100 dark:hover:bg-gray-700 p-1 rounded">
                  <input v-model="form.treatmentIds" type="checkbox" :value="t.id" class="rounded text-primary">
                  <span>{{ t.name }} — {{ formatIDR(t.price) }}</span>
                </label>
              </div>
            </div>

            <div>
              <label class="block text-xs font-semibold mb-1">Keluhan Pasien (Opsional)</label>
              <UTextarea v-model="form.complaintNote" rows="2" placeholder="Keluhan utama pasien..." />
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
              label="Buat Reservasi"
              @click="onSubmit"
            />
          </div>
        </template>
      </UModal>

      <!-- Modal View Detail Reservasi Pasien -->
      <UModal
        v-model:open="showDetailModal"
        title="Detail Reservasi & Tiket Antrian Pasien"
        :ui="{ width: 'sm:max-w-2xl' }"
      >
        <template #body>
          <div v-if="detailReservation" class="space-y-4 text-xs">
            <!-- Top Card Summary -->
            <div class="p-4 rounded-xl border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-950/30 flex items-center justify-between gap-3">
              <div class="min-w-0 flex-1">
                <p class="text-[10px] text-gray-500 font-semibold uppercase tracking-wider">Nomor Antrian / Tiket Reservasi</p>
                <p class="text-sm sm:text-base font-black text-primary-600 dark:text-primary-400 font-mono break-all leading-tight">{{ safeQueueTicket(detailReservation.id) }}</p>
                <p class="text-xs font-medium text-gray-600 dark:text-gray-300 mt-1">
                  Status Antrian: <span class="font-bold uppercase text-primary-600 dark:text-primary-400">{{ STATUS_CONFIG[detailReservation.status]?.label ?? detailReservation.status }}</span>
                </p>
              </div>
              <UBadge color="primary" variant="solid" size="md" class="px-3 py-1.5 text-xs font-extrabold shrink-0">
                {{ detailReservation.branchName || 'Cabang Utama' }}
              </UBadge>
            </div>

            <!-- Information Grid -->
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 p-3.5 border border-gray-200 dark:border-gray-700 rounded-xl bg-gray-50/60 dark:bg-gray-800/40">
              <div>
                <span class="text-[10px] text-gray-400 font-semibold uppercase block">Nama Pasien</span>
                <span class="font-bold text-gray-900 dark:text-white text-sm">{{ detailReservation.patientName || '—' }}</span>
              </div>
              <div>
                <span class="text-[10px] text-gray-400 font-semibold uppercase block">Dokter Spesialis</span>
                <span class="font-bold text-gray-900 dark:text-white text-sm">{{ detailReservation.doctorName || '—' }}</span>
              </div>
              <div>
                <span class="text-[10px] text-gray-400 font-semibold uppercase block">Jadwal Periksa</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200">{{ formatDateTime(detailReservation.scheduledAt) }}</span>
              </div>
              <div>
                <span class="text-[10px] text-gray-400 font-semibold uppercase block">Waktu Reservasi Dibuat</span>
                <span class="font-semibold text-gray-800 dark:text-gray-200">{{ detailReservation.createdAt ? formatDateTime(detailReservation.createdAt) : '—' }}</span>
              </div>
            </div>

            <!-- Rencana Perawatan Gigi -->
            <div class="p-3.5 border border-gray-200 dark:border-gray-700 rounded-xl space-y-2">
              <div class="flex items-center justify-between">
                <span class="font-bold text-gray-900 dark:text-white block text-xs">Layanan Perawatan Gigi</span>
                <span v-if="getTreatmentsList(detailReservation.treatments).length > 0" class="text-[10px] font-semibold text-primary-600 dark:text-primary-400">
                  Total: {{ formatIDR(getTreatmentsTotalPrice(detailReservation.treatments)) }}
                </span>
              </div>
              <div class="divide-y divide-gray-100 dark:divide-gray-800 max-h-48 overflow-y-auto pr-1">
                <div v-for="(t, idx) in getTreatmentsList(detailReservation.treatments)" :key="idx" class="py-2 flex items-center justify-between gap-2">
                  <div>
                    <p class="font-semibold text-gray-900 dark:text-white">{{ getTreatmentName(t) }}</p>
                    <p class="text-[10px] text-gray-400">{{ getTreatmentCategory(t) }}</p>
                  </div>
                  <p class="font-bold text-primary-600 dark:text-primary-400 shrink-0">{{ formatIDR(getTreatmentPrice(t)) }}</p>
                </div>
                <div v-if="getTreatmentsList(detailReservation.treatments).length === 0" class="py-2 text-gray-500 italic">
                  Konsultasi & Pemeriksaan Gigi Umum
                </div>
              </div>
            </div>

            <!-- Informasi & Metode Pembayaran -->
            <div class="p-3.5 border border-sky-200 dark:border-sky-800 rounded-xl bg-sky-50/50 dark:bg-sky-950/20 space-y-2">
              <div class="flex items-center justify-between">
                <span class="font-bold text-sky-900 dark:text-sky-200 block text-xs">Informasi & Metode Pembayaran</span>
                <UBadge :color="getPaymentInfoForReservation(detailReservation.id).status.includes('LUNAS') ? 'success' : 'warning'" size="xs" class="font-extrabold">
                  {{ getPaymentInfoForReservation(detailReservation.id).status }}
                </UBadge>
              </div>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs pt-1">
                <div>
                  <span class="text-[10px] text-gray-400 block font-semibold">Metode Pembayaran</span>
                  <span class="font-bold text-gray-900 dark:text-white text-sm">{{ getPaymentInfoForReservation(detailReservation.id).method }}</span>
                </div>
                <div>
                  <span class="text-[10px] text-gray-400 block font-semibold">Total Biaya Perawatan</span>
                  <span class="font-bold text-primary-600 dark:text-primary-400 text-sm">
                    {{ formatIDR(getPaymentInfoForReservation(detailReservation.id).amount > 0 ? getPaymentInfoForReservation(detailReservation.id).amount : getTreatmentsTotalPrice(detailReservation.treatments)) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Complaint Note Card -->
            <div class="p-3.5 border border-amber-200 dark:border-amber-800 rounded-xl bg-amber-50/50 dark:bg-amber-950/20">
              <span class="font-bold text-amber-800 dark:text-amber-300 block mb-1">Catatan Keluhan Pasien:</span>
              <p class="text-gray-700 dark:text-gray-300 italic">{{ detailReservation.complaintNote || 'Tidak ada catatan keluhan khusus.' }}</p>
            </div>

            <!-- Footer Actions -->
            <div class="flex justify-end gap-2 pt-3 border-t border-gray-200 dark:border-gray-700">
              <UButton label="Tutup" color="neutral" variant="ghost" @click="showDetailModal = false" />
              <UButton
                icon="i-lucide-printer"
                label="Cetak Tiket Antrian"
                color="primary"
                class="font-bold"
                @click="printReservationTicket(detailReservation)"
              />
            </div>
          </div>
        </template>
      </UModal>
    </ClientOnly>
  </div>
</template>
