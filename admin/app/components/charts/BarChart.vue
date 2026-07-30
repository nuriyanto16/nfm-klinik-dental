<script setup lang="ts">
/**
 * Horizontal single-hue bar chart for nominal categories (no natural value
 * order) — one color for every bar, per the data-viz method: a value-ramp
 * on nominal categories double-encodes length as hue and is an
 * anti-pattern. Direct-labeled (category on the axis, value at the bar's
 * tip), so no legend is needed for this single series.
 */
const props = defineProps<{
  items: { label: string, value: number }[]
  formatValue?: (value: number) => string
}>()

const format = (value: number) => props.formatValue ? props.formatValue(value) : value.toLocaleString('id-ID')

const max = computed(() => Math.max(1, ...props.items.map(i => i.value)))
</script>

<template>
  <div class="viz-root">
    <div
      v-if="items.length === 0"
      class="text-sm text-muted py-6 text-center"
    >
      Belum ada data.
    </div>
    <div
      v-for="item in items"
      :key="item.label"
      class="viz-row"
    >
      <span
        class="viz-label"
        :title="item.label"
      >{{ item.label }}</span>
      <div class="viz-track">
        <div
          class="viz-bar"
          :style="{ width: `${(item.value / max) * 100}%` }"
          :title="`${item.label}: ${format(item.value)}`"
        />
      </div>
      <span class="viz-value">{{ format(item.value) }}</span>
    </div>
  </div>
</template>

<style scoped>
.viz-root {
  color-scheme: light;
  --series-1: #2a78d6;
  --baseline: #c3c2b7;
  --text-secondary: #52514e;
  --text-muted: #898781;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
@media (prefers-color-scheme: dark) {
  :root:where(:not([data-theme='light'])) .viz-root {
    color-scheme: dark;
    --series-1: #3987e5;
    --baseline: #383835;
    --text-secondary: #c3c2b7;
    --text-muted: #898781;
  }
}
.dark .viz-root {
  color-scheme: dark;
  --series-1: #3987e5;
  --baseline: #383835;
  --text-secondary: #c3c2b7;
  --text-muted: #898781;
}

.viz-row {
  display: grid;
  grid-template-columns: minmax(0, 40%) 1fr auto;
  align-items: center;
  gap: 10px;
  min-height: 24px;
}

.viz-label {
  font-size: 0.8125rem;
  color: var(--text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.viz-track {
  position: relative;
  height: 20px;
  border-left: 1px solid var(--baseline);
}

.viz-bar {
  height: 100%;
  min-width: 2px;
  background: var(--series-1);
  border-radius: 0 4px 4px 0;
}

.viz-value {
  font-size: 0.8125rem;
  font-variant-numeric: tabular-nums;
  color: var(--text-secondary);
  white-space: nowrap;
}
</style>
