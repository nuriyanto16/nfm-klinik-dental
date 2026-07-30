<script setup lang="ts">
import type { Reservation } from '~/types/api'

const props = defineProps<{
  reservations: Reservation[]
}>()

const emit = defineEmits<{ selectDay: [date: string] }>()

const DAY_HEADERS = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
const MONTH_NAMES = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
]

const today = new Date()
const viewYear = ref(today.getFullYear())
const viewMonth = ref(today.getMonth()) // 0-11

function toDateKey(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}
const todayKey = toDateKey(today)

// Tailwind's build-time class scanner needs literal class strings — a
// template-literal like `bg-${color}-100` would never be generated into the
// final CSS, so this maps each status to a fixed, fully-spelled-out class.
const STATUS_CHIP_CLASS: Record<string, string> = {
  pending: 'bg-neutral-100 dark:bg-neutral-800',
  confirmed: 'bg-info-100 dark:bg-info-900/30',
  checked_in: 'bg-warning-100 dark:bg-warning-900/30',
  in_progress: 'bg-warning-100 dark:bg-warning-900/30',
  completed: 'bg-success-100 dark:bg-success-900/30',
  cancelled: 'bg-error-100 dark:bg-error-900/30',
  no_show: 'bg-error-100 dark:bg-error-900/30'
}
function chipClass(status: string) {
  return STATUS_CHIP_CLASS[status] ?? 'bg-neutral-100 dark:bg-neutral-800'
}

const reservationsByDay = computed(() => {
  const map = new Map<string, Reservation[]>()
  for (const r of props.reservations) {
    const key = r.scheduledAt.slice(0, 10)
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(r)
  }
  return map
})

const weeks = computed(() => {
  const firstOfMonth = new Date(viewYear.value, viewMonth.value, 1)
  const startOffset = firstOfMonth.getDay() // 0=Sunday
  const gridStart = new Date(viewYear.value, viewMonth.value, 1 - startOffset)

  const days = []
  for (let i = 0; i < 42; i++) {
    const d = new Date(gridStart)
    d.setDate(gridStart.getDate() + i)
    days.push(d)
  }

  const result = []
  for (let w = 0; w < 6; w++) result.push(days.slice(w * 7, w * 7 + 7))
  return result
})

function prevMonth() {
  if (viewMonth.value === 0) {
    viewMonth.value = 11
    viewYear.value--
  } else {
    viewMonth.value--
  }
}
function nextMonth() {
  if (viewMonth.value === 11) {
    viewMonth.value = 0
    viewYear.value++
  } else {
    viewMonth.value++
  }
}
function goToday() {
  viewYear.value = today.getFullYear()
  viewMonth.value = today.getMonth()
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-3">
      <h3 class="font-medium">
        {{ MONTH_NAMES[viewMonth] }} {{ viewYear }}
      </h3>
      <div class="flex items-center gap-1">
        <UButton
          icon="i-lucide-chevron-left"
          size="xs"
          color="neutral"
          variant="soft"
          @click="prevMonth"
        />
        <UButton
          size="xs"
          color="neutral"
          variant="soft"
          label="Hari Ini"
          @click="goToday"
        />
        <UButton
          icon="i-lucide-chevron-right"
          size="xs"
          color="neutral"
          variant="soft"
          @click="nextMonth"
        />
      </div>
    </div>

    <div class="grid grid-cols-7 text-center text-xs font-medium text-muted mb-1">
      <div
        v-for="d in DAY_HEADERS"
        :key="d"
        class="py-1"
      >
        {{ d }}
      </div>
    </div>

    <div class="grid grid-cols-7 gap-1">
      <template
        v-for="(week, weekIndex) in weeks"
        :key="weekIndex"
      >
        <button
          v-for="day in week"
          :key="day.toISOString()"
          type="button"
          class="text-left border border-default rounded-md p-1.5 min-h-20 hover:border-primary transition-colors"
          :class="[
            day.getMonth() !== viewMonth ? 'opacity-40' : '',
            toDateKey(day) === todayKey ? 'ring-1 ring-primary' : ''
          ]"
          @click="emit('selectDay', toDateKey(day))"
        >
          <span
            class="text-xs tabular-nums"
            :class="toDateKey(day) === todayKey ? 'font-semibold text-primary' : ''"
          >
            {{ day.getDate() }}
          </span>
          <div class="space-y-0.5 mt-1">
            <div
              v-for="r in (reservationsByDay.get(toDateKey(day)) ?? []).slice(0, 2)"
              :key="r.id"
              class="text-[10px] truncate rounded px-1 py-0.5"
              :class="chipClass(r.status)"
            >
              {{ r.patientName }}
            </div>
            <p
              v-if="(reservationsByDay.get(toDateKey(day))?.length ?? 0) > 2"
              class="text-[10px] text-muted"
            >
              +{{ (reservationsByDay.get(toDateKey(day))?.length ?? 0) - 2 }} lainnya
            </p>
          </div>
        </button>
      </template>
    </div>
  </div>
</template>
