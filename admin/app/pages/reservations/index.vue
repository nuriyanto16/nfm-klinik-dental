<script setup lang="ts">
import type { Branch, CreateReservationInput, DoctorDetail, PaginatedResponse, Patient, Reservation, StatusCount, Treatment } from '~/types/api'

definePageMeta({ title: 'Reservasi & Antrian' })

const viewMode = ref<'list' | 'calendar'>('list')
const page = ref(1)
const pageSize = 10

const filters = reactive({ branchId: '', status: '', from: '', to: '' })

function buildQuery() {
  const params = new URLSearchParams()
  if (filters.branchId) params.set('branchId', filters.branchId)
  if (filters.status) params.set('status', filters.status)
  if (filters.from) params.set('from', filters.from)
  if (filters.to) params.set('to', filters.to)
  params.set('page', String(page.value))
  params.set('pageSize', String(pageSize))
  return `/reservations?${params.toString()}`
}

const { data: reservationsPage, status, error } = useApiFetch<PaginatedResponse<Reservation>>(() => buildQuery())
const reservations = computed(() => reservationsPage.value?.data ?? [])

async function applyFilters() {
  reservationsPage.value = await $fetch<PaginatedResponse<Reservation>>(apiUrl(buildQuery()))
}
watch(page, applyFilters)

const { data: statusCounts } = useApiFetch<StatusCount[]>('/admin/dashboard/reservations-by-status')
const totalReservationsCount = computed(() => (statusCounts.value ?? []).reduce((s, c) => s + c.count, 0))
const pendingReservationsCount = computed(() => (statusCounts.value ?? []).find(c => c.status === 'pending')?.count ?? 0)
const confirmedReservationsCount = computed(() => (statusCounts.value ?? []).find(c => c.status === 'confirmed')?.count ?? 0)
const completedReservationsCount = computed(() => (statusCounts.value ?? []).find(c => c.status === 'completed')?.count ?? 0)

const { data: calendarReservations, status: calendarStatus } = useApiFetch<Reservation[]>('/reservations', 'reservations-calendar')
async function applyCalendarFilters() {
  const params = new URLSearchParams()
  if (filters.branchId) params.set('branchId', filters.branchId)
  if (filters.status) params.set('status', filters.status)
  const qs = params.toString()
  calendarReservations.value = await $fetch<Reservation[]>(apiUrl(qs ? `/reservations?${qs}` : '/reservations'))
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

const columns = [
  { accessorKey: 'scheduledAt', header: 'Jadwal' },
  { accessorKey: 'patientName', header: 'Pasien' },
  { accessorKey: 'branchName', header: 'Cabang' },
  { accessorKey: 'doctorName', header: 'Dokter' },
  { accessorKey: 'treatments', header: 'Perawatan' },
  { accessorKey: 'status', header: 'Status' },
  { id: 'actions', header: '' }
]

const STATUS_OPTIONS = [
  { label: 'Semua Status', value: '' },
  ...['pending', 'confirmed', 'checked_in', 'in_progress', 'completed', 'cancelled', 'no_show'].map(s => ({ label: reservationStatusLabel(s), value: s }))
]

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

const doctorsForBranch = computed(() =>
  (doctorsAdmin.value ?? []).filter(d => !form.branchId || d.branchIds?.includes(form.branchId))
)

function openCreate() {
  form.patientId = ''
  form.branchId = branches.value?.[0]?.id ?? ''
  form.staffId = ''
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
    const payload: CreateReservationInput = {
      patientId: form.patientId,
      branchId: form.branchId,
      staffId: form.staffId,
      scheduledAt: new Date(`${form.scheduledDate}T${form.scheduledTime}:00`).toISOString(),
      complaintNote: form.complaintNote || null,
      treatmentIds: form.treatmentIds
    }
    await apiPost('/reservations', payload as unknown as Record<string, unknown>)
    showModal.value = false
    await applyFilters()
    await applyCalendarFilters()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

async function onStatusChange(reservation: Reservation, newStatus: string) {
  try {
    await apiPatch(`/reservations/${reservation.id}/status`, { status: newStatus })
    await applyFilters()
    await applyCalendarFilters()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <!-- Top Action Bar -->
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-xl font-semibold text-gray-900 dark:text-white">
          Reservasi & Antrian
        </h1>
        <p class="text-sm text-muted">
          Kelola antrian reservasi pasien secara lengkap dan real-time.
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

    <!-- Alert Error if Any -->
    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <!-- Summary KPI Metric Cards Bar (Replaces Pie Chart Graphic) -->
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

    <!-- Filters Bar (Full Width) -->
    <div class="flex flex-wrap items-end gap-4 p-4 rounded-xl border border-default bg-card w-full shadow-xs">
      <UFormField label="Cabang">
        <USelect
          v-model="filters.branchId"
          :items="[{ label: 'Semua Cabang', value: '' }, ...(branches ?? []).map(b => ({ label: b.name, value: b.id }))]"
          class="w-56"
          @update:model-value="onFilterChange"
        />
      </UFormField>
      <UFormField label="Status">
        <USelect
          v-model="filters.status"
          :items="STATUS_OPTIONS"
          class="w-48"
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

    <!-- Main List / Calendar View Container (100% Full Width) -->
    <UCard
      v-if="viewMode === 'list'"
      class="w-full shadow-xs"
      :ui="{ body: 'p-0 sm:p-0' }"
    >
      <SkeletonTableSkeleton
        v-if="status === 'pending'"
        :columns="7"
      />
      <UTable
        v-else
        :data="reservations"
        :columns="columns"
        class="w-full"
      >
        <template #scheduledAt-cell="{ row }">
          {{ formatDateTime(row.original.scheduledAt) }}
        </template>
        <template #status-cell="{ row }">
          <UBadge
            :color="reservationStatusColor(row.original.status)"
            variant="subtle"
          >
            {{ reservationStatusLabel(row.original.status) }}
          </UBadge>
        </template>
        <template #actions-cell="{ row }">
          <USelect
            :model-value="row.original.status"
            :items="STATUS_OPTIONS.filter(o => o.value)"
            size="xs"
            class="w-40"
            @update:model-value="(v: string) => onStatusChange(row.original, v)"
          />
        </template>
      </UTable>
      <PaginationBar
        v-if="reservationsPage"
        :page="reservationsPage.page"
        :total-pages="reservationsPage.totalPages"
        :total="reservationsPage.total"
        :page-size="reservationsPage.pageSize"
        @update:page="page = $event"
      />
    </UCard>

    <UCard v-else class="w-full shadow-xs">
      <SkeletonCalendarSkeleton v-if="calendarStatus === 'pending'" />
      <CalendarMonthCalendar
        v-else
        :reservations="calendarReservations ?? []"
        @select-day="onSelectDay"
      />
    </UCard>

    <!-- Create Reservation Modal -->
    <UModal
      v-model:open="showModal"
      title="Buat Reservasi"
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
            <USelect
              v-model="form.patientId"
              :items="(patients ?? []).map(p => ({ label: `${p.fullName}${p.rmNumber ? ' (' + p.rmNumber + ')' : ''}`, value: p.id }))"
              class="w-full"
              searchable
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Cabang"
              required
            >
              <USelect
                v-model="form.branchId"
                :items="(branches ?? []).map(b => ({ label: b.name, value: b.id }))"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Dokter"
              required
            >
              <USelect
                v-model="form.staffId"
                :items="doctorsForBranch.map(d => ({ label: d.fullName, value: d.id }))"
                class="w-full"
              />
            </UFormField>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Tanggal"
              required
            >
              <UInput
                v-model="form.scheduledDate"
                type="date"
                class="w-full"
              />
            </UFormField>
            <UFormField
              label="Jam"
              required
            >
              <UInput
                v-model="form.scheduledTime"
                type="time"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Rencana Perawatan">
            <div class="flex flex-col gap-2 max-h-40 overflow-y-auto border border-default rounded-md p-2">
              <UCheckbox
                v-for="t in treatments ?? []"
                :key="t.id"
                v-model="form.treatmentIds"
                :value="t.id"
                :label="`${t.name} — ${formatIDR(t.price)}`"
              />
            </div>
          </UFormField>
          <UFormField label="Keluhan (opsional)">
            <UTextarea
              v-model="form.complaintNote"
              class="w-full"
              :rows="2"
            />
          </UFormField>

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
  </div>
</template>
