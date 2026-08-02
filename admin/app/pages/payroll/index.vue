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
  deductions: number
  netPayable: number
  status: 'PAID' | 'PENDING' | 'APPROVED'
  period: string
}

const selectedPeriod = ref('2026-08')

const initialPayrolls: StaffPayroll[] = [
  {
    id: 'pr-101',
    nip: 'NDC-DR-001',
    fullName: 'drg. Friski Raisis, Sp.Ort',
    role: 'dokter_spesialis',
    roleLabel: 'Dokter Spesialis Ortodonti',
    branchName: 'Soreang',
    baseSalary: 6000000,
    treatmentRevenue: 28500000,
    commissionRatePercent: 20,
    calculatedCommission: 5700000,
    allowanceBonus: 850000,
    deductions: 250000,
    netPayable: 12300000,
    status: 'PAID',
    period: 'Agustus 2026'
  },
  {
    id: 'pr-102',
    nip: 'NDC-DR-002',
    fullName: 'drg. Siti Aminah',
    role: 'dokter_umum',
    roleLabel: 'Dokter Gigi Umum',
    branchName: 'Baleendah',
    baseSalary: 5000000,
    treatmentRevenue: 19800000,
    commissionRatePercent: 18,
    calculatedCommission: 3564000,
    allowanceBonus: 600000,
    deductions: 150000,
    netPayable: 9014000,
    status: 'APPROVED',
    period: 'Agustus 2026'
  },
  {
    id: 'pr-103',
    nip: 'NDC-DR-003',
    fullName: 'drg. Budi Santoso, Sp.KGA',
    role: 'dokter_spesialis',
    roleLabel: 'Dokter Spesialis Gigi Anak',
    branchName: 'Soreang',
    baseSalary: 6000000,
    treatmentRevenue: 24200000,
    commissionRatePercent: 20,
    calculatedCommission: 4840000,
    allowanceBonus: 750000,
    deductions: 200000,
    netPayable: 11390000,
    status: 'APPROVED',
    period: 'Agustus 2026'
  },
  {
    id: 'pr-104',
    nip: 'NDC-NR-001',
    fullName: 'Rina Marlina',
    role: 'perawat',
    roleLabel: 'Perawat Gigi Senior',
    branchName: 'Baleendah',
    baseSalary: 4200000,
    treatmentRevenue: 0,
    commissionRatePercent: 5,
    calculatedCommission: 850000,
    allowanceBonus: 400000,
    deductions: 100000,
    netPayable: 5350000,
    status: 'PAID',
    period: 'Agustus 2026'
  },
  {
    id: 'pr-105',
    nip: 'NDC-FO-001',
    fullName: 'Maya Putri',
    role: 'front_office',
    roleLabel: 'Kasir & Front Office',
    branchName: 'Soreang',
    baseSalary: 3800000,
    treatmentRevenue: 0,
    commissionRatePercent: 0,
    calculatedCommission: 0,
    allowanceBonus: 500000,
    deductions: 50000,
    netPayable: 4250000,
    status: 'PAID',
    period: 'Agustus 2026'
  }
]

const payrolls = ref<StaffPayroll[]>([...initialPayrolls])
const selectedPayroll = ref<StaffPayroll | null>(null)
const showPrintSlipModal = ref(false)

const stats = computed(() => {
  const totalNet = payrolls.value.reduce((sum, p) => sum + p.netPayable, 0)
  const totalCommission = payrolls.value.reduce((sum, p) => sum + p.calculatedCommission, 0)
  const totalBase = payrolls.value.reduce((sum, p) => sum + p.baseSalary, 0)
  const totalCount = payrolls.value.length

  return { totalNet, totalCommission, totalBase, totalCount }
})

const search = ref('')
const page = ref(1)
const pageSize = 10

const displayPayrolls = computed(() => {
  return payrolls.value.filter(p => {
    if (!search.value) return true
    const q = search.value.toLowerCase()
    return (p.fullName || '').toLowerCase().includes(q) || (p.nip || '').toLowerCase().includes(q) || (p.roleLabel || '').toLowerCase().includes(q)
  })
})

const totalPages = computed(() => Math.ceil(displayPayrolls.value.length / pageSize) || 1)
const paginatedPayrolls = computed(() => {
  const start = (page.value - 1) * pageSize
  return displayPayrolls.value.slice(start, start + pageSize)
})

// --- CRUD Functionality ---
const showFormModal = ref(false)
const editingId = ref<string | null>(null)
const form = reactive({
  nip: '',
  fullName: '',
  roleLabel: 'Dokter Gigi Umum',
  branchName: 'Soreang',
  baseSalary: 5000000,
  treatmentRevenue: 15000000,
  commissionRatePercent: 15,
  allowanceBonus: 500000,
  deductions: 100000,
  status: 'PAID' as 'PAID' | 'PENDING' | 'APPROVED'
})

function openCreate() {
  editingId.value = null
  form.nip = `NDC-EMP-00${payrolls.value.length + 1}`
  form.fullName = ''
  form.roleLabel = 'Dokter Gigi Umum'
  form.branchName = 'Soreang'
  form.baseSalary = 5000000
  form.treatmentRevenue = 15000000
  form.commissionRatePercent = 15
  form.allowanceBonus = 500000
  form.deductions = 100000
  form.status = 'PAID'
  showFormModal.value = true
}

function openEdit(p: StaffPayroll) {
  editingId.value = p.id
  form.nip = p.nip
  form.fullName = p.fullName
  form.roleLabel = p.roleLabel
  form.branchName = p.branchName
  form.baseSalary = p.baseSalary
  form.treatmentRevenue = p.treatmentRevenue
  form.commissionRatePercent = p.commissionRatePercent
  form.allowanceBonus = p.allowanceBonus
  form.deductions = p.deductions
  form.status = p.status
  showFormModal.value = true
}

function deletePayroll(id: string) {
  if (confirm('Hapus data payroll pegawai ini?')) {
    payrolls.value = payrolls.value.filter(p => p.id !== id)
  }
}

function savePayroll() {
  if (!form.fullName) return
  const comm = Math.round((form.treatmentRevenue * form.commissionRatePercent) / 100)
  const net = form.baseSalary + comm + form.allowanceBonus - form.deductions

  if (editingId.value) {
    const idx = payrolls.value.findIndex(p => p.id === editingId.value)
    if (idx !== -1) {
      payrolls.value[idx] = {
        ...payrolls.value[idx],
        fullName: form.fullName,
        roleLabel: form.roleLabel,
        branchName: form.branchName,
        baseSalary: form.baseSalary,
        treatmentRevenue: form.treatmentRevenue,
        commissionRatePercent: form.commissionRatePercent,
        calculatedCommission: comm,
        allowanceBonus: form.allowanceBonus,
        deductions: form.deductions,
        netPayable: net,
        status: form.status
      }
    }
  } else {
    payrolls.value.unshift({
      id: `pr-${Date.now()}`,
      nip: form.nip,
      fullName: form.fullName,
      role: 'staff',
      roleLabel: form.roleLabel,
      branchName: form.branchName,
      baseSalary: form.baseSalary,
      treatmentRevenue: form.treatmentRevenue,
      commissionRatePercent: form.commissionRatePercent,
      calculatedCommission: comm,
      allowanceBonus: form.allowanceBonus,
      deductions: form.deductions,
      netPayable: net,
      status: form.status,
      period: 'Agustus 2026'
    })
  }
  showFormModal.value = false
}

function printPayrollSlip(p: StaffPayroll) {
  const win = window.open('', '_blank', 'width=800,height=900')
  if (!win) return
  win.document.write(`
    <!DOCTYPE html>
    <html>
    <head>
      <title>SLIP GAJI - ${p.fullName}</title>
      <style>
        body { font-family: sans-serif; padding: 24px; color: #111827; }
        .header { text-align: center; border-bottom: 2px solid #2563eb; padding-bottom: 12px; margin-bottom: 20px; }
        .header h2 { margin: 0; color: #2563eb; font-size: 20px; }
        .header p { margin: 4px 0 0 0; font-size: 11px; color: #6b7280; }
        .table { width: 100%; border-collapse: collapse; margin: 16px 0; }
        .table th, .table td { border: 1px solid #e5e7eb; padding: 8px; font-size: 12px; }
        .table th { background: #f3f4f6; text-align: left; }
        .total-row { font-weight: bold; background: #eff6ff; font-size: 13px; }
        .footer { margin-top: 40px; display: flex; justify-content: space-between; font-size: 11px; }
      </style>
    </head>
    <body>
      <div class="header">
        <h2>NINA DENTAL CARE</h2>
        <p>Jl. Terusan Kopo No. 8, ${p.branchName}, Bandung | Telp: +62 812-3400-0002</p>
        <p><b>SLIP GAJI & HONORarium PEGAWAI (${p.period})</b></p>
      </div>

      <table style="width:100%; font-size:12px; margin-bottom:16px;">
        <tr><td><b>Nama Pegawai:</b> ${p.fullName}</td><td><b>NIP:</b> ${p.nip}</td></tr>
        <tr><td><b>Jabatan:</b> ${p.roleLabel}</td><td><b>Cabang:</b> ${p.branchName}</td></tr>
      </table>

      <table class="table">
        <thead>
          <tr><th>Komponen Gaji / Honor</th><th style="text-align:right;">Jumlah (Rp)</th></tr>
        </thead>
        <tbody>
          <tr><td>Gaji Pokok</td><td style="text-align:right;">${p.baseSalary.toLocaleString('id-ID')}</td></tr>
          <tr><td>Komisi Tindakan (${p.commissionRatePercent}%)</td><td style="text-align:right;">${p.calculatedCommission.toLocaleString('id-ID')}</td></tr>
          <tr><td>Bonus & Tunjangan</td><td style="text-align:right;">${p.allowanceBonus.toLocaleString('id-ID')}</td></tr>
          <tr><td>Potongan</td><td style="text-align:right;">-${p.deductions.toLocaleString('id-ID')}</td></tr>
          <tr class="total-row"><td>TOTAL NET GAJI DITERIMA</td><td style="text-align:right;">${p.netPayable.toLocaleString('id-ID')}</td></tr>
        </tbody>
      </table>

      <div class="footer">
        <div><p>Penerima,</p><br><br><br><p>( ${p.fullName} )</p></div>
        <div><p>Manajer Keuangan,</p><br><br><br><p>( Bendahara NDC )</p></div>
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
  <div class="p-6 space-y-6 w-full max-w-none print:p-0">
    <!-- Header (Hidden on print) -->
    <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 print:hidden">
      <div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900 dark:text-white">
          Manajemen Honor & Gaji Pegawai
        </h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          Pengelolaan gaji pokok, komisi tindakan dokter/perawat, bonus, dan pencetakan slip gaji resmi.
        </p>
      </div>

      <div class="flex items-center gap-3">
        <UInput
          v-model="search"
          icon="i-lucide-search"
          placeholder="Cari pegawai / NIP..."
          class="w-48"
        />
        <select
          v-model="selectedPeriod"
          class="px-3 py-1.5 text-sm rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 font-medium"
        >
          <option value="2026-08">Periode: Agustus 2026</option>
          <option value="2026-07">Periode: Juli 2026</option>
          <option value="2026-06">Periode: Juni 2026</option>
        </select>
        <UButton
          icon="i-lucide-plus"
          label="+ Tambah Honor/Gaji"
          color="primary"
          @click="openCreate"
        />
      </div>
    </div>

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
              <th class="px-4 py-3.5">Gaji Pokok</th>
              <th class="px-4 py-3.5">Komisi Tindakan</th>
              <th class="px-4 py-3.5">Bonus / Tunjangan</th>
              <th class="px-4 py-3.5 font-bold">Total Net Pay</th>
              <th class="px-4 py-3.5">Status</th>
              <th class="px-4 py-3.5 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
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
              <td class="px-4 py-3.5 whitespace-nowrap font-medium">
                {{ formatIDR(item.baseSalary) }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-medium text-emerald-600 dark:text-emerald-400">
                {{ formatIDR(item.calculatedCommission) }}
                <span v-if="item.commissionRatePercent > 0" class="text-[10px] text-gray-400"> ({{ item.commissionRatePercent }}%)</span>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-medium text-blue-600">
                +{{ formatIDR(item.allowanceBonus) }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-extrabold text-sm text-gray-900 dark:text-white">
                {{ formatIDR(item.netPayable) }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge :color="item.status === 'PAID' ? 'green' : 'amber'" variant="soft" size="xs">
                  {{ item.status === 'PAID' ? 'TERBAYAR' : 'APPROVED' }}
                </UBadge>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap text-right">
                <div class="flex items-center justify-end gap-1">
                  <UButton
                    size="xs"
                    color="primary"
                    variant="subtle"
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
        <form class="space-y-3 text-xs" @submit.prevent="savePayroll">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1">NIP Pegawai</label>
              <input v-model="form.nip" type="text" class="w-full p-2 border rounded" required>
            </div>
            <div>
              <label class="block font-semibold mb-1">Nama Lengkap Pegawai *</label>
              <input v-model="form.fullName" type="text" placeholder="Nama dokter / staff..." class="w-full p-2 border rounded" required>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1">Jabatan / Role</label>
              <select v-model="form.roleLabel" class="w-full p-2 border rounded">
                <option value="Dokter Spesialis Ortodonti">Dokter Spesialis Ortodonti</option>
                <option value="Dokter Gigi Umum">Dokter Gigi Umum</option>
                <option value="Dokter Spesialis Gigi Anak">Dokter Spesialis Gigi Anak</option>
                <option value="Perawat Gigi Senior">Perawat Gigi Senior</option>
                <option value="Kasir & Front Office">Kasir & Front Office</option>
              </select>
            </div>
            <div>
              <label class="block font-semibold mb-1">Cabang Klinik</label>
              <select v-model="form.branchName" class="w-full p-2 border rounded">
                <option value="Soreang">Soreang</option>
                <option value="Baleendah">Baleendah</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-3 gap-2">
            <div>
              <label class="block font-semibold mb-1">Gaji Pokok (Rp)</label>
              <input v-model.number="form.baseSalary" type="number" class="w-full p-2 border rounded">
            </div>
            <div>
              <label class="block font-semibold mb-1">Omset Tindakan (Rp)</label>
              <input v-model.number="form.treatmentRevenue" type="number" class="w-full p-2 border rounded">
            </div>
            <div>
              <label class="block font-semibold mb-1">Rate Komisi (%)</label>
              <input v-model.number="form.commissionRatePercent" type="number" class="w-full p-2 border rounded">
            </div>
          </div>

          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="block font-semibold mb-1">Bonus & Tunjangan (Rp)</label>
              <input v-model.number="form.allowanceBonus" type="number" class="w-full p-2 border rounded">
            </div>
            <div>
              <label class="block font-semibold mb-1">Potongan (Rp)</label>
              <input v-model.number="form.deductions" type="number" class="w-full p-2 border rounded">
            </div>
          </div>

          <div class="flex justify-end gap-2 pt-3 border-t">
            <UButton label="Batal" color="neutral" variant="ghost" @click="showFormModal = false" />
            <UButton :label="editingId ? 'Simpan Perubahan' : 'Tambah Honor/Gaji'" color="primary" type="submit" />
          </div>
        </form>
      </template>
    </UModal>

    <!-- Slip Gaji Modal / Print Template -->
    <UModal v-model:open="showPrintSlipModal" :ui="{ width: 'sm:max-w-2xl' }">
      <UCard v-if="selectedPayroll" class="bg-white text-gray-900 print:shadow-none print:border-none">
        <template #header>
          <div class="flex items-center justify-between print:hidden">
            <h3 class="font-bold text-gray-900">Preview Slip Gaji / Honor</h3>
            <div class="flex items-center gap-2">
              <UButton icon="i-lucide-printer" label="Cetak / Download PDF" color="primary" size="xs" @click="triggerPrint" />
              <UButton icon="i-lucide-x" color="gray" variant="ghost" size="xs" @click="showPrintSlipModal = false" />
            </div>
          </div>
        </template>

        <!-- Official Printable Slip Document Template -->
        <div id="printable-slip" class="p-4 space-y-6 text-xs text-gray-900 bg-white font-sans">
          <!-- Kop Header Klinik -->
          <div class="flex items-center justify-between pb-4 border-b-2 border-primary">
            <div>
              <h2 class="text-xl font-extrabold tracking-wider text-primary">NINA DENTAL CARE</h2>
              <p class="text-[11px] text-gray-600">Klinik Dokter Gigi Spesialis & General Dental Care</p>
              <p class="text-[10px] text-gray-500">Cabang Soreang & Baleendah, Kab. Bandung | WA: 0811-2345-001</p>
            </div>
            <div class="text-right">
              <span class="inline-block px-3 py-1 bg-primary-50 text-primary font-bold text-sm rounded">SLIP GAJI & HONOR</span>
              <p class="text-[11px] text-gray-500 mt-1">Periode: {{ selectedPayroll.period }}</p>
            </div>
          </div>

          <!-- Employee Profile Details Grid -->
          <div class="grid grid-cols-2 gap-4 bg-gray-50 p-3 rounded-lg border border-gray-200">
            <div>
              <table class="w-full text-left">
                <tr><td class="text-gray-500 w-24">NIP:</td><td class="font-mono font-bold">{{ selectedPayroll.nip }}</td></tr>
                <tr><td class="text-gray-500">Nama Pegawai:</td><td class="font-bold">{{ selectedPayroll.fullName }}</td></tr>
                <tr><td class="text-gray-500">Jabatan:</td><td>{{ selectedPayroll.roleLabel }}</td></tr>
              </table>
            </div>
            <div>
              <table class="w-full text-left">
                <tr><td class="text-gray-500 w-24">Cabang:</td><td class="font-bold">{{ selectedPayroll.branchName }}</td></tr>
                <tr><td class="text-gray-500">Tanggal Cetak:</td><td>02 Agustus 2026</td></tr>
                <tr><td class="text-gray-500">Status Pembayaran:</td><td class="font-bold text-emerald-600">LUNAS / TERBAYAR</td></tr>
              </table>
            </div>
          </div>

          <!-- Breakdown Earnings Table -->
          <div class="space-y-2">
            <h4 class="font-bold text-xs uppercase tracking-wider text-gray-700 border-b pb-1">RINCIAN PENERIMAAN & KOMISI</h4>
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-gray-100 border-b text-[11px]">
                  <th class="py-2 px-2">Komponen Pembayaran</th>
                  <th class="py-2 px-2 text-right">Keterangan / Rate</th>
                  <th class="py-2 px-2 text-right">Jumlah (Rp)</th>
                </tr>
              </thead>
              <tbody class="divide-y text-xs">
                <tr>
                  <td class="py-2 px-2 font-medium">Gaji Pokok</td>
                  <td class="py-2 px-2 text-right text-gray-500">Fix Per Bulan</td>
                  <td class="py-2 px-2 text-right font-semibold">{{ formatIDR(selectedPayroll.baseSalary) }}</td>
                </tr>
                <tr v-if="selectedPayroll.calculatedCommission > 0">
                  <td class="py-2 px-2 font-medium">Komisi Tindakan Pasien</td>
                  <td class="py-2 px-2 text-right text-gray-500">Rate {{ selectedPayroll.commissionRatePercent }}% (Omset {{ formatIDR(selectedPayroll.treatmentRevenue) }})</td>
                  <td class="py-2 px-2 text-right font-semibold text-emerald-600">{{ formatIDR(selectedPayroll.calculatedCommission) }}</td>
                </tr>
                <tr>
                  <td class="py-2 px-2 font-medium">Tunjangan & Bonus Hadir</td>
                  <td class="py-2 px-2 text-right text-gray-500">Insentif Performa</td>
                  <td class="py-2 px-2 text-right font-semibold text-blue-600">+{{ formatIDR(selectedPayroll.allowanceBonus) }}</td>
                </tr>
                <tr v-if="selectedPayroll.deductions > 0">
                  <td class="py-2 px-2 font-medium text-red-600">Potongan (Kasbon / BPJS)</td>
                  <td class="py-2 px-2 text-right text-gray-500">Potongan Otomatis</td>
                  <td class="py-2 px-2 text-right font-semibold text-red-600">-{{ formatIDR(selectedPayroll.deductions) }}</td>
                </tr>
              </tbody>
              <tfoot>
                <tr class="border-t-2 border-gray-900 bg-gray-50 font-bold text-sm">
                  <td colspan="2" class="py-2 px-2 uppercase">TOTAL TAKEN HOME PAY (NET)</td>
                  <td class="py-2 px-2 text-right text-primary">{{ formatIDR(selectedPayroll.netPayable) }}</td>
                </tr>
              </tfoot>
            </table>
          </div>

          <!-- Signatures Section -->
          <div class="grid grid-cols-2 gap-8 pt-8 text-center text-xs">
            <div>
              <p class="text-gray-500">Penerima Honor/Gaji,</p>
              <div class="h-16"></div>
              <p class="font-bold underline">{{ selectedPayroll.fullName }}</p>
            </div>
            <div>
              <p class="text-gray-500">Finance / Management Clinic,</p>
              <div class="h-16"></div>
              <p class="font-bold underline">Maya Putri, S.E.</p>
            </div>
          </div>
        </div>
      </UCard>
    </UModal>
  </div>
</template>
