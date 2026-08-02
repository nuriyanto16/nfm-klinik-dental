<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { Branch, CreateDoctorInput, DoctorDetail, DoctorSchedule, DoctorStats, PaginatedResponse, Reservation, StaffSkillInput, UpdateDoctorInput } from '~/types/api'

definePageMeta({ title: 'Dokter & Jadwal' })

const page = ref(1)
const pageSize = 10
const { data: doctorsPage, status, refresh, error } = useApiFetch<PaginatedResponse<DoctorDetail>>(() => `/doctors/admin?page=${page.value}&pageSize=${pageSize}`)
const doctors = computed(() => doctorsPage.value?.data ?? [])

const { data: branches } = useApiFetch<Branch[]>('/branches')
const { data: reservations } = useApiFetch<Reservation[]>('/reservations')

const columns = [
  { id: 'photo', header: '' },
  { accessorKey: 'fullName', header: 'Nama Dokter' },
  { accessorKey: 'specialization', header: 'Spesialisasi' },
  { accessorKey: 'email', header: 'Email' },
  { accessorKey: 'phoneWa', header: 'No. WhatsApp' },
  { accessorKey: 'isActive', header: 'Status' },
  { id: 'actions', header: '' }
]

const DAY_NAMES = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu']
const PROFICIENCY_LABELS = ['', 'Dasar', 'Cukup', 'Baik', 'Mahir', 'Ahli']

function blankSchedule(): DoctorSchedule {
  return { dayOfWeek: 1, branchId: branches.value?.[0]?.id ?? '', startTime: '08:00', endTime: '17:00', slotDurationMinutes: 30 }
}
function blankSkill(): StaffSkillInput {
  return { skillName: '', proficiency: 3, yearsExperience: null }
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
const detailStats = ref<DoctorStats | null>(null)
const detailStatsLoading = ref(false)
const detailReservations = computed(() => (reservations.value ?? []).filter(r => r.staffId === detailDoctor.value?.id))

const revenueTrendOption = computed<EChartsOption>(() => ({
  tooltip: { trigger: 'axis', valueFormatter: v => formatIDR(Number(v)) },
  grid: { left: 8, right: 16, top: 16, bottom: 8, containLabel: true },
  xAxis: { type: 'category', data: (detailStats.value?.monthlyRevenue ?? []).map(m => m.period.slice(5)) },
  yAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) }, splitLine: { lineStyle: { type: 'dashed' } } },
  series: [{
    type: 'line',
    data: (detailStats.value?.monthlyRevenue ?? []).map(m => m.revenue),
    smooth: true,
    itemStyle: { color: CHART_PRIMARY },
    lineStyle: { color: CHART_PRIMARY },
    areaStyle: { color: 'rgba(37,99,235,0.15)' }
  }]
}))

const skillsRadarOption = computed<EChartsOption>(() => {
  const skills = detailDoctor.value?.skills ?? []
  return {
    tooltip: {},
    radar: {
      indicator: skills.map(s => ({ name: s.skillName, max: 5 })),
      radius: '65%'
    },
    series: [{
      type: 'radar',
      data: [{ value: skills.map(s => s.proficiency), areaStyle: { color: 'rgba(37,99,235,0.25)' }, lineStyle: { color: CHART_PRIMARY }, itemStyle: { color: CHART_PRIMARY } }]
    }]
  }
})

async function openDetail(doctor: DoctorDetail) {
  detailDoctor.value = await $fetch<DoctorDetail>(apiUrl(`/doctors/${doctor.id}`))
  showDetail.value = true
  detailStatsLoading.value = true
  detailStats.value = null
  try {
    detailStats.value = await $fetch<DoctorStats>(apiUrl(`/doctors/${doctor.id}/stats`))
  } finally {
    detailStatsLoading.value = false
  }
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
  bio: '',
  photoUrl: '',
  commissionRate: 0,
  isActive: true,
  branchIds: [] as string[],
  schedules: [] as DoctorSchedule[],
  skills: [] as StaffSkillInput[]
})

function openCreate() {
  editingId.value = null
  form.fullName = ''
  form.email = ''
  form.phoneWa = ''
  form.specialization = ''
  form.bio = ''
  form.photoUrl = ''
  form.commissionRate = 0
  form.isActive = true
  form.branchIds = []
  form.schedules = []
  form.skills = []
  formError.value = ''
  showModal.value = true
}

async function openEdit(doctor: DoctorDetail) {
  editingId.value = doctor.id
  let detail = doctor
  try {
    const fetched = await $fetch<DoctorDetail>(apiUrl(`/doctors/${doctor.id}`))
    if (fetched) detail = fetched
  } catch (_) {}
  form.fullName = detail.fullName
  form.email = detail.email ?? ''
  form.phoneWa = detail.phoneWa ?? ''
  form.specialization = detail.specialization ?? ''
  form.bio = detail.bio ?? ''
  form.photoUrl = detail.photoUrl ?? ''
  form.commissionRate = detail.commissionRate
  form.isActive = detail.isActive
  form.branchIds = detail.branchIds ?? []
  form.schedules = detail.schedules ?? []
  form.skills = (detail.skills ?? []).map(s => ({ skillName: s.skillName, proficiency: s.proficiency, yearsExperience: s.yearsExperience }))
  formError.value = ''
  showModal.value = true
}

function addScheduleRow() {
  form.schedules.push(blankSchedule())
}
function removeScheduleRow(index: number) {
  form.schedules.splice(index, 1)
}
function addSkillRow() {
  form.skills.push(blankSkill())
}
function removeSkillRow(index: number) {
  form.skills.splice(index, 1)
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
        bio: form.bio || null,
        photoUrl: form.photoUrl || null,
        commissionRate: form.commissionRate,
        isActive: form.isActive,
        branchIds: form.branchIds,
        schedules: form.schedules,
        skills: form.skills.filter(s => s.skillName)
      }
      await apiPut(`/doctors/${editingId.value}`, payload as unknown as Record<string, unknown>)
    } else {
      const payload: CreateDoctorInput = {
        fullName: form.fullName,
        email: form.email,
        phoneWa: form.phoneWa || null,
        specialization: form.specialization || null,
        bio: form.bio || null,
        photoUrl: form.photoUrl || null,
        commissionRate: form.commissionRate,
        branchIds: form.branchIds,
        schedules: form.schedules,
        skills: form.skills.filter(s => s.skillName)
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
  <div class="p-4 space-y-4 w-full max-w-none">
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

    <UCard :ui="{ body: 'p-0 sm:p-0' }">
      <SkeletonTableSkeleton
        v-if="status === 'pending'"
        :columns="7"
      />
      <UTable
        v-else
        :data="doctors"
        :columns="columns"
        class="cursor-pointer"
        @select="(_e, row) => openDetail(row.original)"
      >
        <template #photo-cell="{ row }">
          <UAvatar
            :src="row.original.photoUrl ?? undefined"
            :text="initials(row.original.fullName)"
            size="sm"
            class="bg-primary-100 text-primary-700"
          />
        </template>
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
      <PaginationBar
        v-if="doctorsPage"
        :page="doctorsPage.page"
        :total-pages="doctorsPage.totalPages"
        :total="doctorsPage.total"
        :page-size="doctorsPage.pageSize"
        @update:page="page = $event"
      />
    </UCard>

    <!-- Detail panel -->
    <USlideover
      v-model:open="showDetail"
      :ui="{ content: 'max-w-lg' }"
    >
      <template #body>
        <div
          v-if="detailDoctor"
          class="space-y-6"
        >
          <div class="flex items-center gap-3">
            <UAvatar
              :src="detailDoctor.photoUrl ?? undefined"
              :text="initials(detailDoctor.fullName)"
              size="xl"
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

          <p
            v-if="detailDoctor.bio"
            class="text-sm text-muted"
          >
            {{ detailDoctor.bio }}
          </p>

          <template v-if="detailStatsLoading">
            <div class="grid grid-cols-3 gap-2">
              <SkeletonStatCardSkeleton
                v-for="i in 3"
                :key="i"
              />
            </div>
            <SkeletonChartSkeleton />
          </template>
          <template v-else-if="detailStats">
            <div class="grid grid-cols-3 gap-2">
              <UPageCard
                :title="formatCompactIDR(detailStats.totalRevenue)"
                description="Total Revenue"
              />
              <UPageCard
                :title="formatCompactIDR(detailStats.commissionEarned)"
                :description="`Komisi (${detailDoctor.commissionRate}%)`"
              />
              <UPageCard
                :title="String(detailStats.reservationsCount)"
                description="Total Reservasi"
              />
            </div>

            <div>
              <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
                Tren Revenue (6 Bulan)
              </h4>
              <ChartsEChart
                :option="revenueTrendOption"
                height="180px"
              />
            </div>

            <div v-if="detailDoctor.skills?.length">
              <h4 class="text-xs font-semibold text-muted uppercase tracking-wide mb-2">
                Kemampuan
              </h4>
              <ChartsEChart
                :option="skillsRadarOption"
                height="220px"
              />
            </div>
          </template>

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
      :ui="{ content: 'max-w-xl' }"
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
          <div class="grid grid-cols-2 gap-4">
            <UFormField label="Spesialisasi">
              <UInput
                v-model="form.specialization"
                class="w-full"
                placeholder="Dokter Gigi Umum"
              />
            </UFormField>
            <UFormField label="Komisi (%)">
              <UInput
                v-model.number="form.commissionRate"
                type="number"
                min="0"
                max="100"
                step="0.5"
                class="w-full"
              />
            </UFormField>
          </div>
          <UFormField label="Foto (URL)">
            <UInput
              v-model="form.photoUrl"
              class="w-full"
              placeholder="https://..."
            />
          </UFormField>
          <UFormField label="Bio Singkat">
            <UTextarea
              v-model="form.bio"
              class="w-full"
              :rows="2"
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
              <span class="text-sm font-medium">Kemampuan / Skill</span>
              <UButton
                icon="i-lucide-plus"
                size="xs"
                variant="soft"
                label="Tambah Skill"
                @click="addSkillRow"
              />
            </div>
            <div
              v-for="(skill, index) in form.skills"
              :key="index"
              class="flex items-end gap-2"
            >
              <UFormField
                label="Nama Skill"
                class="flex-1"
              >
                <UInput
                  v-model="skill.skillName"
                  class="w-full"
                  placeholder="Ortodonti"
                />
              </UFormField>
              <UFormField
                label="Level"
                class="w-32"
              >
                <USelect
                  v-model="skill.proficiency"
                  :items="[1, 2, 3, 4, 5].map(v => ({ label: PROFICIENCY_LABELS[v], value: v }))"
                  class="w-full"
                />
              </UFormField>
              <UFormField
                label="Tahun"
                class="w-20"
              >
                <UInput
                  v-model.number="skill.yearsExperience"
                  type="number"
                  min="0"
                />
              </UFormField>
              <UButton
                icon="i-lucide-trash-2"
                color="error"
                variant="ghost"
                @click="removeSkillRow(index)"
              />
            </div>
          </div>

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
  </div>
</template>
