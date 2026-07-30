<script setup lang="ts">
import type { Branch, CreateDoctorInput, DoctorDetail, DoctorSchedule, Reservation, UpdateDoctorInput } from '~/types/api'

definePageMeta({ title: 'Dokter & Jadwal' })

const { data: doctors, status, refresh, error } = useApiFetch<DoctorDetail[]>('/doctors/admin')
const { data: branches } = useApiFetch<Branch[]>('/branches')
const { data: reservations } = useApiFetch<Reservation[]>('/reservations')

const columns = [
  { accessorKey: 'fullName', header: 'Nama Dokter' },
  { accessorKey: 'specialization', header: 'Spesialisasi' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'phoneWa', header: 'No. WhatsApp' },
  { accessorKey: 'isActive', header: 'Status' },
  { id: 'actions', header: '' }
]

const DAY_NAMES = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']

function blankSchedule(): DoctorSchedule {
  return { dayOfWeek: 1, branchId: branches.value?.[0]?.id ?? '', startTime: '08:00', endTime: '17:00', slotDurationMinutes: 30 }
}
function initials(name: string) {
  return name.split(' ').filter(Boolean).slice(0, 2).map(p => p[0]).join('').toUpperCase()
}
function branchName(id: string) {
  return branches.value?.find(b => b.id === id)?.name ?? id
}

// --- Detail panel ---
const showDetail = ref(false)
const detailDoctor = ref<DoctorDetail | null>(null)
const detailReservations = computed(() => (reservations.value ?? []).filter(r => r.staffId === detailDoctor.value?.id))
const detailCompletedCount = computed(() => detailReservations.value.filter(r => r.status === 'completed').length)
const detailUpcomingCount = computed(() => detailReservations.value.filter(r => ['pending', 'confirmed', 'checked_in'].includes(r.status)).length)

async function openDetail(doctor: DoctorDetail) {
  detailDoctor.value = await $fetch<DoctorDetail>(apiUrl(`/doctors/${doctor.id}`))
  showDetail.value = true
}
function editFromDetail() {
  if (detailDoctor.value) openEdit(detailDoctor.value)
  showDetail.value = false
}

// --- Create/edit modal ---
const showModal = ref(false)
const editingId = ref<string | null>(null)
const saving = ref(false)
const formError = ref('')

const form = reactive({
  fullName: '',
  email: '',
  phoneWa: '',
  specialization: '',
  isActive: true,
  branchIds: [] as string[],
  schedules: [] as DoctorSchedule[]
})

function openCreate() {
  editingId.value = null
  form.fullName = ''
  form.email = ''
  form.phoneWa = ''
  form.specialization = ''
  form.isActive = true
  form.branchIds = []
  form.schedules = []
  formError.value = ''
  showModal.value = true
}

async function openEdit(doctor: DoctorDetail) {
  editingId.value = doctor.id
  const detail = await $fetch<DoctorDetail>(apiUrl(`/doctors/${doctor.id}`))
  form.fullName = detail.fullName
  form.email = detail.email ?? ''
  form.phoneWa = detail.phoneWa ?? ''
  form.specialization = detail.specialization ?? ''
  form.isActive = detail.isActive
  form.branchIds = detail.branchIds ?? []
  form.schedules = detail.schedules ?? []
  formError.value = ''
  showModal.value = true
}

function addScheduleRow() {
  form.schedules.push(blankSchedule())
}
function removeScheduleRow(index: number) {
  form.schedules.splice(index, 1)
}

async function onSubmit() {
  if (!form.fullName || form.branchIds.length === 0) {
    formError.value = 'Nama dan minimal satu cabang wajib diisi.'
    return
  }
  saving.value = true
  formError.value = ''
  try {
    if (editingId.value) {
      const payload: UpdateDoctorInput = {
        fullName: form.fullName,
        specialization: form.specialization || null,
        isActive: form.isActive,
        branchIds: form.branchIds,
        schedules: form.schedules
      }
      await apiPut(`/doctors/${editingId.value}`, payload as unknown as Record<string, unknown>)
    } else {
      const payload: CreateDoctorInput = {
        fullName: form.fullName,
        email: form.email,
        phoneWa: form.phoneWa || null,
        specialization: form.specialization || null,
        branchIds: form.branchIds,
        schedules: form.schedules
      }
      await apiPost('/doctors', payload as unknown as Record<string, unknown>)
    }
    showModal.value = false
    await refresh()
  } catch (err) {
    formError.value = apiErrorMessage(err)
  } finally {
    saving.value = false
  }
}

async function onDeactivate(doctor: DoctorDetail) {
  if (!confirm(`Nonaktifkan akun ${doctor.fullName}?`)) return
  try {
    await apiDelete(`/doctors/${doctor.id}`)
    showDetail.value = false
    await refresh()
  } catch (err) {
    alert(apiErrorMessage(err))
  }
}
</script>

<template>
  <UContainer class="py-6 space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-xl font-semibold">
          Dokter & Jadwal
        </h1>
        <p class="text-sm text-muted">
          Kelola akun dokter, spesialisasi, cabang praktik, dan jadwal mingguan. Klik baris untuk lihat detail.
        </p>
      </div>
      <UButton
        icon="i-lucide-plus"
        label="Tambah Dokter"
        @click="openCreate"
      />
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <SkeletonTableSkeleton
      v-if="status === 'pending'"
      :columns="6"
    />
    <UTable
      v-else
      :data="doctors ?? []"
      :columns="columns"
      class="cursor-pointer"
      @select="(_e, row) => openDetail(row.original)"
    >
      <template #isActive-cell="{ row }">
        <UBadge
          :color="row.original.isActive ? 'success' : 'neutral'"
          variant="subtle"
        >
          {{ row.original.isActive ? 'Aktif' : 'Nonaktif' }}
        </UBadge>
      </template>
      <template #actions-cell="{ row }">
        <div
          class="flex justify-end gap-1"
          @click.stop
        >
          <UButton
            icon="i-lucide-eye"
            size="xs"
            color="neutral"
            variant="ghost"
            @click="openDetail(row.original)"
          />
          <UButton
            icon="i-lucide-pencil"
            size="xs"
            color="neutral"
            variant="ghost"
            @click="openEdit(row.original)"
          />
          <UButton
            v-if="row.original.isActive"
            icon="i-lucide-user-x"
            size="xs"
            color="error"
            variant="ghost"
            @click="onDeactivate(row.original)"
          />
        </div>
      </template>
    </UTable>

    <!-- Detail panel -->
    <USlideover
      v-model:open="showDetail"
      :ui="{ content: 'max-w-md' }"
    >
      <template #body>
        <div
          v-if="detailDoctor"
          class="space-y-6"
        >
          <div class="flex items-center gap-3">
            <UAvatar
              :text="initials(detailDoctor.fullName)"
              size="lg"
              class="bg-primary-100 text-primary-700"
            />
            <div>
              <h3 class="font-semibold">
                {{ detailDoctor.fullName }}
              </h3>
              <div class="flex gap-1 mt-1">
                <UBadge
                  v-if="detailDoctor.specialization"
                  color="primary"
                  variant="subtle"
                  size="xs"
                >
                  {{ detailDoctor.specialization }}
                </UBadge>
                <UBadge
                  :color="detailDoctor.isActive ? 'success' : 'neutral'"
                  variant="subtle"
                  size="xs"
                >
                  {{ detailDoctor.isActive ? 'Aktif' : 'Nonaktif' }}
                </UBadge>
              </div>
            </div>
          </div>

          <div class="grid grid-cols-3 gap-2">
            <UPageCard
              :title="String(detailReservations.length)"
              description="Total Reservasi"
            />
            <UPageCard
              :title="String(detailCompletedCount)"
              description="Selesai"
            />
            <UPageCard
              :title="String(detailUpcomingCount)"
              description="Akan Datang"
            />
          </div>

          <div>
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Data Praktik
            </h4>
            <dl class="grid grid-cols-2 gap-y-2 text-sm">
              <dt class="text-muted">
                Email
              </dt>
              <dd class="text-right">
                {{ detailDoctor.email ?? '—' }}
              </dd>
              <dt class="text-muted">
                No. WhatsApp
              </dt>
              <dd class="text-right">
                {{ detailDoctor.phoneWa ?? '—' }}
              </dd>
              <dt class="text-muted">
                Cabang Praktik
              </dt>
              <dd class="text-right">
                {{ (detailDoctor.branchIds ?? []).map(branchName).join(', ') || '—' }}
              </dd>
            </dl>
          </div>

          <div>
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Jadwal Mingguan
            </h4>
            <div
              v-if="!detailDoctor.schedules?.length"
              class="text-sm text-muted"
            >
              Belum ada jadwal.
            </div>
            <ul
              v-else
              class="space-y-1 text-sm"
            >
              <li
                v-for="(s, i) in detailDoctor.schedules"
                :key="i"
                class="flex justify-between border-b border-default pb-1"
              >
                <span>{{ DAY_NAMES[s.dayOfWeek] }} · {{ branchName(s.branchId) }}</span>
                <span class="tabular-nums">{{ s.startTime.slice(0, 5) }}–{{ s.endTime.slice(0, 5) }}</span>
              </li>
            </ul>
          </div>

          <div>
            <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
              Reservasi Terbaru ({{ detailReservations.length }})
            </h4>
            <div
              v-if="detailReservations.length === 0"
              class="text-sm text-muted"
            >
              Belum ada reservasi.
            </div>
            <ul
              v-else
              class="space-y-2"
            >
              <li
                v-for="r in detailReservations.slice(0, 6)"
                :key="r.id"
                class="flex items-center justify-between text-sm border-b border-default pb-2"
              >
                <div>
                  <p>{{ r.patientName }}</p>
                  <p class="text-xs text-muted">
                    {{ formatDateTime(r.scheduledAt) }}
                  </p>
                </div>
                <UBadge
                  :color="reservationStatusColor(r.status)"
                  variant="subtle"
                  size="xs"
                >
                  {{ reservationStatusLabel(r.status) }}
                </UBadge>
              </li>
            </ul>
          </div>

          <div class="flex gap-2 pt-2">
            <UButton
              icon="i-lucide-pencil"
              variant="soft"
              label="Edit"
              class="flex-1"
              @click="editFromDetail"
            />
            <UButton
              v-if="detailDoctor.isActive"
              icon="i-lucide-user-x"
              color="error"
              variant="soft"
              label="Nonaktifkan"
              class="flex-1"
              @click="onDeactivate(detailDoctor)"
            />
          </div>
        </div>
      </template>
    </USlideover>

    <UModal
      v-model:open="showModal"
      :title="editingId ? 'Edit Dokter' : 'Tambah Dokter'"
    >
      <template #body>
        <form
          class="space-y-4"
          @submit.prevent="onSubmit"
        >
          <UFormField
            label="Nama Lengkap"
            required
          >
            <UInput
              v-model="form.fullName"
              class="w-full"
              placeholder="drg. Nama Dokter"
            />
          </UFormField>
          <div class="grid grid-cols-2 gap-4">
            <UFormField
              label="Email"
              required
            >
              <UInput
                v-model="form.email"
                type="email"
                class="w-full"
                :disabled="!!editingId"
              />
            </UFormField>
            <UFormField label="No. WhatsApp">
              <UInput
                v-model="form.phoneWa"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Spesialisasi">
            <UInput
              v-model="form.specialization"
              class="w-full"
              placeholder="Dokter Gigi Umum"
            />
          </UFormField>

          <UFormField
            label="Cabang Praktik"
            required
          >
            <div class="flex flex-wrap gap-4">
              <UCheckbox
                v-for="branch in branches ?? []"
                :key="branch.id"
                v-model="form.branchIds"
                :value="branch.id"
                :label="branch.name"
              />
            </div>
          </UFormField>

          <UFormField
            v-if="editingId"
            label="Status Akun"
          >
            <USwitch
              v-model="form.isActive"
              :label="form.isActive ? 'Aktif' : 'Nonaktif'"
            />
          </UFormField>

          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <span class="text-sm font-medium">Jadwal Praktik</span>
              <UButton
                icon="i-lucide-plus"
                size="xs"
                variant="soft"
                label="Tambah Jadwal"
                @click="addScheduleRow"
              />
            </div>
            <div
              v-if="form.schedules.length === 0"
              class="text-sm text-muted"
            >
              Belum ada jadwal.
            </div>
            <div
              v-for="(schedule, index) in form.schedules"
              :key="index"
              class="flex items-end gap-2"
            >
              <UFormField
                label="Hari"
                class="w-28"
              >
                <USelect
                  v-model="schedule.dayOfWeek"
                  :items="DAY_NAMES.map((d, i) => ({ label: d, value: i }))"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                label="Cabang"
                class="flex-1"
              >
                <USelect
                  v-model="schedule.branchId"
                  :items="form.branchIds.map(id => ({ label: branchName(id), value: id }))"
                  class="w-full"
                />
              </UFormField>
              <UFormField label="Mulai">
                <UInput
                  v-model="schedule.startTime"
                  type="time"
                />
              </UFormField>
              <UFormField label="Selesai">
                <UInput
                  v-model="schedule.endTime"
                  type="time"
                />
              </UFormField>
              <UButton
                icon="i-lucide-trash-2"
                color="error"
                variant="ghost"
                @click="removeScheduleRow(index)"
              />
            </div>
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
            label="Simpan"
            @click="onSubmit"
          />
        </div>
      </template>
    </UModal>
  </UContainer>
</template>
