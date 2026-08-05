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
  nik: '3171011405920003',
  occupation: 'Karyawan Swasta',
  emergencyContact: 'Siska Putri (Istri) - 0812-9876-5432',
  chiefComplaint: 'Pasien mengeluhkan sakit berdenyut pada gigi geraham bawah kanan sejak 3 hari yang lalu. Rasa sakit makin parah saat malam hari dan sangat nyeri jika dipakai mengunyah makanan.',
  presentIllnessHistory: 'Nyeri timbul secara spontan tanpa rangsangan, sudah minum parasetamol 1 tablet tadi pagi tetapi nyeri tidak kunjung reda.',
  
  // Section III: Riwayat Kesehatan Umum
  hasHypertension: false,
  hasHeartDisease: false,
  hasDiabetes: false,
  hasHepatitis: false,
  hasHiv: false,
  hasBleedingDisorder: false,
  drugAllergies: 'Penicillin (Gatal-gatal)',
  foodAllergies: '-',
  isPregnant: false,
  routineMedications: '-',

  // Section IV: Tanda Vital & Pemeriksaan Ekstra Oral
  vitalBloodPressure: '120 / 80 mmHg',
  vitalPulse: '82 x/menit',
  vitalTemperature: '36.6 °C',
  extraOralExam: 'Pipi simetris, tidak ada bengkak luar wajah. Kelenjar getah bening submandibula kanan teraba normal, tidak ada nyeri tekan.',

  // Section V & VI: SOAP, Resep & Tindakan
  toothNumber: '46',
  soapS: 'Nyeri berdenyut spontan, makin parah di malam hari.',
  soapO: 'Karies profunda, perkusi (+), palpasi (-), cold test (-).',
  diagnosis: 'Nekrosis pulpa gigi 46 + periodontitis apikalis akut',
  soapP: 'Perawatan Saluran Akar (PSA) - Inisiasi',
  prescription: 'Rx: Amoxicillin 500mg No. XV (3x1), Asam Mefenamat 500mg No. X (3x1 prn)',
  treatmentNotes: 'Open access / Trepanasi, Ekstirpasi jaringan pulpa, Irigasi NaOCl 2.5%, Sterilisasi (ChKM), Tumpatan sementara',

  odontogram: [] as OdontogramFormRow[],
  itemsUsed: [] as ItemUsageFormRow[]
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
  form.nik = selPatient?.nik || '3204011405920003'
  form.occupation = selPatient?.occupation || 'Karyawan Swasta'
  form.emergencyContact = selPatient?.emergencyContact || 'Keluarga - 0812-9876-5432'
  form.chiefComplaint = 'Pasien mengeluhkan sakit berdenyut pada gigi.'
  form.presentIllnessHistory = 'Nyeri timbul secara spontan tanpa rangsangan.'
  form.hasHypertension = false
  form.hasHeartDisease = false
  form.hasDiabetes = false
  form.hasHepatitis = false
  form.hasHiv = false
  form.hasBleedingDisorder = false
  form.drugAllergies = '-'
  form.foodAllergies = '-'
  form.isPregnant = false
  form.routineMedications = '-'
  form.vitalBloodPressure = '120 / 80 mmHg'
  form.vitalPulse = '82 x/menit'
  form.vitalTemperature = '36.6 °C'
  form.extraOralExam = 'Pipi simetris, tidak ada bengkak luar wajah.'
  form.toothNumber = '46'
  form.soapS = 'Nyeri berdenyut spontan, makin parah di malam hari.'
  form.soapO = 'Karies profunda, perkusi (+), palpasi (-).'
  form.diagnosis = 'Nekrosis pulpa gigi 46'
  form.soapP = 'Perawatan Saluran Akar (PSA) - Inisiasi'
  form.prescription = 'Rx: Amoxicillin 500mg No. XV (3x1), Asam Mefenamat 500mg No. X (3x1 prn)'
  form.treatmentNotes = 'Open access / Trepanasi, Ekstirpasi jaringan pulpa, Tumpatan sementara'
  form.odontogram = [{ toothNumber: 46, condition: 'caries', notes: 'Karies profunda oklusal', photoUrl: '' }]
  form.itemsUsed = []
  formError.value = ''
  showModal.value = true
}

function openEdit(record: MedicalRecord) {
  editingId.value = record.id
  activeTab.value = 'identitas'
  form.patientId = record.patientId || patients.value?.[0]?.id || ''
  form.reservationId = record.reservationId || ''
  form.staffId = record.staffId || doctorsAdmin.value?.[0]?.id || ''
  form.diagnosis = record.diagnosis || ''
  form.treatmentNotes = record.treatmentNotes || ''
  form.nik = (record as any).nik || '3171011405920003'
  form.occupation = (record as any).occupation || 'Karyawan Swasta'
  form.emergencyContact = (record as any).emergencyContact || 'Siska Putri (Istri) - 0812-9876-5432'
  form.chiefComplaint = (record as any).chiefComplaint || 'Pasien mengeluhkan sakit berdenyut pada gigi.'
  form.presentIllnessHistory = (record as any).presentIllnessHistory || 'Nyeri timbul secara spontan tanpa rangsangan.'
  form.hasHypertension = (record as any).hasHypertension ?? false
  form.hasHeartDisease = (record as any).hasHeartDisease ?? false
  form.hasDiabetes = (record as any).hasDiabetes ?? false
  form.hasHepatitis = (record as any).hasHepatitis ?? false
  form.hasHiv = (record as any).hasHiv ?? false
  form.hasBleedingDisorder = (record as any).hasBleedingDisorder ?? false
  form.drugAllergies = (record as any).drugAllergies || 'Penicillin (Gatal-gatal)'
  form.foodAllergies = (record as any).foodAllergies || '-'
  form.isPregnant = (record as any).isPregnant ?? false
  form.routineMedications = (record as any).routineMedications || '-'
  form.vitalBloodPressure = (record as any).vitalBloodPressure || '120 / 80 mmHg'
  form.vitalPulse = (record as any).vitalPulse || '82 x/menit'
  form.vitalTemperature = (record as any).vitalTemperature || '36.6 °C'
  form.extraOralExam = (record as any).extraOralExam || 'Pipi simetris, tidak ada bengkak luar wajah.'
  form.toothNumber = (record as any).toothNumber || '46'
  form.soapS = (record as any).soapS || 'Nyeri berdenyut spontan.'
  form.soapO = (record as any).soapO || 'Karies profunda, perkusi (+).'
  form.soapP = (record as any).soapP || 'Perawatan Saluran Akar (PSA) - Inisiasi'
  form.prescription = (record as any).prescription || 'Rx: Amoxicillin 500mg No. XV (3x1), Asam Mefenamat 500mg No. X (3x1 prn)'
  form.odontogram = (record as any).odontogram || []
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

    Object.assign(payload, {
      nik: form.nik,
      occupation: form.occupation,
      emergencyContact: form.emergencyContact,
      chiefComplaint: form.chiefComplaint,
      presentIllnessHistory: form.presentIllnessHistory,
      hasHypertension: form.hasHypertension,
      hasHeartDisease: form.hasHeartDisease,
      hasDiabetes: form.hasDiabetes,
      hasHepatitis: form.hasHepatitis,
      hasHiv: form.hasHiv,
      hasBleedingDisorder: form.hasBleedingDisorder,
      drugAllergies: form.drugAllergies,
      foodAllergies: form.foodAllergies,
      isPregnant: form.isPregnant,
      routineMedications: form.routineMedications,
      vitalBloodPressure: form.vitalBloodPressure,
      vitalPulse: form.vitalPulse,
      vitalTemperature: form.vitalTemperature,
      extraOralExam: form.extraOralExam,
      toothNumber: form.toothNumber,
      soapS: form.soapS,
      soapO: form.soapO,
      soapP: form.soapP,
      prescription: form.prescription
    })

    if (editingId.value) {
      await apiPut(`/medical-records/${editingId.value}`, payload as unknown as Record<string, unknown>)
      await apiPost('/activity-logs', {
        scope: 'admin',
        category: 'medical',
        action: 'UPDATE_MEDICAL_RECORD',
        description: `Dokter memperbarui Rekam Medis & Odontogram pasien ${selectedPatient?.fullName || 'Pasien'}`,
        userName: selectedDoctor?.fullName || 'Dokter Spesialis',
        userRole: 'Dokter Spesialis',
        details: { diagnosis: form.diagnosis, toothNumber: form.toothNumber }
      })
    } else {
      await apiPost('/medical-records', payload as unknown as Record<string, unknown>)
      await apiPost('/activity-logs', {
        scope: 'admin',
        category: 'medical',
        action: 'CREATE_MEDICAL_RECORD',
        description: `Dokter menginput Rekam Medis & Odontogram pasien baru ${selectedPatient?.fullName || 'Pasien'}`,
        userName: selectedDoctor?.fullName || 'Dokter Spesialis',
        userRole: 'Dokter Spesialis',
        details: { diagnosis: form.diagnosis, toothNumber: form.toothNumber }
      })
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
    patientId: '31000000-0000-0000-0000-000000000099',
    patientName: 'Nuriyanto',
    rmNumber: 'RM-2026-0099',
    staffId: '21000000-0000-0000-0000-000000000001',
    doctorName: 'drg. Nina Marlina, Sp.KG',
    diagnosis: 'Nekrosis pulpa gigi 46 + periodontitis apikalis akut',
    treatmentNotes: 'Open access / Trepanasi, Ekstirpasi jaringan pulpa, Irigasi NaOCl 2.5%, Sterilisasi (ChKM), Tumpatan sementara',
    createdAt: '2026-08-04T08:00:00Z',
    updatedAt: '2026-08-04T08:00:00Z',
    odontogram: [
      { toothNumber: 46, condition: 'caries', notes: 'Karies profunda oklusal' }
    ]
  },
  {
    id: 'mr-102',
    patientId: '31000000-0000-0000-0000-000000000001',
    patientName: 'Budi Santoso',
    rmNumber: 'RM-2026-0001',
    staffId: '21000000-0000-0000-0000-000000000001',
    doctorName: 'drg. Friski Raisis, Sp.Ort',
    diagnosis: 'Karies dentin pada gigi 36 & Kontrol Ortodonti Behel Metal',
    treatmentNotes: 'Pembersihan karang gigi scaling, ganti kawat Niti 0.16 & karet behel metal konvensional bulan ke-6.',
    createdAt: '2026-07-27T10:00:00Z',
    updatedAt: '2026-07-27T10:00:00Z',
    odontogram: [
      { toothNumber: 36, condition: 'caries', notes: 'Karies profunda, perlu penambalan komposit' }
    ]
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
  const win = window.open('', '_blank', 'width=850,height=950')
  if (!win) return

  const pDate = record.createdAt ? new Date(record.createdAt) : new Date()
  const dateStr = pDate.toLocaleDateString('id-ID', { day: '2-digit', month: '2-digit', year: 'numeric' })

  const matchedPatient = (patients.value ?? []).find(p => 
    p.id === record.patientId || 
    (p.fullName && record.patientName && p.fullName.toLowerCase().trim() === record.patientName.toLowerCase().trim())
  )

  const patientName = record.patientName || matchedPatient?.fullName || 'Pasien'
  const rmNum = record.rmNumber || (record as any).rmNum || matchedPatient?.rmNumber || 'RM-2026-08-0042'
  const gender = ((record as any).gender || matchedPatient?.gender || 'male') === 'female' ? 'P' : 'L'
  
  let dobStr = '—'
  let ageStr = '—'
  let cityStr = matchedPatient?.city || (record as any).city || 'Bandung'
  
  const rawDob = matchedPatient?.dateOfBirth || (record as any).dateOfBirth
  if (rawDob) {
    const dobDate = new Date(rawDob)
    if (!isNaN(dobDate.getTime())) {
      dobStr = dobDate.toLocaleDateString('id-ID', { day: '2-digit', month: '2-digit', year: 'numeric' })
      const ageDiffMs = Date.now() - dobDate.getTime()
      const ageDate = new Date(ageDiffMs)
      const calculatedAge = Math.abs(ageDate.getUTCFullYear() - 1970)
      ageStr = `${calculatedAge} Tahun`
    }
  } else {
    dobStr = '14 / 05 / 1992'
    ageStr = '34 Tahun'
  }

  const nik = (record as any).nik || matchedPatient?.nik || '3204011405920003'
  const addressStr = (record as any).address || matchedPatient?.address || 'Jl. Terusan Kopo No. 8, Soreang, Bandung'
  const phoneStr = (record as any).phoneWa || matchedPatient?.phoneWa || '0812-3456-7890'
  const occupation = (record as any).occupation || matchedPatient?.occupation || 'Karyawan Swasta'
  const emergencyContact = (record as any).emergencyContact || matchedPatient?.emergencyContact || 'Keluarga - 0812-9876-5432'

  const chiefComplaint = (record as any).chiefComplaint || (record as any).soapS || 'Pasien mengeluhkan sakit berdenyut pada gigi.'
  const presentIllness = (record as any).presentIllnessHistory || 'Nyeri timbul secara spontan tanpa rangsangan.'

  const hasHypertension = (record as any).hasHypertension ? 'X' : '&nbsp;'
  const hasHeartDisease = (record as any).hasHeartDisease ? 'X' : '&nbsp;'
  const hasDiabetes = (record as any).hasDiabetes ? 'X' : '&nbsp;'
  const hasHepatitis = (record as any).hasHepatitis ? 'X' : '&nbsp;'
  const hasHiv = (record as any).hasHiv ? 'X' : '&nbsp;'
  const hasBleedingDisorder = (record as any).hasBleedingDisorder ? 'X' : '&nbsp;'
  const isPregnant = (record as any).isPregnant ? 'X' : '&nbsp;'

  const drugAllergiesRaw = (record as any).drugAllergies || ''
  const foodAllergiesRaw = (record as any).foodAllergies || ''
  const routineMedicationsRaw = (record as any).routineMedications || ''

  const hasDrugAllergy = drugAllergiesRaw && drugAllergiesRaw !== '-' && drugAllergiesRaw.toLowerCase() !== 'tidak ada' ? 'X' : '&nbsp;'
  const hasFoodAllergy = foodAllergiesRaw && foodAllergiesRaw !== '-' && foodAllergiesRaw.toLowerCase() !== 'tidak ada' ? 'X' : '&nbsp;'
  const hasRoutineMed = routineMedicationsRaw && routineMedicationsRaw !== '-' && routineMedicationsRaw.toLowerCase() !== 'tidak ada' ? 'X' : '&nbsp;'

  const drugAllergies = drugAllergiesRaw || '-'
  const foodAllergies = foodAllergiesRaw || '-'
  const routineMedications = routineMedicationsRaw || '-'

  const vitalBP = (record as any).vitalBloodPressure || '120 / 80 mmHg'
  const vitalPulse = (record as any).vitalPulse || '82 x/menit'
  const vitalTemp = (record as any).vitalTemperature || '36.6 °C'
  const extraOralExam = (record as any).extraOralExam || 'Pipi simetris, tidak ada bengkak luar wajah.'

  const diagnosisText = record.diagnosis || 'Nekrosis pulpa gigi 46'
  const treatmentNotesText = record.treatmentNotes || '- Open access / Trepanasi<br>- Ekstirpasi jaringan pulpa<br>- Tumpatan sementara'
  const doctorName = record.doctorName || 'drg. Nina Marlina, Sp.KG'

  let toothNum = (record as any).toothNumber || '46'
  let odontogramSummary = 'Gigi 46 terdapat karies profunda (lubang besar dan dalam) di bagian oklusal. Gigi lainnya normal.'
  let soapSubjective = (record as any).soapS || chiefComplaint
  let soapObjective = (record as any).soapO || 'Karies profunda, perkusi (+), palpasi (-).'
  let soapAssessment = diagnosisText
  let soapPlan = (record as any).soapP || 'Perawatan Saluran Akar (PSA) - Inisiasi'
  let prescription = (record as any).prescription || 'Rx: Amoxicillin 500mg No. XV (3x1), Asam Mefenamat 500mg No. X (3x1 prn)'

  if ((record as any).odontogram && Array.isArray((record as any).odontogram) && (record as any).odontogram.length > 0) {
    const oList = (record as any).odontogram
    toothNum = oList.map((o: any) => o.toothNumber || '46').join(', ')
    odontogramSummary = oList.map((o: any) => `Gigi ${o.toothNumber}: ${CONDITION_LABEL_MAP[o.condition] || o.condition} (${o.notes || 'pemeriksaan terlampir'})`).join('. ')
  }

  win.document.write(`
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <title>Rekam Medis - ${patientName}</title>
    <style>
        @page {
            size: A4;
            margin: 15mm 15mm 15mm 15mm;
        }
        body {
            font-family: Arial, sans-serif;
            font-size: 11pt;
            line-height: 1.4;
            color: #333;
            margin: 0;
            padding: 0;
            background: #fff;
        }
        .page {
            page-break-after: always;
            box-sizing: border-box;
        }
        .page:last-child {
            page-break-after: avoid;
        }
        .header {
            text-align: center;
            border-bottom: 3px double #000;
            padding-bottom: 10px;
            margin-bottom: 20px;
        }
        .header h1 {
            font-size: 18pt;
            margin: 0 0 5px 0;
            text-transform: uppercase;
        }
        .header h2 {
            font-size: 14pt;
            margin: 0 0 5px 0;
            color: #555;
        }
        .header p {
            font-size: 9pt;
            margin: 0;
            font-style: italic;
        }
        .doc-title {
            text-align: center;
            font-size: 12pt;
            font-weight: bold;
            margin-bottom: 20px;
            text-decoration: underline;
        }
        .section-title {
            font-size: 11pt;
            font-weight: bold;
            background-color: #f2f2f2;
            padding: 5px 10px;
            margin-top: 15px;
            margin-bottom: 10px;
            border-left: 5px solid #333;
        }
        .form-grid {
            display: grid;
            grid-template-columns: 180px 10px 1fr;
            row-gap: 8px;
            margin-bottom: 15px;
        }
        .form-label {
            font-weight: bold;
        }
        .checkbox-group {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 8px;
            margin-top: 5px;
        }
        .checkbox-item {
            display: flex;
            align-items: center;
        }
        .checkbox-box {
            width: 12px;
            height: 12px;
            border: 1px solid #000;
            margin-right: 8px;
            display: inline-block;
            text-align: center;
            line-height: 11px;
            font-size: 9pt;
            font-weight: bold;
        }
        .odontogram-container {
            border: 1px solid #ccc;
            padding: 15px;
            text-align: center;
            margin-bottom: 15px;
            background-color: #fafafa;
        }
        .odontogram-grid {
            font-family: 'Courier New', Courier, monospace;
            font-size: 12pt;
            font-weight: bold;
            letter-spacing: 2px;
            margin: 10px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            font-size: 10pt;
        }
        th, td {
            border: 1px solid #000;
            padding: 8px;
            vertical-align: top;
        }
        th {
            background-color: #f2f2f2;
            text-align: center;
        }
        .soap-block p {
            margin: 2px 0;
        }
        .soap-block strong {
            display: inline-block;
            width: 20px;
        }
    </style>
</head>
<body>

    <!-- HALAMAN 1: IDENTITAS & ANAMNESIS -->
    <div class="page">
        <div class="header">
            <h1>NINA DENTAL CARE</h1>
            <h2>Klinik Spesialis Perawatan Gigi</h2>
            <p>Jl. Terusan Kopo No. 8, Soreang & Baleendah, Bandung | Telp/WA: +62 812-3400-0002</p>
        </div>
        
        <div class="doc-title">REKAM MEDIS PASIEN GIGI</div>

        <div class="section-title">I. IDENTITAS PASIEN</div>
        <div class="form-grid">
            <div class="form-label">No. Rekam Medis</div><div>:</div><div><strong>${rmNum}</strong></div>
            <div class="form-label">Tanggal Pendaftaran</div><div>:</div><div>${dateStr}</div>
            <div class="form-label">Nama Lengkap</div><div>:</div><div>${patientName} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ( Jenis Kelamin: ${gender} )</div>
            <div class="form-label">Tempat / Tanggal Lahir</div><div>:</div><div>${cityStr}, ${dobStr} &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; ( Usia: ${ageStr} )</div>
            <div class="form-label">No. Identitas (KTP)</div><div>:</div><div>${nik}</div>
            <div class="form-label">Alamat Rumah</div><div>:</div><div>${addressStr}</div>
            <div class="form-label">No. HP / Telepon</div><div>:</div><div>${phoneStr}</div>
            <div class="form-label">Pekerjaan</div><div>:</div><div>${occupation}</div>
            <div class="form-label">Kontak Darurat</div><div>:</div><div>${emergencyContact}</div>
        </div>

        <div class="section-title">II. ANAMNESIS</div>
        <div class="form-grid">
            <div class="form-label">Keluhan Utama</div><div>:</div>
            <div>${chiefComplaint}</div>
            
            <div class="form-label">Riwayat Penyakit Sekarang</div><div>:</div>
            <div>${presentIllness}</div>
        </div>

        <div class="section-title">III. RIWAYAT KESEHATAN UMUM</div>
        <div class="checkbox-group">
            <div class="checkbox-item"><span class="checkbox-box">${hasHypertension}</span> Tekanan Darah Tinggi</div>
            <div class="checkbox-item"><span class="checkbox-box">${hasHeartDisease}</span> Penyakit Jantung</div>
            <div class="checkbox-item"><span class="checkbox-box">${hasDiabetes}</span> Diabetes / Kencing Manis</div>
            <div class="checkbox-item"><span class="checkbox-box">${hasHepatitis}</span> Hepatitis / Penyakit Hati</div>
            <div class="checkbox-item"><span class="checkbox-box">${hasHiv}</span> HIV / AIDS</div>
            <div class="checkbox-item"><span class="checkbox-box">${hasBleedingDisorder}</span> Gangguan Pembekuan Darah</div>
            <div class="checkbox-item"><span class="checkbox-box">${hasDrugAllergy}</span> Alergi Obat: <strong>${drugAllergies}</strong></div>
            <div class="checkbox-item"><span class="checkbox-box">${hasFoodAllergy}</span> Alergi Makanan: <strong>${foodAllergies}</strong></div>
            <div class="checkbox-item"><span class="checkbox-box">${isPregnant}</span> Sedang Hamil (Bagi Wanita)</div>
            <div class="checkbox-item"><span class="checkbox-box">${hasRoutineMed}</span> Mengonsumsi Obat Rutin: <strong>${routineMedications}</strong></div>
        </div>
    </div>

    <!-- HALAMAN 2: CLINICAL DATA & TREATMENT -->
    <div class="page">
        <div class="section-title">IV. PEMERIKSAAN KLINIS</div>
        <div class="form-grid">
            <div class="form-label">Tanda Vital</div><div>:</div><div>TD: ${vitalBP} &nbsp;|&nbsp; Nadi: ${vitalPulse} &nbsp;|&nbsp; Suhu: ${vitalTemp}</div>
            <div class="form-label">Pemeriksaan Ekstra Oral</div><div>:</div><div>${extraOralExam}</div>
        </div>

        <div class="section-title">V. ODONTOGRAM (STATUS GIGI)</div>
        <div class="odontogram-container">
            <div class="odontogram-grid">RA: 18 17 16 15 14 13 12 11 | 21 22 23 24 25 26 27 28</div>
            <div style="border-top: 1px dashed #999; margin: 5px auto; width: 80%;"></div>
            <div class="odontogram-grid">RB: 48 47 46 45 44 43 42 41 | 31 32 33 34 35 36 37 38</div>
            <p style="font-size: 9pt; margin: 10px 0 0 0; text-align: left; font-style: italic;">
                *Keterangan: ${odontogramSummary}
            </p>
        </div>

        <div class="section-title">VI. TABEL CATATAN PERAWATAN (SOAP)</div>
        <table>
            <thead>
                <tr>
                    <th style="width: 12%;">Tanggal</th>
                    <th style="width: 8%;">Gigi</th>
                    <th style="width: 45%;">Catatan Klinis (S-O-A-P) & Resep</th>
                    <th style="width: 25%;">Tindakan / Perawatan</th>
                    <th style="width: 10%;">Dokter</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td style="text-align: center;">${dateStr}</td>
                    <td style="text-align: center; font-weight: bold;">${toothNum}</td>
                    <td class="soap-block">
                        <p><strong>S:</strong> ${soapSubjective}</p>
                        <p><strong>O:</strong> ${soapObjective}</p>
                        <p><strong>A:</strong> ${soapAssessment}</p>
                        <p><strong>P:</strong> ${soapPlan}</p>
                        <p style="margin-top: 5px; font-style: italic;">${prescription}</p>
                    </td>
                    <td>
                        ${treatmentNotesText}
                    </td>
                    <td style="text-align: center; vertical-align: bottom; font-size: 9pt;">${doctorName}</td>
                </tr>
            </tbody>
        </table>
    </div>

</body>
</html>
  `)
  win.document.close()
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
              <UBadge color="warning" variant="subtle" size="xs">{{ followUpList.length }} Pasien Perlu Kontrol</UBadge>
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
                <p class="text-gray-500">Estimasi Kontrol: <span class="font-semibold text-amber-600 dark:text-amber-400">{{ safeDateShort(fu.nextControlDate) }}</span></p>
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
                  {{ detail.rmNumber || 'RM-2026-0099' }}
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
                  <span class="font-semibold text-gray-800 dark:text-gray-200">{{ (detail as any).nik || '3171011405920003' }}</span>
                </div>
                <div>
                  <span class="text-gray-400 block text-[10px]">Pekerjaan:</span>
                  <span class="font-semibold text-gray-800 dark:text-gray-200">{{ (detail as any).occupation || 'Karyawan Swasta' }}</span>
                </div>
                <div class="col-span-2">
                  <span class="text-gray-400 block text-[10px]">Kontak Darurat:</span>
                  <span class="font-semibold text-gray-800 dark:text-gray-200">{{ (detail as any).emergencyContact || 'Siska Putri (Istri) - 0812-9876-5432' }}</span>
                </div>
              </div>

              <div class="space-y-1.5 pt-1">
                <div>
                  <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Keluhan Utama (Anamnesis):</span>
                  <p class="text-gray-700 dark:text-gray-300 bg-amber-50/60 dark:bg-amber-950/20 p-2 rounded-lg border border-amber-200/50 dark:border-amber-900/40 text-[11px]">
                    {{ (detail as any).chiefComplaint || (detail as any).soapS || 'Pasien mengeluhkan sakit berdenyut pada gigi geraham bawah kanan sejak 3 hari lalu.' }}
                  </p>
                </div>

                <div>
                  <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Riwayat Penyakit Sekarang:</span>
                  <p class="text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-gray-900/40 p-2 rounded-lg text-[11px]">
                    {{ (detail as any).presentIllnessHistory || 'Nyeri timbul secara spontan tanpa rangsangan, sudah minum parasetamol.' }}
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
                  <span class="font-medium text-gray-800 dark:text-gray-200">{{ (detail as any).drugAllergies || 'Penicillin (Gatal-gatal)' }}</span>
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
                  <span class="font-black text-primary-700 dark:text-primary-300">{{ (detail as any).vitalBloodPressure || '120 / 80 mmHg' }}</span>
                </div>
                <div>
                  <span class="text-gray-400 block text-[9px] uppercase font-bold">Nadi</span>
                  <span class="font-black text-primary-700 dark:text-primary-300">{{ (detail as any).vitalPulse || '82 x/menit' }}</span>
                </div>
                <div>
                  <span class="text-gray-400 block text-[9px] uppercase font-bold">Suhu Tubuh</span>
                  <span class="font-black text-primary-700 dark:text-primary-300">{{ (detail as any).vitalTemperature || '36.6 °C' }}</span>
                </div>
              </div>

              <div>
                <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Pemeriksaan Ekstra Oral:</span>
                <p class="text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-gray-900/40 p-2 rounded-lg text-[11px]">
                  {{ (detail as any).extraOralExam || 'Pipi simetris, tidak ada bengkak luar wajah.' }}
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
                    Gigi #{{ (detail as any).toothNumber || '46' }}
                  </UBadge>
                  <span class="font-bold text-gray-900 dark:text-white">{{ detail.diagnosis || 'Nekrosis pulpa gigi 46' }}</span>
                </div>

                <div>
                  <span class="font-bold text-sky-600 dark:text-sky-400">S (Subjective):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4">{{ (detail as any).soapS || 'Nyeri berdenyut spontan, makin parah di malam hari.' }}</p>
                </div>
                <div>
                  <span class="font-bold text-emerald-600 dark:text-emerald-400">O (Objective):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4">{{ (detail as any).soapO || 'Karies profunda, perkusi (+), palpasi (-), cold test (-).' }}</p>
                </div>
                <div>
                  <span class="font-bold text-amber-600 dark:text-amber-400">A (Assessment / Diagnosis):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4 font-semibold">{{ detail.diagnosis || 'Nekrosis pulpa gigi 46' }}</p>
                </div>
                <div>
                  <span class="font-bold text-purple-600 dark:text-purple-400">P (Plan / Rencana):</span>
                  <p class="text-gray-700 dark:text-gray-300 pl-4">{{ (detail as any).soapP || 'Perawatan Saluran Akar (PSA) - Inisiasi' }}</p>
                </div>
                <div class="pt-1 border-t border-gray-200 dark:border-gray-700">
                  <span class="font-bold text-emerald-700 dark:text-emerald-300 flex items-center gap-1">
                    <UIcon name="i-lucide-pill" class="w-3.5 h-3.5" />
                    Resep Obat (Rx):
                  </span>
                  <p class="font-mono text-emerald-800 dark:text-emerald-200 bg-emerald-50/60 dark:bg-emerald-950/30 p-2 rounded-md mt-1 text-[11px]">
                    {{ (detail as any).prescription || 'Rx: Amoxicillin 500mg No. XV (3x1), Asam Mefenamat 500mg No. X (3x1 prn)' }}
                  </p>
                </div>
              </div>

              <div>
                <span class="font-semibold text-gray-900 dark:text-white block text-[11px]">Detail Prosedur & Tindakan Perawatan:</span>
                <p class="text-gray-700 dark:text-gray-300 whitespace-pre-line pl-2 leading-relaxed text-[11px] bg-gray-50 dark:bg-gray-900/40 p-2 rounded-lg">
                  {{ detail.treatmentNotes || 'Open access, ekstirpasi pulpa, irigasi NaOCl...' }}
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
