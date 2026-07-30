<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { Branch, BranchRevenue, DoctorDetail } from '~/types/api'

definePageMeta({ title: 'Cabang' })

const { data: branches, status, error } = useApiFetch<Branch[]>('/branches')
const { data: doctorsAdmin } = useApiFetch<DoctorDetail[]>('/doctors/admin')
const { data: branchRevenue } = useApiFetch<BranchRevenue[]>('/admin/dashboard/revenue-by-branch')

const activeBranches = computed(() => (branches.value ?? []).filter(b => b.isActive))
const inactiveBranches = computed(() => (branches.value ?? []).filter(b => !b.isActive))

// A computed (rather than a ref populated by a watcher) so the correct
// selection is derived at render time even during SSR, where the list's
// own async fetch may not have resolved yet when a watcher would fire.
const manualBranchId = ref<string | null>(null)
const selectedBranch = computed<Branch | null>(() => {
  const list = branches.value ?? []
  return list.find(b => b.id === manualBranchId.value) ?? list[0] ?? null
})

function selectBranch(b: Branch) {
  manualBranchId.value = b.id
}

const tabs = [
  { label: 'Profil Cabang', value: 'profil', icon: 'i-lucide-building-2' },
  { label: 'Dokter', value: 'dokter', icon: 'i-lucide-stethoscope' },
  { label: 'Jadwal', value: 'jadwal', icon: 'i-lucide-calendar-clock' },
  { label: 'Statistik', value: 'statistik', icon: 'i-lucide-bar-chart-3' }
]
const activeTab = ref('profil')

const branchDoctors = computed(() => {
  const id = selectedBranch.value?.id
  if (!id) return []
  return (doctorsAdmin.value ?? []).filter(d => d.branchIds?.includes(id))
})

const DAY_LABELS = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jum\'at', 'Sabtu']

interface ScheduleRow { doctorName: string, dayOfWeek: number, startTime: string, endTime: string }
const branchSchedules = computed<ScheduleRow[]>(() => {
  const id = selectedBranch.value?.id
  if (!id) return []
  const rows: ScheduleRow[] = []
  for (const d of doctorsAdmin.value ?? []) {
    for (const s of d.schedules ?? []) {
      if (s.branchId === id) {
        rows.push({ doctorName: d.fullName, dayOfWeek: s.dayOfWeek, startTime: s.startTime, endTime: s.endTime })
      }
    }
  }
  return rows.sort((a, b) => a.dayOfWeek - b.dayOfWeek || a.startTime.localeCompare(b.startTime))
})

const scheduleColumns = [
  { accessorKey: 'dayOfWeek', header: 'Hari' },
  { accessorKey: 'doctorName', header: 'Dokter' },
  { id: 'time', header: 'Jam' }
]

const doctorColumns = [
  { id: 'photo', header: '' },
  { accessorKey: 'fullName', header: 'Nama' },
  { accessorKey: 'specialization', header: 'Spesialisasi' },
  { accessorKey: 'commissionRate', header: 'Komisi' },
  { accessorKey: 'isActive', header: 'Status' }
]

const currentBranchRevenue = computed(() =>
  (branchRevenue.value ?? []).find(r => r.branchName === selectedBranch.value?.name) ?? null
)

const branchCompareOption = computed<EChartsOption>(() => ({
  tooltip: {
    trigger: 'axis',
    valueFormatter: v => formatCompactIDR(Number(v ?? 0))
  },
  grid: { left: 4, right: 16, top: 8, bottom: 8, containLabel: true },
  xAxis: { type: 'value', axisLabel: { formatter: (v: number) => formatCompactIDR(v) } },
  yAxis: {
    type: 'category',
    data: (branchRevenue.value ?? []).map(r => r.branchName),
    axisLabel: { fontSize: 10 }
  },
  series: [{
    type: 'bar',
    barMaxWidth: 18,
    data: (branchRevenue.value ?? []).map(r => ({
      value: r.revenue,
      itemStyle: { color: r.branchName === selectedBranch.value?.name ? CHART_PRIMARY : CHART_PRIMARY_LIGHT }
    }))
  }]
}))
</script>

<template>
  <UContainer class="py-6 space-y-4">
    <div>
      <h1 class="text-xl font-semibold">
        Cabang
      </h1>
      <p class="text-sm text-muted">
        Profil, dokter, jadwal, dan statistik tiap cabang Nina Dental Care.
      </p>
    </div>

    <UAlert
      v-if="error"
      color="error"
      variant="subtle"
      icon="i-lucide-alert-triangle"
      title="Gagal memuat data"
      :description="`core-api belum bisa dihubungi: ${error.message}`"
    />

    <div class="grid grid-cols-1 lg:grid-cols-4 gap-4 items-start">
      <!-- Left: branch list, grouped -->
      <UCard
        class="lg:col-span-1"
        :ui="{ body: 'p-2 space-y-3' }"
      >
        <SkeletonTableSkeleton
          v-if="status === 'pending'"
          :columns="1"
        />
        <template v-else>
          <div>
            <p class="text-[10px] font-semibold text-muted uppercase tracking-wide px-2 mb-1">
              Aktif ({{ activeBranches.length }})
            </p>
            <div class="space-y-1">
              <button
                v-for="b in activeBranches"
                :key="b.id"
                type="button"
                class="w-full text-left px-2 py-2 rounded-lg flex items-center gap-2 transition-colors"
                :class="selectedBranch?.id === b.id ? 'bg-primary/10 text-primary' : 'hover:bg-elevated'"
                @click="selectBranch(b)"
              >
                <UIcon
                  name="i-lucide-building-2"
                  class="size-4 shrink-0"
                />
                <span class="min-w-0">
                  <span class="block text-sm font-medium truncate">{{ b.name }}</span>
                  <span class="block text-[11px] text-muted truncate">{{ b.city }}</span>
                </span>
              </button>
            </div>
          </div>
          <div v-if="inactiveBranches.length">
            <p class="text-[10px] font-semibold text-muted uppercase tracking-wide px-2 mb-1">
              Nonaktif ({{ inactiveBranches.length }})
            </p>
            <div class="space-y-1">
              <button
                v-for="b in inactiveBranches"
                :key="b.id"
                type="button"
                class="w-full text-left px-2 py-2 rounded-lg flex items-center gap-2 opacity-60 transition-colors"
                :class="selectedBranch?.id === b.id ? 'bg-primary/10 text-primary' : 'hover:bg-elevated'"
                @click="selectBranch(b)"
              >
                <UIcon
                  name="i-lucide-building-2"
                  class="size-4 shrink-0"
                />
                <span class="min-w-0">
                  <span class="block text-sm font-medium truncate">{{ b.name }}</span>
                  <span class="block text-[11px] text-muted truncate">{{ b.city }}</span>
                </span>
              </button>
            </div>
          </div>
        </template>
      </UCard>

      <!-- Right: tabbed detail -->
      <UCard
        class="lg:col-span-3"
        :ui="{ body: 'p-0 sm:p-0' }"
      >
        <div
          v-if="!selectedBranch"
          class="p-6"
        >
          <EmptyState
            icon="i-lucide-building-2"
            message="Pilih cabang di daftar untuk melihat detail."
          />
        </div>
        <template v-else>
          <div class="px-4 pt-4 flex items-center justify-between flex-wrap gap-2">
            <div>
              <h2 class="text-lg font-semibold">
                {{ selectedBranch.name }}
              </h2>
              <p class="text-xs text-muted">
                {{ selectedBranch.address }}, {{ selectedBranch.city }}
              </p>
            </div>
            <UBadge
              :color="selectedBranch.isActive ? 'success' : 'neutral'"
              variant="subtle"
            >
              {{ selectedBranch.isActive ? 'Aktif' : 'Nonaktif' }}
            </UBadge>
          </div>

          <UTabs
            v-model="activeTab"
            :items="tabs"
            class="px-4"
          >
            <template #content="{ item }">
              <div class="py-4">
                <!-- Profil Cabang -->
                <dl
                  v-if="item.value === 'profil'"
                  class="grid grid-cols-1 sm:grid-cols-2 gap-4 text-sm"
                >
                  <div>
                    <dt class="text-xs text-muted">
                      Alamat
                    </dt>
                    <dd>{{ selectedBranch.address }}</dd>
                  </div>
                  <div>
                    <dt class="text-xs text-muted">
                      Kota
                    </dt>
                    <dd>{{ selectedBranch.city }}</dd>
                  </div>
                  <div>
                    <dt class="text-xs text-muted">
                      Telepon
                    </dt>
                    <dd>{{ selectedBranch.phone ?? '—' }}</dd>
                  </div>
                  <div>
                    <dt class="text-xs text-muted">
                      Jam Operasional
                    </dt>
                    <dd>{{ selectedBranch.opensAt.slice(0, 5) }} – {{ selectedBranch.closesAt.slice(0, 5) }}</dd>
                  </div>
                  <div>
                    <dt class="text-xs text-muted">
                      Slug
                    </dt>
                    <dd class="font-mono text-xs">
                      {{ selectedBranch.slug }}
                    </dd>
                  </div>
                </dl>

                <!-- Dokter -->
                <div v-else-if="item.value === 'dokter'">
                  <EmptyState
                    v-if="branchDoctors.length === 0"
                    icon="i-lucide-stethoscope"
                    message="Belum ada dokter terhubung ke cabang ini."
                  />
                  <UTable
                    v-else
                    :data="branchDoctors"
                    :columns="doctorColumns"
                  >
                    <template #photo-cell="{ row }">
                      <UAvatar
                        :src="row.original.photoUrl ?? undefined"
                        :alt="row.original.fullName"
                        size="xs"
                      />
                    </template>
                    <template #specialization-cell="{ row }">
                      {{ row.original.specialization ?? '—' }}
                    </template>
                    <template #commissionRate-cell="{ row }">
                      {{ row.original.commissionRate }}%
                    </template>
                    <template #isActive-cell="{ row }">
                      <UBadge
                        :color="row.original.isActive ? 'success' : 'neutral'"
                        variant="subtle"
                      >
                        {{ row.original.isActive ? 'Aktif' : 'Nonaktif' }}
                      </UBadge>
                    </template>
                  </UTable>
                </div>

                <!-- Jadwal -->
                <div v-else-if="item.value === 'jadwal'">
                  <EmptyState
                    v-if="branchSchedules.length === 0"
                    icon="i-lucide-calendar-clock"
                    message="Belum ada jadwal dokter di cabang ini."
                  />
                  <UTable
                    v-else
                    :data="branchSchedules"
                    :columns="scheduleColumns"
                  >
                    <template #dayOfWeek-cell="{ row }">
                      {{ DAY_LABELS[row.original.dayOfWeek] }}
                    </template>
                    <template #time-cell="{ row }">
                      {{ row.original.startTime.slice(0, 5) }} – {{ row.original.endTime.slice(0, 5) }}
                    </template>
                  </UTable>
                </div>

                <!-- Statistik -->
                <div
                  v-else
                  class="space-y-4"
                >
                  <div class="grid grid-cols-2 gap-3">
                    <div class="rounded-lg border border-default p-3 text-center">
                      <p class="text-lg font-semibold">
                        {{ currentBranchRevenue ? formatIDR(currentBranchRevenue.revenue) : '—' }}
                      </p>
                      <p class="text-[11px] text-muted">
                        Revenue
                      </p>
                    </div>
                    <div class="rounded-lg border border-default p-3 text-center">
                      <p class="text-lg font-semibold">
                        {{ currentBranchRevenue?.reservationCount ?? '—' }}
                      </p>
                      <p class="text-[11px] text-muted">
                        Total Reservasi
                      </p>
                    </div>
                  </div>
                  <div>
                    <p class="text-xs font-semibold text-muted uppercase tracking-wide mb-1">
                      Perbandingan Revenue Antar Cabang
                    </p>
                    <SkeletonChartSkeleton v-if="!branchRevenue" />
                    <ChartsEChart
                      v-else
                      :option="branchCompareOption"
                      height="180px"
                    />
                  </div>
                </div>
              </div>
            </template>
          </UTabs>
        </template>
      </UCard>
    </div>
  </UContainer>
</template>
