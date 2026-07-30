<script setup lang="ts">
/**
 * Single-series revenue-over-time line/area chart. One hue (sequential
 * blue), no legend needed for one series. Endpoint is direct-labeled per
 * the data-viz method ("lines -> value at the end"); every other point is
 * reachable via the native tooltip on its dot.
 */
const props = defineProps<{
  points: { date: string, revenue: number }[]
}>()

const width = 640
const height = 220
const padding = { top: 16, right: 16, bottom: 28, left: 56 }
const plotWidth = width - padding.left - padding.right
const plotHeight = height - padding.top - padding.bottom

function niceCeil(value: number): number {
  if (value <= 0) return 100000
  const magnitude = 10 ** Math.floor(Math.log10(value))
  return Math.ceil(value / magnitude) * magnitude
}

const maxValue = computed(() => niceCeil(Math.max(...props.points.map(p => p.revenue), 1) * 1.15))
const yTicks = computed(() => [0, maxValue.value / 2, maxValue.value])

function xScale(index: number): number {
  if (props.points.length <= 1) return padding.left + plotWidth / 2
  return padding.left + (index / (props.points.length - 1)) * plotWidth
}
function yScale(value: number): number {
  return padding.top + (1 - value / maxValue.value) * plotHeight
}

const linePath = computed(() =>
  props.points.map((p, i) => `${i === 0 ? 'M' : 'L'} ${xScale(i)} ${yScale(p.revenue)}`).join(' ')
)
const areaPath = computed(() => {
  if (props.points.length === 0) return ''
  const baseline = padding.top + plotHeight
  const first = `M ${xScale(0)} ${baseline}`
  const line = props.points.map((p, i) => `L ${xScale(i)} ${yScale(p.revenue)}`).join(' ')
  const last = `L ${xScale(props.points.length - 1)} ${baseline} Z`
  return `${first} ${line} ${last}`
})

const lastPoint = computed(() => props.points.at(-1))
</script>

<template>
  <div class="viz-root">
    <div
      v-if="points.length === 0"
      class="text-sm text-muted py-6 text-center"
    >
      Belum ada data.
    </div>
    <svg
      v-else
      :viewBox="`0 0 ${width} ${height}`"
      class="w-full h-auto"
      role="img"
      aria-label="Grafik revenue harian"
    >
      <line
        v-for="tick in yTicks"
        :key="tick"
        :x1="padding.left"
        :x2="width - padding.right"
        :y1="yScale(tick)"
        :y2="yScale(tick)"
        class="viz-grid"
      />
      <text
        v-for="tick in yTicks"
        :key="`t-${tick}`"
        :x="padding.left - 8"
        :y="yScale(tick) + 4"
        text-anchor="end"
        class="viz-tick"
      >{{ formatCompactIDR(tick) }}</text>

      <path
        :d="areaPath"
        class="viz-area"
      />
      <path
        :d="linePath"
        class="viz-line"
      />

      <g
        v-for="(p, i) in points"
        :key="p.date"
      >
        <circle
          :cx="xScale(i)"
          :cy="yScale(p.revenue)"
          r="4"
          class="viz-dot"
        >
          <title>{{ formatDateShort(p.date) }}: {{ formatIDR(p.revenue) }}</title>
        </circle>
      </g>

      <text
        v-if="lastPoint"
        :x="xScale(points.length - 1)"
        :y="yScale(lastPoint.revenue) - 12"
        text-anchor="end"
        class="viz-end-label"
      >{{ formatIDR(lastPoint.revenue) }}</text>

      <text
        v-for="(p, i) in points"
        :key="`x-${p.date}`"
        :x="xScale(i)"
        :y="height - padding.bottom + 18"
        text-anchor="middle"
        class="viz-tick"
      >{{ formatDateShort(p.date) }}</text>
    </svg>
  </div>
</template>

<style scoped>
.viz-root {
  color-scheme: light;
  --series-1: #2a78d6;
  --grid: #e1e0d9;
  --text-secondary: #52514e;
  --text-muted: #898781;
}
@media (prefers-color-scheme: dark) {
  :root:where(:not([data-theme='light'])) .viz-root {
    color-scheme: dark;
    --series-1: #3987e5;
    --grid: #2c2c2a;
    --text-secondary: #c3c2b7;
    --text-muted: #898781;
  }
}
.dark .viz-root {
  color-scheme: dark;
  --series-1: #3987e5;
  --grid: #2c2c2a;
  --text-secondary: #c3c2b7;
  --text-muted: #898781;
}

.viz-grid {
  stroke: var(--grid);
  stroke-width: 1;
}
.viz-tick {
  fill: var(--text-muted);
  font-size: 10px;
}
.viz-area {
  fill: var(--series-1);
  opacity: 0.1;
  stroke: none;
}
.viz-line {
  fill: none;
  stroke: var(--series-1);
  stroke-width: 2;
  stroke-linejoin: round;
  stroke-linecap: round;
}
.viz-dot {
  fill: var(--series-1);
  stroke: var(--ui-bg, #fcfcfb);
  stroke-width: 2;
}
.viz-end-label {
  fill: var(--text-secondary);
  font-size: 11px;
  font-weight: 600;
}
</style>
