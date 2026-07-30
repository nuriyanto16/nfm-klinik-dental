<script setup lang="ts">
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { BarChart, LineChart, PieChart, RadarChart } from 'echarts/charts'
import {
  GridComponent,
  TooltipComponent,
  LegendComponent,
  TitleComponent,
  DataZoomComponent
} from 'echarts/components'
import VChart from 'vue-echarts'
import type { EChartsOption } from 'echarts'

// Explicit module registration (not the "echarts" full bundle) keeps the
// client JS payload small — only the chart types actually used here ship.
use([
  CanvasRenderer,
  BarChart,
  LineChart,
  PieChart,
  RadarChart,
  GridComponent,
  TooltipComponent,
  LegendComponent,
  TitleComponent,
  DataZoomComponent
])

defineProps<{
  option: EChartsOption
  height?: string
}>()
</script>

<template>
  <VChart
    class="w-full"
    :style="{ height: height ?? '280px' }"
    :option="option"
    autoresize
  />
</template>
