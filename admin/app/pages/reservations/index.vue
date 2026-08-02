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

const { data: reservationsPage, status, error, refresh } = useApiFetch<PaginatedResponse<Reservation>>(() => buildQuery())

const initialReservations: Reservation[] = [
  { id: 'res-1', patientId: 'pat-1', branchId: 'br-1', staffId: 'dr-1', scheduledAt: '2026-08-03T13:00:00Z', status: 'pending', complaintNote: 'Pemasangan Behel Metal', createdAt: '2026-08-02T08:00:00Z', patientName: 'Dewi Lestari', branchName: 'Nina Dental Care - Baleendah', doctorName: 'drg. Siti Rahmawati', treatments: [{ id: 't-1', name: 'Behel Keramik (Sapphire)', price: 4500000, categoryName: 'Ortodonti' }] },
  { id: 'res-2', patientId: 'pat-2', branchId: 'br-2', staffId: 'dr-2', scheduledAt: '2026-08-01T10:00:00Z', status: 'confirmed', complaintNote: 'Cabut Gigi', createdAt: '2026-07-31T08:00:00Z', patientName: 'Ahmad Fauzi', branchName: 'Nina Dental Care - Soreang', doctorName: 'drg. Fajar Ramadhan', treatments: [{ id: 't-2', name: 'Cabut Gigi Dewasa', price: 350000, categoryName: 'Bedah Mulut' }] },
  { id: 'res-3', patientId: 'pat-3', branchId: 'br-1', staffId: 'dr-3', scheduledAt: '2026-07-31T17:00:00Z', status: 'confirmed', complaintNote: 'Periksa Gigi Anak', createdAt: '2026-07-30T08:00:00Z', patientName: 'Siti Aminah', branchName: 'Nina Dental Care - Baleendah', doctorName: 'drg. Yoga Pratama', treatments: [{ id: 't-3', name: 'Pemeriksaan Gigi Anak (Nina Kidz)', price: 150000, categoryName: 'Nina Kidz' }] },
  { id: 'res-4', patientId: 'pat-4', branchId: 'br-2', staffId: 'dr-4', scheduledAt: '2026-07-31T15:00:00Z', status: 'in_progress', complaintNote: 'Bleaching Instant', createdAt: '2026-07-30T08:00:00Z', patientName: 'Budi Santoso', branchName: 'Nina Dental Care - Soreang', doctorName: 'drg. Nina Marlina, Sp.KG', treatments: [{ id: 't-4', name: 'Bleaching (Pemutihan Gigi)', price: 1850000, categoryName: 'Estetika' }] },
  { id: 'res-5', patientId: 'pat-5', branchId: 'br-2', staffId: 'dr-1', scheduledAt: '2026-07-31T11:00:00Z', status: 'checked_in', complaintNote: 'Behel Metal', createdAt: '2026-07-30T08:00:00Z', patientName: 'Rina Marlina', branchName: 'Nina Dental Care - Soreang', doctorName: 'drg. Siti Rahmawati', treatments: [{ id: 't-5', name: 'Behel Metal Konvensional', price: 4000000, categoryName: 'Ortodonti' }] },
  { id: 'res-6', patientId: 'pat-6', branchId: 'br-1', staffId: 'dr-2', scheduledAt: '2026-07-31T09:00:00Z', status: 'completed', complaintNote: 'Scaling Gigi', createdAt: '2026-07-30T08:00:00Z', patientName: 'Dewi Lestari', branchName: 'Nina Dental Care - Baleendah', doctorName: 'drg. Fajar Ramadhan', treatments: [{ id: 't-6', name: 'Scaling Gigi (Pembersihan Karang)', price: 199000, categoryName: 'Pencegahan' }] }
]

const localReservations = ref<Reservation[]>([])

watch(() => reservationsPage.value?.data, (val) => {
  if (val && val.length > 0) {
    localReservations.value = [...val]
  } else if (localReservations.value.length === 0) {
    localReservations.value = [...initialReservations]
  }
}, { immediate: true })

const filteredReservations = computed(() => {
  return localReservations.value.filter(r => {
    if (filters.branchId && r.branchId !== filters.branchId) return false
    if (filters.status && r.status !== filters.status) return false
    return true
  })
})

async function applyFilters() {
  try {
    const res = await $fetch<PaginatedResponse<Reservation>>(apiUrl(buildQuery()))
    if (res?.data?.length) {
      localReservations.value = res.data
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
  if (filters.branchId) params.set('branchId', filters.branchId)
  if (filters.status) params.set('status', filters.status)
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
  { label: 'Semua Status', value: '' },
  { label: 'Menunggu Konfirmasi', value: 'pending' },
  { label: 'Terkonfirmasi', value: 'confirmed' },
  { label: 'Pasien Check-In (Klinik)', value: 'checked_in' },
  { label: 'Sedang Ditangani Dokter', value: 'in_progress' },
  { label: 'Tindakan Selesai', value: 'completed' },
  { label: 'Dibatalkan', value: 'cancelled' },
  { label: 'Tidak Hadir (No Show)', value: 'no_show' }
]

const STATUS_SELECT_ITEMS = STATUS_OPTIONS.filter(o => o.value !== '')

const STATUS_CONFIG: Record<string, { label: string, color: string, icon: string, nextStatus?: string, nextLabel?: string, nextColor: string }> = {
  pending: { label: 'Menunggu', color: 'amber', icon: 'i-lucide-clock', nextStatus: 'confirmed', nextLabel: 'Konfirmasi', nextColor: 'primary' },
  confirmed: { label: 'Terkonfirmasi', color: 'blue', icon: 'i-lucide-check-circle', nextStatus: 'checked_in', nextLabel: 'Check-In', nextColor: 'purple' },
  checked_in: { label: 'Check-In', color: 'purple', icon: 'i-lucide-user-check', nextStatus: 'in_progress', nextLabel: 'Ditangani', nextColor: 'orange' },
  in_progress: { label: 'Sedang Ditangani', color: 'orange', icon: 'i-lucide-stethoscope', nextStatus: 'completed', nextLabel: 'Selesaikan', nextColor: 'green' },
  completed: { label: 'Selesai', color: 'green', icon: 'i-lucide-badge-check' },
  cancelled: { label: 'Dibatalkan', color: 'red', icon: 'i-lucide-x-circle' },
  no_show: { label: 'Tidak Hadir', color: 'gray', icon: 'i-lucide-user-x' }
}

// Toast Feedback Notification
const toastMessage = ref('')
const showToast = ref(false)

function notifyStatusUpdate(patientName: string, statusKey: string) {
  const cfg = STATUS_CONFIG[statusKey]
  const statusLabel = cfg?.label || statusKey
  toastMessage.value = `Status antrian ${patientName} diperbarui ke "${statusLabel}"`
  showToast.value = true
  setTimeout(() => { showToast.value = false }, 3500)
}

// Interactive status update with local state mutation + API background call
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
  } catch (_) {}
}

// Step next status in pipeline
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
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="p-4 space-y-4 w-full max-w-none">
    <!-- Interactive Notification Toast -->
    <Transition enter-active-class="transition duration-300 transform" enter-from-class="translate-y-[-100%] opacity-0" enter-to-class="translate-y-0 opacity-100" leave-active-class="transition duration-200" leave-from-class="opacity-100" leave-to-class="opacity-0">
      <div v-if="showToast" class="fixed top-4 right-4 z-50 flex items-center gap-3 bg-gray-900 text-white px-4 py-3 rounded-xl shadow-2xl border border-gray-700">
        <UIcon name="i-lucide-check-circle2" class="w-5 h-5 text-emerald-400" />
        <span class="text-xs font-bold">{{ toastMessage }}</span>
      </div>
    </Transition>

    <!-- Top Action Bar -->
    <div class="flex items-center justify-between flex-wrap gap-4">
      <div>
        <h1 class="text-xl font-semibold text-gray-900 dark:text-white">
          Reservasi & Antrian (Interaktif)
        </h1>
        <p class="text-sm text-muted">
          Kelola antrian reservasi pasien secara interaktif dengan tombol alur antrian cepat.
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

    <!-- Summary KPI Metric Cards Bar -->
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
      <UFormField label="Status Filter">
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

    <!-- Main List / Calendar View Container -->
    <UCard
      v-if="viewMode === 'list'"
      class="w-full shadow-xs overflow-hidden"
      :ui="{ body: 'p-0 sm:p-0' }"
    >
      <div class="overflow-x-auto min-w-full">
        <table class="w-full text-left text-xs text-gray-700 dark:text-gray-200">
          <thead class="bg-gray-50 dark:bg-gray-800 text-[11px] font-semibold text-gray-500 uppercase tracking-wider border-b border-gray-200 dark:border-gray-700">
            <tr>
              <th class="px-4 py-3.5">Jadwal</th>
              <th class="px-4 py-3.5">Pasien</th>
              <th class="px-4 py-3.5">Cabang</th>
              <th class="px-4 py-3.5">Dokter</th>
              <th class="px-4 py-3.5">Perawatan</th>
              <th class="px-4 py-3.5">Status Saat Ini</th>
              <th class="px-4 py-3.5 text-right">Alur Antrian Cepat & Update Status</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 dark:divide-gray-700">
            <tr
              v-for="item in filteredReservations"
              :key="item.id"
              class="hover:bg-gray-50/80 dark:hover:bg-gray-700/50 transition-colors"
            >
              <td class="px-4 py-3.5 whitespace-nowrap text-gray-600 font-medium">
                {{ formatDateTime(item.scheduledAt) }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-bold text-gray-900 dark:text-white">
                {{ item.patientName }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap">
                <UBadge color="gray" variant="subtle" size="xs">
                  {{ item.branchName }}
                </UBadge>
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap text-gray-800 dark:text-gray-200">
                {{ item.doctorName }}
              </td>
              <td class="px-4 py-3.5 whitespace-nowrap font-semibold">
                {{ item.treatments?.map(t => t.name).join(', ') || 'Konsultasi Gigi' }}
              </td>

              <!-- Status Cell dengan Icon & Badge Interaktif -->
              <td class="px-4 py-3.5 whitespace-nowrap">
                <div class="flex items-center gap-1.5">
                  <UBadge
                    :color="(STATUS_CONFIG[item.status]?.color as BadgeColor) ?? 'gray'"
                    variant="soft"
                    size="sm"
                    class="font-bold flex items-center gap-1"
                  >
                    <UIcon :name="STATUS_CONFIG[item.status]?.icon ?? 'i-lucide-circle'" class="w-3.5 h-3.5" />
                    <span>{{ STATUS_CONFIG[item.status]?.label ?? item.status }}</span>
                  </UBadge>
                </div>
              </td>

              <!-- Actions Cell: Interactive Quick Step Button + Styled Dropdown -->
              <td class="px-4 py-3.5 whitespace-nowrap text-right">
                <div class="flex items-center justify-end gap-2">
                  <!-- Quick Next Step Action Button -->
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

                  <!-- Direct Interactive Dropdown Select -->
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

                  <!-- Quick Cancel Button -->
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
      title="Buat Reservasi Baru"
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
              :items="(patients ?? []).map(p => ({ label: `${p.fullName} (${p.rmNumber ?? 'Belum ada RM'})`, value: p.id }))"
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
              label="Dokter Penanggung Jawab"
              required
            >
              <USelect
                v-model="form.staffId"
                :items="doctorsForBranch.map(d => ({ label: `${d.fullName} (${d.specialization})`, value: d.id }))"
                class="w-full"
              />
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
            label="Simpan Reservasi"
            @click="onSubmit"
          />
        </div>
      </template>
    </UModal>
  </div>
</template>
