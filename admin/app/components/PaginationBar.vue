<script setup lang="ts">
const props = defineProps<{
  page: number
  totalPages: number
  total: number
  pageSize: number
}>()

const emit = defineEmits<{ 'update:page': [page: number] }>()

const rangeStart = computed(() => (props.total === 0 ? 0 : (props.page - 1) * props.pageSize + 1))
const rangeEnd = computed(() => Math.min(props.page * props.pageSize, props.total))
</script>

<template>
  <div class="flex items-center justify-between px-4 py-3 border-t border-default">
    <p class="text-xs text-muted">
      Menampilkan {{ rangeStart }}–{{ rangeEnd }} dari {{ total }} data
    </p>
    <div class="flex items-center gap-2">
      <UButton
        icon="i-lucide-chevron-left"
        size="xs"
        color="neutral"
        variant="soft"
        :disabled="page <= 1"
        @click="emit('update:page', page - 1)"
      />
      <span class="text-xs text-muted min-w-16 text-center">Hal {{ page }} / {{ Math.max(totalPages, 1) }}</span>
      <UButton
        icon="i-lucide-chevron-right"
        size="xs"
        color="neutral"
        variant="soft"
        :disabled="page >= totalPages"
        @click="emit('update:page', page + 1)"
      />
    </div>
  </div>
</template>
