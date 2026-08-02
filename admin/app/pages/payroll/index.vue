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

function openPrintSlip(p: StaffPayroll) {
  selectedPayroll.value = p
  showPrintSlipModal.value = true
}

function triggerPrint() {
  window.print()
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
        <select
          v-model="selectedPeriod"
          class="px-3 py-1.5 text-sm rounded-lg border border-gray-300 dark:border-gray-700 bg-white dark:bg-gray-800 font-medium"
        >
          <option value="2026-08">Periode: Agustus 2026</option>
          <option value="2026-07">Periode: Juli 2026</option>
          <option value="2026-06">Periode: Juni 2026</option>
        </select>
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
    <UCard :ui="{ body: 'p-0 sm:p-0' }" class="bg-white dark:bg-gray-800 print:hidden overflow-hidden">
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
              <th class="px-4 py-3.5 text-right">Aksi Cetak</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr v-for="item in payrolls" :key="item.id" class="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors">
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
                <UButton
                  size="xs"
                  color="primary"
                  variant="subtle"
                  icon="i-lucide-printer"
                  label="Cetak Slip"
                  @click="openPrintSlip(item)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </UCard>

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
