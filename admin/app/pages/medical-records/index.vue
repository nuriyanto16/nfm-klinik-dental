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

const { followUpList, markAsReminded, updateFollowUpStatus, addFollowUp, getWhatsAppLink } = useFollowUpPatients()

const showFollowUpModal = ref(false)
const followUpForm = reactive({
  patientId: '',
  patientName: '',
  rmNumber: '',
  phoneWa: '',
  treatmentName: 'Scaling & Pembersihan Karang Gigi',
  doctorName: 'drg. Friski Raisis, Sp.Ort',
  branchName: 'Soreang',
  recommendedControlDate: new Date(Date.now() + 14 * 86400000).toISOString().slice(0, 10),
  controlReason: 'Evaluasi & Kontrol Rutin'
})

function openAddFollowUp() {
  if (patients.value && patients.value.length > 0) {
    const firstPat = patients.value[0]
    followUpForm.patientId = firstPat.id
    followUpForm.patientName = firstPat.fullName
    followUpForm.rmNumber = firstPat.rmNumber || 'RM-2026-001'
    followUpForm.phoneWa = firstPat.phoneWa || '08123456789'
  }
  showFollowUpModal.value = true
}

function saveNewFollowUp() {
  if (!followUpForm.patientName) return
  const selPat = (patients.value ?? []).find(p => p.id === followUpForm.patientId)
  addFollowUp({
    patientId: followUpForm.patientId,
    patientName: selPat?.fullName || followUpForm.patientName,
    rmNumber: selPat?.rmNumber || followUpForm.rmNumber,
    phoneWa: selPat?.phoneWa || followUpForm.phoneWa,
    lastVisitDate: new Date().toISOString().slice(0, 10),
    recommendedControlDate: followUpForm.recommendedControlDate,
    daysRemaining: 14,
    treatmentName: followUpForm.treatmentName,
    doctorName: followUpForm.doctorName,
    branchName: followUpForm.branchName,
    controlReason: followUpForm.controlReason,
    status: 'PENDING'
  })
  useAppNotification().success('Jadwal follow-up kontrol berhasil ditambahkan.')
  showFollowUpModal.value = false
}

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
  { label: 'Bleaching', value: 'bleaching' },
  { label: 'Impaksi', value: 'impaction' }
]

const CONDITION_LABEL_MAP: Record<string, string> = {
  healthy: 'Sehat',
  caries: 'Karies',
  filled: 'Ditambal',
  extracted: 'Dicabut',
  crown: 'Mahkota',
  bleaching: 'Bleaching',
  impaction: 'Impaksi'
}

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
const activeTab = ref<'identitas' | 'riwayat' | 'vital' | 'soap' | 'odontogram'>('identitas')

const form = reactive({
  patientId: '',
  reservationId: '',
  staffId: '',
  
  // Section I & II: Identitas & Anamnesis
  nik: '',
  occupation: '',
  emergencyContact: '',
  chiefComplaint: '',
  presentIllnessHistory: '',
  
  // Section III: Riwayat Kesehatan Umum
  hasHypertension: false,
  hasHeartDisease: false,
  hasDiabetes: false,
  hasHepatitis: false,
  hasHiv: false,
  hasBleedingDisorder: false,
  drugAllergies: '',
  foodAllergies: '',
  isPregnant: false,
  routineMedications: '',

  // Section IV: Tanda Vital & Pemeriksaan Ekstra Oral
  vitalBloodPressure: '',
  vitalPulse: '',
  vitalTemperature: '',
  extraOralExam: '',

  // Section V & VI: SOAP, Resep & Tindakan
  toothNumber: '',
  soapS: '',
  soapO: '',
  diagnosis: '',
  soapP: '',
  prescription: '',
  treatmentNotes: '',

  odontogram: [] as OdontogramFormRow[],
  itemsUsed: [] as ItemUsageFormRow[]
})

const selectedPatient = computed(() => {
  if (!form.patientId) return null
  return (patients.value ?? []).find(p => p.id === form.patientId)
})

const selectedDoctor = computed(() => {
  if (!form.staffId) return null
  return (doctorsAdmin.value ?? []).find(d => d.id === form.staffId)
})

watch(() => form.patientId, (newId) => {
  if (!newId) return
  const p = (patients.value ?? []).find(pt => pt.id === newId)
  if (p) {
    if (!editingId.value) {
      if (p.nik) form.nik = p.nik
      if (p.occupation) form.occupation = p.occupation
      if (p.emergencyContact) form.emergencyContact = p.emergencyContact
    }
  }
})

function openCreate() {
  editingId.value = null
  activeTab.value = 'identitas'
  form.patientId = patients.value?.[0]?.id ?? ''
  form.reservationId = ''
  form.staffId = doctorsAdmin.value?.[0]?.id ?? ''

  const selPatient = (patients.value ?? []).find(p => p.id === form.patientId)
  form.nik = selPatient?.nik || ''
  form.occupation = selPatient?.occupation || ''
  form.emergencyContact = selPatient?.emergencyContact || ''
  form.chiefComplaint = ''
  form.presentIllnessHistory = ''
  form.hasHypertension = false
  form.hasHeartDisease = false
  form.hasDiabetes = false
  form.hasHepatitis = false
  form.hasHiv = false
  form.hasBleedingDisorder = false
  form.drugAllergies = ''
  form.foodAllergies = ''
  form.isPregnant = false
  form.routineMedications = ''
  form.vitalBloodPressure = ''
  form.vitalPulse = ''
  form.vitalTemperature = ''
  form.extraOralExam = ''
  form.toothNumber = ''
  form.soapS = ''
  form.soapO = ''
  form.diagnosis = ''
  form.soapP = ''
  form.prescription = ''
  form.treatmentNotes = ''
  form.odontogram = []
  form.itemsUsed = []
  formError.value = ''
  showModal.value = true
}

async function openEdit(record: MedicalRecord) {
  editingId.value = record.id
  activeTab.value = 'identitas'
  form.patientId = record.patientId || patients.value?.[0]?.id || ''
  form.reservationId = record.reservationId || ''
  form.staffId = record.staffId || doctorsAdmin.value?.[0]?.id || ''
  form.diagnosis = record.diagnosis || ''
  form.treatmentNotes = record.treatmentNotes || ''
  form.nik = record.nik || ''
  form.occupation = record.occupation || ''
  form.emergencyContact = record.emergencyContact || ''
  form.chiefComplaint = record.chiefComplaint || ''
  form.presentIllnessHistory = record.presentIllnessHistory || ''
  form.hasHypertension = record.hasHypertension ?? false
  form.hasHeartDisease = record.hasHeartDisease ?? false
  form.hasDiabetes = record.hasDiabetes ?? false
  form.hasHepatitis = record.hasHepatitis ?? false
  form.hasHiv = record.hasHiv ?? false
  form.hasBleedingDisorder = record.hasBleedingDisorder ?? false
  form.drugAllergies = record.drugAllergies || ''
  form.foodAllergies = record.foodAllergies || ''
  form.isPregnant = record.isPregnant ?? false
  form.routineMedications = record.routineMedications || ''
  form.vitalBloodPressure = record.vitalBloodPressure || ''
  form.vitalPulse = record.vitalPulse || ''
  form.vitalTemperature = record.vitalTemperature || ''
  form.extraOralExam = record.extraOralExam || ''
  form.toothNumber = record.toothNumber || ''
  form.soapS = record.soapS || ''
  form.soapO = record.soapO || ''
  form.soapP = record.soapP || ''
  form.prescription = record.prescription || ''
  form.odontogram = record.odontogram || []
  form.itemsUsed = []
  formError.value = ''
  showModal.value = true

  try {
    const fullDetail = await apiGet<MedicalRecordDetail>(`/medical-records/${record.id}`)
    if (fullDetail) {
      form.patientId = fullDetail.patientId || form.patientId
      form.reservationId = fullDetail.reservationId || form.reservationId
      form.staffId = fullDetail.staffId || form.staffId
      form.diagnosis = fullDetail.diagnosis || form.diagnosis
      form.treatmentNotes = fullDetail.treatmentNotes || form.treatmentNotes
      form.nik = fullDetail.nik || form.nik
      form.occupation = fullDetail.occupation || form.occupation
      form.emergencyContact = fullDetail.emergencyContact || form.emergencyContact
      form.chiefComplaint = fullDetail.chiefComplaint || form.chiefComplaint
      form.presentIllnessHistory = fullDetail.presentIllnessHistory || form.presentIllnessHistory
      form.hasHypertension = fullDetail.hasHypertension ?? form.hasHypertension
      form.hasHeartDisease = fullDetail.hasHeartDisease ?? form.hasHeartDisease
      form.hasDiabetes = fullDetail.hasDiabetes ?? form.hasDiabetes
      form.hasHepatitis = fullDetail.hasHepatitis ?? form.hasHepatitis
      form.hasHiv = fullDetail.hasHiv ?? form.hasHiv
      form.hasBleedingDisorder = fullDetail.hasBleedingDisorder ?? form.hasBleedingDisorder
      form.drugAllergies = fullDetail.drugAllergies || form.drugAllergies
      form.foodAllergies = fullDetail.foodAllergies || form.foodAllergies
      form.isPregnant = fullDetail.isPregnant ?? form.isPregnant
      form.routineMedications = fullDetail.routineMedications || form.routineMedications
      form.vitalBloodPressure = fullDetail.vitalBloodPressure || form.vitalBloodPressure
      form.vitalPulse = fullDetail.vitalPulse || form.vitalPulse
      form.vitalTemperature = fullDetail.vitalTemperature || form.vitalTemperature
      form.extraOralExam = fullDetail.extraOralExam || form.extraOralExam
      form.toothNumber = fullDetail.toothNumber || form.toothNumber
      form.soapS = fullDetail.soapS || form.soapS
      form.soapO = fullDetail.soapO || form.soapO
      form.soapP = fullDetail.soapP || form.soapP
      form.prescription = fullDetail.prescription || form.prescription

      if (fullDetail.odontogram && fullDetail.odontogram.length > 0) {
        form.odontogram = fullDetail.odontogram.map(o => ({
          toothNumber: o.toothNumber,
          condition: o.condition,
          notes: o.notes || '',
          photoUrl: o.photoUrl || ''
        }))
      }
    }
  } catch (_) {}
}


async function deleteRecord(record: MedicalRecord) {
  if (!confirm(`Hapus rekam medis pasien ${record.patientName || ''}?`)) return
  try {
    await apiDelete(`/medical-records/${record.id}`)
    useAppNotification().success(
      `Rekam medis pasien ${record.patientName || ''} berhasil dihapus.`,
      'Rekam Medis Dihapus'
    )
  } catch (err: any) {
    useAppNotification().error(
      err?.data?.message ?? err?.message ?? 'Gagal menghapus rekam medis.',
      'Gagal Menghapus'
    )
  }
  await refresh()
}

function addOdontogramRow() {
  form.odontogram.push({ toothNumber: 11, condition: 'caries', notes: '', photoUrl: '' })
}
function removeOdontogramRow(i: number) {
  form.odontogram.splice(i, 1)
}

async function onSubmit() {
  if (!form.patientId || !form.staffId) {
    formError.value = 'Pasien dan Dokter Spesialis wajib dipilih.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    const payload: any = {
      patientId: form.patientId,
      reservationId: form.reservationId ? form.reservationId : null,
      staffId: form.staffId,
      diagnosis: form.diagnosis || null,
      treatmentNotes: form.treatmentNotes || null,
      nik: form.nik || null,
      occupation: form.occupation || null,
      emergencyContact: form.emergencyContact || null,
      chiefComplaint: form.chiefComplaint || null,
      presentIllnessHistory: form.presentIllnessHistory || null,
      hasHypertension: form.hasHypertension,
      hasHeartDisease: form.hasHeartDisease,
      hasDiabetes: form.hasDiabetes,
      hasHepatitis: form.hasHepatitis,
      hasHiv: form.hasHiv,
      hasBleedingDisorder: form.hasBleedingDisorder,
      drugAllergies: form.drugAllergies || null,
      foodAllergies: form.foodAllergies || null,
      isPregnant: form.isPregnant,
      routineMedications: form.routineMedications || null,
      vitalBloodPressure: form.vitalBloodPressure || null,
      vitalPulse: form.vitalPulse || null,
      vitalTemperature: form.vitalTemperature || null,
      extraOralExam: form.extraOralExam || null,
      toothNumber: form.toothNumber || null,
      soapS: form.soapS || null,
      soapO: form.soapO || null,
      soapP: form.soapP || null,
      prescription: form.prescription || null,
      odontogram: form.odontogram.map(o => ({ ...o, notes: o.notes || null, photoUrl: o.photoUrl || null })),
      itemsUsed: form.itemsUsed.map(u => ({ ...u, notes: u.notes || null }))
    }

    const patientName = selectedPatient.value?.fullName || 'Pasien'
    const doctorName = selectedDoctor.value?.fullName || 'Dokter Spesialis'

    if (editingId.value) {
      await apiPut(`/medical-records/${editingId.value}`, payload)
      try {
        await apiPost('/activity-logs', {
          scope: 'admin',
          category: 'medical',
          action: 'UPDATE_MEDICAL_RECORD',
          description: `Dokter memperbarui Rekam Medis & Odontogram pasien ${patientName}`,
          userName: doctorName,
          userRole: 'Dokter Spesialis',
          details: { diagnosis: form.diagnosis, toothNumber: form.toothNumber }
        })
      } catch (_) {}
    } else {
      await apiPost<MedicalRecord>('/medical-records', payload)
      try {
        await apiPost('/activity-logs', {
          scope: 'admin',
          category: 'medical',
          action: 'CREATE_MEDICAL_RECORD',
          description: `Dokter menginput Rekam Medis & Odontogram pasien baru ${patientName}`,
          userName: doctorName,
          userRole: 'Dokter Spesialis',
          details: { diagnosis: form.diagnosis, toothNumber: form.toothNumber }
        })
      } catch (_) {}
    }

    useAppNotification().success(
      `Data rekam medis pasien ${patientName} berhasil disimpan dengan aman.`,
      'Rekam Medis Disimpan'
    )

    showModal.value = false
    editingId.value = null
    await refresh()
  } catch (err: any) {
    formError.value = err?.data?.message ?? err?.message ?? 'Gagal menyimpan rekam medis. Periksa kelengkapan isian form.'
    useAppNotification().error(
      formError.value,
      'Gagal Menyimpan'
    )
  } finally {
    saving.value = false
  }
}


// --- Search, Filter & Pagination ---
const search = ref('')
const filterDoctor = ref('all')
const page = ref(1)
const pageSize = 10

const displayRecords = computed(() => {
  const base = records.value ?? []
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
  const win = window.open('', '_blank', 'width=900,height=1000')
  if (!win) return

  const pDate = record.createdAt ? new Date(record.createdAt) : new Date()
  const dateStr = pDate.toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' })

  const matchedPatient = (patients.value ?? []).find(p => 
    p.id === record.patientId || 
    (p.fullName && record.patientName && p.fullName.toLowerCase().trim() === record.patientName.toLowerCase().trim())
  )

  const patientName = record.patientName || matchedPatient?.fullName || 'Pasien'
  const rmNum = record.rmNumber || (record as any).rmNum || matchedPatient?.rmNumber || 'RM-2026-08-0042'
  const gender = ((record as any).gender || matchedPatient?.gender || 'male') === 'female' ? 'Perempuan (P)' : 'Laki-laki (L)'
  
  let dobStr = '-'
  let ageStr = '-'
  let cityStr = matchedPatient?.city || (record as any).city || 'Bandung'
  
  const rawDob = matchedPatient?.dateOfBirth || (record as any).dateOfBirth
  if (rawDob) {
    const dobDate = new Date(rawDob)
    if (!isNaN(dobDate.getTime())) {
      dobStr = dobDate.toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' })
      const ageDiffMs = Date.now() - dobDate.getTime()
      const ageDate = new Date(ageDiffMs)
      const calculatedAge = Math.abs(ageDate.getUTCFullYear() - 1970)
      ageStr = `${calculatedAge} Tahun`
    }
  }

  const nik = (record as any).nik || matchedPatient?.nik || '-'
  const addressStr = (record as any).address || matchedPatient?.address || 'Kab. Bandung, Jawa Barat'
  const phoneStr = (record as any).phoneWa || matchedPatient?.phoneWa || '-'
  const occupation = (record as any).occupation || matchedPatient?.occupation || '-'
  const emergencyContact = (record as any).emergencyContact || matchedPatient?.emergencyContact || '-'

  const chiefComplaint = (record as any).chiefComplaint || (record as any).soapS || 'Pemeriksaan dan perawatan rutin kesehatan gigi'
  const presentIllness = (record as any).presentIllnessHistory || 'Nyeri timbul saat terkena rangsangan makanan manis/dingin'

  const hasHypertension = (record as any).hasHypertension ? '✓' : '—'
  const hasHeartDisease = (record as any).hasHeartDisease ? '✓' : '—'
  const hasDiabetes = (record as any).hasDiabetes ? '✓' : '—'
  const hasHepatitis = (record as any).hasHepatitis ? '✓' : '—'
  const hasHiv = (record as any).hasHiv ? '✓' : '—'
  const hasBleedingDisorder = (record as any).hasBleedingDisorder ? '✓' : '—'
  const isPregnant = (record as any).isPregnant ? '✓' : '—'

  const drugAllergiesRaw = (record as any).drugAllergies || ''
  const foodAllergiesRaw = (record as any).foodAllergies || ''
  const routineMedicationsRaw = (record as any).routineMedications || ''

  const drugAllergies = drugAllergiesRaw || 'Tidak Ada'
  const foodAllergies = foodAllergiesRaw || 'Tidak Ada'
  const routineMedications = routineMedicationsRaw || 'Tidak Ada'

  const vitalBP = (record as any).vitalBloodPressure || '120/80 mmHg'
  const vitalPulse = (record as any).vitalPulse || '80 x/menit'
  const vitalTemp = (record as any).vitalTemperature || '36.5 °C'
  const extraOralExam = (record as any).extraOralExam || 'Wajah simetris, kelenjar getah bening tidak teraba membesar, TMJ normal'

  const diagnosisText = record.diagnosis || 'Karies Dentis & Pulpitis Reversibel'
  const treatmentNotesText = record.treatmentNotes || 'Preparasi kavitas, pembersihan karies, aplikasi bonding & penumpatan komposit resin estetis'
  const doctorName = record.doctorName || 'drg. Nina Marlina, Sp.KG'

  let toothNum = (record as any).toothNumber || '46'
  let soapSubjective = (record as any).soapS || chiefComplaint
  let soapObjective = (record as any).soapO || 'Terdapat kavitas pada oklusal gigi, perkusi (-), palpasi (-), sonde (+)'
  let soapAssessment = diagnosisText
  let soapPlan = (record as any).soapP || 'Restorasi komposit resin sinar (light-cured) + edukasi OH'
  let prescription = (record as any).prescription || 'Rx: Asam Mefenamat 500mg No. X (3x1 prn), Amoxicillin 500mg No. XV (3x1)'

  const odontogramMap: Record<number, { condition: string, notes?: string }> = {}
  if ((record as any).odontogram && Array.isArray((record as any).odontogram) && (record as any).odontogram.length > 0) {
    const oList = (record as any).odontogram
    toothNum = oList.map((o: any) => o.toothNumber).join(', ')
    oList.forEach((o: any) => {
      odontogramMap[Number(o.toothNumber)] = {
        condition: o.condition,
        notes: o.notes
      }
    })
  } else if ((record as any).toothNumber) {
    const tNum = parseInt((record as any).toothNumber, 10)
    if (!isNaN(tNum)) {
      odontogramMap[tNum] = { condition: 'caries', notes: 'Gigi utama tindakan' }
    }
  }

  // FDI 2-digit teeth matrix quadrants
  const q1 = [18, 17, 16, 15, 14, 13, 12, 11]
  const q2 = [21, 22, 23, 24, 25, 26, 27, 28]
  const q4 = [48, 47, 46, 45, 44, 43, 42, 41]
  const q3 = [31, 32, 33, 34, 35, 36, 37, 38]

  function getToothCellHtml(tNum: number) {
    const data = odontogramMap[tNum]
    if (!data) {
      return `<div class="tooth-cell"><span class="t-num">${tNum}</span><span class="t-badge bg-healthy">H</span></div>`
    }
    const c = data.condition.toLowerCase()
    let bgClass = 'bg-healthy'
    let code = 'H'
    if (c.includes('caries') || c.includes('karies')) { bgClass = 'bg-caries'; code = 'C'; }
    else if (c.includes('fill') || c.includes('tambal')) { bgClass = 'bg-filled'; code = 'F'; }
    else if (c.includes('extract') || c.includes('cabut')) { bgClass = 'bg-extracted'; code = 'X'; }
    else if (c.includes('crown') || c.includes('mahkota')) { bgClass = 'bg-crown'; code = 'Cr'; }
    else if (c.includes('bleach')) { bgClass = 'bg-bleach'; code = 'B'; }
    else if (c.includes('impac') || c.includes('impaksi')) { bgClass = 'bg-impaction'; code = 'I'; }
    return `<div class="tooth-cell highlighted"><span class="t-num">${tNum}</span><span class="t-badge ${bgClass}">${code}</span></div>`
  }

  win.document.write(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
      <meta charset="UTF-8">
      <title>REKAM MEDIS PASIEN - ${patientName} (${rmNum})</title>
      <style>
        @page { size: A4 portrait; margin: 12mm 14mm; }
        * { box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif; font-size: 9.5pt; line-height: 1.4; color: #111827; margin: 0; padding: 10px; background: #fff; }
        
        /* KOP KLINIK */
        .kop { display: flex; align-items: center; justify-content: space-between; border-bottom: 2.5px solid #1d4ed8; padding-bottom: 8px; margin-bottom: 12px; }
        .kop-brand h1 { margin: 0; font-size: 17pt; font-weight: 800; color: #1e40af; letter-spacing: 0.5px; }
        .kop-brand p { margin: 1px 0 0; font-size: 8.5pt; color: #4b5563; }
        .kop-meta { text-align: right; }
        .doc-tag { display: inline-block; background: #eff6ff; color: #1d4ed8; font-weight: 800; font-size: 9.5pt; padding: 3px 10px; border-radius: 4px; border: 1px solid #bfdbfe; text-transform: uppercase; }
        .rm-badge { margin-top: 3px; font-family: monospace; font-size: 11pt; font-weight: 800; color: #111827; }
        
        /* SECTION TITLES */
        .sec-title { font-size: 9pt; font-weight: 700; color: #1e3a8a; background: #f0fdf4; border-left: 3.5px solid #059669; padding: 3px 8px; margin-top: 10px; margin-bottom: 6px; text-transform: uppercase; letter-spacing: 0.4px; }
        
        /* TABLES */
        .grid-table { width: 100%; border-collapse: collapse; margin-bottom: 6px; }
        .grid-table td { padding: 3px 6px; font-size: 8.5pt; vertical-align: top; }
        .label-col { width: 18%; color: #4b5563; font-weight: 600; }
        .sep-col { width: 2%; color: #9ca3af; text-align: center; }
        .val-col { width: 30%; color: #111827; font-weight: 500; }
        
        /* CHECKLIST */
        .check-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; background: #f9fafb; padding: 6px 8px; border: 1px solid #e5e7eb; border-radius: 5px; font-size: 8pt; margin-bottom: 6px; }
        .check-item { display: flex; items-center; gap: 4px; }
        .check-sym { font-weight: 800; color: #dc2626; }
        
        /* ODONTOGRAM MATRIX */
        .odonto-box { border: 1px solid #d1d5db; border-radius: 6px; background: #fafafa; padding: 8px; margin-bottom: 8px; }
        .odonto-row { display: flex; justify-content: center; align-items: center; gap: 3px; margin-bottom: 4px; }
        .odonto-divider { width: 2px; height: 32px; background: #2563eb; margin: 0 6px; }
        .odonto-h-divider { border-top: 1.5px dashed #9ca3af; width: 90%; margin: 4px auto; }
        .tooth-cell { width: 34px; height: 32px; border: 1px solid #e5e7eb; background: #fff; border-radius: 4px; display: flex; flex-direction: column; align-items: center; justify-content: center; font-family: monospace; font-size: 7.5pt; }
        .tooth-cell.highlighted { border: 1.5px solid #2563eb; background: #eff6ff; }
        .t-num { font-weight: 700; color: #1f2937; }
        .t-badge { font-size: 6.5pt; font-weight: 800; padding: 0 2px; border-radius: 2px; }
        .bg-healthy { background: #dcfce7; color: #15803d; }
        .bg-caries { background: #fee2e2; color: #b91c1c; }
        .bg-filled { background: #dbeafe; color: #1d4ed8; }
        .bg-extracted { background: #f3f4f6; color: #6b7280; text-decoration: line-through; }
        .bg-crown { background: #fef3c7; color: #b45309; }
        .bg-bleach { background: #ede9fe; color: #6d28d9; }
        .bg-impaction { background: #ffedd5; color: #c2410c; }
        .odonto-legend { display: flex; justify-content: center; gap: 8px; font-size: 7pt; margin-top: 4px; color: #4b5563; }
        
        /* CLINICAL SOAP TABLE */
        .soap-table { width: 100%; border-collapse: collapse; margin-top: 4px; margin-bottom: 8px; }
        .soap-table th, .soap-table td { border: 1px solid #d1d5db; padding: 6px 8px; font-size: 8.5pt; vertical-align: top; }
        .soap-table th { background: #f3f4f6; font-weight: 700; color: #374151; }
        
        /* SIGNATURE BOX */
        .sign-wrapper { display: flex; justify-content: space-between; margin-top: 18px; padding-top: 6px; }
        .sign-box { width: 220px; text-align: center; font-size: 8.5pt; }
        .sign-line { height: 50px; }
        .sign-name { font-weight: 700; border-bottom: 1px solid #111827; padding-bottom: 2px; }
      </style>
    </head>
    <body>
      <!-- KOP KLINIK -->
      <div class="kop">
        <div class="kop-brand">
          <h1>NINA DENTAL CARE</h1>
          <p>Klinik Dokter Gigi Spesialis & Layanan Gigi Terpadu</p>
          <p>Cabang Soreang & Baleendah, Kab. Bandung | Telp/WA: 0812-3400-0002</p>
        </div>
        <div class="kop-meta">
          <div class="doc-tag">REKAM MEDIS PASIEN GIGI</div>
          <div class="rm-badge">NO. RM: ${rmNum}</div>
          <p style="margin:2px 0 0; font-size:8pt; color:#6b7280;">Tanggal: ${dateStr}</p>
        </div>
      </div>

      <!-- I. IDENTITAS PASIEN -->
      <div class="sec-title">I. IDENTITAS PASIEN</div>
      <table class="grid-table">
        <tr>
          <td class="label-col">Nama Pasien</td><td class="sep-col">:</td><td class="val-col"><b>${patientName}</b></td>
          <td class="label-col">No. Identitas (KTP/NIK)</td><td class="sep-col">:</td><td class="val-col">${nik}</td>
        </tr>
        <tr>
          <td class="label-col">Tempat / Tgl Lahir</td><td class="sep-col">:</td><td class="val-col">${cityStr}, ${dobStr}</td>
          <td class="label-col">Usia / Jenis Kelamin</td><td class="sep-col">:</td><td class="val-col">${ageStr} / ${gender}</td>
        </tr>
        <tr>
          <td class="label-col">Alamat Domisili</td><td class="sep-col">:</td><td class="val-col">${addressStr}</td>
          <td class="label-col">No. Telepon / WhatsApp</td><td class="sep-col">:</td><td class="val-col">${phoneStr}</td>
        </tr>
        <tr>
          <td class="label-col">Pekerjaan</td><td class="sep-col">:</td><td class="val-col">${occupation}</td>
          <td class="label-col">Kontak Darurat</td><td class="sep-col">:</td><td class="val-col">${emergencyContact}</td>
        </tr>
      </table>

      <!-- II. ANAMNESIS & RIWAYAT KESEHATAN UMUM -->
      <div class="sec-title">II. ANAMNESIS & RIWAYAT KESEHATAN UMUM</div>
      <table class="grid-table" style="margin-bottom: 4px;">
        <tr>
          <td class="label-col">Keluhan Utama</td><td class="sep-col">:</td>
          <td colspan="4"><b>${chiefComplaint}</b></td>
        </tr>
        <tr>
          <td class="label-col">Riwayat Penyakit Sekarang</td><td class="sep-col">:</td>
          <td colspan="4">${presentIllness}</td>
        </tr>
      </table>

      <div class="check-grid">
        <div class="check-item"><span class="check-sym">[${hasHypertension}]</span> Hipertensi</div>
        <div class="check-item"><span class="check-sym">[${hasHeartDisease}]</span> Jantung</div>
        <div class="check-item"><span class="check-sym">[${hasDiabetes}]</span> Diabetes Melitus</div>
        <div class="check-item"><span class="check-sym">[${hasHepatitis}]</span> Hepatitis</div>
        <div class="check-item"><span class="check-sym">[${hasHiv}]</span> HIV / AIDS</div>
        <div class="check-item"><span class="check-sym">[${hasBleedingDisorder}]</span> Pembekuan Darah</div>
        <div class="check-item"><span class="check-sym">[${isPregnant}]</span> Sedang Hamil</div>
        <div class="check-item"><span class="check-sym">[—]</span> Asma / Pernapasan</div>
      </div>

      <table class="grid-table">
        <tr>
          <td class="label-col" style="width:18%;">Alergi Obat</td><td class="sep-col">:</td><td style="color:#b91c1c; font-weight:700;">${drugAllergies}</td>
          <td class="label-col" style="width:18%;">Alergi Makanan</td><td class="sep-col">:</td><td>${foodAllergies}</td>
        </tr>
        <tr>
          <td class="label-col">Obat Rutin Dikonsumsi</td><td class="sep-col">:</td><td colspan="4">${routineMedications}</td>
        </tr>
      </table>

      <!-- III. TANDA VITAL -->
      <div class="sec-title">III. PEMERIKSAAN FISIK & TANDA VITAL</div>
      <table class="grid-table">
        <tr>
          <td class="label-col">Tekanan Darah (TD)</td><td class="sep-col">:</td><td class="val-col"><b>${vitalBP}</b></td>
          <td class="label-col">Denyut Nadi</td><td class="sep-col">:</td><td class="val-col"><b>${vitalPulse}</b></td>
        </tr>
        <tr>
          <td class="label-col">Suhu Tubuh</td><td class="sep-col">:</td><td class="val-col"><b>${vitalTemp}</b></td>
          <td class="label-col">Pemeriksaan Ekstra Oral</td><td class="sep-col">:</td><td class="val-col">${extraOralExam}</td>
        </tr>
      </table>

      <!-- IV. ODONTOGRAM (FDI 2-DIGIT SYSTEM) -->
      <div class="sec-title">IV. ODONTOGRAM (STATUS 32 GIGI - FDI TWO-DIGIT MATRIX)</div>
      <div class="odonto-box">
        <!-- RAHANG ATAS -->
        <div style="font-size:7pt; color:#4b5563; text-align:center; font-weight:700; margin-bottom:2px;">RAHANG ATAS (MAXILLA) — KANAN | KIRI</div>
        <div class="odonto-row">
          ${q1.map(t => getToothCellHtml(t)).join('')}
          <div class="odonto-divider"></div>
          ${q2.map(t => getToothCellHtml(t)).join('')}
        </div>

        <div class="odonto-h-divider"></div>

        <!-- RAHANG BAWAH -->
        <div class="odonto-row">
          ${q4.map(t => getToothCellHtml(t)).join('')}
          <div class="odonto-divider"></div>
          ${q3.map(t => getToothCellHtml(t)).join('')}
        </div>
        <div style="font-size:7pt; color:#4b5563; text-align:center; font-weight:700; margin-top:2px;">RAHANG BAWAH (MANDIBULA) — KANAN | KIRI</div>

        <div class="odonto-legend">
          <span><span class="t-badge bg-healthy">H</span> Sehat</span>
          <span><span class="t-badge bg-caries">C</span> Karies</span>
          <span><span class="t-badge bg-filled">F</span> Ditambal</span>
          <span><span class="t-badge bg-extracted">X</span> Dicabut</span>
          <span><span class="t-badge bg-crown">Cr</span> Mahkota</span>
          <span><span class="t-badge bg-bleach">B</span> Bleaching</span>
          <span><span class="t-badge bg-impaction">I</span> Impaksi</span>
        </div>
      </div>

      <!-- V. SOAP & TINDAKAN KLINIS -->
      <div class="sec-title">V. CATATAN MEDIS SOAP, TINDAKAN & RESEP OBAT (Rx)</div>
      <table class="soap-table">
        <thead>
          <tr>
            <th style="width: 14%;">Elemen Gigi</th>
            <th style="width: 48%;">Catatan Klinis (S-O-A-P) & Resep (Rx)</th>
            <th style="width: 38%;">Tindakan Medis & Edukasi Pasien</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td style="text-align: center; font-weight: 800; font-size: 11pt; color: #1e40af;">
              Gigi #${toothNum}
            </td>
            <td>
              <div style="margin-bottom: 2px;"><b>S (Subjective):</b> ${soapSubjective}</div>
              <div style="margin-bottom: 2px;"><b>O (Objective):</b> ${soapObjective}</div>
              <div style="margin-bottom: 2px; color:#1d4ed8;"><b>A (Assessment / Diagnosis):</b> <b>${soapAssessment}</b></div>
              <div style="margin-bottom: 4px;"><b>P (Plan Terapi):</b> ${soapPlan}</div>
              <div style="background:#f0fdf4; border:1px solid #bbf7d0; padding:4px 6px; border-radius:4px; font-family:monospace; font-size:8pt; color:#166534;">
                <b>Resep Obat (Rx):</b><br>${prescription}
              </div>
            </td>
            <td>
              <div style="font-weight: 600; color: #111827; margin-bottom: 4px;">${treatmentNotesText}</div>
              <div style="margin-top: 6px; font-size: 8pt; color: #4b5563; background:#f9fafb; padding:4px; border-radius:4px;">
                <b>Anjuran Kontrol:</b> Evaluasi berkala dalam 14 - 30 hari ke depan. Menjaga kebersihan rongga mulut & sikat gigi 2x sehari.
              </div>
            </td>
          </tr>
        </tbody>
      </table>

      <!-- VI. TANDA TANGAN -->
      <div class="sign-wrapper">
        <div class="sign-box">
          <p>Pasien / Wali yang Menyetujui,</p>
          <div class="sign-line"></div>
          <div class="sign-name">${patientName}</div>
          <p style="margin:2px 0 0; font-size:7.5pt; color:#6b7280;">Tanda Tangan & Nama Terang</p>
        </div>
        <div class="sign-box">
          <p>Dokter Penanggung Jawab,</p>
          <div class="sign-line"></div>
          <div class="sign-name">${doctorName}</div>
          <p style="margin:2px 0 0; font-size:7.5pt; color:#6b7280;">SIP: 446.1/042-SIP-DRG/DISKES/2024</p>
        </div>
      </div>
    </body>
    </html>
  `)
  win.document.close()
  win.focus()
  setTimeout(() => { win.print() }, 350)
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
            class="bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700 shadow-xs w-full text-xs"
          >
            <template #createdAt-cell="{ row }">
              <span class="text-xs whitespace-normal break-words leading-tight block w-24">
                {{ formatDateTime(row.original.createdAt) }}
              </span>
            </template>
            <template #patientName-cell="{ row }">
              <div class="whitespace-normal break-words w-28">
                <span class="font-bold text-gray-900 dark:text-white block">{{ row.original.patientName }}</span>
                <span class="text-[10px] text-gray-400 font-mono block">{{ row.original.rmNumber || 'RM-2026-0001' }}</span>
              </div>
            </template>
            <template #doctorName-cell="{ row }">
              <span class="text-xs text-gray-700 dark:text-gray-300 whitespace-normal break-words leading-tight block w-32">
                {{ row.original.doctorName || 'drg. Nina' }}
              </span>
            </template>
            <template #diagnosis-cell="{ row }">
              <span class="text-xs text-gray-900 dark:text-white whitespace-normal break-words leading-normal block">
                {{ row.original.diagnosis ?? '—' }}
              </span>
            </template>
            <template #actions-cell="{ row }">
              <div class="flex items-center gap-1 shrink-0">
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

      <!-- Right Column: Patient Follow-Up Kontrol Cards -->
      <div class="lg:col-span-5 xl:col-span-4 space-y-4">
        <UCard class="shadow-xs">
          <template #header>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <UIcon name="i-lucide-calendar-clock" class="w-5 h-5 text-amber-600 dark:text-amber-400" />
                <h3 class="font-bold text-sm text-gray-900 dark:text-white">Follow-up Kontrol Berkelanjutan</h3>
              </div>
              <div class="flex items-center gap-1.5">
                <UButton
                  size="xs"
                  color="warning"
                  variant="subtle"
                  icon="i-lucide-plus"
                  label="+ Jadwal Kontrol"
                  @click="openAddFollowUp"
                />
              </div>
            </div>
          </template>

          <div class="space-y-3 divide-y divide-gray-100 dark:divide-gray-800">
            <div v-for="fu in followUpList" :key="fu.id" class="pt-3 first:pt-0 space-y-2">
              <div class="flex items-start justify-between">
                <div>
                  <h4 class="font-bold text-gray-900 dark:text-white text-xs">{{ fu.patientName }}</h4>
                  <p class="text-[10px] text-gray-400 font-mono">{{ fu.rmNumber }}</p>
                </div>
                <UBadge :color="fu.status === 'REMINDED' ? 'success' : 'warning'" size="xs" variant="soft">
                  {{ fu.status === 'REMINDED' ? 'Sudah Di-remind' : 'Jadwal Kontrol' }}
                </UBadge>
              </div>

              <div class="p-2 rounded-lg bg-gray-50 dark:bg-gray-800 text-[11px] space-y-1">
                <p class="text-gray-600 dark:text-gray-300 font-medium">Layanan: <span class="font-bold text-gray-900 dark:text-white">{{ fu.treatmentName }}</span></p>
                <p class="text-gray-500">Estimasi Kontrol: <span class="font-semibold text-amber-600 dark:text-amber-400">{{ safeDateShort(fu.recommendedControlDate) }}</span></p>
                <p v-if="fu.controlReason" class="text-[10px] text-gray-400 italic">Alasan: {{ fu.controlReason }}</p>
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

    <!-- Modal Tambah Follow-Up Kontrol -->
    <UModal v-model:open="showFollowUpModal" title="Tambah Jadwal Follow-Up Kontrol Pasien">
      <template #body>
        <form class="space-y-3 text-xs" @submit.prevent="saveNewFollowUp">
          <div>
            <label class="block font-semibold mb-1">Pilih Pasien *</label>
            <select
              v-model="followUpForm.patientId"
              class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800 font-semibold text-xs"
              required
              @change="() => {
                const sel = (patients ?? []).find(p => p.id === followUpForm.patientId)
                if (sel) {
                  followUpForm.patientName = sel.fullName
                  followUpForm.rmNumber = sel.rmNumber || 'RM-2026-001'
                  followUpForm.phoneWa = sel.phoneWa || '08123456789'
                }
              }"
            >
              <option value="" disabled>-- Pilih Pasien --</option>
              <option v-for="p in patients" :key="p.id" :value="p.id">
                {{ p.fullName }} ({{ p.rmNumber || 'RM Baru' }})
              </option>
            </select>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1">Dokter Penanggung Jawab</label>
              <select v-model="followUpForm.doctorName" class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800">
                <option v-for="d in doctorsAdmin" :key="d.id" :value="d.fullName">
                  {{ d.fullName }}
                </option>
              </select>
            </div>
            <div>
              <label class="block font-semibold mb-1">Cabang Klinik</label>
              <select v-model="followUpForm.branchName" class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800">
                <option value="Soreang">Soreang</option>
                <option value="Baleendah">Baleendah</option>
              </select>
            </div>
          </div>

          <div>
            <label class="block font-semibold mb-1">Jenis Perawatan Sebelumnya</label>
            <input v-model="followUpForm.treatmentName" type="text" class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800" required>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1">Tanggal Kontrol yang Direkomendasikan *</label>
              <input v-model="followUpForm.recommendedControlDate" type="date" class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800 font-semibold" required>
            </div>
            <div>
              <label class="block font-semibold mb-1">No. WhatsApp Pasien</label>
              <input v-model="followUpForm.phoneWa" type="text" class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800 font-mono">
            </div>
          </div>

          <div>
            <label class="block font-semibold mb-1">Alasan / Catatan Kontrol</label>
            <input v-model="followUpForm.controlReason" type="text" placeholder="Contoh: Evaluasi hasil bleaching & penyesuaian oklusi..." class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800">
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t">
            <UButton label="Batal" color="neutral" variant="ghost" @click="showFollowUpModal = false" />
            <UButton label="Simpan Jadwal Kontrol" color="primary" type="submit" />
          </div>
        </form>
      </template>
    </UModal>

    <!-- Modals wrapped in ClientOnly -->
    <ClientOnly>
      <!-- Modal Form Create/Edit Rekam Medis -->
      <UModal
        v-model:open="showModal"
        :title="editingId ? 'Edit Rekam Medis Pasien' : 'Form Input Rekam Medis Pasien Baru'"
        class="sm:max-w-5xl w-full max-w-5xl"
        :ui="{ width: 'sm:max-w-5xl max-w-5xl w-full', content: 'sm:max-w-5xl max-w-5xl w-full' }"
      >
        <template #body>
          <form class="space-y-4 text-xs" @submit.prevent="onSubmit">
            <UAlert v-if="formError" color="error" variant="soft" icon="i-lucide-alert-circle" :title="formError" />

            <!-- Form Tab Navigation -->
            <div class="flex items-center gap-1 border-b border-gray-200 dark:border-gray-700 overflow-x-auto pb-1">
              <button
                type="button"
                class="px-3 py-1.5 font-bold rounded-t-lg transition-colors"
                :class="activeTab === 'identitas' ? 'bg-primary text-white' : 'text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800'"
                @click="activeTab = 'identitas'"
              >
                I. Identitas & Anamnesis
              </button>
              <button
                type="button"
                class="px-3 py-1.5 font-bold rounded-t-lg transition-colors"
                :class="activeTab === 'riwayat' ? 'bg-primary text-white' : 'text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800'"
                @click="activeTab = 'riwayat'"
              >
                II. Riwayat Kesehatan
              </button>
              <button
                type="button"
                class="px-3 py-1.5 font-bold rounded-t-lg transition-colors"
                :class="activeTab === 'vital' ? 'bg-primary text-white' : 'text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800'"
                @click="activeTab = 'vital'"
              >
                III. Pemeriksaan Vital
              </button>
              <button
                type="button"
                class="px-3 py-1.5 font-bold rounded-t-lg transition-colors"
                :class="activeTab === 'soap' ? 'bg-primary text-white' : 'text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800'"
                @click="activeTab = 'soap'"
              >
                IV. Catatan SOAP & Resep
              </button>
              <button
                type="button"
                class="px-3 py-1.5 font-bold rounded-t-lg transition-colors"
                :class="activeTab === 'odontogram' ? 'bg-primary text-white' : 'text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-800'"
                @click="activeTab = 'odontogram'"
              >
                V. Odontogram
              </button>
            </div>

            <!-- TAB 1: IDENTITAS & ANAMNESIS -->
            <div v-if="activeTab === 'identitas'" class="space-y-3">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Pilih Pasien *</label>
                  <select
                    v-model="form.patientId"
                    class="w-full p-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-xs font-medium"
                    required
                  >
                    <option value="" disabled>-- Pilih Pasien --</option>
                    <option v-for="p in patients" :key="p.id" :value="p.id">
                      {{ p.fullName }} ({{ p.rmNumber || 'RM Baru' }})
                    </option>
                  </select>
                </div>
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Dokter Penanggung Jawab *</label>
                  <select
                    v-model="form.staffId"
                    class="w-full p-2 rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 text-xs font-medium"
                    required
                  >
                    <option value="" disabled>-- Pilih Dokter --</option>
                    <option v-for="d in doctorsAdmin" :key="d.id" :value="d.id">
                      {{ d.fullName }}
                    </option>
                  </select>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">No. KTP (NIK)</label>
                  <UInput v-model="form.nik" placeholder="3171011405920003" class="w-full" />
                </div>
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Pekerjaan</label>
                  <UInput v-model="form.occupation" placeholder="Karyawan Swasta" class="w-full" />
                </div>
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Kontak Darurat</label>
                <UInput v-model="form.emergencyContact" placeholder="Siska Putri (Istri) - 0812-9876-5432" class="w-full" />
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Keluhan Utama (Anamnesis)</label>
                <UTextarea v-model="form.chiefComplaint" rows="2" placeholder="Pasien mengeluhkan sakit berdenyut pada gigi..." class="w-full" />
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Riwayat Penyakit Sekarang</label>
                <UTextarea v-model="form.presentIllnessHistory" rows="2" placeholder="Nyeri timbul secara spontan tanpa rangsangan..." class="w-full" />
              </div>
            </div>

            <!-- TAB 2: RIWAYAT KESEHATAN UMUM -->
            <div v-if="activeTab === 'riwayat'" class="space-y-3">
              <div class="p-3 border rounded-xl bg-gray-50 dark:bg-gray-800 space-y-2">
                <span class="font-bold text-gray-900 dark:text-white block">Checklist Riwayat Penyakit Sistemik:</span>
                <div class="grid grid-cols-2 gap-2 text-xs">
                  <label class="flex items-center gap-2">
                    <input v-model="form.hasHypertension" type="checkbox" class="rounded"> Tekanan Darah Tinggi
                  </label>
                  <label class="flex items-center gap-2">
                    <input v-model="form.hasHeartDisease" type="checkbox" class="rounded"> Penyakit Jantung
                  </label>
                  <label class="flex items-center gap-2">
                    <input v-model="form.hasDiabetes" type="checkbox" class="rounded"> Diabetes / Kencing Manis
                  </label>
                  <label class="flex items-center gap-2">
                    <input v-model="form.hasHepatitis" type="checkbox" class="rounded"> Hepatitis / Penyakit Hati
                  </label>
                  <label class="flex items-center gap-2">
                    <input v-model="form.hasHiv" type="checkbox" class="rounded"> HIV / AIDS
                  </label>
                  <label class="flex items-center gap-2">
                    <input v-model="form.hasBleedingDisorder" type="checkbox" class="rounded"> Gangguan Pembekuan Darah
                  </label>
                  <label class="flex items-center gap-2">
                    <input v-model="form.isPregnant" type="checkbox" class="rounded"> Sedang Hamil (Bagi Wanita)
                  </label>
                </div>
              </div>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Alergi Obat</label>
                  <UInput v-model="form.drugAllergies" placeholder="Penicillin (Gatal-gatal)" class="w-full" />
                </div>
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Alergi Makanan</label>
                  <UInput v-model="form.foodAllergies" placeholder="Seafood, Telur..." class="w-full" />
                </div>
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Mengonsumsi Obat Rutin</label>
                <UInput v-model="form.routineMedications" placeholder="Amlodipine 5mg..." class="w-full" />
              </div>
            </div>

            <!-- TAB 3: PEMERIKSAAN VITAL -->
            <div v-if="activeTab === 'vital'" class="space-y-3">
              <div class="grid grid-cols-3 gap-3">
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Tekanan Darah (TD)</label>
                  <UInput v-model="form.vitalBloodPressure" placeholder="120 / 80 mmHg" class="w-full" />
                </div>
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Nadi</label>
                  <UInput v-model="form.vitalPulse" placeholder="82 x/menit" class="w-full" />
                </div>
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Suhu Tubuh</label>
                  <UInput v-model="form.vitalTemperature" placeholder="36.6 °C" class="w-full" />
                </div>
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Pemeriksaan Ekstra Oral</label>
                <UTextarea v-model="form.extraOralExam" rows="2" placeholder="Pipi simetris, tidak ada bengkak luar wajah..." class="w-full" />
              </div>
            </div>

            <!-- TAB 4: CATATAN SOAP & RESEP -->
            <div v-if="activeTab === 'soap'" class="space-y-3">
              <div class="grid grid-cols-2 gap-3">
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">No. Gigi Utama</label>
                  <UInput v-model="form.toothNumber" placeholder="46" class="w-full font-mono font-bold" />
                </div>
                <div>
                  <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">A - Assessment (Diagnosis)</label>
                  <UInput v-model="form.diagnosis" placeholder="Nekrosis pulpa gigi 46" class="w-full font-bold" />
                </div>
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">S - Subjective (Keluhan)</label>
                <UInput v-model="form.soapS" placeholder="Nyeri berdenyut spontan..." class="w-full" />
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">O - Objective (Hasil Periksa)</label>
                <UInput v-model="form.soapO" placeholder="Karies profunda, perkusi (+)..." class="w-full" />
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">P - Plan (Rencana Tindakan)</label>
                <UInput v-model="form.soapP" placeholder="Perawatan Saluran Akar (PSA) - Inisiasi" class="w-full" />
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Resep Obat (Rx)</label>
                <UInput v-model="form.prescription" placeholder="Rx: Amoxicillin 500mg No. XV (3x1)..." class="w-full font-mono text-xs" />
              </div>

              <div>
                <label class="block font-semibold text-gray-700 dark:text-gray-200 mb-1">Detail Prosedur & Tindakan Perawatan</label>
                <UTextarea v-model="form.treatmentNotes" rows="3" placeholder="Open access, ekstirpasi pulpa, irigasi NaOCl..." class="w-full" />
              </div>
            </div>

            <!-- TAB 5: ODONTOGRAM -->
            <div v-if="activeTab === 'odontogram'" class="space-y-3">
              <div class="p-3 border border-gray-200 dark:border-gray-700 rounded-xl bg-gray-50/70 dark:bg-gray-900/40 space-y-2.5">
                <div class="flex items-center justify-between">
                  <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5 text-xs">
                    <UIcon name="i-lucide-activity" class="w-4 h-4 text-primary" />
                    Baris Odontogram Status Gigi
                  </span>
                  <UButton size="xs" color="primary" variant="subtle" icon="i-lucide-plus" label="+ Tambah Gigi" @click="addOdontogramRow" />
                </div>

                <div v-for="(od, idx) in form.odontogram" :key="idx" class="grid grid-cols-12 gap-2 items-center bg-white dark:bg-gray-800 p-2 rounded-lg border border-gray-200 dark:border-gray-700 shadow-xs">
                  <div class="col-span-3">
                    <span class="text-[9px] text-gray-400 font-medium block">No. Gigi</span>
                    <input v-model.number="od.toothNumber" type="number" min="11" max="85" class="w-full p-1.5 border rounded-md font-mono text-xs bg-transparent">
                  </div>
                  <div class="col-span-4">
                    <span class="text-[9px] text-gray-400 font-medium block">Kondisi Gigi</span>
                    <select v-model="od.condition" class="w-full p-1.5 border rounded-md text-xs bg-transparent">
                      <option v-for="c in CONDITIONS" :key="c.value" :value="c.value">{{ c.label }}</option>
                    </select>
                  </div>
                  <div class="col-span-4">
                    <span class="text-[9px] text-gray-400 font-medium block">Catatan Gigi</span>
                    <input v-model="od.notes" type="text" placeholder="Detail..." class="w-full p-1.5 border rounded-md text-xs bg-transparent">
                  </div>
                  <div class="col-span-1 text-right">
                    <UButton icon="i-lucide-x" size="xs" color="error" variant="ghost" @click="removeOdontogramRow(idx)" />
                  </div>
                </div>
              </div>
            </div>

            <div class="flex justify-end gap-2 pt-3 border-t border-gray-200 dark:border-gray-700">
              <UButton label="Batal" color="neutral" variant="ghost" @click="showModal = false" />
              <UButton :label="editingId ? 'Simpan Perubahan' : 'Tambah Rekam Medis'" color="primary" type="submit" :loading="saving" />
            </div>
          </form>
        </template>
      </UModal>

      <!-- Detail slideover -->
      <USlideover
        v-model:open="showDetail"
        title="Detail Lengkap Rekam Medis Pasien"
        :ui="{ width: 'sm:max-w-xl' }"
      >
        <template #body>
          <div
            v-if="detail"
            class="space-y-4 text-xs pb-6"
          >
            <!-- Top Summary Header Card -->
            <div class="p-4 rounded-xl border border-primary-200 dark:border-primary-800 bg-primary-50/50 dark:bg-primary-950/30 space-y-2.5">
              <div class="flex items-center justify-between">
                <div>
                  <span class="text-[10px] uppercase font-bold text-gray-500 block">Nama Pasien</span>
                  <span class="font-bold text-gray-900 dark:text-white text-base flex items-center gap-1.5">
                    <UIcon name="i-lucide-user" class="w-4 h-4 text-primary" />
                    {{ detail.patientName }}
                  </span>
                </div>
                <UBadge color="primary" variant="solid" size="xs" class="font-mono font-bold">
                  {{ detail.rmNumber || '-' }}
                </UBadge>
              </div>

              <div class="grid grid-cols-2 gap-2 pt-2 border-t border-primary-200/60 dark:border-primary-800/60 text-[11px]">
                <div>
                  <span class="text-gray-500 block text-[10px] uppercase font-semibold">Dokter Penanggung Jawab</span>
                  <span class="font-bold text-gray-800 dark:text-gray-200">{{ detail.doctorName }}</span>
                </div>
                <div>
                  <span class="text-gray-500 block text-[10px] uppercase font-semibold">Tanggal Pemeriksaan</span>
                  <span class="font-semibold text-gray-700 dark:text-gray-300">{{ formatDateTime(detail.createdAt) }}</span>
                </div>
              </div>
            </div>

            <!-- I. IDENTITAS & ANAMNESIS -->
            <div class="p-3.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 space-y-2">
              <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5 text-xs">
                <UIcon name="i-lucide-id-card" class="w-4 h-4 text-primary" />
                I. Identitas & Anamnesis Pasien
              </span>
              
              <div class="grid grid-cols-2 gap-2 bg-gray-50 dark:bg-gray-900/50 p-2.5 rounded-lg text-[11px]">
                <div>
                  <span class="text-gray-400 block text-[10px]">No. KTP (NIK):</span>
                  <span class="font-semibold text-gray-800 dark:text-gray-200">{{ (detail as any).nik || '-' }}</span>
                </div>
                <div>
                  <span class="text-gray-400 block text-[10px]">Pekerjaan:</span>
                  <span class="font-semibold text-gray-800 dark:text-gray-200">{{ (detail as any).occupation || '-' }}</span>
                </div>
                <div class="col-span-2">
                  <span class="text-gray-400 block text-[10px]">Kontak Darurat:</span>
                  <span class="font-semibold text-gray-800 dark:text-gray-200">{{ (detail as any).emergencyContact || '-' }}</span>
                </div>
              </div>

              <div class="space-y-1.5 pt-1">
                <div>
                  <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Keluhan Utama (Anamnesis):</span>
                  <p class="text-gray-700 dark:text-gray-300 bg-amber-50/60 dark:bg-amber-950/20 p-2 rounded-lg border border-amber-200/50 dark:border-amber-900/40 text-[11px]">
                    {{ (detail as any).chiefComplaint || (detail as any).soapS || '-' }}
                  </p>
                </div>

                <div>
                  <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Riwayat Penyakit Sekarang:</span>
                  <p class="text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-gray-900/40 p-2 rounded-lg text-[11px]">
                    {{ (detail as any).presentIllnessHistory || '-' }}
                  </p>
                </div>
              </div>
            </div>

            <!-- II. RIWAYAT KESEHATAN UMUM & ALERGI -->
            <div class="p-3.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 space-y-2">
              <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5 text-xs">
                <UIcon name="i-lucide-shield-alert" class="w-4 h-4 text-primary" />
                II. Riwayat Kesehatan Umum & Alergi
              </span>

              <div class="space-y-1.5">
                <span class="text-[10px] text-gray-500 font-semibold block uppercase">Checklist Penyakit Sistemik:</span>
                <div class="flex flex-wrap gap-1.5">
                  <UBadge :color="(detail as any).hasHypertension ? 'error' : 'neutral'" variant="soft" size="xs">
                    {{ (detail as any).hasHypertension ? '✓ Hipertensi' : '× Hipertensi' }}
                  </UBadge>
                  <UBadge :color="(detail as any).hasHeartDisease ? 'error' : 'neutral'" variant="soft" size="xs">
                    {{ (detail as any).hasHeartDisease ? '✓ Penyakit Jantung' : '× Penyakit Jantung' }}
                  </UBadge>
                  <UBadge :color="(detail as any).hasDiabetes ? 'error' : 'neutral'" variant="soft" size="xs">
                    {{ (detail as any).hasDiabetes ? '✓ Diabetes' : '× Diabetes' }}
                  </UBadge>
                  <UBadge :color="(detail as any).hasHepatitis ? 'error' : 'neutral'" variant="soft" size="xs">
                    {{ (detail as any).hasHepatitis ? '✓ Hepatitis' : '× Hepatitis' }}
                  </UBadge>
                  <UBadge :color="(detail as any).hasHiv ? 'error' : 'neutral'" variant="soft" size="xs">
                    {{ (detail as any).hasHiv ? '✓ HIV/AIDS' : '× HIV/AIDS' }}
                  </UBadge>
                  <UBadge :color="(detail as any).hasBleedingDisorder ? 'error' : 'neutral'" variant="soft" size="xs">
                    {{ (detail as any).hasBleedingDisorder ? '✓ Pembekuan Darah' : '× Pembekuan Darah' }}
                  </UBadge>
                  <UBadge :color="(detail as any).isPregnant ? 'warning' : 'neutral'" variant="soft" size="xs">
                    {{ (detail as any).isPregnant ? '✓ Sedang Hamil' : '× Sedang Hamil' }}
                  </UBadge>
                </div>
              </div>

              <div class="grid grid-cols-2 gap-2 pt-1 text-[11px]">
                <div class="p-2 rounded-lg bg-red-50/50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/30">
                  <span class="text-[10px] text-red-600 dark:text-red-400 font-bold block">Alergi Obat:</span>
                  <span class="font-medium text-gray-800 dark:text-gray-200">{{ (detail as any).drugAllergies || '-' }}</span>
                </div>
                <div class="p-2 rounded-lg bg-amber-50/50 dark:bg-amber-950/20 border border-amber-100 dark:border-amber-900/30">
                  <span class="text-[10px] text-amber-600 dark:text-amber-400 font-bold block">Alergi Makanan:</span>
                  <span class="font-medium text-gray-800 dark:text-gray-200">{{ (detail as any).foodAllergies || '-' }}</span>
                </div>
                <div class="col-span-2 p-2 rounded-lg bg-gray-50 dark:bg-gray-900/40">
                  <span class="text-[10px] text-gray-500 font-semibold block">Mengonsumsi Obat Rutin:</span>
                  <span class="font-medium text-gray-800 dark:text-gray-200">{{ (detail as any).routineMedications || '-' }}</span>
                </div>
              </div>
            </div>

            <!-- III. PEMERIKSAAN VITAL & EKSTRA ORAL -->
            <div class="p-3.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 space-y-2">
              <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5 text-xs">
                <UIcon name="i-lucide-activity" class="w-4 h-4 text-primary" />
                III. Pemeriksaan Tanda Vital & Ekstra Oral
              </span>

              <div class="grid grid-cols-3 gap-2 bg-primary-50/30 dark:bg-primary-950/20 p-2.5 rounded-lg text-[11px] text-center border border-primary-100 dark:border-primary-900/40">
                <div>
                  <span class="text-gray-400 block text-[9px] uppercase font-bold">Tekanan Darah</span>
                  <span class="font-black text-primary-700 dark:text-primary-300">{{ (detail as any).vitalBloodPressure || '-' }}</span>
                </div>
                <div>
                  <span class="text-gray-400 block text-[9px] uppercase font-bold">Nadi</span>
                  <span class="font-black text-primary-700 dark:text-primary-300">{{ (detail as any).vitalPulse || '-' }}</span>
                </div>
                <div>
                  <span class="text-gray-400 block text-[9px] uppercase font-bold">Suhu Tubuh</span>
                  <span class="font-black text-primary-700 dark:text-primary-300">{{ (detail as any).vitalTemperature || '-' }}</span>
                </div>
              </div>

              <div>
                <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Pemeriksaan Ekstra Oral:</span>
                <p class="text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-gray-900/40 p-2 rounded-lg text-[11px]">
                  {{ (detail as any).extraOralExam || '-' }}
                </p>
              </div>
            </div>

            <!-- IV. CATATAN SOAP & RESEP OBAT -->
            <div class="p-3.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 space-y-2">
              <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5 text-xs">
                <UIcon name="i-lucide-file-text" class="w-4 h-4 text-primary" />
                IV. Catatan SOAP & Resep Obat (Rx)
              </span>

              <div class="space-y-1.5 bg-gray-50 dark:bg-gray-900/40 p-3 rounded-lg text-[11px] space-y-2">
                <div class="flex items-center gap-2 pb-1.5 border-b border-gray-200 dark:border-gray-700">
                  <UBadge color="primary" variant="solid" size="xs" class="font-mono font-bold">
                    Gigi #{{ (detail as any).toothNumber || '-' }}
                  </UBadge>
                  <span class="font-bold text-gray-900 dark:text-white">{{ detail.diagnosis || '-' }}</span>
                </div>

                <div>
                  <span class="font-bold text-sky-600 dark:text-sky-400">S (Subjective):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4">{{ (detail as any).soapS || '-' }}</p>
                </div>
                <div>
                  <span class="font-bold text-emerald-600 dark:text-emerald-400">O (Objective):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4">{{ (detail as any).soapO || '-' }}</p>
                </div>
                <div>
                  <span class="font-bold text-amber-600 dark:text-amber-400">A (Assessment / Diagnosis):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4 font-semibold">{{ detail.diagnosis || '-' }}</p>
                </div>
                <div>
                  <span class="font-bold text-purple-600 dark:text-purple-400">P (Plan / Rencana):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4">{{ (detail as any).soapP || '-' }}</p>
                </div>
                <div class="pt-1 border-t border-gray-200 dark:border-gray-700">
                  <span class="font-bold text-emerald-700 dark:text-emerald-300 flex items-center gap-1">
                    <UIcon name="i-lucide-pill" class="w-3.5 h-3.5" />
                    Resep Obat (Rx):
                  </span>
                  <p class="font-mono text-emerald-800 dark:text-emerald-200 bg-emerald-50/60 dark:bg-emerald-950/30 p-2 rounded-md mt-1 text-[11px]">
                    {{ (detail as any).prescription || '-' }}
                  </p>
                </div>
              </div>

              <div>
                <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Detail Prosedur & Tindakan Perawatan:</span>
                <p class="text-gray-700 dark:text-gray-300 whitespace-pre-line pl-2 leading-relaxed text-[11px] bg-gray-50 dark:bg-gray-900/40 p-2 rounded-lg">
                  {{ detail.treatmentNotes || '-' }}
                </p>
              </div>
            </div>

            <!-- V. ODONTOGRAM & STATUS GIGI -->
            <div class="p-3.5 rounded-xl border border-gray-200 dark:border-gray-700 bg-gray-50/70 dark:bg-gray-900/40 space-y-2">
              <span class="font-bold text-gray-900 dark:text-white flex items-center gap-1.5 text-xs">
                <UIcon name="i-lucide-grid" class="w-4 h-4 text-primary" />
                V. Odontogram & Status Gigi
              </span>
              <div v-if="detail.odontogram && detail.odontogram.length > 0" class="space-y-1.5">
                <div v-for="(od, idx) in detail.odontogram" :key="idx" class="flex items-center justify-between p-2 rounded-lg bg-white dark:bg-gray-800 border border-gray-100 dark:border-gray-700">
                  <div class="flex items-center gap-2">
                    <UBadge color="primary" variant="solid" size="xs" class="font-mono font-bold">Gigi #{{ od.toothNumber }}</UBadge>
                    <span class="font-semibold text-gray-800 dark:text-gray-200">{{ CONDITION_LABEL_MAP[od.condition] || od.condition }}</span>
                  </div>
                  <span class="text-gray-500 italic text-[11px]">{{ od.notes || 'Pemeriksaan terlampir' }}</span>
                </div>
              </div>
              <div v-else class="text-gray-500 italic pl-5">
                Kondisi seluruh gigi dalam keadaan sehat / normal.
              </div>
            </div>

            <!-- VI. REKOMENDASI KONTROL PASIEN -->
            <div class="p-3.5 rounded-xl border border-amber-200 dark:border-amber-800 bg-amber-50/50 dark:bg-amber-950/20 space-y-1.5">
              <div class="flex items-center justify-between">
                <span class="font-bold text-amber-900 dark:text-amber-300 flex items-center gap-1.5 text-xs">
                  <UIcon name="i-lucide-calendar-clock" class="w-4 h-4 text-amber-600" />
                  VI. Rekomendasi Kontrol Pasien
                </span>
                <UBadge color="warning" variant="subtle" size="xs">Jadwal Kontrol</UBadge>
              </div>
              <p class="text-amber-800 dark:text-amber-200 font-medium pl-5 text-[11px]">
                Diperlukan kunjungan kontrol ulang dalam 14 - 30 hari ke depan untuk pemantauan hasil perawatan gigi.
              </p>
            </div>

            <!-- Slideover Footer Action Buttons -->
            <div class="flex items-center justify-end gap-2 pt-3 border-t border-gray-200 dark:border-gray-700 sticky bottom-0 bg-white dark:bg-gray-900 py-2">
              <UButton label="Tutup" color="neutral" variant="ghost" @click="showDetail = false" />
              <UButton icon="i-lucide-printer" label="Cetak Rekam Medis" color="primary" class="font-bold" @click="printMedicalRecord(detail)" />
            </div>
          </div>
        </template>
      </USlideover>
    </ClientOnly>
  </div>
</template>
