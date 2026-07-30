<script setup lang="ts">
withDefaults(defineProps<{ rows?: number, columns?: number }>(), { rows: 5, columns: 4 })
</script>

<template>
  <div class="w-full">
    <div class="flex items-center gap-4 px-4 py-3 border-b border-default">
      <USkeleton
        v-for="c in columns"
        :key="`h-${c}`"
        class="h-3"
        :class="c === 1 ? 'w-32' : 'flex-1'"
      />
    </div>
    <div
      v-for="r in rows"
      :key="r"
      class="flex items-center gap-4 px-4 py-4 border-b border-default last:border-b-0"
    >
      <USkeleton
        v-for="c in columns"
        :key="`r${r}-c${c}`"
        class="h-4"
        :class="c === 1 ? 'w-32' : 'flex-1'"
      />
    </div>
  </div>
</template>
