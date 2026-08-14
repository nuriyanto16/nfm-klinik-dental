<script setup lang="ts">
definePageMeta({
  title: 'Log Error Aplikasi'
})

const { data, pending, error, refresh } = useApiFetch<{ logs: string[] }>('/system/logs')

const logs = computed(() => data.value?.logs || [])

// Auto-refresh every 10 seconds
let interval: any
onMounted(() => {
  interval = setInterval(() => {
    refresh()
  }, 10000)
})

onUnmounted(() => {
  if (interval) clearInterval(interval)
})

function getLogClass(line: string) {
  if (line.includes('"level":"error"') || line.includes('"level":"fatal"')) return 'text-red-400'
  if (line.includes('"level":"warn"')) return 'text-yellow-400'
  if (line.includes('"level":"info"')) return 'text-blue-400'
  return ''
}
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Log Error Aplikasi</h1>
        <p class="text-gray-500 mt-1">Melihat log error backend secara real-time (1000 baris terakhir).</p>
      </div>
      <UButton
        icon="i-lucide-refresh-cw"
        color="gray"
        variant="ghost"
        :loading="pending"
        @click="refresh"
      >
        Refresh
      </UButton>
    </div>

    <UCard
      :ui="{
        base: 'overflow-hidden flex flex-col',
        body: { base: 'flex-1 overflow-y-auto font-mono text-sm bg-gray-950 text-gray-300 p-4 min-h-[500px] max-h-[700px]' }
      }"
    >
      <div v-if="error" class="text-red-500 flex items-center gap-2">
        <UIcon name="i-lucide-alert-circle" class="w-5 h-5" />
        Gagal memuat log aplikasi: {{ error.message }}
      </div>
      
      <div v-else-if="logs.length === 0" class="text-gray-500 text-center py-12 flex flex-col items-center">
        <UIcon name="i-lucide-check-circle-2" class="w-12 h-12 text-green-500 mb-3" />
        <p>Tidak ada error yang tercatat saat ini.</p>
        <p class="text-xs mt-1">Sistem berjalan dengan normal.</p>
      </div>

      <div v-else class="space-y-1 whitespace-pre-wrap break-all">
        <div 
          v-for="(line, idx) in logs" 
          :key="idx"
          :class="getLogClass(line)"
        >
          {{ line }}
        </div>
      </div>
    </UCard>
  </div>
</template>
