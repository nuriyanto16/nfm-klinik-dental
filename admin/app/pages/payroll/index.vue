<script setup lang="ts">
definePageMeta({ title: 'Honor & Gaji Pegawai' })

export interface StaffPayroll {
  id: string
  nip: string
  fullName: string
  role: string
  roleLabel: string
  branchName: string
  baseSalary: number
  treatmentRevenue: number
  commissionRatePercent: number
  calculatedCommission: number
  allowanceBonus: number
  transportAllowance: number
  deductions: number
  bpjsDeduction: number
  taxDeduction: number
  netPayable: number
  bankName: string
  accountNumber: string
  status: 'PAID' | 'PENDING' | 'APPROVED'
  period: string
  periodYear: number
  periodMonth: number
  paidAt?: string
}

const PAYROLL_STORAGE_KEY = 'ndc_payroll_records_v2'

const INITIAL_PAYROLL_DATA: StaffPayroll[] = [
  {
    id: 'pr-101',
    nip: 'NDC-DR-001',
    fullName: 'drg. Friski Raisis, Sp.Ort',
    role: 'dokter',
    roleLabel: 'Dokter Spesialis Ortodonti',
    branchName: 'Soreang',
    baseSalary: 6000000,
    treatmentRevenue: 28500000,
    commissionRatePercent: 20,
    calculatedCommission: 5700000,
    allowanceBonus: 1000000,
    transportAllowance: 500000,
    deductions: 250000,
    bpjsDeduction: 150000,
    taxDeduction: 100000,
    netPayable: 12700000,
    bankName: 'BCA',
    accountNumber: '7700112233',
    status: 'PAID',
    period: 'September 2026',
    periodYear: 2026,
    periodMonth: 9
  },
  {
    id: 'pr-102',
    nip: 'NDC-DR-002',
    fullName: 'drg. Siti Aminah',
    role: 'dokter',
    roleLabel: 'Dokter Gigi Umum',
    branchName: 'Baleendah',
    baseSalary: 5000000,
    treatmentRevenue: 19800000,
    commissionRatePercent: 15,
    calculatedCommission: 2970000,
    allowanceBonus: 600000,
    transportAllowance: 400000,
    deductions: 200000,
    bpjsDeduction: 120000,
    taxDeduction: 80000,
    netPayable: 8570000,
    bankName: 'Mandiri',
    accountNumber: '13000998877',
    status: 'PAID',
    period: 'September 2026',
    periodYear: 2026,
    periodMonth: 9
  },
  {
    id: 'pr-103',
    nip: 'NDC-DR-003',
    fullName: 'drg. Budi Santoso, Sp.KGA',
    role: 'dokter',
    roleLabel: 'Dokter Spesialis Gigi Anak',
    branchName: 'Soreang',
    baseSalary: 6000000,
    treatmentRevenue: 22000000,
    commissionRatePercent: 18,
    calculatedCommission: 3960000,
    allowanceBonus: 750000,
    transportAllowance: 450000,
    deductions: 200000,
    bpjsDeduction: 120000,
    taxDeduction: 80000,
    netPayable: 10760000,
    bankName: 'BCA',
    accountNumber: '7700445566',
    status: 'APPROVED',
    period: 'September 2026',
    periodYear: 2026,
    periodMonth: 9
  },
  {
    id: 'pr-104',
    nip: 'NDC-DR-004',
    fullName: 'drg. Nina Marlina, Sp.KG',
    role: 'dokter',
    roleLabel: 'Dokter Spesialis Konservasi Gigi',
    branchName: 'Soreang',
    baseSalary: 6500000,
    treatmentRevenue: 31000000,
    commissionRatePercent: 20,
    calculatedCommission: 6200000,
    allowanceBonus: 1200000,
    transportAllowance: 500000,
    deductions: 300000,
    bpjsDeduction: 180000,
    taxDeduction: 120000,
    netPayable: 13800000,
    bankName: 'BCA',
    accountNumber: '7700889900',
    status: 'PAID',
    period: 'Agustus 2026',
    periodYear: 2026,
    periodMonth: 8
  },
  {
    id: 'pr-105',
    nip: 'NDC-NR-001',
    fullName: 'Rina Marlina',
    role: 'perawat',
    roleLabel: 'Perawat Gigi Senior',
    branchName: 'Baleendah',
    baseSalary: 4200000,
    treatmentRevenue: 0,
    commissionRatePercent: 0,
    calculatedCommission: 0,
    allowanceBonus: 850000,
    transportAllowance: 350000,
    deductions: 150000,
    bpjsDeduction: 100000,
    taxDeduction: 50000,
    netPayable: 5100000,
    bankName: 'BCA',
    accountNumber: '7711223344',
    status: 'PAID',
    period: 'September 2026',
    periodYear: 2026,
    periodMonth: 9
  },
  {
    id: 'pr-106',
    nip: 'NDC-FO-001',
    fullName: 'Maya Putri',
    role: 'kasir',
    roleLabel: 'Kasir & Front Office',
    branchName: 'Soreang',
    baseSalary: 3800000,
    treatmentRevenue: 0,
    commissionRatePercent: 0,
    calculatedCommission: 0,
    allowanceBonus: 650000,
    transportAllowance: 350000,
    deductions: 120000,
    bpjsDeduction: 80000,
    taxDeduction: 40000,
    netPayable: 4560000,
    bankName: 'Mandiri',
    accountNumber: '13100223344',
    status: 'PAID',
    period: 'September 2026',
    periodYear: 2026,
    periodMonth: 9
  },
  {
    id: 'pr-107',
    nip: 'NDC-ADM-001',
    fullName: 'Sari Dewi Pratiwi',
    role: 'admin',
    roleLabel: 'Admin Cabang',
    branchName: 'Soreang',
    baseSalary: 4000000,
    treatmentRevenue: 0,
    commissionRatePercent: 0,
    calculatedCommission: 0,
    allowanceBonus: 700000,
    transportAllowance: 350000,
    deductions: 140000,
    bpjsDeduction: 90000,
    taxDeduction: 50000,
    netPayable: 4770000,
    bankName: 'BCA',
    accountNumber: '7722334455',
    status: 'PAID',
    period: 'September 2026',
    periodYear: 2026,
    periodMonth: 9
  }
]

const MONTH_NAMES = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
]

const MONTH_OPTIONS = [
  { value: 'all', label: 'Semua Bulan' },
  ...MONTH_NAMES.map((name, idx) => ({ value: String(idx + 1), label: name }))
]

const YEAR_OPTIONS = [
  { value: 'all', label: 'Semua Tahun' },
  { value: '2024', label: '2024' },
  { value: '2025', label: '2025' },
  { value: '2026', label: '2026' },
  { value: '2027', label: '2027' },
  { value: '2028', label: '2028' }
]

// State management dengan local storage persistence
const localPayrolls = ref<StaffPayroll[]>([])

onMounted(() => {
  try {
    const saved = localStorage.getItem(PAYROLL_STORAGE_KEY)
    if (saved) {
      const parsed = JSON.parse(saved)
      if (Array.isArray(parsed) && parsed.length > 0) {
        localPayrolls.value = parsed
        return
      }
    }
  } catch (_) {}
  localPayrolls.value = [...INITIAL_PAYROLL_DATA]
  saveToStorage()
})

function saveToStorage() {
  try {
    localStorage.setItem(PAYROLL_STORAGE_KEY, JSON.stringify(localPayrolls.value))
  } catch (_) {}
}

const selectedYearFilter = ref('2026')
const selectedMonthFilter = ref('all')
const selectedBranchFilter = ref('all')
const selectedRoleFilter = ref('all')
const search = ref('')
const page = ref(1)
const pageSize = 10

const selectedPayroll = ref<StaffPayroll | null>(null)
const showPrintSlipModal = ref(false)

const stats = computed(() => {
  const totalNet = displayPayrolls.value.reduce((sum, p) => sum + p.netPayable, 0)
  const totalCommission = displayPayrolls.value.reduce((sum, p) => sum + p.calculatedCommission, 0)
  const totalBase = displayPayrolls.value.reduce((sum, p) => sum + p.baseSalary, 0)
  const totalCount = displayPayrolls.value.length

  return { totalNet, totalCommission, totalBase, totalCount }
})

const displayPayrolls = computed(() => {
  return localPayrolls.value.filter(p => {
    // 1. Search Query Match
    if (search.value) {
      const q = search.value.toLowerCase().trim()
      const matchName = (p.fullName || '').toLowerCase().includes(q)
      const matchNip = (p.nip || '').toLowerCase().includes(q)
      const matchRole = (p.roleLabel || '').toLowerCase().includes(q)
      const matchBranch = (p.branchName || '').toLowerCase().includes(q)
      if (!matchName && !matchNip && !matchRole && !matchBranch) return false
    }
    // 2. Branch Filter Match
    if (selectedBranchFilter.value !== 'all' && p.branchName !== selectedBranchFilter.value) {
      return false
    }
    // 3. Role Filter Match
    if (selectedRoleFilter.value !== 'all' && p.roleLabel !== selectedRoleFilter.value) {
      return false
    }
    // 4. Year Filter Match
    if (selectedYearFilter.value !== 'all') {
      const targetYear = parseInt(selectedYearFilter.value, 10)
      if (p.periodYear && p.periodYear !== targetYear) return false
      if (!p.periodYear && !p.period.includes(selectedYearFilter.value)) return false
    }
    // 5. Month Filter Match
    if (selectedMonthFilter.value !== 'all') {
      const monthIdx = parseInt(selectedMonthFilter.value, 10) - 1
      const targetMonthName = MONTH_NAMES[monthIdx]
      if (p.periodMonth && p.periodMonth !== (monthIdx + 1)) return false
      if (!p.periodMonth && !p.period.toLowerCase().includes(targetMonthName.toLowerCase())) return false
    }

    return true
  })
})

const totalPages = computed(() => Math.ceil(displayPayrolls.value.length / pageSize) || 1)
const paginatedPayrolls = computed(() => {
  const start = (page.value - 1) * pageSize
  return displayPayrolls.value.slice(start, start + pageSize)
})

// --- CRUD Functionality ---
const AVAILABLE_EMPLOYEES = [
  { nip: 'NDC-DR-001', fullName: 'drg. Friski Raisis, Sp.Ort', roleLabel: 'Dokter Spesialis Ortodonti', branchName: 'Soreang', baseSalary: 6000000, bankName: 'BCA', accountNumber: '7700112233' },
  { nip: 'NDC-DR-002', fullName: 'drg. Siti Aminah', roleLabel: 'Dokter Gigi Umum', branchName: 'Baleendah', baseSalary: 5000000, bankName: 'Mandiri', accountNumber: '13000998877' },
  { nip: 'NDC-DR-003', fullName: 'drg. Budi Santoso, Sp.KGA', roleLabel: 'Dokter Spesialis Gigi Anak', branchName: 'Soreang', baseSalary: 6000000, bankName: 'BCA', accountNumber: '7700445566' },
  { nip: 'NDC-DR-004', fullName: 'drg. Nina Marlina, Sp.KG', roleLabel: 'Dokter Spesialis Konservasi Gigi', branchName: 'Soreang', baseSalary: 6500000, bankName: 'BCA', accountNumber: '7700889900' },
  { nip: 'NDC-DR-005', fullName: 'drg. Yoga Pratama', roleLabel: 'Dokter Gigi Umum', branchName: 'Soreang', baseSalary: 5000000, bankName: 'BNI', accountNumber: '0887766554' },
  { nip: 'NDC-DR-006', fullName: 'drg. Fajar Ramadhan', roleLabel: 'Dokter Gigi Umum', branchName: 'Baleendah', baseSalary: 5000000, bankName: 'BRI', accountNumber: '4455001122' },
  { nip: 'NDC-NR-001', fullName: 'Rina Marlina', roleLabel: 'Perawat Gigi Senior', branchName: 'Baleendah', baseSalary: 4200000, bankName: 'BCA', accountNumber: '7711223344' },
  { nip: 'NDC-FO-001', fullName: 'Maya Putri', roleLabel: 'Kasir & Front Office', branchName: 'Soreang', baseSalary: 3800000, bankName: 'Mandiri', accountNumber: '13100223344' },
  { nip: 'NDC-ADM-001', fullName: 'Sari Dewi Pratiwi', roleLabel: 'Admin Cabang', branchName: 'Soreang', baseSalary: 4000000, bankName: 'BCA', accountNumber: '7722334455' }
]

function formatCurrencyInput(val: number): string {
  if (val === undefined || val === null || isNaN(val)) return '0'
  return new Intl.NumberFormat('id-ID').format(val)
}

function parseCurrencyInput(val: string): number {
  const clean = String(val || '').replace(/[^0-9]/g, '')
  return clean ? parseInt(clean, 10) : 0
}

const selectedEmployeeNip = ref('')

function onSelectEmployeeByNip() {
  if (!selectedEmployeeNip.value) return
  const emp = AVAILABLE_EMPLOYEES.find(item => item.nip === selectedEmployeeNip.value)
  if (emp) {
    form.nip = emp.nip
    form.fullName = emp.fullName
    form.roleLabel = emp.roleLabel
    form.branchName = emp.branchName
    form.baseSalary = emp.baseSalary
    form.bankName = emp.bankName
    form.accountNumber = emp.accountNumber
  }
}

const showFormModal = ref(false)
const editingId = ref<string | null>(null)

const form = reactive({
  nip: '',
  fullName: '',
  roleLabel: 'Dokter Gigi Umum',
  branchName: 'Soreang',
  periodMonth: 9,
  periodYear: 2026,
  baseSalary: 5000000,
  treatmentRevenue: 15000000,
  commissionRatePercent: 15,
  allowanceBonus: 500000,
  transportAllowance: 350000,
  deductions: 100000,
  bpjsDeduction: 150000,
  taxDeduction: 50000,
  bankName: 'BCA',
  accountNumber: '7700112233',
  status: 'PAID' as 'PAID' | 'PENDING' | 'APPROVED'
})

function openCreate() {
  editingId.value = null
  selectedEmployeeNip.value = AVAILABLE_EMPLOYEES[0].nip
  onSelectEmployeeByNip()
  form.periodMonth = selectedMonthFilter.value !== 'all' ? parseInt(selectedMonthFilter.value, 10) : 9
  form.periodYear = selectedYearFilter.value !== 'all' ? parseInt(selectedYearFilter.value, 10) : 2026
  form.treatmentRevenue = 15000000
  form.commissionRatePercent = 15
  form.allowanceBonus = 500000
  form.transportAllowance = 350000
  form.deductions = 100000
  form.bpjsDeduction = 150000
  form.taxDeduction = 50000
  form.status = 'PAID'
  showFormModal.value = true
}

function openEdit(p: StaffPayroll) {
  editingId.value = p.id
  selectedEmployeeNip.value = p.nip
  form.nip = p.nip
  form.fullName = p.fullName
  form.roleLabel = p.roleLabel
  form.branchName = p.branchName
  form.periodMonth = p.periodMonth || 9
  form.periodYear = p.periodYear || 2026
  form.baseSalary = p.baseSalary
  form.treatmentRevenue = p.treatmentRevenue
  form.commissionRatePercent = p.commissionRatePercent
  form.allowanceBonus = p.allowanceBonus
  form.transportAllowance = p.transportAllowance || 350000
  form.deductions = p.deductions
  form.bpjsDeduction = p.bpjsDeduction || 150000
  form.taxDeduction = p.taxDeduction || 50000
  form.bankName = p.bankName || 'BCA'
  form.accountNumber = p.accountNumber || '7700112233'
  form.status = p.status
  showFormModal.value = true
}

function deletePayroll(id: string) {
  const target = localPayrolls.value.find(p => p.id === id)
  if (!target) return
  if (confirm(`Hapus data honor & gaji ${target.fullName} (${target.period})?`)) {
    localPayrolls.value = localPayrolls.value.filter(p => p.id !== id)
    saveToStorage()
    useAppNotification().success(
      `Data honor ${target.fullName} berhasil dihapus.`,
      'Data Terhapus'
    )
  }
}

function savePayroll() {
  if (!form.fullName) {
    alert('Nama pegawai wajib diisi!')
    return
  }

  const comm = Math.round(((form.treatmentRevenue || 0) * (form.commissionRatePercent || 0)) / 100)
  const totalAllowances = (form.allowanceBonus || 0) + (form.transportAllowance || 0)
  const totalDeductions = (form.deductions || 0) + (form.bpjsDeduction || 0) + (form.taxDeduction || 0)
  const net = (form.baseSalary || 0) + comm + totalAllowances - totalDeductions

  const monthName = MONTH_NAMES[(form.periodMonth || 1) - 1] || 'September'
  const periodStr = `${monthName} ${form.periodYear}`

  if (editingId.value) {
    const idx = localPayrolls.value.findIndex(p => p.id === editingId.value)
    if (idx !== -1) {
      localPayrolls.value[idx] = {
        ...localPayrolls.value[idx],
        nip: form.nip,
        fullName: form.fullName,
        roleLabel: form.roleLabel,
        branchName: form.branchName,
        period: periodStr,
        periodMonth: form.periodMonth,
        periodYear: form.periodYear,
        baseSalary: form.baseSalary,
        treatmentRevenue: form.treatmentRevenue,
        commissionRatePercent: form.commissionRatePercent,
        calculatedCommission: comm,
        allowanceBonus: form.allowanceBonus,
        transportAllowance: form.transportAllowance,
        deductions: form.deductions,
        bpjsDeduction: form.bpjsDeduction,
        taxDeduction: form.taxDeduction,
        netPayable: net,
        bankName: form.bankName,
        accountNumber: form.accountNumber,
        status: form.status
      }
      useAppNotification().success(
        `Perubahan honor ${form.fullName} periode ${periodStr} berhasil disimpan.`,
        'Honor Diperbarui'
      )
    }
  } else {
    const newRecord: StaffPayroll = {
      id: `pr-${Date.now()}`,
      nip: form.nip,
      fullName: form.fullName,
      role: form.roleLabel.toLowerCase().includes('dokter') ? 'dokter' : 'staff',
      roleLabel: form.roleLabel,
      branchName: form.branchName,
      period: periodStr,
      periodMonth: form.periodMonth,
      periodYear: form.periodYear,
      baseSalary: form.baseSalary,
      treatmentRevenue: form.treatmentRevenue,
      commissionRatePercent: form.commissionRatePercent,
      calculatedCommission: comm,
      allowanceBonus: form.allowanceBonus,
      transportAllowance: form.transportAllowance,
      deductions: form.deductions,
      bpjsDeduction: form.bpjsDeduction,
      taxDeduction: form.taxDeduction,
      netPayable: net,
      bankName: form.bankName,
      accountNumber: form.accountNumber,
      status: form.status,
      paidAt: new Date().toISOString()
    }
    localPayrolls.value.unshift(newRecord)
    useAppNotification().success(
      `Honor ${form.fullName} periode ${periodStr} berhasil ditambahkan!`,
      'Honor Ditambahkan'
    )
  }

  saveToStorage()
  showFormModal.value = false
}

function printPayrollSlip(p: StaffPayroll) {
  const win = window.open('', '_blank', 'width=850,height=950')
  if (!win) return

  win.document.write(`
    <!DOCTYPE html>
    <html lang="id">
    <head>
      <meta charset="UTF-8">
      <title>SLIP GAJI - ${p.fullName} - ${p.period}</title>
      <style>
        @page { size: A4; margin: 15mm; }
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 20px; color: #1f2937; background: #fff; line-height: 1.5; font-size: 11pt; }
        .kop { display: flex; align-items: center; justify-content: space-between; border-bottom: 2.5px solid #2563eb; padding-bottom: 12px; margin-bottom: 20px; }
        .kop-logo h1 { margin: 0; color: #1d4ed8; font-size: 20pt; font-weight: 800; letter-spacing: 0.5px; }
        .kop-logo p { margin: 2px 0 0; font-size: 9pt; color: #6b7280; }
        .kop-badge { text-align: right; }
        .slip-title { display: inline-block; background: #eff6ff; color: #1d4ed8; font-weight: 700; font-size: 11pt; padding: 4px 12px; border-radius: 6px; border: 1px solid #bfdbfe; }
        .meta-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; background: #f9fafb; padding: 10px; border-radius: 6px; }
        .meta-table td { padding: 6px 10px; font-size: 10pt; }
        .table-data { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
        .table-data th, .table-data td { border: 1px solid #e5e7eb; padding: 10px 12px; font-size: 10pt; }
        .table-data th { background: #f3f4f6; color: #374151; font-weight: 700; }
        .section-hdr { background: #f8fafc; font-weight: 700; color: #1e3a8a; }
        .total-row { font-weight: 800; background: #eff6ff; color: #1e40af; font-size: 12pt; border-top: 2px solid #2563eb; }
        .footer { margin-top: 40px; display: flex; justify-content: space-between; font-size: 10pt; }
        .sign-col { text-align: center; width: 220px; }
        .sign-space { height: 70px; }
        .sign-name { font-weight: 700; border-bottom: 1px solid #1f2937; padding-bottom: 2px; }
        .bank-box { margin-top: 15px; padding: 10px; border: 1px dashed #93c5fd; background: #f0f9ff; border-radius: 6px; font-size: 9.5pt; }
      </style>
    </head>
    <body>
      <div class="kop">
        <div class="kop-logo">
          <h1>NINA DENTAL CARE</h1>
          <p>Klinik Gigi Spesialis & Perawatan Keluarga</p>
          <p>Cabang ${p.branchName} | Telp: +62 812-3400-0002</p>
        </div>
        <div class="kop-badge">
          <div class="slip-title">SLIP GAJI & HONOR</div>
          <p style="margin: 4px 0 0; font-size: 9pt; color: #4b5563;">Periode: <b>${p.period}</b></p>
        </div>
      </div>

      <table class="meta-table">
        <tr>
          <td style="width: 15%; color: #6b7280;">Nama Pegawai</td>
          <td style="width: 35%; font-weight: 700;">${p.fullName}</td>
          <td style="width: 15%; color: #6b7280;">NIP Pegawai</td>
          <td style="width: 35%; font-family: monospace; font-weight: 700;">${p.nip}</td>
        </tr>
        <tr>
          <td style="color: #6b7280;">Jabatan / Role</td>
          <td>${p.roleLabel}</td>
          <td style="color: #6b7280;">Cabang Klinik</td>
          <td><b>${p.branchName}</b></td>
        </tr>
        <tr>
          <td style="color: #6b7280;">Status Transfer</td>
          <td><span style="color: #059669; font-weight: 700;">${p.status === 'PAID' ? 'TERBAYAR (LUNAS)' : 'APPROVED'}</span></td>
          <td style="color: #6b7280;">Rekening Bank</td>
          <td>${p.bankName || 'BCA'} - ${p.accountNumber || '7700112233'}</td>
        </tr>
      </table>

      <table class="table-data">
        <thead>
          <tr>
            <th style="text-align: left; width: 60%;">Komponen Penerimaan & Komisi</th>
            <th style="text-align: right; width: 40%;">Jumlah (Rp)</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Gaji Pokok</td>
            <td style="text-align: right; font-weight: 600;">Rp ${p.baseSalary.toLocaleString('id-ID')}</td>
          </tr>
          ${p.calculatedCommission > 0 ? `
          <tr>
            <td>
              Komisi Tindakan Pasien (${p.commissionRatePercent}%)
              <div style="font-size: 8.5pt; color: #6b7280;">Basis Omset Tindakan: Rp ${p.treatmentRevenue.toLocaleString('id-ID')}</div>
            </td>
            <td style="text-align: right; font-weight: 600; color: #059669;">+ Rp ${p.calculatedCommission.toLocaleString('id-ID')}</td>
          </tr>` : ''}
          <tr>
            <td>Tunjangan Transport & Kehadiran</td>
            <td style="text-align: right; font-weight: 600;">+ Rp ${(p.transportAllowance || 350000).toLocaleString('id-ID')}</td>
          </tr>
          <tr>
            <td>Bonus Insentif & Kinerja</td>
            <td style="text-align: right; font-weight: 600;">+ Rp ${(p.allowanceBonus || 0).toLocaleString('id-ID')}</td>
          </tr>
          <tr class="section-hdr">
            <th style="text-align: left;">Komponen Potongan</th>
            <th style="text-align: right;">Jumlah Potongan (Rp)</th>
          </tr>
          <tr>
            <td>Iuran BPJS Ketenagakerjaan / Kesehatan</td>
            <td style="text-align: right; color: #dc2626;">- Rp ${(p.bpjsDeduction || 150000).toLocaleString('id-ID')}</td>
          </tr>
          <tr>
            <td>Potongan Pajak PPh 21 / Kasbon Staf</td>
            <td style="text-align: right; color: #dc2626;">- Rp ${(p.taxDeduction || 50000).toLocaleString('id-ID')}</td>
          </tr>
          ${p.deductions > 0 ? `
          <tr>
            <td>Potongan Lainnya / Keterlambatan</td>
            <td style="text-align: right; color: #dc2626;">- Rp ${p.deductions.toLocaleString('id-ID')}</td>
          </tr>` : ''}
          <tr class="total-row">
            <td>TOTAL TAKE-HOME PAY (NET DITERIMA)</td>
            <td style="text-align: right;">Rp ${p.netPayable.toLocaleString('id-ID')}</td>
          </tr>
        </tbody>
      </table>

      <div class="bank-box">
        <b>Catatan Finansial:</b> Pembayaran honor ini telah ditransfer via ${p.bankName || 'BCA'} ke No. Rekening <b>${p.accountNumber || '7700112233'}</b> a.n. ${p.fullName}. Harap simpan slip ini sebagai arsip resmi penerimaan honor Nina Dental Care.
      </div>

      <div class="footer">
        <div class="sign-col">
          <p>Penerima Honor,</p>
          <div class="sign-space"></div>
          <div class="sign-name">${p.fullName}</div>
          <p style="font-size: 8.5pt; color: #6b7280; margin-top: 2px;">NIP: ${p.nip}</p>
        </div>
        <div class="sign-col">
          <p>Manajer Keuangan NDC,</p>
          <div class="sign-space"></div>
          <div class="sign-name">Maya Putri, S.E.</div>
          <p style="font-size: 8.5pt; color: #6b7280; margin-top: 2px;">Finance Department</p>
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
  <div class="p-6 space-y-6 w-full max-w-none print:p-0">
    <!-- Header (Hidden on print) -->
    <div class="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-4 print:hidden">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white flex items-center gap-2">
          <UIcon name="i-lucide-receipt" class="w-7 h-7 text-primary" />
          Manajemen Honor & Gaji Pegawai
        </h1>
        <p class="text-xs text-gray-500 dark:text-gray-400 mt-1">
          Pengelolaan gaji pokok, insentif tindakan dokter/spesialis, tunjangan, potongan BPJS/PPh, dan pencetakan slip gaji resmi per periode.
        </p>
      </div>

      <!-- Quick Action Buttons -->
      <div class="flex items-center gap-2 flex-wrap">
        <UButton
          icon="i-lucide-plus"
          label="+ Tambah Honor/Gaji"
          color="primary"
          class="font-bold shadow-xs"
          @click="openCreate"
        />
      </div>
    </div>

    <!-- Filter Bar Card -->
    <UCard class="bg-white dark:bg-gray-800 shadow-xs">
      <div class="flex flex-wrap items-center justify-between gap-3 text-xs">
        <div class="flex items-center gap-2 flex-wrap w-full md:w-auto">
          <!-- Search input -->
          <UInput
            v-model="search"
            icon="i-lucide-search"
            placeholder="Cari nama, NIP, jabatan..."
            class="w-full sm:w-56"
          />

          <!-- Branch filter -->
          <select
            v-model="selectedBranchFilter"
            class="px-3 py-1.5 text-xs rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 font-medium cursor-pointer"
          >
            <option value="all">Semua Cabang</option>
            <option value="Soreang">Cabang Soreang</option>
            <option value="Baleendah">Cabang Baleendah</option>
          </select>

          <!-- Role filter -->
          <select
            v-model="selectedRoleFilter"
            class="px-3 py-1.5 text-xs rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 font-medium cursor-pointer"
          >
            <option value="all">Semua Jabatan</option>
            <option value="Dokter Spesialis Ortodonti">Spesialis Ortodonti</option>
            <option value="Dokter Gigi Umum">Dokter Gigi Umum</option>
            <option value="Dokter Spesialis Gigi Anak">Spesialis Gigi Anak</option>
            <option value="Dokter Spesialis Konservasi Gigi">Spesialis Konservasi</option>
            <option value="Perawat Gigi Senior">Perawat Gigi</option>
            <option value="Kasir & Front Office">Kasir & FO</option>
            <option value="Admin Cabang">Admin Cabang</option>
          </select>
        </div>

        <!-- Period Selectors: Flexible Month & Year -->
        <div class="flex items-center gap-2 bg-primary-50/50 dark:bg-primary-950/20 p-1.5 rounded-lg border border-primary-200/60 dark:border-primary-800/60">
          <UIcon name="i-lucide-calendar" class="w-4 h-4 text-primary" />
          <span class="font-bold text-[11px] text-primary-700 dark:text-primary-300">Periode:</span>

          <!-- Month Selector -->
          <select
            v-model="selectedMonthFilter"
            class="px-2.5 py-1 text-xs rounded-md border border-primary-300 dark:border-primary-700 bg-white dark:bg-gray-800 font-bold cursor-pointer text-gray-800 dark:text-gray-100"
          >
            <option v-for="m in MONTH_OPTIONS" :key="m.value" :value="m.value">
              {{ m.label }}
            </option>
          </select>

          <!-- Year Selector -->
          <select
            v-model="selectedYearFilter"
            class="px-2.5 py-1 text-xs rounded-md border border-primary-300 dark:border-primary-700 bg-white dark:bg-gray-800 font-bold cursor-pointer text-gray-800 dark:text-gray-100"
          >
            <option v-for="y in YEAR_OPTIONS" :key="y.value" :value="y.value">
              {{ y.label }}
            </option>
          </select>
        </div>
      </div>
    </UCard>

    <!-- Summary Stats (Hidden on print) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 print:hidden">
      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Total Pengeluaran Gaji
            </p>
            <p class="text-2xl font-extrabold text-primary mt-1">
              {{ formatIDR(stats.totalNet) }}
            </p>
          </div>
          <div class="p-3 bg-primary-50 dark:bg-primary-950/30 text-primary rounded-xl">
            <UIcon name="i-lucide-wallet" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Total Komisi Tindakan
            </p>
            <p class="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-1">
              {{ formatIDR(stats.totalCommission) }}
            </p>
          </div>
          <div class="p-3 bg-emerald-50 dark:bg-emerald-950/30 text-emerald-600 rounded-xl">
            <UIcon name="i-lucide-award" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Total Gaji Pokok
            </p>
            <p class="text-2xl font-extrabold text-blue-600 dark:text-blue-400 mt-1">
              {{ formatIDR(stats.totalBase) }}
            </p>
          </div>
          <div class="p-3 bg-blue-50 dark:bg-blue-950/30 text-blue-600 rounded-xl">
            <UIcon name="i-lucide-banknote" class="w-6 h-6" />
          </div>
        </div>
      </UCard>

      <UCard class="bg-white dark:bg-gray-800">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wider">
              Pegawai Diterbitkan
            </p>
            <p class="text-2xl font-extrabold text-purple-600 dark:text-purple-400 mt-1">
              {{ stats.totalCount }} Pegawai
            </p>
          </div>
          <div class="p-3 bg-purple-50 dark:bg-purple-950/30 text-purple-600 rounded-xl">
            <UIcon name="i-lucide-users" class="w-6 h-6" />
          </div>
        </div>
      </UCard>
    </div>

    <!-- Main Payroll Table (Hidden on print) -->
    <UCard :ui="{ body: 'p-0 sm:p-0' }" class="bg-white dark:bg-gray-800 print:hidden overflow-hidden space-y-3">
      <div class="overflow-x-auto">
        <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
          <thead class="bg-gray-50 dark:bg-gray-800 text-[11px] font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th class="px-4 py-3.5">Pegawai</th>
              <th class="px-4 py-3.5">Jabatan / Role</th>
              <th class="px-4 py-3.5">Cabang</th>
              <th class="px-4 py-3.5">Periode</th>
              <th class="px-4 py-3.5">Gaji Pokok</th>
              <th class="px-4 py-3.5">Komisi Tindakan</th>
              <th class="px-4 py-3.5">Tunjangan & Bonus</th>
              <th class="px-4 py-3.5 font-bold">Total Net Pay</th>
              <th class="px-4 py-3.5">Status</th>
              <th class="px-4 py-3.5 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr v-if="paginatedPayrolls.length === 0">
              <td colspan="10" class="px-4 py-8 text-center text-gray-400">
                Tidak ada data honor & gaji yang sesuai dengan filter pencarian / periode.
              </td>
            </tr>
            <tr v-for="item in paginatedPayrolls" :key="item.id" class="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors">
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div class="font-bold text-gray-900 dark:text-white">{{ item.fullName }}</div>
                <div class="text-[11px] font-mono text-gray-400">{{ item.nip }}</div>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge color="gray" variant="subtle" size="xs">{{ item.roleLabel }}</UBadge>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                {{ item.branchName }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge color="primary" variant="subtle" size="xs" class="font-semibold">
                  {{ item.period }}
                </UBadge>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-medium">
                {{ formatIDR(item.baseSalary) }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-medium text-emerald-600 dark:text-emerald-400">
                {{ formatIDR(item.calculatedCommission) }}
                <span v-if="item.commissionRatePercent > 0" class="text-[10px] text-gray-400"> ({{ item.commissionRatePercent }}%)</span>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-medium text-blue-600">
                +{{ formatIDR((item.allowanceBonus || 0) + (item.transportAllowance || 0)) }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-extrabold text-sm text-gray-900 dark:text-white">
                {{ formatIDR(item.netPayable) }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge :color="item.status === 'PAID' ? 'success' : 'warning'" variant="soft" size="xs">
                  {{ item.status === 'PAID' ? 'TERBAYAR' : 'APPROVED' }}
                </UBadge>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap text-right">
                <div class="flex items-center justify-end gap-1">
                  <UButton
                    size="xs"
                    color="primary"
                    variant="outline"
                    icon="i-lucide-printer"
                    label="Cetak"
                    @click="printPayrollSlip(item)"
                  />
                  <UButton
                    size="xs"
                    color="neutral"
                    variant="ghost"
                    icon="i-lucide-edit-2"
                    label="Edit"
                    @click="openEdit(item)"
                  />
                  <UButton
                    size="xs"
                    color="error"
                    variant="ghost"
                    icon="i-lucide-trash-2"
                    label="Hapus"
                    @click="deletePayroll(item.id)"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination Footer -->
      <div class="flex items-center justify-between px-4 py-3 border-t text-xs text-gray-500">
        <span>Menampilkan {{ paginatedPayrolls.length }} dari {{ displayPayrolls.length }} data honor</span>
        <div class="flex items-center gap-2">
          <UButton icon="i-lucide-chevron-left" size="xs" color="neutral" variant="outline" :disabled="page <= 1" @click="page--" />
          <span class="font-semibold text-gray-900 dark:text-white">Hal {{ page }} / {{ totalPages }}</span>
          <UButton icon="i-lucide-chevron-right" size="xs" color="neutral" variant="outline" :disabled="page >= totalPages" @click="page++" />
        </div>
      </div>
    </UCard>

    <!-- Create / Edit Form Modal -->
    <UModal v-model:open="showFormModal" :title="editingId ? 'Edit Honor & Gaji Pegawai' : 'Tambah Honor & Gaji Pegawai Baru'">
      <template #body>
        <form class="space-y-3.5 text-xs" @submit.prevent="savePayroll">
          <!-- Selection Pegawai Dropdown -->
          <div class="p-3 bg-primary-50/50 dark:bg-primary-950/20 border border-primary-200 dark:border-primary-800 rounded-xl space-y-2">
            <label class="block font-bold text-primary-700 dark:text-primary-300">Pilih Pegawai / Dokter *</label>
            <select
              v-model="selectedEmployeeNip"
              class="w-full p-2.5 border border-primary-300 dark:border-primary-700 rounded-lg text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold cursor-pointer text-xs"
              @change="onSelectEmployeeByNip"
            >
              <option v-for="emp in AVAILABLE_EMPLOYEES" :key="emp.nip" :value="emp.nip">
                {{ emp.fullName }} — {{ emp.roleLabel }} ({{ emp.branchName }}) [{{ emp.nip }}]
              </option>
            </select>
          </div>

          <!-- Periode Bulan & Tahun Referensi Fleksibel -->
          <div class="p-3 bg-gray-50 dark:bg-gray-900 rounded-xl border border-gray-200 dark:border-gray-700 space-y-2">
            <span class="block font-bold text-gray-800 dark:text-gray-200">Referensi Periode Honor & Gaji *</span>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="block text-[11px] font-medium text-gray-500 mb-1">Bulan Periode</label>
                <select
                  v-model.number="form.periodMonth"
                  class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800 font-semibold text-gray-900 dark:text-white"
                  required
                >
                  <option v-for="(mName, idx) in MONTH_NAMES" :key="idx" :value="idx + 1">
                    {{ mName }}
                  </option>
                </select>
              </div>
              <div>
                <label class="block text-[11px] font-medium text-gray-500 mb-1">Tahun Periode</label>
                <select
                  v-model.number="form.periodYear"
                  class="w-full p-2 border rounded-lg bg-white dark:bg-gray-800 font-semibold text-gray-900 dark:text-white"
                  required
                >
                  <option :value="2024">2024</option>
                  <option :value="2025">2025</option>
                  <option :value="2026">2026</option>
                  <option :value="2027">2027</option>
                  <option :value="2028">2028</option>
                </select>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">NIP Pegawai</label>
              <input v-model="form.nip" type="text" class="w-full p-2 border rounded bg-gray-50 dark:bg-gray-800 text-gray-900 dark:text-white font-mono" required readonly>
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Nama Lengkap Pegawai *</label>
              <input v-model="form.fullName" type="text" class="w-full p-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold" required>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Jabatan / Role</label>
              <select v-model="form.roleLabel" class="w-full p-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800">
                <option value="Dokter Spesialis Ortodonti">Dokter Spesialis Ortodonti</option>
                <option value="Dokter Gigi Umum">Dokter Gigi Umum</option>
                <option value="Dokter Spesialis Gigi Anak">Dokter Spesialis Gigi Anak</option>
                <option value="Dokter Spesialis Konservasi Gigi">Dokter Spesialis Konservasi Gigi</option>
                <option value="Perawat Gigi Senior">Perawat Gigi Senior</option>
                <option value="Kasir & Front Office">Kasir & Front Office</option>
                <option value="Admin Cabang">Admin Cabang</option>
              </select>
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Cabang Klinik</label>
              <select v-model="form.branchName" class="w-full p-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800">
                <option value="Soreang">Soreang</option>
                <option value="Baleendah">Baleendah</option>
              </select>
            </div>
          </div>

          <!-- Component Gaji Pokok & Komisi -->
          <div class="grid grid-cols-3 gap-2">
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Gaji Pokok (Rp)</label>
              <div class="relative">
                <span class="absolute left-2.5 top-2 text-gray-400 font-semibold text-xs">Rp</span>
                <input
                  :value="formatCurrencyInput(form.baseSalary)"
                  type="text"
                  class="w-full pl-8 pr-2 py-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold"
                  @input="e => form.baseSalary = parseCurrencyInput((e.target as HTMLInputElement).value)"
                >
              </div>
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Omset Tindakan (Rp)</label>
              <div class="relative">
                <span class="absolute left-2.5 top-2 text-gray-400 font-semibold text-xs">Rp</span>
                <input
                  :value="formatCurrencyInput(form.treatmentRevenue)"
                  type="text"
                  class="w-full pl-8 pr-2 py-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold"
                  @input="e => form.treatmentRevenue = parseCurrencyInput((e.target as HTMLInputElement).value)"
                >
              </div>
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Rate Komisi (%)</label>
              <input v-model.number="form.commissionRatePercent" type="number" class="w-full p-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold">
            </div>
          </div>

          <!-- Tunjangan & Bonus -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Tunjangan Transport & Makan (Rp)</label>
              <div class="relative">
                <span class="absolute left-2.5 top-2 text-gray-400 font-semibold text-xs">Rp</span>
                <input
                  :value="formatCurrencyInput(form.transportAllowance)"
                  type="text"
                  class="w-full pl-8 pr-2 py-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold"
                  @input="e => form.transportAllowance = parseCurrencyInput((e.target as HTMLInputElement).value)"
                >
              </div>
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Bonus Performa & Kehadiran (Rp)</label>
              <div class="relative">
                <span class="absolute left-2.5 top-2 text-gray-400 font-semibold text-xs">Rp</span>
                <input
                  :value="formatCurrencyInput(form.allowanceBonus)"
                  type="text"
                  class="w-full pl-8 pr-2 py-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold"
                  @input="e => form.allowanceBonus = parseCurrencyInput((e.target as HTMLInputElement).value)"
                >
              </div>
            </div>
          </div>

          <!-- Potongan BPJS & Tax -->
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Potongan BPJS (Rp)</label>
              <div class="relative">
                <span class="absolute left-2.5 top-2 text-gray-400 font-semibold text-xs">Rp</span>
                <input
                  :value="formatCurrencyInput(form.bpjsDeduction)"
                  type="text"
                  class="w-full pl-8 pr-2 py-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold text-red-600"
                  @input="e => form.bpjsDeduction = parseCurrencyInput((e.target as HTMLInputElement).value)"
                >
              </div>
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Potongan PPh 21 / Kasbon (Rp)</label>
              <div class="relative">
                <span class="absolute left-2.5 top-2 text-gray-400 font-semibold text-xs">Rp</span>
                <input
                  :value="formatCurrencyInput(form.taxDeduction)"
                  type="text"
                  class="w-full pl-8 pr-2 py-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold text-red-600"
                  @input="e => form.taxDeduction = parseCurrencyInput((e.target as HTMLInputElement).value)"
                >
              </div>
            </div>
          </div>

          <!-- Rekening Transfer Pegawai & Status -->
          <div class="grid grid-cols-3 gap-3 p-2.5 bg-gray-50 dark:bg-gray-900 rounded-lg border">
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Bank Transfer</label>
              <select v-model="form.bankName" class="w-full p-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-semibold">
                <option value="BCA">Bank BCA</option>
                <option value="Mandiri">Bank Mandiri</option>
                <option value="BNI">Bank BNI</option>
                <option value="BRI">Bank BRI</option>
                <option value="Tunai">Tunai Kasir</option>
              </select>
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Nomor Rekening</label>
              <input v-model="form.accountNumber" type="text" placeholder="No. Rekening Pegawai" class="w-full p-2 border rounded font-mono text-gray-900 dark:text-white bg-white dark:bg-gray-800">
            </div>
            <div>
              <label class="block font-semibold mb-1 text-gray-700 dark:text-gray-300">Status Pembayaran</label>
              <select v-model="form.status" class="w-full p-2 border rounded text-gray-900 dark:text-white bg-white dark:bg-gray-800 font-bold">
                <option value="PAID">TERBAYAR (PAID)</option>
                <option value="APPROVED">DISETUJUI (APPROVED)</option>
                <option value="PENDING">PENDING</option>
              </select>
            </div>
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t">
            <UButton label="Batal" color="neutral" variant="ghost" @click="showFormModal = false" />
            <UButton :label="editingId ? 'Simpan Perubahan' : 'Tambah Honor/Gaji'" color="primary" type="submit" />
          </div>
        </form>
      </template>
    </UModal>
  </div>
</template>
