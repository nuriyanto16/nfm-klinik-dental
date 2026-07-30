<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { BranchRevenue, CommissionRow, DailyRevenue, Expense, ExpenseCategoryTotal, ExpenseInput, FinancialSummary, PaymentMethodRevenue, ProfitReport } from '~/types/api'

definePageMeta({ title: 'Laporan Keuangan' })

function toDateInput(d: Date) {
  return d.toISOString().slice(0, 10)
}
const today = new Date()
const thirtyDaysAgo = new Date(today.getTime() - 29 * 24 * 60 * 60 * 1000)

const range = reactive({ from: toDateInput(thirtyDaysAgo), to: toDateInput(today) })

const summary = ref<FinancialSummary | null>(null)
const trend = ref<DailyRevenue[]>([])
const byMethod = ref<PaymentMethodRevenue[]>([])
const byBranch = ref<BranchRevenue[]>([])
const expenses = ref<Expense[]>([])
const expensesByCategory = ref<ExpenseCategoryTotal[]>([])
const commission = ref<CommissionRow[]>([])
const profit = ref<ProfitReport | null>(null)
const loading = ref(false)
const loadError = ref('')

async function loadReports() {
  loading.value = true
  loadError.value = ''
  try {
    const qs = `from=${range.from}&to=${range.to}`
    const [s, t, m, b, e, ec, c, p] = await Promise.all([
      $fetch<FinancialSummary>(apiUrl(`/admin/reports/summary?${qs}`)),
      $fetch<DailyRevenue[]>(apiUrl(`/admin/reports/revenue-trend?${qs}`)),
      $fetch<PaymentMethodRevenue[]>(apiUrl(`/admin/reports/by-payment-method?${qs}`)),
      $fetch<BranchRevenue[]>(apiUrl('/admin/dashboard/revenue-by-branch')),
      $fetch<Expense[]>(apiUrl(`/expenses?${qs}`)),
      $fetch<ExpenseCategoryTotal[]>(apiUrl(`/admin/reports/by-expense-category?${qs}`)),
      $fetch<CommissionRow[]>(apiUrl(`/admin/reports/commission?${qs}`)),
      $fetch<ProfitReport>(apiUrl(`/admin/reports/profit?${qs}`))
    ])
    summary.value = s
    trend.value = t
    byMethod.value = m
    byBranch.value = b
    expenses.value = e
    expensesByCategory.value = ec
    commission.value = c
    profit.value = p
  } catch (err) {
    loadError.value = apiErrorMessage(err)
  } finally {
    loading.value = false
  }
}

onMounted(loadReports)

const methodLabel: Record<string, string> = {
  bank_transfer_bca: 'Transfer BCA',
  bank_transfer_bni: 'Transfer BNI',
  bank_transfer_mandiri: 'Transfer Mandiri',
  ewallet_ovo: 'OVO',
  ewallet_dana: 'DANA',
  ewallet_shopeepay: 'ShopeePay',
  qris: 'QRIS',
  cash: 'Tunai',
  manual_transfer: 'Transfer Manual',
  lainnya: 'Lainnya'
}

const trendOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: trend.value.map(d => formatDateShort(d.date)) },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{ type: 'line', smooth: true, data: trend.value.map(d => d.revenue), itemStyle: { color: CHART_PRIMARY }, lineStyle: { color: CHART_PRIMARY }, areaStyle: { color: 'rgba(37,99,235,0.15)' } }]
}))

const methodOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'item', valueFormatter: v => formatIDR(Number(v)) },
  legend: { bottom: 0 },
  series: [{ type: 'pie', radius: ['40%', '70%'], data: byMethod.value.map((m, i) => ({ name: methodLabel[m.method] ?? m.method, value: m.revenue, itemStyle: { color: colorForIndex(i) } })) }]
}))

const branchOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: byBranch.value.map(b => b.branchName) },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{ type: 'bar', data: byBranch.value.map(b => b.revenue), itemStyle: { color: CHART_PRIMARY, borderRadius: [4, 4, 0, 0] }, barMaxWidth: 60 }]
}))

const expenseOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'item', valueFormatter: v => formatIDR(Number(v)) },
  legend: { bottom: 0 },
  series: [{ type: 'pie', radius: ['40%', '70%'], data: expensesByCategory.value.map((e, i) => ({ name: e.category, value: e.total, itemStyle: { color: colorForIndex(i) } })) }]
}))

const commissionOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' }, valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: commission.value.map(c => c.doctorName), axisLabel: { rotate: 20 } },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{ type: 'bar', data: commission.value.map(c => c.commission), itemStyle: { color: CHART_PRIMARY, borderRadius: [4, 4, 0, 0] }, barMaxWidth: 40 }]
}))

// --- Excel export (client-side, sheetjs) ---
// Dynamic import keeps `xlsx` out of the SSR bundle entirely — Nitro can't
// resolve its optional codepage submodule server-side, and this file is
// only ever needed in response to a browser click anyway.
async function exportExcel() {
  const XLSX = await import('xlsx')
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(trend.value), 'Tren Revenue')
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(byMethod.value), 'Per Metode')
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(byBranch.value), 'Per Cabang')
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(expenses.value), 'Pembiayaan')
  XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet(commission.value), 'Komisi Dokter')
  if (summary.value && profit.value) {
    XLSX.utils.book_append_sheet(wb, XLSX.utils.json_to_sheet([{ ...summary.value, ...profit.value }]), 'Ringkasan')
  }
  XLSX.writeFile(wb, `laporan-keuangan_${range.from}_${range.to}.xlsx`)
}

// --- Expense CRUD modal ---
const { data: branches } = useApiFetch<{ id: string, name: string }[]>('/branches')
const EXPENSE_CATEGORIES = ['Sewa', 'Listrik & Air', 'Gaji Non-Komisi', 'Restock Alat/Obat', 'Marketing', 'Lainnya']
const showExpenseModal = ref(false)
const savingExpense = ref(false)
const expenseError = ref('')
const expenseForm = reactive<ExpenseInput>({ branchId: null, category: EXPENSE_CATEGORIES[0]!, description: null, amount: 0, expenseDate: toDateInput(today) })
const expenseDescriptionText = computed({
  get: () => expenseForm.description ?? '',
  set: (v: string) => { expenseForm.description = v || null }
})

function openExpenseModal() {
  expenseForm.branchId = null
  expenseForm.category = EXPENSE_CATEGORIES[0]!
  expenseForm.description = null
  expenseForm.amount = 0
  expenseForm.expenseDate = toDateInput(today)
  expenseError.value = ''
  showExpenseModal.value = true
}

async function onSubmitExpense() {
  if (!expenseForm.category || expenseForm.amount <= 0) {
    expenseError.value = 'Kategori dan jumlah biaya wajib diisi.'
    return
  }
  savingExpense.value = true
  expenseError.value = ''
  try {
    await apiPost('/expenses', expenseForm as unknown as Record<string, unknown>)
    showExpenseModal.value = false
    await loadReports()
  } catch (err) {
    expenseError.value = apiErrorMessage(err)
  } finally {
    savingExpense.value = false
  }
}

async function onDeleteExpense(expense: Expense) {
  if (!confirm(`Hapus biaya "${expense.category}" sebesar ${formatIDR(expense.amount)}?`)) return
  try {
    await apiDelete(`/expenses/${expense.id}`)
    await loadReports()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}

const tabs = [
  { label: 'Ringkasan', value: 'summary' },
  { label: 'Pembiayaan', value: 'expenses' },
  { label: 'Komisi Dokter', value: 'commission' },
  { label: 'Keuntungan', value: 'profit' }
]
const activeTab = ref('summary')
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-xl font-semibold">
          Laporan Keuangan
        </h1>
        <p class="text-sm text-muted">
          Ringkasan transaksi (online Xendit + manual/tunai), pembiayaan, komisi, dan keuntungan per periode.
        </p>
      </div>
      <div class="flex items-end gap-2">
        <UFormField label="Dari">
          <UInput
            v-model="range.from"
            type="date"
          />
        </UFormField>
        <UFormField label="Sampai">
          <UInput
            v-model="range.to"
            type="date"
          />
        </UFormField>
        <UButton
          icon="i-lucide-refresh-cw"
          label="Terapkan"
          color="neutral"
          variant="soft"
          :loading="loading"
          @click="loadReports"
        />
        <UButton
          icon="i-lucide-file-spreadsheet"
          label="Export Excel"
          @click="exportExcel"
        />
      </div>
    </div>

    <UAlert
      v-if="loadError"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat laporan"
      :description="loadError"
    />

    <UTabs
      v-model="activeTab"
      :items="tabs"
    >
      <template #content="{ item }">
        <div
          v-if="item.value === 'summary'"
          class="space-y-4 pt-4"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <template v-if="loading && !summary">
              <SkeletonStatCardSkeleton
                v-for="i in 4"
                :key="i"
              />
            </template>
            <template v-else>
              <UPageCard
                :title="summary ? formatIDR(summary.totalRevenue) : '—'"
                description="Total Revenue (Lunas)"
                icon="i-lucide-banknote"
              />
              <UPageCard
                :title="String(summary?.totalTransactions ?? '—')"
                description="Jumlah Transaksi Lunas"
                icon="i-lucide-receipt"
              />
              <UPageCard
                :title="summary ? formatIDR(summary.avgTransaction) : '—'"
                description="Rata-rata per Transaksi"
                icon="i-lucide-calculator"
              />
              <UPageCard
                :title="summary ? formatIDR(summary.totalRefunded) : '—'"
                description="Total Dikembalikan (Refund)"
                icon="i-lucide-undo-2"
              />
            </template>
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
            <UCard>
              <template #header>
                <h2 class="font-medium">
                  Tren Revenue Harian
                </h2>
              </template>
              <SkeletonChartSkeleton v-if="loading && !trend.length" />
              <ChartsEChart
                v-else
                :option="trendOption"
              />
            </UCard>
            <UCard>
              <template #header>
                <h2 class="font-medium">
                  Revenue per Metode Pembayaran
                </h2>
              </template>
              <SkeletonChartSkeleton v-if="loading && !byMethod.length" />
              <ChartsEChart
                v-else
                :option="methodOption"
              />
            </UCard>
          </div>

          <UCard>
            <template #header>
              <h2 class="font-medium">
                Revenue per Cabang (Keseluruhan)
              </h2>
            </template>
            <SkeletonChartSkeleton v-if="loading && !byBranch.length" />
            <ChartsEChart
              v-else
              :option="branchOption"
            />
          </UCard>
        </div>

        <div
          v-else-if="item.value === 'expenses'"
          class="space-y-4 pt-4"
        >
          <div class="flex justify-end">
            <UButton
              icon="i-lucide-plus"
              label="Catat Biaya"
              @click="openExpenseModal"
            />
          </div>
          <UCard>
            <template #header>
              <h2 class="font-medium">
                Pembiayaan per Kategori
              </h2>
            </template>
            <SkeletonChartSkeleton v-if="loading && !expensesByCategory.length" />
            <ChartsEChart
              v-else
              :option="expenseOption"
            />
          </UCard>
          <UCard :ui="{ body: 'p-0 sm:p-0' }">
            <SkeletonTableSkeleton
              v-if="loading"
              :columns="5"
            />
            <UTable
              v-else
              :data="expenses"
              :columns="[
                { accessorKey: 'expenseDate', header: 'Tanggal' },
                { accessorKey: 'category', header: 'Kategori' },
                { accessorKey: 'description', header: 'Keterangan' },
                { accessorKey: 'branchName', header: 'Cabang' },
                { accessorKey: 'amount', header: 'Jumlah' },
                { id: 'actions', header: '' }
              ]"
            >
              <template #expenseDate-cell="{ row }">
                {{ formatDateShort(row.original.expenseDate) }}
              </template>
              <template #branchName-cell="{ row }">
                {{ row.original.branchName ?? 'Semua Cabang' }}
              </template>
              <template #amount-cell="{ row }">
                {{ formatIDR(row.original.amount) }}
              </template>
              <template #actions-cell="{ row }">
                <UButton
                  icon="i-lucide-trash-2"
                  size="xs"
                  color="error"
                  variant="ghost"
                  @click="onDeleteExpense(row.original)"
                />
              </template>
            </UTable>
          </UCard>
        </div>

        <div
          v-else-if="item.value === 'commission'"
          class="space-y-4 pt-4"
        >
          <UCard>
            <template #header>
              <h2 class="font-medium">
                Komisi per Dokter
              </h2>
            </template>
            <SkeletonChartSkeleton v-if="loading && !commission.length" />
            <ChartsEChart
              v-else
              :option="commissionOption"
            />
          </UCard>
          <UCard :ui="{ body: 'p-0 sm:p-0' }">
            <SkeletonTableSkeleton
              v-if="loading"
              :columns="4"
            />
            <UTable
              v-else
              :data="commission"
              :columns="[
                { accessorKey: 'doctorName', header: 'Dokter' },
                { accessorKey: 'revenue', header: 'Revenue' },
                { accessorKey: 'commissionRate', header: 'Rate' },
                { accessorKey: 'commission', header: 'Komisi' }
              ]"
            >
              <template #revenue-cell="{ row }">
                {{ formatIDR(row.original.revenue) }}
              </template>
              <template #commissionRate-cell="{ row }">
                {{ row.original.commissionRate }}%
              </template>
              <template #commission-cell="{ row }">
                {{ formatIDR(row.original.commission) }}
              </template>
            </UTable>
          </UCard>
        </div>

        <div
          v-else-if="item.value === 'profit'"
          class="space-y-4 pt-4"
        >
          <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <template v-if="loading && !profit">
              <SkeletonStatCardSkeleton
                v-for="i in 4"
                :key="i"
              />
            </template>
            <template v-else-if="profit">
              <UPageCard
                :title="formatIDR(profit.totalRevenue)"
                description="Total Revenue"
                icon="i-lucide-banknote"
              />
              <UPageCard
                :title="formatIDR(profit.totalCommission)"
                description="Total Komisi Dokter"
                icon="i-lucide-percent"
              />
              <UPageCard
                :title="formatIDR(profit.totalExpenses)"
                description="Total Pembiayaan"
                icon="i-lucide-receipt"
              />
              <UPageCard
                :title="formatIDR(profit.netProfit)"
                description="Keuntungan Bersih"
                icon="i-lucide-trending-up"
              />
            </template>
          </div>
          <UAlert
            color="info"
            variant="subtle"
            icon="i-lucide-info"
            description="Keuntungan Bersih = Total Revenue (lunas) − Total Komisi Dokter − Total Pembiayaan, untuk periode yang dipilih."
          />
        </div>
      </template>
    </UTabs>

    <UModal
      v-model:open="showExpenseModal"
      title="Catat Biaya Operasional"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmitExpense"
        >
          <UFormField
            label="Kategori"
            required
          >
            <USelect
              v-model="expenseForm.category"
              :items="EXPENSE_CATEGORIES"
              class="w-full"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Jumlah"
              required
            >
              <UInput
                v-model.number="expenseForm.amount"
                type="number"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Tanggal"
              required
            >
              <UInput
                v-model="expenseForm.expenseDate"
                type="date"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Cabang (opsional)">
            <USelect
              v-model="expenseForm.branchId"
              :items="[{ label: 'Semua Cabang', value: null }, ...(branches ?? []).map(b => ({ label: b.name, value: b.id }))]"
              class="w-full"
            />
          </UFormField>
          <UFormField label="Keterangan">
            <UTextarea
              v-model="expenseDescriptionText"
              class="w-full"
              :rows="2"
            />
          </UFormField>
          <UAlert
            v-if="expenseError"
            color="error"
            variant="subtle"
            :description="expenseError"
          />
        </form>
      </template>
      <template #footer>
        <div class="flex justify-end gap-2 w-full">
          <UButton
            color="neutral"
            variant="ghost"
            label="Batal"
            @click="showExpenseModal = false"
          />
          <UButton
            :loading="savingExpense"
            label="Simpan"
            @click="onSubmitExpense"
          />
        </div>
      </template>
    </UModal>
  </UContainer>
</template>
